//
//  ChatCardDailyReminderCellcomponent.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/14.
//

import Foundation
import AsyncComponent
import EEFlexiable
import RichLabel

// nolint: magic number
class ChatCardDailyReminderCellProps: ASComponentProps {
    var info: ChatCardDailyReminderInfo?
    var onTap: ((String) -> Void)?
}

class ChatCardDailyReminderCellcomponent<C: Context>: ASComponent<ChatCardDailyReminderCellProps, EmptyState, UIView, C> {

    private lazy var titleComponent: RichLabelComponent<C> = {
        let props = RichLabelProps()
        props.numberOfLines = 1
        props.lineSpacing = 4
        props.outOfRangeText = AttrText(string: "\u{2026}", attributes: [.foregroundColor: UIColor.ud.textTitle])

        var style = ASComponentStyle()
        style.marginTop = 8
        style.backgroundColor = .clear
        style.flexShrink = 1

        return RichLabelComponent(props: props, style: style)
    }()

    private lazy var timeComponent: ChatCardTimeComponent<C> = {
        let props = ChatCardTimeComponentProps()
        let style = ASComponentStyle()
        return ChatCardTimeComponent<C>(props: props, style: style)
    }()

    private lazy var bottomLineComponent: UIViewComponent<C> = {
        let props = UIImageViewComponentProps()

        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: 1.0 / UIScreen.main.scale)
        style.backgroundColor = UIColor.ud.lineBorderComponent
        style.marginTop = 8
        return UIViewComponent(props: props, style: style)
    }()

    override init(props: ChatCardDailyReminderCellProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .column
        setSubComponents([
            titleComponent,
            timeComponent,
            bottomLineComponent
        ])
    }

    override func update(view: UIView) {
        super.update(view: view)

        view.removeGestureRecognizer(gesture)
        view.addGestureRecognizer(gesture)
    }

    private lazy var gesture = UITapGestureRecognizer(target: self, action: #selector(onTap))

    @objc
    private func onTap() {
        guard let info = props.info else { return }
        props.onTap?(info.guid)
    }

    override func willReceiveProps(
        _ old: ChatCardDailyReminderCellProps,
        _ new: ChatCardDailyReminderCellProps
    ) -> Bool {
        guard let info = new.info else { return true }

        let props = titleComponent.props
        props.attributedText = info.title.attrText
        titleComponent.props = props

        if let timeContent = info.timeContent {
            var props = timeComponent.props
            props.timeInfo = timeContent
            props.style = .dailyRemind
            timeComponent.props = props
            timeComponent.style.display = .flex
        } else {
            timeComponent.style.display = .none
        }

        return true
    }

}
