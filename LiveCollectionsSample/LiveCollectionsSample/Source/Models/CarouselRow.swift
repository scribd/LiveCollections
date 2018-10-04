//
//  Carousel.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 8/26/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import LiveCollections

struct CarouselRow: Equatable {
    let identifier: String
    let movies: [Movie]
}

extension CarouselRow: UniquelyIdentifiable {
    typealias RawType = CarouselRow
    var uniqueID: String { return identifier }
    var hashValue: Int {
        return movies.reduce(identifier.hashValue) { $0 ^ $1.hashValue }
    }
}
