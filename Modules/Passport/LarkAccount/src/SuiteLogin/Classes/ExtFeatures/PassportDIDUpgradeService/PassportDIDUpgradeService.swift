//
//  PassportDidUpgradeService.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/9.
//

import Foundation
import RxSwift
import RustPB
import LarkContainer
import LarkRustClient
import LarkAccountInterface
import LarkReleaseConfig
import LarkAlertController
import EENavigator
import ECOProbeMeta
import LKCommonsLogging

class PassportDIDUpgradeService {
    
    static let logger = Logger.log(PassportDIDUpgradeService.self, category: "PassportDidUpgradeService")
    
    private let disposeBag = DisposeBag()
    
    @Provider var rustService: GlobalRustService
    
    @Provider var launcher: Launcher
    
    @Provider private var passportCookieDependency: AccountDependency // user:checked (global-resolve)
    
    @Provider private var rustDependency: PassportRustClientDependency // user:checked (global-resolve)
    
    public func startUpgradeSession(finished: @escaping (Result<Void, Error>) -> Void) {
        
    
        //上报session升级开始
        let sessionUpgradeStartTime = Date().timeIntervalSince1970
        PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_session_upgrade_start,
                                   eventName: ProbeConst.monitorEventName,
                                   context: UniContextCreator.create(.didUpgrade))
        
        PassportDIDUpgradeAPI().upgradeSessions()
            .timeout(.seconds(8), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] resp in
                guard let self = self else {
                    finished(.failure(V3LoginError.clientError("instance released")))
                    return
                }
                
