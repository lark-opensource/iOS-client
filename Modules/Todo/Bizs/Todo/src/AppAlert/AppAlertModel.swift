//
//  AppAlertModel.swift
//  Todo
//
//  Created by 张威 on 2020/11/27.
//

import LarkPushCard
import LarkContainer

/// App Alert - Reminder
/// 应用内通知：提醒

struct TodoAlarmExtra {
    let disappearTime: Int64
}

/// 新 push 卡片
struct TodoPushCard: Cardable {
    var id: String

    var priority: LarkPushCard.CardPriority = .normal

    var title: String?

    var buttonConfigs: [LarkPushCard.CardButtonConfig]?

    var icon: UIImage?

    var customView: UIView?

    var duration: TimeInterval?

    var bodyTapHandler: ((LarkPushCard.Cardable) -> Void)?

    var timedDisappearHandler: ((LarkPushCard.Cardable) -> Void)?

    var removeHandler: ((LarkPushCard.Cardable) -> Void)?

    var extraParams: Any?

    init(userResolver: UserResolver,
         pb: Rust.PushReminder,
         buttonConfigs: [LarkPushCard.CardButtonConfig]?,
         bodyTapHandler: ((LarkPushCard.Cardable) -> Void)?) {
        let disappearTime = Int64(Utils.AppAlert.getDisappearTime(
            dueTime: pb.dueTime,
            isAllDay: pb.isAllDay
        ))
        let timeOffset = Int(disappearTime - Int64(Date().timeIntervalSince1970))

        self.id = "Todo_AppAlert_\(pb.guid)_\(pb.dueTime)"
        self.title = I18N.Todo_Task_TaskAssistantBot
        self.icon = Resources.appAlert
        self.buttonConfigs = buttonConfigs
        self.customView = AppAlertCustomView(resolver: userResolver, pb: pb)
        self.duration = TimeInterval(timeOffset)
    }
}
