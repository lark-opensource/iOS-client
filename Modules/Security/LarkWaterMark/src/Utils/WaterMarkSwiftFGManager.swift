//
//  WaterMarkSwiftFGManager.swift
//  LarkWaterMark
//
//  Created by ByteDance on 2022/11/30.
//

import Foundation
import LarkSetting

@objc
public final class WaterMarkSwiftFGManager: NSObject {
    
    @objc
    public class func featureGatingValue(with nsstring: NSString) -> Bool {
        let string = nsstring as String
        let key = FeatureGatingManager.Key(stringLiteral: string)
        return FeatureGatingManager.shared.featureGatingValue(with: key)
    }
    
    @objc
    public class func isWatermarkHitTestFGOn() -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: "admin.security.watermark_hit_test")
    }
    
    @objc
    public class func isWatermarkWindowFGOn() -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: "admin.security.watermark_uiwindow_hook")
    }
}
