//
//  ScenarioThirteenViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class ScenarioThirteenViewController: UIViewController {
    
    private let presentationView = PresentationView()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
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
        presentationView.addViewToPresent(tableView)
        tableView.register(MovieTableViewCell.self, forCellReuseIdentifier: MovieTableViewCell.reuseIdentifier)
        let rowAnimations = TableViewAnimationModel(deleteAnimation: .right,
                                                    insertAnimation: .right,
                                                    reloadAnimation: .middle)
        collectionData.setTableView(tableView,
                                    rowAnimations: rowAnimations,
                                    sectionReloadAnimation: .top)
    }
}

extension ScenarioThirteenViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.reuseIdentifier, for: indexPath)
        guard let movieCell = cell as? MovieTableViewCell else {
            return cell
        }
        
        let movie = collectionData[indexPath.item]
        movieCell.update(with: movie)
        
        imageLoader.loadPosterImage(movie) { result in
            switch result {
            case .success(let image):
                guard movieCell.identifier == movie.id else { return }
                movieCell.update(with: image)
            case .failure:
                return
            }
        }
        
        return movieCell
    }
}

extension ScenarioThirteenViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MovieTableViewCell.cellHeight
    }
}

// MARK: DataCoordinatorDelegate

extension ScenarioThirteenViewController: DataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [Movie], section: Int) {
        collectionData.update(data)
    }
}
