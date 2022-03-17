<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/LiveCollections_main_logo.png" alt="LiveCollections logo">

<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/LiveCollections_Animated.png" alt="Single section collection view class graph">

<b>LiveCollections</b> is an open source framework that makes using UITableView and UICollectionView animations possible in just a few lines of code. Given two sets of data, the framework will automatically perform all of the calculations, build the line item animation code, and perform it in the view.

Using one of the two main classes `CollectionData` or `CollectionSectionData`, you can build a fully generic, immutable data set that is thread safe, timing safe, and highly performant. Simply connect your view to the data object, call the update method and that's it.

In the sample app, there are a number of use case scenarios demonstrated, and the sample code of each one can be found by looking up the respective controller (e.g. ScenarioThreeViewController.swift).

Full detail for the use case of each scenario <a href="https://medium.com/p/59ea1eda2b2d">can be found in the blog post on Medium</a>, which you can read if you want the full explanation. Below, I am just going to show the class graph and the minimum code needed for each case.

<hr>

<h2>Swift Version</h2>

This project has been upgraded to be compatible with Swift 5.5
<br>

<hr>


<h2>Importing With SwiftPM</h2>

<br>
https://github.com/scribd/LiveCollections 1.0.1
<br>
<br>


<h2>Importing With Carthage</h2>

<br>
github "scribd/LiveCollections" "1.0.1"
<br>
<br>


<h2>Importing With CocoaPods</h2>

<br>
pod 'LiveCollections', '~> 1.0.1'
<br>
or
<br>
pod 'LiveCollections'
<br>
<br>

<hr>

<h1>The Main Classes</h1>

<ul> 
    <li><b>CollectionData&lt;YourType&gt;</b></li>
    <li><b>CollectionSectionData&lt;YourSectionType&gt;</b></li>
</ul>

By using one of these two classes to hold your data, every time you update with new data it will automatically calculate the delta between your update and the current data set. If you assign a view to either object, then it will pass both the delta and data to the view and perform the animation automatically.  All updates are queued, performant, thread safe, and timing safe. In your UITableViewDataSource and UICollectionViewDataSource methods, you simply need to fetch your data from the <b>CollectionData</b> or <b>CollectionSectionData</b> object directly using the supplied `count`, `subscript`, and `isEmpty` thread-safe accessors.

To prepare your data to be used in <b>CollectionData</b>, you just need to adopt the protocol <b>UniquelyIdentifiable</b>.
The requirements for <b>CollectionSectionData</b> will be detailed in scenerios 5 and 6 a bit later on.

<BR>
    
<b>Updates made easy!</b>

Once you create an instance of CollectionData, animating your table or collection view becomes just a single line of code:

```swift
func yourDataUpdateFunction(_ updatedData: [YourDataType]) {
    collectionData.update(updatedData)
}

``` 
<BR>

You'll notice that the data being passed in is a Swift immutable type, and at no point do you ever need to worry about what the difference is between the new data being passed in and the existing data.

<BR>
    
<h2>Adopting the protocol UniquelyIdentifiable</h2>

The crux of being able to use <b>CollectionData</b> as your data source and get all of the benefits of LiveCollections, is by adopting the protocol <b>UniquelyIdentifiable</b>. It's what allows the private delta calculator in the framework to determine all of the positional moves of your data objects.

```swift
public protocol UniquelyIdentifiable: Equatable {
    associatedtype RawType
    associatedtype UniqueIDType: Hashable
    var rawData: RawType { get }
    var uniqueID: UniqueIDType { get }
}
```

Since UniquelyIdentifiable inherits from Equatable, making your base class adopt Equatable gives you an auto-synthesized equatability function (or you can write a custom == func if needed).

Here's a simple example of how it can apply to a custom data class:

```swift
import LiveCollections

struct Movie: Equatable {
    let id: UInt
    let title: String
}

extension Movie: UniquelyIdentifiable {
    typealias RawType = Movie
    var uniqueID: UInt { return id }
}
```

Note: Take a look at Scenario 9 below to see an example where RawType is not simply the Self type. We will use a different type if we want to have different equatability functions for the same RawType object in different views, or if we want to create a new object that includes additional metadata.

<BR>
<h2>Adopting the protocol NonUniquelyIdentifiable</h2>

Support has been added for non-unique sets of data as well. 

```swift
public protocol NonUniquelyIdentifiable: Equatable {
    associatedtype NonUniqueIDType: Hashable
    var nonUniqueID: NonUniqueIDType { get }
}
```

