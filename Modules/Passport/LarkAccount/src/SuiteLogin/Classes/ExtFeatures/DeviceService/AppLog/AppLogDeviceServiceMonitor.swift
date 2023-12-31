//
//  AppLogDeviceServiceMonitor.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2020/11/18.
//

import Foundation
import LKCommonsTracker
import LarkPerf
import RxSwift

class AppLogDeviceServiceMonitor {
    static let serviceNameKey: String = "passport_business_overall"
    static let reasonKey: String = "reason"
    static let serialQueue = DispatchQueue(label: "applog.device.service.monitor", qos: .background)

    struct ReasonValue {
        static let timeout: String = "timeout"
        static let appLogInvalidData: String = "app_log_invalid_data"
        static let localInvalidData: String = "local_invalid_data"
        static let appLogError: String = "app_log_error"
        static let unknown: String = "unknown"
    }
    struct TypeValue {
        static let fetchDidSuccess = "fetch_did_success"
        static let fetchDidFailure = "fetch_did_failure"
        static let beforeLoginUseAppLogDid = "before_login_use_app_log_did"
        static let fastLoginUseAppLogDid = "fast_login_use_app_log_did"
        static let loginSuccessUseAppLogDid = "login_success_use_app_log_did"
    }

    static func fetchDidSuccess() {
        track(TypeValue.fetchDidSuccess)
    }

    static func fetchDidFailure(_ error: Error) {
        if case RxError.timeout = error {
            self.fetchDidFailure(
                reason: AppLogDeviceServiceMonitor.ReasonValue.timeout,
                extra: [:]
            )
        } else if let err = error as? RangersAppLogDeviceServiceImpl.AppLogError {
            switch err {
            case .appLogInvalidData(let userInfo):
                self.fetchDidFailure(
                    reason: AppLogDeviceServiceMonitor.ReasonValue.appLogInvalidData,
                    extra: userInfo
                )
            case .appLogError(let userInfo):
                self.fetchDidFailure(
                    reason: AppLogDeviceServiceMonitor.ReasonValue.appLogError,
                    extra: userInfo
                )
            case .localInvalidData(let userInfo):
                self.fetchDidFailure(
                    reason: AppLogDeviceServiceMonitor.ReasonValue.localInvalidData,
                    extra: userInfo
                )
            }
        } else {
            self.fetchDidFailure(
                reason: AppLogDeviceServiceMonitor.ReasonValue.unknown,
                extra: ["error": String(describing: error)]
            )
        }
    }

    static func fetchDidFailure(reason: String, extra: [AnyHashable: Any] ) {
        track(TypeValue.fetchDidFailure, reason: reason, extra: extra)
    }

    private static func track(_ type: String, reason: String? = nil, extra: [AnyHashable: Any] = [:]) {
        serialQueue.async {
            var category = [
                MultiSceneMonitor.Const.type.rawValue: type
            ]
            if let r = reason {
                category[reasonKey] = r
            }
            Tracker.post(SlardarEvent(
                name: serviceNameKey,
                metric: [:],
                category: category,
                extra: extra
            ))
        }
    }
}
