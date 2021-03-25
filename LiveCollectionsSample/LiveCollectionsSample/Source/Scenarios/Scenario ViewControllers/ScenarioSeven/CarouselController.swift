//
//  CarouselController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/23/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

protocol CollectionViewDataProvider: UICollectionViewDataSource, UICollectionViewDelegate {
    var viewProvider: CollectionViewProvider { get }
    func registerCollectionView(_ collectionView: UICollectionView)
}

final class CarouselController: NSObject, CollectionViewDataProvider {
    
    private let imageLoader: MovieImageLoaderInterface
    private let collectionData = CollectionData<Movie>()
    
    init(imageLoader: MovieImageLoaderInterface) {
        self.imageLoader = imageLoader
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func registerCollectionView(_ collectionView: UICollectionView) {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: MovieCollectionViewCell.reuseIdentifier)
        collectionData.validationDelegate = self
        collectionData.view = collectionView
        collectionData.animationDelegate = self
    }
    
    var viewProvider: CollectionViewProvider {
        return collectionData
    }
}

extension CarouselController: CollectionDataReusableViewVerificationDelegate {

    // NOTE: If you look at the file `LiveCollections.CollectionDataReusableViewVerificationDelegate.swift`,
    //       you'll see that this is already handled by an extension. I left the code here for completeness,
    //       but you could replace this etension with:
    //       extension CarouselController: CollectionDataReusableViewVerificationDelegate { }
    
    func isDataSourceValid(for view: DeltaUpdatableView) -> Bool {
        guard let collectionView = view as? UICollectionView,
            collectionView.delegate === self,
            collectionView.dataSource === self else {
                return false
        }
        
        return true
    }
}

extension CarouselController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCollectionViewCell.reuseIdentifier, for: indexPath)
        guard let movieCell = cell as? MovieCollectionViewCell,
            collectionView === collectionData.view else {
            return cell
        }
        
        let movie = collectionData[indexPath.item]
        movieCell.update(with: movie)
        
        return movieCell
    }
}

extension CarouselController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let movieCell = cell as? MovieCollectionViewCell,
            collectionView === collectionData.view
            else {
                return
        }
        
        let movie = collectionData[indexPath.item]
        
        imageLoader.loadPosterImage(movie) { result in
            switch result {
            case .success(let image):
                guard movieCell.identifier == movie.id else { return }
                movieCell.update(with: image)
            case .failure:
                return
            }
        }
    }
}

// MARK: CollectionDataAnimationDelegate

extension CarouselController: CollectionDataAnimationDelegate {

    func preferredItemAnimationStyle(for itemDelta: IndexDelta) -> AnimationStyle {
        // option to suppress deltas that result in undesired animations
        return .preciseAnimations
    }

    func animateAlongsideUpdate(with duration: TimeInterval) {
        // animate alongside the collection view animation here
    }
}

extension CarouselController {
    
    func update(with data: [Movie], completion: (() -> Void)? = nil) {
        collectionData.update(data, completion: completion)
    }
}