By adopting this protocol and using one of the two type aliases `NonUniqueCollectionData` or `NonUniqueCollectionSectionData`, a factory will be built under the hood that will transform your non-unique data into a `UniquelyIdentifiable` type. See Scenarios 10 and 11.

Since the data is wrapped in a new struct, to access your original object you'll need to call the `rawData` getter like so:

```
let data = collectionData[indexPath.item].rawData
```

<i>Note:This will use "best guess" logic, and the identifiers will be determined based on array order.</i>
<br>
<br>

<hr>

Listed below is a summation of the relevant code you'll need in your app for each of the scneario in the sample app. These reflect most of the use cases you will encounter.
<br>
<h2>Scenario 1: A UICollectionView with one section</h2>

<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/single_section_collection_view.png" alt="Single section collection view class graph">

```swift
final class YourClass {
    private let collectionView: UICollectionView
    private let collectionData: CollectionData<YourData>

    init(_ data: [YourData]) {
        collectionData = CollectionData(data)
        ...
        super.init()
        collectionData.view = collectionView
    }

    func someMethodToUpdateYourData(_ data: [YourData]) {
        collectionData.update(data)
    }
}

extension YourClass: UICollectionViewDelegate {
  
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }  
    
    // etc
}
```
<br>
<br>
<br>
<h2>Scenario 2: A UTableView with one section</h2>
<br>
The same as scenario 1 but swap in UITableView.

<br>
<br>
<br>
<h2>Scenario 3: A UICollectionView with multiple sections, each section has its own CollectionData</h2>

<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/discrete_sections_collection_view.png" alt="Multiple discrete sections collection view class graph">

or

<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/discrete_sections_collection_view_with_synchronizer.png" alt="Multiple discrete sections collection view class graph with two sections synchronized">

```swift
final class YourClass {
    private let collectionView: UICollectionView
    private let dataList: [CollectionData<YourData>]

    init() {
        // you can also assign section later on if that better fits your class design
        dataList = [
             CollectionData<YourData>(section: 0),
             CollectionData<YourData>(section: 1),
             CollectionData<YourData>(section: 2)
        ]
        ...
        super.init()
        
        // Optionally apply a synchronizer to multiple sections to have them
        // perform their animations in the same block when possible
        let synchronizer = CollectionDataSynchronizer(delay: .short)
        dataList.forEach { $0.synchronizer = synchronizer }
    }

    func someMethodToUpdateYourData(_ data: [YourData], section: Int) {
        let collectionData = dataList[section]
        collectionData.update(data)
    }
}

extension YourClass: UICollectionViewDelegate {
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataList.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let collectionData = dataList[section]
        return collectionData.count
    }  
    
    // let item = collectionData[indexPath.row]
    // etc
}
```

<br>
<br>
<br>
<h2>Scenario 4: A UITableView with multiple sections, each section has its own CollectionData</h2>
<br>
The same as scenario 3 but swap in UITableView.


<br>
<br>
<hr>
<h1>Using unique data across multiple sections? Adopt the protocol UniquelyIdentifiableSection</h1>

When data items are uniquely represented across the entire view, they may move between sections. To handle these animations, you can instead use <b>CollectionSectionData</b> and create a data item that adopts <b>UniquelyIdentifiableSection</b>.

```swift
public protocol UniquelyIdentifiableSection: UniquelyIdentifiable {
    associatedtype DataType: UniquelyIdentifiable
    var items: [DataType] { get }
}
```

As you can see, it still ultiately relies on the base data type that adopts <b>UniquelyIdentifiable</b>. This new object helps us wrap the section changes.

Note: Since UniquelyIdentifiableSection inherits from UniquelyIdentifiable, that means that each section will also require its own uniqueID to track section changes. These IDs do not have to be unique from those of the underlying `items: [DataType]`.

```swift
import LiveCollections

struct MovieSection: Equatable {
    let sectionIdentifier: String
    let movies: [Movie]
}

extension MovieSection: UniquelyIdentifiableSection {
    var uniqueID: String { return sectionIdentifier }
    var items: [Movie] { return movies }
    var hashValue: Int { return items.reduce(uniqueID.hashValue) { $0 ^ $1.hashValue } }
}
```
<hr>


<br>
<br>
<h2>Scenario 5: A UICollectionView with multiple sections and a singular data source</h2>

<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/multi_section_collection_view.png" alt="Multiple section collection view class graph">

