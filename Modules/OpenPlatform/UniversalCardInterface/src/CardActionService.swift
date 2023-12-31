//
//  File.swift
//  UniversalCardInterface
//
//  Created by ByteDance on 2023/8/10.
//

import RustPB
import ECOProbe
import Foundation
import UniverseDesignToast

public enum UniversalCardLinkFromType {
    case cardLink(reason: String? = nil)
    case innerLink(reason: String? = nil)
    case footerLink(reason: String? = nil)

    public func reason() -> String? {
        switch self {
        case .cardLink(let reason):
            return reason
        case .innerLink(let reason):
            return reason
        case .footerLink(let reason):
            return reason
        }
    }
}

public protocol CardActionContextProtocol {
    func toDict() ->[String: Any]
}

public struct UniversalCardPersonInfo {
    public let name: String
    public let avatarKey: String
    public init(name: String, avatarKey: String) {
        self.name = name
        self.avatarKey = avatarKey
    }
}

public struct UniversalCardActionContext {
    public let trace: OPTrace
    public let elementTag: String?
    public let elementID: String?
    public let bizContext: Any?
    public var actionFrom: UniversalCardLinkFromType?
    public init(
        trace: OPTrace,
        elementTag: String? = nil,
        elementID: String? = nil,
        bizContext: Any? = nil,
        actionFrom: UniversalCardLinkFromType? = nil
    ) {
        self.trace = trace
        self.elementTag = elementTag
        self.elementID = elementID
        self.bizContext = bizContext
        self.actionFrom = actionFrom
    }
}

public enum UniversalCardRequestResultType: String {
    case RequestFinished = "requestFinished"
    case FinishedWaitUpdate = "finishedWaitUpdate"
}

public protocol UniversalCardActionServiceProtocol {
    typealias CardVersion = String
    typealias CardStatus = String

    // 打开链接
    func openUrl(
        context: UniversalCardActionContext,
        cardID: String?,
        urlStr: String?,
        from: UIViewController,
        callback:((Error?) -> Void)?
    )

    // 发送请求
    func sendRequest(
        context: UniversalCardActionContext,
        cardSource: UniversalCardDataActionSourceInfo,
        actionID: String,
        params: [String: String]?,
        callback:((Error?, UniversalCardRequestResultType?) -> Void)?
    )

    // 打开用户 profile 页面
    func openProfile(
        context: UniversalCardActionContext,
        id: String,
        from: UIViewController
    )

    func getChatID() -> String?

    // 存储本地数据
    func updateLocalData(
        context: UniversalCardActionContext,
        bizID: String,
        cardID: String,
        version: String,
        data: String,
        callback: @escaping (Error?, CardVersion?, CardStatus?) -> Void)

    // 弹出提示
    func showToast(
        context: UniversalCardActionContext,
        type: UDToastType,
        text: String,
        on view: UIView?
    )

    // 批量获取用户信息
    func fetchUsers(
        context: UniversalCardActionContext,
        ids: [String],
        callback: @escaping (Error?, [String: UniversalCardPersonInfo]?) -> Void
    )

    // 预览图片, 给的是当前卡片的图片属性数组和序号
    func showImagePreview(
        context: UniversalCardActionContext,
        properties: [RustPB.Basic_V1_RichTextElement.ImageProperty],
        index: Int,
        from: UIViewController
    )
    
    // 更新摘要
    func updateSummary(
        context: UniversalCardActionContext,
        original: String,
        translation: String)
    
    // 打开代码块详细页
    func openCodeBlockDetail(
        context: UniversalCardActionContext,
        property: Basic_V1_RichTextElement.CodeBlockV2Property,
        from: UIViewController
    )

    // 获取翻译配置
    func getTranslateConfig() -> UniversalCardConfig.TranslateConfig?
}
