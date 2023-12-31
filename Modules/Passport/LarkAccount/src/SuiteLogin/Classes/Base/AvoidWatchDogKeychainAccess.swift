//
//  AvoidWatchDogKeychainAccess.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2020/2/13.
//

import Foundation
import KeychainAccess
import LKCommonsLogging

/*
   doc: https://bytedance.feishu.cn/docs/doccn31nWq2aArCuiW8bU3yYV6c#
*/
class AvoidWatchDogKeychainAccess {

    static let keychainLogger = Logger.plog(AvoidWatchDogKeychainAccess.self, category: "keychain")

    /// get keychain data avoid watchdog
    /// - Parameters:
    ///   - key: key for keychian
    ///   - keychain: keychain to access
    ///   - source: identify caller for log
    static func get(key: String, keychain: Keychain, source: String) -> String? {
        return waitReuslt(
            opType: .get,
            op: { () -> String? in
                return keychain.commonGet(key)
            },
            key: key,
            source: source
        )
    }

    /// set keychain data avoid watchdog
    /// - Parameters:
    ///   - key: key for keycahain
    ///   - value: value store in keycah
    ///   - keychain: keychain to access
    ///   - source: dentify caller for log
    @discardableResult
    static func set(key: String, value: String?, keychain: Keychain, source: String) -> Bool {
        return waitReuslt(
            opType: .set,
            op: { () -> Bool? in
                return keychain.commonSet(value, key)
            },
            key: key,
            source: source
        ) ?? false
    }

    /// 出现超时时关闭keychain功能，防止同一个线程串行访问keychain，每次访问都超时，导致watchdog
    private static var disableKeychainStorage: Bool = false

    private static let keychainTimeout: Int = 1500

    private static let opeartionQueue: OperationQueue = {
        let opq = OperationQueue()
        opq.maxConcurrentOperationCount = 4
        opq.name = "AvoidWatchDogKeychainAccessQueue"
        return opq
    }()

    private enum OperationType: CustomStringConvertible {
        case set
        case get
        var description: String {
            switch self {
            case .set:
                return "set"
            case .get:
                return "get"
            }
        }
    }

    private static func waitReuslt<T>(opType: OperationType, op: @escaping () -> T?, key: String, source: String) -> T? {
        var opResult: T?
        if disableKeychainStorage {
            let msg = "keychian disabled \(opType.description) key: \(key) source: \(source)"
            Self.keychainLogger.info(msg)
            return opResult
        }
        let signal = DispatchSemaphore(value: 0)
        let cid = UUID().uuidString
        let start = CFAbsoluteTimeGetCurrent()
        let callerThread = Thread.current
        let ctx = "cid: \(cid) key: \(key) source: \(source)"
        Self.keychainLogger.info("start \(opType.description) keychain callerThread: \(callerThread) \(ctx)")
        // 所有线程的访问都进行同步阻塞等待超时，因为主线程有些任务可能存在等子线程，子线程也需要超时保护
        opeartionQueue.addOperation {
            opResult = op()
            let asyncThread = Thread.current
            Self.keychainLogger.info("end \(opType.description) keychain time: \((CFAbsoluteTimeGetCurrent() - start) * 1000)ms asyncThread: \(asyncThread) \(ctx)")
            signal.signal()
        }
        let signalResult = signal.wait(timeout: .now() + .milliseconds(Self.keychainTimeout))
        switch signalResult {
        case .success:
            Self.keychainLogger.info("\(opType.description) keychain cache success \(ctx)")
            return opResult
        case .timedOut:
            Self.disableKeychainStorage = true
            let msg = "\(opType.description) keychain timeout \(ctx)"
            Self.keychainLogger.error(msg)
            return opResult
        }
    }
}

internal extension Keychain {

    func commonGet(_ key: String, logDesensitized: Bool = true) -> String? {
        do {
            let result = try self.get(key)
            let valueContent: String = logDesensitized ? "\(result)".desensitized() : "\(result)"
            AvoidWatchDogKeychainAccess.keychainLogger.info("n_action_keychain_access: GET key: \(key), value: \(valueContent)")
            return result
        } catch let error {
            AvoidWatchDogKeychainAccess.keychainLogger.error("n_action_keychain_access: GET key: \(key)/ error: " + error.localizedDescription)
            return nil
        }
    }

    @discardableResult
    func commonSet(_ value: String?, _ key: String, logDesensitized: Bool = true) -> Bool {
        if let valueTemp = value {
            let valueContent: String = logDesensitized ? "\(valueTemp)".desensitized() : "\(valueTemp)"
            do {
                AvoidWatchDogKeychainAccess.keychainLogger.info("n_action_keychain_access: SET key: \(key), value \(valueContent)")
                try self.set(valueTemp, key: key)
                return true
            } catch let error {
                AvoidWatchDogKeychainAccess.keychainLogger.error("n_action_keychain_access: SET key \(key), value \(valueContent)/ error: " + error.localizedDescription)
            }
        } else {
            AvoidWatchDogKeychainAccess.keychainLogger.error("n_action_keychain_access: SET key: \(key)/ error: value is nil")
        }
        return false
    }
}
