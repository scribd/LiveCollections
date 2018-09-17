//
//  CarouselSection.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/3/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import LiveCollections

struct CarouselSection: Equatable {
    let sectionIdentifier: String
    let carousels: [CarouselRow]
}

extension CarouselSection: UniquelyIdentifiableSection {
    var uniqueID: String { return sectionIdentifier }
    var items: [CarouselRow] { return carousels }
    var hashValue: Int { return carousels.reduce(uniqueID.hashValue) { $0 ^ $1.hashValue } }
}
