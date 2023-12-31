//
//  SpeedClockIn.swift
//  LarkOpenPlatform
//
//  Created by zhaojingxin on 2022/3/4.
//

import Foundation
import LarkContainer
import LarkAccountInterface
import LarkSDKInterface
import Swinject
import RxSwift
import CoreLocation
import SystemConfiguration.CaptiveNetwork
import EEMicroAppSDK
import LKCommonsLogging
import LarkRustClient
import ServerPB
import Reachability
import LarkSetting
import NetworkExtension
import LarkCoreLocation
import OPFoundation

struct OPClockInPushMessage: PushMessage {
    public enum EventType {
        case refreshConfig
        case topSpeedClockIn
    }

    public let type: EventType
    public let environmentTypeList: [ServerPB_Attendance_push_EnvironmentType]
}

final class OPClockInPushHandler: UserPushHandler {
    
    public func process(push message: ServerPB_Attendance_push_PushAttendanceRequest) throws {
        switch message.eventType {
        case .refreshConfig:
            try self.userResolver.userPushCenter.post(OPClockInPushMessage(type: .refreshConfig, environmentTypeList: []))
        case .topSpeedClockIn:
            try self.userResolver.userPushCenter.post(OPClockInPushMessage(type: .topSpeedClockIn, environmentTypeList: message.environmentTypeList))
        @unknown default: break
        }
    }
}

final class OPClockInMonitorCode: OPMonitorCode {

    /// 发起获取打卡配置请求GetTopSpeedClockInConfig
    static let getConfigStart = OPClockInMonitorCode(code: 10000, message: "get_config_start")

    /// 请求 GetTopSpeedClockInConfig 接口成功
    static let getConfigSuccess = OPClockInMonitorCode(code: 10001, message: "get_config_success")

    /// 请求 GetTopSpeedClockInConfig 接口失败
    static let getConfigFail = OPClockInMonitorCode(code: 10002, level: OPMonitorLevelError, message: "get_config_fail")
    
    static let checkTopSpeedClockinStart = OPClockInMonitorCode(code: 10004, message: "check_top_speed_clockin_start")

    /// 获取打卡参数（gps 或 wifi）成功
    static let checkSpeedClockInSuccess = OPClockInMonitorCode(code: 10005, message: "check_top_speed_clockin_success")

    /// 获取打卡参数失败（gps、wifi信息均获取失败）
    static let checkSpeedClockInFail = OPClockInMonitorCode(code: 10006, level: OPMonitorLevelError, message: "check_top_speed_clockin_fail")

    /// 发起极速打卡请求 TopSpeedClockIn
    static let speedClockInStart = OPClockInMonitorCode(code: 10010, message: "top_speed_clockin_start")

    /// 请求 TopSpeedClockIn 接口成功
    static let speedClockInSuccess = OPClockInMonitorCode(code: 10011, message: "top_speed_clockin_success")

    /// 请求 TopSpeedClockIn 接口失败
    static let speedClockInFail = OPClockInMonitorCode(code: 10012, level: OPMonitorLevelError, message: "top_speed_clockin_fail")

    init(code: Int, level: OPMonitorLevel = OPMonitorLevelNormal, message: String) {
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }

    static let domain = "client.open_platform.gadget.top_speed_clockin"

    static let event = "op_top_speed_clockin"
}

final class SpeedClockIn {

    private static let logger = Logger.oplog(SpeedClockIn.self, category: "SpeedClockIn")
    private var trace: OPTrace?

    private var httpClient: OpenPlatformHttpClient?
    
    /// 是否等待rust init 之后再发出 updateConfig 请求
    @RealTimeFeatureGatingProvider(key: "openplatform.api.speedclockin_rust_wati_updateconfig.disable") private var rustWaitDisable: Bool
    private var globalRustService: GlobalRustService?

    private let resolver: UserResolver

    private let disposeBag = DisposeBag()
    private var configUpdating = false
    private var locating = false
    var locationTask: SingleLocationTask?
    private var onClockIn = false
    private var lastReachabilityConnection: Reachability.Connection?

