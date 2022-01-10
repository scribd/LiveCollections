//
//  TableViewRowAnimationProviding.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

public protocol TableViewRowAnimationProviding {
    func deleteRowAnimation(for section: Int) -> UITableView.RowAnimation?
    func insertRowAnimation(for section: Int) -> UITableView.RowAnimation?
    func reloadRowAnimation(for section: Int) -> UITableView.RowAnimation?
}

public protocol TableViewSectionAnimationProviding: AnyObject {
    func deleteSectionAnimation(for section: Int) -> UITableView.RowAnimation?
    func insertSectionAnimation(for section: Int) -> UITableView.RowAnimation?
    func reloadSectionAnimation(for section: Int) -> UITableView.RowAnimation?
}

public struct TableViewAnimationModel {
    public let deleteAnimation: UITableView.RowAnimation
    public let insertAnimation: UITableView.RowAnimation
    public let reloadAnimation: UITableView.RowAnimation
    
    public init(deleteAnimation: UITableView.RowAnimation,
                insertAnimation: UITableView.RowAnimation,
                reloadAnimation: UITableView.RowAnimation) {
        self.deleteAnimation = deleteAnimation
        self.insertAnimation = insertAnimation
        self.reloadAnimation = reloadAnimation
    }
    
    public static var defaultRowAnimations: TableViewAnimationModel {
        return TableViewAnimationModel(deleteAnimation: TableViewRowConstants.defaultDeleteAnimation,
                                       insertAnimation: TableViewRowConstants.defaultInsertAnimation,
                                       reloadAnimation: TableViewRowConstants.defaultReloadAnimation)
    }

    public static var defaultSectionAnimations: TableViewAnimationModel {
        return TableViewAnimationModel(deleteAnimation: TableViewSectionConstants.defaultDeleteAnimation,
                                       insertAnimation: TableViewSectionConstants.defaultInsertAnimation,
                                       reloadAnimation: TableViewSectionConstants.defaultReloadAnimation)
    }
}
