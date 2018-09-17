//
//  MovieSection.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 8/29/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import LiveCollections

struct MovieSection: Equatable {
    let sectionIdentifier: String
    let movies: [Movie]
}

extension MovieSection: UniquelyIdentifiableSection {
    
    var uniqueID: String { return sectionIdentifier }
    var items: [Movie] { return movies }
    var hashValue: Int { return items.reduce(uniqueID.hashValue) { $0 ^ $1.hashValue } }
}
