//
//  ScenarioThreeViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/22/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

import UIKit
import LiveCollections

final class ScenarioThreeViewController: UIViewController {
    
    private let presentationView = PresentationView()
    private let synchronizer = CollectionDataSynchronizer(delay: .short)
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = isIpad() ? CGSize(width: 66, height: 99) : CGSize(width: 44, height: 66)
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    private let dataCoordinator: DataCoordinator
    private let imageLoader: MovieImageLoaderInterface
    private let dataList: [CollectionData<Movie>]

    init(dataCoordinator: DataCoordinator, imageLoader: MovieImageLoaderInterface) {
        self.dataCoordinator = dataCoordinator
        self.imageLoader = imageLoader
        self.dataList = [CollectionData<Movie>(),
                         CollectionData<Movie>(),
                         CollectionData<Movie>()]

        super.init(nibName: nil, bundle: nil)
        
        setUpSubviews()
        dataCoordinator.nextPressed()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpSubviews() {
        presentationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(presentationView)
        
        NSLayoutConstraint.activate([
            presentationView.topAnchor.constraint(equalTo: view.topAnchor),
            presentationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            presentationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            presentationView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        dataCoordinator.delegate = self
        presentationView.playerControl.delegate = dataCoordinator
        presentationView.addViewToPresent(collectionView)
        
        dataList.enumerated().forEach { index, collectionData in
            collectionData.view = collectionView
            collectionData.section = index
            collectionData.synchronizer = synchronizer
            collectionData.animationDelegate = self
        }

        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: MovieCollectionViewCell.reuseIdentifier)
    }
}

extension ScenarioThreeViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCollectionViewCell.reuseIdentifier, for: indexPath)
        guard let movieCell = cell as? MovieCollectionViewCell else {
            return cell
        }
        
        let movie = dataList[indexPath.section][indexPath.item]
        movieCell.update(with: movie)
        
        return movieCell
    }
}

extension ScenarioThreeViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let movieCell = cell as? MovieCollectionViewCell else { return }
        
        let movie = dataList[indexPath.section][indexPath.item]

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

// MARK: DataCoordinatorDelegate

extension ScenarioThreeViewController: DataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [Movie], section: Int) {
        dataList[section].update(data)
    }
}

// MARK: CollectionDataAnimationDelegate

extension ScenarioThreeViewController: CollectionDataAnimationDelegate {

    func preferredItemAnimationStyle(for itemDelta: IndexDelta) -> AnimationStyle {
        return .preciseAnimations
    }

    func animateAlongsideUpdate(with duration: TimeInterval) {
        // animate alongside the collection view animation here
        // use a CollectionDataSynchronizer object if you would like
        // all animations to map to a single call
    }
}
