//
//  AnyDeltaUpdatableViewDelegate.swift
//  LiveCollections
//
//  Created by Stephane Magne on 8/26/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

// MARK: - Generic Wrapper

protocol AnimationDelegateProviding {
    var animationDelegate: CollectionDataAnimationDelegate? { get }
}

final class AnyDeltaUpdatableViewDelegate: AnimationDelegateProviding {
    private(set) weak var reloadDelegate: CollectionDataManualReloadDelegate?
    private(set) weak var animationDelegate: CollectionDataAnimationDelegate?
    private(set) weak var viewProvider: CollectionViewProvider?

    init(reloadDelegate: CollectionDataManualReloadDelegate? = nil,
         animationDelegate: CollectionDataAnimationDelegate? = nil,
         viewProvider: CollectionViewProvider? = nil) {
        self.reloadDelegate = reloadDelegate
        self.animationDelegate = animationDelegate
        self.viewProvider = viewProvider
    }
}

extension AnyDeltaUpdatableViewDelegate: DeltaUpdatableViewDelegate {

    func willHandleReload(at indexPathPair: IndexPathPair) -> Bool {
        return reloadDelegate?.willHandleReload(at: indexPathPair) ?? false
    }

    func reloadItems(at indexPaths: [IndexPath], indexPathCompletion: @escaping (IndexPath) -> Void) {
        reloadDelegate?.reloadItems(at: indexPaths, indexPathCompletion: indexPathCompletion)
    }

    func preferredItemAnimationStyle(for itemDelta: IndexDelta) -> AnimationStyle {
        return animationDelegate?.preferredItemAnimationStyle(for: itemDelta) ?? .preciseAnimations
    }

    func animateAlongsideUpdate(with duration: TimeInterval) {
        animationDelegate?.animateAlongsideUpdate(with: duration)
    }

    var view: DeltaUpdatableView? {
        get { return viewProvider?.view }
        set { }
    }
}

// MARK: - Generic Section Wrapper

final class AnySectionDeltaUpdatableViewDelegate {
    private(set) weak var reloadDelegate: CollectionDataManualReloadDelegate?
    private(set) weak var animationDelegate: CollectionSectionDataAnimationDelegate?

    init(reloadDelegate: CollectionDataManualReloadDelegate? = nil,
         animationDelegate: CollectionSectionDataAnimationDelegate? = nil) {
        self.reloadDelegate = reloadDelegate
        self.animationDelegate = animationDelegate
    }
}

extension AnySectionDeltaUpdatableViewDelegate: SectionDeltaUpdatableViewDelegate {

    func willHandleReload(at indexPathPair: IndexPathPair) -> Bool {
        return reloadDelegate?.willHandleReload(at: indexPathPair) ?? false
    }

    func reloadItems(at indexPaths: [IndexPath], indexPathCompletion: @escaping (IndexPath) -> Void) {
        reloadDelegate?.reloadItems(at: indexPaths, indexPathCompletion: indexPathCompletion)
    }

    func preferredItemAnimationStyle(for itemDelta: IndexDelta) -> AnimationStyle {
        return animationDelegate?.preferredItemAnimationStyle(for: itemDelta) ?? .preciseAnimations
    }

    func animateAlongsideUpdate(with duration: TimeInterval) {
        animationDelegate?.animateAlongsideUpdate(with: duration)
    }

    func preferredSectionAnimationStyle(for sectionDelta: IndexDelta) -> AnimationStyle {
        return animationDelegate?.preferredSectionAnimationStyle(for: sectionDelta) ?? .preciseAnimations
    }

    func animateAlongsideSectionUpdate(with duration: TimeInterval) {
        animationDelegate?.animateAlongsideSectionUpdate(with: duration)
    }
}

