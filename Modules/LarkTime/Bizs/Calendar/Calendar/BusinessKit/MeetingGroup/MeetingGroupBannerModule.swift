//
//  MeetingGroupBannerModule.swift
//  Calendar
//
//  Created by zhuheng on 2021/3/9.
//

import UIKit
import Foundation
import LarkOpenChat
import LarkModel

/// calendar 业务：会议群横幅
final class MeetingGroupBannerModule: ChatBannerSubModule {
    public override class var name: String { return "CalendarMeetingBannerModule" }

    public override var type: ChatBannerType {
        return .meeting
    }

    private var bannerController: MeetingGroupBannerController?

    public override func contentView() -> UIView? {
        return bannerController?.bannerView()
    }

    public override class func canInitialize(context: ChatBannerContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatBannerMetaModel) -> Bool {
        return model.chat.isMeeting
    }

    public override func handler(model: ChatBannerMetaModel) -> [Module<ChatBannerContext, ChatBannerMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatBannerMetaModel) {
        if !model.chat.isMeeting, self.display {
            self.display = false
            self.context.refresh()
        }
    }
    public override func createViews(model: ChatBannerMetaModel) {
        super.createViews(model: model)

        bannerController = MeetingGroupBannerController(chatId: model.chat.id, chatTitle: model.chat.name, userResolver: self.userResolver)
        display = false

        bannerController?.onBannerClosed = { [weak self] in
            guard let self = self else { return }
            self.display = false
            self.context.refresh()
        }

        bannerController?.loadBanner { [weak self] in
            guard let self = self else { return }
            self.display = true
            self.context.refresh()
        }

        bannerController?.onBannerChanged = { [weak self] in
            guard let self = self else { return }
            self.context.refresh()
        }
    }
}
