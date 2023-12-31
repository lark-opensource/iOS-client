//
//  BasicDataStructure.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/11/16.
//

import Foundation
import UIKit

// MARK: 基础数据类型
public enum PanelType {
    case actionPanel
    case imagePanel
}
/// 自定义分享面板item
public struct CustomShareItemContext {
    public let title: String
    public let icon: UIImage
    public init(title: String, icon: UIImage) {
        self.title = title
        self.icon = icon
    }
}

public struct URLContent {
    public let url: String
    public let image: UIImage
    public init(url: String, image: UIImage) {
        self.url = url
        self.image = image
    }
}

/// 自定义分享内容
public enum CustomShareContent {
    public typealias Text = String
    public typealias Image = UIImage
    public typealias Context = [String: Any]

    case text(Text, Context)
    case image(Image, Context)
    case url(URLContent, Context)
}

/// 自定义渠道上下文
public struct CustomShareContext {
    public let identifier: String  // 用于区分开不同 custom item
    public let itemContext: CustomShareItemContext
    public let content: CustomShareContent
    // 传回的 UIViewController 实例即分享面板，业务方自行控制 action 后是否需要 dismiss
    public let action: (CustomShareContent, UIViewController, PanelType) -> Void
    public init(identifier: String = "",
                itemContext: CustomShareItemContext,
                content: CustomShareContent,
                action: @escaping (CustomShareContent, UIViewController, PanelType) -> Void) {
        self.identifier = identifier
        self.itemContext = itemContext
        self.content = content
        self.action = action
    }

    public static func `default`() -> CustomShareContext {
        let itemContext = CustomShareItemContext(
            title: "",
            icon: UIImage()
        )
        let content = CustomShareContent.text("", [:])
        return CustomShareContext(
            identifier: "custom",
            itemContext: itemContext,
            content: content,
            action: { (_, _, _) in }
        )
    }
}

public struct LarkSystemShareContext {
    public let type: UIActivity.ActivityType?

    public static var `default` = LarkSystemShareContext(type: nil)
}

/// 自定义分享面板的item type
public enum LarkShareItemType: Hashable {
    case wechat   // 微信选择联系人
    case weibo   // 微博
    case qq   // QQ
    case copy   // 复制(仅对文本有效)
    case more(LarkSystemShareContext)   // 系统分享
    case timeline   // 微信朋友圈
    case save   // 保存(仅对图片视频有效)
    case shareImage
    case unknown  // 未知渠道
    case custom(CustomShareContext)  // 自定义渠道

    // disable-lint: magic number
    public var rawValue: Int {
        switch self {
        case .wechat: return 0
        case .weibo: return 1
        case .qq: return 2
        case .copy: return 3
        case .more: return 4
        case .timeline: return 6
        case .save: return 7
        case .shareImage: return 8
        case .unknown: return 99
        case .custom: return 999
        }
    }

    /// JSB -> Native
    public static func transform(rawVaule: Int) -> LarkShareItemType {
        switch rawVaule {
        case 0: return .wechat
        case 1: return .weibo
        case 2: return .qq
        case 3: return .copy
        case 4: return .more(.default)
        case 6: return .timeline
        case 7: return .save
        case 8: return .shareImage
        case 999: return .custom(CustomShareContext.default())
        default: return .unknown
        }
    }
    // enable-lint: magic number

    /// SettingsV3 -> Native
    public static func transform(dynamicItem: String) -> LarkShareItemType {
        switch dynamicItem {
        case "wechat_session": return .wechat
        case "wechat_timeline": return .timeline
        case "qq": return .qq
        case "weibo": return .weibo
        case "copy_text": return .copy
        case "save_image": return .save
        case "share_image": return .shareImage
        case "system_share": return .more(.default)
        case "inapp": return .custom(CustomShareContext.default())
        default: return .unknown
        }
    }

    public static func snsItems() -> [LarkShareItemType] {
        return [.wechat, .weibo, .qq, .more(.default), .timeline]
    }

    public static func == (lhs: LarkShareItemType, rhs: LarkShareItemType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(rawValue)
    }
}

/// 分享结果
public enum ShareResult {
    public enum ErrorCode: Int {
    /// 应用未安装
    case notInstalled = 101
    /// 图片/视频保存失败
    case saveImageFailed = 102
    /// 用户手动取消
    case userCanceledManually = 103
    /// 来自各三方应用、系统分享的报错
    case snsDominError = 200
    /// 触发了降级拦截处理
    case triggleDowngradeHandle = 300
    /// 动态化配置解析失败（配置不符合预期，比如缺失了部分关键的 key，比如 items key 不存在，又或是 json 格式不正确导致解析失败）
    case dynamicConfParseFailed = 400
    /// 动态化配置解析成功，但配置参数不合规（比如 answer_type 拼写错误、trace_id 为空等）
    case illegalConfigurationStruct = 401
    /// 动态化配置解析成功，但与业务方传入的 traceId 不匹配
    case traceIdNotFound = 402
    /// 获取动态配置失败
    case dynamicConfFetchFailed = 500
    /// 未知错误(比如系统分享时的一些系统报错，或当前不支持分享该渠道等)
    case unknownError = 999
    }
    public typealias DebugMsg = String

    case success
    case failure(ErrorCode, DebugMsg)

    public func isSuccess() -> Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }

    public func isFailure() -> Bool {
        !isSuccess()
    }
}

/// 常用社交平台的type
public enum SnsType: String {
    case wechat
    case qq
    case weibo
}

