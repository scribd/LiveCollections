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
    private let dataQueue = DispatchQueue(label: "\(SectionDataCalculator.self) dispatch queue")

    weak var calculationDelegate: CollectionDataCalculationNotificationDelegate?

    private var _isCalculating: Bool = false
    private var isCalculating: Bool {
        get { return dataQueue.sync { return _isCalculating } }
        set {
            dataQueue.async(flags: .barrier) {
                guard newValue != self._isCalculating else { return }
                self._isCalculating = newValue
                newValue ?
                    self.calculationDelegate?.collectionDataDidBeginCalculating() :
                    self.calculationDelegate?.collectionDataDidEndCalculating()
            }
        }
    }

    private let _orderedQueue = DataCalculatorQueue<SectionType>()
    private var orderedQueue: DataCalculatorQueue<SectionType> { return dataQueue.sync { return _orderedQueue } }
    
    private var complationCount = 0
    
    // MARK: API
    
    func updateAndAnimate<DeletionDelegate, SectionProvider>(_ updatedSections: [SectionType],
                                                             sectionProvider: SectionProvider,
                                                             view: SectionDeltaUpdatableView,
                                                             reloadDelegate: CollectionDataManualReloadDelegate?,
                                                             animationDelegate: CollectionSectionDataAnimationDelegate?,
                                                             deletionDelegate: DeletionDelegate?,
                                                             completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, SectionProvider: SectionDataProvider, SectionProvider: SectionCalculatingDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType, SectionProvider.CalculatingSectionType == SectionType {
        
        let calculation: DeltaOperationCalculation<SectionType> = { [weak self] sections in
            self?._updateAndAnimate(sections,
                                    sectionProvider: sectionProvider,
                                    view: view,
                                    reloadDelegate: reloadDelegate,
                                    animationDelegate: animationDelegate,
                                    deletionDelegate: deletionDelegate,
                                    completion: completion)
        }
        
        _processCalculation(updatedSections, action: .update, calculation: calculation)
    }
    
    func appendAndAnimate<SectionProvider>(_ appendedSections: [SectionType],
                                           sectionProvider: SectionProvider,
                                           view: SectionDeltaUpdatableView,
                                           reloadDelegate: CollectionDataManualReloadDelegate?,
                                           animationDelegate: CollectionSectionDataAnimationDelegate?,
                                           completion: (() -> Void)?) where SectionProvider: SectionDataProvider, SectionProvider: SectionCalculatingDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType, SectionProvider.CalculatingSectionType == SectionType {
        
        let calculation: DeltaOperationCalculation<SectionType> = { [weak self] sections in
            self?._appendAndAnimate(sections,
                                    sectionProvider: sectionProvider,
                                    view: view,
                                    reloadDelegate: reloadDelegate,
                                    animationDelegate: animationDelegate,
                                    completion: completion)
        }

        _processCalculation(appendedSections, action: .append, calculation: calculation)
    }
}

// MARK: - Private

private extension SectionDataCalculator {
    
    // MARK: Calculation Queue Management

