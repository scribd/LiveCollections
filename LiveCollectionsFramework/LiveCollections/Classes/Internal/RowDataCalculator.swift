//
//  RowDataCalculator.swift
//  LiveCollections
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

final class RowDataCalculator<DataType: UniquelyIdentifiable> {

    // MARK: State
    
    private var processingQueue = DispatchQueue(label: "\(RowDataCalculator.self) ordering queue")
    private let dataQueue = DispatchQueue(label: "\(RowDataCalculator.self) dispatch queue", attributes: .concurrent)
    
    private var _isCalculating: Bool = false
    private var isCalculating: Bool {
        get { return dataQueue.sync { return _isCalculating } }
        set { dataQueue.async(flags: .barrier) { self._isCalculating = newValue } }
    }

    private let _orderedQueue = DataCalculatorQueue()
    private var orderedQueue: DataCalculatorQueue { return dataQueue.sync { return _orderedQueue } }
    
    // MARK: API

    func calculateDelta<RowProvider>(_ updatedRows: [DataType],
                                     rowProvider: RowProvider) -> IndexDelta where RowProvider: RowDataProvider, RowProvider.DataType == DataType {

        let (delta, _) = _calculateDelta(updatedRows, rowProvider: rowProvider)
        return delta
    }
    
    func calculateAppendDelta<RowProvider>(_ appendedItems: [DataType],
                                           rowProvider: RowProvider) -> IndexDelta where RowProvider: RowDataProvider, RowProvider.DataType == DataType {
        
        return _calculateAppendDelta(appendedItems, rowProvider: rowProvider)
    }
    
    func updateAndAnimate<DeletionDelegate, RowProvider>(_ updatedRows: [DataType],
                                                         rowProvider: RowProvider,
                                                         section: Int,
                                                         viewProvider: CollectionViewProvider,
                                                         reloadDelegate: CollectionDataManualReloadDelegate?,
                                                         deletionDelegate: DeletionDelegate?,
                                                         completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, RowProvider: RowDataProvider, RowProvider.DataType == DataType {
        
        _processCalculation { [weak self] in
            self?._updateAndAnimate(updatedRows,
                                    rowProvider: rowProvider,
                                    section: section,
                                    viewProvider: viewProvider,
                                    reloadDelegate: reloadDelegate,
                                    deletionDelegate: deletionDelegate,
                                    completion: completion)
        }
    }
    
    func appendAndAnimate<RowProvider>(_ appendedItems: [DataType],
                                       rowProvider: RowProvider,
                                       section: Int,
                                       viewProvider: CollectionViewProvider,
                                       completion: (() -> Void)?) where RowProvider: RowDataProvider, RowProvider.DataType == DataType {
        
        _processCalculation { [weak self] in
            self?._appendAndAnimate(appendedItems,
                                    rowProvider: rowProvider,
                                    section: section,
                                    viewProvider: viewProvider,
                                    completion: completion)
        }
    }
}

// MARK: - Private

private extension RowDataCalculator {
    
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
    
    func _calculateDelta<RowProvider>(_ updatedRows: [DataType],
                                      rowProvider: RowProvider) -> (delta: IndexDelta, deletedItems: [DataType]) where RowProvider: RowDataProvider, RowProvider.DataType == DataType {
        
        let deltaCalculator = DeltaCalculator<DataType>(startingData: rowProvider.rows, updatedData: updatedRows)
        let (delta, deletedItems) = deltaCalculator.calculateRowDelta()
        
        return (delta: delta, deletedItems: deletedItems)
    }
    
    func _calculateAppendDelta<RowProvider>(_ appendedItems: [DataType],
                                            rowProvider: RowProvider) -> IndexDelta where RowProvider: RowDataProvider, RowProvider.DataType == DataType {
        
        guard appendedItems.isEmpty == false else {
            return .empty
        }
        
        var rows = rowProvider.rows
        let originalCount = rows.count
        rows.append(contentsOf: appendedItems)
        
        let updatedCount = rows.count
        
        var insertedRowIndexes = [Int]()
        for index in originalCount..<updatedCount {
            insertedRowIndexes.append(index)
        }
        
        let delta = IndexDelta(deletions: [],
                               insertions: insertedRowIndexes,
                               reloads: [],
                               moves: [])
        return delta
    }
    
