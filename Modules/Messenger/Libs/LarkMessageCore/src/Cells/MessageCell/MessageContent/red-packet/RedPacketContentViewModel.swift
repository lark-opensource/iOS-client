//
//  RedPacketContentViewModel.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/6/10.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import EENavigator
import ByteWebImage
import LarkSDKInterface
import LarkMessengerInterface
import UniverseDesignToast
import RustPB

public class RedPacketContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: RedPacketContentContext>: MessageSubViewModel<M, D, C> {
    override public var identifier: String {
        return "red-packet"
    }

    private var content: HongbaoContent {
        return (self.message.content as? HongbaoContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    private var hasMarginAndBorder: Bool {
        if context.contextScene == .newChat {
            return !message.parentId.isEmpty || !message.reactions.isEmpty
        }
        return false
    }

    public var contentPreferMaxWidth: CGFloat {
        if self.context.contextScene == .newChat, message.showInThreadModeStyle {
            return self.metaModelDependency.getContentPreferMaxWidth(self.message)
        }
        if hasMarginAndBorder {
            return metaModelDependency.getContentPreferMaxWidth(message) - 2 * metaModelDependency.contentPadding
        } else {
            return metaModelDependency.getContentPreferMaxWidth(message)
        }
    }

    public var mainTip: String {
        return content.subject
    }

    var chatComponentTheme: ChatComponentTheme {
        let scene = self.context.getChatThemeScene()
        return ChatComponentThemeManager.getComponentTheme(scene: scene)
    }

    public var isCustomCover: Bool {
        content.cover.hasID
    }

    public var isExclusive: Bool {
        return content.type == .exclusive
    }

    // 红包类型描述
    public var typeDescription: String {
        if content.type == .exclusive {
            return BundleI18n.LarkMessageCore.Lark_DesignateRedPacket_DesignatedRedPacket_Label
        } else if content.type == .groupRandom {
            return BundleI18n.LarkMessageCore.Lark_Legacy_RandomHongbao
        } else if content.type == .b2CFix || content.type == .b2CRandom {
            return BundleI18n.LarkMessageCore.Lark_OrgRedPacket_RedPacketAssistant_PacketCoverOrg
        } else {
            return BundleI18n.LarkMessageCore.Lark_Legacy_NormalAmount
        }
    }

    // 企业标识图
    public var companyImagePassThrough: ImagePassThrough {
        var pass = ImagePassThrough()
        pass.key = content.cover.companyLogo.key
        pass.fsUnit = content.cover.companyLogo.fsUnit
        return pass
    }

    public var hongbaoCoverDisplayName: HongbaoCoverDisplayName? {
        content.cover.hasDisplayName ? content.cover.displayName : nil
    }

    /// 企业红包的名字
    var b2cCoverDisplayName: String? {
        if isB2CHongbao {
            return content.cover.companyName
        }
        return nil
    }

    /// 是否是企业红包
    var isB2CHongbao: Bool {
        return (content.type == .b2CFix || content.type == .b2CRandom)
    }

    // 封面图
    public var coverImagePassThrough: ImagePassThrough {
        var pass = ImagePassThrough()
        pass.key = content.cover.messageCover.key
        pass.fsUnit = content.cover.messageCover.fsUnit
        return pass
    }

    /// 专属红包部分可领取用户
    var previewChatters: [Chatter]? {
        if content.type == .exclusive {
            return content.previewChatters
        }
        return nil
    }

    /// 专属红包总人数
    var totalNum: Int32? {
        if content.type == .exclusive {
            return content.totalNum
        }
        return nil
    }

    // 红包领取状态
    // https://bytedance.feishu.cn/docs/doccnQwkRo9vePEZFMsNiQi4akh#Cz3rsC
    public var statusText: String {
        if context.isMe(message.fromId, chat: metaModel.getChat()) {
            if content.isGrabbedFinish {
                return BundleI18n.LarkMessageCore.Lark_Legacy_HongbaoNoneLeft
            }
            if content.isGrabbed {
                return BundleI18n.LarkMessageCore.Lark_Legacy_HongbaoOpened
            }
            if content.isExpired {
                return BundleI18n.LarkMessageCore.Lark_Legacy_HongbaoExpired
            }
            return ""
        }
        if content.canGrab {
            if content.isGrabbed {
                return BundleI18n.LarkMessageCore.Lark_Legacy_HongbaoOpened
            }
            if content.isGrabbedFinish {
                return BundleI18n.LarkMessageCore.Lark_Legacy_HongbaoNoneLeft
            }
            if content.isExpired {
                return BundleI18n.LarkMessageCore.Lark_Legacy_HongbaoExpired
            }
            return ""
        }
        if content.type != .exclusive,
            content.isGrabbedFinish {
            return BundleI18n.LarkMessageCore.Lark_Legacy_HongbaoNoneLeft
        }
        if content.isExpired {
            return BundleI18n.LarkMessageCore.Lark_Legacy_HongbaoExpired
        }
        return ""
    }

    // 是否显示蒙层
    public var isShowShadow: Bool {
        if content.type == .exclusive {
            if content.isExpired {
                return true
            }
            if context.isMe(message.fromId, chat: metaModel.getChat()) {
                return content.isGrabbedFinish || content.isGrabbed
            }
            if content.canGrab {
                return content.isGrabbed
            }
            return content.clicked
        }

        if content.isGrabbed
            || content.isExpired
            || content.isGrabbedFinish {
            return true
        }
        return false
    }

    public var shouldAddFillet: Bool {
        return hasMarginAndBorder
    }

    public func redPacketButtonTapped() {
        let chat = self.metaModel.getChat()
        if chat.isInMeetingTemporary {
            if let targetVC = self.context.targetVC {
                UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_TemporaryJoinMeetingFunctionUnavailableNotice_Desc, on: targetVC.view)
            }
            return
        }
        LarkMessageCoreTracker.imChatMainClick(chat: chat,
                                               target: "none",
                                               click: "hongbao",
                                               msgId: self.message.id,
                                               hongbaoType: self.content.type,
                                               hongbaoId: self.content.id)
        let body = OpenRedPacketBody(chatId: self.metaModel.getChat().id, model: .message(message: message))
        context.navigator(type: .open, body: body, params: nil)
    }

    public override var contentConfig: ContentConfig? {
        let selectedEnable = context.getMessageSelectedEnable(message)
        if hasMarginAndBorder {
            var contentConfig = ContentConfig(
                hasMargin: true,
                maskToBounds: true,
                supportMutiSelect: true,
                selectedEnable: selectedEnable,
                hasBorder: true
            )
            contentConfig.borderStyle = .other
            return contentConfig
        }
        return ContentConfig(
            hasMargin: false,
            backgroundStyle: .clear,
            maskToBounds: true,
            supportMutiSelect: true,
            selectedEnable: selectedEnable
        )
    }
}

public final class MessageDetailRedPacketContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: RedPacketContentContext>: RedPacketContentViewModel<M, D, C> {
    override public var shouldAddFillet: Bool {
        return true
    }
}
