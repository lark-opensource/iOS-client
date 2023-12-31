//
//  UploadLogRetryManager.swift
//  SuiteLogin
//
//  Created by quyiming@bytedance.com on 2019/8/13.
//

import Foundation
import Reachability

protocol UploadLogRetryManagerDelegate: AnyObject {
    func didDowngradeRust(_ limit: UInt)
}

class UploadLogRetryManager {

    private static let uploadLogDowngradeFailureTime: UInt = 2

    private var reach: Reachability? {
        return UploadLogManager.reach
    }

    var cacheBodies: [UploadLogRequestBody] = []

    public var httpTool: LogHTTPTool

    private var lock: DispatchSemaphore = DispatchSemaphore(value: 1)

    public weak var delegate: UploadLogRetryManagerDelegate?

    init(httpTool: LogHTTPTool) {
        self.httpTool = httpTool
    }

    private var logUseRustHttp: Bool {
        return PassportSwitch.shared.logUseRustHttp
    }

    public func failure(body: UploadLogRequestBody) {
        lock.wait()
        defer {
            lock.signal()
        }
        guard self.logUseRustHttp, let reach else {
            return
        }
        switch reach.connection {
        case .cellular, .wifi:
            cacheBodies.append(body)
            if cacheBodies.count >= UploadLogRetryManager.uploadLogDowngradeFailureTime {
                UploadLogManager.logger.info("failure downgrade and retry with network: \(reach.connection) log body count: \(cacheBodies.count) downgradeFailureTime: \(UploadLogRetryManager.uploadLogDowngradeFailureTime)")
                PassportSwitch.shared.forceDisableLogRustHTTP = true
                self.delegate?.didDowngradeRust(UploadLogRetryManager.uploadLogDowngradeFailureTime)
                cacheBodies.forEach { (body) in
                    httpTool.request(body: body, success: {
                    }, failure: { (_) in
                    }, isRetry: true)
                }
                self.cacheBodies.removeAll()
            } else {
                UploadLogManager.logger.info("failure with network: \(reach.connection)")
            }
        case .none:
            UploadLogManager.logger.info("no network failure")
        @unknown default:
            UploadLogManager.logger.info("unkown network")
        }
    }

    public func success(body: UploadLogRequestBody) {
        lock.wait()
        defer {
            lock.signal()
        }
        guard self.logUseRustHttp else {
            return
        }
        if !cacheBodies.isEmpty {
            UploadLogManager.logger.info("success upload retry log body count: \(cacheBodies.count) downgradeFailureTime: \(UploadLogRetryManager.uploadLogDowngradeFailureTime)")
        }
        cacheBodies.forEach { (body) in
            httpTool.request(body: body, success: {
            }, failure: { (_) in
            }, isRetry: true)
        }
        self.cacheBodies.removeAll()
    }
}
