//
//  ScenarioNineViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class ScenarioNineViewController: UIViewController {
    
    private let presentationView = PresentationView()
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
    private let dataCoordinator: InTheatersDataCoordinator
    private let imageLoader: MovieImageLoaderInterface
    private let collectionData: CollectionData<DistributedMovie>
    
    init(dataCoordinator: InTheatersDataCoordinator, imageLoader: MovieImageLoaderInterface, inTheatersState: InTheatersStateInterface) {
        self.dataCoordinator = dataCoordinator
        self.imageLoader = imageLoader
        
        let dataFactory = DistributedMovieFactory(inTheatersState: inTheatersState)
        collectionData = CollectionData<DistributedMovie>(dataFactory: dataFactory)
        
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
        collectionData.view = collectionView
        collectionView.register(MovieAndLocationCollectionViewCell.self, forCellWithReuseIdentifier: MovieAndLocationCollectionViewCell.reuseIdentifier)
    }
}

extension ScenarioNineViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieAndLocationCollectionViewCell.reuseIdentifier, for: indexPath)
        guard let movieCell = cell as? MovieAndLocationCollectionViewCell else {
            return cell
        }
        
        let movieAndLocation = collectionData[indexPath.item]
        movieCell.update(with: movieAndLocation)
        
        return movieCell
    }
}

extension ScenarioNineViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let movieCell = cell as? MovieAndLocationCollectionViewCell else { return }
        
        let movieAndLocation = collectionData[indexPath.item]
        
        imageLoader.loadPosterImage(movieAndLocation.movie) { result in
            switch result {
            case .success(let image):
                guard movieCell.identifier == movieAndLocation.movie.id else { return }
                movieCell.update(with: image)
            case .failure:
                return
            }
        }
    }
}

// MARK: DataCoordinatorDelegate

extension ScenarioNineViewController: DataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [Movie], section: Int) {
        collectionData.update(data)
    }
}
