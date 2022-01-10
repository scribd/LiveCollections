//
//  AnyCollectionDataDeletionNotificationDelegate.swift
//  LiveCollections
//
//  Created by Stephane Magne on 9/9/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

// MARK: - Generic Wrapper

final class AnyCollectionDataDeletionNotificationDelegate<T: UniquelyIdentifiable> {
    private let _performDidDeleteItems: (([T]) -> Void)
    
    init<D: CollectionDataDeletionNotificationDelegate>(_ delegate: D) where D.DataType == T {
        _performDidDeleteItems = { [weak weakDelegate = delegate] items in
            weakDelegate?.didDeleteItems(items)
        }
    }
}

extension AnyCollectionDataDeletionNotificationDelegate: CollectionDataDeletionNotificationDelegate {
    func didDeleteItems(_ items: [T]) { return _performDidDeleteItems(items) }
}
