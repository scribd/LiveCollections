//
//  MovieFileEncoder.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

final class MovieFileEncoder: FileEncoderInterface {
    
    let folderName: String
    
    init(folderName: String) {
        self.folderName = folderName
    }
    
    func decode(from data: Data) -> Movie? {
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Movie.self, from: data)
        } catch {
            return nil
        }
    }
    
    func encode(for movie: Movie) -> Data? {
        do {
            let serializer = JSONEncoder()
            return try serializer.encode(movie)
        } catch {
            return nil
        }
    }
}
