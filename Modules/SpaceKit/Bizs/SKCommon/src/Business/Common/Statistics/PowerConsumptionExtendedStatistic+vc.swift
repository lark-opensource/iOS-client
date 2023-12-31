//
//  PowerConsumptionExtendedStatistic+vc.swift
//  SKCommon
//
//  Created by ByteDance on 2022/12/28.
//

import Foundation

extension PowerConsumptionExtendedStatistic {
    
    public func markBeginMagicShare() {
        Self.markStart(scene: .magicShare)
    }
    
    public func markEndMagicShare() {
        Self.markEnd(scene: .magicShare)
    }
}
