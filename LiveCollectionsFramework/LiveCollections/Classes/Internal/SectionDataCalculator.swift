//
//  SectionDataCalculator.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/15/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import Foundation

private final class Counter {
    static var count = 0
}


final class SectionDataCalculator<SectionType: UniquelyIdentifiableSection> {
    
    // MARK: State

    typealias DataType = SectionType.DataType
    
    private var processingQueue = DispatchQueue(label: "\(SectionDataCalculator.self) ordering queue")
    private let dataQueue = DispatchQueue(label: "\(SectionDataCalculator.self) dispatch queue", attributes: .concurrent)

    private var _isCalculating: Bool = false
    private var isCalculating: Bool {
        get { return dataQueue.sync { return _isCalculating } }
        set { dataQueue.async(flags: .barrier) { self._isCalculating = newValue } }
    }

    private let _orderedQueue = DataCalculatorQueue()
    private var orderedQueue: DataCalculatorQueue { return dataQueue.sync { return _orderedQueue } }
    
    private var complationCount = 0
    
    // MARK: API
    
    func updateAndAnimate<DeletionDelegate, SectionProvider>(_ updatedSections: [SectionType],
                                                             sectionProvider: SectionProvider,
                                                             view: SectionDeltaUpdatableView,
                                                             reloadDelegate: CollectionSectionDataManualReloadDelegate?,
                                                             deletionDelegate: DeletionDelegate?,
                                                             completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, SectionProvider: SectionDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType {
        
        _processCalculation { [weak self] in
            self?._updateAndAnimate(updatedSections,
                                    sectionProvider: sectionProvider,
                                    view: view,
                                    reloadDelegate: reloadDelegate,
                                    deletionDelegate: deletionDelegate,
                                    completion: completion)
        }
    }
    
    func appendAndAnimate<SectionProvider>(_ appendedItems: [SectionType],
                                           sectionProvider: SectionProvider,
                                           view: SectionDeltaUpdatableView,
                                           completion: (() -> Void)?) where SectionProvider: SectionDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType {
        
        _processCalculation { [weak self] in
            self?._appendAndAnimate(appendedItems,
                                    sectionProvider: sectionProvider,
                                    view: view,
                                    completion: completion)
        }
    }
    
    func orderedRows(for sections: [SectionType]) -> [DataType] {
        let allRows = sections.flatMap { $0.items }
        return [DataType](allRows)
    }
}

// MARK: - Private

private extension SectionDataCalculator {
    
    // MARK: Calculation Queue Management

    func _processCalculation(_ calculation: @escaping () -> Void) {
        processingQueue.async {
            if self.isCalculating {
                let operation = BlockOperation(block: calculation)
                self.orderedQueue.setNext(operation)
            } else {
                self.isCalculating = true
                calculation()
            }
        }
    }
    
    func _performNextCalculation() {
        processingQueue.async { [weak self] in
            guard let strongSelf = self else { return }
            guard let nextOperation = strongSelf.orderedQueue.pop() else {
                strongSelf.isCalculating = false
                return
            }
            nextOperation.start()
        }
    }
    
    // MARK: Perform Calculations
    
