//
//  PassportUniversalDeviceService.swift
//  LarkAccount
//
//  Created by ByteDance on 2023/1/6.
//

import Foundation
import RxSwift
import RangersAppLog
import LKCommonsLogging
import LarkAccountInterface
import RxRelay
import LarkAppLog
import ECOProbeMeta

class PassportUniversalDeviceService {
    
    public static let shared = PassportUniversalDeviceService()
    
    static let logger = Logger.log(PassportUniversalDeviceService.self, category: "PassportUniversalDeviceService")
    
    lazy var deviceInfoReplay: PublishSubject<Result<DeviceInfoTuple, Error>> = {
        PublishSubject()
    }()
    
    let disposeBag = DisposeBag()
    
    let serverInfoProvider = ServerInfoProvider()
    
    private lazy var deviceInfoVariable: BehaviorRelay<DeviceInfo?> = {
        return BehaviorRelay(value: deviceInfo)
    }()
    
    init() {
        observerDidChange()
    }
    
    func makeCurrentDeviceInfoUniversal(_ did: String, _ iid: String) {
        PassportStore.shared.deviceID = did
        PassportStore.shared.installID = iid
    }
    
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
                    Self.logger.info("Register device from localCache with userInfo", additionalData: [
                        "did": rdid ?? "Empty did",
                        "iid": riid ?? "Empty iid"
                    ])
                    return
                }
                
                guard let applogURLString = noti.userInfo?[kBDAutoTrackNotificationDataSourceURL] as? String,
                      let applogHost = URL(string: applogURLString)?.host else {
                    Self.logger.error("Device register did not return URL",
                                      additionalData: ["infoSource": (noti.userInfo?[kBDAutoTrackNotificationDataSourceURL] as? String ?? "")])
                    return
                }
                
                //是否是包unit
                var isPackageDeviceInfoResponse = false
                
                if let rawCurrentHost = self.getDidHost(),
                   self.dropProtocolPrefix(rawCurrentHost) == applogHost {
                    // 当服务端返回的 host 和当前环境 host 匹配时才发信号
                    isPackageDeviceInfoResponse = true
                }
                
                // 判断did, iid 合法
                guard let applogDid = rdid,
                      let applogIid = riid,
                      DeviceInfo.isDeviceIDValid(applogDid),
                      DeviceInfo.isInstallIDValid(applogIid) else {
                    Self.logger.error("n_actio_uni_did_recive_invalid_did")
                    //包域名的did获取才需要push error
                    if isPackageDeviceInfoResponse {
                        self.deviceInfoReplay.onNext(.failure(AppLogError.appLogInvalidData(noti.userInfo ?? [:])))
                    }
                    return
                }
                
                //非包环境的设备信息返回，只能更新IID
                guard isPackageDeviceInfoResponse else {
                    //不是包域名的did获取，判断如果did一致，更新iid
                    if PassportStore.shared.deviceID == applogDid,
                       DeviceInfo.isInstallIDValid(applogIid),
                       PassportStore.shared.installID != applogIid {
                        
                        //更新iid
                        PassportStore.shared.installID = applogIid
                    }
                    return
                }
                
                //本地是否已经有统一did
                if let localDid = PassportStore.shared.deviceID,
                   DeviceInfo.isDeviceIDValid(localDid) {
                    //本地已经有统一did
                    Self.logger.info("n_action_uni_did_service_already_had_did")
                    
                    if localDid != applogDid {
                        //did 发生了变化，上报监控
                        PassportMonitor.flush(EPMClientPassportMonitorUniversalDidCode.passport_uni_did_not_match_cache,
                                                  eventName: ProbeConst.monitorEventName,
                                                  categoryValueMap: ["local": localDid,
                                                                     "new": applogDid,
                                                                     "type": 2],
                                                  context: UniContextCreator.create(.unknown))
        
                        //如果 did 发生了变化, iid也不能同步更新, 不处理
                        Self.logger.error("n_action_uni_did_not_match_local")
                    
                    } else if DeviceInfo.isInstallIDValid(applogIid),
                              PassportStore.shared.installID != applogIid {
                        //did一致，iid发生了变化，更新iid
                        PassportStore.shared.installID = applogIid
                        Self.logger.info("n_action_uni_did_update_iid", body: applogIid)
                    }
                    
                } else {
                    //本地没有did，只有包unit的did获取，才可以是统一did
                    PassportStore.shared.deviceID = applogDid
                    //更新did后，同步更新iid
                    PassportStore.shared.installID = applogIid
                    Self.logger.info("n_action_uni_did_set_did_iid", body: applogDid + "&" + applogIid)
                }
                
                //check 一下缓存中取出的值是否正确
                if let returnDid = PassportStore.shared.deviceID,
                   let returnIiD = PassportStore.shared.installID,
                   DeviceInfo.isDeviceIDValid(returnDid),
                   DeviceInfo.isInstallIDValid(returnIiD){
                    
                    // 从服务端返回的 device ID 做 host 比对
                    Self.logger.info("n_action_uni_did_return_value", additionalData: [
                        "did": returnDid,
                        "iid": returnIiD
                    ])
                    
                    self.deviceInfoReplay.onNext(.success(DeviceInfoTuple(returnDid, returnIiD)))
                    self.deviceInfoVariable.accept(self.deviceInfo)
                } else {
                    Self.logger.error("n_action_uni_did_store_error")
                    self.deviceInfoReplay.onNext(.failure(AppLogError.appLogInvalidData(noti.userInfo ?? [:])))
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

                //优化获取统一did的成功率:豁免没有url的报错，等待下一次推送 https://bytedance.feishu.cn/docx/QNddd27YsoZI2gxRrf1cm3MRnUd
                if noti.userInfo?["reason"] as? String == "requestURL is nil" {
                    Self.logger.warn("n_action_switch_fetch_did_receive_fail_notification", body: "requestURL is nil")
                } else {
                    self.deviceInfoReplay.onNext(.failure(AppLogError.appLogError(noti.userInfo ?? [:])))
                }
            })
            .disposed(by: disposeBag)
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

