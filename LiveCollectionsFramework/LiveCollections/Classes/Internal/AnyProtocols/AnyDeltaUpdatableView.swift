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
    private let _performAnimations: (IndexDelta, @escaping () -> Void) -> Void
    private let _performAnimationsWithCompletion: (Int, IndexDelta, DeltaUpdatableViewDelegate?, @escaping () -> Void, (() -> Void)?) -> Void
    private let _performAnimationsForSectionUpdates: ([SectionUpdate]) -> Void

    init<V: DeltaUpdatableView>(_ view: V) {
        self.view = view
        
        _performReloadData = { [weak weakView = view] in
            weakView?.reloadData()
        }
        
        _performReloadSections = { [weak weakView = view] sectionUpdates in
            weakView?.reloadSections(for: sectionUpdates)
        }
        
        _performAnimations = { [weak weakView = view] delta, update in
            weakView?.performAnimations(delta: delta, updateData: update)
        }
        
        _performAnimationsWithCompletion = { [weak weakView = view] section, delta, delegate, update, completion in
            weakView?.performAnimations(section: section, delta: delta, delegate: delegate, updateData: update, completion: completion)
        }
        
        _performAnimationsForSectionUpdates = { [weak weakView = view] sectionUpdates in
            weakView?.performAnimations(for: sectionUpdates)
        }
    }
}

extension AnyDeltaUpdatableView: DeltaUpdatableView {

    func reloadData() { _performReloadData() }
    func reloadSections(for sectionUpdates: [SectionUpdate]) { _performReloadSections(sectionUpdates) }
    func performAnimations(delta: IndexDelta, updateData: @escaping () -> Void) { _performAnimations(delta, updateData) }
    func performAnimations(section: Int, delta: IndexDelta, delegate: DeltaUpdatableViewDelegate?, updateData: @escaping () -> Void, completion: (() -> Void)?) {
        _performAnimationsWithCompletion(section, delta, delegate, updateData, completion)
    }
    func performAnimations(for sectionUpdates: [SectionUpdate]) { _performAnimationsForSectionUpdates(sectionUpdates) }
}
