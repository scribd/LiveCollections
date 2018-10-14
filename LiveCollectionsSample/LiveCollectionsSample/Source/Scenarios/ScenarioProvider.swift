//
//  ScenarioProvider.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

protocol ScenarioProviderInterface {
    var scenarios: [Scenario] { get }
    func viewController(for example: Scenario) -> UIViewController
}

final class ScenarioProvider: ScenarioProviderInterface {
    
    let scenarios: [Scenario] = Scenario.allCases
    private let movieLoader: MovieLoaderInterface
    private let imageLoader = MovieImageLoader()
    
    init(movieLoader: MovieLoaderInterface) {
        self.movieLoader = movieLoader
    }
    
    func viewController(for example: Scenario) -> UIViewController {
        switch example {
        case .basicCollectionView:
            let dataProvider = RandomMovieDataProvider(initialDataCount: isIpad() ? 120 : 40,
                                                       minCount: 5,
                                                       maxCount: isIpad() ? 300 : 80,
                                                       movieLoader: movieLoader)
            let dataCoordinator = DataCoordinator(dataProviders: [dataProvider])
            return ScenarioOneViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)

        case .basicTableView:
            let dataProvider = RandomMovieDataProvider(initialDataCount: 10,
                                                       minCount: 5,
                                                       maxCount: 30,
                                                       movieLoader: movieLoader)
            let dataCoordinator = DataCoordinator(dataProviders: [dataProvider])
            return ScenarioTwoViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)

        case .discreteSectionsCollectionView:
            let dataProviders = [RandomMovieDataProvider(initialDataCount: 10, minCount: 3, maxCount: 15, movieLoader: movieLoader),
                                 RandomMovieDataProvider(initialDataCount: 10, minCount: 3, maxCount: 15, movieLoader: movieLoader),
                                 RandomMovieDataProvider(initialDataCount: 10, minCount: 3, maxCount: 15, movieLoader: movieLoader)]
            
            let dataCoordinator = DataCoordinator(dataProviders: dataProviders)
            return ScenarioThreeViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)

        case .discreteSectionsTableView:
            let dataProviders = [RandomMovieDataProvider(initialDataCount: 4, minCount: 1, maxCount: 8, movieLoader: movieLoader),
                                 RandomMovieDataProvider(initialDataCount: 4, minCount: 1, maxCount: 8, movieLoader: movieLoader),
                                 RandomMovieDataProvider(initialDataCount: 4, minCount: 1, maxCount: 8, movieLoader: movieLoader)]
            
            let dataCoordinator = DataCoordinator(dataProviders: dataProviders)
            return ScenarioFourViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)
            
        case .uniqueDataAcrossSectionsCollectionView:
            let dataProvider = RandomMovieDataProvider(initialDataCount: isIpad() ? 120 : 40,
                                                       minCount: 10,
                                                       maxCount: isIpad() ? 300 : 80,
                                                       movieLoader: movieLoader)
            let dataCoordinator = MultiSectionDataCoordinator(sectionCount: 5, dataProvider: dataProvider)
            return ScenarioFiveViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)

        case .uniqueDataAcrossSectionsTableView:
            let dataProvider = RandomMovieDataProvider(initialDataCount: 20, minCount: 10, maxCount: 80, movieLoader: movieLoader)
            let dataCoordinator = MultiSectionDataCoordinator(sectionCount: 5, dataProvider: dataProvider)
            return ScenarioSixViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)

        case .collectionViewsInTableView:
            let dataProviders: [RandomMovieDataProvider] = {
                let providerCount = isIpad() ? 12 : 10
                return (0..<providerCount).map { _ in RandomMovieDataProvider(initialDataCount: 10, minCount: 2, maxCount: 24, movieLoader: movieLoader) }
            }()
            
            let dataCoordinator = CarouselDataCoordinator(dataProviders: dataProviders)
            return ScenarioSevenViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)
            

        case .uniqueCollectionViewsAcrossSectionsTableView:
            let dataProviders: [RandomMovieDataProvider] = {
                let providerCount = isIpad() ? 15 : 10
                return (0..<providerCount).map { _ in RandomMovieDataProvider(initialDataCount: 10, minCount: 2, maxCount: 24, movieLoader: movieLoader) }
            }()

            let dataCoordinator = MultiSectionCarouselDataCoordinator(sectionCount: 5, dataProviders: dataProviders)
            return ScenarioEightViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)

        case .collectionViewUsingDataFactory:
            let dataProvider = RandomMovieDataProvider(initialDataCount: 50, minCount: 10, maxCount: 100, movieLoader: movieLoader)
            let inTheatersController = InTheatersController(allMovieIdentifiers: movieLoader.availableMovieIdentifiers)
            let dataCoordinator = InTheatersDataCoordinator(dataProviders: [dataProvider], inTheatersController: inTheatersController)
            return ScenarioNineViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader, inTheatersState: inTheatersController)

        case .dataWithNonUniqueIDs:
            let dataProvider = RandomMovieDataProvider(initialDataCount: isIpad() ? 120 : 40,
                                                       minCount: 5,
                                                       maxCount: isIpad() ? 300 : 80,
                                                       allowsDuplicates: true,
                                                       movieLoader: movieLoader)
            let dataCoordinator = DataCoordinator(dataProviders: [dataProvider])
            return ScenarioTenViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)

        case .sectionDataWithNonUniqueIDs:
            let dataProvider = RandomMovieDataProvider(initialDataCount: isIpad() ? 120 : 40,
                                                       minCount: 10,
                                                       maxCount: isIpad() ? 300 : 80,
                                                       allowsDuplicates: true,
                                                       movieLoader: movieLoader)
            let dataCoordinator = MultiSectionDataCoordinator(sectionCount: 5, dataProvider: dataProvider)
            return ScenarioElevenViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)
            
        case .calculateTheDeltaManually:
            let dataProvider = RandomMovieDataProvider(initialDataCount: isIpad() ? 120 : 40,
                                                       minCount: 5,
                                                       maxCount: isIpad() ? 300 : 80,
                                                       movieLoader: movieLoader)
            let dataCoordinator = DataCoordinator(dataProviders: [dataProvider])
            return ScenarioTwelveViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)
            
        case .customTableViewAnimations:
            let dataProvider = RandomMovieDataProvider(initialDataCount: 10,
                                                       minCount: 5,
                                                       maxCount: 12,
                                                       movieLoader: movieLoader)
            let dataCoordinator = DataCoordinator(dataProviders: [dataProvider])
            return ScenarioThirteenViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)
            
        case .customTableViewAnimationsDiscreteSections:
            let dataProviders = [RandomMovieDataProvider(initialDataCount: 3, minCount: 1, maxCount: 6, movieLoader: movieLoader),
                                 RandomMovieDataProvider(initialDataCount: 3, minCount: 1, maxCount: 6, movieLoader: movieLoader),
                                 RandomMovieDataProvider(initialDataCount: 3, minCount: 1, maxCount: 6, movieLoader: movieLoader)]
            
            let dataCoordinator = DataCoordinator(dataProviders: dataProviders)
            return ScenarioFourteenViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)

        case .customTableViewAnimationsAllSections:
            let dataProvider = RandomMovieDataProvider(initialDataCount: 20, minCount: 10, maxCount: 80, movieLoader: movieLoader)
            let dataCoordinator = MultiSectionDataCoordinator(sectionCount: 5, dataProvider: dataProvider)
            return ScenarioFifteenViewController(dataCoordinator: dataCoordinator, imageLoader: imageLoader)
        }
    }
}
