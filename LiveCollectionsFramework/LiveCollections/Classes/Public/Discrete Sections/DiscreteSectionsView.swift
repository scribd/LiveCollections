//
//  DiscreteSectionsView.swift
//  LiveCollections
//
//  Created by Stephane Magne on 7/10/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

/**
 This is a useful tool when:
 A collection/table view has multiple sections and each section maintains a fully independent set of data.
 Each data item only needs to be unique within a single section, and can be found in other sections.
 
 This means that each section is fully autonomous, and while it shares a single view it can be updated and
 animated indpendantly of the timing of other sections. The benefit of this is that you can maintain a fully
 separate data source for each section, keeping them fully siloed, while still getting the benefit of
 automatic aniamations.
 
 Normally, this design would be problematic and if data wasn't managed very carefully, animations triggered by
 other sections could cause timing issues where data is not fully in sync with what is represented in the view
 and a crash occurs.
 
 By wrapping your view with this class, it ensures that data updates and animations are aggregated together,
 triggered in the correct sequence, and data is always updated in concert with the correct animations.
 */

public final class DiscreteSectionsView: CollectionViewProvider {

    public weak var view: DeltaUpdatableView?
    
    private let animator = AnimationAggregator()
    
    public init(_ view: DeltaUpdatableView? = nil) {
        self.view = view
        self.animator.delegate = self
    }
}

// MARK: - DeltaUpdatableView

extension DiscreteSectionsView: DeltaUpdatableView {

    public func reloadData() {
        animator.forceDataUpdates()
        view?.reloadData()
    }
    
    public func reloadSections(for sectionUpdates: [SectionUpdate]) {
        sectionUpdates.forEach { animator.reload($0) }
    }
    
    public func performAnimations(delta: IndexDelta, updateData: @escaping () -> Void) {
        performAnimations(section: 0, delta: delta, delegate: nil, updateData: updateData, completion: nil)
    }
    
    public func performAnimations(section: Int, delta: IndexDelta, delegate: DeltaUpdatableViewDelegate?, updateData: @escaping () -> Void, completion: (() -> Void)?) {
        let sectionUpdate = SectionUpdate(section: section, delta: delta, delegate: delegate, update: updateData, completion: completion)
        performAnimations(for: [sectionUpdate])
    }
    
    public func performAnimations(for sectionUpdates: [SectionUpdate]) {
        sectionUpdates.forEach { animator.update($0) }
    }
}

// MARK: - AnimationAggregatorDelegate

extension DiscreteSectionsView: AnimationAggregatorDelegate {

    func updateView(with sectionUpdates: [SectionUpdate]) {
        view?.performAnimations(for: sectionUpdates)
    }
    
    func reloadViewSections(with sectionUpdates: [SectionUpdate]) {
        view?.reloadSections(for: sectionUpdates)
    }
}
