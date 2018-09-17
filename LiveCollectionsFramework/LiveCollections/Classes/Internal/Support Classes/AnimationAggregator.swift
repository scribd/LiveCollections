//
//  AnimatorAggregator.swift
//  LiveCollections
//
//  Created by Stephane Magne on 7/11/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import Foundation

// MARK: - AnimationAggregator

protocol AnimationAggregatorDelegate: AnyObject {
    func updateView(with sectionUpdates: [SectionUpdate])
    func reloadViewSections(with sectionUpdates: [SectionUpdate])
}

final class AnimationAggregator {
    
    enum Animation {
        case none
        case updateData([SectionUpdate])
        case reloadSections([SectionUpdate])
    }
    
    private var animation: Animation = .none
    weak var delegate: AnimationAggregatorDelegate?
    
    private lazy var invocationCompressor: InvocationCompressor = {
        return InvocationCompressor(strategy: .nextRunLoop,
                                    target: self,
                                    methodSignature: AnimationAggregator._performAnimation)
    }()
    
    func update(_ sectionUpdate: SectionUpdate) {
        
        switch animation {
        case .none,
             .updateData:
            break
        case .reloadSections:
            // flush the differing animation type so the result is cleaner
            _performAnimation()
        }
        
        animation = animation.stateByUpdatingData(sectionUpdate)
        invocationCompressor.invoke()
    }
    
    func reload(_ sectionUpdate: SectionUpdate) {
        
        switch animation {
        case .none,
             .reloadSections:
            break
        case .updateData:
            // flush the differing animation type so the result is cleaner
            _performAnimation()
        }
        
        animation = animation.stateByReloadingSection(sectionUpdate)
        invocationCompressor.invoke()
    }
    
    
    func forceDataUpdates() {
        switch animation {
        case .none:
            break
        case .updateData(let sectionUpdates),
             .reloadSections(let sectionUpdates):
            sectionUpdates.forEach { $0.update() }
        }
    }
    
    private func _performAnimation() {
        print("perform animation")

        switch animation {
        case .none:
            break
        case .updateData(let sectionUpdates):
            delegate?.updateView(with: sectionUpdates)
        case .reloadSections(let sectionUpdates):
            delegate?.reloadViewSections(with: sectionUpdates)
        }
        
        animation = .none
    }
}

extension AnimationAggregator.Animation {
    
    func stateByUpdatingData(_ sectionUpdate: SectionUpdate) -> AnimationAggregator.Animation {
        switch self {
        case .none:
            return .updateData([sectionUpdate])
            
        case .updateData(var previousSectionUpdates):
            if let index = previousSectionUpdates.index(ofSection: sectionUpdate.section) {
                previousSectionUpdates.remove(at: index)
            }
            let allSectionUpdates = previousSectionUpdates + [sectionUpdate]
            return .updateData(allSectionUpdates)
            
        case .reloadSections(let previousSectionUpdates):
            assert(true, "\(AnimationAggregator.self) should have already forced this reload animation to occur.")
            let allSectionUpdates = previousSectionUpdates + [sectionUpdate]
            return .reloadSections(allSectionUpdates)
        }
    }
    
    func stateByReloadingSection(_ sectionUpdate: SectionUpdate) -> AnimationAggregator.Animation {
        switch self {
        case .none:
            return .reloadSections([sectionUpdate])
            
        case .updateData(let previousSectionUpdates):
            assert(true, "\(AnimationAggregator.self) should have already forced this update animation to occur.")
            let allSectionUpdates = previousSectionUpdates + [sectionUpdate]
            return .reloadSections(allSectionUpdates)
            
        case .reloadSections(var previousSectionUpdates):
            if let index = previousSectionUpdates.index(ofSection: sectionUpdate.section) {
                previousSectionUpdates.remove(at: index)
            }
            let allSectionUpdates = previousSectionUpdates + [sectionUpdate]
            return .reloadSections(allSectionUpdates)
        }
    }
}

// MARK: [SectionUpdate] extension

extension Array where Element == SectionUpdate {
    
    func contains(section: Int) -> Bool {
        return index(ofSection: section) != nil
    }
    
    func index(ofSection section: Int) -> Index? {
        return index(where: { $0.section == section })
    }
}
