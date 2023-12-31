//
//  SendMessageTrackerInfo.swift
//  LarkSendMessage
//
//  Created by 李勇 on 2022/11/22.
//

import Foundation
import LarkModel // Message
import ThreadSafeDataStructure // SafeDictionary
import LarkMonitor // BDPowerLogSession

public enum KeyPointForSend: String {
    case start
    case procssForQuasiMessage = "procssForQuasiMessage"
    case callQuasiMessageAPI = "createQuasiMessageRequest"
    case procssForSendMessage = "procssForSendMessage"
    case callSendMessageAPI = "sendMessageRequest"
    case callSendMessageAPINetCost = "sendMessageRequestNetCost"
    case publishOnScreenSignal = "publishOnScreenSignal"
    case publishFinishSignal = "publishFinishSignal"
    // 消息上屏
    case messageOnScreen = "on_screen_cost"
    case success = "success_cost"
    case fail = "failed_cost"
    // 用户退出Chat
    case leave = "leave_cost"
}

/// 记录单个消息发送相关信息 https://bytedance.feishu.cn/space/doc/doccnlXJv4xV4mTJSAFu4VjMqVb#z2JvzI
public final class SendMessageTrackerInfo {
    public let indentify: String
    public var cid: String = ""
    public var messageType: Message.TypeEnum = .unknown
    // 记录各指标耗时
    public var pointCost: SafeDictionary<KeyPointForSend, TimeInterval> = [:] + .readWriteLock
    // 记录调用过的接口的ContextId，目前只有callQuasiMessageAPI、callSendMessageAPI会有接口调用
    public var contextIds: SafeDictionary<KeyPointForSend, String> = [:] + .readWriteLock
    //trace各个阶段耗时
    public var traceSpans: SafeDictionary<String, Any> = [:] + .readWriteLock
    public var showLoading: Bool = false
    public var textContentLength: Int = 0
    // 图片大小信息，发图片、视频等消息时有用
    public var resourceLength: Int64 = 0
    public var chatInfo: ChatKeyPointTrackerInfo?
    public var extralInfo: SafeDictionary<String, Any> = [:] + .readWriteLock // 透传额外信息
    // 视频转码信息，发视频消息时有用
    public var videoTrackInfo: VideoTrackInfo?
    // 视频转码错误信息
    public var videoTranscodeErrorCode: Int?
    // 视频转码错误信息
    public var videoTranscodeErrorMsg: String?
    /// 性能埋点信息
    public var powerLogSession: BDPowerLogSession?
    // 资源数量
    public var multiNumber: Int = 1
    // 是否离开聊天
    public var isExitChat: Bool = false
    // 资源来源
    public var chooseAssetSource: String = "unknown"

    public init(indentify: String) {
        self.indentify = indentify
    }

    // 作为参数放在metric中，Slardar打点使用
    public var metricLog: [String: String] {
        var result = pointCost.reduce([String: String]()) { (result, arg) -> [String: String] in
            let (key, value) = arg
            var result = result
            switch key {
            // 点击发送不记录耗时
            case .start:
                break
            // 只有拿到contextId,说明接口才调用成功了,才会打点记录
            case .callQuasiMessageAPI, .callSendMessageAPI:
                if contextIds[key] != nil {
                    result[key.rawValue] = "\(value)"
                }
            // 其他情况没有接口调用，直接取
            default:
                result[key.rawValue] = "\(value)"
            }
            return result
        }
        result["is_ui_show_loading"] = showLoading ? "1" : "0"
        result["text_content_length"] = "\(textContentLength)"
        result["resource_content_length"] = "\(resourceLength)"
        return result
    }

    public var category: [String: String] {
        return ["message_type": "\(messageType.rawValue)"]
    }

    // 作为参数放在extra中，Slardar打点使用
    public var extraLog: [String: String] {
        var result: [String: String] = [:]
        contextIds.forEach { (_, key, contextId) in
            result["context_id.\(key.rawValue)"] = contextId
            return true
        }
        return result
    }

    //tracing日志tag参数
    public var tracingTags: [String: Any] {
        var result: [String: String] = [:]
        self.metricLog.forEach { (key: String, value: String) in
            result[key] = value
        }
        self.category.forEach { (key: String, value: String) in
            result[key] = value
        }
        return result
    }

    public func enterBackGroud(_ enterBackGroudTime: TimeInterval?) -> Bool {
        guard let start = pointCost[.start], let time = enterBackGroudTime else {
            return false
        }
        // start >= time：进入后台消息才开始发送
        // start < time：消息发送时在前台，发送完成在后台
        return start < time
    }
}

extension SafeDictionary {
    func forEach(_ body: (inout [Key: Value], Key, Value) -> Bool) {
        safeWrite { data in
            for (k, v) in data {
                if !body(&data, k, v) {
                    break
                }
            }
        }
    }
}
