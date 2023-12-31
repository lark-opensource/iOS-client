//
//  PrefetchMockSetting.swift
//  OPPlugin-Unit-Tests
//
//  Created by ByteDance on 2023/12/5.
//

import Foundation
import OPUnitTestFoundation
import OPFoundation
@testable import LarkSetting

struct PrefetchMockSetting {
    static let fixDecodekey = "prefetch_fix_decode"
    
    static func enableFixDecode() {
        SettingStorage.updateSettingValue(Self.enableFixDecodeValue, with: SettingManager.currentChatterID(), and: Self.fixDecodekey)
    }
    static func disableFixDecode() {
        SettingStorage.updateSettingValue(Self.disableFixDecodeValue, with: SettingManager.currentChatterID(), and: Self.fixDecodekey)
    }
    
    private static let enableFixDecodeValue = """
    {
        "appIds": [],
        "default": true
    }
    """
    
    private static let disableFixDecodeValue = """
    {
        "appIds": [],
        "default": false
    }
    """
}