    func _updateAndAnimate<DeletionDelegate, SectionProvider>(_ updatedSections: [SectionType],
                                                              sectionProvider: SectionProvider,
                                                              view: SectionDeltaUpdatableView,
                                                              reloadDelegate: CollectionSectionDataManualReloadDelegate?,
                                                              deletionDelegate: DeletionDelegate?,
                                                              completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, SectionProvider: SectionDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType {
        
        let currentCount = sectionProvider.rows.count
        let updatedCount = updatedSections.reduce(0) { $0 + $1.items.count }
        
        let shortCircuitAnimation = currentCount > sectionProvider.dataCountAnimationThreshold ||
            updatedCount > sectionProvider.dataCountAnimationThreshold
        
        // sanitize data
        // Any empty sections will be removed
        let sanitizedUpdatedSections = updatedSections.filter { $0.items.isEmpty == false }
        
        // calculate deltas
        var sections = sectionProvider.sections
        let sectionDeltaCalculator = DeltaCalculator<SectionType>(startingData: sections, updatedData: sanitizedUpdatedSections)
        let (sectionDelta, deletedSections) = sectionDeltaCalculator.calculateSectionDelta()
        
        // determine deleted row items (from the deleted sections)
        let deletedSectionItems = deletedSections.flatMap { $0.items }
        
        // determine inserted row items (from the inserted sections)
        var insertedItems: [DataType] = []
        for insertedSection in sectionDelta.insertions {
            insertedItems += sanitizedUpdatedSections[insertedSection].items
        }
        
        let originalSections = sections
        
        // ***********************************
        // RELATIVE DATA INTERMEDIATE STAGE
        // ***********************************
        
        // compare original data with moves and deletions applied
        // against new data with insertions *removed*
        // this lets us determine all of the row actions that occurred with the (remaining) existing data
        
        sections = dataWithMovesAndDeletions(byApplying: sectionDelta, on: sections, matching: sanitizedUpdatedSections)
        sectionProvider.sections = sections
        
        var rows = orderedRows(for: sections)
        sectionProvider.rows = rows
        
        let intermediateSections = sections
        
        let targetSections = dataWithInsertionsRemoved(byApplying: sectionDelta, on: sanitizedUpdatedSections)
        let targetUpdatedRowData = targetSections.flatMap { $0.items }
        let targetUpdatedRows = [DataType](targetUpdatedRowData)
        
        let rowDelta: IndexDelta
        let deletedItems: [DataType]

        if shortCircuitAnimation {
            rowDelta = .empty
            if reloadDelegate == nil {
                deletedItems = []
            } else {
                let rowDeltaCalculator = DeltaCalculator<DataType>(startingData: rows, updatedData: targetUpdatedRows, includeIdenticalMoves: true)
                (deletedItems, _) = rowDeltaCalculator.deletedRows()
            }
        } else {
            let rowDeltaCalculator = DeltaCalculator<DataType>(startingData: rows, updatedData: targetUpdatedRows, includeIdenticalMoves: true)
            (rowDelta, deletedItems) = rowDeltaCalculator.calculateRowDelta()
        }

        // ***********************************
        // RELATIVE DATA INTERMEDIATE STAGE 2
        // ***********************************
        
        // Now that we've calculated the row deltas, add just the section insertions to the original data set
        // (remember that we've already applied the deletions and moves) and trigger the section animations
        
        sections = dataWithInsertionsAdded(byApplying: sectionDelta, on: sections, from: sanitizedUpdatedSections)
        rows = orderedRows(for: sections)
        
        typealias SectionUpdateCompletion = () -> Void
        
        let performSectionUpdates: (SectionUpdateCompletion?) -> Void = { sectionUpdateCompletion in
            let sectionAnimationStlye: AnimationStyle = {
                guard let reloadDelegate = reloadDelegate else { return .preciseAnimations }
                return reloadDelegate.preferredSectionAnimationStyle(for: sectionDelta)
            }()
            
            DispatchQueue.main.async {

                let sectionUpdateData = {
                    sectionProvider.sections = sections
                    sectionProvider.rows = rows
                }
                
                switch sectionAnimationStlye {
                case .reloadData:
                    sectionUpdateData()
                    view.reloadData()
                    sectionUpdateCompletion?()

                case .reloadSections,
                     .preciseAnimations:
                    let viewDelegate: DeltaUpdatableViewDelegate? = {
                        guard let reloadDelegate = reloadDelegate else { return nil }
                        return AnyDeltaUpdatableViewDelegate(reloadDelegate)
                    }()
                    view.performAnimations(sectionDelta: sectionDelta,
                                           delegate: viewDelegate,
                                           updateData: sectionUpdateData,
                                           completion: sectionUpdateCompletion)
                }
            }
        }
        
        performSectionUpdates {
            // *******************
            // FINAL ANIMATIONS
            // *******************
            
            // finally we convert the row deltas that we calculated in MIS1 into index paths.  This will include making
            // adjustments for the (then) missing inserted sections.  Once those adjustments are made, trigger the row animations
            
            let calculationCompletion: () -> Void = { [weak self, weak weakDeletionDelegate = deletionDelegate] in
                completion?()
                let allDeletedItems = [deletedItems, deletedSectionItems].flatMap { $0 }
                if allDeletedItems.isEmpty == false {
                    weakDeletionDelegate?.didDeleteItems(allDeletedItems)
                }
                Counter.count += 1
                self?._performNextCalculation()
            }
            
            // short circuit if too many changes
            
            guard shortCircuitAnimation == false else {
                
                let updateData = { [weak self, weak weakProvider = sectionProvider] in
                    guard let strongSelf = self, let strongProvider = weakProvider else { return }
                    strongProvider.sections = sanitizedUpdatedSections
                    let rows = strongSelf.orderedRows(for: sanitizedUpdatedSections)
                    strongProvider.rows = rows
                }
                
                DispatchQueue.main.async {
                    updateData()
                    view.reloadData()
                    calculationCompletion()
                }
                return
            }
            
            guard sectionDelta.hasChanges || rowDelta.hasChanges else {
                calculationCompletion()
                return // don't need to update with no changes
            }
            
            // convert row indexs to NSIndexPaths
            let rowIndexPathDeltas = self.convertRowIndexesToIndexPaths(rowDelta, sectionDelta: sectionDelta, originalSections: originalSections, intermediateSections: intermediateSections, targetSections: targetSections)
            
            // finally we set our data with what was passed into the update() function
            sections = sanitizedUpdatedSections
            rows = self.orderedRows(for: sections)
            
            let updateData = {
                sectionProvider.sections = sections
                sectionProvider.rows = rows
            }
            
            let rowAnimationStlye: AnimationStyle = {
                guard let reloadDelegate = reloadDelegate else { return .preciseAnimations }
                return reloadDelegate.preferredRowAnimationStyle(for: rowDelta)
            }()
            
            DispatchQueue.main.async { [weak weakView = view] in
                guard let strongView = weakView else {
                    updateData()
                    calculationCompletion()
                    return
                }
                
                switch rowAnimationStlye {
                case .reloadData:
                    updateData()
                    strongView.reloadData()
                    calculationCompletion()
                    
                case .reloadSections:
                    strongView.reloadAllSections(updateData: updateData, completion: calculationCompletion)
                    
                case .preciseAnimations:
                    let viewDelegate: DeltaUpdatableViewDelegate? = {
                        guard let reloadDelegate = reloadDelegate else { return nil }
                        return AnyDeltaUpdatableViewDelegate(reloadDelegate)
                    }()
                    strongView.performAnimations(sectionRowDelta: rowIndexPathDeltas,
                                                 delegate: viewDelegate,
                                                 updateData: updateData,
                                                 completion: calculationCompletion)
                }
            }
        }
    }
    
    func _appendAndAnimate<SectionProvider>(_ appendedItems: [SectionType],
                                            sectionProvider: SectionProvider,
                                            view: SectionDeltaUpdatableView,
                                            completion: (() -> Void)?) where SectionProvider: SectionDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType {
        
        let calculationCompletion: () -> Void = { [weak self] in
            completion?()
            self?._performNextCalculation()
        }

        guard appendedItems.isEmpty == false else {
            calculationCompletion()
            return // don't need to update without any changes
        }
        
        let originalRows = sectionProvider.rows
        let originalCount = originalRows.count
        
        var sections = sectionProvider.sections
        sections.append(contentsOf: appendedItems)
        
        let updatedRows = orderedRows(for: sections)
        let updatedCount = updatedRows.count
        
        var insertedIndices = [Int]()
        for index in originalCount..<updatedCount {
            insertedIndices.append(index)
        }
        
        let sectionDelta = IndexDelta(deletions: [],
                                      insertions: insertedIndices,
                                      reloads: [],
                                      moves: [])
        
        let updateData = {
            sectionProvider.sections = sections
            sectionProvider.rows = updatedRows
        }
        
        view.performAnimations(sectionDelta: sectionDelta,
                               delegate: nil,
                               updateData: updateData,
                               completion: calculationCompletion)
    }
}

// MARK: Replay Delta onto data

private extension SectionDataCalculator {
    
