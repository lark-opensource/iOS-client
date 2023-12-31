//
//  LarkRustClient.swift
//  LarkAccount
//
//  Created by liuwanlin on 2018/11/23.
//

import UIKit
import Foundation
import RustPB
import LKCommonsLogging
import LarkAccountInterface
import LarkUIKit
import CoreTelephony
import RxSwift
import LarkFoundation
import Reachability
import AppContainer
import LarkReleaseConfig
import LarkEnv
import LarkPerf
import LarkRustClient
import LarkAppConfig
import LarkLocalizations
import EEAtomic
import ByteWebImage
import LKCommonsTracker
import LarkTracker
import LarkContainer
import LarkSetting
import LarkTTNetInitializor
import BootManager

// swiftlint:disable file_length
final class LarkRustClient: LarkRustService, RustClientHook {
    var unwrapped: RustService { return self.client }
    public func safeUnwrapped(userID: String) throws -> RustService {
        lock.lock(); defer { lock.unlock() }
        if let rustService = _rustServices[userID]?.client {
            return rustService
        }
        throw UserScopeError.invalidUserID
    }

    /* 埋点过滤用 */
    typealias TrackConvertRequest = RustPB.Tool_V1_TrackConvertRequest
    typealias TrackConvertResponse = RustPB.Tool_V1_TrackConvertResponse
    typealias TrackConvertStatus = RustPB.Tool_V1_TrackConvertResponse.StatusCode
    /* 配置拉取用 */
    typealias SettingsRequest = RustPB.Settings_V1_GetSettingsRequest
    typealias SettingsResponse = RustPB.Settings_V1_GetSettingsResponse
    /* 配置获取所需字段 */
    private let ETConfig = "et_config"

    static let logger = Logger.log(LarkRustClient.self, category: "LarkAccount.LarkRustClient")

    enum FlowType {
        case unknown
        case singleUser
        case multiUser
    }
    private func assertFlowType(_ flowType: FlowType, line: UInt = #line) {
        if flowType == self.flowType {
            return
        }
        if self.flowType == .unknown {
            LarkRustClient.logger.info("first flowType \(flowType) called at \(line)")
            self.flowType = flowType
        } else {
            preconditionAlpha(false, "unexpected call. already called by flow \(self.flowType)")
        }
    }
    private var flowType = FlowType.unknown

    fileprivate class RustClientState {
        init(client: RustClient) {
            self.client = client
        }

        let client: RustClient
        // 初始化的PushBarrier，登录初始化结束后释放
        var rustServicePushBarrierExit: (() -> Void)? {
            didSet {
                if let oldValue = oldValue {
                    oldValue()
                }
            }
        }
        /// 需要等rustOnline和端上online都结束才能释放栅栏。rust结束才有containerID用于验证push
        func checkPushBarrierFinish(newValue: UInt) {
            // loginFinish && !waitOnline
            if newValue == 0x2 { rustServicePushBarrierExit = nil }
        }
        var onlineState: AtomicUIntCell = .init(0)
        var waitOnline: Bool {
            get { (onlineState.value & 0x1) == 0x1 }
            set {
                if newValue {
                    onlineState.or(0x1)
                } else {
                    let old = onlineState.and(~0x1)
                    checkPushBarrierFinish(newValue: old & ~0x1)
                }
            }
        }
        var loginFinish: Bool {
            get { (onlineState.value & 0x2) == 0x2 }
            set {
                if newValue {
                    let old = onlineState.or(0x2)
                    checkPushBarrierFinish(newValue: old | 0x2)
                } else { onlineState.and(~0x2) }
            }
        }

        let bag = DisposeBag()

        deinit {
            /// 多用户时，client的生命周期和管理者的持有生命周期一致. 其他地方不再调用dispose
            if MultiUserActivitySwitch.enableMultipleUser {
                client.dispose()
            }
            // ensure didSet called..
            {
                rustServicePushBarrierExit = nil
            }()
            onlineState.deallocate()
        }
    }
    // 用于保护加_的私有变量的安全
    private let lock = UnfairLockCell()
    private var _currentUserID: String = UserStorageManager.placeholderUserID // 当前用户ID {
    {
        didSet {
            if !MultiUserActivitySwitch.enableMultipleUser {
                UserTask.shared.offline(userID: oldValue)
            }
        }
    }
    // 支持多用户同时登录。currentUserID记录前台用户，兼容旧的调用..
    // 这是端上使用到的rustService，生命周期被端上切换控制
    private var _rustServices: [String: RustClientState] = [:]
    // 内部和rust通信的state，生命周期被rust控制. 内部使用状态。不被外部获取到。
    // 主要和端上使用的做区分, 切换状态时，端上的生命周期和rust之间会有重叠.
    private var _rustState: [String: RustClientState] = [:]

    // 前台RustClient. 没userID的情况也会有占位的兜底client
    private var foregroundState: RustClientState {
        lock.lock(); defer { lock.unlock() }
        return _rustServices[_currentUserID] ?? _placeholdRustService()
    }
    private var client: RustService { foregroundState.client }
    private var disposeBag: DisposeBag { foregroundState.bag }

    @Injected private var globalClient: GlobalRustService // global

    typealias RustServiceProvider = (_ userId: String?) -> RustClient
    private let rustServiceProvider: RustServiceProvider
    private let env: Env
    func deviceInfoProvider() -> DeviceInfo {
        @Injected var deviceService: DeviceService
        return deviceService.deviceInfo
    }
    func deviceIdValidator(_ id: String) -> Bool { DeviceInfo.isDeviceIDValid(id) }
    /// NOTE: 全局device信息后续会和用户device信息分开。全局的需要保证在登录前设置上. Online请求后就不管, 旧流程先不管
    let deviceReady = DispatchGroup()
    var lastDeviceInfo: DeviceInfoTuple? // did, iid

    /// foregroundUser的disposeBag
    private let reach = Reachability()

    /// 连续设置网络状态时先调用的可能后收到，添加一个递增序列表示调用顺序，丢弃比当前更小的值。
    private let invokeOrder = AtomicUInt()
    init(localeIdentifier: String, rustServiceProvider: @escaping RustServiceProvider) {
        self.rustServiceProvider = { rustServiceProvider($0 == UserStorageManager.placeholderUserID ? nil : $0) }
        self.env = EnvManager.env

        self.updateRustService(userId: nil)
        // init set deviceInfo, rust metrics & log need deviceId to upload
        // 登录前，保证有同步全局设备ID变更。未来设备不会再跟着用户登录走
        if MultiUserActivitySwitch.enableMultipleUser {
            @Injected var deviceService: DeviceService
            _ = deviceService.deviceInfoObservable
            .startWith(deviceService.deviceInfo)
            .subscribe(onNext: { [weak self] info in
                if let self, let info,
                   lock.withLocking(action: { self._currentUserID == UserStorageManager.placeholderUserID }) {
                    self.updateDeviceInfo(deviceInfo: (info.deviceId, info.installId), validate: true, completion: nil)
                }})
        } else {
            self.updateDeviceInfo(validate: true)
        }
    }
    deinit {
        lock.deallocate()
    }

    /// Return true for clear db.
    public func reset(
        with userId: String,
        tenantID: String,
        tenantTag: TenantTag,
        accessToken: String,
        logoutToken: String?,
        isLightlyActive: Bool,
        isFastLogin: Bool,
        isGuest: Bool,
        avatarPath: String,
        leanModeInfo: LeanModeInfo?
    ) {
        assertFlowType(.singleUser)

        self.updateRustService(userId: userId)
        if !isFastLogin {
            self.updateDeviceInfo(validate: false)
        }

        let id2 = TimeLogger.shared.logBegin(eventName: "SetAccessToken")
        self.makeUserOnline(
            userId: userId,
            tenantID: tenantID,
            tenantTag: tenantTag,
            accessToken: accessToken,
            logoutToken: logoutToken,
            isLightlyActive: isLightlyActive,
            isGuest: isGuest,
            avatarPath: avatarPath,
            leanModeInfo: leanModeInfo
        )
        TimeLogger.shared.logEnd(identityObject: id2, eventName: "SetAccessToken")
        self.setIdcFlowControlValue(client: self.client)

        self.observeAppLifeCycle()
        self.observeNetwork()
    }

