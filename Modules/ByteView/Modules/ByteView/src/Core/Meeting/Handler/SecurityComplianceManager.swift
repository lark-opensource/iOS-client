//
//  SecurityComplianceManager.swift
//  ByteView
//
//  Created by kiri on 2022/6/8.
//

import Foundation
import ByteViewMeeting

final class SecurityComplianceManager {
    static let shared = SecurityComplianceManager()

    // 安全弹窗剩余时间
    var remainTimeOfSecurityCompliance: UInt?

    private init() {}

    func cleanSecurityAlertTime() {
        if !MeetingManager.shared.hasActiveMeeting {
            remainTimeOfSecurityCompliance = nil
        }
    }
}
