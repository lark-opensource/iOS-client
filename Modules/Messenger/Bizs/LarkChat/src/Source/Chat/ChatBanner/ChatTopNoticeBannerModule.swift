//
//  ChatTopNoticeBannerModule.swift
//  LarkChat
//
//  Created by liluobin on 2021/11/4.
//

import Foundation
import UIKit
import RxSwift
import LarkOpenChat
import LarkOpenIM
import LarkCore
import LarkMessageCore
import LarkFeatureGating
import LarkMessengerInterface
import LarkSetting
/// 消息置顶
public final class ChatTopNoticeBannerModule: ChatBannerSubModule {

    public override class var name: String { "ChatTopNoticeBannerModule" }

    public override var type: ChatBannerType {
        return .chatTopNotice
    }

    private let disposeBag = DisposeBag()

    private var topNoticeView: UIView?

    public override func contentView() -> UIView? {
        return self.topNoticeView
    }

    public override class func canInitialize(context: ChatBannerContext) -> Bool {
        return true
    }

    /// 小组，密聊等不支持置顶消息
    public override func canHandle(model: ChatBannerMetaModel) -> Bool {
        if ChatNewPinConfig.checkEnable(chat: model.chat, self.context.userResolver.fg) {
            return false
        }
        if let topNoticeService = try? self.context.resolver.resolve(assert: ChatTopNoticeService.self) {
            return topNoticeService.isSupportTopNoticeChat(model.chat)
        }
        return false
    }

    public override func handler(model: ChatBannerMetaModel) -> [Module<ChatBannerContext, ChatBannerMetaModel>] {
        return [self]
    }

    public override func createViews(model: ChatBannerMetaModel) {
        super.createViews(model: model)
        self.display = false
        guard let chatOpenService = try? self.context.resolver.resolve(assert: ChatOpenService.self),
              let topNoticeService = try? self.context.resolver.resolve(assert: ChatTopNoticeService.self),
              let wrappar = try? self.context.resolver.resolve(assert: ChatPushWrapper.self, argument: model.chat),
              let chatVC = try? self.context.resolver.resolve(assert: ChatOpenService.self).chatVC() else {
            return
        }

        let closeHander: (() -> Void)? = { [weak self] in
            self?.hide()
        }

        chatOpenService.chatTopNoticeChange { [weak self, weak chatVC] topNotice in
            /// 展示banner
            if let topNotice = topNotice, !topNotice.closed {
                let view = topNoticeService.createTopNoticeBannerWith(topNotice: topNotice,
                                                                      chatPush: wrappar.chat,
                                                                      fromVC: chatVC,
                                                                      closeHander: closeHander)
                self?.topNoticeView = view
                self?.display = (view != nil)
                self?.context.refresh()
            } else {
                self?.hide()
            }
        }
    }

    private func hide() {
        self.topNoticeView = nil
        self.display = false
        self.context.refresh()
    }
}