    private var locatingCompletion: ((OPClockInGPS?, OPClockInAuthStatus) -> Void)?
    private var reachability: Reachability?
    private var clockInConfigRes: OPSpeedClockInConfigResponse?
    private var speedClockInCompensateTimer: Timer?

    private var oldSpeedClockIn: UploadInfoChecker?

    deinit {
        speedClockInCompensateTimer?.invalidate()
        reachability?.stopNotifier()
        reachability?.notificationCenter.removeObserver(self)
    }

    init(resolver: UserResolver) {
        self.resolver = resolver
        self.httpClient = try? resolver.resolve(assert: OpenPlatformHttpClient.self)
        self.globalRustService = try? resolver.resolve(assert: GlobalRustService.self)
        let request = SingleLocationRequest(desiredAccuracy: kCLLocationAccuracyHundredMeters,
                                            desiredServiceType: nil,
                                            timeout: 3,
                                            cacheTimeout: 0)
        self.locationTask = try? resolver.resolve(assert: SingleLocationTask.self, argument: request)
    }

    func start() {
        updateConfigAndClockInOnDemand(source: .launch)
        
        if !resolver.fg.dynamicFeatureGatingValue(with: "openplatform.user_scope_compatible_disable") {
            AccountServiceAdapter.shared.accountChangedObservable.subscribe(onNext: { [weak self] account in
                guard let `self` = self else {
                    Self.logger.info("account changed break, self nil")
                    return
                }

                if account != nil {
                    self.updateConfigAndClockInOnDemand(source: .accountChanged)
                }
            }).disposed(by: disposeBag)
        }


        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if self.clockInConfigRes == nil {
                    self.updateConfigAndClockInOnDemand(source: .foregroundCompensate)
                } else {
                    Self.logger.info("willEnterForeground, check speed clcok in break, need not clockin")
                }
            }).disposed(by: disposeBag)

        if let pushCenter = try? resolver.userPushCenter {
            pushCenter.observable(for: OPClockInPushMessage.self)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] payload in
                    Self.logger.info("recieve clock in push message, type: \(payload.type)")

                    guard let `self` = self else { return }

                    if payload.type == .refreshConfig {
                        self.updateConfigAndClockInOnDemand(source: .push)
                    } else if payload.type == .topSpeedClockIn {
                        let envList = payload.environmentTypeList.compactMap { OPClockInEnvType(rawValue: $0.rawValue ?? 0) }
                        DispatchQueue.main.async { [weak self] in
                            self?.checkSpeedClockIn(source: .push, supportedEnvTypeList: envList, needRiskInfo: false)
                        }
                    }
            }).disposed(by: disposeBag)
        }


        reachability?.stopNotifier()
        reachability?.notificationCenter.removeObserver(self)
        reachability = Reachability()
        if let reach = reachability {
            reach.notificationCenter.addObserver(self, selector: #selector(onNetworkChanged(_:)), name: Notification.Name.reachabilityChanged, object: nil)
            do {
                try reach.startNotifier()
            } catch {
                Self.logger.error("reachability startNotifier fail")
            }
        }
    }
}

// MARK: - ClockIn Flow
extension SpeedClockIn {

    func updateConfigAndClockInOnDemand(source: GetConfigSource) {
        Self.logger.info("get config will, source: \(source.rawValue)")
        guard !configUpdating else {
            Self.logger.info("get config break, configUpdating")
            return
        }
        
        guard let userService = try? resolver.resolve(assert: PassportUserService.self) else {
            Self.logger.error("get config break, tid: userService is nil")
            return
        }
        let tenantID = userService.userTenant.tenantID
        let userID = resolver.userID
        guard !tenantID.isEmpty && !userID.isEmpty else {
            Self.logger.info("get config break, tid: \(tenantID), uid: \(userID)")
            return
        }

        trace = OPTraceService.default().generateTrace()

        Self.logger.info("get config start, tid: \(tenantID), uid: \(userID)")
        OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.getConfigStart)
            .addCategoryValue("trigger_type", source.rawValue)
            .addCategoryValue(OPMonitorEventKey.trace_id, trace?.traceId ?? "")
            .flush()

