//
//  MovieLoader.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

enum MovieLoaderError: Error {
    case oops
}

protocol AvailableMovieProvider {
    var availableMovieIdentifiers: [UInt] { get }
}

protocol MovieLoaderInterface: AvailableMovieProvider {
    func loadMovieBatch(ids: [UInt], completion: @escaping (Result<[Movie], MovieLoaderError>) -> Void)
    func loadMovie(id: UInt, completion: @escaping (Result<Movie, MovieLoaderError>) -> Void)
}

final class MovieLoader: MovieLoaderInterface {
    
    private(set) var availableMovieIdentifiers: [UInt] = []
    private let movieCoder = MovieFileEncoder(folderName: "movies")
    private lazy var movieCache = { return DataCache<Movie>(encoder: self.movieCoder) }()
    private let movieAPI = MovieAPI(urlSession: .shared)

    func loadMovieBatch(ids: [UInt], completion: @escaping (Result<[Movie], MovieLoaderError>) -> Void) {
        
        var results: [Movie] = []
        var remainingIds: [UInt] = ids.reversed()
        
        func _loadNext(completion: @escaping (Result<[Movie], MovieLoaderError>) -> Void) {
            guard let nextId = remainingIds.popLast() else {
                completion(.success(results))
                return
            }
            
            loadMovie(id: nextId) { result in
                switch result {
                case .success(let movie):
                    results.append(movie)
                case .failure(let error):
                    NSLog("Unexpected error \(error) when loading movie with identifier \(nextId)")
                }
                _loadNext(completion: completion)
            }
        }
        
        _loadNext(completion: completion)
    }
    
    func loadMovie(id: UInt, completion: @escaping (Result<Movie, MovieLoaderError>) -> Void) {
        
        let filename = String(id)
        if let cachedMovie = movieCache[filename] {
            completion(.success(cachedMovie))
            return
        }

        let request = APIRequest<Movie>(path: "/movie/\(id)")
        
        movieAPI.send(request: request) { result in
            switch result {
            case .success(let movie):
                self.movieCache[filename] = movie
                completion(.success(movie))
            case .failure:
                completion(.failure(.oops))
            }
        }
    }
    
    func loadInitialData() {
        let bundle = Bundle.main
        let start: UInt = 0
        let end: UInt = 1000
        (start..<end).forEach { index in
            let filename = String(index)
            guard movieCache[filename] == nil else {
                availableMovieIdentifiers.append(index)
                return
            }
            guard let resourcePath = bundle.path(forResource: filename, ofType: "") else { return }
            guard let fileData = FileManager.default.contents(atPath: resourcePath) else { return }
            guard let movie = movieCoder.decode(from: fileData) else { return }
            availableMovieIdentifiers.append(index)
            movieCache[filename] = movie
        }
    }
}
