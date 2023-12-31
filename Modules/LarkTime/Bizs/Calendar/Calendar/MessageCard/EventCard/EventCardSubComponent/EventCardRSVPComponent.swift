//
//  EventCardRSVPComponent.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/25.
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
import UIKit

final class CalendarButtonComponentProps: ASComponentProps {
    var normalTitle: String?
    var selectTitle: String?
    var disableTitle: String?
    var highlightedTitle: String?
    var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var normalTitleColor: UIColor?
    var selectTitleColor: UIColor?
    var disableTitleColor: UIColor?
    var highlightedColor: UIColor?
    var normalImage: UIImage?
    var horizontalAlignment: UIControl.ContentHorizontalAlignment = .center
    var isEnabled: Bool = true
    var isSelected: Bool = false
    var backgroundColor: UIColor = .clear
    var target: Any?
    var selector: Selector?
    var replySelector: (() -> Void)?
    var isUserInteractionEnabled: Bool = true
}

final class CalendarButtonComponent<C: Context>: ASComponent<CalendarButtonComponentProps, EmptyState, UIButton, C> {
    public override func update(view: UIButton) {
        super.update(view: view)
        view.isSelected = props.isSelected
        view.isEnabled = props.isEnabled
        view.titleLabel?.font = props.font
        view.setTitleColor(props.normalTitleColor, for: .normal)
        view.setTitleColor(props.selectTitleColor, for: .selected)
        view.setTitleColor(props.disableTitleColor, for: .disabled)
        view.setTitleColor(props.highlightedColor, for: .highlighted)
        view.setTitle(props.normalTitle, for: .normal)
        view.setTitle(props.selectTitle, for: .selected)
        view.setTitle(props.disableTitle, for: .disabled)
        view.setTitle(props.highlightedTitle, for: .highlighted)
        view.setImage(props.normalImage, for: .normal)
        view.backgroundColor = props.backgroundColor
        view.contentHorizontalAlignment = props.horizontalAlignment
        view.isUserInteractionEnabled = props.isUserInteractionEnabled

        if props.replySelector != nil {
            stopAnimation(view: view)
        }

        if props.normalImage != nil && props.normalTitle != nil {
            view.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            view.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
        }

        if let sel = props.selector {
            let tapGesture = UITapGestureRecognizer(target: props.target, action: sel)
            view.gestureRecognizers?.forEach({ (gestures) in
                view.removeGestureRecognizer(gestures)
            })
            view.addGestureRecognizer(tapGesture)
        }
        
        if props.replySelector != nil {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleReplyEvent(replyButton:)))
            view.gestureRecognizers?.forEach({ (gestures) in
                view.removeGestureRecognizer(gestures)
            })
            view.addGestureRecognizer(tapGesture)
        }
    }

    @objc
    func handleReplyEvent(replyButton: UITapGestureRecognizer) {
        if let replyButton = replyButton.view as? UIButton {
            self.startAnimation(view: replyButton)
        }
        self.props.replySelector?()
    }

    public override var isComplex: Bool {
        return true
    }

    func startAnimation(view: UIButton) {
        guard let icon = view.imageView else { return }
        view.setImage(UDIcon.getIconByKey(.chatLoadingOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.primaryContentDefault), for: .normal)
        view.setTitleColor(UIColor.ud.textTitle.withAlphaComponent(0.4), for: .normal)
        view.isUserInteractionEnabled = false
        startZRotation(view: view, icon: icon)
    }

    func stopAnimation(view: UIButton) {
        guard let icon = view.imageView else { return }
        icon.layer.removeAllAnimations()
        view.isUserInteractionEnabled = true
        if view.titleLabel?.text == nil {
            view.setImage(UDIcon.getIconByKey(.replyCnOutlined, size: CGSize(width: 16, height: 16)).renderColor(with: .n2), for: .normal)
        } else {
            view.setTitleColor(UIColor.ud.textTitle, for: .normal)
            view.setImage(nil, for: .normal)
        }
    }

    func startZRotation(view: UIButton, icon: UIImageView, duration: CFTimeInterval = 1, repeatCount: Float = Float.infinity, clockwise: Bool = true) {
        if view.layer.animation(forKey: "transform.rotation.z") != nil {
            return
        }
        let animation = CABasicAnimation(keyPath: "transform.rotation.z")
        let direction = clockwise ? 1.0 : -1.0
        animation.toValue = NSNumber(value: Double.pi * 2 * direction)
        animation.duration = duration
        animation.isCumulative = true
        animation.repeatCount = repeatCount
        icon.layer.add(animation, forKey: "transform.rotation.z")
    }
}

