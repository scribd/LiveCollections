//
//  CollectionSectionDataProtocols.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/15/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import Foundation

// MARK: CollectionSectionDataStateInterface

/**
 This is the interface protocol of `CollectionSectionData`. You can use this if you want to pass your objects
 to a generic function, or store them in a type erasing box. Otherwise, you can just use the
 `CollectionSectionData` class directly.
 */
public protocol CollectionSectionDataStateInterface: AnyObject {
    associatedtype RawType
    associatedtype DataType: UniquelyIdentifiable
    associatedtype SectionType: UniquelyIdentifiableSection
    
    // helpers
    var sectionCount: Int { get }
    func itemCount(forSection section: Int) -> Int
    
    subscript(index: Int) -> SectionType { get }
    subscript(section: Int, item: Int) -> RawType { get }
    subscript(indexPath: IndexPath) -> RawType { get }
}

// MARK: - CollectionSectionDataActionsInterface

protocol CollectionSectionDataActionsInterface: CollectionSectionDataStateInterface {
    
    /**
     Call this when you want to update the entire data set. All deletions, insertions, reloads, and moves will be calculated for you.
     Since you must assign a UITableView, UICollectionView, or custom view to the data source, it will trigger the animation immediately.
     - parameter updatedData: The updated state array of your data. The change delta will be calculated form the current data set.
     - parameter completion: A completion block triggered at the end of the animation.
     */
    func update(_ updatedData: [SectionType], completion: (() -> Void)?)
    
    /**
     Call this when you want to append data to the end of your ordered set. Only insertions will be calculated for you, and all other set
     operations will be ignored. Since you must assign a UITableView, UICollectionView, or custom view to the data source, it will trigger
     the animation immediately.
     - parameter appendedItems: The array of items to append to your ordered data set. The change delta will only include these items.
     - parameter completion: A completion block triggered at the end of the animation.
     */
    func append(_ appendedItems: [SectionType], completion: (() -> Void)?)
}
