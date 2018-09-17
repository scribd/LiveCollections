//
//  BaseTypes+UniquelyIdentifiable.swift
//  LiveCollectionsTests
//
//  Created by Stephane Magne on 8/29/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import LiveCollections

extension Int: UniquelyIdentifiable {
    public typealias RawType = Int
    public typealias UniqueIDType = Int
}

extension String: UniquelyIdentifiable {
    public typealias RawType = String
    public typealias UniqueIDType = String
}

