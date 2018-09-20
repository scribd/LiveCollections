//
//  DistributedMovieFactory.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import LiveCollections

struct DistributedMovie: Hashable {
    let movie: Movie
    let isInTheaters: Bool
}

extension DistributedMovie: UniquelyIdentifiable {
    var rawData: Movie { return movie }
    var uniqueID: UInt { return movie.uniqueID }
}

struct DistributedMovieFactory: UniquelyIdentifiableDataFactory {

    private let inTheatersState: InTheatersStateInterface
    let buildQueue: DispatchQueue?
    
    init(inTheatersState: InTheatersStateInterface) {
        self.inTheatersState = inTheatersState
        self.buildQueue = DispatchQueue(label: "Test", attributes: .concurrent)
    }
    
    func buildUniquelyIdentifiableDatum(_ movie: Movie) -> DistributedMovie {
        let isInTheaters = inTheatersState.isMovieInTheaters(movie)
        return DistributedMovie(movie: movie, isInTheaters: isInTheaters)
    }
}
