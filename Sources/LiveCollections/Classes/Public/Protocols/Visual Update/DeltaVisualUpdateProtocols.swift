//
//  DeltaVisualUpdateProtocols.swift
//  LiveCollections
//
//  Created by Stephane Magne on 7/10/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import CoreGraphics

public protocol CollectionViewProvider: AnyObject {
    var view: DeltaUpdatableView? { get set }
}

public protocol DeltaUpdatableViewDelegate: CollectionDataManualReloadDelegate, CollectionDataAnimationDelegate, CollectionViewProvider { }

public protocol SectionDeltaUpdatableViewDelegate: CollectionDataManualReloadDelegate, CollectionSectionDataAnimationDelegate { }

public protocol DeltaUpdatableView: AnyObject {

    /// Basic view frame getter
    var frame: CGRect { get }

    /// Basic reloadData function
    func reloadData()

    /**
     Calling this will perform a "smear" animation where data doesn't just blink into place, and gives the user
     some indication that data has changed, but without performing line item animations.
     */
    func reloadSections(for sectionUpdates: [SectionUpdate])

    /**
     Animate the view with the updatedData and delta.
     - parameter updateData: A closure in which the calling class must set its data. If the data is set before calling performAnimations, then
     you may end up causing a crash as the UITableView or UICollectionView have very specific timing needs for when the data must update.
     - parameter delta: The item delta (deletions, insertions, reloads, and moves)
     */
    func performAnimations(delta: IndexDelta, updateData: @escaping () -> Void)
    func performAnimations(section: Int, delta: IndexDelta, delegate: DeltaUpdatableViewDelegate?, updateData: @escaping () -> Void, completion: (() -> Void)?)
    func performAnimations(for sectionUpdates: [SectionUpdate])
}

public protocol SectionDeltaUpdatableView: AnyObject {
    
    /// Standard view frame getter
    var frame: CGRect { get }

    /// Basic reloadData function
    func reloadData()
    
    /**
     It is only safe to call this method if you only have reloads (no insertions or deletions)
     */
    func reloadAllSections(updateData: (() -> Void), delegate: CollectionSectionDataAnimationDelegate?, completion: (() -> Void)?)

    /**
     Similar to `DeltaUpdatableView`, but this is the delta for the sections themselves.
     */
    func performAnimations(sectionDelta: IndexDelta, delegate: SectionDeltaUpdatableViewDelegate?, updateData: (() -> Void), completion: (() -> Void)?)

    /**
     After the section animations have been performed, you can then call this function which will animate the items, possibly between sections.
     - note: IndexPathDelta is used instead of IndexDelta. Every position is defined by both section and item.
     */
    func performAnimations(sectionItemDelta itemIndexPathDelta: IndexPathDelta, delegate: SectionDeltaUpdatableViewDelegate?, updateData: (() -> Void), completion: (() -> Void)?)
}
