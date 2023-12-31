//
//  RoundRobinCardBodyComponent.swift
//  Calendar
//
//  Created by tuwenbo on 2023/3/30.
//

import Foundation
import AsyncComponent
import EEFlexiable

final class RoundRobinCardBodyComponent<C: Context>: ASComponent<RoundRobinCardBodyComponent.Props, EmptyState, UIView, C> {

    final class Props: ASComponentProps {
        var isActive: Bool = false
        var hostID: String?
        var hostName: String?
        var inviteeName: String?
        var inviteeEmail: String?
        var time: String?

        var hostOnTapped: ((String?) -> Void)?
        var inviteeEmailOnTapped: ((String?) -> Void)?

        var changeHostAction: (() -> Void)?
        var rescheduleAction: (() -> Void)?
        var cancelAction: (() -> Void)?
        var isForward: Bool = false
        var amIHost: Bool = false
        var amICreator: Bool = false
    }

    private lazy var hostName: UILabelComponent<C> = {
        let label = makeTextLabel()
        label.props.font = UIFont.ud.body2(.fixed)
        label.props.textColor = UIColor.ud.textLinkNormal
        return label
    }()

    private lazy var hostComponent: ASLayoutComponent<C> = {
        let label = makeTextLabel()
        label.props.text = I18n.Calendar_Scheduling_Host_Bot
        label.props.font = UIFont.ud.body1(.fixed)
        return ASLayoutComponent<C>(style: itemPairStyle(), [label, hostName])
    }()

    private lazy var inviteeName: UILabelComponent<C> = {
        let label = makeTextLabel()
        label.props.font = UIFont.ud.body2(.fixed)
        return label
    }()

    private lazy var inviteeComponent: ASLayoutComponent<C> = {
        let label = makeTextLabel()
        label.props.text = I18n.Calendar_Scheduling_Invitee_Bot
        label.props.font = UIFont.ud.body1(.fixed)
        return ASLayoutComponent<C>(style: itemPairStyle(), [label, inviteeName])
    }()

    private lazy var inviteeEmail: UILabelComponent<C> = {
        let label = makeTextLabel(numberOfLines: 2)
        label.props.font = UIFont.ud.body2(.fixed)
        label.props.textColor = UIColor.ud.textLinkNormal
        return label
    }()

    private lazy var inviteeEmailComponent: ASLayoutComponent<C> = {
        let label = makeTextLabel()
        label.props.text = I18n.Calendar_Scheduling_InviteeEmail_Bot
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
        label.props.text = I18n.Calendar_Scheduling_Time_Bot
        label.props.font = UIFont.ud.body1(.fixed)
        return ASLayoutComponent<C>(style: itemPairStyle(), [label, time])
    }()

    private lazy var hostAndInviteeWrap: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.justifyContent = .center
        style.alignContent = .spaceAround
        style.alignItems = .stretch
        // 等分父容器的大小
        hostComponent.style.flexGrow = 1
        hostComponent.style.flexBasis = 0
        hostComponent.style.marginRight = 8
        inviteeComponent.style.flexGrow = 1
        inviteeComponent.style.flexBasis = 0
        return ASLayoutComponent<C>(style: style, [hostComponent, inviteeComponent])
    }()

    private lazy var changeHostButton = makeButton(text: I18n.Calendar_Scheduling_ChangeHost_Bot,
                                                   hasBottomMargin: true)
    private lazy var rescheduleButton = makeButton(text: I18n.Calendar_Scheduling_Reschedule_Bot,
                                                   hasBottomMargin: true)
    private lazy var cancelButton = makeButton(text: I18n.Calendar_Scheduling_Cancel_Bot)

    private lazy var operatorActionComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.justifyContent = .flexStart
        style.alignContent = .center
        style.alignItems = .stretch
        return ASLayoutComponent<C>(style: style, [changeHostButton, rescheduleButton, cancelButton])
    }()

    private lazy var subComponents: [AsyncComponent.ComponentWithContext<C>] = [
        hostAndInviteeWrap,
        inviteeEmailComponent,
        timeComponent,
        operatorActionComponent
    ]

    override init(props: RoundRobinCardBodyComponent.Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents(subComponents)
        style.flexDirection = .column
        style.justifyContent = .flexStart
        style.alignContent = .center
        style.alignItems = .stretch
        style.padding = 12
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        hostComponent.style.display = new.hostName.isEmpty ? .none : .flex
        inviteeComponent.style.display = new.inviteeName.isEmpty ? .none : .flex
        hostAndInviteeWrap.style.display = new.isActive ? .flex : .none
        inviteeEmailComponent.style.display = (new.isActive && !new.inviteeEmail.isEmpty) ? .flex : .none
        timeComponent.style.display = new.time.isEmpty ? .none : .flex
        operatorActionComponent.style.display = (new.isActive &&
                                                 !new.isForward &&
                                                 (new.amIHost || new.amICreator)) ? .flex : .none

        // 按钮显示的时候，主持人不显示切换主持人按钮，只有组织者显示
        changeHostButton.style.display = new.amICreator ? .flex : .none

        if operatorActionComponent.style.display == .none {
            if let last = subComponents.filter({ $0._style.display != .none }).last {
                last._style.marginBottom = 0
            }
        }

        if let name = new.hostName {
            if new.amIHost {
                // 手动 padding, style 里的 padding 不管用
                hostName.props.text = " @\(name) "
                hostName.style.cornerRadius = 10
                hostName.style.backgroundColor = UIColor.ud.primaryContentDefault
                hostName.props.textColor = UIColor.ud.udtokenMessageCardTextNeutral
            } else {
                hostName.props.text = "@\(name)"
                hostName.style.cornerRadius = 0
                hostName.style.backgroundColor = .clear
                hostName.props.textColor = UIColor.ud.textLinkNormal
            }
        }
        hostName.props.onTap =  {
            new.hostOnTapped?(new.hostID)
        }
        inviteeName.props.text = new.inviteeName
        inviteeEmail.props.text = new.inviteeEmail
        inviteeEmail.props.onTap = {
            new.inviteeEmailOnTapped?(new.inviteeEmail)
        }
        time.props.text = new.time

        changeHostButton.props.selector = #selector(changeHostTapped)
        rescheduleButton.props.selector = #selector(rescheduleTapped)
        cancelButton.props.selector = #selector(cancelTapped)
        changeHostButton.props.target = self
        rescheduleButton.props.target = self
        cancelButton.props.target = self
        return true
    }

    @objc
    private func changeHostTapped() {
        self.props.changeHostAction?()
    }

    @objc
    private func rescheduleTapped() {
        self.props.rescheduleAction?()
    }

    @objc
    private func cancelTapped() {
        self.props.cancelAction?()
    }
}

extension RoundRobinCardBodyComponent {
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

    private func makeRichTextLabel() -> RichLabelComponent<C> {
        let props = RichLabelProps()
        props.font = UIFont.ud.body2(.fixed)
        props.numberOfLines = 1
        props.lineSpacing = 4
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.minHeight = 22
        style.flexShrink = 1
        return RichLabelComponent(props: props, style: style)
    }

    private func makeButton(text: String, hasBottomMargin: Bool = false) -> CalendarButtonComponent<C> {
        let props = CalendarButtonComponentProps()
        props.normalTitle = text
        props.font = UIFont.ud.body2
        props.normalTitleColor = UIColor.ud.textTitle

        let style = ASComponentStyle()
        style.height = 36
        style.width = 100%
        style.flexShrink = 1
        style.marginBottom = hasBottomMargin ? 12 : 0
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

