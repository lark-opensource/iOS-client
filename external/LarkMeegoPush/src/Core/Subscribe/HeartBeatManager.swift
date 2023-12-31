//
//  HeartBeatManager.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/13.
//

import Foundation
import LarkMeegoNetClient
import LarkMeegoLogger
import LKCommonsTracker
import LarkContainer
import UIKit

class HeartBeatManager: NSObject {
    override init() {
        super.init()
        addLifeCycleNotification()
    }

    deinit {
        removeLifeCycleNotification()
    }

    static let shared = HeartBeatManager()

    var currentDeviceIdentification: String?

    var isLoginStatusSynced = false
    var isGetHeartBeatIdentityRunning = false
    var isHeartBeatRunning = false

    private var pollingTimer: RepeatingTimer?

    // identity失效时，重新拉取
    func checkHeartBeatIdentityIfNeed(stopRetry stopRetry: Bool = false) {
        if isGetHeartBeatIdentityRunning == false {
            isGetHeartBeatIdentityRunning = true
            /// 如果尚未同步登录状态，先同步登录状态
            /// 登录登出状态同步 https://bytedance.feishu.cn/wiki/wikcnBEdSxy384mDlX6xqFZWIMg
            if isLoginStatusSynced == false {
                MeegoLogger.debug("send pushInfoReport request")
                pushInfoReport(catchError: true) { [weak self] result in
                    switch result {
                    case .success(let response):
                        if response.code != 0 {
                            MeegoLogger.error("pushInfoReport fail with biz err code:\(response.code)")
                            self?.trackHeartBeatResult(success: false,
                                                       bizCode: response.code,
                                                       errMsg: response.msg)
                            return
                        }

                        MeegoLogger.info("pushInfoReport success")
                        self?.trackDeviceReportResult(success: true,
                                                      bizCode: response.code)

                        self?.isLoginStatusSynced = true
                        self?.checkHeartBeatIdentity(stopRetry: stopRetry)
                    case .failure(let apiError):
                        MeegoLogger.error("pushInfoReport fail with http code:\(apiError.httpStatusCode) errorMsg:\(apiError.errorMsg) logId:\(apiError.logId)")
                        self?.trackDeviceReportResult(success: false,
                                                      bizCode: apiError.httpStatusCode ?? -1,
                                                      traceId: apiError.logId,
                                                      errMsg: apiError.errorMsg)

                        self?.isGetHeartBeatIdentityRunning = false
                    }
                }
            } else {
                checkHeartBeatIdentity(stopRetry: stopRetry)
            }
        }
    }

    func startHeartBeat() {
        MeegoLogger.debug("startHeartBeat..")
        if isHeartBeatRunning == false {
            isHeartBeatRunning = true
            if pollingTimer == nil {
                pollingTimer = RepeatingTimer(timeInterval: 2 * 60 + 50)
                pollingTimer?.eventHandler = { [weak self] in
                    // 正在主动检测，可跳过此次心跳{
                    guard let self = self else { return }

                    if self.isGetHeartBeatIdentityRunning {
                        return
                    }
                    // 心跳检测
                    MeegoLogger.info("send getHeartBeatIdentity request..")
                    self.getHeartBeatIdentity(catchError: true) { [weak self] result in
                        guard let self = self else { return }

                        switch result {
                        case .success(let response):
                            if response.code != 0 {
                                MeegoLogger.error("getHeartBeatIdentity with biz err code:\(response.code)")
                                return
                            }
                            guard let deviceIdentification = response.data?.deviceIdentification,
                                  !deviceIdentification.isEmpty else {
                                MeegoLogger.error("getHeartBeatIdentity with empty deviceIdentification")
                                return
                            }

                            // 如果本地当前deviceIdentification失效 => 重新上报所有订阅
                            if self.currentDeviceIdentification != deviceIdentification {
                                // 更新本地currentDeviceIdentification
                                MeegoLogger.info("Update current deviceIdentification:\(deviceIdentification). Trigger afreshSubscribe.")

                                self.currentDeviceIdentification = deviceIdentification
                                SubscribeManager.shared.afreshSubscribe()
                            }
                        case .failure(let error):
                            MeegoLogger.error("getHeartBeatIdentity error: \(error.localizedDescription)")
                            return
                        }
                    }
                }
            }
            pollingTimer?.resume()
        }
    }

