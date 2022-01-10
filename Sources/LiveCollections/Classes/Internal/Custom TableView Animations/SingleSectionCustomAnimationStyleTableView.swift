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
    
    let deleteRowAnimation: UITableView.RowAnimation
    let insertRowAnimation: UITableView.RowAnimation
    let reloadRowAnimation: UITableView.RowAnimation
    
    let deleteSectionAnimation: UITableView.RowAnimation
    let insertSectionAnimation: UITableView.RowAnimation
    let reloadSectionAnimation: UITableView.RowAnimation

    init(tableView: UITableView,
         section: Int,
         rowAnimations: TableViewAnimationModel,
         sectionAnimations: TableViewAnimationModel) {
        self.section = section
        self.deleteRowAnimation = rowAnimations.deleteAnimation
        self.insertRowAnimation = rowAnimations.insertAnimation
        self.reloadRowAnimation = rowAnimations.reloadAnimation
        self.deleteSectionAnimation = sectionAnimations.deleteAnimation
        self.insertSectionAnimation = sectionAnimations.insertAnimation
        self.reloadSectionAnimation = sectionAnimations.reloadAnimation
        super.init(tableView: tableView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
