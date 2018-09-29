//
//  CollectionDataDelegate.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/15/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import Foundation

/**
 A minimum set of delegate methods required to handle manually reloading a table view with an IndexDelta.
 The most common use case of when you would return `true` for `willHandleReload(at indexPathPair: IndexPathPair) -> Bool`
 is when a tableView row contains a collection view. Allowing the table view to reload
 the data will prevent the collection view from performing its own animation. In this case, we just want
 to update the collection view and not perform any table view animations. Instead trigger your collection
 view update in the `reloadItems` call.
 
 Additionally, `preferredItemAnimationStyle` and `preferredSectionAnimationStyle` give you hooks to
 change the resulting animation for a given delta. In most cases, simply return `.preciseAnimations`
 and let CollectionData do its thing, but if you see cases that don't look great in your animation,
 you can handle that here. In most problem scenarios, returning `.reloadSections` will still display
 some animation, but shouldn't replicate the problem behavior. And return `.reloadData` if there are
 times when you don't want to animate at all.
*/
public protocol CollectionDataManualReloadDelegate: AnyObject {
    
    /** - note:
     pair.source == position before animation
     pair.target == position after animation
     */
    func willHandleReload(at indexPathPair: IndexPathPair) -> Bool
    func reloadItems(at indexPaths: [IndexPath], completion: @escaping (IndexPath) -> Void)

    func preferredItemAnimationStyle(for itemDelta: IndexDelta) -> AnimationStyle
}

public protocol CollectionSectionDataManualReloadDelegate: CollectionDataManualReloadDelegate {

    // Note: reloadSections & preciseAnimations have the same behavior for section animations
    func preferredSectionAnimationStyle(for sectionDelta: IndexDelta) -> AnimationStyle
}

// MARK: AnimationStyle

public enum AnimationStyle {
    case reloadData        // no animation
    case reloadSections    // animated but not precise
    case preciseAnimations // animated and precise
}

// MARK: CollectionDataDeletionNotificationDelegate

/**
 Adopt this protocol and set yourself as the delegate if you want a hook to track items that have been
 deleted. Since they will no longer be reflected in your data set, the exact items are handed to you here.
*/
public protocol CollectionDataDeletionNotificationDelegate: AnyObject {
    associatedtype DataType: UniquelyIdentifiable
    
    func didDeleteItems(_ items: [DataType])
}