final class EventCardRSVPComponentProps: ASComponentProps {
    var status: CalendarEventAttendee.Status = .needsAction
    var target: Any?
    var acceptSelector: Selector?
    var declinSelector: Selector?
    var tentativeSelector: Selector?
    var replySelector: (() -> Void)?
    var replyedBtnRetapSelector: Selector?
    var showRSVPInviterEntry: Bool = false
    var shouldDeleteReply: Bool = false
}

final class EventCardRSVPComponent<C: Context>: ASComponent<EventCardRSVPComponentProps, EmptyState, UIView, C> {

    private lazy var acceptBtn: CalendarButtonComponent<C> = {
        let btn = CalendarButtonComponent<C>(
            props: CalendarButtonComponentProps(),
            style: ASComponentStyle(),
            context: nil)
        btn.style.cornerRadius = 6
        btn.style.height = CSSValue(cgfloat: UIFont.ud.body2.figmaHeight + 12)
        btn.style.width = 100%
        btn.style.flexShrink = 1
        btn.props.normalTitleColor = UIColor.ud.textTitle
        btn.props.selectTitleColor = UIColor.ud.functionSuccessContentPressed
        btn.props.normalTitle = BundleI18n.Calendar.Calendar_Detail_Accept
        btn.props.selectTitle = BundleI18n.Calendar.Calendar_Detail_Accepted
        btn.props.font = UIFont.ud.body2
        return btn
    }()

    private lazy var declinBtn: CalendarButtonComponent<C> = {
        let btn = CalendarButtonComponent<C>(
            props: CalendarButtonComponentProps(),
            style: ASComponentStyle(),
            context: nil)
        btn.style.cornerRadius = 6
        btn.style.marginLeft = 12
        btn.style.marginRight = 12
        btn.style.height = CSSValue(cgfloat: UIFont.ud.body2.figmaHeight + 12)
        btn.style.width = 100%
        btn.style.flexShrink = 1
        btn.props.normalTitleColor = UIColor.ud.textTitle
        btn.props.selectTitleColor = UIColor.ud.functionDangerContentPressed
        btn.props.normalTitle = BundleI18n.Calendar.Calendar_Detail_Refuse
        btn.props.selectTitle = BundleI18n.Calendar.Calendar_Detail_Refused
        btn.props.font = UIFont.ud.body2
        return btn
    }()

    private lazy var tentativeBtn: CalendarButtonComponent<C> = {
        let btn = CalendarButtonComponent<C>(
            props: CalendarButtonComponentProps(),
            style: ASComponentStyle(),
            context: nil)
        btn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        btn.style.cornerRadius = 6
        btn.style.height = CSSValue(cgfloat: UIFont.ud.body2.figmaHeight + 12)
        btn.style.width = 100%
        btn.style.flexShrink = 1
        btn.props.normalTitleColor = UIColor.ud.textTitle
        btn.props.selectTitleColor = UIColor.ud.textTitle
        btn.props.normalTitle = BundleI18n.Calendar.Calendar_Detail_Maybe
        btn.props.selectTitle = BundleI18n.Calendar.Calendar_Detail_Maybe
        btn.props.font = UIFont.ud.body2
        return btn
    }()