    func dataWithMovesAndDeletions(byApplying appliedDeltas: IndexDelta, on updatedData: [SectionType], matching matchingData: [SectionType]) -> [SectionType] {
        var updatedSections = updatedData
        
        // Delete Items
        for deletedIndex in appliedDeltas.deletions.reversed() {
            updatedSections.remove(at: deletedIndex)
        }
        
        // Reorder
        return updatedSections.matchOrder(of: matchingData)
    }
    
    func dataWithInsertionsRemoved(byApplying appliedDeltas: IndexDelta, on updatedData: [SectionType]) -> [SectionType] {
        var updatedSections = updatedData
        
        // Remove Inserted Items
        for insertedIndex in appliedDeltas.insertions.reversed() {
            let item = updatedData[insertedIndex]
            guard let index = updatedSections.index(where: { $0.uniqueID == item.uniqueID }) else { continue }
            updatedSections.remove(at: index)
        }
        
        return updatedSections
    }
    
    func dataWithInsertionsAdded(byApplying appliedDeltas: IndexDelta, on originalData: [SectionType], from updatedData: [SectionType]) -> [SectionType] {
        var updatedSections = originalData
        
        // Add Inserted Items
        for insertedIndex in appliedDeltas.insertions {
            let item = updatedData[insertedIndex]
            updatedSections.insert(item, at: insertedIndex)
        }
        
        return updatedSections
    }
}

// MARK: - NSIndexPath Helpers

private extension SectionDataCalculator {
    
