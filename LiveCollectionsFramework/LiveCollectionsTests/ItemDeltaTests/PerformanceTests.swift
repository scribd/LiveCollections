//
//  PerformanceTests.swift
//  LiveCollectionsTests
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import XCTest
@testable import LiveCollections

final class PerformanceTests: XCTestCase {
    
    private var startingData: [Int]!
    private var updatedData: [Int]!
    private var collectionData: CollectionData<Int>!
    
    override func tearDown() {
        defer { super.tearDown() }
        startingData = nil
        updatedData = nil
        collectionData = nil
    }

    func test_10_items_with_10_items() {
        startingData = DataBuilder.build(10, numberToDelete: 0)
        updatedData = DataBuilder.build(10, numberToDelete: 0)
        collectionData = CollectionData<Int>(startingData)
        
        measure {
            _ = collectionData.calculateDeltaSync(updatedData)
        }
    }

    func test_100_items_with_100_items() {
        startingData = DataBuilder.build(100, numberToDelete: 0)
        updatedData = DataBuilder.build(100, numberToDelete: 0)
        collectionData = CollectionData<Int>(startingData)
        
        measure {
            _ = collectionData.calculateDeltaSync(updatedData)
        }
    }

    func test_1000_items_with_1000_items() {
        startingData = DataBuilder.build(1000, numberToDelete: 0)
        updatedData = DataBuilder.build(1000, numberToDelete: 0)
        collectionData = CollectionData<Int>(startingData)
        
        measure {
            _ = collectionData.calculateDeltaSync(updatedData)
        }
    }

    func test_10000_items_with_10000_items() {
        startingData = DataBuilder.build(10000, numberToDelete: 0)
        updatedData = DataBuilder.build(10000, numberToDelete: 0)
        collectionData = CollectionData<Int>(startingData)
        
        measure {
            _ = collectionData.calculateDeltaSync(updatedData)
        }
    }

    func test_600_items_with_1400_items() {
        startingData = DataBuilder.build(1000, numberToDelete: 400)
        updatedData = DataBuilder.build(1400, numberToDelete: 0)
        collectionData = CollectionData<Int>(startingData)
        
        measure {
            _ = collectionData.calculateDeltaSync(updatedData)
        }
    }

    func test_1400_items_with_600_items() {
        startingData = DataBuilder.build(1400, numberToDelete: 0)
        updatedData = DataBuilder.build(1000, numberToDelete: 400)
        collectionData = CollectionData<Int>(startingData)
        
        measure {
            _ = collectionData.calculateDeltaSync(updatedData)
        }
    }

    func test_6000_items_with_14000_items() {
        startingData = DataBuilder.build(10000, numberToDelete: 4000)
        updatedData = DataBuilder.build(14000, numberToDelete: 0)
        collectionData = CollectionData<Int>(startingData)
        
        measure {
            _ = collectionData.calculateDeltaSync(updatedData)
        }
    }
}

private final class DataBuilder {
    
    static func build(_ count: Int, numberToDelete: Int) -> [Int] {
    
        let range = (0..<count)
        var data = Array(range).shuffled()
        
        (0..<numberToDelete).forEach { _ in
            let index = Int(arc4random_uniform(UInt32(data.count)))
            data.remove(at: index)
        }
        
        return data
    }
}

private extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }
        
        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

private extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
