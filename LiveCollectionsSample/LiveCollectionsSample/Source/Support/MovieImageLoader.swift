//
//  MovieImageLoader.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/22/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

protocol MovieImageLoaderInterface {
    func loadPosterImage(_ movie: Movie, completion: @escaping (Result<UIImage, MovieLoaderError>) -> Void)
    func clearAll()
}

final class MovieImageLoader: MovieImageLoaderInterface {
    
    private let imageCache = DataCache<UIImage>(encoder: ImageFileEncoder(folderName: "images"))
    private let movieAPI = MovieAPI(urlSession: .shared)

    func clearAll() {
        imageCache.clearCache()
    }

    func loadPosterImage(_ movie: Movie, completion: @escaping (Result<UIImage, MovieLoaderError>) -> Void) {
        
        let filename = movie.sanitizedPosterPath
        if let cachedImage = imageCache[filename] {
            completion(.success(cachedImage))
            return
        }
        
        let request = APIRequest<Data>(method: .get, host: MovieAPI.Constants.imageAPIHost, path: movie.poster_path)
        
        movieAPI.send(request: request) { result in
            switch result {
            case .success(let data):
                guard let image = UIImage(data: data) else {
                    completion(.failure(.oops))
                    return
                }
                self.imageCache[filename] = image
                completion(.success(image))
                
            case .failure:
                completion(.failure(.oops))
            }
        }
    }
}
