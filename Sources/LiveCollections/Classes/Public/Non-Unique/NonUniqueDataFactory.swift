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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(baseValue.nonUniqueID)
        hasher.combine(occurrence)
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

public struct NonUniqueSectionDatum<SectionType: UniquelyIdentifiableSection>: UniquelyIdentifiableSection where SectionType.DataType: NonUniquelyIdentifiable {
    
    public typealias UniqueItem = NonUniqueDatum<SectionType.DataType>
    
    public let uniqueID: SectionType.UniqueIDType
    public let items: [UniqueItem]
    
    init<Factory>(sectionData: SectionType, dataFactory: Factory) where Factory: UniquelyIdentifiableDataFactory, Factory.UniquelyIdentifiableType == UniqueItem, Factory.RawType == SectionType.DataType {
        self.uniqueID = sectionData.uniqueID
        self.items = dataFactory.buildUniquelyIdentifiableData(sectionData.items)
    }
}

final class NonUniqueDataFactory<RawType: NonUniquelyIdentifiable>: UniquelyIdentifiableDataFactory {
    
    private var occurences: [RawType.NonUniqueIDType: Int] = [:]
    private let automaticallyClearsData: Bool
    
    init(automaticallyClearsData: Bool = true) {
        self.automaticallyClearsData = automaticallyClearsData
    }
    
    public func buildUniquelyIdentifiableDatum(_ rawData: RawType) -> NonUniqueDatum<RawType> {
        let occurrence = (occurences[rawData.nonUniqueID] ?? 0) + 1
        occurences[rawData.nonUniqueID] = occurrence
        return NonUniqueDatum(baseValue: rawData, occurrence: occurrence)
    }
    
    func didEndBuildingData() {
        guard automaticallyClearsData else { return }
        occurences = [:]
    }
}

