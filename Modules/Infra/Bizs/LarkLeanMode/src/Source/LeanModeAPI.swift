//
//  LeanModeAPI.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/6.
//

import Foundation
import RxSwift
import RustPB
import LarkStorage
import LarkRustClient
import RxCocoa
import LKCommonsLogging

public struct LeanModeStatusAndAuthority: Codable {
    private static let logger = Logger.log(LeanModeStatusAndAuthority.self, category: "LeanMode.LeanModeStatusAndAuthority")

    // 精简模式配置
    public let deviceHaveAuthority: Bool // 是否有权限开关精简模式
    public let allDevicesInLeanMode: Bool // 精简模式是否开启
    public let canUseLeanMode: Bool // 用户是否可以使用精简模式（原fg）
    public let leanModeUpdateTime: Int64 // 更新时间(毫秒)

    // 锁屏密码配置
    public let lockScreenPassword: String // 锁屏密码
    public let isLockScreenEnabled: Bool // 锁屏密码是否开启
    public let lockScreenUpdateTime: Int64 // 锁屏密码更新时间

    public init(deviceHaveAuthority: Bool, allDevicesInLeanMode: Bool, canUseLeanMode: Bool, leanModeUpdateTime: Int64,
                lockScreenPassword: String, isLockScreenEnabled: Bool, lockScreenUpdateTime: Int64) {
        self.deviceHaveAuthority = deviceHaveAuthority
        self.allDevicesInLeanMode = allDevicesInLeanMode
        self.canUseLeanMode = canUseLeanMode
        self.leanModeUpdateTime = leanModeUpdateTime
        self.lockScreenPassword = lockScreenPassword
        self.isLockScreenEnabled = isLockScreenEnabled
        self.lockScreenUpdateTime = lockScreenUpdateTime
    }

    func updateLeanModeConfig(deviceHaveAuthority: Bool, allDevicesInLeanMode: Bool, canUseLeanMode: Bool, leanModeUpdateTime: Int64) -> LeanModeStatusAndAuthority {
        return LeanModeStatusAndAuthority(
            deviceHaveAuthority: deviceHaveAuthority,
            allDevicesInLeanMode: allDevicesInLeanMode,
            canUseLeanMode: canUseLeanMode,
            leanModeUpdateTime: leanModeUpdateTime,
            lockScreenPassword: self.lockScreenPassword,
            isLockScreenEnabled: self.isLockScreenEnabled,
            lockScreenUpdateTime: self.lockScreenUpdateTime
        )
    }

    func updateLockScreenConfig(lockScreenPassword: String, isLockScreenEnabled: Bool, lockScreenUpdateTime: Int64) -> LeanModeStatusAndAuthority {
        return LeanModeStatusAndAuthority(
            deviceHaveAuthority: self.deviceHaveAuthority,
            allDevicesInLeanMode: self.allDevicesInLeanMode,
            canUseLeanMode: self.canUseLeanMode,
            leanModeUpdateTime: self.leanModeUpdateTime,
            lockScreenPassword: lockScreenPassword,
            isLockScreenEnabled: isLockScreenEnabled,
            lockScreenUpdateTime: lockScreenUpdateTime
        )
    }

    /// 根据updateTime判断是否数据是否有效
    /// 注：updateTime = 0时为SDK默认值，默认接收
    func check(leanModeUpdateTime: Int64) -> Bool {
        if leanModeUpdateTime == 0 {
            LeanModeStatusAndAuthority.logger.info("LeanMode: new statusAndAuthority.leanModeUpdateTime is zero")
        }
        return leanModeUpdateTime == 0 || leanModeUpdateTime >= self.leanModeUpdateTime
    }

    /// 根据updateTime判断是否数据是否有效
    func check(lockScreenUpdateTime: Int64) -> Bool {
        return lockScreenUpdateTime >= self.lockScreenUpdateTime
    }

    private static let statusAndAuthorityKey = KVKey<Data?>("StatusAndAuthority.V2")

