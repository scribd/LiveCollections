//
//  AnyDeltaUpdatableViewDelegate.swift
//  LiveCollections
//
//  Created by Stephane Magne on 8/26/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

// MARK: - Generic Wrapper

final class AnyDeltaUpdatableViewDelegate {
    private let _getItemWillHandleReload: ((IndexPathPair) -> Bool)
    private let _performReloadItems: (([IndexPath], @escaping (IndexPath) -> Void) -> Void)
    private let _getPreferredItemAnimationStyle: ((IndexDelta) -> AnimationStyle)
    private let _getView: (() -> DeltaUpdatableView?)

    init(_ delegate: CollectionDataManualReloadDelegate? = nil, viewProvider: CollectionViewProvider? = nil) {
        _getItemWillHandleReload = { [weak weakDelegate = delegate] indexPathPair in
            return weakDelegate?.willHandleReload(at: indexPathPair) ?? false
        }
        
        _performReloadItems = { [weak weakDelegate = delegate] indexPaths, completion in
            weakDelegate?.reloadItems(at: indexPaths, completion: completion)
        }
        
        _getPreferredItemAnimationStyle = { [weak weakDelegate = delegate] indexDelta in
            return weakDelegate?.preferredItemAnimationStyle(for: indexDelta) ?? .preciseAnimations
        }
    
        _getView = { [weak weakDeltaVisualUpdateViewAccess = viewProvider] in
            return weakDeltaVisualUpdateViewAccess?.view
        }
    }
}

extension AnyDeltaUpdatableViewDelegate: DeltaUpdatableViewDelegate {
    func willHandleReload(at indexPathPair: IndexPathPair) -> Bool { return _getItemWillHandleReload(indexPathPair) }
    func reloadItems(at indexPaths: [IndexPath], completion: @escaping (IndexPath) -> Void) { _performReloadItems(indexPaths, completion) }
    func preferredItemAnimationStyle(for itemDelta: IndexDelta) -> AnimationStyle { return _getPreferredItemAnimationStyle(itemDelta) }
    var view: DeltaUpdatableView? {
        get { return _getView() }
        set { }
    }
}
