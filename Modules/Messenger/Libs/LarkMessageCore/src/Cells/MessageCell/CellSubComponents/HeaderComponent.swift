//
//  HeaderComponent.swift
//  LarkChat
//
//  Created by Ping on 2023/2/20.
//

import UIKit
import Foundation
import LarkTag
import LarkModel
import LarkFocus
import EEFlexiable
import AsyncComponent
import LarkMessageBase

public final class HeaderComponentProps<C: Context>: ASComponentProps {
    public var fromChatter: Chatter?
    public var nameAndDescColor: UIColor = UIColor.ud.textPlaceholder
    public var chatterStatusDivider: UIColor = UIColor.ud.lineDividerDefault
    public var getDisplayName: ((Chatter) -> String)?
    public var contentPreferMaxWidth: CGFloat = 0
    public var nameTag: [Tag] = []
    public var nameFont: UIFont = UIFont.ud.caption1
    public var nameTextColor: UIColor = UIColor.ud.textPlaceholder
    public var formatTime: String?
    // 是否显示个人状态
    public var shwoFocusStatus: Bool = true
    // 子组件
    public var subComponents: [SubType: ComponentWithContext<C>] = [:]
}

/// 右边顶部区域，包含名字、tag和个人状态
public final class HeaderComponent<C: Context>: ASLayoutComponent<C> {
    public var props: HeaderComponentProps<C> {
        didSet {
            update()
        }
    }

    /// 名字
    lazy var name: ChatMessagePersonalNameUILabelComponent<C> = {
        let props = ChatMessagePersonalNameUILabelComponentProps()
        props.font = UIFont.ud.caption1
        props.oneLineHeight = UIFont.ud.caption1.figmaHeight
        props.textColor = UIColor.ud.textPlaceholder

        let style = ASComponentStyle()
        style.flexShrink = 0
        style.backgroundColor = .clear
        style.marginRight = 4
        return ChatMessagePersonalNameUILabelComponent<C>(props: props, style: style)
    }()

    /// 个人状态 icon
    lazy var focusIcon: FocusTagComponent<C> = {
        let props = FocusTagComponent<C>.Props()
        let style = ASComponentStyle()
        style.display = .none
        style.flexShrink = 0
        style.marginRight = 4
        return FocusTagComponent<C>(props: props, style: style)
    }()

    /// tag
    lazy var tag: TagComponent<C> = {
        let props = TagComponentProps()
        props.tags = self.props.nameTag

        let style = ASComponentStyle()
        style.marginRight = 4
        style.flexShrink = 0
        return TagComponent(props: props, style: style)
    }()

    /// 签名前面的 “｜” 分割线
    private lazy var chatterStatusDivider: UIViewComponent<C> = {
        let props = ASComponentProps()
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.width = 1
        style.height = 10
        style.marginLeft = 2
        style.marginRight = 6
        return UIViewComponent<C>(props: props, style: style)
    }()

    // 时间：目前消息链接化场景会显示
    private lazy var time: UILabelComponent<C> = {
        let font = UIFont.ud.caption1
        let props = UILabelComponentProps()
        props.textColor = UIColor.ud.textPlaceholder
        props.font = font
        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: font.pointSize)
        style.display = .none
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    public init(
        props: HeaderComponentProps<C>,
        key: String = "",
        style: ASComponentStyle,
        context: C? = nil
    ) {
        self.props = props
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.justifyContent = .flexStart
        style.alignItems = .center
        style.marginBottom = 4
        style.height = UIFont.ud.caption1.figmaHeight.css  // name font
        super.init(key: key, style: style, context: context, [])
    }

    private func update() {
        // 名字
        if let fromChatter = props.fromChatter {
            name.props.textColor = props.nameAndDescColor
            name.props.text = props.getDisplayName?(fromChatter)
            name.props.chatterId = fromChatter.id
        } else {
            name.props.text = ""
            name.props.chatterId = ""
        }
        // 名字限制最大宽度，否则当名字过长时会将其他元素挤出屏幕
        name._style.maxWidth = CSSValue(
            cgfloat: props.contentPreferMaxWidth * 0.7
        )
        name.props.contentPreferMaxWidth = props.contentPreferMaxWidth * 0.7
        name.props.font = props.nameFont
        name.props.textColor = props.nameTextColor

        // 自定义个人状态（Focus）
        if let chatter = props.fromChatter,
           let focusStatus = chatter.focusStatusList.topActive,
           props.shwoFocusStatus {
            focusIcon.style.display = .flex
            focusIcon.props.focusStatus = focusStatus
        } else {
            focusIcon.style.display = .none
        }

        // tag
        tag.props.tags = props.nameTag

        // 整个header（包含名字、tag、个人状态)
        var headerSubComponents: [ComponentWithContext<C>] = [name, focusIcon, tag]
        if let chatterStatus = props.subComponents[.chatterStatus] {
            chatterStatus._style.flexShrink = 1
            headerSubComponents.append(contentsOf: [chatterStatusDivider, chatterStatus])
            chatterStatusDivider.style.backgroundColor = props.chatterStatusDivider
        }

        if let formatTime = props.formatTime {
            time.style.display = .flex
            time.props.text = formatTime
            headerSubComponents.append(time)
        }

        setSubComponents(headerSubComponents)
    }
}
