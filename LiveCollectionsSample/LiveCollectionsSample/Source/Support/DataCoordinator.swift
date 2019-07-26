//
//  DataCoordinator.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol DataCoordinatorDelegate: AnyObject {
    
    func dataDidUpdate(_ data: [Movie], section: Int)
}

final class DataCoordinator {
    
    private let dataProviders: [MovieDataProviderInterface]
    private var timer: Timer?
    private var deltaSize: MovieProviderDeltaSize = .small
    private var playbackRate: MovieProviderPlaybackRate = .slow
    weak var delegate: DataCoordinatorDelegate?
    
    init(dataProviders: [MovieDataProviderInterface]) {
        self.dataProviders = dataProviders
    }
}

extension DataCoordinator: PlayerControlDelegate {

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
        dataProviders.enumerated().forEach { index, provider in
            provider.nextDataSet(deltaSize: deltaSize) { result in
                switch result {
                case .success(let movies):
                    self.delegate?.dataDidUpdate(movies, section: index)
                case .failure:
                    NSLog("error")
                }
            }
        }
    }
}
