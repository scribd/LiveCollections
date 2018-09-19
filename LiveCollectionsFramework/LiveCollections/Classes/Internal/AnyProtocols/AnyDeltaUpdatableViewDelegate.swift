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
    private let _getItemWillHandleReload: ((IndexPath) -> Bool)
    private let _performReloadItems: (([IndexPath], @escaping (IndexPath) -> Void) -> Void)
    private let _getPreferredRowAnimationStyle: ((IndexDelta) -> AnimationStyle)
    private let _getView: (() -> DeltaUpdatableView?)

    init(_ delegate: CollectionDataManualReloadDelegate? = nil, viewProvider: CollectionViewProvider? = nil) {
        _getItemWillHandleReload = { [weak weakDelegate = delegate] indexPath in
            return weakDelegate?.willHandleReload(at: indexPath) ?? false
        }
        
        _performReloadItems = { [weak weakDelegate = delegate] indexPaths, completion in
            weakDelegate?.reloadItems(at: indexPaths, completion: completion)
        }
        
        _getPreferredRowAnimationStyle = { [weak weakDelegate = delegate] indexDelta in
            return weakDelegate?.preferredRowAnimationStyle(for: indexDelta) ?? .preciseAnimations
        }
    
        _getView = { [weak weakDeltaVisualUpdateViewAccess = viewProvider] in
            return weakDeltaVisualUpdateViewAccess?.view
        }
    }
}

extension AnyDeltaUpdatableViewDelegate: DeltaUpdatableViewDelegate {
    func willHandleReload(at indexPath: IndexPath) -> Bool { return _getItemWillHandleReload(indexPath) }
    func reloadItems(at indexPaths: [IndexPath], completion: @escaping (IndexPath) -> Void) { _performReloadItems(indexPaths, completion) }
    func preferredRowAnimationStyle(for rowDelta: IndexDelta) -> AnimationStyle { return _getPreferredRowAnimationStyle(rowDelta) }
    var view: DeltaUpdatableView? {
        get { return _getView() }
        set { }
    }
}
