//
//  Scenario.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

enum Scenario {
    case basicCollectionView
    case basicTableView
    case discreteSectionsCollectionView
    case discreteSectionsTableView
    case uniqueDataAcrossSectionsCollectionView
    case uniqueDataAcrossSectionsTableView
    case collectionViewsInTableView
    case uniqueCollectionViewsAcrossSectionsTableView
    case collectionViewUsingDataFactory
    case calculateTheDeltaManually

    static let allScenarios: [Scenario] = [.basicCollectionView,
                                         .basicTableView,
                                         .discreteSectionsCollectionView,
                                         .discreteSectionsTableView,
                                         .uniqueDataAcrossSectionsCollectionView,
                                         .uniqueDataAcrossSectionsTableView,
                                         .collectionViewsInTableView,
                                         .uniqueCollectionViewsAcrossSectionsTableView,
                                         .collectionViewUsingDataFactory,
                                         .calculateTheDeltaManually]
}

extension Scenario {

    var title: String {
        switch self {
        case .basicCollectionView: return "Basic UICollectionView"
        case .basicTableView: return "Basic UITableView"
        case .discreteSectionsCollectionView: return "Discrete Sections UICollectionView"
        case .discreteSectionsTableView: return "Discrete Sections UITableView"
        case .uniqueDataAcrossSectionsCollectionView: return "Unique Data Across Sections in UICollectionView"
        case .uniqueDataAcrossSectionsTableView: return "Unique Data Across Sections in UITableView"
        case .collectionViewsInTableView: return "UICollectionViews in UITableView"
        case .uniqueCollectionViewsAcrossSectionsTableView: return "Unique UICollectionViews Across Sections in UITableView"
        case .collectionViewUsingDataFactory: return "Using a Data Factory"
        case .calculateTheDeltaManually: return "Not assigning a view to CollectionData"
        }
    }
    
    var name: String {
        guard let index = Scenario.allScenarios.index(of: self) else { return "Unknown" }
        return "Scenario \(index+1): \(title)"
    }

    var description: String {
        switch self {
        case .basicCollectionView: return "A collection view with a single section, backed by an immutable array of data"
        case .basicTableView: return "A table view with a single section, backed by an immutable array of data."
        case .discreteSectionsCollectionView: return "A collection view with multiple discrete sections. Each section is backed by its own data source, and each section delta is calculated independently of one another."
        case .discreteSectionsTableView: return "A table view with multiple discrete sections. Each section is backed by its own data source, and each section delta is calculated independently of one another."
        case .uniqueDataAcrossSectionsCollectionView: return "A collection view where each data item is only represented once in the entire view. Unlike previous examples where different sections contained their own data sources (and thus could each hold the same data item), this example presents a set where individual items can move between sections."
        case .uniqueDataAcrossSectionsTableView: return "A table view where each data item is only represented once in the entire view. Unlike previous examples where different sections contained their own data sources (and thus could each hold the same data item), this example presents a set where individual items can move between sections."
        case .collectionViewsInTableView: return "A table view with collection views in its cells. Carousel rows can be inserted, deleted, and moved, but you must handle reloads manually. You don't want to reload the table row in the table animation, as it will result in an unpleasing effect. Instead, you want to delegate the reload action to the row controller and animate the collection view directly."
        case .uniqueCollectionViewsAcrossSectionsTableView: return "A table view will collection views in its cells. However, the main difference from example five is that you can have multiple carousels in a section and carousels can be moved between sections."
        case .collectionViewUsingDataFactory: return "A basic collection view, but this time we are using a data factory to help us manage changes in externally related information that aren't stored on the data object."
        case .calculateTheDeltaManually: return "For the times you don't want the animation to occur automatically or every time. Depending on your class structure or needs, you may want to separate the action of calculating the delta with performing the animation. You may even just want the delta without ever associating a view, say, for analytics purposes."
        }
    }
}
