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
                guard insertedIndex <= index else {
                    remainingDeletedIndices.append(insertedIndex)
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

final class DataCalculatorQueue {
    
    private var _nextOperation: BlockOperation?
    private let dataQueue = DispatchQueue(label: "\(DataCalculatorQueue.self) dispatch queue")
    
    func setNext(_ value: BlockOperation) {
        dataQueue.async {
            // there's no need to manage intermediate updates.
            // If the data is streaming in so quickly that an update is queued,
            // just drop it on the ground and animate A->C rather than A->B->C
            self._nextOperation = value
        }
    }
    
    func pop() -> BlockOperation? {
        return dataQueue.sync {
            defer {
                _nextOperation = nil
            }
            return _nextOperation
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


