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
    private var _getBuildUniquelyIdentifiableDatum: ((T.RawType) -> T)
    private var _getBuildQueue: (() -> DispatchQueue?)

    init<F>(_ factory: F) where F: UniquelyIdentifiableDataFactory, F.RawType == T.RawType, F.UniquelyIdentifiableType == T {
        _getBuildUniquelyIdentifiableDatum = factory.buildUniquelyIdentifiableDatum
        _getBuildQueue = { factory.buildQueue }
    }
}

extension AnyUniquelyIdentifiableDataFactory: UniquelyIdentifiableDataFactory {    
    func buildUniquelyIdentifiableDatum(_ rawType: T.RawType) -> T {
        return _getBuildUniquelyIdentifiableDatum(rawType)
    }
    
    var buildQueue: DispatchQueue? { return _getBuildQueue() }
}
