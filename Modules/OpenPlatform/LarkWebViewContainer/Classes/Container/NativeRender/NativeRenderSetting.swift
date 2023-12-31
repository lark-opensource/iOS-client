//
//  NativeRenderSetting.swift
//  LarkWebViewContainer
//
//  Created by baojianjun on 2022/6/14.
//

import Foundation
import LarkSetting

// MARK: - AppSetting
public struct LarkWebViewNativeComponentSettings {
    private static let kOPNativeComponentGesturesFix = UserSettingKey.make(userKeyLiteral: "OPNativeComponentGesturesFix")
    private static let kGesturesFix = "gesturesFix"
    private static let kHitTestFirstResponderFix = "hitTestFirstResponderFix"
    private static let kBlackListGes = "blackListGes"
    
    private static func nativeComponentGesturesFix() -> [String: Any] {
        do {
            let config: [String: Any] = try SettingManager.shared.setting(with: kOPNativeComponentGesturesFix)// user:global
            return config
        } catch {
            return [
                kGesturesFix: false,
                kHitTestFirstResponderFix: false,
                kBlackListGes: [],
            ]
        }
    }
    
    public static func gesturesFix() -> Bool {
        let config = self.nativeComponentGesturesFix()
        return config[kGesturesFix] as? Bool ?? false
    }
    
    public static func blackListGes() -> [String] {
        let config = self.nativeComponentGesturesFix()
        return config[kBlackListGes] as? [String] ?? []
    }
    
    public static func hitTestFirstResponderFix() -> Bool {
        let config = self.nativeComponentGesturesFix()
        return config[kHitTestFirstResponderFix] as? Bool ?? false
    }
}
