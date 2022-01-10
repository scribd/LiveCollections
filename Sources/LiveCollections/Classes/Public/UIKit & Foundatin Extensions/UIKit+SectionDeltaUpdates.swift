//
//  UIKit+SectionDeltaUpdates.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/15/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import UIKit

extension UITableView: SectionDeltaUpdatableView {
    
    public func performAnimations(sectionDelta: IndexDelta, delegate: SectionDeltaUpdatableViewDelegate?, updateData: (() -> Void), completion: (() -> Void)?) {
        
        guard sectionDelta.hasChanges, dataSource != nil else {
            updateData()
            completion?()
            return
        }
        
        guard isVisibleOnScreen else {
            updateData()
            reloadData()
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
            self.deleteSections(sectionDeletedIndexSet as IndexSet, with: self.preferredDeleteSectionAnimation)
            sectionDelta.moves.forEach { indexPair in
                self.moveSection(indexPair.source, toSection: indexPair.target)
            }
            self.insertSections(sectionInsertedIndexSet as IndexSet, with: self.preferredInsertSectionAnimation)
        }
        
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                updateData()
                guard let strongSelf = self else { return }
                guard strongSelf.isVisibleOnScreen else {
                    strongSelf.reloadData()
                    return
                }
                deleteMoveInsert()
                delegate?.animateAlongsideSectionUpdate(with: TimeInterval.standardCollectionAnimationDuration)
            }, completion: { _ in
                completion?()
            })
        } else {
            beginUpdates()
            updateData()
            deleteMoveInsert()
            delegate?.animateAlongsideSectionUpdate(with: TimeInterval.standardCollectionAnimationDuration)
            endUpdates()
            completion?()
        }
    }
    
    public func performAnimations(sectionItemDelta itemIndexPathDelta: IndexPathDelta, delegate: SectionDeltaUpdatableViewDelegate?, updateData: (() -> Void), completion: (() -> Void)?) {
        
        guard itemIndexPathDelta.hasChanges, dataSource != nil else {
            updateData()
            completion?()
            return
        }
        
        guard isVisibleOnScreen else {
            updateData()
            reloadData()
            completion?()
            return
        }
        
        var automaticReloadIndexPaths = [IndexPath]()
        var manualReloadIndexPaths = [IndexPath]()
        
        // Calculate manual reloads to pass down to the delegate
        itemIndexPathDelta.reloads.forEach { indexPathPair in
            if let delegate = delegate, delegate.willHandleReload(at: indexPathPair) {
                manualReloadIndexPaths.append(indexPathPair.target as IndexPath)
            } else {
                automaticReloadIndexPaths.append(indexPathPair.target as IndexPath)
            }
        }
        
        let deleteMoveInsert = {
            self.deleteRows(at: itemIndexPathDelta.deletions as [IndexPath], with: self.preferredDeleteRowAnimation)
            itemIndexPathDelta.moves.forEach { indexPathPair in
                self.moveRow(at: indexPathPair.source as IndexPath, to: indexPathPair.target as IndexPath)
            }
            self.insertRows(at: itemIndexPathDelta.insertions as [IndexPath], with: self.preferredInsertRowAnimation)
        }

        let reload = {
            // Reloads occur on original indexes
            // These need to be performed after the first animation is complete
            self.reloadRows(at: automaticReloadIndexPaths, with: self.preferredReloadRowAnimation)
        }
        
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                updateData()
                guard let strongSelf = self else { return }
                guard strongSelf.isVisibleOnScreen else {
                    strongSelf.reloadData()
                    return
                }
                deleteMoveInsert()
                delegate?.animateAlongsideUpdate(with: TimeInterval.standardCollectionAnimationDuration)
            }, completion: { [weak self] _ in
                guard let strongSelf = self else {
                    completion?()
                    return
                }
                strongSelf.performBatchUpdates({ [weak weakSelf = strongSelf] in
                    guard let strongSelf = weakSelf else { return }
                    guard strongSelf.isVisibleOnScreen else {
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
            guard isVisibleOnScreen else {
                reloadData()
                completion?()
                return
            }
            deleteMoveInsert()
            delegate?.animateAlongsideUpdate(with: TimeInterval.standardCollectionAnimationDuration)
            endUpdates()
            
            beginUpdates()
            guard isVisibleOnScreen else {
                reloadData()
                completion?()
                return
            }
            reload()
            endUpdates()
            
            manualReload(indexPaths: manualReloadIndexPaths, delegate: delegate, viewCompletion: completion)
        }
    }
    
    // NOTE: You can only call this method safely if you are only performing reloads
    //       i.e. no insertions or deletions
    public func reloadAllSections(updateData: (() -> Void), delegate: CollectionSectionDataAnimationDelegate?, completion: (() -> Void)?) {
        
        // UITableViews will crash if you attempt to reload from the empty state
        guard numberOfSections > 0, isVisibleOnScreen else {
            updateData()
            reloadData()
            completion?()
            return
        }
        
        if #available(iOS 11.0, *) {
            performBatchUpdates({ [weak self] in
                updateData()
                guard let strongSelf = self else { return }
                guard strongSelf.isVisibleOnScreen else {
                    strongSelf.reloadData()
                    return
                }
                guard let numberOfSections = strongSelf.dataSource?.numberOfSections?(in: strongSelf) else {
                    return
                }
                let sections = IndexSet(integersIn: 0..<numberOfSections)
                strongSelf.reloadSections(sections, with: strongSelf.preferredReloadSectionAnimation)
                delegate?.animateAlongsideSectionUpdate(with: TimeInterval.standardCollectionAnimationDuration)
            }, completion: { _ in
                completion?()
            })
                                
        } else {
            beginUpdates()
            updateData()
            guard isVisibleOnScreen else {
                reloadData()
                completion?()
                return
            }
            guard let numberOfSections = dataSource?.numberOfSections?(in: self) else {
                return
            }
            let sections = IndexSet(integersIn: 0..<numberOfSections)
            reloadSections(sections, with: preferredReloadSectionAnimation)
            delegate?.animateAlongsideSectionUpdate(with: TimeInterval.standardCollectionAnimationDuration)
            endUpdates()
            completion?()
        }
    }
}

