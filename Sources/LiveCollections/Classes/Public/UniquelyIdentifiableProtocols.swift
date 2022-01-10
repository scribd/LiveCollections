//
//  UniquelyIdentifiableProtocol.swift
//  LiveCollections
//
//  Created by Stephane Magne on 8/21/16.
//  Copyright © 2016 Stephane Magne. All rights reserved.
//

import Foundation

/**
 The UniquelyIdentifiable protocol is what allows LiveCollections to determine the changes between two sets of data.
 UniqueID becomes the singular identifier that allows two items to be seen as the same item, while equatability
 helps determing if that item has been mutated/changed from the previous set.
 
 How the protocols are used:
 • Equatable - This largely reflects the state of the data item. (e.g. An age could change on a Person object, or in the table
   of carousels scenario, the contents of an array could have shifted).
 • Hashable - Needed for management in set unions, subtractions and intersects. This should reflect the same concepts as Equatable.
 • UniquelyIdentifiable - The uniqueID is used to determine identity (e.g. A person object is the same even if they have changed
   their name). The RawType value is what determines the interface of the `update(_ data: [RawType])` method. In many cases,
   it will simply be the Self type, but when using data factories, it should represent the underlying type that is being wrapped.
 
 - warning: Since the UniquelyIdentifiable protocol inherits from Equatable, your object's default equatability function will be
   used to determine changes (and thus reloads). If this equatability is too costly and want to simplify it, if you'd like custom
   equatability, or if you'd like eqauatability to include other metadata, you should consider creating a wrapper struct and using
   a data factory.
 */
public protocol UniquelyIdentifiable: Equatable {
    associatedtype RawType
    associatedtype UniqueIDType: Hashable
    var rawData: RawType { get }
    var uniqueID: UniqueIDType { get }
}

public extension UniquelyIdentifiable where RawType == Self {
    var rawData: Self { return self }
}

public extension UniquelyIdentifiable where UniqueIDType == Self {
    var uniqueID: Self { return self }
}

// MARK: UniquelyIdentifiableSection

/**
 This is specifically for creating a data set to represent a single section in a multi-section view.
 The section item, and all of its items, are uniquely identifiable.
 */
public protocol UniquelyIdentifiableSection: UniquelyIdentifiable {
    associatedtype DataType: UniquelyIdentifiable
    var items: [DataType] { get }
}

// MARK: - Implementation example

// NOTE: If you adopt `Hashable` or `Equatable` on your main class definition, then
// as of Swift 4.1, it will auto-synthesize the `==` and `hashValue` functions for you.

/**
 extension Carousel: UniquelyIdentifiable {

    typelias rawData = Carousel
 
    static func == (lhs: Carousel, rhs: Carousel) -> Bool {
        return lhs.myIdentifier == rhs.myIdentifier &&
            lhs.documents.map { $0.remoteID } == rhs.documents.map { $0.remoteID }
    }
 
    var hashValue: Int {
        return myIdentifier ^ documents.first.remoteID // or whatever
    }
 
    var uniqueID: Int {
        return Int(myIdentifier)
    }
 }
 */
