//
//  UIKit+SectionDeltaUpdates.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/15/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import UIKit

extension UITableView: SectionDeltaUpdatableView {
    
    public func performAnimations(updateData: (() -> Void), sectionDelta: IndexDelta, delegate: CollectionDataManualReloadDelegate?, completion: (() -> Void)?) {
        
        guard sectionDelta.hasChanges, dataSource != nil else {
            updateData()
            completion?()
            return
        }
        
        // deleted sections
        let sectionDeletedIndexSet = NSMutableIndexSet()
        sectionDelta.deletions.forEach { deletion in
            sectionDeletedIndexSet.add(deletion)
        }
        
        // inserted sections
        let sectionInsertedIndexSet = NSMutableIndexSet()
        sectionDelta.insertions.forEach { insertion in
            sectionInsertedIndexSet.add(insertion)
        }
        
        let deleteMoveInsert = {
            self.deleteSections(sectionDeletedIndexSet as IndexSet, with: .top)
            sectionDelta.moves.forEach { indexPair in
                self.moveSection(indexPair.source, toSection: indexPair.target)
            }
            self.insertSections(sectionInsertedIndexSet as IndexSet, with: .top)
        }
        
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                updateData()
                guard let strongSelf = self else { return }
                guard strongSelf.window != nil else {
                    strongSelf.reloadData()
                    return
                }
                deleteMoveInsert()
            }, completion: { _ in
                completion?()
            })
        } else {
            beginUpdates()
            updateData()
            deleteMoveInsert()
            endUpdates()
            completion?()
        }
    }
    
    public func performAnimations(updateData: (() -> Void), sectionRowDelta rowIndexPathDelta: IndexPathDelta, delegate: CollectionDataManualReloadDelegate?, completion: (() -> Void)?) {
        
        guard rowIndexPathDelta.hasChanges, dataSource != nil else {
            updateData()
            completion?()
            return
        }
        
        var automaticReloadIndexPaths = [IndexPath]()
        var manualReloadIndexPaths = [IndexPath]()
        
        // Calculate manual reloads to pass down to the delegate
        rowIndexPathDelta.reloads.forEach { indexPathPair in
            if let delegate = delegate, delegate.willHandleReload(at: indexPathPair.target) {
                manualReloadIndexPaths.append(indexPathPair.target as IndexPath)
            } else {
                automaticReloadIndexPaths.append(indexPathPair.target as IndexPath)
            }
        }
        
        let deleteMoveInsert = {
            self.deleteRows(at: rowIndexPathDelta.deletions as [IndexPath], with: .top)
            rowIndexPathDelta.moves.forEach { indexPathPair in
                self.moveRow(at: indexPathPair.source as IndexPath, to: indexPathPair.target as IndexPath)
            }
            self.insertRows(at: rowIndexPathDelta.insertions as [IndexPath], with: .top)
        }

        let reload = {
            // Reloads occur on original indexes
            // These need to be performed after the first animation is complete
            self.reloadRows(at: automaticReloadIndexPaths, with: .fade)
        }
        
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                updateData()
                guard let strongSelf = self else { return }
                guard strongSelf.window != nil else {
                    strongSelf.reloadData()
                    return
                }
                deleteMoveInsert()
            }, completion: { [weak self] _ in
                guard let strongSelf = self else {
                    completion?()
                    return
                }
                strongSelf.performBatchUpdates({ [weak weakSelf = strongSelf] in
                    guard let strongSelf = weakSelf else { return }
                    guard strongSelf.window != nil else {
                        strongSelf.reloadData()
                        return
                    }
                    reload()
                }, completion: { _ in
                    strongSelf.manualReload(indexPaths: manualReloadIndexPaths, delegate: delegate, viewCompletion: completion)
                })
            })
        } else {
            beginUpdates()
            updateData()
            guard window != nil else {
                reloadData()
                completion?()
                return
            }
            deleteMoveInsert()
            endUpdates()
            
            beginUpdates()
            guard window != nil else {
                reloadData()
                completion?()
                return
            }
            reload()
            endUpdates()
            
            manualReload(indexPaths: manualReloadIndexPaths, delegate: delegate, viewCompletion: completion)
        }
    }
    
    public func reloadAllSections(updateData: (() -> Void), completion: (() -> Void)?) {
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                updateData()
                guard let strongSelf = self else { return }
                guard strongSelf.window != nil else {
                    strongSelf.reloadData()
                    return
                }
                guard let numberOfSections = strongSelf.dataSource?.numberOfSections?(in: strongSelf) else {
                    return
                }
                let sections = IndexSet(integersIn: 0..<numberOfSections)
                strongSelf.reloadSections(sections, with: .none)
            }, completion: { _ in
                completion?()
            })
                                
        } else {
            beginUpdates()
            updateData()
            guard window != nil else {
                reloadData()
                completion?()
                return
            }
            guard let numberOfSections = dataSource?.numberOfSections?(in: self) else {
                return
            }
            let sections = IndexSet(integersIn: 0..<numberOfSections)
            reloadSections(sections, with: .none)
            endUpdates()
            completion?()
        }
    }
}

