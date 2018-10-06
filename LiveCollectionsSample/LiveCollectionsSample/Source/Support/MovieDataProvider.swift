//
//  MovieDataProvider.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import LiveCollections

enum MovieProviderError: Error {
    case noServerResponse
}

enum MovieProviderDeltaSize: String {
    case small
    case moderate
    case massive
}

enum MovieProviderPlaybackRate: String {
    case slow
    case fast
    case ludicrous
    
    var delay: TimeInterval {
        switch self {
        case .slow: return 4.0
        case .fast: return 1.0
        case .ludicrous: return 0.05
        }
    }
}

protocol MovieDataProviderInterface {
    func nextDataSet(deltaSize: MovieProviderDeltaSize, completion: @escaping (Result<[Movie], MovieProviderError>) -> Void)
}

final class RandomMovieDataProvider: MovieDataProviderInterface {
    
    static func randomUniqueMovieIdentifiers(count: Int, availableIDs: [UInt], existingIdentifiers: [UInt] = []) -> [UInt] {
        var insertedCount = 0
        var identifiers = Set<UInt>(existingIdentifiers)
        while insertedCount < count {
            let index = Int(arc4random_uniform(UInt32(availableIDs.count)))
            let uniqueIdentifier = availableIDs[index]
            guard identifiers.contains(uniqueIdentifier) == false else { continue }
            identifiers.insert(uniqueIdentifier)
            insertedCount += 1
        }
        return Array(identifiers)
    }

    static func randomNonUniqueMovieIdentifiers(count: Int, availableIDs: [UInt], existingIdentifiers: [UInt] = []) -> [UInt] {
        var identifiers = existingIdentifiers
        (0..<count).forEach { _ in
            let index = Int(arc4random_uniform(UInt32(availableIDs.count)))
            let uniqueIdentifier = availableIDs[index]
            identifiers.append(uniqueIdentifier)
        }
        return Array(identifiers)
    }
    
    private let initialDataCount: Int
    private let minCount: UInt32
    private let maxCount: UInt32
    private let allowsDuplicates: Bool
    private let movieLoader: MovieLoaderInterface
    
    private var dataSet: [Movie] = []
    
    init(initialDataCount: Int, minCount: UInt32 = 1, maxCount: UInt32 = 100, allowsDuplicates: Bool = false, movieLoader: MovieLoaderInterface) {
        self.initialDataCount = initialDataCount
        self.minCount = minCount
        if maxCount < minCount {
            assert(true, "\(RandomMovieDataProvider.self) can't set a maxCount that is lower than minCount")
            self.maxCount = minCount
        } else {
            self.maxCount = maxCount
        }
        self.allowsDuplicates = allowsDuplicates
        self.movieLoader = movieLoader
    }
    
    func nextDataSet(deltaSize: MovieProviderDeltaSize, completion: @escaping (Result<[Movie], MovieProviderError>) -> Void) {

        let movieIdentifiers: [UInt]
        if dataSet.count == 0 {
            movieIdentifiers = calculateWildlyDifferentDelta(exactCount: initialDataCount)
        } else {
            switch deltaSize {
            case .small:
                movieIdentifiers = calculateDelta(modifier: 2)
            case .moderate:
                movieIdentifiers = calculateDelta(modifier: 6)
            case .massive:
                movieIdentifiers = calculateWildlyDifferentDelta()
            }
        }
        
        movieLoader.loadMovieBatch(ids: movieIdentifiers) { result in
            switch result {
            case .success(let movies):
                self.dataSet = movies
                completion(.success(movies))
            case .failure:
                completion(.failure(.noServerResponse))
            }
        }
    }

    private func calculateWildlyDifferentDelta(exactCount: Int? = nil) -> [UInt] {
        let count = exactCount ?? Int(arc4random_uniform(maxCount-minCount)+minCount)
        if allowsDuplicates {
            return RandomMovieDataProvider.randomNonUniqueMovieIdentifiers(count: count,
                                                                           availableIDs: movieLoader.availableMovieIdentifiers)
        } else {
            return RandomMovieDataProvider.randomUniqueMovieIdentifiers(count: count,
                                                                        availableIDs: movieLoader.availableMovieIdentifiers)
        }
    }
    
    private func calculateDelta(modifier: UInt32) -> [UInt] {
        var updatedIdentifiers = dataSet.map { $0.id }
        let numberOfDeletions = Int(arc4random_uniform(modifier))
        let numberOfInsertions = Int(arc4random_uniform(modifier))
        let numberOfMoves = Int(arc4random_uniform(modifier))
        
        guard updatedIdentifiers.count + numberOfInsertions - numberOfDeletions >= Int(minCount) else {
            return updatedIdentifiers
        }
        
        // deletions
        (0..<numberOfDeletions).forEach { _ in
            guard updatedIdentifiers.count > 0 else { return }
            let indexToDelete = Int(arc4random_uniform(UInt32(updatedIdentifiers.count)))
            updatedIdentifiers.remove(at: indexToDelete)
        }
        
        // insertions
        let newIdentifiers: [UInt]
        if allowsDuplicates {
            newIdentifiers = RandomMovieDataProvider.randomNonUniqueMovieIdentifiers(count: numberOfInsertions,
                                                                                     availableIDs: movieLoader.availableMovieIdentifiers,
                                                                                     existingIdentifiers: updatedIdentifiers)
        } else {
            newIdentifiers = RandomMovieDataProvider.randomUniqueMovieIdentifiers(count: numberOfInsertions,
                                                                                  availableIDs: movieLoader.availableMovieIdentifiers,
                                                                                  existingIdentifiers: updatedIdentifiers)
        }
        
        newIdentifiers.forEach { identifier in
            guard updatedIdentifiers.contains(identifier) == false else { return }
            let indexToInsert = Int(arc4random_uniform(UInt32(updatedIdentifiers.count)))
            updatedIdentifiers.insert(identifier, at: indexToInsert)
        }
        
        // moves
        (0..<numberOfMoves).forEach { _ in
            guard updatedIdentifiers.count > 1 else { return }
            let indexOne = Int(arc4random_uniform(UInt32(updatedIdentifiers.count)))
            let heldData = updatedIdentifiers[indexOne]
            updatedIdentifiers.remove(at: indexOne)
            let indexTwo = Int(arc4random_uniform(UInt32(updatedIdentifiers.count)))
            updatedIdentifiers.insert(heldData, at: indexTwo)
        }
        
        return updatedIdentifiers
    }
}
