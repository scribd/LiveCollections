//
//  InvocationCompressor.swift
//  LiveCollections
//
//  Created by Stephane Magne on 7/11/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

/**
 This class is to solve the problem where individual actors may all trigger the same
 action, where only one instance of that action need be invoked. It's use in of itself
 is not a particularly good design pattern, but we sometimes find ourselves interacting
 with code whose behavior we can't control.
 
 The common problem is that N calls results in N actions where N-1 of those actions are redundant.
 In the case where the action is resource intensive, this is undesirable.  This could be the result of
 multiple objects making the call independently, or a response to a series of actions in a loop.
 
 By invoking via this object, the action will be performed after a short delay, but will
 only perform once. N-1 calls are effectively ignored. Once the timer is fired,
 or the async block is run, the next call will perform the action once again.
 
 The reason I use this code here is to allow multiple sections within a tableView or collectionView
 each have their own data source that work independently.  As a result, there can be cases where
 multiple sections will update their data on the same run-loop (usually due to responding to the
 same event) and if we only trigger animations for a single section, the app will crash as data
 in the other sections will be out of sync.
 */

final class InvocationCompressor {
    
    enum Strategy {
        case rateLimit(DispatchTimeInterval) // first call is immediate, subsequent calls during interval are blocked
        case delay(DispatchTimeInterval)     // all calls blocked for duration, single call after interval
        case nextRunLoop                     // all calls are blocked, single call on next run loop
    }
    
    private let action: () -> Void
    
    private let actionQueue: DispatchQueue
    let strategy: Strategy
    
    private var isExecuting = false
    private let batchQueue = DispatchQueue(label: "InvocationCompressorBatchQueue")
    
    init<Type>(strategy: Strategy, queue: DispatchQueue = .main, target: Type, methodSignature: @escaping (Type) -> () -> Void) where Type: AnyObject {
        self.strategy = strategy
        self.actionQueue = queue
        self.action = { [weak target] in
            guard let strongTarget = target else { return }
            methodSignature(strongTarget)()
        }
    }
    
    func invoke() {
        
        if shouldPerformImmediately() {
            action()
        }
        
        batchQueue.async(flags: .barrier) {
            guard self.isExecuting == false else {
                return
            }
            
            self.isExecuting = true
            
            let performAction: (Strategy) -> Void = { [weak self] strategy in
                guard let strongSelf = self else {
                    return
                }
                
                switch strategy {
                case .rateLimit:
                    break
                case .delay,
                     .nextRunLoop:
                    strongSelf.action()
                }
                
                strongSelf.batchQueue.async(flags: .barrier) { [weak strongSelf] in
                    guard let asyncSelf = strongSelf else { return }
                    asyncSelf.isExecuting = false
                }
            }
            
            let completion: (Strategy) -> Void = { strategy in
                self.actionQueue.async {
                    performAction(strategy)
                }
            }
            
            let delayedCompletion: (Strategy, DispatchTimeInterval) -> Void = { strategy, interval in
                let deadline: DispatchTime = .now() + interval
                self.actionQueue.asyncAfter(deadline: deadline, execute: {
                    performAction(strategy)
                })
            }
            
            switch self.strategy {
            case .rateLimit(let interval),
                 .delay(let interval):
                delayedCompletion(self.strategy, interval)
            case .nextRunLoop:
                completion(self.strategy)
            }
        }
    }
    
    private func shouldPerformImmediately() -> Bool {
        
        switch strategy {
        case .rateLimit:
            break
        case .delay,
             .nextRunLoop:
            return false
        }
        
        var shouldPerform = false
        
        batchQueue.sync {
            shouldPerform = self.isExecuting == false
        }
        
        return shouldPerform
    }
}