// MARK: - Update Collection View

extension UICollectionView: SectionDeltaUpdatableView {
    
    public func performAnimations(updateData: (() -> Void), sectionDelta: IndexDelta, delegate: CollectionDataManualReloadDelegate?, completion: (() -> Void)?) {

        guard sectionDelta.hasChanges, dataSource != nil else {
            updateData()
            completion?()
            return
        }
        
        // deleted sections
        let sectionDeletedIndexSet = NSMutableIndexSet()
        sectionDelta.deletions.forEach { deletion in
            sectionDeletedIndexSet.add(deletion)
        }
        
        // inserted sections
        let sectionInsertedIndexSet = NSMutableIndexSet()
        sectionDelta.insertions.forEach { insertion in
            sectionInsertedIndexSet.add(insertion)
        }
        
        performBatchUpdates({ [weak self] in
            updateData()
            guard let strongSelf = self else { return }
            guard strongSelf.window != nil else {
                strongSelf.reloadData()
                return
            }
            // delete
            strongSelf.deleteSections(sectionDeletedIndexSet as IndexSet)
            // move
            sectionDelta.moves.forEach { indexPair in
                strongSelf.moveSection(indexPair.source, toSection: indexPair.target)
            }
            // insert
            strongSelf.insertSections(sectionInsertedIndexSet as IndexSet)
        }, completion: { _ in
            completion?()
        })
    }
    
    public func performAnimations(updateData: (() -> Void), sectionRowDelta rowIndexPathDelta: IndexPathDelta, delegate: CollectionDataManualReloadDelegate?, completion: (() -> Void)?) {
        
        guard rowIndexPathDelta.hasChanges, dataSource != nil else {
            completion?()
            return
        }
        
        var automaticReloadIndexPaths = [IndexPath]()
        var manualReloadIndexPaths = [IndexPath]()

        // Calculate manual reloads to pass down to the delegate
        rowIndexPathDelta.reloads.forEach { indexPathPair in
            if let delegate = delegate, delegate.willHandleReload(at: indexPathPair.target) {
                manualReloadIndexPaths.append(indexPathPair.target as IndexPath)
            } else {
                automaticReloadIndexPaths.append(indexPathPair.target as IndexPath)
            }
        }
        
        performBatchUpdates({ [weak self] in
            updateData()
            guard let strongSelf = self else { return }
            guard strongSelf.window != nil else {
                strongSelf.reloadData()
                return
            }
            strongSelf.deleteItems(at: rowIndexPathDelta.deletions as [IndexPath])
            rowIndexPathDelta.moves.forEach { indexPathPair in
                strongSelf.moveItem(at: indexPathPair.source as IndexPath, to: indexPathPair.target as IndexPath)
            }
            strongSelf.insertItems(at: rowIndexPathDelta.insertions as [IndexPath])
        }, completion: { [weak self] _ in
            guard let strongSelf = self else {
                completion?()
                return
            }
            strongSelf.performBatchUpdates({ [weak weakSelf = strongSelf] in
                guard let strongSelf = weakSelf else { return }
                guard strongSelf.window != nil else {
                    strongSelf.reloadData()
                    return
                }
                strongSelf.reloadItems(at: automaticReloadIndexPaths)
            }, completion: { _ in
                strongSelf.manualReload(indexPaths: manualReloadIndexPaths, delegate: delegate, viewCompletion: completion)
            })
        })
    }
    
    public func reloadAllSections(updateData: (() -> Void), completion: (() -> Void)?) {
        performBatchUpdates({ [weak self] in
            updateData()
            guard let strongSelf = self else { return }
            guard strongSelf.window != nil else {
                strongSelf.reloadData()
                return
            }
            guard let numberOfSections = strongSelf.dataSource?.numberOfSections?(in: strongSelf) else {
                return
            }
            let sections = IndexSet(integersIn: 0..<numberOfSections)
            strongSelf.reloadSections(sections)
        }, completion: { _ in
            completion?()
        })
    }
}

private extension UIView {
    
    func manualReload(indexPaths: [IndexPath], delegate: CollectionDataManualReloadDelegate?, viewCompletion: (() -> Void)?) {
        
        guard let delegate = delegate, indexPaths.isEmpty == false else {
            viewCompletion?()
            return
        }
        
        let dispathQueue = DispatchQueue(label: "\(UITableView.self) sectionDeltaUpdates dispatch queue")
        var remainingIndexPaths = Set(indexPaths)
        
        delegate.reloadItems(at: indexPaths, completion: { indexPath in
            dispathQueue.sync {
                guard remainingIndexPaths.isEmpty == false else { return }
                remainingIndexPaths.remove(indexPath)
                guard remainingIndexPaths.isEmpty else { return }
                viewCompletion?()
            }
        })
        
    }
}
