//
//  DiskEncoderInterface.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

protocol FileEncoderInterface: AnyObject {
    associatedtype DataType
    var folderName: String { get }
    func decode(from data: Data) -> DataType?
    func encode(for item: DataType) -> Data?
}

final class DiskCache<DataType> {
    
    private let decode: (Data) -> DataType?
    private let encode: (DataType) -> Data?
    private let localURL: URL
    
    init<Encoder>(_ encoder: Encoder) where Encoder: FileEncoderInterface, Encoder.DataType == DataType {
        
        localURL = DiskCache.folderURL(for: encoder.folderName)
        DiskCache.ensureDirectoryExists(for: localURL)
        
        decode = { data in
            return encoder.decode(from: data)
        }
        encode = { item in
            encoder.encode(for: item)
        }
    }
    
    subscript(name: String) -> DataType? {
        get {
            let fileURL = localURL.appendingPathComponent(name)
            return readItem(fileURL: fileURL) }
        set {
            let fileURL = localURL.appendingPathComponent(name)
            writeItem(newValue, fileURL: fileURL)
        }
    }
    
    private func readItem(fileURL: URL) -> DataType? {
        guard let fileData = FileManager.default.contents(atPath: fileURL.path) else { return nil}
        return decode(fileData)
    }
    
    private func writeItem(_ item: DataType?, fileURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            guard let item = item else { return }
            
            let data = encode(item)
            guard FileManager.default.createFile(atPath: fileURL.path, contents: data, attributes: nil) else {
                throw NSError(domain: "Failed to write image file at \(fileURL)", code: 1, userInfo: nil)
            }
        } catch {
            assert(true, "\(DiskCache.self) Error: \(error)")
        }
    }

    private static func folderURL(for folderName: String) -> URL {
        return RootURLProvider.rootURL.appendingPathComponent(folderName, isDirectory: true)
    }
    
    private static func ensureDirectoryExists(for localURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: localURL.path) == false {
                try FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            assert(true, "\(DiskCache.self) Error: \(error)")
        }
    }
}

private final class RootURLProvider {
    
    static let rootURL: URL = {
        let applicationSupportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last
        precondition(applicationSupportDirectory != nil)
        guard let rootURL = applicationSupportDirectory else {
            assert(true, "\(RootURLProvider.self) couldn't find a valid application support directory. Is your device ok?")
            return URL(fileURLWithPath: "/")
        }
        return rootURL
    }()
}
