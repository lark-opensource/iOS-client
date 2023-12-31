//
//  CalendarFeedActionJumpFactory.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/8/29.
//

import LarkModel
import LarkOpenFeed
import RustPB
import LarkUIKit
import Calendar
#if MessengerMod
import LarkMessengerInterface
#endif

final class CalendarFeedActionJumpFactory: FeedActionBaseFactory {
    var type: FeedActionType {
        return .jump
    }

    var bizType: FeedPreviewType? {
        return .calendar
    }

    func createActionHandler(model: FeedActionModel, context: FeedCardContext) -> FeedActionHandlerInterface {
        return CalendarFeedActionJumpHandler(type: type, model: model, context: context)
    }
}

final class CalendarFeedActionJumpHandler: FeedActionHandler {
    private let context: FeedCardContext
    init(type: FeedActionType, model: FeedActionModel, context: FeedCardContext) {
        self.context = context
        super.init(type: type, model: model)
    }

    override func executeTask() {
        guard let vc = model.fromVC ?? context.feedContextService.page else { return }
        self.willHandle()
        Self.routerToEventList(feedPreview: model.feedPreview,
                               basicData: model.basicData,
                               groupType: model.groupType ?? .unknown,
                               context: context,
                               from: vc)
        self.didHandle()
    }

    static func routerToEventList(feedPreview: FeedPreview,
                                  basicData: IFeedPreviewBasicData?,
                                  groupType: Feed_V1_FeedFilter.TypeEnum,
                                  context: FeedCardContext,
                                  from: UIViewController) {
        let feedGroup = LarkOpenFeed.FeedGroupData.name(groupType: groupType)
        let isTempTop = basicData?.isTempTop ?? false
        let body = CalendarTodayEventBody(feedTab: feedGroup,
                                          isTop: isTempTop,
                                          showCalendarID: feedPreview.basicMeta.bizId,
                                          feedID: feedPreview.id)
        context.userResolver.navigator.showDetailOrPush(body: body, from: from)
    }
}

#if MessengerMod
extension TodayEventViewController: FeedSelectionInfoProvider {
    public func getFeedIdForSelected() -> String? {
        return self.feedID
    }
}
#endif
