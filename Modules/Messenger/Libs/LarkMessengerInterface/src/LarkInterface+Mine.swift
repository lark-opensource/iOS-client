//
//  LarkInterface+Mine.swift
//  LarkInterface
//
//  Created by liuwanlin on 2019/1/3.
//

import UIKit
import Foundation
import EENavigator
import LarkOpenSetting
import LarkUIKit

/// 我的侧边栏
public struct MineMainBody: PlainBody {
    public static let pattern = "//client/mine/home"

    public weak var hostProvider: UIViewController?

    public init(hostProvider: UIViewController?) {
        self.hostProvider = hostProvider
    }
}

/// 通知设置 旧的入口，待全量后删除
public struct MineNoticeSettingBody: CodablePlainBody {
    public static let pattern = "//client/mine/notice"

    public static let highlightFragment = "highlight"

    /// 需要高亮的条目，可以在这里加，进入设置界面后会高亮
    enum ItemKey: String {
        case NotifyScopeAll, NotifyScopePartial, NotifyScopeNone
        case SpecialFocusSetting
        case ReceiveCallUsingSystemPhone, SystemCallRecordIntegrateApp
        case VCNotificationUseINStartCallIntent
        case OffDuringCalls
        case DoNotDisturb
        case OffWhenPCOnline, BuzzStillNotify, AtMeStillNotify, SpecialFocusStillNotify
        case AddUrgentNum
        case BannerPreview
        case NotificationDiagnosis
        case CustomizeRinging
    }
    public let highlight: Set<String>

    public init(highlight: Set<String> = Set<String>()) {
        self.highlight = highlight
    }

    public var _url: URL {
        if !highlight.isEmpty {
            return URL(string: "\(Self.pattern)#\(Self.highlightFragment)") ?? .init(fileURLWithPath: "")
        }
        return URL(string: Self.pattern) ?? .init(fileURLWithPath: "")
    }
}

/// 关于飞书
public struct MineAboutLarkBody: CodablePlainBody {
    public static let pattern = "//client/mine/about"

    public init() {}
}

/// 设备权限管理
public struct MineCapabilityPermissionBody: CodablePlainBody {
    public static let pattern = "//client/mine/about/permisson"

    public init() {}
}

/// 通用设置
public struct MineGeneralSettingBody: CodablePlainBody {
    public static let pattern = "//client/general/setting"
    public init() {}
}

/// 效率设置
public struct EfficiencySettingBody: CodablePlainBody {
    public static let pattern = "//client/efficiency/setting"
    public init() {}
}

/// 翻译设置，提供给其他业务模块跳转
public struct TranslateSettingBody: CodablePlainBody {
    public static let pattern = "//client/mine/translateSetting"

    public init() {}
}

public struct FeedFilterSettingBody: PlainBody {
    public enum BodySource: String {
        case fromFeed = "feed_more_edit_mobile"
        case fromMine = "set_efficiency_edit"
        case unknown = ""
    }
    public static let pattern = "//client/mine/feedFilterSetting"
    public var source: BodySource
    public var showMuteFilterSetting: Bool = false
    public var highlight: Bool = false

    public init(source: BodySource = .unknown,
                showMuteFilterSetting: Bool = false,
                highlight: Bool = false) {
        self.source = source
        self.showMuteFilterSetting = showMuteFilterSetting
        self.highlight = highlight
    }
}

public struct FeedSwipeActionSettingBody: PlainBody {
    public static let pattern = "//client/mine/feedSwipeActionSetting"
    public init() {}
}

/// 翻译目标语言设置
public struct TranslateTargetLanguageSettingBody: CodablePlainBody {
    public static let pattern = "//client/mine/translateTargetLanguageSetting"
    public init() {}
}

/// 隐私设置
public struct PrivacySettingBody: CodablePlainBody {
    public static let pattern = "//client/mine/privacySetting"
    public static let appLinkPattern = "/client/setting/privacy/open"

    public init() {}
}

/// 添加我的方式设置
public struct AddMeWaySettingBody: CodablePlainBody {
    public static let pattern = "//client/mine/AddMeWaySetting"
    public static let appLinkPattern = "/client/setting/privacy/add_me_way"

    public init() {}
}

/// 对外展示时区设置
public struct ShowTimeZoneWithOtherBody: CodablePlainBody {
    public static let pattern = "//client/mine/showTimeZone"
    public static let appLinkPattern = "/client/setting/privacy/external_time_zone/open"

    public init() {}
}

/// 个人信息
public struct MinePersonalInformationBody: PlainBody {
    public static var pattern: String = "//client/mine/minePersonalInformation"
    public let completion: (String) -> Void
    public init(completion: @escaping (String) -> Void) {
        self.completion = completion
    }
}

