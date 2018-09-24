//
//  AdvancedItemDeltaTests.swift
//  LiveCollectionsTests
//
//  Created by Stephane Magne on 9/6/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import XCTest
@testable import LiveCollections

final class AdvancedItemDeltaTests: XCTestCase {
    
    private var startingData: [Int]!
    private var updatedData: [Int]!
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
    
    private var deltaCalculator: DeltaCalculator<Int> {
        return DeltaCalculator(startingData: startingData,
                               updatedData: updatedData,
                               includeIdenticalMoves: includesIdenticalMoves)
    }

    // MARK: Moves

    func test_small_set_one_deletion_only_shouldnt_trigger_moves() {
        
        startingData = [383, 30, 296, 74, 68, 396, 158]
        updatedData = [383, 30, 74, 68, 396, 158]
        
        let (_, insertedIndices) = deltaCalculator.insertedItems()
        let (_, deletedIndices) = deltaCalculator.deletedItems()
        
        let (_, movedIndexPairs) = deltaCalculator.reloadedAndMovedItems(deletedIndices: deletedIndices, insertedIndices: insertedIndices)
        
        XCTAssertTrue(movedIndexPairs.isEmpty)
    }

    func test_small_set_multiple_deletions_shouldnt_trigger_moves() {
        
        startingData = [383, 30, 296, 74, 68, 396, 158]
        updatedData = [30, 74, 68, 158]
        
        let (_, insertedIndices) = deltaCalculator.insertedItems()
        let (_, deletedIndices) = deltaCalculator.deletedItems()
        
        let (_, movedIndexPairs) = deltaCalculator.reloadedAndMovedItems(deletedIndices: deletedIndices, insertedIndices: insertedIndices)

        XCTAssertTrue(movedIndexPairs.isEmpty)
    }

    func test_large_set_one_deletion_only_shouldnt_trigger_moves() {
        
        startingData = [383, 30, 296, 74, 68, 396, 158, 58, 28, 933, 389, 377, 180, 401, 272, 289, 822, 938, 824, 704, 591, 274, 164, 189, 407, 300, 913, 914, 163, 823, 708, 192, 21, 19, 928, 491, 35, 86, 932, 55, 85, 275, 395, 22, 835, 178, 69, 829]
        
        updatedData = [383, 30, 296, 74, 68, 396, 158, 58, 28, 933, 389, 377, 180, 401, 272, 289, 822, 938, 824, 704, 591, 274, 164, 189, 407, 913, 914, 163, 823, 708, 192, 21, 19, 928, 491, 35, 86, 932, 55, 85, 275, 395, 22, 835, 178, 69, 829]

        let (_, insertedIndices) = deltaCalculator.insertedItems()
        let (_, deletedIndices) = deltaCalculator.deletedItems()
        
        let (_, movedIndexPairs) = deltaCalculator.reloadedAndMovedItems(deletedIndices: deletedIndices, insertedIndices: insertedIndices)

        XCTAssertTrue(movedIndexPairs.isEmpty)
    }

}

