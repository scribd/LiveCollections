//
//  UniquelyIdentifiableDataFactory.swift
//  LiveCollections
//
//  Created by Stephane Magne on 7/9/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

/**
 Adopt this protocol to build a class that takes in your RawData type and outputs a second wrapper type.
 This useful for the following scenarios:
 • Your wrapper type to exposes a different equality function than your RawType
 • Your wrapper type includes additional metadata pertaining to the RawType.
 
 In this second scenario, you would inject `data fetchers` into your factory object that can fetch the
 metadata for you on the fly and construct the new object. These fecthers should be lightweight and hopefully
 be maintining some in-memory cache to draw their state from.
 
 You pass in your factory in the intializer of `CollectionData` or `CollectionSectionData`. It will hold a
 strong reference to your factory, so you do not need to hold your local copy.
 */
public protocol UniquelyIdentifiableDataFactory {

    associatedtype RawType
    associatedtype UniquelyIdentifiableType: UniquelyIdentifiable

    var buildQueue: DispatchQueue? { get } // optional queue if your data is thread sensitive
    func buildUniquelyIdentifiableDatum(_ rawType: RawType) -> UniquelyIdentifiableType
    
    func didBeginBuildingData()
    func didEndBuildingData()
}

public extension UniquelyIdentifiableDataFactory {
    var buildQueue: DispatchQueue? { return nil }
    func didBeginBuildingData() { }
    func didEndBuildingData() { }
}

extension UniquelyIdentifiableDataFactory {
    
    func buildUniquelyIdentifiableData(_ rawType: [RawType]) -> [UniquelyIdentifiableType] {
        let buildData: ([RawType]) -> [UniquelyIdentifiableType] = { rawType in
            self.didBeginBuildingData()
            let data = rawType.map { self.buildUniquelyIdentifiableDatum($0) }
            self.didEndBuildingData()
            return data
        }
        
        if let buildQueue = buildQueue {
            return buildQueue.safeSync { buildData(rawType) }
        } else {
            return buildData(rawType)
        }        
    }
}

public protocol UniquelyIdentifiableIdentityDataFactory: UniquelyIdentifiableDataFactory where RawType == UniquelyIdentifiableType { }

// MARK: IdentityDataFactory

/**
 By default, any object that sets RawType to its Self type, will be assigned an IdentityDataFactory under the hood.
 As you can see, it does not manipulation and simply returns the object it was given.
 */
public struct IdentityDataFactory<DataType: UniquelyIdentifiable>: UniquelyIdentifiableIdentityDataFactory {
    
    public func buildUniquelyIdentifiableDatum(_ rawType: DataType) -> DataType {
        return rawType
    }
}
