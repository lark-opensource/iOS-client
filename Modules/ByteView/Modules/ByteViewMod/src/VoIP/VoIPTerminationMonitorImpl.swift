//
//  VoIPTerminationMonitorImpl.swift
//  Lark
//
//  Created by ford on 2019/4/10.
//  Copyright © 2019 Bytedance.Inc. All rights reserved.
//
import Foundation
import LarkVoIP
import ByteView

final class VoIPTerminationMonitorImpl: VoipTerminationMonitorType {
    let lastestTerminationType: VoipTerminationType
    init(service: TerminationMonitor) {
        switch service.latestTerminationType {
        case .userKilled:
            self.lastestTerminationType = .userKilled
        case .appCrashed:
            self.lastestTerminationType = .appCrashed
        case .systemRecycled:
            self.lastestTerminationType = .systemRecycled
        default:
            self.lastestTerminationType = .unknown
        }
    }
}