    func indexOffsets(for sections: [SectionType]) -> [Int] {
        var startingOffsets: [Int] = [0]
        
        var totalOffset = 0
        
        if sections.count > 1 {
            for i in 1..<sections.count {
                let offset = i - 1
                // the offset for the current section will be the previous sections count
                let section = sections[offset]
                totalOffset += section.items.count
                startingOffsets.append(totalOffset)
            }
        }
        
        return startingOffsets
    }
    
    func convertToRowIndexes(_ sections: [Int], for sectionItems: [SectionType]) -> [Int] {
        let startingIndexes = indexOffsets(for: sectionItems)
        var rowIndexes: [Int] = []
        
        for section in sections {
            let startingIndex = startingIndexes[section]
            
            let sectionItem = sectionItems[section]
            for i in 0..<sectionItem.items.count {
                let rowIndex = i + startingIndex
                rowIndexes.append(rowIndex)
            }
        }
        
        return rowIndexes.sorted()
    }
}

// MARK: - NSIndexPath Helpers

private extension SectionDataCalculator {
    
    func convertRowIndexesToIndexPaths(_ indexDelta: IndexDelta, sectionDelta: IndexDelta, originalSections: [SectionType], intermediateSections: [SectionType], targetSections: [SectionType]) -> IndexPathDelta {
        
        let originalStartingOffsets = indexOffsets(for: originalSections)
        let intermediateStartingOffsets = indexOffsets(for: intermediateSections)
        let targetStartingOffsets = indexOffsets(for: targetSections)
        
        func indexPath(for rowIndex: Int, in offsets: [Int]) -> IndexPath {
            var section = 0
            var row = 0
            
            let start = offsets.count-1
            for sectionIndex in stride(from: start, to: -1, by: -1) where rowIndex >= offsets[sectionIndex] {
                section = sectionIndex
                row = rowIndex - offsets[sectionIndex]
                break
            }
            
            return IndexPath(row: row, section: section)
        }
        
        // index adjustment
        func adjustSectionForInsertions(_ section: Int) -> Int {
            guard sectionDelta.insertions.count > 0 else {
                return section
            }
            
            var adjustedSection = section
            
            for insertedSection in sectionDelta.insertions where insertedSection <= adjustedSection {
                adjustedSection += 1
            }
            
            return adjustedSection
        }
        
        func convertSourceRowsToIndexPaths(_ rows: [Int]) -> [IndexPath] {
            
            var indexPaths: [IndexPath] = []
            
            for rowIndex in rows {
                let index = indexPath(for: rowIndex, in: intermediateStartingOffsets)
                let adjustedSection = adjustSectionForInsertions(index.section)
                let adjustedIndexPath = IndexPath(row: index.row, section: adjustedSection)
                indexPaths.append(adjustedIndexPath)
            }
            
            return indexPaths
        }
        
        func convertTargetRowsToIndexPaths(_ rows: [Int]) -> [IndexPath] {
            // calculate final index path
            var indexPaths: [IndexPath] = []
            
            for rowIndex in rows {
                let index = indexPath(for: rowIndex, in: targetStartingOffsets)
                let adjustedSection = adjustSectionForInsertions(index.section)
                let adjustedIndexPath = IndexPath(row: index.row, section: adjustedSection)
                indexPaths.append(adjustedIndexPath)
            }
            
            return indexPaths
        }
        
        func convertRowPairsToIndexPathPairs(_ indexPairRows: [IndexPair]) -> [IndexPathPair] {
            var indexPathPairs: [IndexPathPair] = []
            
            for indexPair in indexPairRows {
                let sourceIndexPaths = convertSourceRowsToIndexPaths([indexPair.source])
                let targetIndexPaths = convertTargetRowsToIndexPaths([indexPair.target])
                
                if sourceIndexPaths.count == 1 && targetIndexPaths.count == 1 {
                    let source = sourceIndexPaths[0]
                    let target = targetIndexPaths[0]
                    
                    let indexPathPair = IndexPathPair(source: source, target: target)
                    
                    indexPathPairs.append(indexPathPair)
                }
            }
            
            return indexPathPairs
        }
        
        func convertNecessaryMovesToReloads(reloads: [IndexPathPair], moves: [IndexPathPair]) -> (updatedReloads: [IndexPathPair], updatedMoves: [IndexPathPair]) {
            var updatedMoves: [IndexPathPair] = []
            var updatedReloads = reloads
            
            func adjustSectionByRemovingInsertions(_ section: Int) -> Int {
                let insertions = sectionDelta.insertions.reversed()
                guard insertions.isEmpty == false else {
                    return section
                }
                
                var adjustedSection = section
                
                for insertedSection in insertions where insertedSection <= adjustedSection {
                    adjustedSection -= 1
                }
                
                return adjustedSection
            }
            
            for move in moves {
                if move.source.section == move.target.section &&
                    move.source.row == move.target.row {
                    
                    // compare data
                    let adjustedSourceSection = adjustSectionByRemovingInsertions(move.source.section)
                    let adjustedTargetSection = adjustSectionByRemovingInsertions(move.target.section)
                    
                    let intermediateSection = intermediateSections[adjustedSourceSection]
                    let targetSection = targetSections[adjustedTargetSection]
                    
                    let intermediateItem = intermediateSection.items[move.source.row]
                    let targetItem = targetSection.items[move.target.row]
                    
                    if intermediateItem != targetItem {
                        updatedReloads.append(move)
                    }
                } else {
                    updatedMoves.append(move)
                }
            }
            
            return (updatedReloads: updatedReloads, updatedMoves: updatedMoves)
        }
        
        let deletedIndexPaths = convertSourceRowsToIndexPaths(indexDelta.deletions)
        let insertedIndexPaths = convertTargetRowsToIndexPaths(indexDelta.insertions)
        
        let reloadedIndexPathPairs = convertRowPairsToIndexPathPairs(indexDelta.reloads)
        let movedIndexPathPairs = convertRowPairsToIndexPathPairs(indexDelta.moves)
        
        let (updatedReloads, updatedMoves) = convertNecessaryMovesToReloads(reloads: reloadedIndexPathPairs, moves: movedIndexPathPairs)
        
        return IndexPathDelta(deletions: deletedIndexPaths,
                              insertions: insertedIndexPaths,
                              reloads: updatedReloads,
                              moves: updatedMoves)    }
}

// MARK: - Convenience

private extension Array where Element: UniquelyIdentifiable {
    
    mutating func matchOrder(of updatedData: [Element]) -> [Element] {
        var orderedItems: [Element] = []
        
        for updatedItem in updatedData {
            guard let index = index(where: { $0.uniqueID == updatedItem.uniqueID }) else { continue }
            let originalItem = self[index]
            orderedItems.append(originalItem)
        }
        
        return [Element](orderedItems)
    }
}
