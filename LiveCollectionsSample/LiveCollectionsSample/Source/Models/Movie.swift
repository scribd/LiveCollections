//
//  Movie.swift
//  LiveCollectionsSample
//
//  Created by Théophane Rupin on 5/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation
import LiveCollections

struct Movie: Codable, Hashable {
    let vote_count: UInt
    let id: UInt
    let video: Bool
    let vote_average: Float
    let title: String
    let popularity: Float
    let poster_path: String
    let original_language: String
    let original_title: String
    let adult: Bool
    let overview: String
    let release_date: String
    
    private static let urlRequestCharacters = CharacterSet(charactersIn: "/")
    var sanitizedPosterPath: String { return poster_path.trimmingCharacters(in: Movie.urlRequestCharacters) }
}

extension Movie: UniquelyIdentifiable {
    typealias RawType = Movie
    var uniqueID: UInt { return id }
}
