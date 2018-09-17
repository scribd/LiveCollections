//
//  InTheaterController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol InTheatersStateInterface {
    func isMovieInTheaters(_ movie: Movie) -> Bool
}

protocol InTheatersControllerInterface {
    func shuffleState(deltaSize: MovieProviderDeltaSize)
}

final class InTheatersController: InTheatersControllerInterface, InTheatersStateInterface {

    private var data: [UInt: Bool] = [:]
    
    init(allMovieIdentifiers: [UInt]) {
        allMovieIdentifiers.forEach { data[$0] = false }
    }
    
    func shuffleState(deltaSize: MovieProviderDeltaSize) {
        data.keys.forEach { key in
            guard Constants.coinFlip(deltaSize) else { return }
            let value = data[key] ?? false
            data[key] = !value
        }
    }

    func isMovieInTheaters(_ movie: Movie) -> Bool {
        return data[movie.id] ?? false
    }
}

private extension InTheatersController {
    struct Constants {
        static func coinFlip(_ deltaSize: MovieProviderDeltaSize) -> Bool {
            let count: UInt32
            let trueThreshold: UInt32
            switch deltaSize {
            case .small:
                count = 10
                trueThreshold = 9
            case .moderate:
                count = 5
                trueThreshold = 4
            case .massive:
                count = 2
                trueThreshold = 1
            }
            
            let randomValue = arc4random_uniform(count)
            let flipValue = randomValue >= trueThreshold
            return flipValue
        }
    }
}
