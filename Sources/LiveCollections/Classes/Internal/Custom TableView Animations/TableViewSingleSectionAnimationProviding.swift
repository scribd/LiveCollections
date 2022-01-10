//
//  TableViewSingleSectionAnimationProviding.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

protocol TableViewSingleSectionProviding {
    var section: Int { get }
}

protocol TableViewFixedRowAnimationProviding {
    var deleteRowAnimation: UITableView.RowAnimation { get }
    var insertRowAnimation: UITableView.RowAnimation { get }
    var reloadRowAnimation: UITableView.RowAnimation { get }
}

protocol TableViewFixedSectionAnimationProviding {
    var deleteSectionAnimation: UITableView.RowAnimation { get }
    var insertSectionAnimation: UITableView.RowAnimation { get }
    var reloadSectionAnimation: UITableView.RowAnimation { get }
}

// MARK: Extension TableViewFixedRowAnimationProviding

extension TableViewFixedRowAnimationProviding {
    
    var rowAnimationModel: TableViewAnimationModel {
        return TableViewAnimationModel(deleteAnimation: deleteRowAnimation,
                                       insertAnimation: insertRowAnimation,
                                       reloadAnimation: reloadRowAnimation)
    }
}

// MARK: Extension TableViewFixedSectionAnimationProviding

extension TableViewFixedSectionAnimationProviding {
    
    var sectionAnimationModel: TableViewAnimationModel {
        return TableViewAnimationModel(deleteAnimation: deleteSectionAnimation,
                                       insertAnimation: insertSectionAnimation,
                                       reloadAnimation: reloadSectionAnimation)
    }
}

// MARK: Extension TableViewSingleSectionProviding + TableViewFixedRowAnimationProviding

extension TableViewRowAnimationProviding where Self: TableViewSingleSectionProviding, Self: TableViewFixedRowAnimationProviding {

    func deleteRowAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return deleteRowAnimation
    }
    
    func insertRowAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return insertRowAnimation
    }
    
    func reloadRowAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return reloadRowAnimation
    }

}

extension TableViewRowAnimationProviding where Self: TableViewSingleSectionProviding, Self: TableViewFixedSectionAnimationProviding {

    func deleteSectionAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return deleteSectionAnimation
    }
    
    func insertSectionAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return insertSectionAnimation
    }
    
    func reloadSectionAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return reloadSectionAnimation
    }
}
