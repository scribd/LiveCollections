//
//  MultiSectionCustomAnimationStyleTableView.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

final class MultiSectionCustomAnimationStyleTableView: CustomAnimationStyleTableView, TableViewRowAnimationProviding, TableViewSectionAnimationProviding {

    private typealias Section = Int
    private var rowAnimationModels: [Section: TableViewAnimationModel] = [:]
    private var sectionAnimationModels: [Section: TableViewAnimationModel] = [:]

    override init(tableView: UITableView) {
        super.init(tableView: tableView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addTableView(_ tableView: UITableView,
                      section: Int,
                      rowAnimations: TableViewAnimationModel,
                      sectionAnimations: TableViewAnimationModel) {
        
        guard targetTableView === tableView else {
            assertionFailure("Attemping to add a Synchronizer to different \(UITableView.self) objects. This is not allowed.")
            return
        }

        guard rowAnimationModels[section] == nil, sectionAnimationModels[section] == nil else {
            assertionFailure("Attemping to set multiple views to the same section. Make sure to set the section values before assigning a synchronizer.")
            return
        }
        
        rowAnimationModels[section] = rowAnimations
        sectionAnimationModels[section] = sectionAnimations
    }
    
    // MARK: TableViewRowAnimationProviding
    
    func deleteAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard let animationModel = rowAnimationModels[section] else { return nil }
        return animationModel.deleteAnimation
    }
    
    func insertAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard let animationModel = rowAnimationModels[section] else { return nil }
        return animationModel.insertAnimation
    }
    
    func reloadAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard let animationModel = rowAnimationModels[section] else { return nil }
        return animationModel.reloadAnimation
    }
    
    // MARK: TableViewSectionAnimationProviding
    
    func sectionDeleteAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard let animationModel = sectionAnimationModels[section] else { return nil }
        return animationModel.deleteAnimation
    }
    
    func sectionInsertAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard let animationModel = sectionAnimationModels[section] else { return nil }
        return animationModel.insertAnimation
    }
    
    func sectionReloadAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard let animationModel = sectionAnimationModels[section] else { return nil }
        return animationModel.reloadAnimation
    }
}
