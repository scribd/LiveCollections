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
                    let image = UIImage.withRandomColor()
                    self.imageCache[filename] = image
                    completion(.success(image))
                    return
                }
                self.imageCache[filename] = image
                completion(.success(image))
                
            case .failure:
                let image = UIImage.withRandomColor()
                self.imageCache[filename] = image
                completion(.success(image))
            }
        }
    }
}

private extension UIImage {

    static func withRandomColor() -> UIImage {
        return UIImage(color: .random())
    }

    convenience init(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        // Fill
        guard let context = UIGraphicsGetCurrentContext() else {
            self.init()
            return
        }

        context.setFillColor(color.cgColor)
        let path = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: size))
        context.addPath(path.cgPath)
        context.fillPath()

        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            self.init()
            return
        }

        UIGraphicsEndImageContext()

        guard let cgImage = image.cgImage else {
            self.init()
            return
        }

        self.init(cgImage: cgImage)
    }
}

private extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

private extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red:   .random(),
            green: .random(),
            blue:  .random(),
            alpha: 0.25 + (.random() * 0.75)
        )
    }
}
