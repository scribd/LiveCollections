//
//  CollectionData.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/16/17.
//  Copyright © 2017 Scribd. All rights reserved.
//

import Foundation

/**
 This is a tool for the most common case:
 A collection/table view with a single section.
 
 There are two ways to use this object, by assigning a view or by leaving the view nil.
 
 Assigning a view (reactive):
 If there is an assigned view (UITableView, UICollectionView, or DiscreteSectionsView), any time you
 call the `update` or `append` functions, the delta calculation and resulting animation will be performed
 immediately and automatically. So calling `update` or `append` is all you need to do.
 
 Nil view (non-reactive):
 Without an assigned view, you give your app more flexibility to manage the timing of the animation.
 This occurs in a few steps:
 1) Calculate the delta
 2) Create a data update closure that calls either `update` or `append`
 3) Call one of the animation actions on your view defined in `DeltaUpdatableView`, passing in your data update closure
 
 NOTE: See `UniquelyIdentifiableDataFactory` for how to make your data type UniquelyIdentifiable and
 available to be used with this class.
*/

public final class CollectionData<DataType: UniquelyIdentifiable>: CollectionDataActionsInterface, ItemDataProvider, ItemCalculatingDataProvider, CollectionViewProvider, CollectionDataSynchronizable {
    
    // UITableView, UICollectionView, or a custom view
    // Assign to animate view as soon as data is updated, otherwise you must manually call `calculateDelta`
    private weak var _view: DeltaUpdatableView?
    public var view: DeltaUpdatableView? {
        get { return dataQueue.sync {
            if let synchronizer = self.synchronizer { return synchronizer }
            return _view
        }
        }
        set {
            dataQueue.async(flags: .barrier) {
                self._view = newValue
                self.synchronizer?.view = newValue
            }
            if Thread.isMainThread { self.view?.reloadData() }
            else { DispatchQueue.main.sync { return self.view?.reloadData() } }
        }
    }
    
    private var _customTableView: UITableView?
    
    // delegate
    public weak var validationDelegate: CollectionDataReusableViewVerificationDelegate?
    public weak var reloadDelegate: CollectionDataManualReloadDelegate?
    private var deletionNotificationDelegate: AnyCollectionDataDeletionNotificationDelegate<DataType>?
    
    // data
    private let dataFactory: AnyUniquelyIdentifiableDataFactory<DataType>
    private var _items: [DataType]
    internal(set) public var items: [DataType] {
        get { return dataQueue.sync { _items } }
        set { dataQueue.async(flags: .barrier) { self._items = newValue } }
    }
    
    private var _calculatingItems: [DataType.RawType]?
    internal(set) public var calculatingItems: [DataType.RawType]? {
        get { return dataQueue.sync { _calculatingItems } }
        set {
            dataQueue.async(flags: .barrier) {
                guard self._calculatingItems == nil || newValue == nil else { return } // prevent overriding data incorrectly
                self._calculatingItems = newValue
            }
        }
    }
    
    // calculator
    private let dataCalculator = ItemDataCalculator<DataType>()

    // syncronizer
    public var synchronizer: CollectionDataSynchronizer? {
        didSet { dataQueue.async(flags: .barrier) { self.synchronizer?.view = self._view } }
    }
    
    // animation threshold
    public var dataCountAnimationThreshold: Int = 10000

    // thread safety
    private let dataQueue = DispatchQueue(label: "\(CollectionData.self) data dispatch queue", attributes: .concurrent)
    private let calculationQueue = DispatchQueue(label: "\(CollectionData.self) calculation dispatch queue")

    public convenience init<DataFactory>(dataFactory: DataFactory, rawData: [DataType.RawType] = [], section: Int = 0) where DataFactory: UniquelyIdentifiableDataFactory, DataFactory.RawType == DataFactory.UniquelyIdentifiableType.RawType, DataFactory.UniquelyIdentifiableType == DataType {
        let anyDataFactory = AnyUniquelyIdentifiableDataFactory(dataFactory)
        self.init(anyDataFactory: anyDataFactory, rawData: rawData, section: section)
    }
    
    private init(anyDataFactory: AnyUniquelyIdentifiableDataFactory<DataType>, rawData: [DataType.RawType] = [], section: Int = 0) {
        self.dataFactory = anyDataFactory
        self._items = dataFactory.buildUniquelyIdentifiableData(rawData)
        self._section = section
    }
    
    public func setDeletionNotificationDelegate<Delegate: CollectionDataDeletionNotificationDelegate>(_ delegate: Delegate) where Delegate.DataType == DataType {
        self.deletionNotificationDelegate = AnyCollectionDataDeletionNotificationDelegate(delegate)
    }
    
    // MARK: CollectionDataStateInterface
    
    public var count: Int {
        return items.count
    }
    
    public var isEmpty: Bool {
        return items.isEmpty
    }

    public var isCalculating: Bool {
        guard let calculatingItems = calculatingItems else { return false }
        return calculatingItems.isEmpty == false
    }
    
    public subscript(index: Int) -> DataType {
        return items[index]
    }

    // MARK: CollectionDataFixedSectionInterface
    
    private var _section: Int
    public var section: Int {
        get { return dataQueue.sync { _section } }
        set { dataQueue.async(flags: .barrier) { self._section = newValue } }
    }
    
    // MARK: CollectionDataActionsInterface
    
    public func calculateDeltaSync(_ rawData: [DataType.RawType]) -> IndexDelta {
        return calculationQueue.sync {
            let uniquelyIdentifiableData = dataFactory.buildUniquelyIdentifiableData(rawData)
            return dataCalculator.calculateDelta(uniquelyIdentifiableData, itemProvider: self)
        }
    }

