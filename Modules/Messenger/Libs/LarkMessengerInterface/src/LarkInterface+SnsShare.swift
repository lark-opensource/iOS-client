//
//  LarkInterface+SnsShare.swift
//  LarkMessengerInterface
//
//  Created by shizhengyu on 2020/5/10.
//

import UIKit
import Foundation
import LarkSnsShare

/// 结构参考自 ShareImageBody
public struct ImageContentInLark {
    public let name: String
    public let image: UIImage
    public let type: ShareImageType
    public let needFilterExternal: Bool
    public let cancelCallBack: (() -> Void)?
    public let successCallBack: (() -> Void)?
    public var shareResultsCallBack: (([(String, Bool)]?) -> Void)?

    public init(name: String,
                image: UIImage,
                type: ShareImageType,
                needFilterExternal: Bool,
                cancelCallBack: (() -> Void)?,
                successCallBack: (() -> Void)?) {
        self.name = name
        self.image = image
        self.type = type
        self.needFilterExternal = needFilterExternal
        self.cancelCallBack = cancelCallBack
        self.successCallBack = successCallBack
    }
}

/// 结构参考自 ForwardTextBody
public struct TextContentInLark {
    public typealias SendHandler = (_ userIds: [String], _ chatIds: [String]) -> Void
    public let text: String
    public let sendHandler: SendHandler?
    public var shareResultsCallBack: (([(String, Bool)]?) -> Void)?

    public init(text: String, sendHandler: SendHandler?) {
        self.text = text
        self.sendHandler = sendHandler
    }
}

public struct URLContentInLark {
    /// - Parameter:
    ///    - userIds: 单聊id
    ///    - chatIds: 群聊id
    public typealias SendHandler = (_ userIds: [String], _ chatIds: [String]) -> Void
    public let url: String
    public let ShareTextSuccessCallBack: SendHandler?
    public let image: UIImage
    public let imageShareType: ShareImageType
    public let imageNeedFilterExternal: Bool
    public let ShareImageSuccessCallBack: (() -> Void)?

    public init(url: String,
                image: UIImage,
                imageShareType: ShareImageType,
                imageNeedFilterExternal: Bool,
                ShareTextSuccessCallBack: SendHandler?,
                ShareImageSuccessCallBack: (() -> Void)?) {
        self.url = url
        self.image = image
        self.imageShareType = imageShareType
        self.imageNeedFilterExternal = imageNeedFilterExternal
        self.ShareTextSuccessCallBack = ShareTextSuccessCallBack
        self.ShareImageSuccessCallBack = ShareImageSuccessCallBack
    }
}

public enum InAppShareContent {
    case image(content: ImageContentInLark)
    case text(content: TextContentInLark)
    case url(content: URLContentInLark)
}

/// 内部提供应用内分享的路由实现、注册飞书/Lark的icon和i18n文案
public protocol InAppShareService {
    /// 用于动态分享配置（推荐）
    func genInAppShareContext(content: InAppShareContent) -> CustomShareContext
    /// 用于静态分享配置
    func genInAppShareItem(content: InAppShareContent) -> LarkShareItemType
}
