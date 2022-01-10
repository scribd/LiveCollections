//
//  CustomAnimationStyleTableView.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

class CustomAnimationStyleTableView: UITableView {
    
    weak var targetTableView: UITableView?
    
    init(tableView: UITableView) {
        self.targetTableView = tableView
        super.init(frame: .zero, style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var delegate: UITableViewDelegate? {
        get { return targetTableView?.delegate }
        set { }
    }
    
    override var dataSource: UITableViewDataSource? {
        get { return targetTableView?.dataSource }
        set { }
    }
    
    @available(iOS 11.0, *)
    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        guard let targetTableView = targetTableView else {
            updates?()
            completion?(false)
            return
        }
        
        targetTableView.performBatchUpdates(updates, completion: completion)
    }
    
    override func beginUpdates() {
        targetTableView?.beginUpdates()
    }
    
    override func endUpdates() {
        targetTableView?.endUpdates()
    }
    
    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        targetTableView?.deleteRows(at: indexPaths, with: animation)
    }
    
    override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        targetTableView?.insertRows(at: indexPaths, with: animation)
    }
    
    override func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        targetTableView?.moveRow(at: indexPath, to: newIndexPath)
    }
    
    override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        targetTableView?.reloadRows(at: indexPaths, with: animation)
    }
    
    override func deleteSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        targetTableView?.deleteSections(sections, with: animation)
    }
    
    override func insertSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        targetTableView?.insertSections(sections, with: animation)
    }
    
    override func moveSection(_ section: Int, toSection newSection: Int) {
        targetTableView?.moveSection(section, toSection: newSection)
    }
    
    override func reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        targetTableView?.reloadSections(sections, with: animation)
    }
    
    override func reloadData() {
        targetTableView?.reloadData()
    }
    
    override var window: UIWindow? {
        return targetTableView?.window
    }
    
    // MARK: Override pointer equality
    
    // Note: If this is causing you issues, for true equality you will have to use:
    // (tableView === myTableView && tableView.hash == myTableView.hash)

    static func === (lhs: CustomAnimationStyleTableView, rhs: CustomAnimationStyleTableView) -> Bool {
        return lhs.targetTableView === rhs.targetTableView
    }
    
    static func === (lhs: CustomAnimationStyleTableView, rhs: UITableView) -> Bool {
        return lhs.targetTableView === rhs
    }
    
    static func === (lhs: UITableView, rhs: CustomAnimationStyleTableView) -> Bool {
        return lhs === rhs.targetTableView
    }
}