// MARK: - Update Collection View

extension UICollectionView: SectionDeltaUpdatableView {
    
    public func performAnimations(sectionDelta: IndexDelta, delegate: SectionDeltaUpdatableViewDelegate?, updateData: (() -> Void), completion: (() -> Void)?) {

        guard sectionDelta.hasChanges, dataSource != nil else {
            updateData()
            completion?()
            return
        }
        
        guard isVisibleOnScreen else {
            updateData()
            reloadData()
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
            guard strongSelf.isVisibleOnScreen else {
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
            // delegate
            delegate?.animateAlongsideSectionUpdate(with: TimeInterval.standardCollectionAnimationDuration)
        }, completion: { _ in
            completion?()
        })
    }
    
    public func performAnimations(sectionItemDelta itemIndexPathDelta: IndexPathDelta, delegate: SectionDeltaUpdatableViewDelegate?, updateData: (() -> Void), completion: (() -> Void)?) {
        
        guard itemIndexPathDelta.hasChanges, dataSource != nil else {
            updateData()
            completion?()
            return
        }
        
        guard isVisibleOnScreen else {
            updateData()
            reloadData()
            completion?()
            return
        }
        
        var automaticReloadIndexPaths = [IndexPath]()
        var manualReloadIndexPaths = [IndexPath]()

        // Calculate manual reloads to pass down to the delegate
        itemIndexPathDelta.reloads.forEach { indexPathPair in
            if let delegate = delegate, delegate.willHandleReload(at: indexPathPair) {
                manualReloadIndexPaths.append(indexPathPair.target as IndexPath)
            } else {
                automaticReloadIndexPaths.append(indexPathPair.target as IndexPath)
            }
        }
        
        performBatchUpdates({ [weak self] in
            updateData()
            guard let strongSelf = self else { return }
            guard strongSelf.isVisibleOnScreen else {
                strongSelf.reloadData()
                return
            }
            strongSelf.deleteItems(at: itemIndexPathDelta.deletions as [IndexPath])
            itemIndexPathDelta.moves.forEach { indexPathPair in
                strongSelf.moveItem(at: indexPathPair.source as IndexPath, to: indexPathPair.target as IndexPath)
            }
            strongSelf.insertItems(at: itemIndexPathDelta.insertions as [IndexPath])
            delegate?.animateAlongsideUpdate(with: TimeInterval.standardCollectionAnimationDuration)
        }, completion: { [weak self] _ in
            guard let strongSelf = self else {
                completion?()
                return
            }
            strongSelf.performBatchUpdates({ [weak weakSelf = strongSelf] in
                guard let strongSelf = weakSelf else { return }
                guard strongSelf.isVisibleOnScreen else {
                    strongSelf.reloadData()
                    return
                }
                strongSelf.reloadItems(at: automaticReloadIndexPaths)
            }, completion: { _ in
                strongSelf.manualReload(indexPaths: manualReloadIndexPaths, delegate: delegate, viewCompletion: completion)
            })
        })
    }
    
