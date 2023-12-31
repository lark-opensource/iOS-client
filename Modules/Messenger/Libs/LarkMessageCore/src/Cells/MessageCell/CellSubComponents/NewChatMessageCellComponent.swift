//
//  NewChatMessageCellComponent.swift
//  LarkChat
//
//  Created by Ping on 2023/2/16.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import UniverseDesignColor

public enum ChatMessageCellSubType: CaseIterable {
    case highlight // 高亮
    case avatar // 头像区域
    case top // 顶部区域
    case header // header区域
    case content // 内容区域
    case footer // 底部区域
}

public final class NewChatMessageCellProps<C: Context>: SafeASComponentProps {
    public var inSelectMode: Bool = false
    // 非吸附消息
    public var isSingle: Bool = true
    // 是否消息被折叠
    public var isFold = false
    // 是否是临时消息
    public var isEphemeral: Bool = false
    public var cellBackgroundColor = UIColor.clear
    public var avatarLayout: AvatarLayout = .left
    public var maxCellWidth: CGFloat = UIScreen.main.bounds.width
    private var _subComponents: [ChatMessageCellSubType: ComponentWithContext<C>] = [:]
    public var subComponents: [ChatMessageCellSubType: ComponentWithContext<C>] {
        get {
            safeRead {
                self._subComponents
            }
        }
        set {
            safeWrite {
                self._subComponents = newValue
            }
        }
    }
    // 头像大小
    public var avatarSize: CGFloat = 30.auto()
    public var cellHorizontalPadding: CGFloat = 16
    public var leftContainerPaddingRight: CGFloat = 6
}

// CellComponent相关生命周期
public protocol ChatMessageCellComponentLifeCycle: AnyObject {
    func update(view: UIView)
}

public final class NewChatMessageCellComponent<C: Context>: ASComponent<NewChatMessageCellProps<C>, EmptyState, UIView, C> {
    public weak var lifeCycle: ChatMessageCellComponentLifeCycle?

    /// 左边，包含头像区域
    lazy var leftContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexShrink = 0
        style.flexDirection = .column
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// 右边容器
    lazy var rightContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.flexGrow = 1
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// warp leftContainer and leftContainer
    private lazy var contentComponent: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.paddingBottom = 2
        style.width = 100%
        return ASLayoutComponent(style: style, context: context, [leftContainer, rightContainer])
    }()

    public override init(props: NewChatMessageCellProps<C>, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        leftContainer.style.width = CSSValue(cgfloat: props.avatarSize + props.cellHorizontalPadding + props.leftContainerPaddingRight)
        var subComponents: [ComponentWithContext<C>] = [contentComponent]
        if let highlight = props.subComponents[.highlight] {
            subComponents.insert(highlight, at: 0)
        }
        setSubComponents(subComponents)
    }

    public override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: props.maxCellWidth)
        return super.render()
    }

    public override func willReceiveProps(_ old: NewChatMessageCellProps<C>, _ new: NewChatMessageCellProps<C>) -> Bool {
        if let highlight = new.subComponents[.highlight] {
            setSubComponents([highlight, contentComponent])
        } else {
            setSubComponents([contentComponent])
        }

        leftContainer.style.width = CSSValue(cgfloat: props.avatarSize + props.cellHorizontalPadding + props.leftContainerPaddingRight)
        if let avatar = new.subComponents[.avatar] {
            leftContainer.setSubComponents([avatar])
        } else {
            leftContainer.setSubComponents([])
        }

        var rightSubComponents: [ComponentWithContext<C>] = []
        if let top = new.subComponents[.top] {
            rightSubComponents.append(top)
            // 显示top时，需要留一个padding
            leftContainer.style.paddingTop = 24
        } else {
            leftContainer.style.paddingTop = 0
        }
        if let header = new.subComponents[.header] {
            rightSubComponents.append(header)
        }
        if let content = new.subComponents[.content] {
            rightSubComponents.append(content)
        }
        if let footer = new.subComponents[.footer] {
            rightSubComponents.append(footer)
        }
        rightContainer.setSubComponents(rightSubComponents)

        // layout
        if new.isSingle {
            self.style.paddingTop = new.isEphemeral ? 8 : 24
            self.style.paddingBottom = new.isEphemeral ? 8 : 0
            if new.isFold {
                self.style.paddingTop = 22
            }
        } else {
            self.style.paddingTop = 4
            self.style.paddingBottom = new.isEphemeral ? 8 : 0
        }

        self.style.backgroundColor = new.cellBackgroundColor

        layoutByAvatarLayout(props: new)

        return true
    }

    public override func update(view: UIView) {
        super.update(view: view)
        // 多选态消息整个消息屏蔽点击事件，只响应cell层的显示时间和选中事件
        view.isUserInteractionEnabled = !props.inSelectMode
        lifeCycle?.update(view: view)
    }

    //根据头像巨左或居右，调整布局
    private func layoutByAvatarLayout(props: NewChatMessageCellProps<C>) {
        switch self.props.avatarLayout {
        case .left:
            self.style.flexDirection = .row
            self.leftContainer.style.alignItems = .flexEnd
            self.leftContainer.style.paddingRight = CSSValue(cgfloat: props.leftContainerPaddingRight)
            self.leftContainer.style.display = props.isFold ? .none : .flex
            self.contentComponent.style.flexDirection = .row
            self.rightContainer.style.paddingRight = props.isFold ? 0 : CSSValue(cgfloat: props.cellHorizontalPadding)
            self.rightContainer.style.justifyContent = .flexStart
        case .right:
            self.style.flexDirection = .rowReverse
            self.leftContainer.style.alignItems = .flexStart
            self.leftContainer.style.paddingLeft = CSSValue(cgfloat: props.leftContainerPaddingRight)
            self.leftContainer.style.display = (props.isFold || props.inSelectMode) ? .none : .flex
            self.contentComponent.style.flexDirection = .rowReverse
            self.rightContainer.style.paddingLeft = props.isFold ? 0 : CSSValue(cgfloat: props.cellHorizontalPadding)
            self.rightContainer.style.paddingRight = (props.isFold || !props.inSelectMode) ? 0 : CSSValue(cgfloat: props.cellHorizontalPadding)
        }
    }
}
