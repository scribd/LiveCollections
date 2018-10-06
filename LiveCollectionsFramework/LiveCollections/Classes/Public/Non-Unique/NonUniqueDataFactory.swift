//
//  NonUniqueDataFactory.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/6/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

public struct UniqueKeyFromNonUniqueDatum<DataType: NonUniquelyIdentifiable>: Hashable {
    let baseValue: DataType
    let occurrence: Int
    
    public var hashValue: Int {
        var hasher = Hasher()
        hasher.combine(baseValue.nonUniqueID)
        hasher.combine(occurrence)
        return hasher.finalize()
    }
}

public struct NonUniqueDatum<DataType: NonUniquelyIdentifiable>: UniquelyIdentifiable {

    let key: UniqueKeyFromNonUniqueDatum<DataType>
    
    init(baseValue: DataType, occurrence: Int) {
        self.key = UniqueKeyFromNonUniqueDatum(baseValue: baseValue, occurrence: occurrence)
    }
    
    public var rawData: DataType {
        return key.baseValue
    }
    
    public var uniqueID: UniqueKeyFromNonUniqueDatum<DataType> {
        return key
    }
}

final class NonUniqueDataFactory<RawType: NonUniquelyIdentifiable>: UniquelyIdentifiableDataFactory {
    
    private var occurences: [RawType.NonUniqueIDType: Int] = [:]
    
    public func buildUniquelyIdentifiableDatum(_ rawData: RawType) -> NonUniqueDatum<RawType> {
        let occurrence = (occurences[rawData.nonUniqueID] ?? 0) + 1
        occurences[rawData.nonUniqueID] = occurrence
        return NonUniqueDatum(baseValue: rawData, occurrence: occurrence)
    }
    
    public func didBeginBuildingData() {
        occurences = [:]
    }
}

