//
//  SingleSectionCustomAnimationStyleTableView.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

final class SingleSectionCustomAnimationStyleTableView: CustomAnimationStyleTableView, TableViewSingleSectionProviding, TableViewRowAnimationProviding, TableViewSectionAnimationProviding, TableViewFixedRowAnimationProviding, TableViewFixedSectionAnimationProviding {
    
    let section: Int
    
    let deleteAnimation: UITableView.RowAnimation
    let insertAnimation: UITableView.RowAnimation
    let reloadAnimation: UITableView.RowAnimation

    let sectionDeleteAnimation: UITableView.RowAnimation
    let sectionInsertAnimation: UITableView.RowAnimation
    let sectionReloadAnimation: UITableView.RowAnimation

    init(tableView: UITableView,
         section: Int,
         rowAnimations: TableViewAnimationModel,
         sectionAnimations: TableViewAnimationModel) {
        self.section = section
        self.deleteAnimation = rowAnimations.deleteAnimation
        self.insertAnimation = rowAnimations.insertAnimation
        self.reloadAnimation = rowAnimations.reloadAnimation
        self.sectionDeleteAnimation = sectionAnimations.deleteAnimation
        self.sectionInsertAnimation = sectionAnimations.insertAnimation
        self.sectionReloadAnimation = sectionAnimations.reloadAnimation
        super.init(tableView: tableView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
