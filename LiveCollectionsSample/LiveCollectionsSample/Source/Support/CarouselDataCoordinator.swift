//
//  CarouselDataCoordinator.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 8/19/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol CarouselDataCoordinatorDelegate: AnyObject {
    func dataDidUpdate(_ data: [CarouselRow])
}

final class CarouselDataCoordinator {
    
    private let dataProviders: [MovieDataProviderInterface]
    private var timer: Timer?
    private var deltaSize: MovieProviderDeltaSize = .small
    private var playbackRate: MovieProviderPlaybackRate = .slow
    weak var delegate: CarouselDataCoordinatorDelegate?
    
    init(dataProviders: [MovieDataProviderInterface]) {
        self.dataProviders = dataProviders
    }
}

extension CarouselDataCoordinator: PlayerControlDelegate {
    
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
        var data: [CarouselRow] = []
        
        let providers: [(offset: Int, element: MovieDataProviderInterface)] = {
            guard shouldShuffle() else { return dataProviders.enumerated().map { return ($0.offset, $0.element) } }
            return dataProviders.enumerated().shuffled()
        }()
        
        providers.forEach { index, provider in
            
            let shouldHide = coinFlip()
            guard shouldHide == false else { return }
            
            provider.nextDataSet(deltaSize: deltaSize) { result in
                switch result {
                case .success(let movies):
                    let identifier = String(index)
                    let carouselRow = CarouselRow(identifier: identifier, movies: movies)
                    data.append(carouselRow)
                case .failure:
                    NSLog("error")
                }
            }
        }
        self.delegate?.dataDidUpdate(data)
    }

    private func coinFlip() -> Bool {
        let count: UInt32
        let trueThreshold: UInt32
        switch deltaSize {
        case .small:
            count = 50
            trueThreshold = 48
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