    func _processCalculation(_ sections: [SectionType], action: DeltaOperationAction, calculation: @escaping DeltaOperationCalculation<SectionType>) {
        processingQueue.async {
            if self.isCalculating {
                let operation = DeltaOperation<SectionType>(data: sections, action: action, calculation: calculation)
                self.orderedQueue.setNext(operation)
            } else {
                self.isCalculating = true
                calculation(sections)
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
                                                              reloadDelegate: CollectionDataManualReloadDelegate?,
                                                              animationDelegate: CollectionSectionDataAnimationDelegate?,
                                                              deletionDelegate: DeletionDelegate?,
                                                              completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, SectionProvider: SectionDataProvider, SectionProvider: SectionCalculatingDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType, SectionProvider.CalculatingSectionType == SectionType {
        
        sectionProvider.calculatingSections = updatedSections

        let currentCount = sectionProvider.items.count
        let updatedCount = updatedSections.reduce(0) { $0 + $1.items.count }
        
        let dataSetTooLarge = currentCount > sectionProvider.dataCountAnimationThreshold ||
            updatedCount > sectionProvider.dataCountAnimationThreshold
        
        // sanitize data
        // Any empty sections will be removed
        let sanitizedUpdatedSections = updatedSections.filter { $0.items.isEmpty == false }
        
        // calculate deltas
        var sections = sectionProvider.sections
        let sectionDeltaCalculator = DeltaCalculator<SectionType>(startingData: sections, updatedData: sanitizedUpdatedSections)
        let (sectionDelta, deletedSections) = sectionDeltaCalculator.calculateSectionDelta()
        
        // determine deleted items (from the deleted sections)
        let deletedSectionItems = deletedSections.flatMap { $0.items }
        
        // determine inserted items (from the inserted sections)
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
        // this lets us determine all of the item actions that occurred with the (remaining) existing data
        
        sections = dataWithMovesAndDeletions(byApplying: sectionDelta, on: sections, matching: sanitizedUpdatedSections)
        sectionProvider.sections = sections
        
        var items = sectionProvider.orderedItems(for: sections)
        sectionProvider.items = items
        
        let intermediateSections = sections
        
        let targetSections = dataWithInsertionsRemoved(byApplying: sectionDelta, on: sanitizedUpdatedSections)
        let targetUpdatedItemData = targetSections.flatMap { $0.items }
        let targetUpdatedItems = [DataType](targetUpdatedItemData)
        
        let itemDelta: IndexDelta
        let deletedItems: [DataType]

        if dataSetTooLarge {
            itemDelta = .empty
            if reloadDelegate == nil {
                deletedItems = []
            } else {
                let itemDeltaCalculator = DeltaCalculator<DataType>(startingData: items, updatedData: targetUpdatedItems, includeIdenticalMoves: true)
                (deletedItems, _) = itemDeltaCalculator.deletedItems()
            }
        } else {
            let itemDeltaCalculator = DeltaCalculator<DataType>(startingData: items, updatedData: targetUpdatedItems, includeIdenticalMoves: true)
            (itemDelta, deletedItems) = itemDeltaCalculator.calculateItemDelta()
        }

        // ***********************************
        // RELATIVE DATA INTERMEDIATE STAGE 2
        // ***********************************
        
        // Now that we've calculated the item deltas, add just the section insertions to the original data set
        // (remember that we've already applied the deletions and moves) and trigger the section animations
        
        sections = dataWithInsertionsAdded(byApplying: sectionDelta, on: sections, from: sanitizedUpdatedSections)
        items = sectionProvider.orderedItems(for: sections)
        
        typealias SectionUpdateCompletion = () -> Void
        
        let performSectionUpdates: (SectionUpdateCompletion?) -> Void = { sectionUpdateCompletion in

            DispatchQueue.main.async {

                let sectionAnimationStlye: AnimationStyle = {
                    if view.frame.isEmpty { return .reloadData }
                    guard let animationDelegate = animationDelegate else { return .preciseAnimations }
                    return animationDelegate.preferredSectionAnimationStyle(for: sectionDelta)
                }()

                let sectionUpdateData = {
                    sectionProvider.sections = sections
                    sectionProvider.items = items
                }
                
                switch sectionAnimationStlye {
                case .reloadData:
                    sectionUpdateData()
                    view.reloadData()
                    sectionUpdateCompletion?()

                case .reloadSections,
                     .preciseAnimations:
                    let viewDelegate: SectionDeltaUpdatableViewDelegate? = {
                        if reloadDelegate == nil, animationDelegate == nil { return nil }
                        return AnySectionDeltaUpdatableViewDelegate(reloadDelegate: reloadDelegate, animationDelegate: animationDelegate)
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
            
            // finally we convert the item deltas that we calculated in MIS1 into index paths. This will include making
            // adjustments for the (then) missing inserted sections. Once those adjustments are made, trigger the item animations
            
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
            let deltaChangeTooLarge = itemDelta.changeCount > sectionProvider.deltaCountAnimationThreshold
            
            guard dataSetTooLarge == false && deltaChangeTooLarge == false else {
                
                let updateData = { [weak weakProvider = sectionProvider] in
                    guard let strongProvider = weakProvider else { return }
                    strongProvider.sections = sanitizedUpdatedSections
                    let items = strongProvider.orderedItems(for: sanitizedUpdatedSections)
                    strongProvider.items = items
                    strongProvider.calculatingSections = nil
                }
                
                DispatchQueue.main.async {
                    updateData()
                    view.reloadData()
                    calculationCompletion()
                }
                return
            }
            
            guard sectionDelta.hasChanges || itemDelta.hasChanges else {
                sectionProvider.calculatingSections = nil
                calculationCompletion()
                return // don't need to update with no changes
            }
            
            // convert item indices to NSIndexPaths
            let itemIndexPathDeltas = self.convertItemIndicesToIndexPaths(itemDelta, sectionDelta: sectionDelta, originalSections: originalSections, intermediateSections: intermediateSections, targetSections: targetSections)
            
            // finally we set our data with what was passed into the update() function
            sections = sanitizedUpdatedSections
            items = sectionProvider.orderedItems(for: sections)
            
            let updateData = {
                sectionProvider.sections = sections
                sectionProvider.items = items
                sectionProvider.calculatingSections = nil
            }

            DispatchQueue.main.async { [weak weakView = view] in

                guard let strongView = weakView else {
                    updateData()
                    calculationCompletion()
                    return
                }

                let itemAnimationStlye: AnimationStyle = {
                    if view.frame.isEmpty { return .reloadData }
                    guard let animationDelegate = animationDelegate else { return .preciseAnimations }
                    return animationDelegate.preferredItemAnimationStyle(for: itemDelta)
                }()

                switch itemAnimationStlye {
                case .reloadData:
                    updateData()
                    strongView.reloadData()
                    calculationCompletion()
                    
                case .reloadSections:
                    strongView.reloadAllSections(updateData: updateData, delegate: animationDelegate, completion: calculationCompletion)
                    
                case .preciseAnimations:
                    let viewDelegate: SectionDeltaUpdatableViewDelegate? = {
                        if reloadDelegate == nil, animationDelegate == nil { return nil }
                        return AnySectionDeltaUpdatableViewDelegate(reloadDelegate: reloadDelegate, animationDelegate: animationDelegate)
                    }()
                    strongView.performAnimations(sectionItemDelta: itemIndexPathDeltas,
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
                                            reloadDelegate: CollectionDataManualReloadDelegate?,
                                            animationDelegate: CollectionSectionDataAnimationDelegate?,
                                            completion: (() -> Void)?) where SectionProvider: SectionDataProvider, SectionProvider: SectionCalculatingDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType, SectionProvider.CalculatingSectionType == SectionType {
        
        sectionProvider.calculatingSections = appendedItems
        
        let calculationCompletion: () -> Void = { [weak self] in
            sectionProvider.calculatingSections = nil
            completion?()
            self?._performNextCalculation()
        }
        
        guard appendedItems.isEmpty == false else {
            sectionProvider.calculatingSections = nil
            calculationCompletion()
            return // don't need to update without any changes
        }

        let updatedSections = sectionProvider.sections + appendedItems
        let updatedItems = sectionProvider.orderedItems(for: updatedSections)
        
        let updateData = { [weak weakSectionProvider = sectionProvider] in
            guard let strongSectionProvider = weakSectionProvider else { return }
            strongSectionProvider.sections = updatedSections
            strongSectionProvider.items = updatedItems
            strongSectionProvider.calculatingSections = nil
        }

        let startingCount = sectionProvider.sections.count
        let insertedIndices = [Int](startingCount..<(startingCount + appendedItems.count))
        let sectionDelta = IndexDelta(insertions: insertedIndices)
        
        DispatchQueue.main.async { [weak weakSectionProvider = sectionProvider, weak weakView = view] in

            guard let strongSectionProvider = weakSectionProvider,
                let strongView = weakView else {
                updateData()
                calculationCompletion()
                return
            }

            let sectionAnimationStlye: AnimationStyle = {
                if view.frame.isEmpty { return .reloadData }
                guard let animationDelegate = animationDelegate else { return .preciseAnimations }
                return animationDelegate.preferredSectionAnimationStyle(for: sectionDelta)
            }()

            switch sectionAnimationStlye {
            case .reloadData:
                updateData()
                strongView.reloadData()
                calculationCompletion()

            case .reloadSections,
                 .preciseAnimations:
                if startingCount == 0 {
                    self._appendIndividuallyAndAnimate(appendedItems,
                                                       sectionProvider: strongSectionProvider,
                                                       view: strongView,
                                                       calculationCompletion: calculationCompletion)
                } else {
                    let viewDelegate: SectionDeltaUpdatableViewDelegate? = {
                        if reloadDelegate == nil, animationDelegate == nil { return nil }
                        return AnySectionDeltaUpdatableViewDelegate(reloadDelegate: reloadDelegate, animationDelegate: animationDelegate)
                    }()
                    view.performAnimations(sectionDelta: sectionDelta,
                                           delegate: viewDelegate,
                                           updateData: updateData,
                                           completion: calculationCompletion)

                }
            }
        }
    }
    
    func _appendIndividuallyAndAnimate<SectionProvider>(_ appendedItems: [SectionType],
                                                        sectionProvider: SectionProvider,
                                                        view: SectionDeltaUpdatableView,
                                                        calculationCompletion: (() -> Void)?) where SectionProvider: SectionDataProvider, SectionProvider: SectionCalculatingDataProvider, SectionProvider.SectionType == SectionType, SectionProvider.DataType == DataType {

        let startingIndex = sectionProvider.sections.count

        let lastIndex = appendedItems.count - 1
        appendedItems.enumerated().forEach { index, item in
            let isFinalItem = index == (appendedItems.count - 1)
            
            let completion: (() -> Void)? = isFinalItem ? calculationCompletion : nil
            let updateAppend = { [weak weakSectionProvider = sectionProvider] in
                guard let strongSectionProvider = weakSectionProvider else { return }
                
                strongSectionProvider.sections = strongSectionProvider.sections + [item]
                let updatedItems = sectionProvider.orderedItems(for: [item])
                strongSectionProvider.items = strongSectionProvider.items + updatedItems
                if index == lastIndex {
                    strongSectionProvider.calculatingSections = nil
                }
            }
            
            let insertedIndex = startingIndex + index
            let sectionDelta = IndexDelta(insertions: [insertedIndex])
            view.performAnimations(sectionDelta: sectionDelta,
                                   delegate: nil,
                                   updateData: updateAppend,
                                   completion: completion)
        }
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
            guard let index = updatedSections.firstIndex(where: { $0.uniqueID == item.uniqueID }) else { continue }
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
    
    func convertToItemIndices(_ sections: [Int], for sectionItems: [SectionType]) -> [Int] {
        let startingIndexes = indexOffsets(for: sectionItems)
        var itemIndices: [Int] = []
        
        for section in sections {
            let startingIndex = startingIndexes[section]
            
            let sectionItem = sectionItems[section]
            for i in 0..<sectionItem.items.count {
                let itemIndex = i + startingIndex
                itemIndices.append(itemIndex)
            }
        }
        
        return itemIndices.sorted()
    }
}

// MARK: - NSIndexPath Helpers

private extension SectionDataCalculator {
    
    func convertItemIndicesToIndexPaths(_ indexDelta: IndexDelta, sectionDelta: IndexDelta, originalSections: [SectionType], intermediateSections: [SectionType], targetSections: [SectionType]) -> IndexPathDelta {
        
        let intermediateStartingOffsets = indexOffsets(for: intermediateSections)
        let targetStartingOffsets = indexOffsets(for: targetSections)
        
        func indexPath(for itemIndex: Int, in offsets: [Int]) -> IndexPath {
            var section = 0
            var item = 0
            
            let start = offsets.count-1
            for sectionIndex in stride(from: start, to: -1, by: -1) where itemIndex >= offsets[sectionIndex] {
                section = sectionIndex
                item = itemIndex - offsets[sectionIndex]
                break
            }
            
            return IndexPath(item: item, section: section)
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
        
        func convertSourceItemsToIndexPaths(_ items: [Int]) -> [IndexPath] {
            
            var indexPaths: [IndexPath] = []
            
            for itemIndex in items {
                let index = indexPath(for: itemIndex, in: intermediateStartingOffsets)
                let adjustedSection = adjustSectionForInsertions(index.section)
                let adjustedIndexPath = IndexPath(item: index.item, section: adjustedSection)
                indexPaths.append(adjustedIndexPath)
            }
            
            return indexPaths
        }
        
        func convertTargetItemsToIndexPaths(_ items: [Int]) -> [IndexPath] {
            // calculate final index path
            var indexPaths: [IndexPath] = []
            
            for itemIndex in items {
                let index = indexPath(for: itemIndex, in: targetStartingOffsets)
                let adjustedSection = adjustSectionForInsertions(index.section)
                let adjustedIndexPath = IndexPath(item: index.item, section: adjustedSection)
                indexPaths.append(adjustedIndexPath)
            }
            
            return indexPaths
        }
        
        func convertItemPairsToIndexPathPairs(_ indexPairItems: [IndexPair]) -> [IndexPathPair] {
            var indexPathPairs: [IndexPathPair] = []
            
            for indexPair in indexPairItems {
                let sourceIndexPaths = convertSourceItemsToIndexPaths([indexPair.source])
                let targetIndexPaths = convertTargetItemsToIndexPaths([indexPair.target])
                
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
                    move.source.item == move.target.item {
                    
                    // compare data
                    let adjustedSourceSection = adjustSectionByRemovingInsertions(move.source.section)
                    let adjustedTargetSection = adjustSectionByRemovingInsertions(move.target.section)
                    
                    let intermediateSection = intermediateSections[adjustedSourceSection]
                    let targetSection = targetSections[adjustedTargetSection]
                    
                    let intermediateItem = intermediateSection.items[move.source.item]
                    let targetItem = targetSection.items[move.target.item]
                    
                    if intermediateItem != targetItem {
                        updatedReloads.append(move)
                    }
                } else {
                    updatedMoves.append(move)
                }
            }
            
            return (updatedReloads: updatedReloads, updatedMoves: updatedMoves)
        }
        
        let deletedIndexPaths = convertSourceItemsToIndexPaths(indexDelta.deletions)
        let insertedIndexPaths = convertTargetItemsToIndexPaths(indexDelta.insertions)
        
        let reloadedIndexPathPairs = convertItemPairsToIndexPathPairs(indexDelta.reloads)
        let movedIndexPathPairs = convertItemPairsToIndexPathPairs(indexDelta.moves)
        
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
            guard let index = firstIndex(where: { $0.uniqueID == updatedItem.uniqueID }) else { continue }
            let originalItem = self[index]
            orderedItems.append(originalItem)
        }
        
        return [Element](orderedItems)
    }
}
