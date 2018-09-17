//
//  InTheatersDataCoordinator.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

final class InTheatersDataCoordinator {
    
    private let dataProviders: [MovieDataProviderInterface]
    private let inTheatersController: InTheatersControllerInterface
    private var timer: Timer?
    private var deltaSize: MovieProviderDeltaSize = .small
    private var playbackRate: MovieProviderPlaybackRate = .slow
    weak var delegate: DataCoordinatorDelegate?
    
    init(dataProviders: [MovieDataProviderInterface], inTheatersController: InTheatersControllerInterface) {
        self.dataProviders = dataProviders
        self.inTheatersController = inTheatersController
    }
}

extension InTheatersDataCoordinator: PlayerControlDelegate {

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
        inTheatersController.shuffleState(deltaSize: deltaSize)
        dataProviders.enumerated().forEach { index, provider in
            provider.nextDataSet(deltaSize: .small) { result in
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
