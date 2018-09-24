//
//  ScenarioEightViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/3/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class ScenarioEightViewController: UIViewController {
    
    private let presentationView = PresentationView()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    private let dataCoordinator: MultiSectionCarouselDataCoordinator
    private let imageLoader: MovieImageLoaderInterface
    private var sectionHeaderViews: [Int: UIView] = [:]
    private var carouselDataSources: [String: CarouselController] = [:]
    private lazy var collectionData: CollectionSectionData<CarouselSection> = {
        let data = CollectionSectionData<CarouselSection>(view: tableView)
        data.reloadDelegate = self
        data.setDeletionNotificationDelegate(self)
        return data
    }()
    
    init(dataCoordinator: MultiSectionCarouselDataCoordinator, imageLoader: MovieImageLoaderInterface) {
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

extension ScenarioEightViewController: CollectionSectionDataManualReloadDelegate {

    func preferredItemAnimationStyle(for itemDelta: IndexDelta) -> AnimationStyle {
        // option to suppress deltas that result in undesired animations
        return .preciseAnimations
    }

    func preferredSectionAnimationStyle(for sectionDelta: IndexDelta) -> AnimationStyle {
        // option to suppress deltas that result in undesired animations
        return .preciseAnimations
    }

    func willHandleReload(at indexPath: IndexPath) -> Bool {
        return true
    }
    
    func reloadItems(at indexPaths: [IndexPath], completion: @escaping (IndexPath) -> Void) {

        for indexPath in indexPaths {
            let carouselRow = collectionData[indexPath]
            let dataSource = _carouselDataSource(for: carouselRow.identifier)
            
            let itemCompletion = {
                completion(indexPath)
            }
            
            dataSource.update(with: carouselRow.movies, completion: itemCompletion)
        }
    }
}

extension ScenarioEightViewController: CollectionDataDeletionNotificationDelegate {

    func didDeleteItems(_ items: [CarouselRow]) {
        // logging, analytics, or action hooks here
    }
}

extension ScenarioEightViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return collectionData.sectionCount
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionData.itemCount(forSection: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CarouselTableViewCell.reuseIdentifier, for: indexPath)
        guard let carouselCell = cell as? CarouselTableViewCell else {
            return cell
        }
        
        let carouselRow = collectionData[indexPath]
        let dataSource = _carouselDataSource(for: carouselRow.identifier)
        carouselCell.register(with: dataSource)
        dataSource.update(with: carouselRow.movies)

        return carouselCell
    }
}

extension ScenarioEightViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CarouselTableViewCell.cellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = sectionHeaderViews[section] { return view }
        let label = UILabel()
        label.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.text = "Section \(section)"
        label.textAlignment = .center
        sectionHeaderViews[section] = label
        return label
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
}

// MARK: MultiSectionCarouselDataCoordinatorDelegate

extension ScenarioEightViewController: MultiSectionCarouselDataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [CarouselSection]) {
        collectionData.update(data)
    }
}
