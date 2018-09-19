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
 immediately and automatically.  So calling `update` or `append` is all you need to do.
 
 Nil view (non-reactive):
 Without an assigned view, you give your app more flexibility to manage the timing of the animation.
 This occurs in a few steps:
 1) Calculate the delta
 2) Create a data update closure that calls either `update` or `append`
 3) Call one of the animation actions on your view defined in `DeltaUpdatableView`, passing in your data update closure
 
 NOTE: See `UniquelyIdentifiableDataFactory` for how to make your data type UniquelyIdentifiable and
 available to be used with this class.
*/

public final class CollectionData<DataType: UniquelyIdentifiable>: CollectionDataActionsInterface, RowDataProvider, CollectionViewProvider {
    
    // UITableView, UICollectionView, or a custom view
    // Assign to animate view as soon as data is updated, otherwise you must manually call `calculateDelta`
    private weak var _view: DeltaUpdatableView?
    public var view: DeltaUpdatableView? {
        get { return dataQueue.sync { _view } }
        set {
            dataQueue.async(flags: .barrier) { self._view = newValue }
            if Thread.isMainThread  { self.view?.reloadData() }
            else { DispatchQueue.main.sync { return self.view?.reloadData() } }
        }
    }
    
    // delegate
    public weak var validationDelegate: CollectionDataReusableViewVerificationDelegate?
    public weak var reloadDelegate: CollectionDataManualReloadDelegate?
    private var deletionNotificationDelegate: AnyCollectionDataDeletionNotificationDelegate<DataType>?
    
    // data
    private let dataFactory: AnyUniquelyIdentifiableDataFactory<DataType>
    private var _rows: [DataType]
    var rows: [DataType] {
        get { return dataQueue.sync { _rows } }
        set { dataQueue.async(flags: .barrier) { self._rows = newValue } }
    }

    // calculator
    private let dataCalculator = RowDataCalculator<DataType>()

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
        self._rows = dataFactory.buildUniquelyIdentifiableData(rawData)
        self._section = section
    }
    
    public func setDeletionNotificationDelegate<Delegate: CollectionDataDeletionNotificationDelegate>(_ delegate: Delegate) where Delegate.DataType == DataType {
        self.deletionNotificationDelegate = AnyCollectionDataDeletionNotificationDelegate(delegate)
    }
    
    // MARK: CollectionDataStateInterface
    
    public var count: Int {
        return rows.count
    }
    
    public var isEmpty: Bool {
        return rows.isEmpty
    }

    public subscript(index: Int) -> DataType {
        return rows[index]
    }
    
    public func forEach(_ iteration: (DataType) -> Void) {
        rows.forEach(iteration)
    }

    public var snapshot: [DataType] {
        return rows
    }
    
    // MARK: CollectionDataFixedSectionInterface
    
    private var _section: Int
    public var section: Int {
        get { return dataQueue.sync { _section } }
        set { dataQueue.async(flags: .barrier) { self._section = newValue } }
    }
    
    // MARK: CollectionDataActionsInterface
    
    public func calculateDelta(_ rawData: [DataType.RawType]) -> IndexDelta {
        return calculationQueue.sync {
            let uniquelyIdentifiableData = dataFactory.buildUniquelyIdentifiableData(rawData)
            return dataCalculator.calculateDelta(uniquelyIdentifiableData, rowProvider: self)
        }
    }
    
    public func calculateAppendDelta(_ rawData: [DataType.RawType]) -> IndexDelta {
        return calculationQueue.sync {
            let uniquelyIdentifiableData = dataFactory.buildUniquelyIdentifiableData(rawData)
            return dataCalculator.calculateAppendDelta(uniquelyIdentifiableData, rowProvider: self)
        }
    }
    
    public func update(_ rawData: [DataType.RawType], completion: (() -> Void)? = nil) {
        calculationQueue.async {
            if let view = self._validView() {
                self.updateAndAnimate(rawData, view: view, completion: completion)
            } else {
                self.rows = self.dataFactory.buildUniquelyIdentifiableData(rawData)
                completion?()
            }
        }
    }
    
    public func append(_ rawData: [DataType.RawType], completion: (() -> Void)? = nil) {
        calculationQueue.async {
            if let view = self._validView() {
                self.appendAndAnimate(rawData, view: view, completion: completion)
            } else {
                self.rows = self.rows + self.dataFactory.buildUniquelyIdentifiableData(rawData)
                completion?()
            }
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
    
    private func updateAndAnimate(_ rawData: [DataType.RawType], view: DeltaUpdatableView, completion: (() -> Void)?) {
        let uniquelyIdentifiableData = dataFactory.buildUniquelyIdentifiableData(rawData)
        dataCalculator.updateAndAnimate(uniquelyIdentifiableData,
                                        rowProvider: self,
                                        section: section,
                                        viewProvider: viewProvider,
                                        reloadDelegate: reloadDelegate,
                                        deletionDelegate: deletionNotificationDelegate,
                                        completion: completion)
    }
    
    private func appendAndAnimate(_ rawData: [DataType.RawType], view: DeltaUpdatableView, completion: (() -> Void)?) {
        if let validationDelegate = validationDelegate, validationDelegate.isDataSourceValid(for: view) == false { return }
        let uniquelyIdentifiableData = dataFactory.buildUniquelyIdentifiableData(rawData)
        dataCalculator.appendAndAnimate(uniquelyIdentifiableData,
                                        rowProvider: self,
                                        section: section,
                                        viewProvider: viewProvider,
                                        completion: completion)
    }
}

extension CollectionData where DataType == DataType.RawType {
    
    public convenience init(_ rawData: [DataType.RawType] = [], section: Int = 0) {
        let identityFactory = IdentityDataFactory<DataType>()
        let anyDataFactory = AnyUniquelyIdentifiableDataFactory(identityFactory)
        self.init(anyDataFactory: anyDataFactory, rawData: rawData, section: section)
    }
}