/// 打开网页
public struct SetWebLinkBody: PlainBody {
    public static var pattern: String = "//client/mine/setweblink"

    public let key: String
    public let pageTitle: String
    public let text: String
    public let link: String
    public let successCallBack: (String, String) -> Void?

    public init(key: String, pageTitle: String, text: String, link: String, successCallBack: @escaping (String, String) -> Void?) {
        self.key = key
        self.pageTitle = pageTitle
        self.text = text
        self.link = link
        self.successCallBack = successCallBack
    }
}

/// 设置文本
public struct SetTextBody: PlainBody {
    public static var pattern: String = "//client/mine/settext"

    public let key: String
    public let pageTitle: String
    public let text: String
    public let successCallBack: (String) -> Void?

    public init(key: String, pageTitle: String, text: String, successCallBack: @escaping (String) -> Void?) {
        self.key = key
        self.pageTitle = pageTitle
        self.text = text
        self.successCallBack = successCallBack
    }
}

public enum SetNameType {
    case name /// 姓名
    case anotherName /// 别名
}

/// 修改name
public struct SetNameControllerBody: PlainBody {
    public static var pattern: String = "//client/mine/setName"

    public let oldName: String
    public let nameType: SetNameType
    public init(oldName: String, nameType: SetNameType = .name) {
        self.oldName = oldName
        self.nameType = nameType
    }
}

/// 系统设置 设置页首页
public struct MineSettingBody: CodablePlainBody {
    public static let pattern = "//client/mine/setting"
    public static let appLinkPattern = "/client/setting/section"

    public init() {}
}

/// 工作状态
public struct WorkDescriptionSetBody: PlainBody {
    public static var pattern: String = "//client/mine/workDescription"
    public let completion: (String) -> Void
    public init(completion: @escaping (String) -> Void) {
        self.completion = completion
    }
}

/// 内部设置
public struct InnerSettingBody: PlainBody {
    public static let pattern = "//client/mine/innerSetting"

    public init() {}
}

/// 语言与文字 显示(切换)语言页
public struct MineLanguageSettingBody: PlainBody {
    public static let pattern = "//client/mine/mineLanguageSetting"

    public init() {}
}

/// 不自动翻译语言设置
public struct DisableAutoTranslateLanguagesSettingBody: PlainBody {
    public static let pattern = "//client/mine/autoTranslateLanguagesSetting"

    public init() {}
}

/// 翻译效果高级设置
public struct LanguagesConfigurationSettingBody: PlainBody {
    public static let pattern = "//client/mine/languagesConfigurationSetting"

    public init() {}
}

/// 修改字体
public struct MineFontSettingBody: PlainBody {
    public static let pattern = "//client/mine/fontSetting"

    public init() {}
}

///网络诊断
public struct NetDiagnoseSettingBody: PlainBody {
    public static let pattern = "//client/mine/netDiagnoseSetting"
    public enum Scene: String {
        case workplace        // 开放平台
        case general_setting  // 设置页
        case feed_banner      // feed页
        case app_link         // appLink
    }
    public let from: Scene
    public init(from: Scene) {
        self.from = from
    }
}

/// 星标联系人(特别关注) 设置
public struct SpecialFocusSettingBody: PlainBody {
    public static let pattern = "//client/mine/specialFocusSetting"

    public enum Scene: String {
        case profile
        case setting
    }

    public let from: Scene

    public init(from: Scene) {
        self.from = from
    }
}

/// 接收其他账号消息通知
public struct MultiUserNotificationBody: PlainBody {
    public static let pattern = "//client/mine/multiUserNotificationSetting"
    public init() {}
}

/// 通知诊断页
public struct NotificationDiagnosisBody: PlainBody {
    public static let pattern = "//client/push_diagnose"

    public init() {}
}

/// 通知设置 新的入口
public struct MineNotificationSettingBody: HighlightableBody {

    public static let pattern = "//client/mine/notification"

    public var highlight: String?

    public init(highlight: ItemKey? = nil) {
        if let key = highlight {
            self.highlight = key.rawValue
        }
    }

    /// 需要高亮的条目，可以在这里加，进入设置界面后会高亮
    public enum ItemKey: String {
        case NotifyScopeAll, NotifyScopePartial, NotifyScopeNone
        case SpecialFocusSetting
        case ReceiveCallUsingSystemPhone, SystemCallRecordIntegrateApp
        case VCNotificationUseINStartCallIntent
        case OffDuringCalls
        case DoNotDisturb
        case OffWhenPCOnline, BuzzStillNotify, AtMeStillNotify, SpecialFocusStillNotify
        case AddUrgentNum
        case BannerPreview
        case NotificationDiagnosis
        case CustomizeRinging
    }
}

public protocol AppLanguageService {
    func updateAppLanguage(model: LanguageModel, from: UIViewController)
}
