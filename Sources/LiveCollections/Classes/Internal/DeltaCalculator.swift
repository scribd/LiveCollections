//
//  DeltaCalculator.swift
//  LiveCollections
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

// MARK: Calculate Deltas

final class DeltaCalculator<Element: UniquelyIdentifiable> {
    
    private let startingData: [Element]
    private let updatedData: [Element]
    private let originalIndices: [Element.UniqueIDType: Int]
    private let updatedIndices: [Element.UniqueIDType: Int]
    private let includeIdenticalMoves: Bool
    
    init(startingData: [Element], updatedData: [Element], includeIdenticalMoves: Bool = false) {
        self.startingData = startingData
        self.updatedData = updatedData
        self.originalIndices = startingData.makeIndexMap()
        self.updatedIndices = updatedData.makeIndexMap()
        self.includeIdenticalMoves = includeIdenticalMoves
    }
    
    func calculateItemDelta() -> (delta: IndexDelta, deletedItems: [Element]) {
        
        let (deletedItems, deletedItemIndices) = self.deletedItems()
        let (_, insertedItemIndices) = insertedItems()
        let (reloadedIndexItemPairs, movedIndexItemPairs) = reloadedAndMovedItems(deletedIndices: deletedItemIndices, insertedIndices: insertedItemIndices)
        
        let delta = IndexDelta(deletions: deletedItemIndices,
                               insertions: insertedItemIndices,
                               reloads: reloadedIndexItemPairs,
                               moves: movedIndexItemPairs)
        
        return (delta: delta, deletedItems: deletedItems)
    }
    
    func calculateSectionDelta() -> (delta: IndexDelta, deletedItems: [Element]) {
        
        let (deletedItems, deletedItemIndices) = self.deletedItems()
        let (_, insertedItemIndices) = insertedItems()
        let (_, movedIndexItemPairs) = reloadedAndMovedItems(deletedIndices: deletedItemIndices, insertedIndices: insertedItemIndices)
        
        let delta = IndexDelta(deletions: deletedItemIndices,
                               insertions: insertedItemIndices,
                               reloads: [],
                               moves: movedIndexItemPairs)
        
        return (delta: delta, deletedItems: deletedItems)
    }
    
    // MARK: Deletions
    
    func deletedItems() -> (items: [Element], indices: [Int]) {
        
        let deletedItems: [Element] = startingData.filter { updatedIndices[$0.uniqueID] == nil }
        let deletedIndices = originalIndices.indices(forItemsIn: deletedItems)
        return (items: Array(deletedItems), indices: deletedIndices)
    }
    
    // MARK: Insertions
    
    func insertedItems() -> (items: [Element], indices: [Int]) {
        
        let insertedItems: [Element] = updatedData.filter { originalIndices[$0.uniqueID] == nil }
        let insertedIndices = updatedIndices.indices(forItemsIn: insertedItems)
        return (items: Array(insertedItems), indices: insertedIndices)
    }
    
    // MARK: Moves / Reloads
    
