//
//  DevTrackEvent.swift
//  ByteViewTracker
//
//  Created by kiri on 2022/1/25.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import AVFoundation

/// builder for `vc_client_event_dev` TrackEvent
public final class DevTrackEvent {
    public let action: Action
    internal var categories: [DevTrackEvent.Category] = []
    internal var subcategories: [String] = []
    internal var params = TrackParams()

    private init<T: RawRepresentable>(_ actionType: ActionType, _ name: T) where T.RawValue == String {
        self.action = Action(actionType, name.rawValue)
    }

    internal func toEvent() -> TrackEvent {
        /// category被占用，使用scene作为分类名
        var params = self.params
        params["scene"] = categories.map({ $0.rawValue }).joined(separator: ",")
        params["subscene"] = subcategories.joined(separator: ",")
        params["action_type"] = action.actionType.rawValue
        params["action_name"] = action.actionName
        return TrackEvent(name: .vc_client_event_dev, params: params)
    }

    /// 添加事件所属分类
    public func category(_ category: DevTrackEvent.Category) -> Self {
        if !self.categories.contains(category) {
            self.categories.append(category)
        }
        return self
    }

    /// 添加事件所属子分类
    public func subcategory(_ subcategory: DevTrackEvent.Subcategory) -> Self {
        self.subcategory(rawValue: subcategory.rawValue)
    }

    /// 添加事件所属子分类
    public func subcategory(rawValue: String) -> Self {
        if !self.subcategories.contains(rawValue) {
            self.subcategories.append(rawValue)
        }
        return self
    }

    /// 更新TrackParams
    @discardableResult
    public func params(_ params: TrackParams) -> Self {
        self.params.updateParams(params.rawValue)
        return self
    }
}

public extension DevTrackEvent {
    /// 通用关键路径埋点，action_type = critical_path
    /// - parameter path: 会被填入参数action_name里
    static func criticalPath(_ path: CriticalPath) -> DevTrackEvent {
        DevTrackEvent(.critical_path, path)
    }

    /// 通用用户操作埋点，action_type = user_action
    /// - parameter action: 会被填入参数action_name里
    static func userAction(_ action: UserAction) -> DevTrackEvent {
        DevTrackEvent(.user_action, action)
    }

    /// 通用告警埋点，action_type = warn
    /// - parameter warning: 会被填入参数action_name里
    static func warning(_ warning: Warning) -> DevTrackEvent {
        DevTrackEvent(.warn, warning)
    }

    /// 通用隐私安全埋点，action_type = privacy
    /// - parameter privacy: 会被填入参数action_name里
    static func privacy(_ privacy: Privacy) -> DevTrackEvent {
        DevTrackEvent(.privacy, privacy)
    }

    /// 通用音频埋点，action_type = audio
    /// - parameter audio: 会被填入参数action_name里
    static func audio(_ audio: Audio) -> DevTrackEvent {
        DevTrackEvent(.audio, audio).category(.audio).params([.current_audio_route: AVAudioSession.sharedInstance().currentRoute])
    }
}

extension DevTrackEvent {
    /// 事件类型
    /// - 可根据需求新增
    public enum ActionType: String, Hashable {
        /// 关键路径
        case critical_path
        /// 用户操作（点击）
        case user_action
        /// 告警
        case warn
        /// 隐私安全
        case privacy
        /// 音频
        case audio
    }
}

extension DevTrackEvent {

    /// Hashable, 可用来做key或事件类型
    public struct Action: Hashable {
        public let actionType: ActionType
        public let actionName: String

        fileprivate init(_ type: ActionType, _ action: String) {
            self.actionType = type
            self.actionName = action
        }

        /// 通用关键路径埋点，action_type = critical_path
        /// - parameter path: 会被填入参数action_name里
        public static func criticalPath(_ path: CriticalPath) -> Action {
            Action(.critical_path, path.rawValue)
        }

        /// 通用用户操作埋点，action_type = user_action
        /// - parameter action: 会被填入参数action_name里
        public static func userAction(_ action: UserAction) -> Action {
            Action(.user_action, action.rawValue)
        }

        /// 通用告警埋点，action_type = warn
        /// - parameter warning: 会被填入参数action_name里
        public static func warning(_ warning: Warning) -> Action {
            Action(.warn, warning.rawValue)
        }

        /// 通用隐私安全埋点，action_type = privacy
        /// - parameter privacy: 会被填入参数action_name里
        public static func privacy(_ privacy: Privacy) -> Action {
            Action(.privacy, privacy.rawValue)
        }
    }
}
