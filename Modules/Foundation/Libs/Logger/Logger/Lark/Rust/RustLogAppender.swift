//
//  File.swift
//  LarkApp
//
//  Created by 李晨 on 2019/8/6.
//

import Foundation
import LarkStorage

public struct RustLogConfig {
    public var process: String
    public var logPath: String
    public var monitorEnable: Bool

    public init(process: String, logPath: String, monitorEnable: Bool) {
        self.process = process
        self.logPath = logPath
        self.monitorEnable = monitorEnable
    }
}

public final class RustLogAppender: Appender {

    private static var sdkHadInit: Bool = false

    public var rules: [LogRule] = []

    public static func setupRustLogSDK(config: RustLogConfig) {
        transformToUIntUnsafePointer(with: config.process, config.logPath) { processBuffer, logpathBuffer in

            let secretKey = LarkStorage.KVPublic.Setting.rustLogSecretKey.value()
            let encodedPublicKey = secretKey["encoded_public_key"] ?? ""
            let keyID = secretKey["key_id"] ?? ""

            transformToUIntUnsafePointer(with: encodedPublicKey, keyID) { encodedPublicKey, keyID in

                var request = InitLogRequest(
                    process_name: processBuffer,
                    log_path: logpathBuffer,
                    enable_content_monitor: config.monitorEnable ? 1 : 0,
                    encoded_public_key: encodedPublicKey,
                    key_id: keyID
                )

                let result = init_client_log(&request)
                assert(result == 0, "rust log sdk init failed")
                if result == 0 {
                    sdkHadInit = true
                }
            }
        }
    }

    public init() {
    }

    public static func identifier() -> String {
        return "\(RustLogAppender.self)"
    }

    public static func persistentStatus() -> Bool {
        return false
    }

    public func doAppend(_ event: LogEvent) {
        assert(RustLogAppender.sdkHadInit == true, "please setup rust log sdk use 'setupRustLogSDK(config:)'")
        let extra: [String: String] = event.params ?? [:]
        // 之前用swift的字典直接做了转json的操作，但是在JSONSerialization.data()方法上会有偶现的崩溃情况
        // 现在尝试使用oc来做这个操作，希望能有所改善。更改版本为5.0
        let extraDictionary: NSMutableDictionary = NSMutableDictionary()
        for item in extra {
            let ocKey = NSString(string: item.key)
            let ocValue = NSString(string: item.value)
            extraDictionary.setObject(ocValue, forKey: ocKey)
        }
        if let error = event.error {
            let ocValue = NSString(string: "\(error)")
            let ocKey = NSString(string: "error")
            extraDictionary.setObject(ocValue, forKey: ocKey)
        }
        var extraJson = ""
        // swiftlint:disable:next empty_count
        if extraDictionary.count != 0,
           let extraData = try? JSONSerialization.data(withJSONObject: extraDictionary, options: []),
           let str = String(data: extraData, encoding: String.Encoding.utf8) {
            extraJson = str
        }

        client_log_v2(
            event.logId,
            event.message,
            extraJson,
            event.tags.joined(separator: ","),
            levelNumber(level: event.level),
            Int64(event.time * 1000),
            event.category,
            event.file,
            Int32(event.line),
            event.function,
            event.thread,
            -1)
    }

    public func persistent(status: Bool) {
    }

    private func levelNumber(level: LogLevel) -> Int32 {
        switch level {
        case .trace:
            return 1
        case .debug:
            return 2
        case .info:
            return 3
        case .warn:
            return 4
        case .error:
            return 5
        case .fatal:
            return 6
        }
    }

    public func debugLogRules() -> [LogRule] {
        return self.rules
    }
}


@inlinable
func transformToUIntUnsafePointer(with a: String, _ b: String, _ handler: (_ a: UnsafePointer<UInt8>?, _ b: UnsafePointer<UInt8>?) -> Void) {
    transformToUIntUnsafePointer(with: a) { _a in
        transformToUIntUnsafePointer(with: b) { _b in
            handler(_a, _b)
        }
    }
}

@inlinable
func transformToUIntUnsafePointer(with string: String, _ handler: (UnsafePointer<UInt8>?) -> Void) {
    string.utf8CString.withUnsafeBufferPointer {
        $0.withMemoryRebound(to: UInt8.self) {
            handler($0.baseAddress)
        }
    }
}
