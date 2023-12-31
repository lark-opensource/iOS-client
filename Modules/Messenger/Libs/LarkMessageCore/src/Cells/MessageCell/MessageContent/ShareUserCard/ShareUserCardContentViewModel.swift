//
//  ShareUserCardContentViewModel.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2020/4/21.
//

import UIKit
import Foundation
import RxSwift
import LarkModel
import LarkMessageBase
import EENavigator
import LarkSDKInterface
import LarkSetting
import LarkMessengerInterface
import LarkUIKit
import LarkCore
import RustPB

public final class ShareUserCardContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ShareUserCardContentContext>: MessageSubViewModel<M, D, C> {

    private let shareUserCardContentConfig: ShareUserCardContentConfig

    public init(metaModel: M,
                metaModelDependency: D,
                context: C,
                binder: ComponentBinder<C>,
                shareUserCardContentConfig: ShareUserCardContentConfig = ShareUserCardContentConfig()) {
        self.shareUserCardContentConfig = shareUserCardContentConfig
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override var identifier: String {
        return "share-UserCard"
    }

    public var content: ShareUserCardContent {
        return (self.message.content as? ShareUserCardContent) ?? .transform(pb: RustPB.Basic_V1_Message())
    }

    public var contentPreferMaxWidth: CGFloat {
        return metaModelDependency.getContentPreferMaxWidth(message)
    }

    public override var contentConfig: ContentConfig? {
        var contentConfig = ContentConfig(hasMargin: false, backgroundStyle: .white, maskToBounds: true, supportMutiSelect: true, hasBorder: true)
        contentConfig.isCard = true
        return contentConfig
    }

    public var hasPaddingBottom: Bool {
        if let hasPaddingBottom = shareUserCardContentConfig.hasPaddingBottom {
            return hasPaddingBottom
        }
        if (self.context.scene == .newChat || self.context.scene == .mergeForwardDetail), !message.reactions.isEmpty, !self.message.showInThreadModeStyle { return false }
        return true
    }

    private var senderName: String {
        // 获取不到 originalSender 时使用 fromChatter 兜底
        if let chatter = self.message.originalSender {
            return chatter.displayWithAnotherName
        } else if let chatter = self.message.fromChatter {
            return chatter.displayWithAnotherName
        }
        return ""
    }

    public func cardTapped() {
        if self.context.scene == .newChat || self.context.scene == .threadChat {
            IMTracker.Chat.Main.Click.Msg.ShareUserCard(self.metaModel.getChat(), self.message, context.trackParams[PageContext.TrackKey.sceneKey] as? String)
        } else if self.context.scene == .threadDetail || self.context.scene == .replyInThread {
            ChannelTracker.TopicDetail.Click.Msg.ShareUserCard(self.metaModel.getChat(), self.message)
        }
        let body = PersonCardBody(chatterId: content.shareChatterID,
                                  sender: self.senderName,
                                  source: .nameCard)
        if Display.phone {
            self.context.navigator(type: .push, body: body, params: nil)
        } else {
            self.context.navigator(type: .present, body: body, params: NavigatorParams(wrap: LkNavigationController.self, prepare: { vc in
                vc.modalPresentationStyle = .formSheet
            }))
        }
    }
}
