//
//  HostAppBridge+Service.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/7/1.
//  

import UIKit


public typealias SKMarkFeedSuccess = (String) -> Void
public typealias SKMarkFeedFailure = (Error) -> Void

public final class LaunchCustomerService {
    public init() {}
}

public final class ShareToLarkService {
    public enum ShareType {
        case qq
        case weibo
        case wechatMoments
        case wechat
        case feishu
    }
    public enum ContentType {
        /// 纯文本分享回调
        public typealias TextShareCallback = (_ userIds: [String], _ chatIds: [String]) -> Void
        
        /// 分享云文档链接
        case link(title: String, content: String)
        /// 分享纯文本
        case text(content: String, callback: TextShareCallback? = nil)
        /// 分享图片，name: 废弃字段，传空字符串即可
        case image(name: String, image: UIImage)
    }
    public let contentType: ContentType
    public let fromVC: UIViewController?
    public let shareType: ShareType
    public init(contentType: ContentType,
         fromVC: UIViewController?,
         type: ShareType) {
        self.contentType = contentType
        self.fromVC = fromVC
        self.shareType = type
    }
}

public final class ShowUserProfileService {
    public let userId: String
    public let fromVC: UIViewController
    public let fileName: String?
    public let params: [String: Any]
    public init(userId: String,
                fileName: String? = nil,
                fromVC: UIViewController,
                params: [String: Any] = [:]) {
        self.userId = userId
        self.fromVC = fromVC
        self.fileName = fileName
        self.params = params
    }
}
/// 获取分享面板消息提醒页面
public final class RequestShareAccessory {
    public let feedId: String
    public init(feedId: String) {
        self.feedId = feedId
    }
}

public final class GetDocsManagerDelegateService {
    public init() {}
}

/// 获取Lark FG对象, Lark暂时只支持Bool
public final class GetLarkFeatureGatingService {
    public let key: String
    public let isStatic: Bool
    public let defaultValue: Bool
    public init(key: String, isStatic: Bool, defaultValue: Bool) {
        self.key = key
        self.isStatic = isStatic
        self.defaultValue = defaultValue
    }
}
/// 切换 Lark Tab
public final class SwitchTabService {
    public let path: String
    public let from: UIViewController
    public init(path: String, from: UIViewController) {
        self.path = path
        self.from = from
    }
}

public final class FeedShortcutService {
    public enum Method {
        case get
        case set
    }
    public let feed: String
    public let method: Method

    public var success: SKMarkFeedSuccess?
    public var failure: SKMarkFeedFailure?
    public var isAdd: Bool?

    public init(_ feed: String, _ method: FeedShortcutService.Method) {
        self.feed = feed
        self.method = method
    }

    public func setSuccessBlock(_ success: SKMarkFeedSuccess?) -> Self {
        self.success = success
        return self
    }

    public func setFailureBlock(_ failure: SKMarkFeedFailure?) -> Self {
        self.failure = failure
        return self
    }

    public func setMark(as add: Bool) -> Self {
        self.isAdd = add
        return self
    }
}

/// 获取当前是否正在运行视频会议
public final class GetVCRuningStatusService {
    public init() {}
}

/// 仅用于 DocsSDK 打开 Lark 的 URL，其他 URL 请直接 push
/// 原因是单品内打开 lark 的 URL 时，需要给 webview 设置 Lark 的 UA，因此抛给 LarkSpaceKit / LDSpaceKit 进行处理
/// 目前只有举报的URL需要使用，其他情况使用前请先联系 @wuwenjian.weston
public final class LarkURLService {
    public let url: URL
    public let fromVC: UIViewController?
    public init(url: URL, from: UIViewController?) {
        self.url = url
        fromVC = from
    }
}

public struct GetABTestService {
    public let key: String
    public let shouldExposure: Bool

    public init(key: String, shouldExposure: Bool) {
        self.key = key
        self.shouldExposure = shouldExposure
    }
}

public typealias EnterpriseTopicClickHandle = ((String) -> Void)
public typealias EnterpriseTopicTapApplinkHandle = ((URL) -> Void)
/// 实体词面板操作
public final class EnterpriseTopicActionService {
    public enum Action {
        case show
        case dismiss
    }
    public let action: Action
    public let query: String?
    public let addrId: String?
    public let triggerView: UIView?
    public let triggerPoint: CGPoint?
    public let targetVC: UIViewController?
    public let clientArgs: String?
    public let clickHandle: EnterpriseTopicClickHandle?
    public let tapApplinkHandle: EnterpriseTopicTapApplinkHandle?
    public init(action: Action,
                query: String? = nil,
                addrId: String? = nil,
                triggerView: UIView? = nil,
                triggerPoint: CGPoint? = nil,
                targetVC: UIViewController? = nil,
                clientArgs: String? = nil,
                clickHandle: EnterpriseTopicClickHandle? = nil,
                tapApplinkHandle: EnterpriseTopicTapApplinkHandle? = nil) {
        self.action = action
        self.query = query
        self.addrId = addrId
        self.triggerView = triggerView
        self.triggerPoint = triggerPoint
        self.targetVC = targetVC
        self.clientArgs = clientArgs
        self.clickHandle = clickHandle
        self.tapApplinkHandle = tapApplinkHandle
    }
}

public final class ResponderService {
    public let responder: UIResponder
    public init(responder: UIResponder) {
        self.responder = responder
    }
}