```swift
final class YourClass {
    private let collectionView: UICollectionView

    private let collectionData: CollectionSectionData<YourSectionData>

    init(_ data: [YourSectionData]) {
        collectionData = CollectionSectionData(data)
        ...
        super.init()
        collectionData.view = collectionView
    }

    func someMethodToUpdateYourData(_ data: [YourSectionData]) {
        collectionData.update(data)
    }
}

extension YourClass: UICollectionViewDelegate {
  
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collectionData.sectionCount
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.rowCount(forSection: section)
    }  
    
    // let item = collectionData[indexPath]
    // etc
}
```

<br>
<br>
<br>
<h2>Scenario 6: A UITableView with multiple sections and a singular data source</h2>
<br>
The same as scenario 5 but swap in UITableView (I bet you didn't see that coming).

<br>
<br>
<br>
<h2>Scenario 7: A Table of Carousels</h2>

<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/table_of_carousels.png" alt="Table of carousels class graph">

<b>Table view data source </b>

```swift
final class YourClass {
    private let tableView: UITableView
    private let collectionData: CollectionData<YourData>
    private let carouselDataSources: [SomeCarouselDataSource]

    init(_ data: [YourData]) {
        collectionData = CollectionData(data)
        ...
        super.init()
        collectionData.view = tableView
    }

    func someMethodToUpdateYourData(_ data: [YourData]) {
        collectionData.update(data)
    }
    
    // some function that fetches a carousel data source based on identifier
    private func _carouselDataSource(for identifier: Int) -> SomeCarouselDataSource {
        ....
    }
}

extension YourClass: UITableViewDelegate {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // hook up SomeCarouselDataSource to the cell containing the collection view
        // ideally wrap this logic into a private func rather than exposing these variables

        ...
        let carouselRow = collectionData[indexPath.row]
        let carouselDataSource = _carouselDataSource(for: carouselRow.identifier)
        cell.collectionView.dataSource = carouselDataSource
        cell.collectionView.delegate = carouselDataSource
        carouselDataSource.collectionData.view = cell.collectionView
        ...
    }
     
     // etc
}

extension YourClass: CollectionDataManualReloadDelegate {
    
    // IndexPathPair is a struct that contains both the source index path for the original data set
    // and the target index path of the updated data set. You may need to know one or both pieces 
    // of information to determine if you want to handle the reload.
    
    func willHandleReload(at indexPathPair: IndexPathPair) -> Bool {
        return true
    }
    
    func reloadItems(at indexPaths: [IndexPath], indexPathCompletion: @escaping (IndexPath) -> Void) {

        indexPaths.forEach { indexPath in
            let carouselRow = collectionData[indexPath.item]
            let carouselDataSource = _carouselDataSource(for: carouselRow.identifier)
            
            let itemCompletion = {
                indexPathCompletion(indexPath)
            }
            
            carouselDataSource.update(with: carouselRow.movies, completion: itemCompletion)
        }
    }
    
    func preferredRowAnimationStyle(for rowDelta: IndexDelta) -> AnimationStyle {
         return .preciseAnimation
    }
}
```

<b>A table view cell to contain the collection view</b>

```swift
final class CarouselTableViewCell: UITableViewCell {
    private let collectionView: UICollectionView
    ...
}
```

<b>Carousel data source</b>

```swift
final class SomeCarouselDataSource: UICollectionViewDelegate {
    private let collectionView: UICollectionView
    private let collectionData: CollectionData<YourData>

    func someMethodToUpdateYourData(_ data: [YourData], completion: (() -> Void)?) {
        collectionData.update(data, completion: completion)
    }
}

extension SomeCarouselDataSource: CollectionDataReusableViewVerificationDelegate {
    func isDataSourceValid(for view: DeltaUpdatableView) -> Bool {
        guard let collectionView = view as? UICollectionView,
            collectionView.delegate === self,
            collectionView.dataSource === self else {
                return false
        }
        
        return true
    }
}

extension SomeCarouselDataSource: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SomeCarouselCell.reuseIdentifier, for: indexPath)

        // NOTE: Very imporatant guard. Any time you need to fetch data from an index, first guard that it
        //       is the correct collection view. Dequeueing table view cells means that we can get into 
        //       situations where views temporarily point to outdated data sources.
        guard collectionView === collectionData.view else {
            return cell
        }
        
        let item = collectionData[indexPath.item]
        ...
    }
}
```

<br>
<br>
<br>
<h2>Scenario 8: A Sectioned Table of Carousels (carousels can move between sections)</h2>

<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/sectioned_table_of_carousels.png" alt="Sectioned table of carousels class graph">

Almost everything is the same as the previous example, except that our table view uses CollectionSectionData.

```swift
final class YourClass {
    private let tableView: UITableView
    private let collectionData: CollectionSectionData<YourSectionData>
    private let carouselDataSources: [SomeCarouselDataSource]
    
    ...
}
```

<br>
<br>
<br>
<h2>Scenario 9: Using a Data Factory</h2>

<img src="https://github.com/scribd/LiveCollections/blob/master/ReadMe/using_a_data_factory.png" alt="Using a data factory class graph">

A data factory you build must conform to the protocol <b>UniquelyIdentifiableDataFactory</b>. It's role is to simply take in a value of `RawType` and build a new object. This can be as simple as a wrapper class that modifies the equatability function, or could be a complex factory that injects multiple data services that fetch metadata for the RawType item.

What using a data factory means is that your update method on <b>CollectionData</b> takes in [RawType], but returns a value of [UniquelyIdentifiableType] (your new data class) when requesting values via `subscript`. This also saves your data source from needing to know about any custom types you are building to customize your view.

The `buildQueue` property will default to nil via an extension, and is only needed if your data needs to be build on a specific thread. Otherwise ignore it.

```swift
public protocol UniquelyIdentifiableDataFactory {

    associatedtype RawType
    associatedtype UniquelyIdentifiableType: UniquelyIdentifiable

    var buildQueue: DispatchQueue? { get } // optional queue if your data is thread sensitive
    func buildUniquelyIdentifiableDatum(_ rawType: RawType) -> UniquelyIdentifiableType
}
```

Here is the example I use in the sample app. It takes in an injected controller that looks up whether a movie is currently playing in theaters, and creates a new object that includes this data.  The equatability function includes this metadata, and thus changes the conditions of what constitutes a `reload` action in the view animation.

```swift
import LiveCollections

struct DistributedMovie: Hashable {
    let movie: Movie
    let isInTheaters: Bool
}

extension DistributedMovie: UniquelyIdentifiable {
    var rawData: Movie { return movie }
    var uniqueID: UInt { return movie.uniqueID }
}

struct DistributedMovieFactory: UniquelyIdentifiableDataFactory {

    private let inTheatersController: InTheatersStateInterface
    
    init(inTheatersController: InTheatersStateInterface) {
        self.inTheatersController = inTheatersController
    }
    
    func buildUniquelyIdentifiableDatum(_ movie: Movie) -> DistributedMovie {
        let isInTheaters = inTheatersController.isMovieInTheaters(movie)
        return DistributedMovie(movie: movie, isInTheaters: isInTheaters)
    }
}
```

Once you build your factory, the only real change to your code is injecting it into the initializer:

```swift
final class YourClass {
    private let collectionView: UICollectionView
    private let collectionData: CollectionData<Movie>

    init(_ movies: [Movie]) {
        let factory = DistributedMovieFactory(inTheatersController: InTheatersController()) 
        collectionData = CollectionData(dataFactory: factory, rawData: movies)
        ...
        super.init()
        collectionData.view = collectionView
    }

    func someMethodToUpdateYourData(_ movies: [Movie]) {
        collectionData.update(movies)
    }
}

extension YourClass: UICollectionViewDelegate {
  
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }  
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        ...
        // note the different type being returned
        let distributedMovie = collectionData[indexPath.item]
        ...
    }
    
    // etc
}
```


<br>
<br>
<br>

<h2>Scenario 10: Non-unique data in a single section</h2>

Use the typealiased data struct `NonUniqueCollectionData` with your non-unique data.

```swift
final class YourClass {
    private let collectionView: UICollectionView
    private let collectionData: NonUniqueCollectionData<YourData>

    init(_ data: [YourData]) {
        collectionData = CollectionData(data)
        ...
        super.init()
        collectionData.view = collectionView
    }

    func someMethodToUpdateYourData(_ data: [YourData]) {
        collectionData.update(data)
    }
}

extension YourClass: UICollectionViewDelegate {
  
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionData.count
    }  
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        ...
        // note that your data is wrapped in a unique type, it must be fetched with rawData
        let movie = collectionData[indexPath.item].rawData
        ...
    }

    // etc
}
```
<br>
<br>
<br>

<h2>Scenario 11: Non-unique data in multiple sections</h2>

Use the typealiased data struct `NonUniqueCollectionSectionData` with your non-unique section data.

```swift
final class YourClass {
    private let collectionView: UICollectionView
    private let collectionData: NonUniqueCollectionSectionData<YourSectionData>

    init(_ data: [YourSectionData]) {
        collectionData = CollectionData(view: view, sectionData: data)
        ...
        super.init()
    }

    func someMethodToUpdateYourData(_ data: [YourData]) {
        collectionData.update(data)
    }
}

extension YourClass: UICollectionViewDelegate {
  
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
        ...
        // note that your data is wrapped in a unique type, it must be fetched with rawData
        let movie = collectionData[indexPath.item].rawData
        ...
    }

    // etc
}
```
<br>
<br>
<br>

<h2>Scenario 12: Manual timing of the animation</h2>

In every previous case we have assigned the view object to the `CollectionData` object. If you choose to omit this step, you can still get the benefits of LiveCollections caltulations.

Simply do the following:

```swift
let delta = collectionData.calculateDelta(data)

// perform any analysis or analytics on the delta

let updateData = {
    self.collectionData.update(data)
}

// when the time is right, call...
collectionView.performAnimations(section: collectionData.section, delta: delta, updateData: updateData)
```

Note: This is unavailable for <b>CollectionSectionData</b> as the animations occur in multiple steps and the timing of the updates is very specific. 
<br>
<br>
<br>

<h2>Scenario 13: Custom table view animations</h2>

By default LiveCollections performs a preset selection of table view animations: delete (.bottom), insert (.fade), reload (.fade), reloadSection (.none).

As of 0.9.8 there is support for overriding these defaults and setting your own values. 

There is a new accessor on `CollectionData` to set up your view instead of using `collectionData.view = tableView`.

```swift
let rowAnimations = TableViewAnimationModel(deleteAnimation: .right,
                                            insertAnimation: .right,
                                            reloadAnimation: .middle)

collectionData.setTableView(tableView,
                            rowAnimations: rowAnimations,
                            sectionReloadAnimation: .top)
```

<br>
<br>
<br>

<h2>Scenario 14: Multiple data sources pointing at the same table view with custom animations</h2>

If you have multiple data souces each animating a section of a table view, you can give each of them custom animations. They can even be different per section if that's what you really want.

```swift
let sectionZeroRowAnimations = TableViewAnimationModel(deleteAnimation: .left,
                                                       insertAnimation: .left,
                                                       reloadAnimation: .left)

dataList[0].setTableView(tableView, rowAnimations: sectionZeroRowAnimations)

let sectionOneRowAnimations = TableViewAnimationModel(deleteAnimation: .right,
                                                      insertAnimation: .right,
                                                      reloadAnimation: .right)

dataList[1].setTableView(tableView, rowAnimations: sectionOneRowAnimations)

let sectionTwoRowAnimations = TableViewAnimationModel(deleteAnimation: .top,
                                                      insertAnimation: .top,
                                                      reloadAnimation: .top)

dataList[2].setTableView(tableView, rowAnimations: sectionTwoRowAnimations)
```

<br>
<br>
<br>

<h2>Scenario 15: Custom table view animations for data across all sections</h2>

`CollectionSectionData` has a new initializer.

```swift
let rowAnimations = TableViewAnimationModel(deleteAnimation: .right,
                                            insertAnimation: .right,
                                            reloadAnimation: .right)

let sectionAnimations = TableViewAnimationModel(deleteAnimation: .left,
                                                insertAnimation: .left,
                                                reloadAnimation: .left)

return CollectionSectionData<MovieSection>(tableView: tableView,
                                           sectionData: initialData,
                                           rowAnimations: rowAnimations,
                                           sectionAnimations: sectionAnimations)
```

<br>
<br>
<br>


<hr>
<br>

I hope this covers nearly all of the use cases out there, but if you find a gap in what this framework offers, I'd love to hear your suggestions and feedback.

Happy animating!

<hr>

<img width="204" height="81" src="https://www.themoviedb.org/assets/1/v4/logos/408x161-powered-by-rectangle-green-bb4301c10ddc749b4e79463811a68afebeae66ef43d17bcfd8ff0e60ded7ce99.png">

Special thanks to <b>The Movie Database</b>. All of the images and data in the sample application were retrieved from their open source API. It's an excellent tool that helped save a lot of time and hassle. Using their data, the examples demonstrate how you can take existing data and extend it to use LiveCollections.

<i>This product uses the TMDb API but is not endorsed or certified by TMDb.</i>
