//
//  ItemDataCalculator.swift
//  LiveCollections
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

final class ItemDataCalculator<DataType: UniquelyIdentifiable> {
    
    // MARK: State
    
    private var processingQueue = DispatchQueue(label: "\(ItemDataCalculator.self) ordering queue")
    private let dataQueue = DispatchQueue(label: "\(ItemDataCalculator.self) dispatch queue")
    
    private var _isCalculating: Bool = false
    private var isCalculating: Bool {
        get { return dataQueue.sync { return _isCalculating } }
        set { dataQueue.async(flags: .barrier) { self._isCalculating = newValue } }
    }
    
    private let _orderedQueue = DataCalculatorQueue()
    private var orderedQueue: DataCalculatorQueue { return dataQueue.sync { return _orderedQueue } }
    
    // MARK: API
    
    func calculateDelta<ItemProvider>(_ updatedItems: [DataType],
                                      itemProvider: ItemProvider) -> IndexDelta where ItemProvider: ItemDataProvider, ItemProvider.DataType == DataType {
        
        let (delta, _) = _calculateDelta(updatedItems, itemProvider: itemProvider)
        return delta
    }
    
    func calculateAppendDelta<ItemProvider>(_ appendedItems: [DataType],
                                            itemProvider: ItemProvider) -> IndexDelta where ItemProvider: ItemDataProvider, ItemProvider.DataType == DataType {
        
        return _calculateAppendDelta(appendedItems, itemProvider: itemProvider)
    }
    
    func updateAndAnimate<DeletionDelegate, ItemProvider>(_ updatedItems: [DataType],
                                                          rawData: [DataType.RawType],
                                                          itemProvider: ItemProvider,
                                                          section: Int,
                                                          viewProvider: CollectionViewProvider,
                                                          reloadDelegate: CollectionDataManualReloadDelegate?,
                                                          deletionDelegate: DeletionDelegate?,
                                                          completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, ItemProvider: ItemDataProvider, ItemProvider: ItemCalculatingDataProvider, ItemProvider.DataType == DataType, ItemProvider.CalculatingRawType == DataType.RawType {
        
        _processCalculation { [weak self] in
            self?._updateAndAnimate(updatedItems,
                                    rawData: rawData,
                                    itemProvider: itemProvider,
                                    section: section,
                                    viewProvider: viewProvider,
                                    reloadDelegate: reloadDelegate,
                                    deletionDelegate: deletionDelegate,
                                    completion: completion)
        }
    }
    
    func appendAndAnimate<ItemProvider>(_ appendedItems: [DataType],
                                        rawData: [DataType.RawType],
                                        itemProvider: ItemProvider,
                                        section: Int,
                                        viewProvider: CollectionViewProvider,
                                        reloadDelegate: CollectionDataManualReloadDelegate?,
                                        completion: (() -> Void)?) where ItemProvider: ItemDataProvider, ItemProvider: ItemCalculatingDataProvider, ItemProvider.DataType == DataType, ItemProvider.CalculatingRawType == DataType.RawType {
        
        _processCalculation { [weak self] in
            self?._appendAndAnimate(appendedItems,
                                    rawData: rawData,
                                    itemProvider: itemProvider,
                                    section: section,
                                    viewProvider: viewProvider,
                                    reloadDelegate: reloadDelegate,
                                    completion: completion)
        }
    }
}

// MARK: - Private

private extension ItemDataCalculator {
    
    // MARK: Calculation Queue Management
    
    func _processCalculation(_ calculation: @escaping () -> Void) {
        processingQueue.async {
            if self.isCalculating == false {
                self.isCalculating = true
                calculation()
            } else {
                let operation = BlockOperation(block: calculation)
                self.orderedQueue.setNext(operation)
            }
        }
    }
    
