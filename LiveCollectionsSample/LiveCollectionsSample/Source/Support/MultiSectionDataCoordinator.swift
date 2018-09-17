//
//  MultiSectionDataCoordinator.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 8/29/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol MultiSectionDataCoordinatorDelegate: AnyObject {
    func dataDidUpdate(_ data: [MovieSection])
}

final class MultiSectionDataCoordinator {
    
    private let sectionCount: Int
    private let dataProvider: MovieDataProviderInterface
    private var timer: Timer?
    private var deltaSize: MovieProviderDeltaSize = .small
    private var playbackRate: MovieProviderPlaybackRate = .slow
    weak var delegate: MultiSectionDataCoordinatorDelegate?
    
    init(sectionCount: Int, dataProvider: MovieDataProviderInterface) {
        self.sectionCount = sectionCount
        self.dataProvider = dataProvider
    }
}

extension MultiSectionDataCoordinator: PlayerControlDelegate {
    func deltaSizeChanged(to size: MovieProviderDeltaSize) {
        deltaSize = size
    }
    
    func playbackRateChanged(to rate: MovieProviderPlaybackRate) {
        playbackRate = rate
        if timer != nil { playPressed() }
    }
    
    func playPressed() {
        timer?.invalidate()
        _fetchNext()
        timer = Timer.scheduledTimer(withTimeInterval: playbackRate.delay, repeats: true, block: { [weak self] timer in
            self?._fetchNext()
        })
    }

    func pausePressed() {
        timer?.invalidate()
        timer = nil
    }
    
    func nextPressed() {
        guard timer == nil else { return }
        _fetchNext()
    }
    
    private func _fetchNext() {
        
        dataProvider.nextDataSet(deltaSize: deltaSize) { result in
            switch result {
            case .success(let movies):
                let sections = self.buildSections(from: movies)
                self.delegate?.dataDidUpdate(sections)
            case .failure:
                NSLog("error")
            }
        }
    }

    private func buildSections(from movies: [Movie]) -> [MovieSection] {
        let visibleSections = (0..<sectionCount).filter { _ in coinFlip() == false }
        let orederedSections = shouldShuffle() ? visibleSections.shuffled() : visibleSections
        var remainingMovies = movies
        let sections: [MovieSection] = orederedSections.map { section in
            let movieCount = Int(arc4random_uniform(UInt32(movies.count / sectionCount))) + 2
            let moviesForSection = remainingMovies.prefix(movieCount)
            remainingMovies = Array(remainingMovies.dropFirst(movieCount))
            return MovieSection(sectionIdentifier: String(section), movies: Array(moviesForSection))
        }
        
        return sections
    }
    
    private func coinFlip() -> Bool {
        let count: UInt32
        let trueThreshold: UInt32
        switch deltaSize {
        case .small:
            count = 10
            trueThreshold = 9
        case .moderate:
            count = 5
            trueThreshold = 3
        case .massive:
            count = 2
            trueThreshold = 1
        }
        
        let randomValue = arc4random_uniform(count)
        let flipValue = randomValue > trueThreshold
        return flipValue
    }
    
    private func shouldShuffle() -> Bool {
        switch deltaSize {
        case .small,
             .moderate:
            return false
        case .massive:
            return true
        }
    }
}
