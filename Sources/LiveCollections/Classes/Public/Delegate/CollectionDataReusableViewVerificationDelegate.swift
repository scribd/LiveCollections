//
//  CollectionDataReusableViewVerificationDelegate.swift
//  LiveCollections
//
//  Created by Stephane Magne on 9/14/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

/**
 This is a specific protocol for the `Table of Carousels` scenario (A UITableView that has a UICollectionView in
 it's row cells). You can read about how this is used here (https://medium.com/p/3bf877e78f50), but the gist is,
 make sure the view object is a UICollectionView and check to see if the dataSource/delegate point to your object.
 
 I've added the most common extensions for classes that adopt both CollectionDataReusableViewVerificationDelegate
 and the UICollectionView delegate methods, but you can implement you own method if you are using custom views
 or an alternate class structure.
 */
public protocol CollectionDataReusableViewVerificationDelegate: AnyObject {
    func isDataSourceValid(for view: DeltaUpdatableView) -> Bool
}

public extension CollectionDataReusableViewVerificationDelegate where Self: UICollectionViewDataSource {
    
    func isDataSourceValid(for view: DeltaUpdatableView) -> Bool {
        guard let collectionView = view as? UICollectionView,
            collectionView.dataSource === self else {
                return false
        }
        
        return true
    }
}

public extension CollectionDataReusableViewVerificationDelegate where Self: UICollectionViewDataSource, Self: UICollectionViewDelegate {
    
    func isDataSourceValid(for view: DeltaUpdatableView) -> Bool {
        guard let collectionView = view as? UICollectionView,
            collectionView.dataSource === self,
            collectionView.delegate === self else {
                return false
        }
        
        return true
    }
}