    // NOTE: You can only call this method safely if you are only performing reloads
    //       i.e. no insertions or deletions
    public func reloadAllSections(updateData: (() -> Void), delegate: CollectionSectionDataAnimationDelegate?, completion: (() -> Void)?) {
        
        // UICollectionViews will crash if you attempt to reload from the empty state
        guard numberOfSections > 0, isVisibleOnScreen else {
            updateData()
            reloadData()
            completion?()
            return
        }

        performBatchUpdates({ [weak self] in
            updateData()
            guard let strongSelf = self else { return }
            guard strongSelf.isVisibleOnScreen else {
                strongSelf.reloadData()
                return
            }
            guard let numberOfSections = strongSelf.dataSource?.numberOfSections?(in: strongSelf) else {
                return
            }
            let sections = IndexSet(integersIn: 0..<numberOfSections)
            strongSelf.reloadSections(sections)
            delegate?.animateAlongsideSectionUpdate(with: TimeInterval.standardCollectionAnimationDuration)
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
        
        let completionQueue = DispatchQueue(label: "\(UITableView.self) sectionDeltaUpdates dispatch queue")
        var remainingIndexPaths = Set(indexPaths)
        
        DispatchQueue.main.async {
            delegate.reloadItems(at: indexPaths, indexPathCompletion: { indexPath in
                completionQueue.sync {
                    guard remainingIndexPaths.isEmpty == false else { return }
                    remainingIndexPaths.remove(indexPath)
                    guard remainingIndexPaths.isEmpty else { return }
                    viewCompletion?()
                }
            })
        }
        
    }
}

// MARK: UITableView + TableViewFixedRowAnimationProviding

extension UITableView {
    
    var preferredDeleteRowAnimation: UITableView.RowAnimation {
        guard let animationProviding = self as? TableViewFixedRowAnimationProviding else {
            return TableViewRowConstants.defaultDeleteAnimation
        }
        return animationProviding.deleteRowAnimation
    }
    
    var preferredInsertRowAnimation: UITableView.RowAnimation {
        guard let animationProviding = self as? TableViewFixedRowAnimationProviding else {
            return TableViewRowConstants.defaultInsertAnimation
        }
        return animationProviding.insertRowAnimation
    }
    
    var preferredReloadRowAnimation: UITableView.RowAnimation {
        guard let animationProviding = self as? TableViewFixedRowAnimationProviding else {
            return TableViewRowConstants.defaultReloadAnimation
        }
        return animationProviding.reloadRowAnimation
    }
}

// MARK: UITableView + TableViewFixedSectionAnimationProviding

extension UITableView {
    
    var preferredDeleteSectionAnimation: UITableView.RowAnimation {
        guard let animationProviding = self as? TableViewFixedSectionAnimationProviding else {
            return TableViewSectionConstants.defaultDeleteAnimation
        }
        return animationProviding.deleteSectionAnimation
    }
    
    var preferredInsertSectionAnimation: UITableView.RowAnimation {
        guard let animationProviding = self as? TableViewFixedSectionAnimationProviding else {
            return TableViewSectionConstants.defaultInsertAnimation
        }
        return animationProviding.insertSectionAnimation
    }
    
    var preferredReloadSectionAnimation: UITableView.RowAnimation {
        guard let animationProviding = self as? TableViewFixedSectionAnimationProviding else {
            return TableViewSectionConstants.defaultReloadAnimation
        }
        return animationProviding.reloadSectionAnimation
    }
}

// MARK: TableView Section Animation Constants

enum TableViewSectionConstants {
    static let defaultDeleteAnimation: UITableView.RowAnimation = .bottom
    static let defaultInsertAnimation: UITableView.RowAnimation = .fade
    static let defaultReloadAnimation: UITableView.RowAnimation = .none
}
