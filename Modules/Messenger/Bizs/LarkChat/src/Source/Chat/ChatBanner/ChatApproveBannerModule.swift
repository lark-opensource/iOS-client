//
//  ChatApproveBannerModule.swift
//  LarkChatSetting
//
//  Created by  李勇 on 2020/12/8.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkFeatureGating
import LarkCore
import LarkSDKInterface
import LarkMessageCore

/// Setting业务：入群申请
public final class ChatApproveBannerModule: ChatBannerSubModule {
    public override class var name: String { return "ChatApproveBannerModule" }

    public override var type: ChatBannerType {
        return .chatApprove
    }

    private var approveContentView: ApproveChatBanner?

    //view展示的埋点是否已上报过
    private var isViewTracked = false
    public override func contentView() -> UIView? {
        if !isViewTracked,
           let view = self.approveContentView {
            isViewTracked = true
            LarkMessageCoreTracker.trackNoticeBarView(chat: view.chatWrapper.chat.value, noticeBarType: .group_application_noticebar)
        }
        return self.approveContentView
    }

    public override class func canInitialize(context: ChatBannerContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatBannerMetaModel) -> Bool {
        return model.chat.type == .group
    }

    public override func handler(model: ChatBannerMetaModel) -> [Module<ChatBannerContext, ChatBannerMetaModel>] {
        return [self]
    }

    public override func createViews(model: ChatBannerMetaModel) {
        super.createViews(model: model)
        guard let targetVC = (try? self.context.userResolver.resolve(assert: ChatOpenService.self))?.chatVC(),
            let chatWrapper = try? self.context.userResolver.resolve(assert: ChatPushWrapper.self, argument: model.chat),
            let chatAPI = try? self.context.userResolver.resolve(assert: ChatAPI.self)
        else { return }
        self.display = true
        self.approveContentView = ApproveChatBanner(
            targetVC: targetVC,
            chatWrapper: chatWrapper,
            chatAPI: chatAPI,
            nav: self.context.nav) { [weak self] isHidden in
                self?.display = !isHidden
                self?.context.refresh()
        }
    }
}