        configUpdating = true
        let begin = Date().timeIntervalSince1970
        let configAPI = OpenPlatformAPI.speedClockInGetConfigAPI(tenantID: tenantID, userID: userID, traceID: trace?.traceId ?? "", beginTime: begin, resolver: resolver)
        let sendRequstAction: () -> Void = { [weak self] in
            guard let self = self else {
                Self.logger.error("requestAction exec failed: self is nil")
                return
            }
            self.httpClient?.request(api: configAPI).subscribe { [weak self] (res: OPSpeedClockInConfigResponse) in
                Self.logger.info("get config end, res: \(res.json["data"])")
                self?.configUpdating = false
                guard res.code == 0 else {
                    OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.getConfigFail)
                        .setErrorCode("\(res.code ?? 0)")
                        .setErrorMessage(res.msg)
                        .addCategoryValue("trigger_type", source.rawValue)
                        .addCategoryValue(OPMonitorEventKey.duration, Int64((Date().timeIntervalSince1970 - begin) * 1000))
                        .addCategoryValue(OPMonitorEventKey.trace_id, self?.trace?.traceId ?? "")
                        .flush()
                    return
                }

                OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.getConfigSuccess)
                    .addCategoryValue("trigger_type", source.rawValue)
                    .addCategoryValue(OPMonitorEventKey.duration, Int64((Date().timeIntervalSince1970 - begin) * 1000))
                    .addCategoryValue("is_new_version", res.refactorEnabled)
                    .addCategoryValue("is_opened", res.opended)
                    .addCategoryValue("environment_type", res.supportedEnvTypeList.map { $0.rawValue })
                    .addCategoryValue("begin_time", res.beginTime)
                    .addCategoryValue("end_time", res.endTime)
                    .addCategoryValue("need_speed_clock_in", res.needClockin)
                    .addCategoryValue(OPMonitorEventKey.trace_id, self?.trace?.traceId ?? "")
                    .flush()
                guard let `self` = self else { return }

