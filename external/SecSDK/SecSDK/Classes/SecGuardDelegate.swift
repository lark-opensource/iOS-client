//
//  SecGuardDelegate.swift
//  EETest
//
//  Created by moqianqian on 2020/1/10.
//

import Foundation
import SecGuard
import AppContainer
import LarkContainer
import LarkAccountInterface
import LarkAppConfig
import RustPB
import LarkRustClient
import LarkReleaseConfig
import RunloopTools
import Swinject
import LarkSetting
import LKCommonsLogging


struct SecHelper {
    static let logger = Logger.log(SecHelper.self, category: "SecHelper")
    static var secEnabled: Bool {
        let settingOpt = try? SettingManager.shared.setting(with: "lark_security_clientsdk_info")
        SecHelper.logger.info("[SecSDK] setting: \(settingOpt)")
        
        if let setting = settingOpt, let degrade = setting["degrade"] as? Bool {
            // 兜底fg: 出现严重稳定性问题时降级关闭secsdk, 默认线上不配置
            return !degrade
        }
        return true
    }
}

public class SecGuardDelegate: NSObject, SGMSafeGuardDelegate, ApplicationDelegate{
    static public let config = Config(name: "SecGuardDelegate", daemon: true)
    
    @Provider var deviceService: DeviceService
    @Provider var appConfiguration: AppConfiguration
    
    let DEBUG_ID = "1128"
    let INTERNATIONAL_ID = "1664"
    let INHOUSE_ID = "1161"
    
    var deviceID = ""
    var installID = ""
    var domain = ""
    
    public required init(context: AppContext) {
        
        super.init()
        
        RunloopDispatcher.shared.addTask(priority: .low) {
            self.scheduleSecSDKTask()
        }
    }
    
    // unused
    public func sgm_sessionID() -> String {
        return ""
    }
    
    // unused
    public func sgm_installChannel() -> String {
        return "APPLE"
    }
    
    // unused
    public func sgm_installID() -> String {
        return installID
    }
    
    // unused
    public func isUseTTNet() -> Bool{
        return false
    }
    
    // 当前设备的device id
    public func sgm_customDeviceID() -> String{
        return deviceID
    }
    
    // 当前sdk后端的domain
    func sgm_Domain() -> String {
        return domain
    }
    
    // sec token 回调, 设置到rust测
    public func sgm_sectoken(_ token: String) {
        var request = RustPB.Security_V1_UpdateSecTokenRequest()
        request.secToken = token
        var packet = RequestPacket(message: request)
        packet.command = Command.updateSecToken
        
        let globalService = Container.shared.resolve(GlobalRustService.self)
        let _ = globalService?.async(packet) { resp in }
    }
    
    func scheduleSecSDKTask() {
        if !SecHelper.secEnabled {
            SecHelper.logger.info("[SecSDK] schedule task is disabled")
            return
        }
        
        // device id
        let deviceService = self.deviceService
        self.deviceID = deviceService.deviceId
        // install id
        self.installID = deviceService.installId
        
        let appConfig = self.appConfiguration
        // domain
        self.domain = appConfig.settings[.suiteSecsdk]?.first ?? ""
        // app id
#if DEBUG
        let appID = self.DEBUG_ID
#else
        let appID = ReleaseConfig.appIdForAligned
#endif
        
        if(self.deviceID != ""){
            if (appID != self.INTERNATIONAL_ID){
                SecHelper.logger.info("[SecSDK] schedule task start")
                let config  = SGMSafeGuardConfig.init(domain: self.domain, appID: appID)
                let manager = SGMSafeGuardManager.shared()
                manager.sgm_start(with: config, delegate: self)
                manager.sgm_scheduleSafeGuard(true)
            } else {
                //海外版Lark暂不启动secsdk
                SecHelper.logger.info("[SecSDK] schedule task skipped for oversea env")
            }
        } else {
            SecHelper.logger.info("[SecSDK] schedule task failed because of empty did")
        }
    }
}

/// 返回本地的环境检测信息
///
/// 如果检测有效，返回如下格式的字符串:
/// `{"risk": [], "detail": ""}`
///
/// 如果检测无效或发生错误: 则返回空串""
///
public func SecLocalEnv() -> String {
    if !SecHelper.secEnabled {
        SecHelper.logger.info("[SecSDK] SecLocalEnv disabled")
        return ""
    }
    
    SecHelper.logger.info("[SecSDK] SecLocalEnv start")
    return SGMSafeGuardManager.shared().sgm_rawLocalEnv() ?? ""
}
