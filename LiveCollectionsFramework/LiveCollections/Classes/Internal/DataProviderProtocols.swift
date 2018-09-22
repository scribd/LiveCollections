//
//  RowDataProvider.swift
//  LiveCollections
//
//  Created by Stephane Magne on 7/9/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol RowDataProvider: AnyObject {
    associatedtype DataType: UniquelyIdentifiable
    var rows: [DataType] { get set }
    
    // As data sets get large, calculation time becomes expensive, so
    // if either the current data or the updated data exceeds this count,
    // the view will simply call `reloadSection` which performs sort of
    // a smear of an animation rather than item per item animations
    var dataCountAnimationThreshold: Int { get }
}

protocol RowCalculatingDataProvider: AnyObject {
    associatedtype CalculatingRawType
    var calculatingRows: [CalculatingRawType]? { get set }
}

protocol SectionDataProvider: RowDataProvider {
    associatedtype SectionType: UniquelyIdentifiableSection
    var sections: [SectionType] { get set }
}

protocol SectionCalculatingDataProvider: AnyObject {
    associatedtype CalculatingSectionType
    var calculatingSections: [CalculatingSectionType]? { get set }
}
