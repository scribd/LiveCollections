//
//  ImageCache.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

// MARK: - ImageCache

final class DataCache<DataType> {
    
    private let dataQueue = DispatchQueue(label: "\(DataCache.self) data queue")
    private var _memoryCache: [String: DataType] = [:]
    private var memoryCache: [String: DataType] { return dataQueue.sync { _memoryCache } }
    private let diskCache: DiskCache<DataType>
    
    init<DiskEncoder>(encoder: DiskEncoder) where DiskEncoder: FileEncoderInterface, DiskEncoder.DataType == DataType {
        self.diskCache = DiskCache(encoder)
    }
    
    subscript(name: String) -> DataType? {
        get { return cachedItem(name) }
        set { writeItem(newValue, name: name) }
    }

    func clearCache() {
        dataQueue.async { self._memoryCache = [:] }
    }
    
    // MARK: Private

    private func cachedItem(_ name: String) -> DataType? {
        if let memoryItem = memoryCache[name] {
            return memoryItem
        }
        if let diskItem = diskCache[name] {
            dataQueue.async(flags: .barrier) { self._memoryCache[name] = diskItem }
            return diskItem
        }
        return nil
    }
    
    private func writeItem(_ item: DataType?, name: String) {
        diskCache[name] = item
    }
}