    private lazy var replyBtn: CalendarButtonComponent<C> = {
        let btn = CalendarButtonComponent<C>(
            props: CalendarButtonComponentProps(),
            style: ASComponentStyle(),
            context: nil)
        btn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        btn.style.cornerRadius = 6
        btn.style.marginLeft = 12
        btn.style.flexShrink = 0
        if Zoom.currentZoom == .large4 {
            btn.style.height = CSSValue(cgfloat: UIFont.ud.body2.figmaHeight + 12)
            btn.style.width = 100%
            btn.props.normalTitleColor = UIColor.ud.textTitle
            btn.props.normalTitle = BundleI18n.Calendar.Calendar_Common_Reply
            btn.props.font = UIFont.ud.body2
        } else {
            btn.style.marginRight = 0
            btn.props.normalImage = UDIcon.getIconByKey(.chatNewsOutlined, size: CGSize(width: 16, height: 16)).renderColor(with: .n2)
            btn.style.height = 32
            btn.style.width = 32
        }

        return btn
    }()

    override init(props: EventCardRSVPComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .spaceBetween
        style.flexDirection = .row
        style.width = 100%
        style.marginTop = 20
        style.paddingLeft = 12
        style.paddingRight = 12
        // 4 * 40 + 30
        style.maxHeight = 190

        let buttons = [acceptBtn, declinBtn, tentativeBtn, replyBtn]
        // 针对最大字号特化，相当于 remake
        if Zoom.currentZoom == .large4 {
            buttons.forEach { (button) in
                button.style.marginRight = 12
                button.style.marginLeft = 0
            }
            declinBtn.style.marginTop = 10
            tentativeBtn.style.marginTop = 10
            replyBtn.style.marginTop = 10
            style.flexDirection = .column
            style.marginLeft = 12
        }
        setSubComponents(buttons)
    }

    override func willReceiveProps(_ old: EventCardRSVPComponentProps, _ new: EventCardRSVPComponentProps) -> Bool {
        let acceptBtnProps = acceptBtn.props
        acceptBtnProps.target = new.target
        acceptBtnProps.selector = new.acceptSelector
        acceptBtnProps.isSelected = new.status == .accept
        if !acceptBtnProps.isSelected {
            acceptBtnProps.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
            acceptBtn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        } else {
            acceptBtnProps.backgroundColor = UIColor.ud.functionSuccessFillTransparent01
            acceptBtn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.functionSuccessContentDefault, style: .solid))
        }
        acceptBtn.props = acceptBtnProps

        let declinBtnProps = declinBtn.props
        declinBtnProps.target = new.target
        declinBtnProps.selector = new.declinSelector
        declinBtnProps.isSelected = new.status == .decline
        if !declinBtnProps.isSelected {
            declinBtnProps.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
            declinBtn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        } else {
            declinBtnProps.backgroundColor = UIColor.ud.functionDangerFillTransparent01
            declinBtn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.functionDangerContentDefault, style: .solid))
        }

        declinBtn.props = declinBtnProps

        let tentativBtnProps = tentativeBtn.props
        tentativBtnProps.target = new.target
        tentativBtnProps.selector = new.tentativeSelector
        tentativBtnProps.isSelected = new.status == .tentative
        if !tentativBtnProps.isSelected {
            tentativBtnProps.backgroundColor = UIColor.ud.udtokenComponentOutlinedBg
            tentativeBtn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderComponent, style: .solid))
        } else {
            tentativBtnProps.backgroundColor = UIColor.ud.N50
            tentativeBtn.style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N500, style: .solid))
        }
        tentativeBtn.props = tentativBtnProps

        let replyBtnProps = replyBtn.props
        replyBtnProps.replySelector = new.replySelector
        replyBtnProps.target = new.target
        replyBtn.props = replyBtnProps
        replyBtn.style.display = new.showRSVPInviterEntry ? .flex : .none
        if new.shouldDeleteReply {
            replyBtn.style.display = .none
        }
        return true
    }
}
