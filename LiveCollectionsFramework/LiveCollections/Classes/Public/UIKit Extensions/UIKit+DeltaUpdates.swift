//
//  UIKit+DeltaUpdates.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/15/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import UIKit

extension UITableView: DeltaUpdatableView {
    
    public func performAnimations(delta: IndexDelta, updateData: @escaping () -> Void) {
        performAnimations(section: 0, delta: delta, delegate: nil, updateData: updateData, completion: nil)
    }
    
    public func performAnimations(section: Int, delta: IndexDelta, delegate: DeltaUpdatableViewDelegate? = nil, updateData: @escaping () -> Void, completion: (() -> Void)? = nil) {
        let sectionUpdate = SectionUpdate(section: section, delta: delta, delegate: delegate, update: updateData, completion: completion)
        performAnimations(for: [sectionUpdate])
    }

    public func performAnimations(for sectionUpdates: [SectionUpdate]) {
        let tableViewUpdates: [EntireViewSectionUpdate] = sectionUpdates.map { update in
            let indexPathsToAnimate = IndexPathsToAnimate.build(for: update)
            return EntireViewSectionUpdate(sectionUpdate: update, indexPathsToAnimate: indexPathsToAnimate)
        }
        _performAnimations(for: tableViewUpdates)
    }

    private func _performAnimations(for tableViewUpdates: [EntireViewSectionUpdate]) {
        
        let hasChanges = tableViewUpdates.reduce(false) { $0 || $1.indexPathsToAnimate.hasChanges }
        guard hasChanges, dataSource != nil else {
            tableViewUpdates.forEach { $0.sectionUpdate.update() }
            tableViewUpdates.forEach { $0.sectionUpdate.completion?() }
            return
        }
        
        let deleteMoveInsert = { [weak self] in
            guard let strongSelf = self else { return }
            for update in tableViewUpdates {
                guard update.isDataSourceValid(for: strongSelf) else { continue }
                let delta = update.indexPathsToAnimate
                strongSelf.deleteRows(at: delta.deletedIndexPaths, with: .bottom)
                delta.movedIndexPathPairs.forEach { indexPathPair in
                    strongSelf.moveRow(at: indexPathPair.source as IndexPath, to: indexPathPair.target as IndexPath)
                }
                strongSelf.insertRows(at: delta.insertedIndexPaths, with: .fade)
            }
        }
        
        let reload = { [weak self] in
            guard let strongSelf = self else { return }
            // Reloads occur on original indexes
            // These need to be performed after the first animation is complete
            for update in tableViewUpdates {
                guard update.isDataSourceValid(for: strongSelf) else { continue }
                let delta = update.indexPathsToAnimate
                strongSelf.reloadRows(at: delta.automaticReloadIndexPaths, with: .fade)
            }
        }
        
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                tableViewUpdates.forEach { $0.sectionUpdate.update() }
                guard self != nil else { return }
                deleteMoveInsert()
            }, completion: { [weak self] animationsCompletedSuccessfully in
                guard let strongSelf = self else {
                    tableViewUpdates.forEach { $0.sectionUpdate.completion?() }
                    return
                }
                guard animationsCompletedSuccessfully else {
                    strongSelf.reloadData()
                    tableViewUpdates.forEach { $0.sectionUpdate.completion?() }
                    return
                }
                strongSelf.performBatchUpdates({ [weak weakSelf = strongSelf] in
                    guard weakSelf != nil else { return }
                    reload()
                }, completion: { [weak weakSelf = strongSelf] animationsCompletedSuccessfully in
                    guard let strongSelf = weakSelf else {
                        tableViewUpdates.forEach { $0.sectionUpdate.completion?() }
                        return
                    }
                    guard animationsCompletedSuccessfully else {
                        strongSelf.reloadData()
                        tableViewUpdates.forEach { $0.sectionUpdate.completion?() }
                        return
                    }

                    tableViewUpdates.manualReload(view: strongSelf) {
                        tableViewUpdates.forEach { $0.sectionUpdate.completion?() }
                    }
                })
            })
        } else {
            beginUpdates()
            tableViewUpdates.forEach { $0.sectionUpdate.update() }
            deleteMoveInsert()
            endUpdates()
            
            guard window != nil else {
                reloadData()
                tableViewUpdates.forEach { $0.sectionUpdate.completion?() }
                return
            }

            beginUpdates()
            reload()
            endUpdates()
            
            tableViewUpdates.manualReload(view: self) {
                tableViewUpdates.forEach { $0.sectionUpdate.completion?() }
            }
        }
    }
    
    public func reloadSections(for sectionUpdates: [SectionUpdate]) {
        
        let sections = sectionUpdates.map { $0.section }
        let indexSet = IndexSet(sections)
        
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                sectionUpdates.forEach { $0.update() }
                guard self != nil else { return }
                reloadSections(indexSet, with: .none)
            }, completion: { _ in
                sectionUpdates.forEach { $0.completion?() }
            })
        } else {
            beginUpdates()
            sectionUpdates.forEach { $0.update() }
            reloadSections(indexSet, with: .none)
            endUpdates()
            sectionUpdates.forEach { $0.completion?() }
        }
    }
}

