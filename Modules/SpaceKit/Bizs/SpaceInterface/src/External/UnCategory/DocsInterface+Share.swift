//
//  DocsInterface+Share.swift
//  SpaceInterface
//
//  Created by CJ on 2021/6/25.
//

import Foundation
import EENavigator

public protocol DocShareViewControllerDependency {
    /// 打开doc分享面板
    func openDocShareViewController(body: DocShareViewControllerBody, from: UIViewController?)
}

public struct DocShareViewControllerBody: PlainBody {
    public static let pattern = "//client/docs/share"
    // 文档token
    public var token: String
    // 文档类型
    public var type: Int
    // 是否是owner
    public var isOwner: Bool
    // ownerId
    public var ownerId: String
    // ownerName
    public var ownerName: String
    // 文档url
    public var url: String
    // 文档title
    public var title: String
    // 文档所属租户
    public var tenantID: String
    // 是否支持iPad popover样式
    public var needPopover: Bool?
    // 如果支持iPad popover样式，需要传padPopDirection/popoverSourceFramesourceView/
    public var padPopDirection: UIPopoverArrowDirection?
    public var popoverSourceFrame: CGRect?
    public var sourceView: UIView?
    // 是否是vc投屏模式
    public var isInVideoConference: Bool
    // 适配多窗口
    public weak var hostViewController: UIViewController?

    ///允许密码分享
    public var enableShareWithPassWord: Bool
    ///允许转移owner
    public var enableTransferOwner: Bool
    // 文档是否来自 Phoenix，影响复制链接的 URL path，目前 CCM 外部暂无场景使用
    public var isFromPhoenix: Bool

    public var scPasteImmunity: Bool

    public init(token: String,
                type: Int,
                isOwner: Bool,
                ownerId: String,
                ownerName: String,
                url: String,
                title: String,
                tenantID: String,
                enableShareWithPassWord: Bool = true,
                enableTransferOwner: Bool = true,
                isFromPhoenix: Bool = false,
                needPopover: Bool? = nil,
                padPopDirection: UIPopoverArrowDirection? = nil,
                popoverSourceFrame: CGRect? = nil,
                sourceView: UIView? = nil,
                isInVideoConference: Bool,
                hostViewController: UIViewController,
                scPasteImmunity: Bool = false) {
        self.token = token
        self.type = type
        self.isOwner = isOwner
        self.ownerId = ownerId
        self.ownerName = ownerName
        self.url = url
        self.title = title
        self.tenantID = tenantID
        self.needPopover = needPopover
        self.padPopDirection = padPopDirection
        self.popoverSourceFrame = popoverSourceFrame
        self.sourceView = sourceView
        self.isInVideoConference = isInVideoConference
        self.hostViewController = hostViewController
        self.enableTransferOwner = enableTransferOwner
        self.enableShareWithPassWord = enableShareWithPassWord
        self.isFromPhoenix = isFromPhoenix
        self.scPasteImmunity = scPasteImmunity
    }
}
