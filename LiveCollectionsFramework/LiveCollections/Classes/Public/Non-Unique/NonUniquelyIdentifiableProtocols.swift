//
//  NonUniquelyIdentifiableProtocols.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/6/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

public protocol NonUniquelyIdentifiable: Equatable {
    associatedtype NonUniqueIDType: Hashable
    var nonUniqueID: NonUniqueIDType { get }
}