    func stopHeartBeat() {
        MeegoLogger.info("stopHeartBeat..")
        if isHeartBeatRunning == false {
            return
        }
        pollingTimer?.suspend()
        pollingTimer = nil
        isHeartBeatRunning = false
    }

    func isIdentificationValid() -> Bool {
        return currentDeviceIdentification != nil
    }
}

private extension HeartBeatManager {
    func checkHeartBeatIdentity(stopRetry stopRetry: Bool = false) {
        MeegoLogger.info("send getHeartBeatIdentity request")
        currentDeviceIdentification = nil
        getHeartBeatIdentity(catchError: false) { [weak self] result in
            self?.isGetHeartBeatIdentityRunning = false

            switch result {
            case .success(let response):
                if response.code != 0 {
                    MeegoLogger.error("getHeartBeatIdentity with biz errCode \(response.msg) errMsg: \(response.msg)")
                    self?.trackHeartBeatResult(success: false,
                                               bizCode: response.code,
                                               errMsg: response.msg)
                    return
                }

                guard let deviceIdentification = response.data?.deviceIdentification,
                      !deviceIdentification.isEmpty else {
                    MeegoLogger.error("getHeartBeatIdentity with deviceIdentification is empty")
                    self?.trackHeartBeatResult(success: false,
                                               bizCode: response.code,
                                               errMsg: response.msg)
                    return
                }

                MeegoLogger.info("getHeartBeatIdentity success.deviceIdentification: \(deviceIdentification) ")
                self?.trackHeartBeatResult(success: true,
                                           bizCode: response.code)

                self?.currentDeviceIdentification = deviceIdentification
                SubscribeManager.shared.afreshSubscribe(with: stopRetry)
                // log
            case .failure(let apiError):
                MeegoLogger.error("getHeartBeatIdentity fail http code \(apiError.httpStatusCode) errorMsg:\(apiError.errorMsg) logId:\(apiError.logId)")
                self?.trackHeartBeatResult(success: false,
                                           bizCode: apiError.httpStatusCode ?? -1,
                                           errMsg: apiError.errorMsg)
            }
        }
    }

    func getHeartBeatIdentity(catchError: Bool,
                              completionHandler: @escaping (Result<Response<HeartbeatResponse>, APIError>) -> Void) {
        let request = HeartbeatRequest(catchError: catchError, deviceIdentification: currentDeviceIdentification ?? "")

        if let netClient = try? Container.shared.getCurrentUserResolver().resolve(type: MeegoNetClient.self) {
            netClient.sendRequest(request, completionHandler: completionHandler)
        }
    }

    // 上报设备信息
    func pushInfoReport(catchError: Bool,
                        completionHandler: @escaping (Result<Response<EmptyDataResponse>, APIError>) -> Void) {
        let request = LoginReportRequest(catchError: catchError, loginStatus: true)

        if let netClient = try? Container.shared.getCurrentUserResolver().resolve(type: MeegoNetClient.self) {
            netClient.sendRequest(request, completionHandler: completionHandler)
        }
    }

    // 埋点
    func trackHeartBeatResult(success: Bool, bizCode: Int, traceId: String? = nil, errMsg: String? = nil) {
        let slardarEvent = SlardarEvent(
            name: "meego_push_heart_beat",
            metric: [:],
            category: [
                "success": success,
                "biz_code": bizCode
            ],
            extra: success ? [:] : ["trace_id": traceId ?? "", "error_msg": errMsg ?? ""]
        )
        Tracker.post(slardarEvent)
    }

    func trackDeviceReportResult(success: Bool, bizCode: Int, traceId: String? = nil, errMsg: String? = nil) {
        let slardarEvent = SlardarEvent(
            name: "meego_push_device_report",
            metric: [:],
            category: [
                "success": success,
                "biz_code": bizCode
            ],
            extra: success ? [:] : ["trace_id": traceId ?? "", "error_msg": errMsg ?? ""]
        )
        Tracker.post(slardarEvent)
    }
}

// Mark - LifeCycle
private extension HeartBeatManager {
    func addLifeCycleNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).appDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).appDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func removeLifeCycleNotification() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    @objc
    public func appDidBecomeActive(_ notify: NSNotification) {
        MeegoLogger.debug("[HeartBeatManager] appDidBecomeActive")
        SubscribeManager.shared.afreshSubscribe()
    }

    @objc
    public func appDidEnterBackground(_ notify: NSNotification) {
        MeegoLogger.debug("[HeartBeatManager] appDidEnterBackground")
        HeartBeatManager.shared.stopHeartBeat()
    }
}
