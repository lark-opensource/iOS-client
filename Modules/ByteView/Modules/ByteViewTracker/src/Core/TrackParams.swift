//
//  TrackParams.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/13.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

/// TrackEvent的参数，在[String: Any]的基础上加一些埋点相关的自定义
public struct TrackParams {
    private var params: [String: Any]

    public init(_ params: [String: Any] = [:]) {
        self.params = TrackParams.normalized(params: params)
    }

    init(raw params: [String: Any]) {
        self.params = params
    }

    public var rawValue: [String: Any] {
        params
    }

    /// 设nil的时候会removeValue(forKey: key)
    public subscript(key: TrackParamKey) -> Any? {
        get {
            params[key.rawValue]
        }
        set {
            let k = key.rawValue
            if let v0 = newValue {
                if let v1 = Self.normalized(key: k, value: v0) {
                    params[k] = v1
                }
            } else {
                params.removeValue(forKey: k)
            }
        }
    }

    @discardableResult
    public mutating func removeValue(forKey key: TrackParamKey) -> Any? {
        self.params.removeValue(forKey: key.rawValue)
    }

    /// 更新多个值
    /// - parameter isOverwrite: key重复时是否覆盖旧有值
    public mutating func updateParams(_ params: [String: Any], isOverwrite: Bool = true) {
        if self.params.isEmpty {
            self.params = params
        } else if !params.isEmpty {
            self.params.merge(TrackParams.normalized(params: params), uniquingKeysWith: { isOverwrite ? $1 : $0 })
        }
    }

    public func contains(_ key: TrackParamKey) -> Bool {
        let key = key.rawValue
        return self.params.contains(where: { $0.key == key })
    }

    private static let reservedKeys: Set<String> = [
        "conference_id", // 会议ID，空表示无会议，并防止被被通参覆盖（影响通参选择）
        "env_id" // 无会议时的上下文时的ID，防止被通参覆盖
    ]

    private static func normalized(key: String, value anyObj: Any) -> Any? {
        let value = JSONSerialization.isValidJSONObject([anyObj]) ? anyObj : "\(anyObj)"
        if reservedKeys.contains(key) {
            return value
        }
        switch value {
        case let b as Bool:
            return b.description
        case let s as String:
            return s.isEmpty ? nil : s
        default:
            return value
        }
    }

    private static func normalized(params: [String: Any]) -> [String: Any] {
        var normalizedParams: [String: Any] = [:]
        params.forEach { key, value in
            if let v = normalized(key: key, value: value) {
                normalizedParams[key] = v
            }
        }
        return normalizedParams
    }
}

extension TrackParams: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (TrackParamKey, Any?)...) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
}

/// 可以像String一样用，但是包含一些预定义值
public struct TrackParamKey: RawRepresentable, CustomStringConvertible, CustomDebugStringConvertible, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

public extension TrackParamKey {
    /// 会议session（placeholderId），String
    /// - 埋点时状态机还没有变化，拿不到通参的conferenceId，与数据同学沟通后决定添加env_id
    /// - 不设置时，取当前会议通参
    /// - 设置后，通参取该envId（placeholderId）对应的通参
    /// - 置为空字符串可忽略会议相关的通参
    static let env_id: TrackParamKey = "env_id"
    /// 会议ID，String
    /// - 置为空字符串可忽略会议相关的通参
    static let conference_id: TrackParamKey = "conference_id"
    /// 网络类型，String
    /// - 2g/3g/4g/5g/wifi/others
    static let network_type: TrackParamKey = "network_type"

    /// 用户操作名称，String
    static let action_name: TrackParamKey = "action_name"
    /// 行为触发源，String
    static let from_source: TrackParamKey = "from_source"
    /// 点击事件，String
    static let click: TrackParamKey = "click"
    /// - 目标页，TrackEventName
    /// - action的target，String
    static let target: TrackParamKey = "target"
    /// 是否在共享中（屏幕/文档)
    static let isSharing: TrackParamKey = "is_sharing"
    /// 勾选的分享人数/群组
    static let shareNum: TrackParamKey = "share_num"
    /// 建议列表人数
    static let suggestionNum: TrackParamKey = "suggest_list_num"
    /// 是否会前等候页，Bool
    static let is_starting_auth: TrackParamKey = "is_starting_auth"
    /// 打开还是关闭，open/close，String
    /// - 分组会议中部分埋点：离开选择位置
    static let option: TrackParamKey = "option"
    /// 事件发生所在的位置，String
    static let location: TrackParamKey = "location"
    /// 弹窗内容，String
    static let content: TrackParamKey = "content"
    /// 额外参数，[String: Any]
    static let extend_value: TrackParamKey = "extend_value"

    /// 延迟，毫秒, Double/Int
    static let latency: TrackParamKey = "latency"
    /// 耗时，毫秒, Double/Int
    static let duration: TrackParamKey = "duration"
    /// 持续时间，秒，Double/Int
    static let elapse: TrackParamKey = "elapse"
    /// 事件触发时间，1970.1.1以来的毫秒数，Int64
    static let start_time: TrackParamKey = "start_time"
    /// 错误码，0为成功，Int
    static let error_code: TrackParamKey = "error_code"
    /// 错误信息，String
    static let error_msg: TrackParamKey = "error_msg"
    /// Rust请求号，String
    static let command: TrackParamKey = "command"
    /// 页面，String
    static let page: TrackParamKey = "page"
    /// 原因，String
    static let reason: TrackParamKey = "reason"
    /// 从 App启动/会议开始 到现在的时间，秒，Double
    static let since_start: TrackParamKey = "since_start"
    /// 当前的音频设备信息, String
    static let current_audio_route: TrackParamKey = "current_audio_route"

    /// 是否第一次，Bool
    static let is_first: TrackParamKey = "is_first"

    /// 标识开关是否开启，比如摄像头麦克风状态
    static let is_on: TrackParamKey = "is_on"
    /// unmute 摄像头或麦克风请求的 request id
    static let request_id: TrackParamKey = "request_id"
    /// 邀请入口聚合展示的 tab
    static let tab: TrackParamKey = "tab"
    /// sip/h323 点击类型类型
    static let sip_or_h323: TrackParamKey = "sip_or_h323"
    /// 温度降级弹窗等级
    static let thermalState: TrackParamKey = "temperature_level"
    /// 录制类型
    static let recordType: TrackParamKey = "record_type"
}
