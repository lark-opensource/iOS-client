//
//  MsgInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_MsgInfo
public struct MsgInfo: Equatable, Codable {
    public init(type: TypeEnum, expire: Int32, message: String, isShow: Bool, isOverride: Bool,
                msgI18NKey: I18nKeyInfo?, msgTitleI18NKey: I18nKeyInfo?, popupType: PopupType, alert: Alert?, toastIcon: ToastIconType, msgButtonI18NKey: I18nKeyInfo?, monitor: Monitor?) {
        self.type = type
        self.expire = expire
        self.message = message
        self.isShow = isShow
        self.isOverride = isOverride
        self.msgI18NKey = msgI18NKey
        self.msgTitleI18NKey = msgTitleI18NKey
        self.popupType = popupType
        self.alert = alert
        self.toastIcon = toastIcon
        self.msgButtonI18NKey = msgButtonI18NKey
        self.monitor = monitor
    }

    public var type: TypeEnum

    /// toast显示时长(单位ms)，过期后自动消失，(0)表示用端上默认显示时间
    public var expire: Int32

    /// 提示信息
    public var message: String

    /// 是否toast展示给用户
    public var isShow: Bool

    /// 是否覆盖前端默认信息
    public var isOverride: Bool

    /// msg关联i18n key信息
    public var msgI18NKey: I18nKeyInfo?

    /// msg title关联i18n key信息
    public var msgTitleI18NKey: I18nKeyInfo?

    /// popup类型
    public var popupType: PopupType

    /// alert富文本，仅当 type == ALERT 时非空
    public var alert: Alert?

    /// toastIcon 类型
    public var toastIcon: ToastIconType

    /// msg button 关联 i18n key 信息
    public var msgButtonI18NKey: I18nKeyInfo?

    /// 埋点用
    public var monitor: Monitor?

    public enum TypeEnum: Int, Hashable, Codable, CustomStringConvertible {
        case unknown // = 0
        case tips // = 1
        case toast // = 2
        case popup // = 3
        case alert // = 4

        public var description: String {
            switch self {
            case .unknown:
                return "unknown"
            case .tips:
                return "tips"
            case .toast:
                return "toast"
            case .popup:
                return "popup"
            case .alert:
                return "alert"
            }
        }
    }

    public enum PopupType: Int, Hashable, Codable, CustomStringConvertible {
        case unknown // = 0
        case info // = 1
        case warning // = 2
        case error // = 3

        public var description: String {
            switch self {
            case .unknown:
                return "unknown"
            case .info:
                return "info"
            case .warning:
                return "warning"
            case .error:
                return "error"
            }
        }
    }

    public enum ToastIconType: Int, Hashable, Codable, CustomStringConvertible {
        case unknown // = 0
        case info // = 1
        case success // = 2
        case warning // = 3
        case error // = 4
        case loading // = 5

        public var description: String {
            switch self {
            case .unknown:
                return "unknown"
            case .info:
                return "info"
            case .success:
                return "success"
            case .warning:
                return "warning"
            case .error:
                return "error"
            case .loading:
                return "loading"
            }
        }
    }

    public struct Alert: Equatable, Codable {
        public init(title: Alert.Text, body: Alert.Text, footer: Alert.Button?, footer2: Alert.Button?) {
            self.title = title
            self.body = body
            self.footer = footer
            self.footer2 = footer2
        }

        public var title: Alert.Text
        public var body: Alert.Text
        public var footer: Alert.Button?
        public var footer2: Alert.Button?

        public enum ButtonColor: Int, Hashable, Codable, CustomStringConvertible {
            case black // = 0
            case red // = 1
            case blue // = 2
            case grey // = 3

            public var description: String {
                switch self {
                case .black:
                    return "black"
                case .red:
                    return "red"
                case .blue:
                    return "blue"
                case .grey:
                    return "grey"
                }
            }
        }

        public struct Text: Equatable, Codable, CustomStringConvertible {
            public var i18NKey: String
            public init(i18NKey: String) {
                self.i18NKey = i18NKey
            }

            public var description: String {
                i18NKey
            }
        }

        public struct Button: Equatable, Codable {
            /// 按钮文本
            public var text: Alert.Text

            /// 等待按钮可点击时间（单位：秒）
            public var waitTime: Int32

            /// 按钮的颜色
            public var color: Alert.ButtonColor

            public init(text: Alert.Text, waitTime: Int32, color: Alert.ButtonColor) {
                self.text = text
                self.waitTime = waitTime
                self.color = color
            }
        }
    }

    public struct Monitor: Codable, Equatable {
        public var logID: String

        public var blockType: BlockType

        public var ownerTenantID: String

        public init(logID: String, blockType: BlockType, ownerTenantID: String) {
            self.logID = logID
            self.blockType = blockType
            self.ownerTenantID = ownerTenantID
        }

        public enum BlockType: Int, Codable {
            case unknown // = 0
            case feishuSuperAdmin // = 1
            case feishuGeneral // = 2
            case feishuPersonal // = 3
            case lark // = 4

            public var trackParam: String {
                switch self {
                case .unknown: return "unknown"
                case .feishuSuperAdmin: return "feishu_super_admin"
                case .feishuGeneral: return "feishu_general"
                case .feishuPersonal: return "feishu_personal"
                case .lark: return "lark"
                }
            }
        }
    }
}

extension MsgInfo: CustomStringConvertible {
    public var description: String {
        String(name: "MsgInfo", [
            "type": type,
            "isShow": isShow,
            "isOverride": isOverride,
            "expire": expire,
            "toastIcon": toastIcon,
            "popupType": popupType,
            "alert": alert
        ])
    }
}

extension MsgInfo.Alert: CustomStringConvertible {
    public var description: String {
        String(name: "Alert", [
            "title": title,
            "body": body,
            "footer": footer,
            "footer2": footer2
        ])
    }
}

extension MsgInfo.Alert.Button: CustomStringConvertible {
    public var description: String {
        if waitTime > 0 {
            return String(name: "Button", ["text": text, "color": color, "waitTime": waitTime])
        } else {
            return String(name: "Button", ["text": text, "color": color])
        }
    }
}