    // 新逻辑，灰度完成后删除上面的
    public func reset(
        with userId: String,
        tenantID: String,
        tenantTag: TenantTag,
        accessToken: String,
        logoutToken: String?,
        isLightlyActive: Bool,
        isGuest: Bool,
        avatarPath: String,
        leanModeInfo: LeanModeInfo?,
        completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        assertFlowType(.singleUser)

        self.updateRustService(userId: userId)

        let id2 = TimeLogger.shared.logBegin(eventName: "SetAccessToken")
        self.makeUserOnline(
            userId: userId,
            tenantID: tenantID,
            tenantTag: tenantTag,
            accessToken: accessToken,
            logoutToken: logoutToken,
            isLightlyActive: isLightlyActive,
            isGuest: isGuest,
            avatarPath: avatarPath,
            leanModeInfo: leanModeInfo,
            completionHandler: completionHandler
        )
        TimeLogger.shared.logEnd(identityObject: id2, eventName: "SetAccessToken")
        self.setIdcFlowControlValue(client: self.client)

        self.observeAppLifeCycle()
        self.observeNetwork()
    }

    /// update deviceInfo to rust
    private func updateDeviceInfo(validate: Bool) {
        let deviceInfo = self.deviceInfoProvider()
        let id = TimeLogger.shared.logBegin(eventName: "Init Client")
        _update(deviceInfo: (deviceInfo.deviceId, deviceInfo.installId), validate: validate)
        TimeLogger.shared.logEnd(identityObject: id, eventName: "Init Client")
    }
    private func _update(deviceInfo: DeviceInfoTuple, validate: Bool,
                         completion: ((Result<Void, Error>) -> Void)? = nil) {
        if !validate || self.deviceIdValidator(deviceInfo.deviceId) {
            self.setDeviceInfo(deviceInfo, completion: completion)
        } else {
            LarkRustClient.logger.error(
                "update invalid deviceId:\(deviceInfo.deviceId) installId: \(deviceInfo.installId)"
            )
        }
    }

    /// Send sync SetDeviceRequest
    private func setDeviceInfo(_ deviceInfo: DeviceInfoTuple, completion: ((Result<Void, Error>) -> Void)? ) {
        var request = RustPB.Device_V1_SetDeviceRequest()
        // TNC need specifical devicePlatform and appName.
        // https://bytedance.feishu.cn/docs/doccnwt9lOhqwtU0XsU0vNpJA5c#
        request.appName = Utils.appName
        request.devicePlatform = Display.pad ? "iPad" : "iPhone"
        request.deviceID = deviceInfo.deviceId
        request.installID = deviceInfo.installId
        let osVersion = UIDevice.current.systemVersion
        let deviceType = LarkFoundation.Utils.machineType
        request.osVersion = osVersion
        request.deviceType = deviceType
        request.settingsQueries = ["device_model": deviceType]
        if let alchemyProjectID = Bundle.main.infoDictionary?["ALCHEMY_PROJECT_ID"] as? String,
           !alchemyProjectID.isEmpty {
            request.settingsQueries["alchemy_project_id"] = alchemyProjectID
        }
        LarkRustClient.logger.info(
            """
            Async Barrier SetDeviceRequest deviceId: \(deviceInfo.deviceId), \
            installId: \(deviceInfo.installId), \
            osVersion: \(osVersion), \
            deviceType: \(deviceType).
            """
            )
        var packet = RequestPacket(message: request)
        deviceReady.enter()
        let client: RustService
        // 旧流程需要packet的barrier属性. 新流程通过deviceReady来控制
        if MultiUserActivitySwitch.enableMultipleUser {
            client = globalClient
        } else {
            client = self.client
            packet.barrier = true
        }

        client.async(packet) { response in
            self.deviceReady.leave()
            defer { completion?(response.result) }
            switch response.result {
            case .failure(let error):
                LarkRustClient.logger.error(
                    "Set DeviceInfo error",
                    additionalData: [
                        "deviceId": deviceInfo.deviceId,
                        "installId": deviceInfo.installId,
                        "osVersion": osVersion,
                        "deviceType": deviceType
                    ],
                    error: error
                )
            default: break
            }
        }
    }

    private func updateDeviceInfo(deviceInfo: DeviceInfoTuple, validate: Bool,
                                  completion: ((Result<Void, Error>) -> Void)?) {
        assertFlowType(.multiUser)
        lock.lock()
        if let lastDeviceInfo, deviceInfo == lastDeviceInfo {
            LarkRustClient.logger.info("ignore same device info: \(deviceInfo)")
            lock.unlock()
            completion?(.success(()))
            return
        }
        lastDeviceInfo = deviceInfo
        lock.unlock()
        _update(deviceInfo: deviceInfo, validate: validate, completion: completion)
    }

    public func setDeviceInfoV2(did: String, iid: String, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        updateDeviceInfo(deviceInfo: (did, iid), validate: false, completion: completionHandler)
    }

    public func setDeviceInfo(did: String, iid: String, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        if MultiUserActivitySwitch.enableMultipleUser {
            return setDeviceInfoV2(did: did, iid: iid, completionHandler: completionHandler)
        }
        assertFlowType(.singleUser)
        var request = RustPB.Device_V1_SetDeviceRequest()
        // TNC need specifical devicePlatform and appName.
        // https://bytedance.feishu.cn/docs/doccnwt9lOhqwtU0XsU0vNpJA5c#
        request.appName = Utils.appName
        request.devicePlatform = Display.pad ? "iPad" : "iPhone"
        request.deviceID = did
        request.installID = iid
        let osVersion = UIDevice.current.systemVersion
        let deviceType = LarkFoundation.Utils.machineType
        request.osVersion = osVersion
        request.deviceType = deviceType
        request.settingsQueries = ["device_model": deviceType]
        LarkRustClient.logger.info(
            """
            v2 Async Barrier SetDeviceRequest deviceId: \(did), \
            installId: \(iid), \
            osVersion: \(osVersion), \
            deviceType: \(deviceType).
            """
            )
        client.sendAsyncRequestBarrier(request).subscribe(onNext: { _ in
            LarkRustClient.logger.info("v2 Set DeviceInfo succ")
            completionHandler(.success(()))
        }, onError: { (error) in
            LarkRustClient.logger.error(
                "v2 Set DeviceInfo error",
                additionalData: [
                    "deviceId": did,
                    "installId": iid,
                    "osVersion": osVersion,
                    "deviceType": deviceType
                ],
                error: error
            )
            completionHandler(.failure(error))
        }).disposed(by: self.disposeBag)
    }

    public func setEnv(_ env: Basic_V1_InitSDKRequest.EnvV2, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        assertFlowType(.singleUser)
        var request = RustPB.Basic_V1_SetEnvRequest()
        request.envType = .online /// 3.27.0起，无用字段
        request.envV2 = env
        request.syncDataStrategy = .tryLocal
        return client
            .sendAsyncRequestBarrier(request)
            .subscribe(onNext: { _ in
                completionHandler(.success(()))
            }, onError: { error in
                completionHandler(.failure(error))
            }).disposed(by: disposeBag)
    }

