//
//  BasicItemDeltaTests.swift
//  LiveCollectionsTests
//
//  Created by Stephane Magne on 8/29/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import XCTest
@testable import LiveCollections

final class BasicItemDeltaTests: XCTestCase {

    private var startingData: [String]!
    private var updatedData: [String]!
    private var includesIdenticalMoves: Bool!

    override func setUp() {
        super.setUp()
        includesIdenticalMoves = false
    }
    
    override func tearDown() {
        defer { super.tearDown() }
        startingData = nil
        updatedData = nil
        includesIdenticalMoves = nil
    }
    
    private var deltaCalculator: DeltaCalculator<String> {
        return DeltaCalculator(startingData: startingData,
                               updatedData: updatedData,
                               includeIdenticalMoves: includesIdenticalMoves)
    }
    
    // MARK: Deletions
    
    func test_deletion_zero_index() {
        
        startingData = ["A", "B", "C", "D", "E"]
        updatedData = ["B", "C", "D", "E"]
        
        let (deletedItems, deletedIndices) = deltaCalculator.deletedItems()

        XCTAssertEqual(deletedItems, ["A"])
        XCTAssertEqual(deletedIndices, [0])
    }
    
    func test_deletion_first_index() {
        
        startingData = ["A", "B", "C", "D", "E"]
        updatedData = ["A", "C", "D", "E"]
        
        let (deletedItems, deletedIndices) = deltaCalculator.deletedItems()
        
        XCTAssertEqual(deletedItems, ["B"])
        XCTAssertEqual(deletedIndices, [1])
    }

    func test_deletion_third_index() {
        
        startingData = ["A", "B", "C", "D", "E"]
        updatedData = ["A", "B", "C", "E"]
        
        let (deletedItems, deletedIndices) = deltaCalculator.deletedItems()
        
        XCTAssertEqual(deletedItems, ["D"])
        XCTAssertEqual(deletedIndices, [3])
    }

    func test_deletion_many_indices() {
        
        startingData = ["A", "B", "C", "D", "E"]
        updatedData = ["B", "D"]
        
        let (deletedItems, deletedIndices) = deltaCalculator.deletedItems()
        
        XCTAssertEqual(deletedItems, ["A", "C", "E"])
        XCTAssertEqual(deletedIndices, [0, 2, 4])
    }

    func test_deletion_all_indices() {
        
        startingData = ["A", "B", "C", "D", "E"]
        updatedData = []
        
        let (deletedItems, deletedIndices) = deltaCalculator.deletedItems()
        
        XCTAssertEqual(deletedItems, ["A", "B", "C", "D", "E"])
        XCTAssertEqual(deletedIndices, [0, 1, 2, 3, 4])
    }

    func test_no_deletions() {
        
        startingData = ["3", "2", "0", "4", "1"]
        updatedData = ["3", "0", "2", "1", "4"]
        
        let (deletedItems, deletedIndices) = deltaCalculator.deletedItems()
        
        XCTAssertTrue(deletedItems.isEmpty)
        XCTAssertTrue(deletedIndices.isEmpty)
    }
    
    // MARK: Insertions
    
    func test_insertion_zero_index() {
        
        startingData = ["B", "C", "D", "E"]
        updatedData = ["A", "B", "C", "D", "E"]
        
        let (insertedItems, insertedIndices) = deltaCalculator.insertedItems()
        
        XCTAssertEqual(insertedItems, ["A"])
        XCTAssertEqual(insertedIndices, [0])
    }

    func test_insertion_second_index() {
        
        startingData = ["B", "C", "D", "E"]
        updatedData = ["B", "C", "F", "D", "E"]
        
        let (insertedItems, insertedIndices) = deltaCalculator.insertedItems()
        
        XCTAssertEqual(insertedItems, ["F"])
        XCTAssertEqual(insertedIndices, [2])
    }

    func test_insertion_fourth_index() {
        
        startingData = ["B", "C", "D", "E"]
        updatedData = ["B", "C", "D", "E", "G"]
        
        let (insertedItems, insertedIndices) = deltaCalculator.insertedItems()
        
        XCTAssertEqual(insertedItems, ["G"])
        XCTAssertEqual(insertedIndices, [4])
    }

    func test_insertion_many_indices() {
        
        startingData = ["B", "C", "D", "E"]
        updatedData = ["A", "B", "F", "C", "D", "E", "G", "H"]
        
        let (insertedItems, insertedIndices) = deltaCalculator.insertedItems()
        
        XCTAssertEqual(insertedItems, ["A", "F", "G", "H"])
        XCTAssertEqual(insertedIndices, [0, 2, 6, 7])
    }

    // MARK: Moves
    
    func test_move_one_item() {
        
        startingData = ["A", "B", "C", "D", "E"]
        updatedData = ["B", "C", "A", "D", "E"]
        
        let (_, movedIndexPairs) = deltaCalculator.reloadedAndMovedItems(deletedIndices: [], insertedIndices: [])
        
        XCTAssertEqual(movedIndexPairs, [IndexPair(source: 0, target: 2),
                                         IndexPair(source: 1, target: 0),
                                         IndexPair(source: 2, target: 1)])
    }

    func test_move_two_item() {
        
        startingData = ["A", "B", "C", "D", "E"]
        updatedData = ["B", "D", "C", "A", "E"]
        
        let (_, movedIndexPairs) = deltaCalculator.reloadedAndMovedItems(deletedIndices: [], insertedIndices: [])

        XCTAssertEqual(movedIndexPairs, [IndexPair(source: 0, target: 3),
                                         IndexPair(source: 1, target: 0),
                                         IndexPair(source: 3, target: 1)])
    }

    func test_swap_two_item() {
        
        startingData = ["A", "B", "C", "D", "E"]
        updatedData = ["A", "E", "C", "D", "B"]
        
        let (_, movedIndexPairs) = deltaCalculator.reloadedAndMovedItems(deletedIndices: [], insertedIndices: [])

        XCTAssertEqual(movedIndexPairs, [IndexPair(source: 1, target: 4),
                                         IndexPair(source: 4, target: 1)])
    }
}