    static func saveToUserDefaults(statusAndAuthority: LeanModeStatusAndAuthority,
                                   store: KVStore) {
        do {
            store[statusAndAuthorityKey] = try JSONEncoder().encode(statusAndAuthority)
        } catch {
            LeanModeStatusAndAuthority.logger.error("LeanMode: saveToUserDefaults error", error: error)
        }
    }

    static func buildFromUserDefaults(store: KVStore) -> LeanModeStatusAndAuthority {
        do {
            if let data = store[statusAndAuthorityKey] {
                return try JSONDecoder().decode(LeanModeStatusAndAuthority.self, from: data)
            }
        } catch {
            LeanModeStatusAndAuthority.logger.error("LeanMode: buildFromUserDefaults error", error: error)
        }
        return LeanModeStatusAndAuthority(
            deviceHaveAuthority: false,
            allDevicesInLeanMode: false,
            canUseLeanMode: false,
            leanModeUpdateTime: 0,
            lockScreenPassword: "",
            isLockScreenEnabled: false,
            lockScreenUpdateTime: 0
        )
    }
}

/// 数据来源：仅push数据源才会走被动开关流程
public enum LeanModeDataScene: Int {
    case pull // 主动pull
    case push // 被动push
    case login
}

protocol LeanModeAPI {
    /// 当前精简模式状态和权限信号
    var leanModeStatusAndAuthorityObservable: Observable<(LeanModeStatusAndAuthority, LeanModeDataScene)> { get }

    /// 离线状态下开启精简模式，在线后失去权限
    var offlineSwitchFailed: Observable<Void> { get }

    /// 当前精简模式状态和权限
    var currentLeanModeStatusAndAuthority: LeanModeStatusAndAuthority { get }

    /// 数据清理
    var dataCleanObservable: Observable<PushCleanDataResponse> { get }

    /// 获取精简模式状态和权限
    func fetchLeanModeStatusAndAuthority(syncDataStrategy: SyncDataStrategy) -> Observable<PullLeanModeStatusAndAuthorityResponse>

    /// 开关精简模式
    /// on: 开启(true)/关闭(false)
    func patchLeanModeStatus(on: Bool) -> Observable<PatchLeanModeStatusResponse>


    /// 修改锁屏密码 & 锁屏是否开启
    /// - Parameters:
    ///   - password: 锁屏密码
    ///   - isEnabled: 锁屏密码是否开启
    func patchLockScreenConfig(password: String?, isEnabled: Bool?) -> Observable<PatchLockScreenCfgResponse>

    /// 更新精简模式状态和权限
    func updateLeanModeStatusAndAuthority(statusAndAuthority: LeanModeStatusAndAuthority, scene: LeanModeDataScene)

    /// 更新offlineSwitchFailed
    func updateOfflineSwitchFailedStatus()

    /// 更新dataCleanObservable
    func updateDataCleanObservable(message: PushCleanDataResponse)
}

final class RustLeanModeAPI: LeanModeAPI {
    private static let logger = Logger.log(RustLeanModeAPI.self,
                                           category: "LarkLeanMode.RustLeanModeAPI")

    private let client: RustService
    private let userStore: KVStore

    private let statusAndAuthorityRelay: BehaviorRelay<(LeanModeStatusAndAuthority, LeanModeDataScene)>
    var leanModeStatusAndAuthorityObservable: Observable<(LeanModeStatusAndAuthority, LeanModeDataScene)> {
        return statusAndAuthorityRelay.asObservable()
    }
    private let offlineSwitchFailedSubject: PublishSubject<Void>
    var offlineSwitchFailed: Observable<Void> {
        return offlineSwitchFailedSubject.asObservable()
    }
    private let dataCleanSubject: PublishSubject<PushCleanDataResponse>
    var dataCleanObservable: Observable<PushCleanDataResponse> {
        return dataCleanSubject.asObservable()
    }
    
    var currentLeanModeStatusAndAuthority: LeanModeStatusAndAuthority {
        return statusAndAuthorityRelay.value.0
    }
    
