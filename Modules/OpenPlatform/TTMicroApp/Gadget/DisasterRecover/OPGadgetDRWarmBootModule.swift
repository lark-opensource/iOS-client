//
//  OPGadgetDRWarmBootModule.swift
//  TTMicroApp
//
//  Created by justin on 2023/2/21.
//

import Foundation
import OPSDK

final class OPGadgetDRWarmBootModule: OPGadgetDRModule {
    
    override class func getModuleName() -> String {
        return DRModuleName.WARMBOOT.rawValue
    }
    
    override class func getPriority() -> DRModulePriority {
        return .warmboot
    }
    
    override func startDRModule(config: OPGadgetDRConfig?) {
        self.config = config
        guard let safeConfig = config else {
            moduleDidFinished(self)
            return
        }
        let triggerScene = safeConfig.triggerScene
        /* https://bytedance.feishu.cn/wiki/wikcnpqWa5lMPivtytV7Chy5oqg
         serverSetting 无意义，因为这时候被前置条件拦截，不会触发容灾
         larkSetting 清理保活小程序，但不清理 主导航小程序以及后台播放的小程序x
         gadgetMenuClearCache 清理当前的小程序即可，但需要排除Tab小程序，避免如 清理独立容器的审批，但主导航审批也被清理的情况
         */
        if(triggerScene == .serverSetting){
            OPGadgetDRLog.logger.warn("should not try to clean warmboot when get serverSettings")
            moduleDidFinished(self)
            return
        }
        
        if(triggerScene == .larkSetting){
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                
                if let allAliveAppIds = BDPWarmBootManager.shared().aliveAppUniqueIdSet {
                    allAliveAppIds.forEach { uniqueID in
                        // 非主Tab并且可以自动回收的应用，校验是否需要清理临时区
                        if !OPGadgetRotationHelper.isTabGadget(uniqueID) && BDPWarmBootManager.shared().isAutoDestroyEnable(with: uniqueID) {
                            OPApplicationService.current.getContainer(uniuqeID: uniqueID)?.removeTemporaryTab()
                        }
                    }
                }
                BDPWarmBootManager.shared().clearAllWarmBootCache()
                self.moduleDidFinished(self)
            }
            return
        }
        
        if(triggerScene == .gadgetMenuClearCache){
            guard let firstAppID = safeConfig.appIdList.first else {
                moduleDidFinished(self)
                return
            }

            var targetAppId : OPAppUniqueID? = nil
            BDPWarmBootManager.shared().aliveAppUniqueIdSet.forEach { uniqueID in
                if uniqueID.appID == firstAppID && !OPGadgetRotationHelper.isTabGadget(uniqueID){
                    targetAppId = uniqueID
                }
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                if let clearUniqueID = targetAppId {
                    // iPad临时区关闭
                    OPApplicationService.current.getContainer(uniuqeID: clearUniqueID)?.removeTemporaryTab()
                    BDPWarmBootManager.shared().cleanCache(with: clearUniqueID)
                    OPGadgetDRLog.logger.info("warmboot clear finished, appID:\(clearUniqueID), module:\(Self.getModuleName())")
                }
                self.moduleDidFinished(self)
            }
        }
        
    }
}
