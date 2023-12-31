//
//  FileCryptoDeviceKey.swift
//  SecurityComplianceDebug
//
//  Created by qingchun on 2023/7/9.
//

import UIKit
import LarkContainer
import LarkSecurityCompliance
import LarkAccountInterface

class FileCryptoDeviceKey {
    
    static func deviceKey() -> Data {
        @Provider var service: FileCryptoService
        @Provider var passportService: PassportService
        do {
            return try service.deviceKey(did: Int64(passportService.deviceID) ?? 0)
        } catch {
            return Data()
        }
    }
}
