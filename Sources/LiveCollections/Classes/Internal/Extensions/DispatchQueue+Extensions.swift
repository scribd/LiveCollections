//
//  DispatchQueue+Extensions.swift
//  LiveCollections
//
//  Created by Stephane Magne on 10/13/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

extension DispatchQueue {
    
    func safeSync<T>(execute work: () -> T) -> T {
        
        if Thread.isMainThread, self === DispatchQueue.main {
            return work()
        } else {
            return sync { return work() }
        }
    }
}