    /**
     This finds the items that have been moved (positions have changed but uniqueID and equality are the same)
     - parameters:
     - updatedData: the updated array to calculate the deltas against
     - deletedIndices: previously calculated positions of deleted items
     - insertedIndices: previously calculated positions of inserted items
     - returns: an array of the index pairs of all moved items
     */
    func reloadedAndMovedItems(deletedIndices: [Int],
                               insertedIndices: [Int]) -> (reloaded: [IndexPair], moved: [IndexPair]) {
        
        var movedIndexPairs = [IndexPair]()
        var reloadedIndexPairs = [IndexPair]()

        let intersectedItems: [Element] = startingData.filter { updatedIndices[$0.uniqueID] != nil }
        
        var remainingDeletedIndices = Array(deletedIndices.reversed())
        var remainingInsertedIndices = Array(insertedIndices.reversed())
        
        var totalDeletionShift: Int = 0
        var totalInsertionShift: Int = 0

        func adjustedIndex(_ index: Int) -> Int {
            var transposedIndex = index + totalDeletionShift + totalInsertionShift
            
            while let deletedIndex = remainingDeletedIndices.popLast() {
                guard deletedIndex < index else {
                    remainingDeletedIndices.append(deletedIndex)
                    break
                }
                transposedIndex -= 1
                totalDeletionShift -= 1
            }
            
            while let insertedIndex = remainingInsertedIndices.popLast() {
                guard insertedIndex <= transposedIndex else {
                    remainingInsertedIndices.append(insertedIndex)
                    break
                }
                transposedIndex += 1
                totalInsertionShift += 1
            }
            
            return transposedIndex
        }
        
        for intersectedItem in intersectedItems {
            guard let originalIndex = originalIndices[intersectedItem.uniqueID],
                let updatedIndex = updatedIndices[intersectedItem.uniqueID] else {
                continue
            }

            let adjustedOriginalIndex = adjustedIndex(originalIndex)
            
            let startingItem = startingData[originalIndex]
            let updatedItem = updatedData[updatedIndex]
            let isReload = startingItem != updatedItem
            
            let logicallyEqualPositions = (updatedIndex == adjustedOriginalIndex)
            let isValidMove = logicallyEqualPositions == false || includeIdenticalMoves
            
            let indexPair = IndexPair(source: originalIndex, target: updatedIndex)

            if isReload {
                reloadedIndexPairs.append(indexPair)
            }

            if isValidMove {
                movedIndexPairs.append(indexPair)
            }
        }
        
        return (reloaded: reloadedIndexPairs, moved: movedIndexPairs)
    }
}

typealias DeltaOperationCalculation<DataType> = ([DataType]) -> Void

enum DeltaOperationAction {
    case append
    case update
}

struct DeltaOperation<DataType> {
    
    private let data: [DataType]
    private let action: DeltaOperationAction
    private let calculation: DeltaOperationCalculation<DataType>
    
    init(data: [DataType], action: DeltaOperationAction, calculation: @escaping DeltaOperationCalculation<DataType>) {
        self.data = data
        self.action = action
        self.calculation = calculation
    }
    
    func buildBlockOperation() -> BlockOperation {
        return BlockOperation {
           self.calculation(self.data)
        }
    }
    
    func merged(with operation: DeltaOperation) -> DeltaOperation {
        switch (action, operation.action) {
        case (.append, .append):
            // append merged contents
            return DeltaOperation(data: data + operation.data, action: .append, calculation: operation.calculation)
        case (.update, .append):
            // update merged contents
            return DeltaOperation(data: data + operation.data, action: .update, calculation: calculation)
        case (_, .update):
            // drop intermediate stages
            return operation
        }
    }
}

final class DataCalculatorQueue<DataType> {
    
    private var _nextOperation: DeltaOperation<DataType>?
    private let dataQueue = DispatchQueue(label: "\(DataCalculatorQueue.self) dispatch queue")
    
    func setNext(_ operation: DeltaOperation<DataType>) {
        dataQueue.async {
            // merge intermediate updates
            if let nextOperation = self._nextOperation {
                self._nextOperation = nextOperation.merged(with: operation)
            } else {
                self._nextOperation = operation
            }
        }
    }
    
    func pop() -> BlockOperation? {
        return dataQueue.sync {
            defer {
                _nextOperation = nil
            }
            return _nextOperation?.buildBlockOperation()
        }
    }
}

// MARK: - Private

private extension Array where Element: UniquelyIdentifiable {
    
    func makeIndexMap() -> [Element.UniqueIDType: Int] {
        var indexMap = [Element.UniqueIDType: Int]()
        for iterator in enumerated() {
            indexMap[iterator.element.uniqueID] = iterator.offset
        }
        return indexMap
    }
}

private extension Dictionary where Value == Int {
    
    func indices<DataType>(forItemsIn array: [DataType]) -> [Int] where DataType: UniquelyIdentifiable, DataType.UniqueIDType == Key {
        return array.compactMap { self[$0.uniqueID] }
    }
}