                //上报session升级成功
                let sessionUpgradeSuccTime = Date().timeIntervalSince1970
                Self.logger.info("n_action_session_upgrade_succ")
                PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_session_upgrade_succ,
                                           eventName: ProbeConst.monitorEventName,
                                           categoryValueMap: ["cost": sessionUpgradeSuccTime - sessionUpgradeStartTime],
                                           context: UniContextCreator.create(.didUpgrade))
                
                //执行session升级成功后的代码处理
                self.actionsAfterSessionUpgrade(with: resp.userList)
                //结束升级流程
                PassportDeviceServiceWrapper.shared.blockMode = false
                finished(.success(()))
            } onError: { error in
                PassportDeviceServiceWrapper.shared.blockMode = false
                finished(.failure(error))
                
                //上报统一did升级超时
                if case RxError.timeout = error {
                    Self.logger.error("n_action_session_upgrade_timeout")
                    PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_uni_did_switch_timeout,
                                               eventName: ProbeConst.monitorEventName,
                                               context: UniContextCreator.create(.didUpgrade))
                }
                
                //上报session升级失败
                Self.logger.error("n_action_session_upgrade_fail", error: error)
                PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_session_upgrade_fail,
                                           eventName: ProbeConst.monitorEventName,
                                           categoryValueMap: ["error_code": (error as NSError).code],
                                           context: UniContextCreator.create(.didUpgrade),
                                           error: error)
                
            }.disposed(by: self.disposeBag)
        
        PassportDeviceServiceWrapper.shared.blockMode = true
    }
    
    private func actionsAfterSessionUpgrade(with userList: [V4UserInfo]) {
        
        //
        var logoutTokens: [String] = []
        //记录某个unit的did切换到了统一did
        var didChangedMap: [String: String] = [:]
        for newUser in userList {
            // 保存user出现更新的old did
            if newUser.isActive,
               let unit = newUser.user.unit,
               let legacyDid = PassportStore.shared.getDeviceID(unit: unit) {
                didChangedMap[unit] = legacyDid
            }
            
            //把老的session登出（logoutToken加入logoutTokenArray）
            if newUser.isActive,
               let oldUser = PassportStore.shared.getUser(userID: newUser.userID),
               oldUser.isActive,
               let logoutToken = oldUser.logoutToken {
                logoutTokens.append(logoutToken)
            }
            // Todo: 如果前台用户下发的是匿名的是否要失败处理
            // 更新user 到本地
            UserManager.shared.addUserToStore(newUser)
        }
        
        //登出 logoutTokenArray中的所有token
        OfflineLogoutHelper.shared.append(logoutTokens: logoutTokens)

        //更新keychain中的logout token
        if !logoutTokens.isEmpty {
            UserManager.shared.updateCachedLogoutTokenList()
        }
        
        //PassportStore存储变更前的did map
        PassportStore.shared.didChangedMap = PassportStore.shared.deviceIDMap
        
                
        //同步变更前的所有[unit: did] 到rustSDK
        //所有值的原因：
        //切换到统一did后，再登录一个新租户，如果这个租户之前在这台设备登录过
        //同样需要把旧did给到rustSDK，用于拉取离线的密聊消息；
        if didChangedMap.count > 0 {
            var request = Device_V1_SetOldDeviceIdRequest()
            request.oldDeviceIds = PassportStore.shared.deviceIDMap ?? [:]
            rustService.sendAsyncRequest(request).subscribe(onError: { error in
                //上报rustSDK设置旧did失败
                PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_rust_set_old_did_fail,
                                           eventName: ProbeConst.monitorEventName,
                                           categoryValueMap: ["error_code": (error as NSError).code],
                                           context: UniContextCreator.create(.didUpgrade),
                                           error: error)
            }).disposed(by: disposeBag)
            
            //上报did发生变更埋点
            PassportMonitor.delayFlush(EPMClientPassportMonitorUniversalDidCode.passport_did_changed,
                                       eventName: ProbeConst.monitorEventName,
                                       categoryValueMap: ["count": didChangedMap.count,
                                                          "old_did": didChangedMap.values,
                                                          "uni_did": PassportDeviceServiceWrapper.shared.deviceId],
                                       context: UniContextCreator.create(.didUpgrade))
            
            Self.logger.info("n_action_session_upgrade_did_changed_map", additionalData: didChangedMap)
        } else {
            Self.logger.info("n_action_session_upgrade_no_did_change")
        }
        
        //更新rustSDK did和iid
        

        if (MultiUserActivitySwitch.enableMultipleUser) {
            rustDependency.updateDeviceInfoV2(did: PassportUniversalDeviceService.shared.deviceId, iid: PassportUniversalDeviceService.shared.installId) { result in
                switch result {
                case .success(_):
                    Self.logger.info("n_action_session_upgrade_rsut_set_deviceinfo_succ_v2", method: .local)
                case .failure(let error):
                    //日志和埋点
                    Self.logger.error("n_action_session_upgrade_rust_set_deviceinfo_fail_v2", error: error)
                    PassportMonitor.delayFlush(PassportMonitorMetaUniversalDID.rustSetDeviceInfoFail,
                                               categoryValueMap: ["version": "2"],
                                               context: UniContextCreator.create(.didUpgrade),
                                               error: error)
                }
            }

        } else {
            rustDependency.updateDeviceInfo(did: PassportUniversalDeviceService.shared.deviceId, iid: PassportUniversalDeviceService.shared.installId) { result in
                switch result {
                case .success(_):
                    Self.logger.info("n_action_session_upgrade_rsut_set_deviceinfo_succ", method: .local)
                case .failure(let error):
                    //日志和埋点
                    Self.logger.error("n_action_session_upgrade_rust_set_deviceinfo_fail", error: error)
                    PassportMonitor.delayFlush(PassportMonitorMetaUniversalDID.rustSetDeviceInfoFail,
                                               context: UniContextCreator.create(.didUpgrade),
                                               error: error)
                }
            }
        }
        
        //更新cookie
        if let foregroundUser = UserManager.shared.foregroundUser { // user:current
            passportCookieDependency.setupCookie(user: foregroundUser.makeUser()) // user:current
        }
        
        //切换did服务为统一did服务
        PassportDeviceServiceWrapper.shared.switchToUniversalDeviceService()
        
        //比较本次启动为did upgrade
        launcher.launcherContext.isDIDUpgrade = true
    }
    
}
