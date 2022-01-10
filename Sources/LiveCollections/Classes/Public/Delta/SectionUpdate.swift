//
//  SectionUpdate.swift
//  LiveCollections
//
//  Created by Stephane Magne on 7/11/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

public struct SectionUpdate {
    public let section: Int
    public let delta: IndexDelta
    public let delegate: DeltaUpdatableViewDelegate?
    public let update: () -> Void
    public let completion: (() -> Void)?
    
    public init(section: Int,
                delta: IndexDelta,
                delegate: DeltaUpdatableViewDelegate? = nil,
                update: @escaping () -> Void,
                completion: (() -> Void)? = nil) {
        
        self.section = section
        self.delta = delta
        self.delegate = delegate
        self.update = update
        self.completion = completion
    }
}
