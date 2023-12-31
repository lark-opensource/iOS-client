//
//  MinutesCommonErrorToastManger.swift
//  Minutes
//
//  Created by sihuahao on 2021/10/13.
//

import Foundation
import MinutesFoundation
import Reachability
import MinutesNetwork

public struct MinutesCommonErrorToastManger {

    static let semaphore = DispatchSemaphore(value: 1)
    static var errMessage: [String: ErrorResponse] = [:]

    static let reachability: Reachability? = {
        let reachability = Reachability(hostname: "toutiao.com")
        try? reachability?.startNotifier()
        return reachability
    }()

    public static func saveMessage(_ msg: ErrorResponse, forKey key: String) {
        semaphore.wait()
        if specialList.contains(key) {
            errMessage[key] = msg
        }
        semaphore.signal()
    }

    public static func message(forKey key: String) -> ErrorResponse? {
        var msg: ErrorResponse?
        semaphore.wait()
        msg = errMessage[key]
        semaphore.signal()
        return msg
    }

    public static func removeMessage(forKey key: String) {
        semaphore.wait()
        errMessage.removeValue(forKey: key)
        semaphore.signal()
    }

    public static func errorMsgManger(result: Result<ErrorResponse, Error>, targetView: UIView?) {
        switch result {
        case .success:
            guard let newMsg = try? result.get().newMsg else {
                return
            }
            if let isShow = newMsg.isShow, let type = newMsg.type, let content = newMsg.content {
                if isShow {
                    switch type {
                    case .unknown:
                        break
                    case .alert:
                        break
                    case .toastNormal:
                        DispatchQueue.main.async {
                            MinutesToast.showTips(with: content.body ?? BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
                        }
                    case .toastSuccess:
                        DispatchQueue.main.async {
                            MinutesToast.showSuccess(with: content.body ?? BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
                        }
                    case .toastFailed:
                        DispatchQueue.main.async {
                            MinutesToast.showFailure(with: content.body ?? BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
                        }
                    case .toastInfo:
                        DispatchQueue.main.async {
                            MinutesToast.showWarning(with: content.body ?? BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
                        }
                    }
                }
            }
        case .failure:
            /// backend
            break
        }
    }

    static func backendToast(targetView: UIView?) {
        DispatchQueue.main.async {
            MinutesToast.showFailure(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, targetView: targetView)
        }
    }

    public static func internetCheck(requestInterface: String, targetView: UIView?) {
        if reachability?.connection == Reachability.Connection.none {
            /// 无需通用处理的url过滤
            if urlWhiteList.contains(requestInterface) {
                return
            }
            DispatchQueue.main.async {
                MinutesToast.showFailure(with: BundleI18n.Minutes.MMWeb_G_NoInternetConnectionTryAgainLater, targetView: targetView)
            }
        }
    }

    public static func shouldToastCheck(requestInterface: String) -> Bool {
        return !urlWhiteList.contains(requestInterface)
    }

    public static func individualInternetCheck() -> Bool {
        if reachability?.connection == Reachability.Connection.none {
            return false
        } else {
            return true
        }
    }

    static let urlWhiteList: Set<String> = [MinutesAPIPath.timelineMerge,
                                            MinutesAPIPath.audioLanguage,
                                            MinutesAPIPath.audioStatus,
                                            MinutesAPIPath.listBatchStatus,
                                            MinutesAPIPath.status]

    static let specialList: Set<String> = [MinutesAPIPath.baseInfo,
                                           MinutesAPIPath.simpleBaseInfo,
                                           MinutesAPIPath.status,
                                           MinutesAPIPath.upload,
                                           MinutesAPIPath.create]
}