    func _updateAndAnimate<DeletionDelegate, RowProvider>(_ updatedRows: [DataType],
                                                          rowProvider: RowProvider,
                                                          section: Int,
                                                          viewProvider: CollectionViewProvider,
                                                          reloadDelegate: CollectionDataManualReloadDelegate?,
                                                          deletionDelegate: DeletionDelegate?,
                                                          completion: (() -> Void)?) where DeletionDelegate: CollectionDataDeletionNotificationDelegate, DeletionDelegate.DataType == DataType, RowProvider: RowDataProvider, RowProvider.DataType == DataType {
        
        let view = viewProvider.view
        
        let updateData = { [weak weakRowProvider = rowProvider, weak weakViewProvider = viewProvider] in
            guard let strongRowProvider = weakRowProvider,
                let strongViewProvider = weakViewProvider else { return }
            
            let updatedRows = [DataType](updatedRows)
            strongRowProvider.rows = updatedRows
            
            if view !== strongViewProvider.view {
                DispatchQueue.main.async { [weak weakViewProvider = viewProvider] in
                    weakViewProvider?.view?.reloadData()
                }
            }
        }

        let viewDelegate = AnyDeltaUpdatableViewDelegate(reloadDelegate,
                                                         viewProvider: viewProvider)

        // Short circuit if there are too many rows
        
        guard rowProvider.rows.count <= rowProvider.dataCountAnimationThreshold &&
            updatedRows.count <= rowProvider.dataCountAnimationThreshold else {

                let deletedItems: [DataType]
                if deletionDelegate == nil {
                    deletedItems = []
                } else {
                    let deltaCalculator = DeltaCalculator<DataType>(startingData: rowProvider.rows, updatedData: updatedRows)
                    (deletedItems, _) = deltaCalculator.deletedRows()
                }

                let calculationCompletion: () -> Void = { [weak self, weak weakDeletionDelegate = deletionDelegate] in
                    completion?()
                    if deletedItems.isEmpty == false {
                        weakDeletionDelegate?.didDeleteItems(deletedItems)
                    }
                    self?._performNextCalculation()
                }
                
                let sectionUpdate = SectionUpdate(section: section,
                                                 delta: .empty,
                                                 update: updateData,
                                                 delegate: viewDelegate,
                                                 completion: calculationCompletion)

                DispatchQueue.main.async { [weak weakViewProvider = viewProvider] in
                    guard let targetView = weakViewProvider?.view else {
                        updateData()
                        calculationCompletion()
                        return
                    }
                    targetView.reloadSections(for: [sectionUpdate])
                }
                return
        }

        // Otherwise, calculate
        
        let (delta, deletedItems) = _calculateDelta(updatedRows, rowProvider: rowProvider)
        
        let calculationCompletion: () -> Void = { [weak self, weak weakDeletionDelegate = deletionDelegate] in
            completion?()
            if deletedItems.isEmpty == false {
                weakDeletionDelegate?.didDeleteItems(deletedItems)
            }
            self?._performNextCalculation()
        }
        
        guard delta.hasChanges else {
            calculationCompletion()
            return
        }
        
        let rowAnimationStlye: AnimationStyle = {
            guard let reloadDelegate = reloadDelegate else { return .preciseAnimations }
            return reloadDelegate.preferredRowAnimationStyle(for: delta)
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

            switch rowAnimationStlye {
            case .reloadData:
                updateData()
                targetView.reloadData()
                calculationCompletion()
                
            case .reloadSections:
                let sectionUpdate = SectionUpdate(section: section,
                                                  delta: delta,
                                                  update: updateData,
                                                  delegate: viewDelegate,
                                                  completion: calculationCompletion)
                targetView.reloadSections(for: [sectionUpdate])
                
            case .preciseAnimations:
                targetView.performAnimations(updateData: updateData,
                                             delta: delta,
                                             section: section,
                                             delegate: viewDelegate,
                                             completion: calculationCompletion)
            }
        }
    }
    
    func _appendAndAnimate<RowProvider>(_ appendedItems: [DataType],
                                        rowProvider: RowProvider,
                                        section: Int,
                                        viewProvider: CollectionViewProvider,
                                        completion: (() -> Void)?) where RowProvider: RowDataProvider, RowProvider.DataType == DataType {
        
        // Note: we don't short circuit for appending, because there is no calculation, it costs nothing to determine the delta
        
        let view = viewProvider.view
        let delta = _calculateAppendDelta(appendedItems, rowProvider: rowProvider)
        
        let calculationCompletion: () -> Void = { [weak self] in
            completion?()
            self?._performNextCalculation()
        }
        
        guard delta.hasChanges else {
            calculationCompletion()
            return
        }

        let updateData = { [weak weakRowProvider = rowProvider, weak weakViewProvider = viewProvider] in
            guard let strongRowProvider = weakRowProvider,
                let strongViewProvider = weakViewProvider else { return }
            
            var rows = strongRowProvider.rows
            rows.append(contentsOf: appendedItems)
            strongRowProvider.rows = rows
            
            if view !== strongViewProvider.view {
                DispatchQueue.main.async {
                    strongViewProvider.view?.reloadData()
                }
            }
        }
        
        let viewDelegate = AnyDeltaUpdatableViewDelegate(viewProvider: viewProvider)
        DispatchQueue.main.async { [weak weakViewProvider = viewProvider] in
            guard let targetView = weakViewProvider?.view else {
                updateData()
                return
            }
            
            if targetView !== view {
                targetView.reloadData()
            }
            
            targetView.performAnimations(updateData: updateData,
                                         delta: delta,
                                         section: section,
                                         delegate: viewDelegate,
                                         completion: calculationCompletion)
        }
    }
}
