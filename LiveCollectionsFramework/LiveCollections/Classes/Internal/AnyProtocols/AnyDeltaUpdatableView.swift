//
//  AnyDeltaUpdatableView.swift
//  LiveCollections
//
//  Created by Stephane Magne on 9/12/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

// MARK: - Generic Wrapper

final class AnyDeltaUpdatableView {
    private(set) weak var view: DeltaUpdatableView?

    private let _performReloadData: () -> Void
    private let _performReloadSections: ([SectionUpdate]) -> Void
    private let _performAnimations: (@escaping () -> Void, IndexDelta) -> Void
    private let _performAnimationsWithCompletion: (@escaping () -> Void, IndexDelta, Int, DeltaUpdatableViewDelegate?, (() -> Void)?) -> Void
    private let _performAnimationsForSectionUpdates: ([SectionUpdate]) -> Void

    init<V: DeltaUpdatableView>(_ view: V) {
        self.view = view
        
        _performReloadData = { [weak weakView = view] in
            weakView?.reloadData()
        }
        
        _performReloadSections = { [weak weakView = view] sectionUpdates in
            weakView?.reloadSections(for: sectionUpdates)
        }
        
        _performAnimations = { [weak weakView = view] update, delta in
            weakView?.performAnimations(updateData: update, delta: delta)
        }
        
        _performAnimationsWithCompletion = { [weak weakView = view] update, delta, section, delegate, completion in
            weakView?.performAnimations(updateData: update, delta: delta, section: section, delegate: delegate, completion: completion)
        }
        
        _performAnimationsForSectionUpdates = { [weak weakView = view] sectionUpdates in
            weakView?.performAnimations(for: sectionUpdates)
        }
    }
}

extension AnyDeltaUpdatableView: DeltaUpdatableView {

    func reloadData() { _performReloadData() }
    func reloadSections(for sectionUpdates: [SectionUpdate]) { _performReloadSections(sectionUpdates) }
    func performAnimations(updateData: @escaping () -> Void, delta: IndexDelta) { _performAnimations(updateData, delta) }
    func performAnimations(updateData: @escaping () -> Void, delta: IndexDelta, section: Int, delegate: DeltaUpdatableViewDelegate?, completion: (() -> Void)?) {
        _performAnimationsWithCompletion(updateData, delta, section, delegate, completion)
    }
    func performAnimations(for sectionUpdates: [SectionUpdate]) { _performAnimationsForSectionUpdates(sectionUpdates) }
}
