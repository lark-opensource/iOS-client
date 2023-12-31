//
//  EventCardRSVPCellComponent.swift
//  Calendar
//
//  Created by pluto on 2023/1/17.
//

import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import LarkTag
import RustPB
import LarkZoomable
import UniverseDesignIcon
import UniverseDesignCardHeader
import UniverseDesignColor
import UIKit

final class EventCardRSVPCellComponentProps: ASComponentProps {
    var status: CalendarEventAttendee.Status = .needsAction
    var target: Any?
    var acceptSelector: Selector?
    var declinSelector: Selector?
    var tentativeSelector: Selector?
    var replySelector: Selector?
    var replyedBtnRetapSelector: Selector?
    var moreReplyeTappedSelector: Selector?
}

final class NewRSVPReplyedBtnComponentProps: ASComponentProps {
    var text: String?
    var target: Any?
    var selector: Selector?
}

final class NewRSVPReplyedBtnComponent<C: Context>: ASComponent<NewRSVPReplyedBtnComponentProps, EmptyState, UIView, C> {
    private let titleLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.ud.body2
        titleProps.textColor = UIColor.ud.textTitle
        titleProps.text = I18n.Calendar_Bot_AcceptInvitation_Button
        titleProps.numberOfLines = 1
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 12
        style.height = 22
        return UILabelComponent(props: titleProps, style: style)
    }()

    private let folderIcon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.downOutlined).renderColor(with: .n1)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 10.auto()
        style.height = 10.auto()
        style.flexShrink = 0
        style.marginLeft = 4
        style.marginTop = 6
        return UIImageViewComponent(props: props, style: style)
    }()

    override init(props: NewRSVPReplyedBtnComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style)
        style.flexDirection = .row
        style.alignItems = .flexStart
        setSubComponents([
            titleLabel,
            folderIcon
        ])
    }

    override func update(view: UIView) {
        super.update(view: view)
        if let sel = props.selector {
            let tapGesture = UITapGestureRecognizer(target: props.target, action: sel)
            view.gestureRecognizers?.forEach({ (gestures) in
                view.removeGestureRecognizer(gestures)
            })
            view.addGestureRecognizer(tapGesture)
        }
    }
    
    // 属性更新 需要在此方法中（子线程），若置于主线程更新可能会有ui加载问题
    override func willReceiveProps(_ old: NewRSVPReplyedBtnComponentProps, _ new: NewRSVPReplyedBtnComponentProps) -> Bool {
        let titleProps = titleLabel.props
        titleProps.text = new.text
        titleLabel.props = titleProps
        return true
    }
}

final class MoreActionPanelComponentProps: ASComponentProps {
    var target: Any?
    var selector: Selector?
}

final class MoreActionPanelComponent<C: Context>: ASComponent<MoreActionPanelComponentProps, EmptyState, UIView, C> {
    private lazy var moreBtn: CalendarButtonComponent<C> = {
        let btn = CalendarButtonComponent<C>(
            props: CalendarButtonComponentProps(),
            style: ASComponentStyle(),
            context: nil)
        btn.style.height = 40
        btn.style.width = 40
        btn.style.cornerRadius = 6
        btn.props.isUserInteractionEnabled = false
        btn.props.normalImage = UDIcon.getIconByKey(.moreBoldOutlined, size: CGSize(width: 16.auto(), height: 16.auto())).ud.withTintColor(.ud.iconN1)
        btn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        return btn
    }()
    
    override init(props: MoreActionPanelComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style)
        style.flexDirection = .column
        setSubComponents([
            moreBtn
        ])
    }
    
    override func update(view: UIView) {
        super.update(view: view)
        moreBtn.props.selector = props.selector
        moreBtn.props.target = props.target
        if let sel = props.selector {
            let tapGesture = UITapGestureRecognizer(target: props.target, action: sel)
            view.gestureRecognizers?.forEach({ (gestures) in
                view.removeGestureRecognizer(gestures)
            })
            view.addGestureRecognizer(tapGesture)
        }
    }
}

final class EventCardRSVPCellComponent<C: Context>: ASComponent<EventCardRSVPCellComponentProps, EmptyState, UIView, C> {

