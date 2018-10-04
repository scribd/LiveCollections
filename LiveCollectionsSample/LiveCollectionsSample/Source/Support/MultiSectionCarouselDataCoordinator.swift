//
//  MultiSectionCarouselDataCoordinator.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/3/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol MultiSectionCarouselDataCoordinatorDelegate: AnyObject {
    func dataDidUpdate(_ data: [CarouselSection])
}

final class MultiSectionCarouselDataCoordinator {
    
    private let sectionCount: Int
    private let dataProviders: [MovieDataProviderInterface]
    private var timer: Timer?
    private var deltaSize: MovieProviderDeltaSize = .small
    private var playbackRate: MovieProviderPlaybackRate = .slow
    weak var delegate: MultiSectionCarouselDataCoordinatorDelegate?
    
    init(sectionCount: Int, dataProviders: [MovieDataProviderInterface]) {
        self.sectionCount = sectionCount
        self.dataProviders = dataProviders
    }
}

extension MultiSectionCarouselDataCoordinator: PlayerControlDelegate {
    
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
        
        let sections = [Int](0..<sectionCount)
        let carousels = [Int](0..<dataProviders.count)
        let orderedCarousels = shouldShuffle() ? carousels.shuffled() : carousels
        
        var remainingCarousels = orderedCarousels
        
        let averageCarouselsPerSection = max(carousels.count/sectionCount, 1)
        
        let sectionData: [CarouselSection] = sections.map { section in
            let carouselCountInSection = max(Int(arc4random_uniform(UInt32(averageCarouselsPerSection))) + 1, 1)
            let carouselsInSection = remainingCarousels.prefix(carouselCountInSection)
            remainingCarousels = Array(remainingCarousels.dropFirst(carouselCountInSection))
            
            let carouselsForSection: [CarouselRow] = carouselsInSection.compactMap { carousel in
                let dataProvider = dataProviders[carousel]
                var carouselRow: CarouselRow?
                dataProvider.nextDataSet(deltaSize: .small) { result in
                    switch result {
                    case .success(let movies):
                        carouselRow = CarouselRow(identifier: String(carousel), movies: movies)
                    case .failure:
                        NSLog("error")
                    }
                }
                return carouselRow
            }

            let visibleCarousels = carouselsForSection.filter { _ in coinFlip() == false }

            return CarouselSection(sectionIdentifier: String(section), carousels: visibleCarousels)
        }

        let orderedSections = shouldShuffle() ? sectionData.shuffled() : sectionData
        let visibleSections = orderedSections.filter { _ in coinFlip() == false }
        delegate?.dataDidUpdate(visibleSections)
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
