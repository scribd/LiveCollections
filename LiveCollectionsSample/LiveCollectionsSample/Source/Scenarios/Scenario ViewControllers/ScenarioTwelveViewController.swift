//
//  ScenarioTwelveViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/14/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class ScenarioTwelveViewController: UIViewController {
    
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
    private let collectionData = CollectionData<Movie>()
    
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
    }
}

extension ScenarioTwelveViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCollectionViewCell.reuseIdentifier, for: indexPath)
        guard let movieCell = cell as? MovieCollectionViewCell else {
            return cell
        }
        
        let movie = collectionData[indexPath.item]
        movieCell.update(with: movie)
        
        return movieCell
    }
}

extension ScenarioTwelveViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let movieCell = cell as? MovieCollectionViewCell else { return }
        
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

// MARK: DataCoordinatorDelegate

extension ScenarioTwelveViewController: DataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [Movie], section: Int) {
        let delta = collectionData.calculateDeltaSync(data)

        // perform any analysis or analytics on the delta

        let updateData = {
            self.collectionData.update(data)
        }

        // when the time is right, call...
        collectionView.performAnimations(section: collectionData.section, delta: delta, updateData: updateData)

        /**
         NOTE 1:
         You'll notice if you click the "next" button as fast as you can, that the animations don't wait for the
         previous animation to finish like they do in other scenarios. This is a side effect of talking to the
         view directly. If you update quickly enough, the next animation will start from the mid-point of the
         previous animation. Feature or bug? You decide.
         */
        
        /**
         NOTE 2:
         Alternatively, if you decided you didn't want to animate this update, you could instead call
         
         collectionData.update(data)
         collectionView.reloadData()
         
         */
    }
}
