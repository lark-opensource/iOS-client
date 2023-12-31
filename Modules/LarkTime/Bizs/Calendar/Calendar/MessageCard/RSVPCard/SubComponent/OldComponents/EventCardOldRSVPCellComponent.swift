//
//  EventCardOldRSVPCellComponent.swift
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

final class OldRSVPReplyedBtnComponent<C: Context>: ASComponent<NewRSVPReplyedBtnComponentProps, EmptyState, UIView, C> {
    private let titleLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font = UIFont.ud.body2
        titleProps.textColor = UIColor.ud.textTitle
        titleProps.text = I18n.Calendar_Bot_AcceptInvitation_Button
        titleProps.numberOfLines = 1
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginLeft = 23
        style.marginTop = 6
        style.marginBottom = 6
        return UILabelComponent(props: titleProps, style: style)
    }()

    private let folderIcon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { task in
            let image = UDIcon.getIconByKeyNoLimitSize(.downOutlined).renderColor(with: .n1)
            task.set(image: image)
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.flexShrink = 0
        style.marginLeft = 4
        style.marginRight = 23
        return UIImageViewComponent(props: props, style: style)
    }()

    override init(props: NewRSVPReplyedBtnComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style)
        style.flexDirection = .row
        style.alignItems = .center
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

final class OldMoreActionPanelComponent<C: Context>: ASComponent<MoreActionPanelComponentProps, EmptyState, UIView, C> {
    private lazy var moreBtn: CalendarButtonComponent<C> = {
        let btn = CalendarButtonComponent<C>(
            props: CalendarButtonComponentProps(),
            style: ASComponentStyle(),
            context: nil)
        btn.style.height = 16
        btn.style.width = 44
        btn.props.isUserInteractionEnabled = false
        btn.props.normalImage = UDIcon.getIconByKey(.moreBoldOutlined, size: CGSize(width: 16.auto(), height: 16.auto())).ud.withTintColor(.ud.iconN1)
        return btn
    }()
    
    private let moreLabel: UILabelComponent<C> = {
        let titleProps = UILabelComponentProps()
        titleProps.font =  UIFont.ud.caption2
        titleProps.textColor = UIColor.ud.textCaption
        titleProps.text = I18n.Calendar_Common_More
        titleProps.numberOfLines = 1
        titleProps.textAlignment = .center
        titleProps.isUserInteractionEnabled = false
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.clear
        style.marginTop = 3.5
        
        return UILabelComponent(props: titleProps, style: style)
    }()
    
    override init(props: MoreActionPanelComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style)
        style.flexDirection = .column
        setSubComponents([
            moreBtn,
            moreLabel
        ])
    }
    
    override func update(view: UIView) {
        super.update(view: view)
        moreBtn.props.selector = props.selector
        moreBtn.props.target = props.selector
        if let sel = props.selector {
            let tapGesture = UITapGestureRecognizer(target: props.target, action: sel)
            view.gestureRecognizers?.forEach({ (gestures) in
                view.removeGestureRecognizer(gestures)
            })
            view.addGestureRecognizer(tapGesture)
        }
    }
}

final class EventCardOldRSVPCellComponent<C: Context>: ASComponent<EventCardRSVPCellComponentProps, EmptyState, UIView, C> {

    private lazy var acceptBtn: CalendarButtonComponent<C> = {
        let btn = CalendarButtonComponent<C>(
            props: CalendarButtonComponentProps(),
            style: ASComponentStyle(),
            context: nil)
        btn.style.cornerRadius = 6
        btn.style.height = CSSValue(cgfloat: UIFont.ud.body2.figmaHeight + 12)
        btn.style.flexGrow = 1
        btn.props.normalTitleColor = UIColor.ud.primaryOnPrimaryFill
        btn.props.normalTitle = I18n.Calendar_Bot_AcceptInvitation_Button
        btn.props.font = UIFont.ud.body2
        btn.props.backgroundColor = UDColor.calendarRSVPCardacceptBtnBgColor
        return btn
    }()

    private lazy var moreActionPanel: OldMoreActionPanelComponent = {
        let style = ASComponentStyle()
        style.width = 44
        var moreProps = MoreActionPanelComponentProps()
        return OldMoreActionPanelComponent<C>(props: moreProps, style: style)
    }()
    
    private lazy var needActionPanel: ASLayoutComponent = {
        let style = ASComponentStyle()
        style.width = 100%
        style.justifyContent = .flexStart
        style.marginTop = 12

        return ASLayoutComponent(style: style, [acceptBtn, moreActionPanel])
    }()

    private let replyedBtn: OldRSVPReplyedBtnComponent<C> = {
        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: UIFont.ud.body2.figmaHeight + 12)
        style.flexShrink = 0
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        style.cornerRadius = 6
        var buttonProps = NewRSVPReplyedBtnComponentProps()
        return OldRSVPReplyedBtnComponent<C>(props: buttonProps, style: style)
    }()


    private lazy var replyedActionPanel: ASLayoutComponent = {
        let style = ASComponentStyle()
        style.marginTop = 12
        style.flexDirection = .column
        return ASLayoutComponent(style: style, [replyedBtn])
    }()

    override init(props: EventCardRSVPCellComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)

        style.justifyContent = .flexStart
        style.marginTop = 0
        style.paddingLeft = 12

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
            replyedBtnProps.text = I18n.Calendar_Detail_Accepted
        }
        if new.status == .decline {
            replyedBtnProps.text = I18n.Calendar_Detail_Refused
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