    init(client: RustService, userID: String) {
        self.client = client
        self.userStore = KVStores.LeanMode.user(id: userID)
        let defaultStatusAndAuthority = LeanModeStatusAndAuthority.buildFromUserDefaults(store: userStore)
        self.statusAndAuthorityRelay = BehaviorRelay(value: (defaultStatusAndAuthority, .pull))
        self.offlineSwitchFailedSubject = PublishSubject()
        self.dataCleanSubject = PublishSubject()
    }
    
    func fetchLeanModeStatusAndAuthority(syncDataStrategy: SyncDataStrategy) -> Observable<PullLeanModeStatusAndAuthorityResponse> {
        var request = PullLeanModeStatusAndAuthorityRequest()
        request.syncDataStrategy = syncDataStrategy
        return client.sendAsyncRequest(request).do(onNext: {[weak self] (response) in
            guard let `self` = self else { return }
            
            var newStatusAndAuthority = self.currentLeanModeStatusAndAuthority
            
            let leanModeChange = newStatusAndAuthority.check(leanModeUpdateTime: response.leanModeCfg.leanModeCfgUpdatedAtMicroSec)
            if leanModeChange {
                newStatusAndAuthority = newStatusAndAuthority.updateLeanModeConfig(
                    deviceHaveAuthority: response.leanModeCfg.deviceHaveAuthority,
                    allDevicesInLeanMode: response.leanModeCfg.allDevicesInLeanMode,
                    canUseLeanMode: response.leanModeCfg.canUseLeanMode,
                    leanModeUpdateTime: response.leanModeCfg.leanModeCfgUpdatedAtMicroSec
                )
            }
            
            let lockScreenChange = newStatusAndAuthority.check(lockScreenUpdateTime: response.lockScreenCfg.lockScreenCfgUpdatedAtMicroSec)
            if lockScreenChange {
                newStatusAndAuthority = newStatusAndAuthority.updateLockScreenConfig(
                    lockScreenPassword: response.lockScreenCfg.lockScreenPassword,
                    isLockScreenEnabled: response.lockScreenCfg.isLockScreenEnabled,
                    lockScreenUpdateTime: response.lockScreenCfg.lockScreenCfgUpdatedAtMicroSec
                )
            }
            // 都没变化不处理
            guard leanModeChange || lockScreenChange else { return }
            
            self.statusAndAuthorityRelay.accept((newStatusAndAuthority, .pull))
            LeanModeStatusAndAuthority.saveToUserDefaults(statusAndAuthority: newStatusAndAuthority,
                                                          store: self.userStore)
            RustLeanModeAPI.logger.info("LeanMode: pull statusAndAuthority",
                                        additionalData: ["statusAndAuthority": "\(newStatusAndAuthority)"])
        }, onError: { (error) in
            RustLeanModeAPI.logger.error("LeanMode: pull statusAndAuthority error", error: error)
        })
    }
    
    func patchLeanModeStatus(on: Bool) -> Observable<PatchLeanModeStatusResponse> {
        var request = PatchLeanModeStatusRequest()
        request.isDeviceStatus = on
        request.isAllDevice = true // 开启和关闭都全设备同步
        return client.sendAsyncRequest(request).do(onNext: {[weak self] (status) in
            guard let `self` = self else { return }

            var statusAndAuthority = self.currentLeanModeStatusAndAuthority
            guard statusAndAuthority.check(leanModeUpdateTime: status.leanModeCfg.leanModeCfgUpdatedAtMicroSec) else {
                RustLeanModeAPI.logger.info("LeanMode: patchLeanModeStatus updateTime less",
                                            additionalData: ["updateStatus": "\(status)"])
                return
            }
            statusAndAuthority = statusAndAuthority.updateLeanModeConfig(
                deviceHaveAuthority: status.leanModeCfg.deviceHaveAuthority,
                allDevicesInLeanMode: status.leanModeCfg.allDevicesInLeanMode,
                canUseLeanMode: status.leanModeCfg.canUseLeanMode,
                leanModeUpdateTime: status.leanModeCfg.leanModeCfgUpdatedAtMicroSec
            )
            self.statusAndAuthorityRelay.accept((statusAndAuthority, .pull))
            LeanModeStatusAndAuthority.saveToUserDefaults(statusAndAuthority: statusAndAuthority,
                                                          store: self.userStore)
        })
    }
    
