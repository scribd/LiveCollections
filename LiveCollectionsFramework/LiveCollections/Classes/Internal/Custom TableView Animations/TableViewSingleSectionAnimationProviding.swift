//
//  TableViewSingleSectionAnimationProviding.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol TableViewSingleSectionProviding {
    var section: Int { get }
}

protocol TableViewAllSectionsProviding { }

protocol TableViewFixedRowAnimationProviding {
    var deleteAnimation: UITableView.RowAnimation { get }
    var insertAnimation: UITableView.RowAnimation { get }
    var reloadAnimation: UITableView.RowAnimation { get }
}

protocol TableViewFixedSectionAnimationProviding {
    var sectionDeleteAnimation: UITableView.RowAnimation { get }
    var sectionInsertAnimation: UITableView.RowAnimation { get }
    var sectionReloadAnimation: UITableView.RowAnimation { get }
}

// MARK: Extension TableViewFixedRowAnimationProviding

extension TableViewFixedRowAnimationProviding {
    
    var rowAnimationModel: TableViewAnimationModel {
        return TableViewAnimationModel(deleteAnimation: deleteAnimation,
                                       insertAnimation: insertAnimation,
                                       reloadAnimation: reloadAnimation)
    }
}

// MARK: Extension TableViewFixedSectionAnimationProviding

extension TableViewFixedSectionAnimationProviding {
    
    var sectionAnimationModel: TableViewAnimationModel {
        return TableViewAnimationModel(deleteAnimation: sectionDeleteAnimation,
                                       insertAnimation: sectionInsertAnimation,
                                       reloadAnimation: sectionReloadAnimation)
    }
}

// MARK: Extension TableViewSingleSectionProviding + TableViewFixedRowAnimationProviding

extension TableViewRowAnimationProviding where Self: TableViewSingleSectionProviding, Self: TableViewFixedRowAnimationProviding {

    func deleteAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return deleteAnimation
    }
    
    func insertAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return insertAnimation
    }
    
    func reloadAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return reloadAnimation
    }

}

extension TableViewRowAnimationProviding where Self: TableViewSingleSectionProviding, Self: TableViewFixedSectionAnimationProviding {

    func sectionDeleteAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return sectionDeleteAnimation
    }
    
    func sectionInsertAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return sectionInsertAnimation
    }
    
    func sectionReloadAnimation(for section: Int) -> UITableView.RowAnimation? {
        guard self.section == section else { return nil }
        return sectionReloadAnimation
    }
}

// MARK: Extension TableViewAllSectionsProviding + TableViewFixedRowAnimationProviding

extension TableViewRowAnimationProviding where Self: TableViewAllSectionsProviding, Self: TableViewFixedRowAnimationProviding {
    
    func deleteAnimation(for section: Int) -> UITableView.RowAnimation? {
        return deleteAnimation
    }
    
    func insertAnimation(for section: Int) -> UITableView.RowAnimation? {
        return insertAnimation
    }
    
    func reloadAnimation(for section: Int) -> UITableView.RowAnimation? {
        return reloadAnimation
    }
}

extension TableViewRowAnimationProviding where Self: TableViewAllSectionsProviding, Self: TableViewFixedSectionAnimationProviding {
    
    func sectionDeleteAnimation(for section: Int) -> UITableView.RowAnimation? {
        return sectionDeleteAnimation
    }
    
    func sectionInsertAnimation(for section: Int) -> UITableView.RowAnimation? {
        return sectionInsertAnimation
    }
    
    func sectionReloadAnimation(for section: Int) -> UITableView.RowAnimation? {
        return sectionReloadAnimation
    }
}
