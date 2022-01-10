//
//  CollectionDataProtocols.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/15/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import Foundation

// MARK: Live Data Protocols

/**
 This is the interface protocol of `CollectionData`. You can use this if you want to pass your objects
 to a generic function, or store them in a type erasing box. Otherwise, you can just use the
 `CollectionData` class directly.
 */
public protocol CollectionDataStateInterface: AnyObject {
    associatedtype DataType

    var count: Int { get }
    subscript(index: Int) -> DataType { get }
}

public protocol CollectionDataFixedSectionInterface: AnyObject {
    var section: Int { get set }
}

public protocol CollectionDataSynchronizable: AnyObject {
    var synchronizer: CollectionDataSynchronizer? { get set }
}

public protocol CollectionDataActionsInterface: CollectionDataStateInterface, CollectionDataFixedSectionInterface {
    associatedtype RawType

    /**
     Syncronously or asynchronously calculate the delta between the updatedData and the existing Data. All deletions, insertions,
     reloads, and moves will be calculated for you. This should only be called when you have not assigned a view to the
     CollectionData object. (Or in rare scenarios where you want to analyze the delta in advance).
     - note: This does *not* update the data, but only calculates a delta. You must still call the `update` method as part of a
             manual animation call.
     - parameter updatedData: The updated state array of your data. The change delta will be calculated form the current data set.
     - parameter completion: A completion block to receive the asyncronously calculated delta
     - returns: An IndexDelta that tells you what animations will take place.
     */
    func calculateDeltaSync(_ updatedData: [RawType]) -> IndexDelta
    func calculateDeltaAsync(_ updatedData: [RawType], completion: @escaping (IndexDelta) -> Void)

    /**
     Syncronously calculate the append delta between the updatedData and the existing Data. This returns an insertion only delta
     and the calculation cost is negligible. This should only be called when you have not assigned a view to the CollectionData object.
     This action has O(1) computational cost, so there is no need for an asyncronous counterpart.
     - note: This does *not* update the data, but only calculates a delta. You must still call the `append` method as part of a
     manual animation call.
     - parameter updatedData: The updated state array of your data. The change delta will be calculated form the current data set.
     - returns: An IndexDelta that tells you what animations will take place.
     */
    func calculateAppendDelta(_ updatedData: [RawType]) -> IndexDelta
    
    /**
     Update the entire data set. All deletions, insertions, reloads, and moves will be calculated for you.
     If you assign a UITableView, UICollectionView, or custom view to the data source, it will trigger the animation immediately.
     - parameter updatedData: The updated state array of your data. The change delta will be calculated form the current data set.
     - parameter completion: A completion block triggered at the end of the animation.
     */
    func update(_ updatedData: [RawType], completion: (() -> Void)?)
    
    /**
     Append data to the end of your ordered set. Only insertions will be calculated for you, and all other set operations will be
     ignored. If you assign a UITableView, UICollectionView, or custom view to the data source, it will trigger the animation immediately.
     - parameter appendedItems: The array of items to append to your ordered data set. The change delta will only include these items.
     - parameter completion: A completion block triggered at the end of the animation.
     */
    func append(_ appendedItems: [RawType], completion: (() -> Void)?)
}
