//
//  ScenarioSevenViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/23/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class ScenarioSevenViewController: UIViewController {
    
    private let presentationView = PresentationView()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    private let dataCoordinator: CarouselDataCoordinator
    private let imageLoader: MovieImageLoaderInterface
    private var carouselDataSources: [String: CarouselController] = [:]
    private let collectionData = CollectionData<CarouselRow>()
    
    init(dataCoordinator: CarouselDataCoordinator, imageLoader: MovieImageLoaderInterface) {
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
        tableView.register(CarouselTableViewCell.self, forCellReuseIdentifier: CarouselTableViewCell.reuseIdentifier)
        collectionData.view = tableView
        collectionData.reloadDelegate = self
        collectionData.animationDelegate = self
        collectionData.setDeletionNotificationDelegate(self)
    }
    
    private func _carouselDataSource(for identifier: String) -> CarouselController {
        if let controller = carouselDataSources[identifier] {
            return controller
        }
        
        let controller = CarouselController(imageLoader: imageLoader)
        carouselDataSources[identifier] = controller
        return controller
    }
}

// MARK: CollectionDataManualReloadDelegate

extension ScenarioSevenViewController: CollectionDataManualReloadDelegate {
    
    func willHandleReload(at indexPathPair: IndexPathPair) -> Bool {
        return true
    }
    
    func reloadItems(at indexPaths: [IndexPath], indexPathCompletion: @escaping (IndexPath) -> Void) {

        indexPaths.forEach { indexPath in
            let carouselRow = collectionData[indexPath.item]
            let dataSource = _carouselDataSource(for: carouselRow.identifier)
            
            let itemCompletion = {
                indexPathCompletion(indexPath)
            }
            
            dataSource.update(with: carouselRow.movies, completion: itemCompletion)
        }
    }
}

// MARK: CollectionDataAnimationDelegate

extension ScenarioSevenViewController: CollectionDataAnimationDelegate {

    func preferredItemAnimationStyle(for itemDelta: IndexDelta) -> AnimationStyle {
        // option to suppress deltas that result in undesired animations
        return .preciseAnimations
    }

    func animateAlongsideUpdate(with duration: TimeInterval) {
        // animate alongside the table view animation here
    }
}

extension ScenarioSevenViewController: CollectionDataDeletionNotificationDelegate {
    
    func didDeleteItems(_ items: [CarouselRow]) {
        // logging, analytics, or action hooks here
    }
}

extension ScenarioSevenViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CarouselTableViewCell.reuseIdentifier, for: indexPath)
        guard let carouselCell = cell as? CarouselTableViewCell else {
            return cell
        }
        
        let carouselRow = collectionData[indexPath.item]
        let dataSource = _carouselDataSource(for: carouselRow.identifier)
        carouselCell.register(with: dataSource)
        dataSource.update(with: carouselRow.movies)

        return carouselCell
    }
}

extension ScenarioSevenViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CarouselTableViewCell.cellHeight
    }
}

// MARK: CarouselDataCoordinatorDelegate

extension ScenarioSevenViewController: CarouselDataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [CarouselRow]) {
        collectionData.update(data)
    }
}


