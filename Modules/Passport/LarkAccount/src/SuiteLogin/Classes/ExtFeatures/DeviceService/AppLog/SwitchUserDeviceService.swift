//
//  SwitchUserDeviceService.swift
//  LarkAccount
//
//  Created by bytedance on 2022/8/11.
//

import Foundation
import LarkAccountInterface
import LKCommonsLogging
import RxSwift
import LarkAppLog
import RangersAppLog

protocol SwitchUserDeviceServiceProtocol {
    
    func fetchDeviceId(_ callback: @escaping (DeviceInfoFetchResult) -> Void)
    
    func getDidHost() -> String?

}

class SwitchUserDeviceService: SwitchUserDeviceServiceProtocol {

    static let logger = Logger.plog(RangersAppLogDeviceServiceImpl.self, category: "SwitchUserDeviceService")

    //deviceInfoStore 不是单例
    private var store: DeviceInfoStore = RangersAppLogDeviceServiceImpl.shared.store

    internal let unit: String

    lazy var deviceInfoReplay: PublishSubject<Result<DeviceInfoTuple, Error>> = {
        PublishSubject()
    }()

    let disposeBag = DisposeBag()

    init(unit: String) {
        self.unit = unit
        observerDidChange()
    }

    func fetchDeviceId(_ callback: @escaping (DeviceInfoFetchResult) -> Void) {
        if let deviceId = self.store.getDeviceID(unit: unit),
           let installId = self.store.getInstallID(unit: unit),
           DeviceInfo.isDeviceIDValid(deviceId),
           DeviceInfo.isInstallIDValid(installId) {
            V3LoginService.logger.info("n_action_switch_fetch_did_local", additionalData: ["did": deviceId, "iid": installId, "unit": unit], method: .local)
            callback(.success((deviceId, installId)))
            return
        }
        Self.logger.info("n_action_switch_fetch_remote_did_start")

        deviceInfoReplay
            .asObservable()
            .take(1)
            .map({ [weak self] (result) -> DeviceInfoTuple in
                switch result {
                case .success(let deviceInfo):
                    return deviceInfo
                case .failure(let error):
                    throw error
                }
            })
            .timeout(.seconds(60), scheduler: MainScheduler.instance)
            .subscribe(onNext: { (args) in
                Self.logger.info("n_action_switch_fetch_remote_did_succ")
                SuiteLoginUtil.runOnMain {
                    callback(.success(args))
                }
            }, onError: { (error) in
                AppLogDeviceServiceMonitor.fetchDidFailure(error)
                Self.logger.error("n_action_switch_fetch_remote_did_fail", error: error)
                SuiteLoginUtil.runOnMain {
                    if case RxError.timeout = error {
                        // “请求超时”
                        callback(.failure(V3LoginError.fetchDeviceIDFail(I18N.Lark_Login_NumberDetectOverTimePopupTitle)))
                    } else {
                        callback(.failure(V3LoginError.badServerData))
                    }
                }
            }).disposed(by: disposeBag)

            //发起did获取
            LarkAppLog.shared.sendRegisterRequest()
    }

    enum AppLogError: Error {
        case appLogError([AnyHashable: Any])
        case appLogInvalidData([AnyHashable: Any])
        case localInvalidData([AnyHashable: Any])
    }

    func getDidHost() -> String? {
        store.getDidHost(unit: unit)
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
                    Self.logger.info("Register device from localCache with userInfo", additionalData: [
                        "did": rdid ?? "Empty did",
                        "iid": riid ?? "Empty iid"
                    ])
                    return
                }

                guard let userInfoURLString = noti.userInfo?[kBDAutoTrackNotificationDataSourceURL] as? String,
                      let userInfoHost = URL(string: userInfoURLString)?.host else {
                          Self.logger.error("Device register did not return URL",
                                            additionalData: ["infoSource": (noti.userInfo?[kBDAutoTrackNotificationDataSourceURL] as? String ?? "")])
                          return
                      }

                var needPushResult = false

                if let rawCurrentHost = self.store.getDidHost(unit: self.unit),
                   self.dropProtocolPrefix(rawCurrentHost) == userInfoHost {
                    // 当服务端返回的 host 和当前环境 host 匹配时才发信号
                    needPushResult = true
                }

                // 判断did合法
                guard let did = rdid,
                      let iid = riid,
                      DeviceInfo.isDeviceIDValid(did) else {
                    Self.logger.error("n_action_switch_fetch_did_recive_invalid_did")
                    self.deviceInfoReplay.onNext(.failure(AppLogError.appLogInvalidData(noti.userInfo ?? [:])))
                    return
                }
                //更新did，iid 到deviceStore
                self.store.set(deviceID: did, installID: iid, with: userInfoHost)

                //check 一下缓存中取出的值是否正确
                if let returnDid = self.store.getDeviceID(unit: self.unit),
                   let returnIiD = self.store.getInstallID(unit: self.unit),
                   DeviceInfo.isDeviceIDValid(returnDid) {

                    // 从服务端返回的 device ID 做 host 比对
                    Self.logger.info("n_action_switch_fetch_did_return_value", additionalData: [
                        "did": returnDid,
                        "iid": returnIiD
                    ])

                    if needPushResult { self.deviceInfoReplay.onNext(.success(DeviceInfoTuple(returnDid, returnIiD))) }
                } else {
                    Self.logger.error("n_action_switch_fetch_cache_did_fail")
                    if needPushResult { self.deviceInfoReplay.onNext(.failure(AppLogError.appLogInvalidData(noti.userInfo ?? [:]))) }
                }
            })
            .disposed(by: disposeBag)

        NotificationCenter
            .default
            .rx
            .notification(Notification.Name(rawValue: BDAutoTrackNotificationRegisterFailure))
            .subscribe(onNext: { [weak self] noti in
                guard let self = self else { return }
                Self.logger.error("n_action_switch_fetch_did_receive_fail_notification")
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
}

