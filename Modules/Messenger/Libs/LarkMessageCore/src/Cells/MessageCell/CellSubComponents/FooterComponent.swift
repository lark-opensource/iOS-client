//
//  FooterComponent.swift
//  LarkChat
//
//  Created by Ping on 2023/2/21.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

public final class FooterComponentProps<C: Context>: ASComponentProps {
    // 是否展示时间
    public var showTime: Bool = false
    public var bottomFormatTime: String = ""
    // 底部时间文字
    public var bottomTimeTextColor: UIColor = UIColor.ud.textPlaceholder
    // 是否是临时消息
    public var isEphemeral: Bool = false
    public var avatarLayout: AvatarLayout = .left
    public var inSelectMode: Bool = false
    public var oneOfSubComponentsDisplay: (([SubType]) -> Bool)?
    // 子组件
    public var subComponents: [SubType: ComponentWithContext<C>] = [:]
}

public final class FooterComponent<C: Context>: ASLayoutComponent<C> {
    public var props: FooterComponentProps<C> {
        didSet {
            update()
        }
    }

    // 支持的类型
    private var supportSubTypes: [SubType] {
        return [
            .dlpTip,
            .riskFile,
            .restrict,
            .multiEditStatus,
            .countDown,
            .replyThreadInfo,
            .replyStatus,
            .pin,
            .chatPin,
            .urgentTip,
            .quickActions,
            .forward
        ]
    }

    /// pin和reply一行，容器包一下
    lazy var footerReplyPin: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignItems = .flexStart
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 底部时间
    lazy var bottomTime: UILabelComponent<C> = {
        let font = UIFont.ud.caption1
        let props = UILabelComponentProps()
        props.textColor = UIColor.ud.textPlaceholder
        props.font = font
        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: font.pointSize)
        style.backgroundColor = .clear
        style.marginTop = 4
        return UILabelComponent<C>(props: props, style: style)
    }()

    public init(
        props: FooterComponentProps<C>,
        key: String = "",
        style: ASComponentStyle,
        context: C? = nil
    ) {
        self.props = props
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.display = .none
        super.init(key: key, style: style, context: context, [])
    }

    private func update() {
        // 如果DLP管控提示、时间、焚毁倒计时、回复数、pin、加急、语音转发有一个显示的情况下，footer容器就需要显示
        let anySubComponentShow = props.showTime || self.oneOfSubComponentsDisplay(supportSubTypes)
        guard anySubComponentShow else {
            self.style.display = .none
            return
        }
        var footerSubs: [ComponentWithContext<C>] = []
        // DLP管控提示"发送失败,消息内容包含敏感信息"
        if let dlpTip = props.subComponents[.dlpTip] {
            footerSubs.append(dlpTip)
            if props.avatarLayout == .left {
                dlpTip._style.marginRight = 18
            } else {
                dlpTip._style.marginLeft = 18
            }
        }

        // 文件安全检测提示
        if let riskFile = props.subComponents[.riskFile] {
            footerSubs.append(riskFile)
        }

        // 保密消息
        if props.inSelectMode, let restrictTip = props.subComponents[.restrict] {
            footerSubs.append(restrictTip)
        }

        //二次编辑状态
        if let multiEditStatus = props.subComponents[.multiEditStatus] {
            footerSubs.append(multiEditStatus)
        }

        // 密聊倒计时
        if let countDown = props.subComponents[.countDown] {
            footerSubs.append(countDown)
        }

        // General Forward
        if let forward = props.subComponents[.forward] {
            footerSubs.append(forward)
        }

        // 底部UrgentTip
        if let urgentTips = props.subComponents[.urgentTip] {
            footerSubs.append(urgentTips)
        }

        // Reply & Pin (这两个占一行)
        var replyAndPin: [ComponentWithContext<C>] = []
        if let replyStatus = props.subComponents[.replyStatus] {
            replyStatus._style.flexShrink = 0
            replyAndPin.append(replyStatus)
        }
        if let replyStatus = props.subComponents[.replyThreadInfo] {
            replyStatus._style.flexShrink = 0
            replyStatus._style.flexDirection = self.props.avatarLayout == .left ? .row : .rowReverse
            replyAndPin.append(replyStatus)
        }
        if let pin = props.subComponents[.pin] {
            pin._style.flexShrink = 1
            pin._style.marginTop = props.subComponents[.replyThreadInfo] == nil ? 4 : 8
            replyAndPin.append(pin)
        }
        if let chatPin = props.subComponents[.chatPin] {
            replyAndPin.append(chatPin)
        }
        footerReplyPin.setSubComponents(replyAndPin)
        footerSubs.append(footerReplyPin)

        // 快捷指令
        if let quickAction = props.subComponents[.quickActions] {
            footerSubs.append(quickAction)
        }

        // Time
        bottomTime.style.display = props.showTime ? .flex : .none
        bottomTime.props.text = props.showTime ? props.bottomFormatTime : ""
        bottomTime.props.textColor = props.bottomTimeTextColor
        footerSubs.append(bottomTime)

        // 整个footer容器
        self.setSubComponents(footerSubs)
        self.style.display = .flex
        self.style.marginBottom = self.oneOfSubComponentsDisplay([.replyStatus, .pin, .urgentTip, .forward]) ? 4 : 0
        self.style.marginTop = CSSValue(cgfloat: props.isEphemeral ? 8 : 0)
        switch self.props.avatarLayout {
        case .left:
            self.style.alignItems = .flexStart
            footerReplyPin.style.alignItems = .flexStart
        case .right:
            self.style.alignItems = .flexEnd
            footerReplyPin.style.alignItems = .flexEnd
        }
    }

    private func oneOfSubComponentsDisplay(_ types: [SubType]) -> Bool {
        return props.oneOfSubComponentsDisplay?(types) ?? false
    }
}
