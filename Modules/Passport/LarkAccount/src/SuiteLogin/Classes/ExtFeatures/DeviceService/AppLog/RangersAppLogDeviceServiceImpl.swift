//
//  BDDeviceServiceImpl.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/10/20.
//

import Foundation
import RxSwift
import LarkContainer
import RxRelay
import LarkAccountInterface
import RangersAppLog
import LKCommonsLogging
import LarkAppLog
import LarkReleaseConfig
import ECOProbe
import LarkEnv

public extension Foundation.Notification {
    static let getDeviceIdSuccessKey = "deviceId"
    static let getDeviceIdSuccess = NSNotification.Name(rawValue: "getDeviceIdSuccess")
}

public final class RangersAppLogDeviceServiceImpl: InternalDeviceServiceProtocol, PassportGlobalDeviceService {

    public static let shared = RangersAppLogDeviceServiceImpl()
    static let logger = Logger.plog(RangersAppLogDeviceServiceImpl.self, category: "SuiteLogin.RangersAppLog")

    static var hasSetupAppLog: Bool = false

    @Provider var setDeviceInfoAPI: SetDeviceInfoAPI // user:checked (global-resolve)

    var store: DeviceInfoStore

    public var deviceInfoObservable: Observable<DeviceInfo?> {
        return store.deviceInfoObservable
    }

    public var deviceInfo: DeviceInfo {
        store.deviceInfo
    }

    func reset() {
        Self.logger.error("n_action_legacy_did_reset")
        store.reset()
        LarkAppLog.shared.clearCache()
    }

    /// deviceLoginID 从前台用户数据中直接获取，一般情况下不需要单独更新，使用时请注意判断
    func updateDeviceLoginId(_ deviceLoginId: String?) {
        store.deviceLoginId = deviceLoginId
    }

    private init() {
        store = DeviceInfoStore()
        observerDidChange()
    }

    func assertInitialize() {
        assert(Self.hasSetupAppLog, "must setup app log")
    }

    func fetchDeviceIDMap() -> [String: String]? {
        return store.deviceIdMap
    }
    
    func universalDeviceID() -> String? {
        return nil
    }

    func fetchDeviceId(_ callback: @escaping (DeviceInfoFetchResult) -> Void) {
        if let deviceId = self.store.deviceId,
           let installId = self.store.installId,
           DeviceInfo.isDeviceIDValid(deviceId),
           DeviceInfo.isInstallIDValid(installId) {
            V3LoginService.logger.info("fetch local deviceId", additionalData: ["did": deviceId, "iid": installId], method: .local)
            self.store.deviceInfoUpdated()
            callback(.success((deviceId, installId)))
            return
        }
        Self.logger.info("start fetch device id", method: .local)
        deviceInfoReplay
            .asObservable()
            .take(1)
            .map({ (result) -> DeviceInfoTuple in
                switch result {
                case .success:
                    ///  只判断did合法
                    if let did = self.store.deviceId,
                       let iid = self.store.installId,
                       DeviceInfo.isDeviceIDValid(did) {
                        Self.logger.info("fetch device id valid deviceId: \(did) installId: \(iid)")
                        self.store.deviceInfoUpdated()
                        return (did, iid)
                    } else {
                        let didText = self.store.deviceId ?? "empty"
                        let iidText = self.store.installId ?? "empty"
                        let additionalData = [
                            "did": didText,
                            "iid": iidText
                        ]
                        Self.logger.error("fetch device id local data invalid", additionalData: additionalData)
                        throw AppLogError.localInvalidData(additionalData)
                    }
                case .failure(let error):
                    Self.logger.error("fetch device id applog internal error", error: error)
                    throw error
                }
            })
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .subscribe(onNext: { (args) in
                AppLogDeviceServiceMonitor.fetchDidSuccess()
                Self.logger.info("fetch device on next", method: .local)
                SuiteLoginUtil.runOnMain {
                    callback(.success(args))
                }

                //监控
                PassportMonitor.monitor(PassportMonitorMetaCommon.getDeviceIDResult,
                                        categoryValueMap: [ProbeConst.duration: ProbeDurationHelper.stopDuration(CommonMonitorDurationFlow.fetchDeviceId.rawValue)],
                                        context: UniContext(.unknown)).setResultTypeSuccess().flush()

            }, onError: { (error) in
                AppLogDeviceServiceMonitor.fetchDidFailure(error)
                Self.logger.error("fetch device on error", error: error)
                SuiteLoginUtil.runOnMain {
                    if case RxError.timeout = error {
                        // “请求超时”
                        callback(.failure(V3LoginError.fetchDeviceIDFail(I18N.Lark_Login_NumberDetectOverTimePopupTitle)))
                    } else {
                        callback(.failure(V3LoginError.badServerData))
                    }
                    //监控
                    PassportMonitor.monitor(PassportMonitorMetaCommon.getDeviceIDResult,
                                            categoryValueMap: ["env": EnvManager.env.description],
                                            context: UniContext(.unknown))
                                            .setPassportErrorParams(error: error)
                                            .setResultTypeFail()
                                            .flush()
                }
            }, onCompleted: {
                Self.logger.info("fetch device on complete", method: .local)
            }).disposed(by: disposeBag)
            LarkAppLog.shared.sendRegisterRequest()

        //监控
        ProbeDurationHelper.startDuration(CommonMonitorDurationFlow.fetchDeviceId.rawValue)
        PassportMonitor.delayFlush(PassportMonitorMetaCommon.getDeviceIDStart, context: UniContext(.unknown))
    }

    // MARK: AppLog