    func updateLeanModeStatusAndAuthority(statusAndAuthority: LeanModeStatusAndAuthority, scene: LeanModeDataScene) {
        var newStatusAndAuthority = self.currentLeanModeStatusAndAuthority
        
        let leanModeChange = newStatusAndAuthority.check(leanModeUpdateTime: statusAndAuthority.leanModeUpdateTime)
        if leanModeChange {
            newStatusAndAuthority = newStatusAndAuthority.updateLeanModeConfig(
                deviceHaveAuthority: statusAndAuthority.deviceHaveAuthority,
                allDevicesInLeanMode: statusAndAuthority.allDevicesInLeanMode,
                canUseLeanMode: statusAndAuthority.canUseLeanMode,
                leanModeUpdateTime: statusAndAuthority.leanModeUpdateTime
            )
        }
        
        let lockScreenChange = newStatusAndAuthority.check(lockScreenUpdateTime: statusAndAuthority.lockScreenUpdateTime)
        if lockScreenChange {
            newStatusAndAuthority = newStatusAndAuthority.updateLockScreenConfig(
                lockScreenPassword: statusAndAuthority.lockScreenPassword,
                isLockScreenEnabled: statusAndAuthority.isLockScreenEnabled,
                lockScreenUpdateTime: statusAndAuthority.lockScreenUpdateTime
            )
        }
        // 都没变化不处理
        guard leanModeChange || lockScreenChange else { return }
        
        statusAndAuthorityRelay.accept((newStatusAndAuthority, scene))
        LeanModeStatusAndAuthority.saveToUserDefaults(statusAndAuthority: newStatusAndAuthority, store: userStore)
        RustLeanModeAPI.logger.info("LeanMode: push statusAndAuthority",
                                    additionalData: ["statusAndAuthority": "\(newStatusAndAuthority)"])
    }
    
    func updateOfflineSwitchFailedStatus() {
        offlineSwitchFailedSubject.onNext(())
        RustLeanModeAPI.logger.info("LeanMode: updateOfflineSwitchFailedStatus")
    }
    
    func updateDataCleanObservable(message: PushCleanDataResponse) {
        dataCleanSubject.onNext(message)
        RustLeanModeAPI.logger.info("LeanMode: updateDataCleanObservable")
    }
    
    func patchLockScreenConfig(password: String?, isEnabled: Bool?) -> Observable<PatchLockScreenCfgResponse> {
        var request = PatchLockScreenCfgRequest()
        if let password = password {
            request.lockScreenPassword = password
        }
        if let isEnabled = isEnabled {
            request.isLockScreenEnabled = isEnabled
        }

        return client.sendAsyncRequest(request).do(onNext: { [weak self] (response) in
            guard let `self` = self else { return }

            var statusAndAuthority = self.currentLeanModeStatusAndAuthority
            guard statusAndAuthority.check(lockScreenUpdateTime: response.lockScreenCfg.lockScreenCfgUpdatedAtMicroSec) else {
                RustLeanModeAPI.logger.info("LeanMode: patchLockScreen updateTime less",
                                            additionalData: ["updateStatus": "\(response)"])
                return
            }
            statusAndAuthority = statusAndAuthority.updateLockScreenConfig(
                lockScreenPassword: response.lockScreenCfg.lockScreenPassword,
                isLockScreenEnabled: response.lockScreenCfg.isLockScreenEnabled,
                lockScreenUpdateTime: response.lockScreenCfg.lockScreenCfgUpdatedAtMicroSec
            )
            self.statusAndAuthorityRelay.accept((statusAndAuthority, .pull))
            LeanModeStatusAndAuthority.saveToUserDefaults(statusAndAuthority: statusAndAuthority,
                                                          store: self.userStore)
        })
    }
}

extension String {
    var doubleValue: Double {
        return (self as NSString).doubleValue
    }
}
