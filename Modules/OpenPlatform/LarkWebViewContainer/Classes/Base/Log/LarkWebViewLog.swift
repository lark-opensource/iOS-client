//
//  LarkWebViewLog.swift
//  LarkWebViewContainer
//
//  Created by 新竹路车神 on 2020/9/24.
//

import LarkOPInterface
import LKCommonsLogging
import ECOInfra
import LarkSetting

/// 套件统一WebView前缀
private let larkWebViewLogCategoryPrefix = "lkw."

extension Logger {
    /// 获取日志对象
    /// - Parameters:
    ///   - type: 类型
    ///   - category: 类别，可为空
    /// - Returns: 日志对象
    public static func lkwlog(_ type: Any, category: String = "") -> Log {
        //  基于op进行lkw的extension
        oplog(type, category: larkWebViewLogCategoryPrefix + category)
    }
}

extension Log {
    /// 记录自定义级别日志
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志内容
    ///   - traceId: 生命周期
    ///   - tag: 日志标签
    ///   - params: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public func lkwlog(level: LogLevel,
                       _ message: String,
                       traceId: String? = nil,
                       tag: String = "",
                       additionalData params: [String: String]? = nil,
                       error: Error? = nil,
                       file: String = #fileID,
                       function: String = #function,
                       line: Int = #line) {
        let params = Self.addTraceIdToAdditionalData(traceId: traceId, additionalData: params)
        log(level: level, message, tag: tag, additionalData: params, error: error, file: file, function: function, line: line)
    }
    
    /// 记录自定义级别日志
    /// - Parameters:
    ///   - level: 日志级别
    ///   - message: 日志内容
    ///   - traceId: 生命周期
    ///   - tag: 日志标签
    ///   - params: 附加数据
    ///   - error: 附加错误
    ///   - file: 文件名
    ///   - function: 函数名
    ///   - line: 行号
    public func lkwUrlEncryptLog(level: LogLevel,
                       _ message: String,
                       url:URL? = nil,
                       traceId: String? = nil,
                       tag: String = "",
                       additionalData params: [String: String]? = nil,
                       error: Error? = nil,
                       file: String = #fileID,
                       function: String = #function,
                       line: Int = #line) {
        let params = Self.addTraceIdToAdditionalData(traceId: traceId, additionalData: params)
        if let url = url, !url.absoluteString.isEmpty {
            DispatchQueue.global().async {
                let encrytmessage = message + ", encrypted_key_link:\(OPEncryptUtils.webURLAES256Encrypt(content: url.absoluteString))"
                log(level: level, encrytmessage, tag: tag, additionalData: params, error: error, file: file, function: function, line: line)
            }
        } else {
            // 这个分支下encrypted_key_link 要么是nil，要么是空字符串
            let encrytmessage = message + ", encrypted_key_link:\(String(describing: url?.safeURLString)))"
            log(level: level, message, tag: tag, additionalData: params, error: error, file: file, function: function, line: line)
        }
    }
    
    private static func addTraceIdToAdditionalData(traceId: String?, additionalData: [String: String]?) -> [String: String]? {
        guard let traceId = traceId else {
            return additionalData
        }
        var additionalData = additionalData ?? [:]
        additionalData.updateValue(traceId, forKey: "traceId")
        return additionalData
    }
}