    let disposeBag = DisposeBag()
    lazy var deviceInfoReplay: PublishSubject<Result<Void, Error>> = {
        PublishSubject()
    }()

    enum AppLogError: Error {
        case appLogError([AnyHashable: Any])
        case appLogInvalidData([AnyHashable: Any])
        case localInvalidData([AnyHashable: Any])
    }

    func observerDidChange() {
        NotificationCenter
            .default
            .rx
            .notification(Notification.Name(rawValue: BDAutoTrackNotificationRegisterSuccess))
            .subscribe(onNext: { [weak self] noti in
                guard let self = self else { return }
                let rdid = noti.userInfo?[kBDAutoTrackNotificationRangersDeviceID] as? String
                let riid = noti.userInfo?[kBDAutoTrackNotificationInstallID] as? String
                
                let source = noti.userInfo?[kBDAutoTrackNotificationDataSource] as? String
                
                // 不再接收来自 SDK 内部缓存的 deviceID
                if source == BDAutoTrackNotificationDataSource.localCache.rawValue {
                    Self.logger.info("Register device from localCache with userInfo",
                                     additionalData: [
                                        "did": rdid ?? "Empty did",
                                        "iid": riid ?? "Empty iid"
                                     ], method: .local)
                    return
                }
                
                // 从服务端返回的 device ID 做 host 比对
                Self.logger.info("Register device from server with userInfo", additionalData: [
                    "did": rdid ?? "Empty did",
                    "iid": riid ?? "Empty iid"
                ])
                guard let userInfoURLString = noti.userInfo?[kBDAutoTrackNotificationDataSourceURL] as? String,
                      let userInfoHost = URL(string: userInfoURLString)?.host else {
                          Self.logger.error("Device register did not return URL",
                                            additionalData: ["infoSource": (noti.userInfo?[kBDAutoTrackNotificationDataSourceURL] as? String ?? "")])
                          return
                      }

                // jinjian.au: 后半部分理论上不会走到，这里为了在覆盖安装的 case 下更保险
                let rawCurrentHost = self.store.fetchCurrentHost() ?? AppLogIntegrator.fetchCurrentDeviceIDHost()
                let currentHost = self.dropProtocolPrefix(rawCurrentHost)

                if currentHost != userInfoHost {
                    // 当服务端返回的 host 和当前环境 host 不匹配时，只存储，不发送信号
                    Self.logger.info("Current host was not equal to user info host", additionalData: [
                        "currentHost": currentHost,
                        "userInfoHost": userInfoHost
                    ])
                    if let did = rdid, let iid = riid {
                        let previousDeviceID = self.store.deviceId
                        self.store.set(deviceID: did, installID: iid, with: userInfoHost)
                        Self.logger.info("Store DeviceID with user info host", additionalData: [
                            "previousDeviceID": previousDeviceID ?? "",
                            "newDeviceID": did,
                            "newInstallID": iid,
                            "userInfoHost": userInfoHost
                        ])
                    }
                    return
                }
                Self.logger.info("Receive device info from server", additionalData: [
                    "userInfo host": userInfoHost,
                    "current host": currentHost
                ])

                // 只判断did合法
                guard let did = rdid,
                      let iid = riid,
                      DeviceInfo.isDeviceIDValid(did) else {
                    Self.logger.error("Register device validate date fail")
                    self.deviceInfoReplay.onNext(.failure(AppLogError.appLogInvalidData(noti.userInfo ?? [:])))
                    return
                }
                let succeeded = self.store.set(deviceID: did, installID: iid, with: userInfoHost)
                if succeeded {
                    Self.logger.info("Register device success and update device store")
                } else {
                    Self.logger.error("Register device failed, local already had did in this unit")
                    //上报
                    if did != self.store.deviceId {
                        //did 发生了变化，上报监控
                        PassportMonitor.flush(EPMClientPassportMonitorUniversalDidCode.passport_uni_did_not_match_cache,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: ["local": self.store.deviceId,
                                                                 "new": did],
                                              context: UniContextCreator.create(.unknown))
                    }
                }
                // 无论是服务端获取新值，还是本地已经存在，发送成功信号
                self.deviceInfoReplay.onNext(.success(()))

                #if LarkAccount_APPSFLYERFRAMEWORK
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: Foundation.Notification.getDeviceIdSuccess,
                        object: nil,
                        userInfo: [Foundation.Notification.getDeviceIdSuccessKey: did]
                    )
                }
                #endif
            })
            .disposed(by: disposeBag)
        
        NotificationCenter
            .default
            .rx
            .notification(Notification.Name(rawValue: BDAutoTrackNotificationRegisterFailure))
            .subscribe(onNext: { [weak self] noti in
                guard let self = self else { return }
                Self.logger.error("Register device received failure notification!")
                self.deviceInfoReplay.onNext(.failure(AppLogError.appLogError(noti.userInfo ?? [:])))
            })
            .disposed(by: disposeBag)
    }

    func cacheDeviceIDUnit(_ unit: String, with host: String) {
        let fixedHost = dropProtocolPrefix(host)
        store.set(unit: unit, with: fixedHost)
    }

    private func dropProtocolPrefix(_ text: String) -> String {
        let http = "http://"
        let https = "https://"
        if text.hasPrefix(https) {
            return String(text.dropFirst(https.count))
        }
        if text.hasPrefix(http) {
            return String(text.dropFirst(http.count))
        }
        return text
    }
    
    public func getDeviceIdAndInstallId(unit: String) -> DeviceInfoTuple? {
        if let deviceId = PassportStore.shared.getDeviceID(unit: unit), let installId = PassportStore.shared.getInstallID(unit: unit) {
            return (deviceId, installId)
        }
        
        return nil
    }
}