                if var clockInEnv = try? self.resolver.resolve(assert: OPClockInEnv.self) {
                    clockInEnv.speedClockRefactorEnabled = res.refactorEnabled
                }
                if res.refactorEnabled {
                    guard res.opended else {
                        Self.logger.info("check speed clcok in break, refactor enabled: \(res.refactorEnabled), opended: \(res.opended)")
                        self.clockInConfigRes = res
                        return
                    }
                    if !res.needClockin {
                        Self.logger.info("check speed clcok in break, need not clockin")
                        return
                    } else {
                        self.clockInConfigRes = nil
                    }
                    self.checkSpeedClockIn(source: .afterConfig, supportedEnvTypeList: res.supportedEnvTypeList, needRiskInfo: res.needRiskInfo)
                } else if self.oldSpeedClockIn == nil {
                    Self.logger.info("oldSpeedClockIn cache clockInConfigRes")
                    self.clockInConfigRes = res
                    self.triggerOldSpeedClockInFlowOnce()
                }
            } onError: { [weak self] error in
                Self.logger.error("get config error : \(error.localizedDescription)")
                OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.getConfigFail)
                    .setError(error)
                    .addCategoryValue("trigger_type", source.rawValue)
                    .addCategoryValue(OPMonitorEventKey.duration, Int64((Date().timeIntervalSince1970 - begin) * 1000))
                    .addCategoryValue(OPMonitorEventKey.trace_id, self?.trace?.traceId ?? "")
                    .flush()
                self?.configUpdating = false
            }.disposed(by: self.disposeBag)
        }
        // 网络请求底层被rust接管。极速打卡触发的时机非常早，此时发送请求rust很可能还未初始化完成。
        // 这里使用 rust 提供的wait方法，等待rust初始化后再发送
        if rustWaitDisable {
            Self.logger.info("direct sendRequstAction")
            sendRequstAction()
        } else {
            Self.logger.info("sendRequstAction with rust wait")
            globalRustService?.wait(callback: sendRequstAction)
        }
        
    }

    private func triggerOldSpeedClockInFlowOnce() {
        guard oldSpeedClockIn == nil else { return }

        Self.logger.info("old speed clock in trigger")
        oldSpeedClockIn = UploadInfoChecker(resolver: resolver)
        oldSpeedClockIn?.start()
    }

    private func checkSpeedClockIn(source: SpeedClockInSource, supportedEnvTypeList: [OPClockInEnvType], needRiskInfo: Bool) {

        func monitorCheckSpeedClockIn(source: SpeedClockInSource, envList: [OPClockInEnvType], wifiStatus: OPClockInAuthStatus?, gpsStatus: OPClockInAuthStatus?, success: Bool) {
            let monitor = OPMonitor(name: OPClockInMonitorCode.event, code: success ? OPClockInMonitorCode.checkSpeedClockInSuccess : OPClockInMonitorCode.checkSpeedClockInFail)
                .addCategoryValue("trigger_type", source.rawValue)
                .addCategoryValue("environment_type", envList.map { $0.rawValue })
                .addCategoryValue(OPMonitorEventKey.trace_id, trace?.traceId ?? "")
            if let wifi = wifiStatus { monitor.addCategoryValue("wifi", wifi.rawValue) }
            if let gps = gpsStatus { monitor.addCategoryValue("gps", gps.rawValue) }
            monitor.flush()
        }

        Self.logger.info("check speed clcok in will, source: \(source.rawValue)")

        if source != .nextTimeCompensate { speedClockInCompensateTimer?.invalidate() }

        let envList: [OPClockInEnvType] = supportedEnvTypeList
        guard envList.contains(.wifi) || envList.contains(.GPS) else {
            Self.logger.info("check speed clcok in break, env list: \(envList)")
            return
        }
        
        var riskInfo: OPClockInRiskInfo?
        if needRiskInfo {
            let isCracked = OpenSecurityHelper.isCracked()
            let isEmulator = OpenSecurityHelper.isEmulator()
            let isDebug = OpenSecurityHelper.isDebug()
            let deviceID = EMARouteProvider.getEMADelegate()?.hostDeviceID() ?? ""
            let model = "\(UIDevice.current.lu.modelName()), iOS \(UIDevice.current.systemVersion)"
            riskInfo = OPClockInRiskInfo(isCracked: isCracked, isEmulator: isEmulator, isDebug: isDebug, deviceID: deviceID, deviceModel: model)
        }
        
        OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.checkTopSpeedClockinStart)
            .addCategoryValue("trigger_type", source.rawValue)
            .addCategoryValue("environment_type", envList.map { $0.rawValue })
            .addCategoryValue(OPMonitorEventKey.trace_id, trace?.traceId ?? "")
            .flush()
        
        if envList.contains(.wifi), !self.resolver.fg.dynamicFeatureGatingValue(with: "attendance.top_speed_clock_in.forbid_bssid") {
            Self.logger.info("get wifi info")
            self.getWifiInfo { opClockInWifi in
                if envList.contains(.GPS) {
                    self.fetchGPSInfo { [weak self] (gps, status) in
                        monitorCheckSpeedClockIn(source: source, envList: envList, wifiStatus: opClockInWifi != nil ? OPClockInAuthStatus.success : nil, gpsStatus: status, success: true)
                        if let gpsInfo = gps {
                            self?.speedClockIn(gps: gpsInfo, wifi: opClockInWifi, source: source, envList: envList, riskInfo: riskInfo)
                        } else if let opClockInWifi = opClockInWifi {
                            self?.speedClockIn(gps: nil, wifi: opClockInWifi, source: source, envList: envList, riskInfo: riskInfo)
                        }
                    }
                } else if let opClockInWifi = opClockInWifi {
                    monitorCheckSpeedClockIn(source: source, envList: envList, wifiStatus: OPClockInAuthStatus.success, gpsStatus: nil, success: true)
                    self.speedClockIn(gps: nil, wifi: opClockInWifi, source: source, envList: envList, riskInfo: riskInfo)
                } else {
                    monitorCheckSpeedClockIn(source: source, envList: envList, wifiStatus: nil, gpsStatus: nil, success: false)
                }
            }
        } else if envList.contains(.GPS) {
            self.fetchGPSInfo { [weak self] (gps, status) in
                monitorCheckSpeedClockIn(source: source, envList: envList, wifiStatus: OPClockInAuthStatus.fail, gpsStatus: status, success: true)
                if let gpsInfo = gps {
                    self?.speedClockIn(gps: gpsInfo, wifi: nil, source: source, envList: envList, riskInfo: riskInfo)
                }
            }
        }
    }
    
    private func getWifiInfo(completion: @escaping (OPColockInWifi?) -> Void) {
        guard requestLocationEnabled() else {
            Self.logger.error("not allow bgLocaiton getWifiInfo fail!")
            completion(nil)
            return
        }
        if #available(iOS 14.0, *) {
            do {
                Self.logger.info("get wifi info by NEHotspotNetwork")
                try OPSensitivityEntry.fetchCurrent(forToken: .openPlatformSpeedClockInGetWifiInfo) { network in
                    if let network = network {
                        let clockInWifi = OPColockInWifi(id: nil, name: network.ssid, macAddress: MacAddressFormat().format(network.bssid))
                        Self.logger.info("get wifi info success")
                        completion(clockInWifi)
                    } else {
                        Self.logger.error("get wifi info fail")
                        completion(nil)
                    }
                }
            } catch {
                Self.logger.error("fetchCurrentWifi throws error: \(error)")
                completion(nil)
            }
        } else {
            do {
                Self.logger.info("get wifi info by CNCopyCurrentNetworkInfo")
                if let wifiInfo = try self.fetchWifiInfo() {
                    Self.logger.info("get wifi info success")
                    let clockInWifi = wifiInfo
                    completion(clockInWifi)
                } else {
                    Self.logger.error("get wifi info fail")
                    completion(nil)
                }
            } catch {
                Self.logger.error("CNCopyCurrentNetworkInfo throws error: \(error)")
                completion(nil)
            }
            
        }
    }

    private func speedClockIn(gps: OPClockInGPS?, wifi: OPColockInWifi?, source: SpeedClockInSource, envList: [OPClockInEnvType], riskInfo: OPClockInRiskInfo?) {
        Self.logger.info("speed clcok in will, source: \(source.rawValue)")


        guard !onClockIn else {
            Self.logger.info("speed clcok in break, onClockIn")
            return
        }

        guard let userService = try? resolver.resolve(assert: PassportUserService.self) else {
            Self.logger.error("get config break, tid: userService is nil")
            return
        }
        let tenantID = userService.userTenant.tenantID
        let userID = resolver.userID
        guard !tenantID.isEmpty && !userID.isEmpty else {
            Self.logger.info("speed clcok in break, tid: \(tenantID), uid: \(userID)")
            return
        }

        Self.logger.info("speed clock in start, tid: \(tenantID), uid: \(userID)")
        OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.speedClockInStart)
            .addCategoryValue("trigger_type", source.rawValue)
            .addCategoryValue(OPMonitorEventKey.trace_id, trace?.traceId ?? "")
            .flush()

        onClockIn = true
        let begin = Date().timeIntervalSince1970
        let req = OPSpeedColckInReq(tenantID: tenantID, userID: userID, gps: gps, wifiMacAdress: wifi?.macAddress, scanWifiList: nil, traceID: trace?.traceId ?? "", riskInfo: riskInfo)
        let clockInAPI = OpenPlatformAPI.speedClockInAPI(req: req, resolver: resolver)
        httpClient?.request(api: clockInAPI).subscribe { [weak self] (res: OPSpeedClockInResponse) in
            Self.logger.info("speed clock in end, res: \(res.json["data"])")
            self?.onClockIn = false
            guard res.code == 0 else {
                OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.speedClockInFail)
                    .setErrorCode("\(res.code ?? 0)")
                    .setErrorMessage(res.msg)
                    .addCategoryValue("trigger_type", source.rawValue)
                    .addCategoryValue(OPMonitorEventKey.duration, Int64((Date().timeIntervalSince1970 - begin) * 1000))
                    .addCategoryValue(OPMonitorEventKey.trace_id, self?.trace?.traceId ?? "")
                    .flush()
                return
            }
            
            OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.speedClockInSuccess)
                .addCategoryValue("trigger_type", source.rawValue)
                .addCategoryValue(OPMonitorEventKey.duration, Int64((Date().timeIntervalSince1970 - begin) * 1000))
                .addCategoryValue("is_in_env", res.inValidArea)
                .addCategoryValue("clock_in_fail_code_name", res.clockInFailCode)
                .addCategoryValue("is_clock_in_succeed", res.colockInSucceed)
                .addCategoryValue("top_speed_retry_time_duration", res.nextTimeInterval4SpeedClockIn)
                .addCategoryValue(OPMonitorEventKey.trace_id, self?.trace?.traceId ?? "")
                .flush()

            guard let `self` = self else { return }

            if !res.colockInSucceed, let interval = res.nextTimeInterval4SpeedClockIn, interval > 0 {
                self.compensateColockInNextTime(interval: interval, envList: envList, needRiskInfo: riskInfo != nil)
            }
        } onError: { [weak self] error in
            Self.logger.error("speed clock in error : \(error.localizedDescription)")
            OPMonitor(name: OPClockInMonitorCode.event, code: OPClockInMonitorCode.speedClockInFail)
                .setError(error)
                .addCategoryValue("trigger_type", source.rawValue)
                .addCategoryValue(OPMonitorEventKey.duration, Int64((Date().timeIntervalSince1970 - begin) * 1000))
                .addCategoryValue(OPMonitorEventKey.trace_id, self?.trace?.traceId ?? "")
                .flush()

            self?.onClockIn = false
        }
    }

    private func compensateColockInNextTime(interval: Int32, envList: [OPClockInEnvType], needRiskInfo: Bool) {
        speedClockInCompensateTimer?.invalidate()

        speedClockInCompensateTimer = Timer(timeInterval: TimeInterval(integerLiteral: Int64(interval)), repeats: false, block: { [weak self] _ in
            self?.checkSpeedClockIn(source: .nextTimeCompensate, supportedEnvTypeList: envList, needRiskInfo: needRiskInfo)
        })
        RunLoop.main.add(speedClockInCompensateTimer!, forMode: .common)
    }

    @objc
    private func onNetworkChanged(_ notification: Notification) {
        guard !self.resolver.fg.dynamicFeatureGatingValue(with: "attendance.top_speed_clock_in.forbid_bssid") else {
            return
        }
        guard let reach = notification.object as? Reachability else { return }

        if reach.connection == .wifi, lastReachabilityConnection != nil, lastReachabilityConnection != reach.connection {
            self.updateConfigAndClockInOnDemand(source: .wifiCompensate)
        }
        lastReachabilityConnection = reach.connection
    }
}

