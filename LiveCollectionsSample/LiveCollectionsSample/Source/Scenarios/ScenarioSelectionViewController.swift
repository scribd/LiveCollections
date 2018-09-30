//
//  ScenarioSelectionViewController.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

final class ScenarioSelectionViewController: UIViewController {
    
    private lazy var tableView: UITableView = {
       let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.separatorColor = .lightGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ScenarioDescrpitionTableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        return tableView
    }()
    
    private let scenarioProvider: ScenarioProviderInterface
    
    init(scenarioProvider: ScenarioProviderInterface) {
        self.scenarioProvider = scenarioProvider
        super.init(nibName: nil, bundle: nil)
        self.title = "Scenarios"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = tableView
    }
}

extension ScenarioSelectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scenarioProvider.scenarios.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        let example = scenarioProvider.scenarios[indexPath.item]
        configureCell(cell, for: example)
        return cell
    }
}

extension ScenarioSelectionViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let example = scenarioProvider.scenarios[indexPath.item]
        let exampleController = scenarioProvider.viewController(for: example)
        exampleController.title = example.title
        navigationController?.pushViewController(exampleController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private extension ScenarioSelectionViewController {

    func configureCell(_ cell: UITableViewCell, for example: Scenario) {
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        cell.textLabel?.textColor = UIColor(red: 35/255, green: 35/255, blue: 180/255, alpha: 1)
        cell.textLabel?.text = example.name
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .darkGray
        cell.detailTextLabel?.text = example.description
    }
    
    enum Constants {
        static let cellIdentifier = "ScenarioSelectionViewControllerCellIdentifier"
    }
}

private final class ScenarioDescrpitionTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        detailTextLabel?.numberOfLines = 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
