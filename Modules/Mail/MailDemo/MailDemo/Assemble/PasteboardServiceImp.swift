//
//  PasteboardServiceImp.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/7/6.
//

import Foundation
import LarkSecurityAudit
import LarkEMM
import LarkContainer
import LarkAccountInterface
import CommonCrypto
import EENavigator
import UIKit
import LarkWaterMark
import CryptoSwift

protocol PasteboardService {
    func checkProtectPermission() -> Bool
    func currentEncryptUserId() -> String?
    func currentTenantName() -> String?
    func onWaterMarkViewCovered(_ window: UIWindow)
}

class PasteboardServiceImp: PasteboardService {
    private var lastPasteProtectPermission: Bool?
    private var lastPasteProtectPermissionKey: String {
        let userId = currentEncryptUserId()
        return "PasteboardServiceImp.\(userId ?? "").lastPasteProtectPermission"
    }

    init() {}

    func checkProtectPermission() -> Bool {
        return false
    }

    func currentEncryptUserId() -> String? {
        return nil
    }

    func currentTenantName() -> String? {
        return nil
    }

    func onWaterMarkViewCovered(_ window: UIWindow) {
        
    }
}
