//
//  Scenario.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

enum Scenario: CaseIterable {
    case basicCollectionView
    case basicTableView
    case discreteSectionsCollectionView
    case discreteSectionsTableView
    case uniqueDataAcrossSectionsCollectionView
    case uniqueDataAcrossSectionsTableView
    case collectionViewsInTableView
    case uniqueCollectionViewsAcrossSectionsTableView
    case collectionViewUsingDataFactory
    case dataWithNonUniqueIDs
    case sectionDataWithNonUniqueIDs
    case calculateTheDeltaManually
    case customTableViewAnimations
    case customTableViewAnimationsDiscreteSections
    case customTableViewAnimationsAllSections
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
        case .collectionViewsInTableView: return "A Table of Carousels"
        case .uniqueCollectionViewsAcrossSectionsTableView: return "A Sectioned Table of Carousels"
        case .collectionViewUsingDataFactory: return "Using a Data Factory"
        case .dataWithNonUniqueIDs: return "Data With Duplicate Items"
        case .sectionDataWithNonUniqueIDs: return "Section Data With Duplicate Items"
        case .calculateTheDeltaManually: return "Not assigning a view to CollectionData"
        case .customTableViewAnimations: return "Custom UITableView Animations"
        case .customTableViewAnimationsDiscreteSections: return "Disctete Sections With Custom UITableView Animations"
        case .customTableViewAnimationsAllSections: return "Unique Data Across All Sections With Custom UITableView Animations"
        }
    }
    
    var name: String {
        guard let index = Scenario.allCases.firstIndex(of: self) else { return "Unknown" }
        return "Scenario \(index+1): \(title)"
    }

    var description: String {
        switch self {
        case .basicCollectionView: return "A collection view with a single section, backed by an immutable array of data"
        case .basicTableView: return "A table view with a single section, backed by an immutable array of data."
        case .discreteSectionsCollectionView: return "A collection view with multiple discrete sections. Each section is backed by its own data source, and each section delta is calculated independently of one another."
        case .discreteSectionsTableView: return "A table view with multiple discrete sections. Each section is backed by its own data source, and each section delta is calculated independently of one another."
        case .uniqueDataAcrossSectionsCollectionView: return "A collection view where each data item is only represented once in the entire view. Unlike previous scenarios where different sections contained their own data sources (and thus could each hold the same data item), this scenario presents a set where individual items can move between sections."
        case .uniqueDataAcrossSectionsTableView: return "A table view where each data item is only represented once in the entire view. Like the previous scenario, items can move between sections."
        case .collectionViewsInTableView: return "A table view with collection views in its cells. Carousel items can be inserted, deleted, and moved, but you must handle reloads manually. You don't want to reload the table row in the table animation, as it will result in an unpleasing effect. Instead, you want to delegate the reload action to the row controller and animate the collection view directly."
        case .uniqueCollectionViewsAcrossSectionsTableView: return "A table view with collection views in its cells. However, the main difference from scenario seven is that you can have multiple carousels in a section and carousels can be moved between sections."
        case .collectionViewUsingDataFactory: return "A basic collection view, but this time we are using a data factory to help us manage changes in externally related information that aren't stored on the data object."
        case .dataWithNonUniqueIDs: return "Have a data set where not every items can be expressed uniquely? No problem. Here's an example of how to set up your data."
        case .sectionDataWithNonUniqueIDs: return "By using the typealias NonUniqueCollectionSectionData, new accessors are introduced to support non-unique data."
        case .calculateTheDeltaManually: return "For the times you don't want the animation to occur automatically or every time. Depending on your class structure or needs, you may want to separate the action of calculating the delta with performing the animation. You may even just want the delta without ever associating a view, say, for analytics purposes."
        case .customTableViewAnimations: return "Use the specific setTableView(_) function to tell CollectionData which animation styles to use when updating."
            case .customTableViewAnimationsDiscreteSections: return "Multiple CollectionData objects pointing at the same UITableView with custom animations (they can even specify different animations per section if that's the sort of funky experience that you want). "
        case .customTableViewAnimationsAllSections: return "Like Scenario 6, but with custom animations."
        }
    }
}
