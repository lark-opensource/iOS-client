//
//  LarkShareContainerMaterial.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2020/12/16.
//

import UIKit
import Foundation
import RxSwift
import RustPB

// 分享容器 tab 类型
public enum ShareTabType: String {
    case viaChat
    case viaLink
    case viaQRCode
}

// 会话选择模式
public enum ViaChatSelectMode {
    // 单选
    case single
    // 单选或多选
    case all
}

// 头像样式
public enum IconShapeType {
    // 圆形
    case circle
    // 带圆角矩形
    case roundRect
}

// 通过选择会话分享时的配置
public struct ViaChatChooseConfig {
    public enum ChatChooseType: Int {
        case all = 0     // 全部
        case group = 1   // 群聊
        case user = 2   // 单聊
    }

    public let allowCreateGroup: Bool
    public let multiSelect: Bool
    public let ignoreSelf: Bool
    public let ignoreBot: Bool
    // 外部联系人
    public let needSearchOuterTenant: Bool
    // 外部群组
    public let includeOuterChat: Bool
    public let selectType: ChatChooseType
    // 不传展示默认的文案 `发送到:`
    public let confirmTitle: String?
    // 展示的确认框描述，当inputView显示时无效
    public let confirmDesc: String
    // 是否展示留言输入框，与confirmDesc互斥
    public let showInputView: Bool

    public init(
        allowCreateGroup: Bool,
        multiSelect: Bool,
        ignoreSelf: Bool,
        ignoreBot: Bool,
        needSearchOuterTenant: Bool = true,
        includeOuterChat: Bool = true,
        selectType: ViaChatChooseConfig.ChatChooseType,
        confirmTitle: String? = nil,
        confirmDesc: String = "",
        showInputView: Bool = true
    ) {
        self.allowCreateGroup = allowCreateGroup
        self.multiSelect = multiSelect
        self.ignoreSelf = ignoreSelf
        self.ignoreBot = ignoreBot
        self.needSearchOuterTenant = needSearchOuterTenant
        self.includeOuterChat = includeOuterChat
        self.selectType = selectType
        self.confirmTitle = confirmTitle
        self.confirmDesc = confirmDesc
        self.showInputView = showInputView
    }

    public static func `default`() -> ViaChatChooseConfig {
        return ViaChatChooseConfig(
            allowCreateGroup: true,
            multiSelect: true,
            ignoreSelf: false,
            ignoreBot: true,
            needSearchOuterTenant: true,
            includeOuterChat: true,
            selectType: .all,
            confirmTitle: nil,
            confirmDesc: "",
            showInputView: true
        )
    }
}

// 通过选择会话分享的物料
public struct ShareViaChooseChatMaterial {
    public enum ItemType: Int {
        case unknown = -1
        case user = 0
        case chat = 1
        case bot = 2
    }

    public struct SelectContext {
        public let itemType: ItemType
        public let chatId: String
        public let chatterId: String?
        public let avatarKey: String?

        public init(
            itemType: ItemType,
            chatId: String,
            chatterId: String?,
            avatarKey: String?
        ) {
            self.itemType = itemType
            self.chatId = chatId
            self.chatterId = chatterId
            self.avatarKey = avatarKey
        }
    }

    public struct ShareInput {
        public var string: String?
        public var attributedString: NSAttributedString?
        public var richText: RustPB.Basic_V1_RichText?

        public init() {}
    }

    public let config: ViaChatChooseConfig
    // 选择会话的回调，接入者负责返回异步流（比如dismiss分享容器需要依赖异步推送消息成功）
    public let selectHandler: (_ contexts: [SelectContext], _ input: String?) -> Observable<Void>
    // 带有富文本的选择会话的回调
    public var selectHandlerWithShareInput: ((_ contexts: [SelectContext], _ input: ShareInput?) -> Observable<Void>)?

    public init(
        config: ViaChatChooseConfig = ViaChatChooseConfig.default(),
        selectHandler: @escaping (_ contexts: [SelectContext], _ input: String?) -> Observable<Void>
    ) {
        self.config = config
        self.selectHandler = selectHandler
    }
}

// 选择会话Tab需要的初始物料
public struct ViaChatTabMeterial {
    public let tabName: String
    public let material: ShareViaChooseChatMaterial

    public init(
        tabName: String,
        material: ShareViaChooseChatMaterial
    ) {
        self.tabName = tabName
        self.material = material
    }
}

// 链接Tab需要的初始物料
public struct ViaLinkTabMeterial {
    public let tabName: String

    public init(tabName: String) {
        self.tabName = tabName
    }
}

// 二维码Tab需要的初始物料
public struct ViaQRCodeTabMaterial {
    public let tabName: String
    public let canShareToExternal: Bool

    public init(
        tabName: String,
        canShareToExternal: Bool
    ) {
        self.tabName = tabName
        self.canShareToExternal = canShareToExternal
    }
}

// Tab需要的初始物料
public enum TabMaterial: Hashable {
    case viaChat(ViaChatTabMeterial)
    case viaLink(ViaLinkTabMeterial)
    case viaQRCode(ViaQRCodeTabMaterial)

    public func type() -> ShareTabType {
        switch self {
        case .viaChat: return .viaChat
        case .viaLink: return .viaLink
        case .viaQRCode: return .viaQRCode
        }
    }

    public func title() -> String {
        switch self {
        case .viaChat(let meterial):
            return meterial.tabName
        case .viaLink(let meterial):
            return meterial.tabName
        case .viaQRCode(let meterial):
            return meterial.tabName
        }
    }

    public var rawValue: String {
        return type().rawValue
    }

    public static func == (lhs: TabMaterial, rhs: TabMaterial) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(rawValue)
    }
}