// MARK: - Location && Wifi
extension SpeedClockIn {

    enum OPClockInAuthStatus: String {
        case success = "success"
        case fail = "fail"
        case noPermission = "no_permission"
    }
    /// https://meego.feishu.cn/larksuite/story/detail/11929697
    /// 安全合规 禁止后台定位
    private func requestLocationEnabled() -> Bool {
        // 如果造成极速打卡成功率下降，造成大量oncall，考虑打开此fg
        // 极速打开后台定位治理，fg默认关闭
        if self.resolver.fg.dynamicFeatureGatingValue(with: "openplatform.speedclockin.allow_bg_location") {
            Self.logger.warn("openplatform.speedclockin.allow_bg_location fg open allow bgLocaiton")
            return true
        }
        if UIApplication.shared.applicationState != .background {
            return true
        }
        Self.logger.error("Background positioning is not allowed")
        return false
    }

    private func fetchGPSInfo(completion: @escaping (OPClockInGPS?, OPClockInAuthStatus) -> Void) {
        guard requestLocationEnabled() else {
            Self.logger.error("not allow bgLocaiton fetchGPSInfo fail!")
            completion(nil,.fail)
            return
        }
        
        func finishLocating(gps: OPClockInGPS?, status: OPClockInAuthStatus) {
            locatingCompletion?(gps, status)
            locatingCompletion = nil
        }

        guard !locating else {
            Self.logger.info("fetch gps break, locating")
            locatingCompletion = completion
            return
        }

        locatingCompletion = completion
        locating = true

        let authStatus = CLLocationManager.authorizationStatus()
        guard authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse else {
            Self.logger.info("fetch gps break, auth status: \(authStatus)")
            locating = false
            finishLocating(gps: nil, status: .noPermission)
            return
        }
        Self.logger.info("fetch gps by SingleLocationTask")
        let request = SingleLocationRequest(desiredAccuracy: kCLLocationAccuracyHundredMeters,
                                            desiredServiceType: nil,
                                            timeout: 3,
                                            cacheTimeout: 0)
        guard let locationTask = self.locationTask else {
            Self.logger.error("locationTask is nil")
            self.locating = false
            finishLocating(gps: nil, status: .fail)
            return
        }
        locationTask.locationCompleteCallback = { aTask, result in
        self.locating = false
                switch result {
                case .success(let larkLocation):
                    Self.logger.info("fetch gps success")
                    finishLocating(gps: OPClockInGPS(longitude: larkLocation.location.coordinate.longitude, latitude: larkLocation.location.coordinate.latitude, mapType: larkLocation.locationType == .wjs84 ? .WGS84 : .GCJ02, subsidy: nil, accuracy: larkLocation.location.horizontalAccuracy, id: nil, name: nil, range: nil), status: .success)
                case .failure(let error):
                    Self.logger.error("fetch gps fail \(error)")
                    finishLocating(gps: nil, status: .fail)
                }
            }
        do {
            try locationTask.resume(forToken: OPSensitivityEntryToken.speedClockInFetchGPSInfo.psdaToken)
        } catch {
            Self.logger.error("locationTask resume error: \(error)")
        }
        
    }