    public func calculateDeltaAsync(_ rawData: [DataType.RawType], completion: @escaping (IndexDelta) -> Void) {
        calculationQueue.async {
            let uniquelyIdentifiableData = self.dataFactory.buildUniquelyIdentifiableData(rawData)
            completion(self.dataCalculator.calculateDelta(uniquelyIdentifiableData, itemProvider: self))
        }
    }
    
    public func calculateAppendDelta(_ rawData: [DataType.RawType]) -> IndexDelta {
        return calculationQueue.sync {
            let uniquelyIdentifiableData = dataFactory.buildUniquelyIdentifiableData(rawData)
            return dataCalculator.calculateAppendDelta(uniquelyIdentifiableData, itemProvider: self)
        }
    }
    
    public func update(_ rawData: [DataType.RawType], completion: (() -> Void)? = nil) {

        if view == nil {
            updateDataOnly(rawData, completion: completion)
        } else {
            updateAndAnimate(rawData, completion: completion)
        }
    }
    
    public func append(_ rawData: [DataType.RawType], completion: (() -> Void)? = nil) {
        if view == nil {
            appendDataOnly(rawData, completion: completion)
        } else {
            appendAndAnimate(rawData, completion: completion)
        }
    }
    
    // MARK: Private
    
    private func _validView() -> DeltaUpdatableView? {
        guard let view = self.view else { return nil }
        guard let validationDelegate = validationDelegate else { return view }
        
        let validationFromDelegate: () -> DeltaUpdatableView? = {
            let isValid = validationDelegate.isDataSourceValid(for: view)
            return isValid ? view : nil
        }
        
        guard Thread.isMainThread == false else { return validationFromDelegate() }
        return DispatchQueue.main.sync { return validationFromDelegate() }
    }
    
    private var viewProvider: CollectionViewProvider {
        if let selfProvidableView = view as? CollectionViewProvider { return selfProvidableView }
        return self
    }

    private func updateDataOnly(_ rawData: [DataType.RawType], completion: (() -> Void)?) {
        self.items = self.dataFactory.buildUniquelyIdentifiableData(rawData)
        completion?()
    }
    
    private func updateAndAnimate(_ rawData: [DataType.RawType], completion: (() -> Void)?) {
        let shouldAppend: Bool = {
            guard let calculatingItems = calculatingItems else { return isEmpty }
            return calculatingItems.isEmpty
        }()
        
        guard shouldAppend == false else {
            appendAndAnimate(rawData, completion: completion)
            return
        }

        calculatingItems = rawData
        calculationQueue.async {
            guard self._validView() != nil else {
                self.calculatingItems = nil
                self.updateDataOnly(rawData, completion: completion)
                return
            }

            let uniquelyIdentifiableData = self.dataFactory.buildUniquelyIdentifiableData(rawData)
            self.dataCalculator.updateAndAnimate(uniquelyIdentifiableData,
                                                 rawData: rawData,
                                                 itemProvider: self,
                                                 section: self.section,
                                                 viewProvider: self.viewProvider,
                                                 reloadDelegate: self.reloadDelegate,
                                                 deletionDelegate: self.deletionNotificationDelegate,
                                                 completion: completion)
        }
    }

    private func appendDataOnly(_ rawData: [DataType.RawType], completion: (() -> Void)?) {
        self.items = self.items + self.dataFactory.buildUniquelyIdentifiableData(rawData)
        completion?()
    }

    private func appendAndAnimate(_ rawData: [DataType.RawType], completion: (() -> Void)?) {
        calculatingItems = rawData
        calculationQueue.async {
            guard self._validView() != nil else {
                self.calculatingItems = nil
                self.appendDataOnly(rawData, completion: completion)
                return
            }
            
            let uniquelyIdentifiableData = self.dataFactory.buildUniquelyIdentifiableData(rawData)
            self.dataCalculator.appendAndAnimate(uniquelyIdentifiableData,
                                                 rawData: rawData,
                                                 itemProvider: self,
                                                 section: self.section,
                                                 viewProvider: self.viewProvider,
                                                 reloadDelegate: self.reloadDelegate,
                                                 completion: completion)
        }
    }
}

// MARK: - Identity Data

public extension CollectionData where DataType == DataType.RawType {
    
    public convenience init(_ rawData: [DataType.RawType] = [], section: Int = 0) {
        let identityFactory = IdentityDataFactory<DataType>()
        self.init(dataFactory: identityFactory, rawData: rawData, section: section)
    }
}

// MARK: - Non-unique Data

public typealias NonUniqueCollectionData<NonUniqueDataType: NonUniquelyIdentifiable> = CollectionData<NonUniqueDatum<NonUniqueDataType>>

public extension NonUniqueCollectionData where DataType.RawType: NonUniquelyIdentifiable {
    
    public convenience init<RawType>(_ rawData: [RawType] = [], section: Int = 0) where DataType == NonUniqueDatum<RawType> {
        let duplicatableFactory = NonUniqueDataFactory<RawType>()
        self.init(dataFactory: duplicatableFactory, rawData: rawData, section: section)
    }
}

// MARK: - Setting UITableView Animation Style

public extension CollectionData {
    
    public func setTableView(_ tableView: UITableView,
                             rowAnimations: TableViewAnimationModel,
                             sectionReloadAnimation: UITableView.RowAnimation = .none) {
        
        let sectionAnimations = TableViewAnimationModel(deleteAnimation: TableViewSectionConstants.defaultDeleteAnimation,
                                                        insertAnimation: TableViewSectionConstants.defaultInsertAnimation,
                                                        reloadAnimation: sectionReloadAnimation)
        
        self._customTableView = CustomAnimationStyleTableView(tableView: tableView,
                                                              section: section,
                                                              rowAnimations: rowAnimations,
                                                              sectionAnimations: sectionAnimations)
        self.view = _customTableView
    }
}
