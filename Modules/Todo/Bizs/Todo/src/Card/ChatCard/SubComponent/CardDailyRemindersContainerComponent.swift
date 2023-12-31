//
//  BotDailyRemindersContainerComponent.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/14.
//

import Foundation
import AsyncComponent
import EEFlexiable
import RichLabel

// nolint: magic number
class ChatCardDailyRemindersContainerProps: ASComponentProps {
    var dailyReminderCellPropsList: [ChatCardDailyReminderCellProps] = []
}

class ChatCardDailyRemindersContainerComponent<C: Context>: ASComponent<ChatCardDailyRemindersContainerProps, EmptyState, UIView, C> {

    private lazy var dailyReminderCell1: ChatCardDailyReminderCellcomponent<C> = makeDailyReminderCellComponent()
    private lazy var dailyReminderCell2: ChatCardDailyReminderCellcomponent<C> = makeDailyReminderCellComponent()
    private lazy var dailyReminderCell3: ChatCardDailyReminderCellcomponent<C> = makeDailyReminderCellComponent()
    private lazy var dailyReminderCell4: ChatCardDailyReminderCellcomponent<C> = makeDailyReminderCellComponent()
    private lazy var dailyReminderCell5: ChatCardDailyReminderCellcomponent<C> = makeDailyReminderCellComponent()

    private var dailyReminderCellList: [ChatCardDailyReminderCellcomponent<C>] {
        return [dailyReminderCell1, dailyReminderCell2, dailyReminderCell3, dailyReminderCell4, dailyReminderCell5]
    }

    override init(props: ChatCardDailyRemindersContainerProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .column
        setSubComponents([
            dailyReminderCell1,
            dailyReminderCell2,
            dailyReminderCell3,
            dailyReminderCell4,
            dailyReminderCell5
        ])
    }

    override func willReceiveProps(
        _ old: ChatCardDailyRemindersContainerProps,
        _ new: ChatCardDailyRemindersContainerProps
    ) -> Bool {
        let propsList = new.dailyReminderCellPropsList
        let propsCount = min(propsList.count, dailyReminderCellList.count)

        for index in 0..<propsCount {
            dailyReminderCellList[index].style.display = .flex
            dailyReminderCellList[index].props = propsList[index]
        }

        for index in propsCount..<dailyReminderCellList.count {
            dailyReminderCellList[index].style.display = .none
        }

        return true
    }

    private func makeDailyReminderCellComponent() -> ChatCardDailyReminderCellcomponent<C> {
        let props = ChatCardDailyReminderCellProps()

        let style = ASComponentStyle()
        style.marginTop = 3
        style.backgroundColor = .clear
        style.flexShrink = 1
        return ChatCardDailyReminderCellcomponent(props: props, style: style)

    }

}
