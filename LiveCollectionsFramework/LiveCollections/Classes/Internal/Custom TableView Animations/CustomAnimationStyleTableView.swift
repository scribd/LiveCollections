//
//  CustomAnimationStyleTableView.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

final class CustomAnimationStyleTableView: UITableView, TableViewRowAnimationProviding {
    
    private weak var targetTableView: UITableView?
    private let section: Int

    private let deleteAnimation: UITableView.RowAnimation
    private let insertAnimation: UITableView.RowAnimation
    private let reloadAnimation: UITableView.RowAnimation

    private let sectionDeleteAnimation: UITableView.RowAnimation
    private let sectionInsertAnimation: UITableView.RowAnimation
    private let sectionReloadAnimation: UITableView.RowAnimation

    init(tableView: UITableView,
         section: Int,
         rowAnimations: TableViewAnimationModel,
         sectionAnimations: TableViewAnimationModel) {
        self.targetTableView = tableView
        self.section = section
        self.deleteAnimation = rowAnimations.deleteAnimation
        self.insertAnimation = rowAnimations.insertAnimation
        self.reloadAnimation = rowAnimations.reloadAnimation
        self.sectionDeleteAnimation = sectionAnimations.deleteAnimation
        self.sectionInsertAnimation = sectionAnimations.insertAnimation
        self.sectionReloadAnimation = sectionAnimations.reloadAnimation
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
    
    override func reloadSections(_ sections: IndexSet, with animation: UITableView.RowAnimation) {
        targetTableView?.reloadSections(sections, with: animation)
    }

    override func reloadData() {
        targetTableView?.reloadData()
    }
    
    // MARK: TableViewRowAnimationProviding
    
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
    
    // MARK: Override pointer equality
    
    // Note: If this is causing you issues, for true equality you will have to use:
    // (tableView === myTableView && tableView.hash == myTableView.hash)
    
    static func === (lhs: CustomAnimationStyleTableView, rhs: UITableView) -> Bool {
        return lhs.targetTableView === rhs
    }
    
    static func === (lhs: UITableView, rhs: CustomAnimationStyleTableView) -> Bool {
        return lhs === rhs.targetTableView
    }
}
