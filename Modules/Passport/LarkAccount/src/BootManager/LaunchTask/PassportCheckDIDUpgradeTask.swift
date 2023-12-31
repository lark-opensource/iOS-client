//
//  PassportCheckDIDUpgradeTask.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/6.
//

import Foundation
import BootManager
import LarkAccountInterface
import LarkReleaseConfig
import LKCommonsLogging
import ECOProbeMeta
import LarkEnv

class PassportCheckDIDUpgradeTask: BranchBootTask, Identifiable{ // user:checked (boottask)
    
    static var identify = "PassportCheckDIDUpgradeTask"

    /**
        iPad 端启用分屏时，会构建一个新的window，
        同时会重新执行bootManager的所有流程，包括beforeLoginFlow.
        现在BootManager没有用于区分场景的标识，只能借用 runOnlyOnce() 达到类似的效果
     */
    override var runOnlyOnce: Bool { return true }
    
    static let logger = Logger.log(PassportCheckDIDUpgradeTask.self, category: "PassportCheckDIDUpgradeTask")
    
    public override var runOnlyOnceInUserScope: Bool { return true }
    
    override func execute(_ context: BootContext) {
        
        guard !PassportStore.shared.universalDeviceServiceUpgraded else { //判断是不是已经切换到了统一did
            
            //如果关闭了灰度，进行降级
            if !PassportGray.shared.getGrayValue(key: .enableUniversalDid) {
                let uniDid = PassportUniversalDeviceService.shared.deviceId //统一did
                let uniIid = PassportUniversalDeviceService.shared.installId //统一iid
                
                if DeviceInfo.isDeviceIDValid(uniDid),
                   DeviceInfo.isInstallIDValid(uniIid) {
                    /*
                     正式session的unit都设置一遍统一did，保留匿名session unit的旧did
                     https://bytedance.feishu.cn/docx/YHtzdJAncojsy8xOYl6caftanlf
                     */
                    UserManager.shared.getActiveUserList().forEach { userInfo in // 旧did服务的 did map 数据，有效session的unit 都更新为统一did
                        if let unit = userInfo.user.unit {
                            PassportStore.shared.setDeviceID(deviceID: uniDid, unit: unit)
                            PassportStore.shared.setInstallID(installID: uniIid, unit: unit)
                        }
                    }
                    
                    //因为iOS登出后会清空旧did服务的did map, 降级时如果包unit没有值，需要重新设置
                    let packageUnit = EnvManager.getPackageEnv().unit
                    if  let packageUnitDID = PassportStore.shared.deviceIDMap?[packageUnit],
                        DeviceInfo.isDeviceIDValid(packageUnitDID) {
                        //包unit有值，不处理
                        Self.logger.info("n_action_uni_did_rollback_package_unit_did_not_null")
                    } else {
                        //包unit无值，重新设置一个
                        PassportStore.shared.setDeviceID(deviceID: uniDid, unit: packageUnit)
                        PassportStore.shared.setInstallID(installID: uniIid, unit: packageUnit)
                    }
                    
                } else {
                    //理论上不会出现没有统一did的场景，如果出现了不进行回滚操作，继续使用统一did服务
                    Self.logger.error("n_action_uni_did_rollback_fail", body: "uni did invalid")
                    return
                }
                
                //切换为旧did服务
                Self.logger.info("n_action_uni_did_switch_to_ranger")
                PassportDeviceServiceWrapper.shared.switchToRangersDeviceService()
                
                //上报统一did回滚
                PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_unit_did_rollback,
                                           eventName: ProbeConst.monitorEventName,
                                           context: UniContextCreator.create(.didUpgrade))
            }
            return
        }
        
        if PassportGray.shared.getGrayValue(key: .enableUniversalDid) {
            
            //没有登录态，直接切换did服务为统一did
            guard PassportStore.shared.isLoggedIn else {
                PassportDeviceServiceWrapper.shared.switchToUniversalDeviceService()
                
                Self.logger.info("n_action_uni_did_switch_to_universal", body: "unLogin")
                return
            }
            
            //私有化KA包
            guard !ReleaseConfig.isPrivateKA else {
                //迁移当前的did作为统一did(如果可用)
                if PassportDeviceServiceWrapper.shared.makePackageDeviceInfoUniversal() {
                    //切换did服务为统一did
                    PassportDeviceServiceWrapper.shared.switchToUniversalDeviceService()
                    
                    Self.logger.info("n_action_uni_did_switch_to_universal", body: "private ka")
                } else {
                    Self.logger.warn("n_action_uni_did_private_ka_ranger_did_invalid")
                    //异常场景异常处理(统一did切换失败)
                }
                return
            }
            
            // 开始session升级
            NewBootManager.shared.context.blockDispatcher = true
            self.flowCheckout(.passportDIDUpgradeFlow)
        }
    }
}


