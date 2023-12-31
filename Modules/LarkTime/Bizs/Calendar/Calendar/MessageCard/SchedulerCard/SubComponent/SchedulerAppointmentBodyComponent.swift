//
//  SchedulerAppointmentBodyComponent.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/30.
//

import Foundation
import AsyncComponent
import EEFlexiable

final class SchedulerAppointmentBodyComponent<C: Context>: ASComponent<SchedulerAppointmentBodyComponent.Props, EmptyState, UIView, C> {

    final class Props: ASComponentProps {
        var isActive: Bool = false
        var inviteeEmail: String?
        var time: String?
        var message: String?
        var messageTitle: String?
        var detailLink: String?

        var inviteeEmailOnTapped: ((String?) -> Void)?
        var viewDetailAction: ((String?) -> Void)?
        var actionButtonVisible: Bool = false
    }

    private lazy var inviteeEmail: UILabelComponent<C> = {
        let label = makeTextLabel(numberOfLines: 2)
        label.props.font = UIFont.ud.body2(.fixed)
        label.props.textColor = UIColor.ud.textLinkNormal
        return label
    }()

    private lazy var emailComponent: ASLayoutComponent<C> = {
        let label = makeTextLabel()
        label.props.text = I18n.Calendar_ScheduleBot_Email
        label.props.font = UIFont.ud.body1(.fixed)
        return ASLayoutComponent<C>(style: itemPairStyle(), [label, inviteeEmail])
    }()

    private lazy var time: UILabelComponent<C> = {
        let label = makeTextLabel()
        label.props.font = UIFont.ud.body2(.fixed)
        return label
    }()

    private lazy var timeComponent: ASLayoutComponent<C> = {
        let label = makeTextLabel()
        label.props.text = I18n.Calendar_ScheduleBot_Time
        label.props.font = UIFont.ud.body1(.fixed)
        return ASLayoutComponent<C>(style: itemPairStyle(), [label, time])
    }()

    private lazy var message: UILabelComponent<C> = {
        let label = makeTextLabel()
        label.props.numberOfLines = 2
        label.props.font = UIFont.ud.body2(.fixed)
        return label
    }()

    private lazy var messageTitle: UILabelComponent<C> = {
        let label = makeTextLabel()
        label.props.font = UIFont.ud.body1(.fixed)
        return label
    }()

    private lazy var messageComponent: ASLayoutComponent<C> = {
        return ASLayoutComponent<C>(style: itemPairStyle(), [messageTitle, message])
    }()

    private lazy var viewDetailButton = makeButton(text: I18n.Calendar_Edit_ViewDetail)

    private lazy var subComponents: [AsyncComponent.ComponentWithContext<C>] = [
        emailComponent,
        timeComponent,
        messageComponent,
        viewDetailButton
    ]

    override init(props: SchedulerAppointmentBodyComponent.Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents(subComponents)
        style.flexDirection = .column
        style.justifyContent = .flexStart
        style.alignContent = .center
        style.alignItems = .stretch
        style.padding = 12
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        emailComponent.style.display = new.inviteeEmail.isEmpty ? .none : .flex
        timeComponent.style.display = new.time.isEmpty ? .none : .flex
        messageComponent.style.display = new.message.isEmpty ? .none : .flex
        viewDetailButton.style.display = new.actionButtonVisible ? .flex : .none

        if viewDetailButton.style.display == .none {
            if let last = subComponents.filter({ $0._style.display != .none }).last {
                last._style.marginBottom = 0
            }
        }

        inviteeEmail.props.text = new.inviteeEmail
        inviteeEmail.props.onTap = {
            new.inviteeEmailOnTapped?(new.inviteeEmail)
        }
        time.props.text = new.time
        messageTitle.props.text = new.messageTitle
        message.props.text = new.message

        viewDetailButton.props.selector = #selector(viewDetailTapped)
        viewDetailButton.props.target = self
        return true
    }

    @objc
    private func viewDetailTapped() {
        self.props.viewDetailAction?(self.props.detailLink)
    }
}

extension SchedulerAppointmentBodyComponent {
    private func makeTextLabel(numberOfLines: Int = 1) -> UILabelComponent<C> {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.body2(.fixed)
        props.textColor = UIColor.ud.textTitle
        props.lineBreakMode = .byTruncatingTail
        props.numberOfLines = numberOfLines
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.minHeight = 22
        style.flexShrink = 1
        return UILabelComponent(props: props, style: style)
    }

    private func makeButton(text: String, hasMarginBottom: Bool = false) -> CalendarButtonComponent<C> {
        let props = CalendarButtonComponentProps()
        props.normalTitle = text
        props.font = UIFont.ud.body2
        props.normalTitleColor = UIColor.ud.textTitle

        let style = ASComponentStyle()
        style.height = 36
        style.width = 100%
        style.flexShrink = 1
        style.marginBottom = hasMarginBottom ? 12 : 0
        style.cornerRadius = 6
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        return CalendarButtonComponent<C>(props: props, style: style)
    }

    // 一上一下两个 label 的样式
    private func itemPairStyle() -> ASComponentStyle {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.justifyContent = .flexStart
        style.alignItems = .flexStart
        style.flexShrink = 1
        style.flexGrow = 1
        style.marginBottom = 16
        return style
    }
}
