//
//  MobileClassify.swift
//  SKCommon
//
//  Created by GuoXinyi on 2023/2/8.
//

import Foundation
import LarkSetting
import SKFoundation

public enum MobileClassifyType: String {
    
    /// 高端机
    case highMobile =   "mobile_classify_high"
    /// 中端机
    case middleMobile = "mobile_classify_mid"
    /// 低端机
    case lowMobile =    "mobile_classify_low"
    
    case unClassify =   "mobile_unclassify"
}

public struct MobileClassify {
    private static var _mobileClassType: MobileClassifyType?
    public static var mobileClassType: MobileClassifyType {
        if let type = _mobileClassType {
            return type
        }
        let deviceClassify = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "get_device_classify"))
        if let deviceType = deviceClassify?["mobileClassify"] as? String,
            let type = MobileClassifyType(rawValue: deviceType) {
            _mobileClassType = type
            DocsLogger.info("get_device_classify: \(deviceType)")
            return type
        }
        return MobileClassifyType.unClassify
    }
    
    public static var isHigh: Bool {
        return Self.mobileClassType == .highMobile
    }
    
    public static var isMiddle: Bool {
        return Self.mobileClassType == .middleMobile
    }
    
    public static var isLow: Bool {
        return Self.mobileClassType == .lowMobile
    }
}