    private lazy var acceptBtn: CalendarButtonComponent<C> = {
        let btn = CalendarButtonComponent<C>(
            props: CalendarButtonComponentProps(),
            style: ASComponentStyle(),
            context: nil)
        btn.style.cornerRadius = 6
        btn.style.height = 40
        btn.style.flexGrow = 1
        btn.style.marginRight = 8
        btn.props.normalTitleColor = UIColor.ud.primaryContentDefault
        btn.props.normalTitle = I18n.Calendar_Bot_AcceptInvitation_Button
        btn.props.font = UIFont.ud.body2
        btn.props.backgroundColor = .clear
        btn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.primaryPri500, style: .solid))
        return btn
    }()
    
    private let rsvpTopLineComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.width = 100%
        style.height = 1
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.display = .flex
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    private lazy var moreActionPanel: MoreActionPanelComponent = {
        let style = ASComponentStyle()
        style.width = 40
        var moreProps = MoreActionPanelComponentProps()
        return MoreActionPanelComponent<C>(props: moreProps, style: style)
    }()
    
    private lazy var needActionPanel: ASLayoutComponent = {
        let style = ASComponentStyle()
        style.width = 100%
        style.justifyContent = .flexStart
        style.marginTop = 12
        return ASLayoutComponent(style: style, [acceptBtn, moreActionPanel])
    }()
    
    private let replyLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.attributedText = NSAttributedString(string: I18n.Calendar_Detail_StatusReplied, attributes: [.foregroundColor: UIColor.ud.textCaption,
                                                                                                                .font: UIFont.ud.body2])
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.height = 22
        return UILabelComponent(props: titleProps, style: style)
    }()

    private let replyedBtn: NewRSVPReplyedBtnComponent<C> = {
        let style = ASComponentStyle()
        style.height = 22
        style.flexShrink = 0
        style.cornerRadius = 6
        var buttonProps = NewRSVPReplyedBtnComponentProps()
        return NewRSVPReplyedBtnComponent<C>(props: buttonProps, style: style)
    }()

    private lazy var replyPanel: ASLayoutComponent = {
        let style = ASComponentStyle()
        style.width = 100%
        style.justifyContent = .flexStart
        style.marginTop = 12.5
        style.flexDirection = .row
        return ASLayoutComponent(style: style, [replyLabel, replyedBtn])
    }()

    private lazy var replyedActionPanel: ASLayoutComponent = {
        let style = ASComponentStyle()
        style.marginTop = 13
        style.width = 100%
        style.flexDirection = .column
        return ASLayoutComponent(style: style, [rsvpTopLineComponent, replyPanel])
    }()

    override init(props: EventCardRSVPCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)

        style.justifyContent = .flexStart
        style.marginTop = 0
        style.paddingLeft = 13
        style.paddingRight = 12

        setSubComponents([needActionPanel, replyedActionPanel])
    }

    override func willReceiveProps(_ old: EventCardRSVPCellComponentProps, _ new: EventCardRSVPCellComponentProps) -> Bool {
        if new.status == .needsAction {
            return updateToNeedActionWith(new)
        } else {
            return updateToReplyedWith(new)
        }
    }

    private func updateToReplyedWith(_ new: EventCardRSVPCellComponentProps) -> Bool {
        needActionPanel.style.display = .none
        replyedActionPanel.style.display = .flex

        let replyedBtnProps = NewRSVPReplyedBtnComponentProps()
        if new.status == .accept {
            replyedBtnProps.text = I18n.Calendar_Detail_Accept
        }
        if new.status == .decline {
            replyedBtnProps.text = I18n.Calendar_Detail_Refuse
        }
        if new.status == .tentative {
            replyedBtnProps.text = I18n.Calendar_Detail_Maybe
        }

        replyedBtnProps.selector = new.replyedBtnRetapSelector
        replyedBtnProps.target = new.target
        replyedBtn.props = replyedBtnProps

        return true
    }

    private func updateToNeedActionWith(_ new: EventCardRSVPCellComponentProps) -> Bool {
        replyedActionPanel.style.display = .none
        needActionPanel.style.display = .flex

        let moreReplyPanelProps = MoreActionPanelComponentProps()
        let acceptBtnProps = acceptBtn.props
        acceptBtnProps.target = new.target
        acceptBtnProps.selector = new.acceptSelector
        acceptBtn.props = acceptBtnProps
        
        moreReplyPanelProps.selector = new.moreReplyeTappedSelector
        moreReplyPanelProps.target = new.target
        moreActionPanel.props = moreReplyPanelProps

        return true
    }
}