    private func _performNextCalculation() {
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
    
    func _calculateDelta<ItemProvider>(_ updatedItems: [DataType],
                                       itemProvider: ItemProvider) -> (delta: IndexDelta, deletedItems: [DataType]) where ItemProvider: ItemDataProvider, ItemProvider.DataType == DataType {
        
        let deltaCalculator = DeltaCalculator<DataType>(startingData: itemProvider.items, updatedData: updatedItems)
        let (delta, deletedItems) = deltaCalculator.calculateItemDelta()
        
        return (delta: delta, deletedItems: deletedItems)
    }
    
    func _calculateAppendDelta<ItemProvider>(_ appendedItems: [DataType],
                                             itemProvider: ItemProvider) -> IndexDelta where ItemProvider: ItemDataProvider, ItemProvider.DataType == DataType {
        
        guard appendedItems.isEmpty == false else {
            return .empty
        }
        
        let originalCount = itemProvider.items.count
        let insertedItemIndices = [Int](originalCount..<(originalCount + appendedItems.count))
        let delta = IndexDelta(insertions: insertedItemIndices)
        return delta
    }
    
    func _updateAndAnimate<DeletionDelegate, ItemProvider>(_ updatedItems: [DataType],
                                                           rawData: [DataType.RawType],
                                                           itemProvider: ItemProvider,
                                                           section: Int,
                                                           viewProvider: CollectionViewProvider,
                                                           reloadDelegate: CollectionDataManualReloadDelegate?,
                                                           deletionDelegate: DeletionDelegate?,
                                                           completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, ItemProvider: ItemDataProvider, ItemProvider: ItemCalculatingDataProvider, ItemProvider.DataType == DataType, ItemProvider.CalculatingRawType == DataType.RawType {
        
        itemProvider.calculatingItems = rawData
        let view = viewProvider.view
        let viewDelegate = AnyDeltaUpdatableViewDelegate(reloadDelegate, viewProvider: viewProvider)

        let updateData = { [weak weakItemProvider = itemProvider, weak weakViewProvider = viewProvider] in
            guard let strongItemProvider = weakItemProvider,
                let strongViewProvider = weakViewProvider else { return }
            
            let updatedItems = [DataType](updatedItems)
            strongItemProvider.items = updatedItems
            strongItemProvider.calculatingItems = nil
            
            if view !== strongViewProvider.view {
                DispatchQueue.main.async { [weak weakViewProvider = viewProvider] in
                    weakViewProvider?.view?.reloadData()
                }
            }
        }
        
        // Short circuit if there are too many items
        
        let dataSetTooLarge = itemProvider.items.count > itemProvider.dataCountAnimationThreshold ||
            updatedItems.count > itemProvider.dataCountAnimationThreshold

        let delta: IndexDelta
        let deletedItems: [DataType]

        if dataSetTooLarge {
            delta = .empty
            deletedItems = []
        } else {
            (delta, deletedItems) = _calculateDelta(updatedItems, itemProvider: itemProvider)
        }
        
        let deltaChangeTooLarge = delta.changeCount > itemProvider.deltaCountAnimationThreshold
        
        guard deltaChangeTooLarge == false && deltaChangeTooLarge == false else {
            _updateSections(updatedItems,
                            itemProvider: itemProvider,
                            section: section,
                            viewProvider: viewProvider,
                            viewDelegate: viewDelegate,
                            deletionDelegate: deletionDelegate,
                            updateData: updateData,
                            completion: completion)
            return
        }
        
        // Otherwise animate
        
        let calculationCompletion: () -> Void = { [weak self, weak weakDeletionDelegate = deletionDelegate] in
            completion?()
            if deletedItems.isEmpty == false {
                weakDeletionDelegate?.didDeleteItems(deletedItems)
            }
            self?._performNextCalculation()
        }
        
        guard delta.hasChanges else {
            updateData()
            calculationCompletion()
            return
        }
        
        let itemAnimationStlye: AnimationStyle = {
            guard let reloadDelegate = reloadDelegate else { return .preciseAnimations }
            return reloadDelegate.preferredItemAnimationStyle(for: delta)
        }()
        
        DispatchQueue.main.async { [weak weakViewProvider = viewProvider] in
            guard let targetView = weakViewProvider?.view else {
                updateData()
                calculationCompletion()
                return
            }
            
            if targetView !== view {
                targetView.reloadData()
            }
            
            switch itemAnimationStlye {
            case .reloadData:
                updateData()
                targetView.reloadData()
                calculationCompletion()
                
            case .reloadSections:
                let sectionUpdate = SectionUpdate(section: section,
                                                  delta: delta,
                                                  delegate: viewDelegate,
                                                  update: updateData,
                                                  completion: calculationCompletion)
                targetView.reloadSections(for: [sectionUpdate])
                
            case .preciseAnimations:
                targetView.performAnimations(section: section,
                                             delta: delta,
                                             delegate: viewDelegate,
                                             updateData: updateData,
                                             completion: calculationCompletion)
            }
        }
    }
    
    func _appendAndAnimate<ItemProvider>(_ appendedItems: [DataType],
                                         rawData: [DataType.RawType],
                                         itemProvider: ItemProvider,
                                         section: Int,
                                         viewProvider: CollectionViewProvider,
                                         reloadDelegate: CollectionDataManualReloadDelegate?,
                                         completion: (() -> Void)?) where ItemProvider: ItemDataProvider, ItemProvider: ItemCalculatingDataProvider, ItemProvider.DataType == DataType, ItemProvider.CalculatingRawType == DataType.RawType {
        
        itemProvider.calculatingItems = rawData
        let view = viewProvider.view
        let viewDelegate = AnyDeltaUpdatableViewDelegate(viewProvider: viewProvider)
        let delta = _calculateAppendDelta(appendedItems, itemProvider: itemProvider)

        let updatedItems = itemProvider.items + appendedItems

        let updateData = { [weak weakItemProvider = itemProvider, weak weakViewProvider = viewProvider] in
            guard let strongItemProvider = weakItemProvider,
                let strongViewProvider = weakViewProvider else { return }
            
            strongItemProvider.items = updatedItems
            strongItemProvider.calculatingItems = nil
            
            if view !== strongViewProvider.view {
                DispatchQueue.main.async {
                    strongViewProvider.view?.reloadData()
                }
            }
        }
        
        let calculationCompletion: () -> Void = { [weak self] in
            completion?()
            self?._performNextCalculation()
        }

        // Short circuit if there are too many items

        let deltaChangeTooLarge = delta.changeCount > itemProvider.deltaCountAnimationThreshold
        
        guard deltaChangeTooLarge == false && deltaChangeTooLarge == false else {
            _updateSections(section: section,
                            viewProvider: viewProvider,
                            viewDelegate: viewDelegate,
                            updateData: updateData,
                            calculationCompletion: calculationCompletion)
            return
        }

        // Otherwise animate
        
        guard delta.hasChanges else {
            itemProvider.calculatingItems = nil
            calculationCompletion()
            return
        }
        
        let itemAnimationStlye: AnimationStyle = {
            guard let reloadDelegate = reloadDelegate else { return .preciseAnimations }
            return reloadDelegate.preferredItemAnimationStyle(for: delta)
        }()
        
        let startingItemCount = itemProvider.items.count
        
        DispatchQueue.main.async { [weak weakItemProvider = itemProvider, weak weakViewProvider = viewProvider] in
            guard let strongItemProvider = weakItemProvider,
                let strongViewProvider = weakViewProvider,
                let targetView = weakViewProvider?.view else {
                    updateData()
                    calculationCompletion()
                    return
            }
            
            if targetView !== view {
                targetView.reloadData()
            }
            
            switch itemAnimationStlye {
            case .reloadData:
                updateData()
                targetView.reloadData()
                calculationCompletion()
                
            case .reloadSections:
                let sectionUpdate = SectionUpdate(section: section,
                                                  delta: delta,
                                                  delegate: viewDelegate,
                                                  update: updateData,
                                                  completion: calculationCompletion)
                targetView.reloadSections(for: [sectionUpdate])
                
            case .preciseAnimations:
                if startingItemCount == 0 {
                    self._appendIndividuallyAndAnimate(appendedItems,
                                                       itemProvider: strongItemProvider,
                                                       section: section,
                                                       viewProvider: strongViewProvider,
                                                       calculationCompletion: calculationCompletion)
                } else {
                    // appen all and animate
                    targetView.performAnimations(section: section,
                                                 delta: delta,
                                                 delegate: viewDelegate,
                                                 updateData: updateData,
                                                 completion: calculationCompletion)
                }
            }
        }
    }
    
    func _appendIndividuallyAndAnimate<ItemProvider>(_ appendedItems: [DataType],
                                                     itemProvider: ItemProvider,
                                                     section: Int,
                                                     viewProvider: CollectionViewProvider,
                                                     calculationCompletion: (() -> Void)?) where ItemProvider: ItemDataProvider, ItemProvider: ItemCalculatingDataProvider, ItemProvider.DataType == DataType {
        
        let startingIndex = itemProvider.items.count
        let viewDelegate = AnyDeltaUpdatableViewDelegate(viewProvider: viewProvider)
        let view = viewProvider.view
        
        appendedItems.enumerated().forEach { index, item in
            let isFinalItem = index == (appendedItems.count - 1)
            
            let completion: (() -> Void)? = isFinalItem ? calculationCompletion : nil
            
            let updateAppend = { [weak weakItemProvider = itemProvider, weak weakViewProvider = viewProvider] in
                guard let strongItemProvider = weakItemProvider,
                    let strongViewProvider = weakViewProvider else { return }
                
                strongItemProvider.items = strongItemProvider.items + [item]
                strongItemProvider.calculatingItems = nil
                
                if view !== strongViewProvider.view {
                    strongViewProvider.view?.reloadData()
                }
            }
            
            let insertedIndex = startingIndex + index
            let delta = IndexDelta(insertions: [insertedIndex])
            view?.performAnimations(section: section,
                                    delta: delta,
                                    delegate: viewDelegate,
                                    updateData: updateAppend,
                                    completion: completion)
        }
    }
    
    // MARK: Short circuit and update section
    
    func _updateSections<DeletionDelegate, ItemProvider>(_ updatedItems: [DataType],
                                                         itemProvider: ItemProvider,
                                                         section: Int,
                                                         viewProvider: CollectionViewProvider,
                                                         viewDelegate: AnyDeltaUpdatableViewDelegate,
                                                         deletionDelegate: DeletionDelegate?,
                                                         updateData: @escaping () -> Void,
                                                         completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, ItemProvider: ItemDataProvider, ItemProvider: ItemCalculatingDataProvider, ItemProvider.DataType == DataType, ItemProvider.CalculatingRawType == DataType.RawType {

        let deletedItems: [DataType]
        if deletionDelegate == nil {
            deletedItems = []
        } else {
            let deltaCalculator = DeltaCalculator<DataType>(startingData: itemProvider.items, updatedData: updatedItems)
            (deletedItems, _) = deltaCalculator.deletedItems()
        }
        
        let calculationCompletion: () -> Void = { [weak self, weak weakDeletionDelegate = deletionDelegate] in
            completion?()
            if deletedItems.isEmpty == false {
                weakDeletionDelegate?.didDeleteItems(deletedItems)
            }
            self?._performNextCalculation()
        }

        _updateSections(section: section,
                        viewProvider: viewProvider,
                        viewDelegate: viewDelegate,
                        updateData: updateData,
                        calculationCompletion: calculationCompletion)
    }
    
    func _updateSections(section: Int,
                         viewProvider: CollectionViewProvider,
                         viewDelegate: AnyDeltaUpdatableViewDelegate,
                         updateData: @escaping () -> Void,
                         calculationCompletion: @escaping () -> Void) {

        let sectionUpdate = SectionUpdate(section: section,
                                          delta: .empty,
                                          delegate: viewDelegate,
                                          update: updateData,
                                          completion: calculationCompletion)

        
        DispatchQueue.main.async { [weak weakViewProvider = viewProvider] in
            guard let targetView = weakViewProvider?.view else {
                updateData()
                calculationCompletion()
                return
            }
            targetView.reloadSections(for: [sectionUpdate])
        }
    }
}
