//
//  ScenarioFourteenViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class ScenarioFourteenViewController: UIViewController {
    
    private let presentationView = PresentationView()
    private let synchronizer = CollectionDataSynchronizer(delay: .short)
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    private let dataCoordinator: DataCoordinator
    private let imageLoader: MovieImageLoaderInterface
    private let dataList: [CollectionData<Movie>]
    private var sectionHeaderViews: [Int: UIView] = [:]
    
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
        presentationView.addViewToPresent(tableView)

        let sectionZeroRowAnimations = TableViewAnimationModel(deleteAnimation: .left,
                                                               insertAnimation: .left,
                                                               reloadAnimation: .left)
        
        dataList[0].setTableView(tableView, rowAnimations: sectionZeroRowAnimations)

        let sectionOneRowAnimations = TableViewAnimationModel(deleteAnimation: .right,
                                                              insertAnimation: .right,
                                                              reloadAnimation: .right)
        
        dataList[1].setTableView(tableView, rowAnimations: sectionOneRowAnimations)

        let sectionTwoRowAnimations = TableViewAnimationModel(deleteAnimation: .top,
                                                              insertAnimation: .top,
                                                              reloadAnimation: .top)
        
        dataList[2].setTableView(tableView, rowAnimations: sectionTwoRowAnimations)

        
        dataList.enumerated().forEach { index, collectionData in
            collectionData.section = index
            collectionData.synchronizer = synchronizer
        }
        
        tableView.register(MovieTableViewCell.self, forCellReuseIdentifier: MovieTableViewCell.reuseIdentifier)
    }
}

extension ScenarioFourteenViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.reuseIdentifier, for: indexPath)
        guard let movieCell = cell as? MovieTableViewCell else {
            return cell
        }
        
        let movie = dataList[indexPath.section][indexPath.item]
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

extension ScenarioFourteenViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MovieTableViewCell.cellHeight
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

// MARK: DataCoordinatorDelegate

extension ScenarioFourteenViewController: DataCoordinatorDelegate {
    
    func dataDidUpdate(_ data: [Movie], section: Int) {
        dataList[section].update(data)
    }
}