/// 唤醒错误
public enum WakeupError {
    case notInstalled
    case sdkWakeupFailed
    case notSupported
}

/// 唤醒结果
public typealias SnsWakeUpResult = (Bool, WakeupError?)

/// 分享具体场景
public enum SnsScenes: String {
    // 微信
    case wechatSession // 微信会话
    case wechatTimeline // 微信朋友圈
    case wechatFavorite // 微信收藏
    case wechatSpecifiedSession // 微信指定联系人
    // QQ
    case qqSpecifiedSession // qq指定联系人
    case qqZone // qq空间
    // 微博: 暂无场景区分
}

/// 分享内容类型
public enum ShareContentType: Hashable {
    case text     // 纯文本
    case image    // 图片
    case webUrl   // web链接
    case video    // 视频，暂不支持
    case miniProgram  // 小程序
    case unknown  // 未知

    public var rawValue: String {
        switch self {
        case .text: return "text"
        case .image: return "image"
        case .webUrl: return "web_url"
        case .video: return "video"
        case .miniProgram: return "mini_program"
        case .unknown: return "unknown"
        }
    }

    public static func transform(rawValue: String) -> ShareContentType {
        switch rawValue {
        case "text": return .text
        case "image": return .image
        case "web_url": return .webUrl
        case "video": return .video
        case "mini_program": return .miniProgram
        default: return .unknown
        }
    }

    public static func == (lhs: ShareContentType, rhs: ShareContentType) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(rawValue)
    }
}

/// 纯文本分享所需准备的数据
public struct TextPrepare {
    public let content: String
    public let customCallbackUserInfo: [AnyHashable: Any]

    public init(
        content: String,
        customCallbackUserInfo: [AnyHashable: Any] = [:]
    ) {
        self.content = content
        self.customCallbackUserInfo = customCallbackUserInfo
    }
}

/// 纯图片分享所需准备的数据
public struct ImagePrepare {
    public let title: String
    public let image: UIImage
    public let description: String
    public let customCallbackUserInfo: [AnyHashable: Any]

    public init(
        title: String,
        image: UIImage,
        description: String = "",
        customCallbackUserInfo: [AnyHashable: Any] = [:]
    ) {
        self.title = title
        self.image = image
        self.description = description
        self.customCallbackUserInfo = customCallbackUserInfo
    }
}

/// 网页链接分享所需准备的数据
public struct WebUrlPrepare {
    public let title: String
    public let webpageURL: String
    public let imageURL: String
    public let thumbnailImage: UIImage?
    public let description: String
    public let customCallbackUserInfo: [AnyHashable: Any]

    public init(
        title: String,
        webpageURL: String,
        imageURL: String = "",
        thumbnailImage: UIImage? = nil,
        description: String = "",
        customCallbackUserInfo: [AnyHashable: Any] = [:]
    ) {
        self.title = title
        self.webpageURL = webpageURL
        self.imageURL = imageURL
        self.thumbnailImage = thumbnailImage
        self.description = description
        self.customCallbackUserInfo = customCallbackUserInfo
    }
}

/// 小程序分享所需准备的数据
public struct MiniProgramPrepare {
    public let title: String
    public let webPageURLString: String
    public let miniProgramUserName: String  // 小程序原始ID
    public let miniProgramPath: String  // 小程序path
    public let launchMiniProgram: Bool
    public let thumbnailImage: UIImage
    public let description: String

    public init(
        title: String,
        webPageURLString: String,
        miniProgramUserName: String,
        miniProgramPath: String,
        launchMiniProgram: Bool,
        thumbnailImage: UIImage,
        description: String
    ) {
        self.title = title
        self.webPageURLString = webPageURLString
        self.miniProgramUserName = miniProgramUserName
        self.miniProgramPath = miniProgramPath
        self.launchMiniProgram = launchMiniProgram
        self.thumbnailImage = thumbnailImage
        self.description = description
    }
}

/// 分享内容上下文
public enum ShareContentContext {
    case text(TextPrepare)
    case image(ImagePrepare)
    case webUrl(WebUrlPrepare)
    case miniProgram(MiniProgramPrepare)

    public func type() -> ShareContentType {
        switch self {
        case .text: return .text
        case .image: return .image
        case .webUrl: return .webUrl
        case .miniProgram: return .miniProgram
        }
    }
}

/// 分享降级弹窗物料，用于分享动态配置内设置 `answer_type = downgrade_to_wakeup_by_tip` 的场景
/// 详见 https://bytedance.feishu.cn/docs/doccngbnlPSCV7NQ7CuXLy19RJn#
public enum DowngradeTipPanelMaterial {
    /// 如果分享内容为纯文本或链接形式：
    /// 面板标题文案可选，不传则取的是组件内部预设的文案 - `已复制到剪贴板`；
    /// 面板展示内容可选，不传则取的是shareContentContext里的content或webpageUrl；
    case text(panelTitle: String?, content: String?)

    /// 如果分享内容为图片形式：
    /// 面板标题文案可选，不传则取的是组件内部预设的文案 - `已保存至相册`；
    /// 面板无展示内容；
    case image(panelTitle: String?)
}

// iPad 平台 popover 展示态的物料
public struct PopoverMaterial {
    public let sourceView: UIView
    public let sourceRect: CGRect
    public let direction: UIPopoverArrowDirection

    public init(
        sourceView: UIView,
        sourceRect: CGRect,
        direction: UIPopoverArrowDirection
    ) {
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.direction = direction
    }
}
