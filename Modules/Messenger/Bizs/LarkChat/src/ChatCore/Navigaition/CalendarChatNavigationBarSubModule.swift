//
//  CalendarChatNavigationBarSubModule.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/1/12.
//

import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkMessengerInterface
import LarkContainer
import LarkBadge

final public class CalendarChatNavigationBarSubModule: BaseNavigationBarItemSubModule {
    private var meetingMinutesBadgeService: MeetingMinutesBadgeService?

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return model.chat.isMeeting
    }

    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        return [self]
    }
    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        self.meetingMinutesBadgeService = try? self.context.resolver.resolve(assert: MeetingMinutesBadgeService.self, arguments: metaModel.chat.id, self.context.chatRootPath.chat_more)
        self.meetingMinutesBadgeService?.startMonitorMeetingSummaryBadge()
    }
}
