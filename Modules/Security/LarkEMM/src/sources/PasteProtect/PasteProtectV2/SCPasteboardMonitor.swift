//
//  SCPasteboardMonitor.swift
//  LarkEMM
//
//  Created by ByteDance on 2023/12/26.
//

import Foundation
import LarkSecurityComplianceInfra

struct SCPasteboardMonitor {
    static func monitorPasteProtectVersion(_ version: String) {
        SCMonitor.info(business: .paste_protect, eventName: "version", category: ["version": ""])
    }
}
