//
//  ScenarioElevenViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 10/6/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class ScenarioElevenViewController: UIViewController {
    
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
    private let dataCoordinator: MultiSectionDataCoordinator
    private let imageLoader: MovieImageLoaderInterface
    private lazy var collectionData: NonUniqueCollectionSectionData<MovieSection> = {
        return NonUniqueCollectionSectionData(view: collectionView)
    }()
    
    init(dataCoordinator: MultiSectionDataCoordinator, imageLoader: MovieImageLoaderInterface) {
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
    }
}

extension ScenarioElevenViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionData.sectionCount
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.itemCount(forSection: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCollectionViewCell.reuseIdentifier, for: indexPath)
        guard let movieCell = cell as? MovieCollectionViewCell else {
            return cell
        }
        
        let movie = collectionData[indexPath].rawData
        movieCell.update(with: movie)
        
        return movieCell
    }
}

extension ScenarioElevenViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let movieCell = cell as? MovieCollectionViewCell else { return }
        
        let movie = collectionData[indexPath].rawData
        
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

// MARK: MultiSectionDataCoordinatorDelegate

extension ScenarioElevenViewController: MultiSectionDataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [MovieSection]) {
        collectionData.update(data)
    }
}
