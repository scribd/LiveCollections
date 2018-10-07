//
//  ScenarioTenViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 10/6/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class ScenarioTenViewController: UIViewController {
    
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
    private let dataCoordinator: DataCoordinator
    private let imageLoader: MovieImageLoaderInterface
    private let collectionData = NonUniqueCollectionData<Movie>()
    
    init(dataCoordinator: DataCoordinator, imageLoader: MovieImageLoaderInterface) {
        self.dataCoordinator = dataCoordinator
        self.imageLoader = imageLoader
        
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
        collectionView.register(MovieCollectionViewCell.self, forCellWithReuseIdentifier: MovieCollectionViewCell.reuseIdentifier)
        collectionData.view = collectionView
    }
}

extension ScenarioTenViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCollectionViewCell.reuseIdentifier, for: indexPath)
        guard let movieCell = cell as? MovieCollectionViewCell else {
            return cell
        }
        
        let movie = collectionData[indexPath.item].rawData
        movieCell.update(with: movie)
        
        return movieCell
    }
}

extension ScenarioTenViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let movieCell = cell as? MovieCollectionViewCell else { return }
        
        let movie = collectionData[indexPath.item].rawData
        
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

extension ScenarioTenViewController: DataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [Movie], section: Int) {
        collectionData.update(data)
    }
}

// MARK: DataCoordinatorDelegate

extension Movie: NonUniquelyIdentifiable {
    var nonUniqueID: UInt {
        return id
    }
}
