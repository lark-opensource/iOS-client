//
//  SendVideoLogger.swift
//  LarkSendMessage
//
//  Created by Saafo on 2023/5/22.
//

import Foundation
import LKCommonsLogging // Logger
import LarkFoundation // Utils
import ByteWebImage // crc32

/// 视频发送日志模块
///
/// 主要用于使用 ContentID 和 ProcessID 拼接成 ContextID 来串联视频发送链路
/// - ContentID: 对于同一个视频资源，不变，便于串联同一个视频资源的所有操作
/// - ProcessID: 对于同一个流程，不变，比如预处理流程；发视频流程
enum SendVideoLogger {

    enum IDGenerator {
        /// 对于每次预处理流程，创建一个唯一的 ID
        static var preprocessID: String { "PRE\(Utils.randomID())" }
        /// 对于每次流程，创建一个唯一的 ID
        static var uniqueID: String { Utils.randomID() }
        /// 对于未修改过的 PHAsset，保持 ID 不变
        static func contentID(for video: SendVideoContent, origin: Bool) -> String {
            let rawID: String
            switch video {
            case .asset(let asset):
                rawID = VideoParser.phassetResourceID(asset: asset)
            case .fileURL(let url):
                rawID = url.absoluteString
            }
            let originPrefix = origin ? "ORI-" : ""
            guard let data = rawID.data(using: .utf8) else {
                return originPrefix + rawID
            }
            return originPrefix + data.bt.crc32
        }
    }

    /// 发视频阶段，会打印在每条日志中
    enum Phrase: String {
        /// 预处理
        case preprocess
        /// 解析数据
        case parseInfo
        /// 解码
        case transcode
        /// 上传
        case upload
        /// 发送
        case send
        /// 发视频组件生命周期，可不传 CID
        case lifeCycle
        /// 其他
        case others
    }

    private static let sharedLogger = Logger.log(SendVideoLogger.self)

    static func error(
        _ message: String,
        _ phrase: Phrase,
        pid processId: String,
        cid contentId: String,
        params: [String: String] = [:],
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message, phrase, pid: processId, cid: contentId, additionalData: params, error: error,
            file: file, function: function, line: line)
    }

    static func warn(
        _ message: String,
        _ phrase: Phrase,
        pid processId: String,
        cid contentId: String,
        params: [String: String] = [:],
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warn, message, phrase, pid: processId, cid: contentId, additionalData: params, error: error,
            file: file, function: function, line: line)
    }

    static func info(
        _ message: String,
        _ phrase: Phrase,
        pid processId: String,
        cid contentId: String,
        params: [String: String] = [:],
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message, phrase, pid: processId, cid: contentId, additionalData: params, error: error,
            file: file, function: function, line: line)
    }

    static func debug(
        _ message: String,
        _ phrase: Phrase,
        pid processId: String,
        cid contentId: String,
        params: [String: String] = [:],
        error: Error? = nil,
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message, phrase, pid: processId, cid: contentId, additionalData: params, error: error,
            file: file, function: function, line: line)
    }

    // swiftlint:disable function_parameter_count
    private static func log(
        level: LogLevel,
        _ message: String,
        _ phrase: Phrase,
        pid processId: String,
        cid contentId: String,
        additionalData params: [String: String],
        error: Error?,
        file: String,
        function: String,
        line: Int
    ) {
        let message = "[send video][\(phrase)] " + message
        var params = params
        if !processId.isEmpty || !contentId.isEmpty {
            let contextID: String
            if processId == contentId {
                contextID = contentId
            } else if processId.isEmpty {
                contextID = contentId
            } else if contentId.isEmpty {
                contextID = processId
            } else {
                contextID = [contentId, processId].joined(separator: "_")
            }
            params["contextID"] = contextID
        }
        sharedLogger.log(level: level, message, additionalData: params, error: error,
                         file: file, function: function, line: line)
    }
    // swiftlint:enable function_parameter_count
}
