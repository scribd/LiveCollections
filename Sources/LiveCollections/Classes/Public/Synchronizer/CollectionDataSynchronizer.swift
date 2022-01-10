//
//  CollectionDataSynchronizer.swift
//  LiveCollections
//
//  Created by Stephane Magne on 9/26/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

public final class CollectionDataSynchronizer: DeltaUpdatableView {
    
    private(set) weak var view: DeltaUpdatableView?
    private var _customTableView: MultiSectionCustomAnimationStyleTableView?
    
    private let timingQueue = DispatchQueue(label: "\(CollectionDataSynchronizer.self) timing queue")
    private let dataQueue = DispatchQueue(label: "\(CollectionDataSynchronizer.self) data queue")

    private typealias Section = Int
    private var updates: [Section: SectionUpdate] = [:]
    
    public enum BatchDelay {
        case none
        case short
        case long
        case custom(milliseconds: Int)
        
        var deadline: DispatchTime {
            switch self {
            case .none: return .now()
            case .short: return .now() + .milliseconds(10)
            case .long: return .now() + .milliseconds(100)
            case .custom(let ms): return .now() + .milliseconds(ms)
            }
        }
    }
    private var batchDelay: BatchDelay
    
    public init(delay: BatchDelay = .short) {
        self.batchDelay = delay
    }
    
    func setView(_ view: DeltaUpdatableView?, section: Int) {
        guard let tableView = view as? UITableView else {
            if self.view != nil, self.view !== view {
                assertionFailure("Attemping to add a Synchronizer to different view objects. This is not allowed.")
                return
            }
            
            self.view = view
            return
        }
        
        if let singleSectionProvider = tableView as? SingleSectionCustomAnimationStyleTableView,
            let targetTableView = singleSectionProvider.targetTableView {
            let customTableView = self.customTableView(for: targetTableView)
            customTableView.addTableView(targetTableView,
                                         section: section,
                                         rowAnimations: singleSectionProvider.rowAnimationModel,
                                         sectionAnimations: singleSectionProvider.sectionAnimationModel)
        } else {
            let customTableView = self.customTableView(for: tableView)
            customTableView.addTableView(tableView,
                                         section: section,
                                         rowAnimations: .defaultRowAnimations,
                                         sectionAnimations: .defaultSectionAnimations)
        }
    }
    
    private func customTableView(for tableView: UITableView) -> MultiSectionCustomAnimationStyleTableView {
        if let customTableView = _customTableView {
            return customTableView
        } else {
            let view = MultiSectionCustomAnimationStyleTableView(tableView: tableView)
            _customTableView = view
            self.view = view
            return view
        }
    }
    
    private func add(update: SectionUpdate) {
        dataQueue.sync {
            if self.updates.isEmpty {
                self._fireAnimationEvent()
            }
            
            let section = update.section
            if let existingUpdates = self.updates[section]  {
                self._performAnimations(for: [existingUpdates])
            }
            
            updates[section] = update
        }
    }
    
    private func _fireAnimationEvent() {
        timingQueue.asyncAfter(deadline: batchDelay.deadline) {
            let allUpdates: [SectionUpdate] = self.dataQueue.sync {
                let allUpdates = Array(self.updates.values)
                self.updates = [:]
                return allUpdates
            }
            
            self._performAnimations(for: allUpdates)
        }
    }
    
    private func _performAnimations(for sectionUpdates: [SectionUpdate]) {
        DispatchQueue.main.async {
            self.view?.performAnimations(for: sectionUpdates)
        }
    }
    
    // MARK: DeltaUpdatableView

    public var frame: CGRect {
        return view?.frame ?? .zero
    }

    public func reloadData() {
        view?.reloadData()
    }
    
    public func reloadSections(for sectionUpdates: [SectionUpdate]) {
        view?.reloadSections(for: sectionUpdates)
    }
    
    public func performAnimations(delta: IndexDelta, updateData: @escaping () -> Void) {
        performAnimations(section: 0, delta: delta, delegate: nil, updateData: updateData, completion: nil)
    }
    
    public func performAnimations(section: Int, delta: IndexDelta, delegate: DeltaUpdatableViewDelegate?, updateData: @escaping () -> Void, completion: (() -> Void)?) {
        let sectionUpdate = SectionUpdate(section: section, delta: delta, delegate: delegate, update: updateData, completion: completion)
        performAnimations(for: [sectionUpdate])
    }
    
    public func performAnimations(for sectionUpdates: [SectionUpdate]) {
        sectionUpdates.forEach { add(update: $0)}
    }
    
    // MARK: Override pointer equality
    
    static func === (lhs: CollectionDataSynchronizer, rhs: UIView) -> Bool {
        return lhs.view === rhs
    }
    
    static func === (lhs: UIView, rhs: CollectionDataSynchronizer) -> Bool {
        return lhs === rhs.view
    }
}