// MARK: - Update Collection View

extension UICollectionView: DeltaUpdatableView {

    public func performAnimations(delta: IndexDelta, updateData: @escaping () -> Void) {
        performAnimations(section: 0, delta: delta, delegate: nil, updateData: updateData, completion: nil)
    }
    
    public func performAnimations(section: Int, delta: IndexDelta, delegate: DeltaUpdatableViewDelegate? = nil, updateData: @escaping () -> Void, completion: (() -> Void)? = nil) {
        let sectionUpdate = SectionUpdate(section: section, delta: delta, delegate: delegate, update: updateData, completion: completion)
        performAnimations(for: [sectionUpdate])
    }
    
    public func performAnimations(for sectionUpdates: [SectionUpdate]) {
        let collectionViewUpdates: [EntireViewSectionUpdate] = sectionUpdates.map { update in
            let indexPathsToAnimate = IndexPathsToAnimate.build(for: update)
            return EntireViewSectionUpdate(sectionUpdate: update, indexPathsToAnimate: indexPathsToAnimate)
        }
        _performAnimations(for: collectionViewUpdates)
    }
    
    private func _performAnimations(for collectionViewUpdates: [EntireViewSectionUpdate]) {

        let hasChanges = collectionViewUpdates.reduce(false) { $0 || $1.indexPathsToAnimate.hasChanges }
        guard hasChanges, dataSource != nil else {
            collectionViewUpdates.forEach { $0.sectionUpdate.update() }
            collectionViewUpdates.forEach { $0.sectionUpdate.completion?() }
            return
        }
        
        performBatchUpdates({ [weak self] in
            collectionViewUpdates.forEach { $0.sectionUpdate.update() }
            guard let strongSelf = self else { return }
            for update in collectionViewUpdates {
                guard update.isDataSourceValid(for: strongSelf) else { continue }
                let delta = update.indexPathsToAnimate
                strongSelf.deleteItems(at: delta.deletedIndexPaths)
                delta.movedIndexPathPairs.forEach { indexPathPair in
                    strongSelf.moveItem(at: indexPathPair.source as IndexPath, to: indexPathPair.target as IndexPath)
                }
                strongSelf.insertItems(at: delta.insertedIndexPaths)
            }
        }, completion: { [weak self] animationsCompletedSuccessfully in
            guard let strongSelf = self else {
                collectionViewUpdates.forEach { $0.sectionUpdate.completion?() }
                return
            }
            guard animationsCompletedSuccessfully else {
                strongSelf.reloadData()
                collectionViewUpdates.forEach { $0.sectionUpdate.completion?() }
                return
            }

            let filteredUpdates = collectionViewUpdates.filter { $0.isDataSourceValid(for: strongSelf) }
            guard filteredUpdates.isEmpty == false else {
                collectionViewUpdates.forEach { $0.sectionUpdate.completion?() }
                return
            }
            
            strongSelf.performBatchUpdates({ [weak weakSelf = strongSelf] in
                guard let strongSelf = weakSelf else { return }
                for update in filteredUpdates {
                    let delta = update.indexPathsToAnimate
                    strongSelf.reloadItems(at: delta.automaticReloadIndexPaths)
                }
            }, completion: { _ in
                collectionViewUpdates.manualReload(view: strongSelf) {
                    collectionViewUpdates.forEach { $0.sectionUpdate.completion?() }
                }
            })
        })
    }
    
    public func reloadSections(for sectionUpdates: [SectionUpdate]) {
        
        let sections = sectionUpdates.map { $0.section }
        let indexSet = IndexSet(sections)
        
        performBatchUpdates({ [weak self] in
            sectionUpdates.forEach { $0.update() }
            guard self != nil else { return }
            reloadSections(indexSet)
        }, completion: { _ in
            sectionUpdates.forEach { $0.completion?() }
        })
    }
}

// MARK: - Helper Methods

private struct Mapping {
    
    static func generateIndexToIndexPathMap(forSection section: Int) -> ((Int) -> IndexPath) {
        
        func indexToIndexPath(_ index: Int) -> IndexPath {
            return IndexPath(item: index, section: section)
        }
        
        return indexToIndexPath
    }
    
    static func generateIndexPairToIndexPathPairMapping(forSection section: Int) -> ((IndexPair) -> IndexPathPair) {
        
        func indexPairToIndexPathPair(_ indexPair: IndexPair) -> IndexPathPair {
            let sourceIndexPath = IndexPath(item: indexPair.source, section: section)
            let targetIndexPath = IndexPath(item: indexPair.target, section: section)
            return IndexPathPair(source: sourceIndexPath, target: targetIndexPath)
        }
        
        return indexPairToIndexPathPair
    }
}

