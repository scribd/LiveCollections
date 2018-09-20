//
//  CollectionSectionData.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/15/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import Foundation

/**
 This is a tool for the scenario:
 A collection/table view that has multiple sections where data items are unique across all sections.
 (e.g. a data item in section 0 will not also appear in section 3)
 
 Due to the timing nature of animations, a view must be set on this object and all animations will
 be performed automatically.

 Much like the use of CollectionData, you only need to call `update` or `append`.  However to use
 this class, you will need to create a section based data structure that adheres to
 `UniquelyIdentifiableSection`.
 */

public final class CollectionSectionData<SectionType: UniquelyIdentifiableSection>: CollectionSectionDataActionsInterface, SectionDataProvider {
    
    public typealias DataType = SectionType.DataType
    
    // table or collection view
    private let view: SectionDeltaUpdatableView
    
    // delegate
    public weak var reloadDelegate: CollectionSectionDataManualReloadDelegate?
    private var deletionNotificationDelegate: AnyCollectionDataDeletionNotificationDelegate<DataType>?
    
    // section data
    private var _sections: [SectionType]
    var sections: [SectionType] {
        get { return dataQueue.sync { _sections } }
        set { dataQueue.async(flags: .barrier) { self._sections = newValue } }
    }
    
    // row data
    private var _rows: [DataType]
    var rows: [DataType] {
        get { return dataQueue.sync { _rows } }
        set { dataQueue.async(flags: .barrier) { self._rows = newValue } }
    }

    // calculator
    private let dataCalculator = SectionDataCalculator<SectionType>()
    
    // animation threshold
    public var dataCountAnimationThreshold: Int = 10000
    
    // thread safety
    private let dataQueue = DispatchQueue(label: "\(CollectionSectionData.self) dispatch queue", attributes: .concurrent)
    private let calculationQueue = DispatchQueue.main
        //DispatchQueue(label: "\(CollectionSectionData.self) calculation dispatch queue")

    public init(view: SectionDeltaUpdatableView, sectionData: [SectionType] = []) {
        self.view = view
        self._sections = sectionData
        self._rows = dataCalculator.orderedRows(for: sectionData)
    }
    
    public func setDeletionNotificationDelegate<Delegate: CollectionDataDeletionNotificationDelegate>(_ delegate: Delegate) where Delegate.DataType == DataType {
        self.deletionNotificationDelegate = AnyCollectionDataDeletionNotificationDelegate(delegate)
    }
    
    // MARK: CollectionSectionDataStateInterface
    
    public var sectionCount: Int {
        return sections.count
    }
    
    public var isEmpty: Bool {
        return sections.isEmpty
    }
    
    public func rowCount(forSection section: Int) -> Int {
        return sections[section].items.count
    }

    public subscript(index: Int) -> SectionType {
        return sections[index]
    }
    
    public subscript(section: Int, row: Int) -> DataType {
        return sections[section].items[row]
    }
    
    public subscript(indexPath: IndexPath) -> DataType {
        return self[indexPath.section, indexPath.row]
    }

    public var snapshot: [SectionType] {
        return sections
    }
    
    // MARK: CollectionSectionDataActionsInterface
    
    public func update(_ updatedData: [SectionType], completion: (() -> Void)? = nil) {
        calculationQueue.async {
            self.dataCalculator.updateAndAnimate(updatedData,
                                                 sectionProvider: self,
                                                 view: self.view,
                                                 reloadDelegate: self.reloadDelegate,
                                                 deletionDelegate: self.deletionNotificationDelegate,
                                                 completion: completion)
        }
    }
    
    public func append(_ appendedItems: [SectionType], completion: (() -> Void)? = nil) {
        calculationQueue.async {
            self.dataCalculator.appendAndAnimate(appendedItems,
                                                 sectionProvider: self,
                                                 view: self.view,
                                                 completion: completion)
        }
    }
}
