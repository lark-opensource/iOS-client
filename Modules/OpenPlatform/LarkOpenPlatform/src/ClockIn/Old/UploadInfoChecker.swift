//
//  UploadInfoChecker.swift
//  Action
//
//  Created by tujinqiu on 2019/8/9.
//
// swiftlint:disable all
import Foundation
import Swinject
import LarkRustClient
import CoreLocation
import RxSwift
import LKCommonsLogging
import LarkAccountInterface
import LarkSetting
import LarkSDKInterface
import LarkMessengerInterface
import LarkOPInterface
import EEMicroAppSDK
import LarkContainer

class UploadInfoChecker {
    private static let logger = Logger.oplog(UploadInfoChecker.self, category: "UploadInfoChecker")

    private var clockInEnv: OPClockInEnv?

    private var config: UploadInfoConfig? {
        didSet {
            locationChecker.config = config
        }
    }
    private let wifiChecker: WifiChecker
    private let locationChecker = LocationChecker()
    let resolver: UserResolver
    private let disposeBag = DisposeBag()

    init(resolver: UserResolver) {
        self.resolver = resolver
        self.wifiChecker = WifiChecker(resolver: resolver)
        self.clockInEnv = try? resolver.resolve(assert: OPClockInEnv.self)
    }

    //  SetupOpenPlatformTask的execute方法会执行start函数 会在afterLoginStage的阶段执行
    //  这个setup目前在登录后执行，后面修改一定要保证登录后执行
    func start() {
        //  已经是login之后了，无需延迟
        UploadInfoChecker.logger.info("UploadInfoChecker start")
        self.config = nil
        OPMonitor(name: uploadInfoCheckerEvent, code: MonitorCodeUploadInfoChecker.trigger_start)
            .setTriggerType(.start_up)
            .setSnapshotId(config?.rule_snapshot_id)
            .flush()
        fetchConfigAndTryCheck(triggerType: .start_up)

        //  推送监听
        if let pushCenter = try? resolver.userPushCenter {
            pushCenter.observable(for: PushOpenCommonRequestEvent.self).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (push) in
                guard let `self` = self, self.clockInEnv?.speedClockRefactorEnabled == false else { return }

                if push.hasUserUploadSettingUpdated() {
                    //  和安卓对齐，先拉取config，在check
                    UploadInfoChecker.logger.info("receive push and hasUserUploadSettingUpdated")
                    OPMonitor(name: uploadInfoCheckerEvent, code: MonitorCodeUploadInfoChecker.trigger_start)
                        .setTriggerType(.push)
                        .setSnapshotId(self.config?.rule_snapshot_id)
                        .flush()
                    self.fetchConfigAndTryCheck(triggerType: .push)
                } else {
                    UploadInfoChecker.logger.info("receive push and has no UserUploadSettingUpdated")
                }
            }).disposed(by: disposeBag)
        }

        //  后台切前台
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self, self.clockInEnv?.speedClockRefactorEnabled == false else { return }
                if !self.resolver.fg.dynamicFeatureGatingValue(with: "openplatform.user_scope_compatible_disable") {
                    guard AccountServiceAdapter.shared.isLogin else {
                        UploadInfoChecker.logger.info("UploadInfoChecker didBecomeActiveNotification and not login, not check")
                        return
                    }
                }
                if let config = self.config {
                    OPMonitor(name: uploadInfoCheckerEvent, code: MonitorCodeUploadInfoChecker.trigger_start)
                        .setTriggerType(.back_to_front)
                        .setSnapshotId(config.rule_snapshot_id)
                        .flush()
                    UploadInfoChecker.logger.info("UploadInfoChecker didBecomeActiveNotification, logged in, use effective cache to check")
                    self.trycheck(config: config, wifiInfo: nil, triggerType: .back_to_front)
                } else {
                    UploadInfoChecker.logger.info("UploadInfoChecker didBecomeActiveNotification, logged in, fetch config")
                    self.fetchConfigAndTryCheck(triggerType: .back_to_front)
                }
            }).disposed(by: self.disposeBag)
    }

    /// 获取配置检查上报
    private func fetchConfigAndTryCheck(triggerType: TriggerType) {
        guard clockInEnv?.speedClockRefactorEnabled == false else { return }

        fetchUploadInfoConfig(triggerType: triggerType) { [weak self] config in
            guard let `self` = self else { return }
            self.trycheck(config: config, wifiInfo: nil, triggerType: triggerType)
        } failure: { err in
            Self.logger.error("fetchUploadInfoConfig failed", error: err)
        }
    }

    /// 获取配置
    private func fetchUploadInfoConfig(
        triggerType: TriggerType,
        success: @escaping (UploadInfoConfig) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        let monitorEvent = MonitorEvent(name: MonitorEvent.terminalinfo_settings_result)
        guard let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self) else {
            UploadInfoChecker.logger.info("resolve OpenPlatformHttpClient failed")
            return
        }
        UploadInfoChecker.logger.info("start fetchUploadInfoConfig")
        OPMonitor(name: uploadInfoCheckerEvent, code: MonitorCodeUploadInfoChecker.get_config_start)
            .setTriggerType(triggerType)
            .setSnapshotId(config?.rule_snapshot_id)
            .flush()
        let getConfigSuccessOrFailMonitor = OPMonitor(uploadInfoCheckerEvent)
            .setTriggerType(triggerType)
            .timing()
        client.request(api: OpenPlatformAPI.TerminalUploadSettingAPI(resolver: resolver))
            /// 先在子线程把json解析出来，后面在主线程用的时候，不需要再次解析
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .map({ (apiResponse: TerminalUploadSettingAPIResponse) -> TerminalUploadSettingAPIResponse in
                /// 尝试cong json string 解析为config json对象
                apiResponse.tryParseConfig()
                return apiResponse
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (apiResponse: TerminalUploadSettingAPIResponse) in
                guard let `self` = self else { return }
                monitorEvent.setSnapshotId(apiResponse.config?.rule_snapshot_id)
                getConfigSuccessOrFailMonitor.setSnapshotId(apiResponse.config?.rule_snapshot_id)
                guard let config = apiResponse.config else {
                    UploadInfoChecker.logger.error("getUploadInfoConfig error:parse error")
                    monitorEvent.addFail().addError(0, "parse error").flush()
                    getConfigSuccessOrFailMonitor
                        .setMonitorCode(MonitorCodeUploadInfoChecker.get_config_fail)
                        .setResultTypeFail()
                        .timing()
                        .flush()
                    return
                }
                
                //  异常排查，后端反馈下发了数据但是端上没搜到
                UploadInfoChecker.logger.info("fetchUploadInfo success and data is", additionalData: [
                    "config.location.status": "\(config.location?.status)",
                    "config.location.geofences.isempty": "\(config.location?.geofences?.isEmpty)",
                    "config.location.geofences.circle.isempty": "\(config.location?.geofences?.filter { $0.type == .circle }.isEmpty)",
                    "config.wifi.status": "\(config.wifi?.status)",
                    "config.rule_snapshot_id": "\(config.rule_snapshot_id)"
                ])

                UploadInfoChecker.logger.debug("getUploadInfoConfig success:\(config)")
                monitorEvent.addDuration().addSuccess().flush()
                getConfigSuccessOrFailMonitor
                    .setMonitorCode(MonitorCodeUploadInfoChecker.get_config_success)
                    .setResultTypeSuccess()
                    .timing()
                    .setLocationSwitch(config.location?.status ?? false)
                    .setWifiSwitch(config.wifi?.status ?? false)
                    .flush()
                if config.location == nil, config.wifi == nil {
                    UploadInfoChecker.logger.info("cache getUploadInfoConfig fail, location and wifi is nil")
                    return
                }
                //  进行内存缓存
                self.config = config
                self.judgeStartMonitorNetwork(config: config)
                success(config)
            }, onError: { [weak self] (error) in
                UploadInfoChecker.logger.error("getUploadInfoConfig error:\(error.localizedDescription)")
                monitorEvent.setSnapshotId(self?.config?.rule_snapshot_id)
                monitorEvent.addFail().addError((error as NSError).code, "\(error.localizedDescription)").flush()
                getConfigSuccessOrFailMonitor
                    .setMonitorCode(MonitorCodeUploadInfoChecker.get_config_fail)
                    .setResultTypeFail()
                    .timing()
                getConfigSuccessOrFailMonitor.setSnapshotId(self?.config?.rule_snapshot_id)
                    .flush()
                failure(error)
            }).disposed(by: self.disposeBag)

    }

    //  如果config的字段有wifi.status，则开启wifiChecker，否则关掉 FIXME：不建议端上耦合重业务逻辑，灵活的业务下沉到后端
    private func judgeStartMonitorNetwork(config: UploadInfoConfig) {
        UploadInfoChecker.logger.info("judgeStartMonitorNetwork")
        if config.wifi?.status == true {
            wifiChecker.stop()
            UploadInfoChecker.logger.info("start check wifi")
            wifiChecker.start { [weak self] (wifiInfo) in
                guard let `self` = self else { return }
                UploadInfoChecker.logger.info("wifi status changed")
                OPMonitor(name: uploadInfoCheckerEvent, code: MonitorCodeUploadInfoChecker.trigger_start)
                    .setTriggerType(.network_change)
                    .setSnapshotId(config.rule_snapshot_id)
                    .flush()
                self.trycheck(config: config, wifiInfo: wifiInfo, triggerType: .network_change)
            }
        } else {
            UploadInfoChecker.logger.info("stop check wifi")
            wifiChecker.stop()
        }
    }

    private var isChecking = false // 避免同一时间重复上传
    private func trycheck(config: UploadInfoConfig, wifiInfo: WIFIInfo?, triggerType: TriggerType) {
        //  这个函数的唯一目的是为了避免重复check
        UploadInfoChecker.logger.info("begin check wifiinfo isChecking:\(isChecking) config: applicationState:\(UIApplication.shared.applicationState == .background)")
        // 避免同一时间重复上传
        if isChecking {
            return
        }
        isChecking = true
        check(triggerType: triggerType, config: config, wifiInfo: wifiInfo) { [weak self] in
            self?.isChecking = false
        }
    }
    private func check(triggerType: TriggerType,
                       config: UploadInfoConfig,
                       wifiInfo: WIFIInfo?,
                       completion: @escaping () -> Void) {
        //  TODO：考虑把check的灵活逻辑挪到后端，端上不耦合重逻辑
        OPMonitor(name: uploadInfoCheckerEvent, code: MonitorCodeUploadInfoChecker.get_terminal_info_start)
            .setTriggerType(triggerType)
            .setLocationSwitch(config.location?.status ?? false)
            .setWifiSwitch(config.wifi?.status ?? false)
            .setSnapshotId(config.rule_snapshot_id)
            .flush()

        let getTerminalInfoFinishMonitor = OPMonitor(name: uploadInfoCheckerEvent, code: MonitorCodeUploadInfoChecker.get_terminal_info_finish)
            .setTriggerType(triggerType)
            .setLocationSwitch(config.location?.status ?? false)
            .setWifiSwitch(config.wifi?.status ?? false)
            .setSnapshotId(config.rule_snapshot_id)

        self.getWifiInfo(wifi: config.wifi, info: wifiInfo) { updateWifiInfo in
            self.locationChecker.checkLocation(location: config.location) { [weak self] locationInfo, inScope in
                let hasWifi = wifiInfo?.hasWifi ?? false
                let hasLastWifi = wifiInfo?.hasLastWifi ?? false
                let hasLocation = locationInfo != nil
                getTerminalInfoFinishMonitor
                    .setHasWifi(hasWifi)
                    .setHasLastWifi(hasLastWifi)
                    .setHasLocation(hasLocation)
                    .setInScope(inScope)
                    .flush()
                self?.upload(locationInfo: locationInfo, wifiInfo: updateWifiInfo, triggerType: triggerType, locationSwitch: config.location?.status ?? false, wifiSwitch: config.wifi?.status ?? false, hasWifi: hasWifi, hasLastWifi: hasLastWifi, hasLocation: hasLocation, inScope: inScope, completion: completion)
            }
        }
    }
    
    private func getWifiInfo(wifi: Wifi?, info: WIFIInfo?, completion: @escaping (WIFIInfo?) -> Void) {
        guard LocationChecker.requestLocationEnabled() else {
            Self.logger.error("not allow bgLocaiton getWifiInfo fail!")
            completion(nil)
            return
        }
        guard !FeatureGatingManager.shared.featureGatingValue(with: "attendance.top_speed_clock_in.forbid_bssid") else {// user:global
            UploadInfoChecker.logger.error("forbid wifi clockin")
            completion(nil)
            return
        }
        guard let wifi = wifi, wifi.status else {
            let monitorEvent = MonitorEvent(name: MonitorEvent.terminalinfo_wifi)
            monitorEvent.setSnapshotId(config?.rule_snapshot_id)
            monitorEvent.addFail().addError(1, "wifi status closed").flush()
            completion(nil)
            return
        }
        wifiChecker.getWifiInfo(completion: completion)
    }

    private func upload(locationInfo: LocationInfo?,
                        wifiInfo: WIFIInfo?,
                        triggerType: TriggerType,
                        locationSwitch: Bool,
                        wifiSwitch: Bool,
                        hasWifi: Bool,
                        hasLastWifi: Bool,
                        hasLocation: Bool,
                        inScope: Bool,
                        completion: @escaping () -> Void) {
        
        if !resolver.fg.dynamicFeatureGatingValue(with: "openplatform.user_scope_compatible_disable") {
            guard AccountServiceAdapter.shared.isLogin else {
                completion()
                UploadInfoChecker.logger.info("not launched or not login")
                return
            }
        }
        
        //  FIXME：不要耦合这几个判断
        if locationInfo == nil && wifiInfo == nil {
            completion()
            UploadInfoChecker.logger.info("null to upload")
            return
        }
        OPMonitor(name: uploadInfoCheckerEvent, code: MonitorCodeUploadInfoChecker.upload_info_start)
            .setTriggerType(triggerType)
            .setLocationSwitch(locationSwitch)
            .setWifiSwitch(wifiSwitch)
            .setHasWifi(hasWifi)
            .setHasLastWifi(hasLastWifi)
            .setHasLocation(hasLocation)
            .setInScope(inScope)
            .setSnapshotId(config?.rule_snapshot_id)
            .flush()
        var locationJson: Any?
        if let location = locationInfo,
            let data = try? JSONEncoder().encode(location),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            locationJson = json
        }
        var wifiJson: Any?
        if let wifi = wifiInfo,
            let data = try? JSONEncoder().encode(wifi),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            wifiJson = json
        }
        let timestamp = String(currentNTPTime())
        let monitorEvent = MonitorEvent(name: MonitorEvent.terminalinfo_upload_result)
        monitorEvent.setSnapshotId(config?.rule_snapshot_id)
        let client = try? resolver.resolve(assert: OpenPlatformHttpClient.self)
        var did: String = ""
        if let opService: OpenPlatformService = try? resolver.resolve(assert: OpenPlatformService.self) {
            did = opService.getOpenPlatformDeviceID()
        }
        let api = OpenPlatformAPI.TerminalUploadAPI(location: locationJson, wifi: wifiJson, timestamp: timestamp, did: did, resolver: resolver)
        UploadInfoChecker.logger.info("start uploadArriveLocationInfo \(timestamp)")
        let uploadInfoSuccessOrFailMonitor = OPMonitor(uploadInfoCheckerEvent)
            .setTriggerType(triggerType)
            .setLocationSwitch(locationSwitch)
            .setWifiSwitch(wifiSwitch)
            .setHasWifi(hasWifi)
            .setHasLastWifi(hasLastWifi)
            .setHasLocation(hasLocation)
            .setInScope(inScope)
            .timing()
            .setSnapshotId(config?.rule_snapshot_id)
        client?.request(api: api)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (_) in
                UploadInfoChecker.logger.debug("uploadArriveLocationInfo success: \(timestamp)")
                monitorEvent.addDuration().addSuccess().flush()
                uploadInfoSuccessOrFailMonitor
                    .setMonitorCode(MonitorCodeUploadInfoChecker.upload_info_success)
                    .setResultTypeSuccess()
                    .timing()
                    .flush()
                completion()
            }, onError: { (error) in
                UploadInfoChecker.logger.error("uploadArriveLocationInfo error:\(error.localizedDescription)")
                monitorEvent.addFail().addError((error as NSError).code, "\(error.localizedDescription)").flush()
                uploadInfoSuccessOrFailMonitor
                    .setMonitorCode(MonitorCodeUploadInfoChecker.upload_info_fail)
                    .setResultTypeFail()
                    .timing()
                    .flush()
                completion()
            }).disposed(by: self.disposeBag)
    }

    // 当前时间戳 ms
    private func currentNTPTime() -> Int64 {
        if let service = try? resolver.resolve(assert: ServerNTPTimeService.self) {
            return service.serverTime * 1000
        } else {
            return Int64(Date().timeIntervalSince1970) * 1000
        }
    }
}
// swiftlint:enable all