    private func fetchWifiInfo() throws -> OPColockInWifi?   {
        guard let cfas: NSArray = CNCopySupportedInterfaces() else {
            Self.logger.info("fetch wifi break, cfas nil")
            return nil
        }

        var SSID: String?
        var BSSID: String?
        for cfa in cfas {
            // swiftlint:disable force_cast
            let cfDic = try OPSensitivityEntry.CNCopyCurrentNetworkInfo(forToken: .openPlatformSpeedClockInGetWifiInfoCNCopyCurrentNetworkInfo,
                                                                   interfaceName: cfa as! CFString)
            if let dic = CFBridgingRetain(cfDic) {
                if let ssid = dic["SSID"] as? String { SSID = ssid }
                if let bssid = dic["BSSID"] as? String { BSSID = bssid }
            }
            // swiftlint:enable force_cast
        }

        Self.logger.info("fetch wifi cfas scan")

        if let ssid = SSID, let bssid = BSSID {
            return OPColockInWifi(id: nil, name: ssid, macAddress: bssid)
        }
        return nil
    }
}

extension SpeedClockIn {

    enum GetConfigSource: String {
        case launch = "start_up"
        case accountChanged = "account_change"
        case push = "push"
        case wifiCompensate = "network"
        case foregroundCompensate = "back_to_front"
    }

    enum SpeedClockInSource: String {
        case afterConfig = "config"
        case push = "push"
        case foregroundCompensate = "back_to_front"
        case wifiCompensate = "network"
        case nextTimeCompensate = "retry"
    }
}