extension PassportUniversalDeviceService: PassportGlobalDeviceService {
    
    func getDeviceIdAndInstallId(unit: String) -> DeviceInfoTuple? {
        if let deviceId = PassportStore.shared.deviceID, let installId = PassportStore.shared.installID {
            return (deviceId, installId)
        }
        
        return nil
    }
}

extension PassportUniversalDeviceService: InternalDeviceServiceProtocol {
    
    func fetchDeviceId(_ callback: @escaping (DeviceInfoFetchResult) -> Void) {
        
        if let deviceId = PassportStore.shared.deviceID,
           let installId = PassportStore.shared.installID,
           DeviceInfo.isDeviceIDValid(deviceId),
           DeviceInfo.isInstallIDValid(installId) {
            Self.logger.info("n_action_uni_did_fetch_did_local", additionalData: ["did": deviceId, "iid": installId])
            callback(.success((deviceId, installId)))
            return
        }
        Self.logger.info("n_action_uni_did_fetch_remote_did_start")
        
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
                        callback(.failure(error))
                    }
                }
            }).disposed(by: disposeBag)
        
        //获取包环境的applog域名配置
        if let applogDomain = getDidHost() {
            //更新applog配置
            AppLogIntegrator.updateAppLogForUniDid(with: applogDomain)
            
            //发起did获取
            LarkAppLog.shared.sendRegisterRequest()
        } else {
            callback(.failure(V3LoginError.fetchDeviceIDFail("no applog domain")))
        }
    }
    
    func fetchDeviceIDMap() -> [String : String]? {
        return nil
    }
    
    func universalDeviceID() -> String? {
        return PassportStore.shared.deviceID
    }
    
    func reset() {
        Self.logger.info("n_action_uni_did_reset")
        PassportStore.shared.deviceID = nil
        PassportStore.shared.installID = nil
    }
    
    func updateDeviceLoginId(_ deviceLoginId: String?) {
        //保持跟旧逻辑一致
        DeviceInfoStore().deviceLoginId = deviceLoginId
    }
    
    func cacheDeviceIDUnit(_ unit: String, with host: String) {
        //统一did不需要
    }
    
    var deviceInfo: LarkAccountInterface.DeviceInfo {
        let did = PassportStore.shared.deviceID ?? ""
        let iid = PassportStore.shared.installID ?? ""
        let deviceloginId = UserManager.shared.foregroundUser?.deviceLoginID ?? DeviceInfo.emptyValue // user:current
        
        return DeviceInfo(deviceId: did,
                          installId: iid,
                          deviceLoginId: deviceloginId,
                          isValidDeviceID: DeviceInfo.isDeviceIDValid(did),
                          isValid: DeviceInfo.isDeviceIDValid(did) && DeviceInfo.isInstallIDValid(iid))
    }
    
    var deviceInfoObservable: Observable<DeviceInfo?> {
        return deviceInfoVariable.asObservable().distinctUntilChanged { (old, new) -> Bool in
            return old?.deviceId == new?.deviceId &&
            old?.installId == new?.installId &&
            old?.deviceLoginId == new?.deviceLoginId
        }
    }
}

extension PassportUniversalDeviceService: SwitchUserDeviceServiceProtocol {
    
    func getDidHost() -> String? {
        return serverInfoProvider.getDomain(.ttApplogUsingPackageDomain).value
    }
}