    /// PreRelease 环境设置 idc flow control value 用来切换机房
    private func setIdcFlowControlValue(client: RustService) {
        if env.type != .preRelease {
            return
        }

        let idcFlowControlValue = PassportDebugEnv.idcFlowControlValue
        if !idcFlowControlValue.isEmpty {
            var request = RustPB.Basic_V1_SetIdcFlowControlValueRequest()
            request.value = idcFlowControlValue
            do {
                let res: SetIdcFlowControlValueResponse = try client.sendSyncRequest(request)
                LarkRustClient.logger.debug(
                    "set idc flow control value successfully",
                    additionalData: ["value": res.value]
                )
            } catch {
                LarkRustClient.logger.error(
                    "Set idc flow control value failed",
                    additionalData: ["value": idcFlowControlValue],
                    error: error
                )
            }
        } else {
            LarkRustClient.logger.info("idc flow control value is empty")
        }
    }

    private func makeUserOnline(
        userId: String,
        tenantID: String,
        tenantTag: TenantTag,
        accessToken: String,
        logoutToken: String?,
        isLightlyActive: Bool,
        isGuest: Bool,
        avatarPath: String,
        leanModeInfo: LeanModeInfo?,
        completionHandler: ((Result<Void, Error>) -> Void)? = nil
    ) {
        // 图片请求必须在makeUserOnline以后，否则请求图片会失败
        LarkImageService.shared.pauseImageRequest()

        AppStartupMonitor.shared.start(key: .ttnetInitialize)
        setupTTNetInitializor(accessToken: accessToken, tenantID: tenantID, userID: userId)
        AppStartupMonitor.shared.end(key: .ttnetInitialize)

        let timeStart = CACurrentMediaTime()
        var request = RustPB.Tool_V1_MakeUserOnlineRequest()
        // 这里和rust同学meepo确认过之前的UserId设定为String只是为了兼容js场景，底层一直采用Int作为存储
        guard let userIdAsInt = Int64(userId) else {
            LarkRustClient.logger.error(
                "make user online failed. no valid userId as Int",
                additionalData: ["userId": userId]
            )
            return
        }
        request.userID = userIdAsInt
        if let tenantID = Int64(tenantID) {
            request.tenantID = tenantID
        }
        request.localeIdentifier = LanguageManager.currentLanguage.localeIdentifier
        request.accessToken = accessToken
        request.enableBackgroundMode = true
        request.clientAvatarPath = avatarPath
        if isGuest {
            request.guestUserExtraInfo = Tool_V1_MakeUserOnlineRequest.GuestUserExtraInfo()
        } else {
            var extraInfo = Tool_V1_MakeUserOnlineRequest.NamedUserExtraInfo()
            switch tenantTag {
            case .standard:
                extraInfo.tenantTag = .standard
            case .simple:
                extraInfo.tenantTag = .simple
            case .undefined, .unknown: fallthrough
            @unknown default:
                extraInfo.tenantTag = .undefined
            }
            request.namedUserExtraInfo = extraInfo
        }
        // lean mode
        if let leanModeInfo = leanModeInfo {
            request.leanModeConfig = from(leanModeInfo: leanModeInfo)
        }

        let req: Observable<ContextResponse<Tool_V1_MakeUserOnlineResponse>>
        req = self.client.sendAsyncRequestBarrier(request)
        LarkRustClient.logger.info("makeUserOnline", additionalData: [
            "userId": "\(userId)",
            "accessTokenIsEmpty": "\(accessToken.isEmpty)",
            "isLightlyActive": "\(isLightlyActive)",
            "isGuest": "\(isGuest)",
            "avatarPath": avatarPath
        ])
        req.map({ (response) -> Tool_V1_MakeUserOnlineResponse in
            return response.response
        })
        .subscribe(onNext: { (response) in
            // makeUserOnline以后，恢复图片请求
            LarkImageService.shared.resumeImageRequest()
            ColdStartup.shared?.doForRust(.stateReciableSetAccessToken, (CACurrentMediaTime() - timeStart) * 1_000)
            ColdStartup.shared?.doForRust(.stateReciableInit, RustClient.rustInitCost)
            // if response.isClearDb {
            //     LarkRustClient.logger.warn("RustSDK has cleared database")
            // }
            if response.hasDomainSettings {
                DomainSettingManager.shared.updateUserDomainSettings(
                    with: userId,
                    new: DomainSettingManager.toDomainSettings(domains: response.domainSettings)
                )
            }
            completionHandler?(.success(()))
        }, onError: { (error) in
            //                assertionFailure("Sync SetAccessToken should not failed, plz contact RustSDK team.")
            LarkImageService.shared.resumeImageRequest()
            LarkRustClient.logger.error(
                "make user online failed.",
                additionalData: ["userId": userId],
                error: error
            )

            completionHandler?(.failure(error))

        }, onCompleted: {
            LarkImageService.shared.resumeImageRequest()
        }).disposed(by: self.disposeBag)
    }

    public func makeUserOffline(completionHandler: @escaping (Result<Void, Error>) -> Void) {
        assertFlowType(.singleUser)
        LarkRustClient.logger.info("make user offline")
        let offlineRequest = RustPB.Tool_V1_MakeUserOfflineRequest()
        self.client.sendAsyncRequestBarrier(offlineRequest)
            .subscribe { _ in
                LarkRustClient.logger.info("make user offline succ")
                completionHandler(.success(()))
            } onError: { error in
                LarkRustClient.logger.error("make user offline fail", error: error)
                completionHandler(.failure(error))
            }.disposed(by: self.disposeBag)
    }

    private func setupTTNetInitializor(accessToken: String, tenantID: String, userID: String) {
        // TODO: TTNet多用户改造
        let domainSetting = DomainSettingManager.shared.currentSetting
        TTNetInitializor.initialWithLarkUserInfo(
            session: accessToken,
            deviceID: self.deviceInfoProvider().deviceId,
            tenantID: tenantID,
            uuid: Encrypto.encryptoId(userID),
            envType: convert(env: EnvManager.env.type),
            envUnit: EnvManager.env.unit,
            tncDomains: domainSetting[.ttnetTNC] ?? [],
            httpDNS: domainSetting[.ttnetHttpDNS] ?? [],
            netlogDomain: domainSetting[.ttnetNetLog] ?? []
        )
    }

    /// Notify SDK the network state, async
    private func setClientNetworkType(networkType: RustPB.Basic_V1_SetClientStatusRequest.NetType? = nil) {
        var request = RustPB.Basic_V1_SetClientStatusRequest()
        request.invokeOrder = UInt32(self.invokeOrder.increment())
        request.netType = networkType ?? self.fetchNetworType()
        self.client.sendAsyncRequest(request)
            .subscribe(onError: { (error) in
                LarkRustClient.logger.error(
                    "网络类型设置失败",
                    additionalData: ["netType": "\(request.netType)"],
                    error: error
                )
            })
            .disposed(by: disposeBag)
    }

    private func fetchNetworType() -> RustPB.Basic_V1_SetClientStatusRequest.NetType {
        var networkType: RustPB.Basic_V1_SetClientStatusRequest.NetType
        switch self.reach?.connection ?? .none {
        case .none: networkType = .offline
        case .wifi: networkType = .onlineWifi
        case .cellular:
            switch CTTelephonyNetworkInfo.lu.shared.lu.currentSpecificStatus {
            case .📶2G: networkType = .online2G
            case .📶3G: networkType = .online3G
            case .📶4G: networkType = .online4G
            default: networkType = .online4G
            }
        @unknown default:
            assert(false, "new value")
            networkType = .offline
        }
        return networkType
    }

    var hasObserveNetwork = false
    private func observeNetwork() {
        if hasObserveNetwork { return }
        hasObserveNetwork = true
        reach?.whenReachable = { [weak self] _ in
            self?.setClientNetworkType()
        }
        reach?.whenUnreachable = { [weak self] _ in
            self?.setClientNetworkType(networkType: .offline)
        }

        do {
            try reach?.startNotifier()
        } catch {
            LarkRustClient.logger.error("StartNotifier error", error: error)
        }
    }

