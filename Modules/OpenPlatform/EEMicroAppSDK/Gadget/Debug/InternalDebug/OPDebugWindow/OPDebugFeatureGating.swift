//
//  OPDebugWindow+OPDebugFeatureGating.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/3/3.
//

import Foundation
import OPFoundation

/// 负责新版小程序调试功能的应用范围
@objcMembers
public final class OPDebugFeatureGating: NSObject {

    /// 是否对调试窗口使用降级方案
    /// 当出现无法预估到的错误时将downgrade属性设置为true，进行降级
    public static var downgrade = false

    /// 新版的Debug调试能力是否处于可用状态
    /// 所有的入口都需要先经过该接口判断
    public static func debugAvailable() -> Bool {
        // 如果方案被降级则不使用新版调试
        if downgrade {
            return false
        }
        // DiagnoseAPI可用性
        if (!EMAFeatureGating.boolValue(forKey: EMAFeatureGatingKeyMicroAppDiagnoseApiEnable)) {
            return false;
        }
        // 获取调试小程序的uniqueID
        guard let debugAppID = EMAAppEngine.current()?.onlineConfig?.debuggerAppID() else {
            return false
        }
        let uniqueID = OPAppUniqueID(appID: debugAppID, identifier: nil, versionType: .current, appType: .gadget)
        // debug小程序是否可以调用DiagnoseAPI
        if !(EMAAppEngine.current()?.onlineConfig?.isApiAvailable("execDiagnoseCommands", for: uniqueID) ?? false) {
            return false
        }

        // 若不处于Debug模式
        if !(EMAAppEngine.current()?.onlineConfig?.isDebug() ?? false) {
            return false
        }

        // 如果是统一生态Demo工程则直接放行
        if EMASandBoxHelper.gadgetDebug() {
            return true
        // 如果不是，则要受到用户与版本灰度的控制
        } else {
            return (EMAAppEngine.current()?.onlineConfig?.enableDebugApp() ?? false)
        }
    }


}
