//
//  ContentComponent.swift
//  LarkChat
//
//  Created by Ping on 2023/2/21.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

public final class ContentComponentProps<C: Context>: ASComponentProps {
    // 标记相关
    public var flagIconMargin: CGFloat = 6
    // 消息状态
    public var hasMessageStatus: Bool = true
    // checkbox
    public var showCheckBox: Bool = false
    public var checked: Bool = false
    // 是否支持选中
    public var selectedEnable: Bool = false
    // 是否消息被折叠
    public var isFold = false
    public var avatarLayout: AvatarLayout = .left
    public var bubbleView: ComponentWithContext<C>
    public var oneOfSubComponentsDisplay: (([SubType]) -> Bool)?
    // 子组件
    public var subComponents: [SubType: ComponentWithContext<C>] = [:]

    public init(bubbleView: ComponentWithContext<C>) {
        self.bubbleView = bubbleView
    }
}

public final class ContentComponent<C: Context>: ASLayoutComponent<C> {
    public var props: ContentComponentProps<C> {
        didSet {
            update()
        }
    }

    /// 消息状态容器： [flagComponent , statusComponent]
    lazy var contentStatusContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        style.height = 100%
        style.justifyContent = .spaceBetween
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 放在气泡区域的checkbox
    lazy var checkbox: LKCheckboxComponent<C> = {
        let style = ASComponentStyle()
        style.width = 20
        style.height = 20
        style.position = .absolute
        style.marginTop = -10
        style.top = 50%
        style.left = 0
        style.display = .none
        let props = LKCheckboxComponentProps()
        props.key = ChatCellConsts.checkboxKey
        return LKCheckboxComponent<C>(props: props, style: style)
    }()

    public init(
        props: ContentComponentProps<C>,
        key: String = "",
        style: ASComponentStyle,
        context: C? = nil
    ) {
        self.props = props
        let style = ASComponentStyle()
        style.alignItems = .flexStart
        style.flexWrap = .noWrap
        super.init(key: key, style: style, context: context, [])
    }

    private func update() {
        // 气泡
        var contentSubComponents: [ComponentWithContext<C>] = [props.bubbleView]
        // 右边状态栏
        var contentStatusComponents: [ComponentWithContext<C>] = []
        if let flag = props.subComponents[.flag] {
            contentStatusComponents.append(flag)
            contentStatusContainer.style.justifyContent = .flexStart
        }

        if let status = props.subComponents[.messageStatus] {
            let oldDisplay = status._style.display
            status._style.display = props.hasMessageStatus ? oldDisplay : .none
            contentStatusContainer.style.justifyContent = oneOfSubComponentsDisplay([.flag]) ? .spaceBetween : .flexEnd
            contentStatusComponents.append(status)
        }
        contentStatusContainer.setSubComponents(contentStatusComponents)
        contentSubComponents.append(contentStatusContainer)

        // 左边绝对定位的checkbox
        checkbox._style.display = props.showCheckBox ? .flex : .none
        if props.showCheckBox { contentSubComponents.insert(checkbox, at: 0) }
        checkbox.props.isSelected = props.checked
        checkbox.props.isEnabled = props.selectedEnable

        self.setSubComponents(contentSubComponents)

        switch props.avatarLayout {
        case .left:
            if let flag = props.subComponents[.flag] {
                flag._style.marginLeft = CSSValue(cgfloat: props.flagIconMargin)
            }
            checkbox.style.left = -36
            self.style.flexDirection = .row
            self.style.justifyContent = (props.isFold ? .center : .flexStart)
        case .right:
            if let flag = props.subComponents[.flag] {
                flag._style.marginRight = CSSValue(cgfloat: props.flagIconMargin)
            }
            checkbox.style.left = 0
            self.style.flexDirection = .rowReverse
            self.style.justifyContent = (props.isFold ? .center : .flexStart)
        }
    }

    private func oneOfSubComponentsDisplay(_ types: [SubType]) -> Bool {
        return props.oneOfSubComponentsDisplay?(types) ?? false
    }
}