    var hasObserveAppLifeCycle = false
    private func observeAppLifeCycle() {
        if hasObserveAppLifeCycle { return }
        hasObserveAppLifeCycle = true

        _ = NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.noticeAppLifeCycle(event: .enterBackground)
            })

        _ = NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.noticeAppLifeCycle(event: .enterForeground)
            })

        _ = NotificationCenter.default.rx
            .notification(UIApplication.didReceiveMemoryWarningNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.noticeAppLifeCycle(event: .memoryWarning)
            })

        _ = NotificationCenter.default.rx
            .notification(UIApplication.willTerminateNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.noticeAppLifeCycle(event: .terminating)
            })

        DispatchQueue.main.async {
            if UIApplication.shared.applicationState == .background {
                // RustSDK 内部初始状态是 foreground, APP 后台启动时需要做同步
                self.noticeAppLifeCycle(event: .enterBackground)
            }
        }
    }

    private let sendQueue: DispatchQueue = DispatchQueue(label: "lk.noticeAppLifeCycle", qos: .userInteractive)
    /// Notify SDK the App LifeCycle
    private func noticeAppLifeCycle(event: NoticeClientEventRequest.Event) {
        // 同一个队列，保证同步请求的时序性
        self.sendQueue.async {
            var request = NoticeClientEventRequest()
            request.event = event
            do {
                try self.globalClient.sendSyncRequest(request)
            } catch {
                LarkRustClient.logger.error(
                    "Notice App LifeCycle error",
                    additionalData: ["event": "\(event.rawValue)"],
                    error: error
                )
            }
        }
    }

    static func pushAllowCmds(cmd: CMD) -> Bool {
        // FIXME: 白名单没被栅栏拦截，分发时机可能过早而取不到userResolver而失败..
        switch cmd {
        case .rust(let cmd):
            return cmd == .pushLoadFeedCardsStatus
        default: break
        }
        return false
    }

    /// 更新当前用户的接口
    func updateRustService(userId: String?) {
        guard let userId else {
            lock.lock(); defer { lock.unlock() }
            _rustServices.removeValue(forKey: self._currentUserID)
            _currentUserID = UserStorageManager.placeholderUserID
            return
        }
        // get before lock, lazy resolve in lock may cause deadlock
        let newService = rustServiceProvider(userId)
        let state = RustClientState(client: newService)

        lock.lock(); defer { lock.unlock() }
        self._rustServices.removeValue(forKey: self._currentUserID)
        self._currentUserID = userId
        self._rustServices[userId] = state
        _configService(userID: userId, foreground: true, state: state)
    }
    private func _placeholdRustService() -> RustClientState {
        // lazy created placeholder state
        #if ALPHA
        lock.assertOwner()
        preconditionAlpha(_currentUserID == UserStorageManager.placeholderUserID,
                          "should be called only for empty user")
        #endif
        let newService = rustServiceProvider(nil)
        let state = RustClientState(client: newService)
        _rustServices[_currentUserID] = state
        LarkRustClient.logger.info("create lazy rust service for \(_currentUserID)")
        return state
    }

    public func loginFinish(userID: String) {
        var foreground = false
        lock.withLocking {
            _rustServices[userID]?.loginFinish = true
            foreground = userID == _currentUserID
        }
        if foreground {
            self.mainThreadTimedout = !FeatureGatingManager.shared
            .featureGatingValue(with: "mainThreadTimedoutDisabled")
            if !MultiUserActivitySwitch.enableMultipleUser {
                MultiUserActivitySwitch.Observer.shared.observeEnableFG()
            }
        }
        UserTask.shared.online(userID: userID)
    }
    static fileprivate func registerSharedUserPush(on state: RustClientState, userID: String, foreground: Bool) {
        // NOTE: 这里已经在lock里了，使用static避免引用状态导致死循环

        // FIXME: 这里注册的factory需要能够获取到用户容器.., 还要考虑自己切自己的情况..
        // 现在是用的userID，但最好是能够提前创建容器保证正确性
        // 在容器创建前如果有push过来的话，会收不到。虽然大部分push现在有拦截保证初始化后统一调用..
        let getUserResolver = { (compatibleModeGetter: () -> Bool) in
            // 获取storage不用兼容模式，如果没有当前user的storage，直接抛错给RustService
            let storage = try UserStorageManager.shared.getStorage(userID: userID, type: foreground ? .foreground : .background)
            return Container.shared.getUserResolver(storage: storage, compatibleMode: compatibleModeGetter())
        }
        #if ALPHA || DEBUG
        RustPushHandlerRegistry.frozen = true
        #endif

        var serverCommands = Set<Int32>()
        let disposeBag = state.bag
        let service = state.client
        service.barrier(id: "register push") {
            if foreground {
                for i in PushHandlerRegistry.shared.getPushHandlers() {
                    service.registerPushHandler(factories: i).disposed(by: disposeBag)
                }
                for (_, register) in RustPushHandlerRegistry.rustUserPushHandlers {
                    register(service, getUserResolver).disposed(by: disposeBag)
                }

                for i in ServerPushHandlerRegistry.shared.getPushHandlers() {
                    serverCommands.formUnion(i.keys.map { Int32($0.rawValue) })
                    service.registerPushHandler(factories: i).disposed(by: disposeBag)
                }
                for (cmd, register) in ServerPushHandlerRegistry.serverUserPushHandlers {
                    serverCommands.insert(Int32(cmd.rawValue))
                    register(service, getUserResolver).disposed(by: disposeBag)
                }
            } else {
                for (_, register) in RustPushHandlerRegistry.rustBackgroundUserPushHandlers {
                    register(service, getUserResolver).disposed(by: disposeBag)
                }
                for (cmd, register) in ServerPushHandlerRegistry.serverBackgroundUserPushHandlers {
                    serverCommands.insert(Int32(cmd.rawValue))
                    register(service, getUserResolver).disposed(by: disposeBag)
                }
            }

            if !serverCommands.isEmpty {
                var req = Im_V1_SetPassThroughPushCommandsRequest()
                // 看rust的实现, 这个是添加覆盖式的
                req.commands = Array(serverCommands)
                _ = service.sendAsyncRequest(req).subscribe()
            }
        }
    }
    // 前后台都注册了的Command，才可以透传，避免所有command都进行缓存
    // 请求时机应该晚于集成时机，这样获取到的值才正确
    static let bothRegisteredCommands: Set<CMD> = {
        var foreground: Set<CMD> = []
        var background: Set<CMD> = []
        foreground.formUnion(PushHandlerRegistry.shared.getPushHandlers().flatMap { $0.keys.map { .init($0) } })
        foreground.formUnion(RustPushHandlerRegistry.rustUserPushHandlers.map { .init($0.0) })
        foreground.formUnion(ServerPushHandlerRegistry.shared.getPushHandlers().flatMap { $0.keys.map { .init($0) } })
        foreground.formUnion(ServerPushHandlerRegistry.serverUserPushHandlers.map { .init($0.0) })

        background.formUnion(RustPushHandlerRegistry.rustBackgroundUserPushHandlers.map { .init($0.0) })
        background.formUnion(ServerPushHandlerRegistry.serverBackgroundUserPushHandlers.map { .init($0.0) })
        let both = foreground.intersection(background)
        return both
    }()

    // 埋点上报前过滤
    // swiftlint:disable function_body_length
    func trackDataFilter(event: String, params: [String: Any], onSuccess: @escaping (([String: Any]) -> Void)) {
        var request = TrackConvertRequest()
        request.event = event
        request.params = params.mapValues({ (v) -> RustPB.Tool_V1_Value in
            var value = RustPB.Tool_V1_Value()
            switch v {
            case let intVal as Int32:
                value.intValue = intVal
            case let longVal as Int64:
                value.longValue = longVal
            case let doubleVal as Double:
                value.doubleValue = doubleVal
            case let floatVal as Float:
                value.floatValue = floatVal
            case let cgfloatVal as CGFloat:
                value.floatValue = Float(cgfloatVal)
            case let strVal as String:
                value.stringValue = strVal
            default:
                value.value = nil
            }
            return value
        })

        client.sendAsyncRequest(
            request,
            transform: { (response: TrackConvertResponse) -> (TrackConvertStatus, [String: Any]) in
            let newParams = response.params.mapValues({ (v) -> Any? in
                guard let value = v.value else { return nil }
                switch value {
                case .intValue(let int):
                    return int
                case .doubleValue(let double):
                    return double
                case .stringValue(let str):
                    return str
                case .floatValue(let float):
                    return float
                case .longValue(let long):
                    return long
                @unknown default:
                    assert(false, "new value")
                    return nil
                }
            }).compactMapValues { $0 }
            return (response.statusCode, newParams)
        }).subscribe(onNext: { (status, newParams) in
            switch status {
            case .notChanged:
                onSuccess(params)
            case .changed:
                LarkRustClient.logger.info("event track modified: \(event)")
                onSuccess(newParams)
            case .deleted:
                LarkRustClient.logger.warn("event track deleted: \(event)")
            @unknown default:
                assert(false, "new value")
                break
            }
        }, onError: { (error) in
            LarkRustClient.logger.error(
                "event track filter failed",
                error: error
            )
        }).disposed(by: disposeBag)
    }
    // swiftlint:enable function_body_length

    /// 临时的hook能力提供给FG保证时序使用
    func hookSerialize(client: RustClient, userID: String) {
        client.serializeHook = { (message) in
            let name = type(of: message).protoMessageName
            if name == Tool_V1_MakeUserOnlineRequest.protoMessageName, var online = message as? Tool_V1_MakeUserOnlineRequest { // swiftlint:disable:this all
                online.namedUserExtraInfo.usedImmutableFeatureGating = FeatureGatingManager.immutableFeatures(of: userID)
                online.namedUserExtraInfo.clientFgData = Dictionary(uniqueKeysWithValues: FeatureGatingManager
                .mutableFeatures(of: userID)
                .map { ($0, "") })
                FeatureGatingManager.userStateDidChange(isOnline: true, of: userID)
                return online
            }
            if name == Tool_V1_MakeUserOnlineV2Request.protoMessageName, var request = message as? Tool_V1_MakeUserOnlineV2Request {
                request.userExtraInfo.usedImmutableFeatureGating = FeatureGatingManager.immutableFeatures(of: userID)
                request.userExtraInfo.clientFgData = Dictionary(uniqueKeysWithValues: FeatureGatingManager
                    .mutableFeatures(of: userID)
                    .map { ($0, "") })
                FeatureGatingManager.userStateDidChange(isOnline: true, of: userID)
                return request
            }
            if name == Tool_V1_MakeUserOfflineRequest.protoMessageName || name == Tool_V1_MakeUserOfflineV2Request.protoMessageName {
                FeatureGatingManager.userStateDidChange(isOnline: false, of: userID)
            }
            return nil // no deal
        }
    }
    // 获取通用配置，在启动前调用，埋点和日志都需要
    func getConfigSettings(onSuccess: @escaping (([String: String]) -> Void)) {
        var request = SettingsRequest()
        request.fields = [ETConfig]
        client.sendAsyncRequest(request, transform: { (response: SettingsResponse) -> [String: String] in
            return response.fieldGroups
        }).subscribe(onNext: { (groups) in
            onSuccess(groups)
        }, onError: { (error) in
            LarkRustClient.logger.error(
                "拉取配置失败",
                error: error
            )
        }).disposed(by: disposeBag)
    }

    // FIXME: 这个好像可以清理了？, 观察一下是不是始终有初始化回调, 这里应该就不用同步了
    func notifyNetworkStatus() { setClientNetworkType() }

    // MARK: RustClientHook
    var multiUserFlow: Bool { MultiUserActivitySwitch.enableMultipleUser }
    func shouldKeepLive(cmd: CMD) -> Bool {
        LarkRustClient.bothRegisteredCommands.contains(cmd)
    }

    var mainThreadTimedout: Bool = true

    func onInvalidUserID(_ data: RustClient.OnInvalidUserID) {
        func enc(id: UInt64) -> String {
            if id == 0 { return "" }
            return Encrypto.encryptoId(String(id))
        }
        var params: [String: Any] = [
            "scenario": data.scenario,
            "client_user_id": enc(id: data.clientUserID),
            "sdk_user_id": enc(id: data.sdkUserID),
            "context_id": data.contextID,
            "utc_time_stamp": Date().timeIntervalSince1970,
            "is_error": data.hasError ? 1 : 0
        ]
        var extra = [String]()
        if type(of: data).hasBarrier { extra.append("switch") }
        if data.intercepted { extra.append("intercepted") }
        if !extra.isEmpty { params["extra"] = extra.joined(separator: ",") }
        if let cmd = data.command { params["command"] = cmd }
        if let cmd = data.serverCommand { params["server_command"] = cmd }
        Tracker.post(TeaEvent(
            "lark_rust_ffi_userid_check_dev",
            params: params
            ))
        LarkRustClient.logger.warn(
            logId: "rust_onInvalidUserID", """
            [user_id_verification][ios][\(data.scenario)][intercepted: \(data.intercepted)][is_err: \(data.hasError)]\
            (cmd: \(data.command ?? 0), server_cmd: \(data.serverCommand ?? 0), \
            client_user_id: \(data.clientUserID), \
            sdk_user_id: \(data.sdkUserID))
            """, params: ["contextID": data.contextID])
    }

    func onPushBarrierStat(_ data: RustClient.PushBarrierStat) {
        let params: [String: Any] = [
            "barrier": data.barrier,
            "total": data.total,
            "size": data.size,
            "count": data.count,
            "expired": data.expired ? 1 : 0,
            "maxMemory": data.maxMemory
        ]
        Tracker.post(TeaEvent("lark_rust_push_barrier_info_dev", params: params))
    }

    // MARK: New Multiuser lifetime
    public enum LifeCycleError: Error {
    case rust(Error)
    // fatal Error
    case invalidUserID
    case nodestinationID(String) // (user)
    }
    /// 用户登录，没有旧状态
    public func makeUserOnline(
        user: User, foreground: Bool, nowait: Bool,
        priorState: Tool_V1_UserLoginState,
        callback: @escaping (Result<Void, LifeCycleError>) -> Void
    ) {
        assertFlowType(.multiUser)
        preconditionAlpha(priorState == .offline, "priorState should be offline to makeUserOnline")
        AppStartupMonitor.shared.start(key: .rustSDK)
        defer { AppStartupMonitor.shared.end(key: .rustSDK) }

        // 前置数据检查
        let userID = user.userID
        guard let userIdAsInt = UInt64(userID) else {
            LarkRustClient.logger.error(
                "make user online failed. no valid userId as Int",
                additionalData: ["userId": userID]
            )
            preconditionAlpha(false, "online with invalid userID \(userID)")
            callback(.failure(.invalidUserID))
            return
        }
        guard let toUnit = user.userUnit else {
            LarkRustClient.logger.error(
                "make user online failed. no valid user Unit",
                additionalData: ["userId": userID]
            )
            preconditionAlpha(false, "online with empty user unit: \(userID)")
            callback(.failure(.invalidUserID))
            return
        }

        let rustState = self.willOnlineRustService(userID: userID, foreground: foreground)

        // finish必定调用, success成功调用。注意不要重复设置
        var actionsAfterSuccess = [() -> Void]()
        var actionsWhenFinish = [() -> Void]()
        if foreground {
            foregroundUserOnlineSpecial(user: user, state: rustState,
                                        actionsAfterSuccess: &actionsAfterSuccess,
                                        actionsWhenFinish: &actionsWhenFinish)
        }

        var req = Tool_V1_MakeUserOnlineV2Request()
        req.userID = userIdAsInt
        if let tenantID = Int64(user.tenant.tenantID) {
            req.tenantID = tenantID
        }
        req.localeIdentifier = LanguageManager.currentLanguage.localeIdentifier
        req.accessToken = user.sessionKey ?? ""
        req.enableBackgroundMode = true
        @Injected var rustClientDependency: RustClientDependency
        req.clientAvatarPath = rustClientDependency.avatarPath

        // user.extraInfo
        var extraInfo = Tool_V1_NamedUserExtraInfo()
        switch user.tenant.tenantTag {
        case .standard:
            extraInfo.tenantTag = .standard
        case .simple:
            extraInfo.tenantTag = .simple
        case .undefined, .unknown, nil:
            extraInfo.tenantTag = .undefined
        @unknown default:
            extraInfo.tenantTag = .undefined
        }
        req.userExtraInfo = extraInfo
        if let leanMode = user.leanModeInfo {
            req.leanModeConfig = from(leanModeInfo: leanMode)
        }

        var deviceInfo = Tool_V1_UserDeviceInfo()
        @Injected var device: PassportGlobalDeviceService
        if let (did, iid) = device.getDeviceIdAndInstallId(unit: toUnit) {
            deviceInfo.deviceID = did
            deviceInfo.installID = iid
        }
        deviceInfo.appName = Utils.appName
        deviceInfo.devicePlatform = Display.pad ? "iPad" : "iPhone"
        let deviceType = LarkFoundation.Utils.machineType
        deviceInfo.settingsQueries = ["device_model": deviceType]
        if let alchemyProjectID = Bundle.main.infoDictionary?["ALCHEMY_PROJECT_ID"] as? String, !alchemyProjectID.isEmpty {
            deviceInfo.settingsQueries["alchemy_project_id"] = alchemyProjectID
        }
        req.userDeviceInfo = deviceInfo

        let toEnv = Env(unit: toUnit, geo: user.geo, type: EnvManager.env.type)
        var rustEnv = Basic_V1_InitSDKRequest.EnvV2()
        rustEnv.unit = toEnv.unit
        rustEnv.type = toEnv.type.transform()
        rustEnv.brand = user.tenant.tenantBrand.rawValue
        req.envV2 = rustEnv
        // env的response目前看新逻辑没有处理response了。所以这里也不处理回调的数据..

        req.priorUserState = priorState
        req.destinationState = foreground ? .foregroundOnline : .backgroundOnline
        req.settingsFields = SettingKeyCollector.shared.getSettingKeysUsed(id: userID)

        LarkRustClient.logger.info("makeUserOnline", additionalData: [
            "userId": "\(req.userID)",
            "accessTokenIsEmpty": "\(req.accessToken.isEmpty)",
            "isLightlyActive": "\(NewBootManager.shared.context.isLightlyActive)",
            "avatarPath": req.clientAvatarPath
        ])
        // waiting时不等rust结果，但需要保证rustService的正常创建和拦截。
        // 主要是fastLogin场景不等rust

        // online需要在设备通知ready后。设置通知应该在之前发送过了，不过不一定结束了
        if nowait {
            // 另外也要加栅栏保证业务调用在online后
            rustState.client.barrier(id: "Wait deviceID") { _ = self.deviceReady.wait(timeout: .now() + 10) }
            _run(callback: { _ in })
            LarkRustClient.logger.info("nowait callback")
            callback(.success(()))
        } else {
            deviceReady.notify(queue: .global(qos: .userInitiated)) { _run(callback: callback) }
        }
        func _run(callback: @escaping (Result<Void, LifeCycleError>) -> Void) {
            var packet = RequestPacket(message: req)
            packet.barrier = true
            rustState.client.async(packet) { (packet: ResponsePacket<Tool_V1_MakeUserOnlineV2Response>) in
                do {
                    let response = try packet.result.get()
                    rustState.client.rustContainerID = (response.destinationContainerID, response.userContainerID)
                    rustState.waitOnline = false
                    rustState.client.onRustContainerSet()
                    LarkRustClient.logger.info("makeUserOnline Success", additionalData: [
                        "userId": userID,
                        "clientIdentifier": rustState.client.identifier,
                        "destinationID": response.destinationContainerID.description,
                        "userContainerID": response.userContainerID.description
                    ])

                    actionsAfterSuccess.reversed().forEach { $0() }
                    actionsWhenFinish.reversed().forEach { $0() }

                    // if response.isClearDb {
                    //     LarkRustClient.logger.warn("RustSDK has cleared database")
                    // }
                    if response.hasDomainSettings {
                        DomainSettingManager.shared.updateUserDomainSettings(
                            with: userID,
                            new: DomainSettingManager.toDomainSettings(domains: response.domainSettings)
                        )
                    }
                    if !response.settings.isEmpty {
                        let isSyncUpdated = response.onlineScenario != .normal
                        if let globalSettingService = try? Container.shared.resolve(type: GlobalSettingService.self) {
                            globalSettingService.settingUpdate(
                                settings: response.settings,
                                id: userID,
                                sync: isSyncUpdated
                            )
                        }
                    }
                    FeatureGatingSyncEventCollector.shared.syncResult(userID, true)
                    callback(.success(()))
                } catch {
                    rustState.waitOnline = false
                    actionsWhenFinish.reversed().forEach { $0() }

                    LarkRustClient.logger.error("make user online failed.",
                                                additionalData: ["userId": userID],
                                                error: error)
                    FeatureGatingSyncEventCollector.shared.syncResult(userID, false)
                    callback(.failure(.rust(error)))
                }
            }
        }
    }

    /// 用户登出, 清理当前状态
    public func makeUserOffline(
        userID: String,
        priorState: Tool_V1_UserLoginState,
        forceOffline: Bool = false, // 错误兜底, 强制对齐offline状态
        callback: @escaping (Result<Void, LifeCycleError>) -> Void
    ) {
        assertFlowType(.multiUser)
        LarkRustClient.logger.info("make user offline", additionalData: ["userId": userID])
        // 可能会有强制offline，所以priorState会有所有的情况
        preconditionAlpha(forceOffline || priorState != .offline,
                          "already offline, shouldn't call multiple times")

        // 前置数据检查
        guard let userIdAsInt = UInt64(userID) else {
            LarkRustClient.logger.error(
                "make user online failed. no valid userId as Int",
                additionalData: ["userId": userID]
            )
            preconditionAlpha(false, "offline with invalid userID \(userID)")
            callback(.failure(.invalidUserID))
            return
        }
        guard let state = willOfflineRustService(userID: userID) else {
            preconditionAlpha(false, "offline with invalid rust state \(userID)")
            callback(.failure(.invalidUserID))
            return
        }

        guard let oldID = state.client.userLifeContainerID else {
            LarkRustClient.logger.info("try wait destinationID for offline - userID: \(userID)")
            return notify(when: { !state.waitOnline }, timeout: 2) { (_) in
                /// logout一定要成功。即时获取不到containerID..
                runAfter(oldID: state.client.userLifeContainerID)
            }
        }
        runAfter(oldID: oldID)
        func runAfter(oldID: UInt64?) {
            // logoutReason以前没有传，要传的话得passport支持，把信息传递过来..
            var req = Tool_V1_MakeUserOfflineV2Request()
            req.userID = userIdAsInt
            // NOTE: 登出场景, rust要求传全生命周期ID
            // NOTE: 目前必传，强制登出的异常场景可能没有这个ID..
            if let oldID { req.containerID = oldID }
            req.priorState = priorState

            var packet = RequestPacket(message: req)
            packet.barrier = true

            let additionalData = [
                "userId": userID,
                "clientIdentifier": state.client.identifier
            ]
            state.client.async(packet) { packet in
                _ = state // state需要保活，否则async发不出去... 只是capture看起来不生效..

                switch packet.result {
                case .success:
                    LarkRustClient.logger.info("make user offline succ", additionalData: additionalData)
                    callback(.success(()))
                case .failure(let error):
                    LarkRustClient.logger.error("make user offline fail", additionalData: additionalData, error: error)
                    callback(.failure(.rust(error)))
                }
            }
        }
    }

    /// 用户切换状态，旧状态和rust切换状态间可以并发. 旧状态需要保留直到端上用新状态登录
    public func switchUserState(user: User, state: Tool_V1_UserLoginState,
                                callback: @escaping (Result<Void, LifeCycleError>) -> Void) {
        assertFlowType(.multiUser)
        preconditionAlpha(state != .offline, "switch user state must not to offline, should call offline")

        // 前置数据检查
        let userID = user.userID
        guard let userIdAsInt = UInt64(userID) else {
            LarkRustClient.logger.error(
                "switch user state failed. no valid userId as Int",
                additionalData: ["userId": userID]
            )
            preconditionAlpha(false, "switch user state with invalid userID \(userID)")
            callback(.failure(.invalidUserID))
            return
        }
        // NOTE: fastLogin如果没有等rust，这里可能没有id..
        // 不过测试发现虽然不等fastLogin，但因为串行流程会等background，所以时间也足够上线了..,
        // 进入这个异常分支的可能性很小
        guard let oldState = willOfflineRustService(userID: userID) else {
            preconditionAlpha(false, "switch user must has old rustClient! userID: \(userID)")
            return callback(.failure(.invalidUserID))
        }
        guard let oldID = oldState.client.destinationID else {
            LarkRustClient.logger.info("try wait destinationID - userID: \(userID)")
            return notify(when: { !oldState.waitOnline }, timeout: 5, action: { [self](ok) in
                if ok, let oldID = oldState.client.destinationID {
                    LarkRustClient.logger.info("try wait destinationID ok - userID: \(userID)")
                    runAfter(oldID: oldID)
                } else {
                    // fastLogin不等rust结果，才可能出现失败或者超时，而没有destinationID的情况.
                    // 当成正常情况兼容。最终都是offline兜底..
                    // NOTE: 这里把rustState清理调了，但是并没有调用rust, 因此状态需要还远等待配对的offline调用
                    LarkRustClient.logger.info("try wait destinationID failed - userID: \(userID)")
                    lock.withLocking { _rustState[userID] = oldState }
                    return callback(.failure(.rust(LifeCycleError.nodestinationID(userID))))
                }
            })
        }
        runAfter(oldID: oldID)
        func runAfter(oldID: UInt64) {
            let foreground = state == .foregroundOnline
            let rustState = self.willOnlineRustService(userID: userID, foreground: foreground)
            oldState.client.movePushToNewClient(next: rustState.client)

            // finish必定调用, success成功调用。注意不要重复设置
            var actionsAfterSuccess = [() -> Void]()
            var actionsWhenFinish = [() -> Void]()
            if foreground {
                foregroundUserOnlineSpecial(user: user, state: rustState,
                                            actionsAfterSuccess: &actionsAfterSuccess,
                                            actionsWhenFinish: &actionsWhenFinish)
            }

            var req = Tool_V1_SwitchUserStateRequest()
            req.userID = userIdAsInt
            req.destinationState = state
            req.previousContainerID = oldID

            LarkRustClient.logger.info("switch user state", additionalData: [
                "userId": "\(req.userID)",
                "state": "\(state.rawValue)"
            ])

            var packet = RequestPacket(message: req)
            packet.barrier = true
            rustState.client.async(packet) { packet in
                do {
                    let response: Tool_V1_SwitchUserStateResponse = try packet.result.get()
                    rustState.client.rustContainerID = (response.destinationContainerID, response.userContainerID)
                    rustState.waitOnline = false
                    rustState.client.onRustContainerSet()
                    LarkRustClient.logger.info("switch user state Success", additionalData: [
                        "userId": userID,
                        "clientIdentifier": rustState.client.identifier,
                        "destinationID": response.destinationContainerID.description,
                        "userContainerID": response.userContainerID.description
                    ])

                    actionsAfterSuccess.reversed().forEach { $0() }
                    actionsWhenFinish.reversed().forEach { $0() }

                    callback(.success(()))
                } catch {
                    rustState.waitOnline = false
                    actionsWhenFinish.reversed().forEach { $0() }

                    LarkRustClient.logger.error("switch user state failed.",
                                                additionalData: ["userId": userID],
                                                error: error)
                    callback(.failure(.rust(error)))
                }
            }
        }
    }
    /// 保证切换账户和创建新RustClient的原子性。避免切换用户期间发生意外的调用。
    /// 同时也保障切换性能..
    /// 多用户新流程下，会拦截所有的用户client。但用户无关的全局client不受影响
    public func barrier(enter: @escaping (_ leave: @escaping () -> Void) -> Void) {
        // NOTE: 新流程client生命周期跟随容器管理，释放即销毁, 其他地方不再调用dispose
        // NOTE: DispatchQueue有最大线程数限制（目前测试是64），所以卡住线程wait可能导致线程用完卡死.., 对应实现需要是非阻塞的
        lock.lock()
        let allowRequest = self.allowRequestInBarrier()
        // 只控制已经上线，业务可能交互的，rust内部新上线的不用拦截
        let rustServices = _rustServices
        let expectBarrierCount = rustServices.count
        Self.logger.info("switch user start barrier \(expectBarrierCount)")
        if expectBarrierCount == 0 {
            lock.unlock()
            enter { Self.logger.info("switch user finish barrier") }
            return
        }
        defer { lock.unlock() }
        let barrierCount = AtomicUInt(0)
        var leaves = [() -> Void](repeating: {}, count: expectBarrierCount)
        for (i, (_, state)) in rustServices.enumerated() {
            state.client.barrier(allowRequest: allowRequest) { leave in
                leaves[i] = leave
                if barrierCount.increment() + 1 == expectBarrierCount {
                    Self.logger.info("switch user enter barrier")
                    // 都已经进入barrier，开始执行
                    enter {
                        Self.logger.info("switch user finish barrier")
                        for leave in leaves {
                            leave()
                        }
                    }
                }
            }
        }
    }
    func allowRequestInBarrier() -> (RequestPacket) -> Bool {
        let allowMessage: Set<String> = [
            // 多用户新流程
            Tool_V1_MakeUserOnlineV2Request.protoMessageName,
            Tool_V1_MakeUserOfflineV2Request.protoMessageName,
            Tool_V1_SwitchUserStateRequest.protoMessageName,
            // 业务特殊接口
            Device_V1_SetPushTokenRequest.protoMessageName, // 登出时清空pushToken
            Basic_V1_SetClientStatusRequest.protoMessageName, // 网络状态设置，本身应该是全局接口，待迁移。但现在跟随用户态使用..
            // 安全文件加解密
            Security_V1_FileSecurityQueryStatusV2Request.protoMessageName,
            Security_V1_FileSecurityEncryptDirV2Request.protoMessageName,
            Security_V1_FileSecurityEncryptV2Request.protoMessageName,
            Security_V1_FileSecurityDecryptDirV2Request.protoMessageName,
            Security_V1_FileSecurityDecryptV2Request.protoMessageName,
            Security_V1_FileSecurityWriteBackV2Request.protoMessageName,

            // TODO: 确认这些command哪些不应该在V2里调用
            Basic_V1_SetEnvRequest.protoMessageName,
            Device_V1_GetDeviceIdRequest.protoMessageName,
            Device_V1_SetDeviceRequest.protoMessageName,
            Tool_V1_GetCaptchaEncryptedTokenRequest.protoMessageName,
            // SwitchUser，本地没有对应user时，拉取user列表会调用此方法
            Device_V1_SetDeviceSettingRequest.protoMessageName,
            Openplatform_V1_IsAppLinkEnableRequest.protoMessageName,
            Settings_V1_GetCommonSettingsRequest.protoMessageName,
            Passport_V1_ResetRequest.protoMessageName
        ]
        return { packet in
            let messageName = type(of: packet.message).protoMessageName
            let allow = allowMessage.contains(messageName)
            if !allow {
                Self.logger.warn("not allow request while barrier, may cause stuck on switch user", additionalData: [
                    "messageName": messageName
                ])
            }
            return allow
        }
    }

    /// 前台用户兼容的一些旧逻辑.., 主要从之前的逻辑中搬运
    private func foregroundUserOnlineSpecial(
        user: User,
        state: RustClientState,
        actionsAfterSuccess: inout [() -> Void],
        actionsWhenFinish: inout [() -> Void]
    ) {
        actionsAfterSuccess.append { [client = state.client] in
            DispatchQueue.global().async {
                self.setIdcFlowControlValue(client: client)
            }
        }

        // 图片请求必须在makeUserOnline以后，否则请求图片会失败. 直到online成功
        LarkImageService.shared.pauseImageRequest()
        actionsWhenFinish.append { LarkImageService.shared.resumeImageRequest() }

        AppStartupMonitor.shared.start(key: .ttnetInitialize)
        setupTTNetInitializor(accessToken: user.sessionKey ?? "",
                              tenantID: user.tenant.tenantID,
                              userID: user.userID)
        AppStartupMonitor.shared.end(key: .ttnetInitialize)

        let timeStart = CACurrentMediaTime()
        actionsAfterSuccess.append {
            ColdStartup.shared?.doForRust(.stateReciableSetAccessToken, (CACurrentMediaTime() - timeStart) * 1_000)
            ColdStartup.shared?.doForRust(.stateReciableInit, RustClient.rustInitCost)
        }

        observeAppLifeCycle()
        actionsAfterSuccess.append {
            self.observeNetwork()
        }
    }

    private func from(leanModeInfo: LeanModeInfo) -> Tool_V1_LeanModeConfig {
        var leanModeConfig = Tool_V1_LeanModeConfig()
        // cfg
        var leanModeCfg = Basic_V1_LeanModeCfg()
        leanModeCfg.allDevicesInLeanMode = leanModeInfo.allDevicesInLeanMode
        leanModeCfg.leanModeCfgUpdatedAtMicroSec = leanModeInfo.leanModeCfgUpdateTime
        leanModeCfg.canUseLeanMode = leanModeInfo.canUseLeanMode
        leanModeCfg.deviceHaveAuthority = leanModeInfo.deviceHaveAuthority
        leanModeConfig.leanModeCfg = leanModeCfg

        // lockScreenCfg
        var lockScreenCfg = Basic_V1_LockScreenCfg()
        lockScreenCfg.isLockScreenEnabled = leanModeInfo.isLockScreenEnabled
        if let lockScreenPwd = leanModeInfo.lockScreenPwd {
            lockScreenCfg.lockScreenPassword = lockScreenPwd
        }
        lockScreenCfg.lockScreenCfgUpdatedAtMicroSec = leanModeInfo.lockScreenCfgUpdateTime
        leanModeConfig.lockScreenCfg = lockScreenCfg

        return leanModeConfig
    }

    private func _configService(userID: String, foreground: Bool, state: RustClientState) {
        state.rustServicePushBarrierExit = state.client.pushBarrier(allowCmds: Self.pushAllowCmds(cmd:))
        // FIXME: 这里的注册好像要花100ms？看看能不能优化启动性能..
        Self.registerSharedUserPush(on: state, userID: userID, foreground: foreground)
        hookSerialize(client: state.client, userID: userID)
    }

    /// 新用户调用rust前调用, 保证对应的client已经被创建.
    fileprivate func willOnlineRustService(userID: String, foreground: Bool) -> RustClientState {
        // TODO: 也许改成用userStorage做唯一标识会更好?
        let newService = rustServiceProvider(userID)
        let state = RustClientState(client: newService)

        LarkRustClient.logger.info("will Online Rust Service", additionalData: [
            "userId": userID,
            "foreground": String(foreground),
            "clientIdentifier": newService.identifier
        ])

        lock.lock(); defer { lock.unlock() }
        _rustState[userID] = state
        _configService(userID: userID, foreground: foreground, state: state)
        state.waitOnline = true
        return state
    }
    fileprivate func willOfflineRustService(userID: String) -> RustClientState? {
        lock.lock(); defer { lock.unlock() }
        // 优先用最新的，保证rust的online和offline配对..
        // 异常强制下线，或者端上没有登录的情况，会留在_willOnlineRustServices状态里
        //
        // willOnlineRustService是给rust用的，在这次状态管控里需要被下线, 所以直接清理
        // _rustServices是给端上访问的. 需要外部控制
        return _rustState.removeValue(forKey: userID)
    }

    /// 端上上线前调用, 替换调当前的client, 可以被外部访问到..
    /// NOTE:Precondition: 需要先进行过willOnline的流程
    public func didOnlineRustService(userID: String, foreground: Bool) {
        lock.lock(); defer { lock.unlock() }
        let state = _rustState[userID] ?? {
            preconditionAlpha(false, "must create rust service before online")
            let state = RustClientState(client: rustServiceProvider(userID))
            self._configService(userID: userID, foreground: foreground, state: state)
            return state
        }()

        _rustServices[userID] = state
        if foreground && userID != _currentUserID {
            // NOTE: 期望旧前台用户的下线在前面，上线在新前台的后面.
            // 所以此时旧前台已经下线，且当前user也被改掉，因此可以清理掉对应的services
            _rustServices.removeValue(forKey: self._currentUserID)
            self._currentUserID = userID
        }
    }

    public func didOfflineRustService(userID: String, foreground: Bool) {
        if foreground {
            // 下线为nil时再清理，避免马上上线，中间产生一个临时对象
            // 需要保证didOfflineForegroundRustService的调用
            // 如果是切换状态，那后续online时会覆盖新的对象..
            // NOTE: 如果online被取消，会在下一次的流程里:
            //  1. 如果重新上线, online后会覆盖
            //  2. 如果下线，流程会直接运行offline to nil的逻辑, 会调用didOfflineForegroundRustService
        } else {
            lock.lock(); defer { lock.unlock() }
            _rustServices.removeValue(forKey: userID)
        }
    }
    /// 仅当下线前台，且不马上online新用户的下线场景使用.
    /// 由此避免创建一个临时占位的rustService
    public func didOfflineForegroundRustService(userID: String) {
        preconditionAlpha(userID == lock.withLocking { _currentUserID }, "must be current user")
        updateRustService(userId: nil)
    }
}

func preconditionAlpha(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String, file: StaticString = #file, line: UInt = #line) {
    if !condition() {
        #if ALPHA
        fatalError(message(), file: file, line: line)
        #else
        LarkContainerManager.logger.error(message(), file: String(describing: file), line: Int(line))
        #endif
    }

}

/// - Parameters:
///     when condition: 等待条件（返回true）
///     timeout: 等待时间
///     action: 结束回调。true代表成功等待。false代表超时
func notify(when condition: @escaping () -> Bool, interval: TimeInterval = 0.001, timeout: TimeInterval, action: @escaping (Bool) -> Void) {
    let end = DispatchTime.now() + timeout
    check()
    func check() {
        if condition() { return action(true) }
        let now = DispatchTime.now()
        if now > end { return action(false) }

        DispatchQueue.global().asyncAfter(deadline: now + interval, execute: check)
    }
}

typealias NoticeClientEventRequest = RustPB.Basic_V1_NoticeClientEventRequest
typealias SetReqIdSuffixResponse = RustPB.Basic_V1_SetReqIdSuffixResponse
typealias SetIdcFlowControlValueResponse = RustPB.Basic_V1_SetIdcFlowControlValueResponse

// swiftlint:enable file_length
