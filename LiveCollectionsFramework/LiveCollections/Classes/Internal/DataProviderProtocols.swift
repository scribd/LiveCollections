//
//  ItemDataProvider.swift
//  LiveCollections
//
//  Created by Stephane Magne on 7/9/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol ItemDataProvider: AnyObject {
    associatedtype DataType: UniquelyIdentifiable
    var items: [DataType] { get set }
    
    // As data sets get large, calculation time becomes expensive, so
    // if either the current data or the updated data exceeds this count,
    // the view will simply call `reloadSection` which performs sort of
    // a smear of an animation rather than item per item animations
    var dataCountAnimationThreshold: Int { get }
    
    // As deltas get large, it can trigger an incrasing number of layout loops.
    // This can reduce drawing performance and also trip your debugger flags
    // if 'UIViewLayoutFeedbackLoopDebuggingThreshold' is set
    var deltaCountAnimationThreshold: Int { get }
}

protocol ItemCalculatingDataProvider: AnyObject {
    associatedtype CalculatingRawType
    var calculatingItems: [CalculatingRawType]? { get set }
}

protocol SectionDataProvider: ItemDataProvider {
    associatedtype SectionType: UniquelyIdentifiableSection
    var sections: [SectionType] { get set }
    func orderedItems(for sections: [SectionType]) -> [DataType]
}

protocol SectionCalculatingDataProvider: AnyObject {
    associatedtype CalculatingSectionType
    var calculatingSections: [CalculatingSectionType]? { get set }
}
