//
//  PassportLog.swift
//  LarkAccount
//
//  Created by au on 2021/9/22.
//

import Foundation
import LKCommonsLogging

private let passportCategoryPrefix = "plog."

/// 日志发布方式/上报渠道
public enum PassportLogDistributionMethod: String {
    /// 只本地落库，通过 trouble kill 回捞获取，默认
    case local

    /// 通过 OPMonitor 上报，在 Timeline 上可以看到实时日志
    /// 本地依然会将这部分内容落库
    /// 为了控制上报的数据量，建议只有遵循格式化流程的日志内容（以 n_/r_ 开头）使用此方式
    case timeline
}

/// https://bytedance.feishu.cn/docs/doccnHKV9wYfJHkRYtLz2HZZoQf#mfYwTO
/// event: 形如 n_page_LoginInput_start 双端统一的字符串
/// body: 用于传入自定义日志内容
/// 请不要将这里的日志方法设置为 public，会污染到其它模块的 log
internal extension Log {
    func info(
        _ event: String,
        body: String = "",
        additionalData params: [String: CustomStringConvertible]? = nil,
        error: Error? = nil,
        method: PassportLogDistributionMethod = .timeline,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
            if error != nil {
                assertionFailure("You should use warn() or error() log method when error is not nil.")
            }
            let message = body.isEmpty ? event : "\(event): \(body)"
            let data = params?.mapValues { $0.description }
            self.info(message, tag: method.rawValue, additionalData: data, error: error, file: file, function: function, line: line)
        }

    func warn(
        _ event: String,
        body: String = "",
        additionalData params: [String: CustomStringConvertible]? = nil,
        error: Error? = nil,
        method: PassportLogDistributionMethod = .timeline,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
            var message = body.isEmpty ? event : "\(event): \(body)"
            if let e = error {
                if let v3e = e as? V3LoginError {
                    message += " Error desc: \(v3e.description); Error code: \(v3e.errorCode)"
                } else {
                    message += " \(e.localizedDescription)"
                }
            }
            let data = params?.mapValues { $0.description }
            self.warn(message, tag: method.rawValue, additionalData: data, error: error, file: file, function: function, line: line)
        }

    func error(
        _ event: String,
        body: String = "",
        additionalData params: [String: CustomStringConvertible]? = nil,
        error: Error? = nil,
        method: PassportLogDistributionMethod = .timeline,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
            var message = body.isEmpty ? event : "\(event): \(body)"
            if let e = error {
                if let v3e = e as? V3LoginError {
                    message += " Error desc: \(v3e.description); Error code: \(v3e.errorCode)"
                } else {
                    message += " \(e.localizedDescription)"
                }
            }
            let data = params?.mapValues { $0.description }
            self.error(message, tag: method.rawValue, additionalData: data, error: error, file: file, function: function, line: line)
        }
}

public extension Log {

    func passportInfo(
        _ event: String,
        body: String = "",
        additionalData params: [String: CustomStringConvertible]? = nil,
        error: Error? = nil,
        method: PassportLogDistributionMethod = .timeline,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
            self.info(event, body: body, additionalData: params, error: error, method: method, file: file, function: function, line: line)
        }

    func passportWarn(
        _ event: String,
        body: String = "",
        additionalData params: [String: CustomStringConvertible]? = nil,
        error: Error? = nil,
        method: PassportLogDistributionMethod = .timeline,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
            self.warn(event, body: body, additionalData: params, error: error, method: method, file: file, function: function, line: line)
        }

    func passportError(
        _ event: String,
        body: String = "",
        additionalData params: [String: CustomStringConvertible]? = nil,
        error: Error? = nil,
        method: PassportLogDistributionMethod = .timeline,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line) {
            self.error(event, body: body, additionalData: params, error: error, method: method, file: file, function: function, line: line)
        }
}

extension Logger {

    /// Passport 内请使用该 plog 方法注册日志
    /// - Parameters:
    ///   - type: 当前对象类型
    ///   - category: 类别名称，通常使用模块名和类型名结合
    /// - Returns: 日志对象
    public static func plog(_ type: Any, category: String = "") -> Log {
        log(type, category: passportCategoryPrefix + category)
    }
}

extension Logger {

    static func setupPassportLog(forwardLogFactory: @escaping (_ type: Any, _ category: String)-> Log) {
        Logger.setup(for: passportCategoryPrefix) { (type, category) -> LKCommonsLogging.Log in
            let logger = forwardLogFactory(type, category)
            return PassportLogProxy(type, category, forwardTo: logger)
        }
    }
}
