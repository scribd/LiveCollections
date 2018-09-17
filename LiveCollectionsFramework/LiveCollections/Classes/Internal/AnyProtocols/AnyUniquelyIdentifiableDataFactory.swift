//
//  AnyUniquelyIdentifiableDataFactory.swift
//  LiveCollections
//
//  Created by Stephane Magne on 8/19/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

// MARK: - Generic Wrapper

final class AnyUniquelyIdentifiableDataFactory<T: UniquelyIdentifiable> {
    fileprivate var _getBuildUniquelyIdentifiableDatum: ((T.RawType) -> T)

    init<F>(_ factory: F) where F: UniquelyIdentifiableDataFactory, F.RawType == T.RawType, F.UniquelyIdentifiableType == T {
        _getBuildUniquelyIdentifiableDatum = factory.buildUniquelyIdentifiableDatum
    }
}

extension AnyUniquelyIdentifiableDataFactory: UniquelyIdentifiableDataFactory {    
    func buildUniquelyIdentifiableDatum(_ rawType: T.RawType) -> T {
        return _getBuildUniquelyIdentifiableDatum(rawType)
    }
}