// MARK: IndexPathsToAnimate

private struct EntireViewSectionUpdate {
    let sectionUpdate: SectionUpdate
    let indexPathsToAnimate: IndexPathsToAnimate
}

private struct IndexPathsToAnimate {

    let deletedIndexPaths: [IndexPath]
    let insertedIndexPaths: [IndexPath]
    let automaticReloadIndexPaths: [IndexPath]
    let manualReloadIndexPaths: [IndexPath]
    let movedIndexPathPairs: [IndexPathPair]
    
    static var empty: IndexPathsToAnimate {
        return IndexPathsToAnimate(deletedIndexPaths: [], insertedIndexPaths: [], automaticReloadIndexPaths: [], manualReloadIndexPaths: [], movedIndexPathPairs: [])
    }
    
    var hasChanges: Bool {
        return deletedIndexPaths.isEmpty == false
            || insertedIndexPaths.isEmpty == false
            || automaticReloadIndexPaths.isEmpty == false
            || manualReloadIndexPaths.isEmpty == false
            || movedIndexPathPairs.isEmpty == false
    }
}

private extension IndexPathsToAnimate {
    
    static func build(for sectionUpdate: SectionUpdate) -> IndexPathsToAnimate {
        
        let delta = sectionUpdate.delta
        let section = sectionUpdate.section
        
        guard delta.hasChanges else {
            return .empty
        }
        
        let indexToIndexPathMap = Mapping.generateIndexToIndexPathMap(forSection: section)
        let indexPairToIndexPathPair  = Mapping.generateIndexPairToIndexPathPairMapping(forSection: section)
        
        let insertedIndexPaths = delta.insertions.map(indexToIndexPathMap)
        let deletedIndexPaths = delta.deletions.map(indexToIndexPathMap)
        let movedIndexPathPairs = delta.moves.map(indexPairToIndexPathPair)
        
        var automaticReloadIndexPaths = [IndexPath]()
        var manualReloadIndexPaths = [IndexPath]()
        
        // Calculate manual reloads to pass down to the delegate
        delta.reloads.forEach { indexPair in
            let targetIndexPath = IndexPath(item: indexPair.target, section: section)
            if let delegate = sectionUpdate.delegate, delegate.willHandleReload(at: targetIndexPath) {
                manualReloadIndexPaths.append(targetIndexPath)
            } else {
                automaticReloadIndexPaths.append(targetIndexPath)
            }
        }
        
        return IndexPathsToAnimate(deletedIndexPaths: deletedIndexPaths,
                                   insertedIndexPaths: insertedIndexPaths,
                                   automaticReloadIndexPaths: automaticReloadIndexPaths,
                                   manualReloadIndexPaths: manualReloadIndexPaths,
                                   movedIndexPathPairs: movedIndexPathPairs)
    }
}

// MARK: Remove redundancy

private extension EntireViewSectionUpdate {

    func isDataSourceValid(for view: UIView) -> Bool {
        guard let sectionDelegate = sectionUpdate.delegate else { return true }
        if let synchronizer = sectionDelegate.view as? CollectionDataSynchronizer {
            return synchronizer.view === view
        } else {
            return sectionDelegate.view === view
        }
    }
}

private extension Array where Element == EntireViewSectionUpdate {

    func manualReload(view: UIView, viewCompletion: @escaping () -> Void) {
        
        let allManualReloadIndexPaths = filter { update in
            guard update.sectionUpdate.delegate != nil else { return false }
            guard update.isDataSourceValid(for: view) else { return false }
            guard update.indexPathsToAnimate.manualReloadIndexPaths.isEmpty == false else { return false }
            return true
            }.flatMap { $0.indexPathsToAnimate.manualReloadIndexPaths }
        
        guard allManualReloadIndexPaths.isEmpty == false else {
            viewCompletion()
            return
        }
        
        var remainingIndexPaths = Set(allManualReloadIndexPaths)
        
        let dispathQueue = DispatchQueue(label: "\(UITableView.self) itemDeltaUpdates dispatch queue")
        let completion: (IndexPath) -> Void = { indexPath in
            dispathQueue.sync {
                guard remainingIndexPaths.isEmpty == false else { return }
                remainingIndexPaths.remove(indexPath)
                guard remainingIndexPaths.isEmpty else { return }
                viewCompletion()
            }
        }
        
        self.forEach { update in
            guard let delegate = update.sectionUpdate.delegate else { return }
            guard update.isDataSourceValid(for: view) else { return }
            guard update.indexPathsToAnimate.manualReloadIndexPaths.isEmpty == false else { return }
            let delta = update.indexPathsToAnimate
            delegate.reloadItems(at: delta.manualReloadIndexPaths, completion: completion)
        }
    }
}
