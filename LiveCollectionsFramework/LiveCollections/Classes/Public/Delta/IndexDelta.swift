//
//  IndexDelta.swift
//  LiveCollections
//
//  Created by Stephane Magne on 8/23/16.
//  Copyright © 2016 Stephane Magne. All rights reserved.
//

import Foundation

// MARK: IndexPair

public struct IndexPair: Hashable {
    public let source: Int
    public let target: Int
    
    public init(source: Int, target: Int) {
        self.source = source
        self.target = target
    }
}

// MARK: CustomDebugStringConvertible

extension IndexPair: CustomStringConvertible, CustomDebugStringConvertible {
    
    public var description: String {
        return privateDescription
    }

    public var debugDescription: String {
        return privateDescription
    }
    
    private var privateDescription: String {
        return "(\(source), \(target))"
    }
}

// MARK: - IndexDelta

public struct IndexDelta: Equatable {
    // Use index in source data
    public let deletions: [Int]
    
    // Use index in target data
    public let insertions: [Int]

    // index in source data, index in target data (the latter is for manual reloads)
    public let reloads: [IndexPair]

    // from index in source data --> to index in target data
    public let moves: [IndexPair]

    // sort all arrays, this will be needed for performing operations in logical order as well as for comparison
    public init(deletions: [Int] = [], insertions: [Int] = [], reloads: [IndexPair] = [], moves: [IndexPair] = []) {
        self.deletions = deletions.sorted()
        self.insertions = insertions.sorted()
        self.reloads = reloads.sorted { $0.source > $1.source }
        self.moves = moves.sorted { $0.source > $1.source }
    }

    public var changeCount: Int {
        return deletions.count + insertions.count + reloads.count + moves.count
    }

    public var hasChanges: Bool {
        return changeCount > 0
    }
}

public extension IndexDelta {
    
    static var empty: IndexDelta {
        return IndexDelta(deletions: [], insertions: [], reloads: [], moves: [])
    }
}

// MARK: - IndexPathPair

public struct IndexPathPair: Hashable {
    public let source: IndexPath
    public let target: IndexPath
    
    public init(source: IndexPath, target: IndexPath) {
        self.source = source
        self.target = target
    }
}

// MARK: - IndexPathDelta

public struct IndexPathDelta: Equatable {
    // Use index in source data
    public let deletions: [IndexPath]

    // Use index in target data
    public let insertions: [IndexPath]
    
    // index in source data, index in target data (the latter is for manual reloads)
    public let reloads: [IndexPathPair]

    // from index in source data --> to index in target data
    public let moves: [IndexPathPair]

    public init(deletions: [IndexPath] = [], insertions: [IndexPath] = [], reloads: [IndexPathPair] = [], moves: [IndexPathPair] = []) {
        self.deletions = deletions
        self.insertions = insertions
        self.reloads = reloads
        self.moves = moves
    }
    
    public var changeCount: Int {
        return deletions.count + insertions.count + reloads.count + moves.count
    }

    public var hasChanges: Bool {
        return changeCount > 0
    }
}

// MARK: - Better NSIndexPath Description

public extension IndexPath {
    
    var debugDescription: String {
        return "{\(section).\(item)}"
    }
}
