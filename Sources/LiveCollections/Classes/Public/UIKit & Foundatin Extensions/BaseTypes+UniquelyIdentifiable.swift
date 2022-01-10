//
//  BaseTypes+UniquelyIdentifiable.swift
//  LiveCollectionsTests
//
//  Created by Stephane Magne on 8/29/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

extension String: UniquelyIdentifiable {
    public typealias RawType = String
    public typealias UniqueIDType = String
}

extension FixedWidthInteger where Self: UniquelyIdentifiable {
    public typealias RawType = Self
    public typealias UniqueIDType = Self
}

extension Int: UniquelyIdentifiable { }
extension Int8: UniquelyIdentifiable { }
extension Int16: UniquelyIdentifiable { }
extension Int32: UniquelyIdentifiable { }
extension Int64: UniquelyIdentifiable { }
extension UInt: UniquelyIdentifiable { }
extension UInt8: UniquelyIdentifiable { }
extension UInt16: UniquelyIdentifiable { }
extension UInt32: UniquelyIdentifiable { }
extension UInt64: UniquelyIdentifiable { }

extension FloatingPoint where Self: UniquelyIdentifiable {
    public typealias RawType = Self
    public typealias UniqueIDType = Self
}

extension Float: UniquelyIdentifiable { }
extension Double: UniquelyIdentifiable { }
extension CGFloat: UniquelyIdentifiable { }
