//
//  PinMessageCellComponent.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/22.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkMessageCore
import LarkModel
import EEFlexiable

final class PinMessageCellProps: ASComponentProps {
    var fromChatter: Chatter?
    var getDisplayName: ((Chatter) -> String)?
    var sendTime: String = ""
    var contentComponent: ComponentWithContext<PinContext>
    var contentPreferMaxWidth: CGFloat = 0
    var fromChat: String?
    // 子组件
    var subComponents: [SubType: ComponentWithContext<PinContext>] = [:]
    var onFunctionButtonClicked: ((UIView) -> Void)?
    var onlyHasDocLink: Bool = false
    var onlyHasURLLink: Bool = false
    var showSeperateLine: Bool = true
    init(contentComponent: ComponentWithContext<PinContext>) {
        self.contentComponent = contentComponent
    }
}

final class PinMessageCellComponent: ASComponent<PinMessageCellProps, EmptyState, UIView, PinContext> {

    private enum Cons {
        static var nameFont: UIFont { return UIFont.ud.caption1 }
        static var timeFont: UIFont { return UIFont.ud.caption3 }
        static var fromFont: UIFont { return UIFont.ud.body2 }
        static var nameTimeMargin: CGFloat = 2
        static var avatarDimention: CGFloat {
            return nameFont.rowHeight + nameTimeMargin + timeFont.rowHeight
        }
    }

    static let hightViewKey = "pinMessageCell_highlightKey"

    override init(props: PinMessageCellProps, style: ASComponentStyle, context: PinContext? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.flexDirection = .column
        self.style.alignItems = .stretch
        style.paddingLeft = 16
        style.paddingRight = 16
        style.paddingBottom = 6
        style.paddingTop = 6
        setSubComponents([highlightViewComponent, bubbleContainer])
    }

    private lazy var highlightViewComponent: UIViewComponent<PinContext> = {
        let viewProps = ASComponentProps()
        viewProps.key = PinMessageCellComponent.hightViewKey

        let viewStyle = ASComponentStyle()
        viewStyle.position = .absolute
        viewStyle.backgroundColor = UIColor.ud.Y50
        viewStyle.top = 0
        viewStyle.bottom = 0
        viewStyle.right = 0
        viewStyle.left = 0
        return UIViewComponent<PinContext>(props: viewProps, style: viewStyle)
    }()

    lazy var bubbleContainer: UIViewComponent<PinContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignItems = .stretch
        style.cornerRadius = 4
        style.backgroundColor = UIColor.ud.bgBody
        style.padding = 16
        let bubble = UIViewComponent(props: .empty, style: style, context: context)
        return bubble
    }()

    /// 上边，包含头像、消息发送时间
    lazy var topContainer: ASLayoutComponent<PinContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.justifyContent = .spaceBetween
        return ASLayoutComponent(style: style, context: context, [avatarContainer, functionButton])
    }()

    /// 头像+(名字+发送时间)
    lazy var avatarContainer: ASLayoutComponent<PinContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        return ASLayoutComponent(style: style, context: context, [avatar, nameAndSendTimeContainer])
    }()

    /// 头像
    lazy var avatar: AvatarComponent<PinContext> = {
        let props = AvatarComponent<PinContext>.Props()
        let style = ASComponentStyle()
        let dimention = CSSValue(cgfloat: Cons.avatarDimention)
        style.width = dimention
        style.height = dimention
        return AvatarComponent(props: props, style: style)
    }()

    /// 名字+发送时间
    lazy var nameAndSendTimeContainer: ASLayoutComponent<PinContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.marginLeft = 6
        return ASLayoutComponent(style: style, context: context, [name, sendTime])
    }()

    /// 名字
    lazy var name: UILabelComponent<PinContext> = {
        let props = UILabelComponentProps()
        props.font = Cons.nameFont
        props.textColor = UIColor.ud.textTitle

        let style = ASComponentStyle()
        style.flexShrink = 0
        style.backgroundColor = .clear
        return UILabelComponent<PinContext>(props: props, style: style)
    }()

    /// 时间
    lazy var sendTime: UILabelComponent<PinContext> = {
        let props = UILabelComponentProps()
        props.textColor = UIColor.ud.textPlaceholder
        props.font = Cons.timeFont
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 2
        return UILabelComponent<PinContext>(props: props, style: style)
    }()

    lazy var bottomContainer: ASLayoutComponent<PinContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.marginLeft = 6
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// ...功能按钮
    lazy var functionButton: TappedImageComponent<PinContext> = {
        let props = TappedImageComponentProps()
        let style = ASComponentStyle()
        return TappedImageComponent<PinContext>(props: props, style: style)
    }()

    // 分割横线
    lazy var seperateLine: UIViewComponent<PinContext> = {
        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: 1.0)
        style.backgroundColor = UIColor.ud.lineDividerDefault
        style.marginTop = 14
        return UIViewComponent<PinContext>(props: .empty, style: style)
    }()

    lazy var contentWrapper: ASLayoutComponent<PinContext> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.marginTop = 12
        return ASLayoutComponent(style: style, context: context, [])
    }()

    /// pin来自哪个群
    lazy var fromChat: UILabelComponent<PinContext> = {
        let props = UILabelComponentProps()
        props.font = Cons.fromFont
        props.textColor = UIColor.ud.textPlaceholder

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 12
        return UILabelComponent<PinContext>(props: props, style: style)
    }()

    override func render() -> BaseVirtualNode {
        self.style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }

    override func willReceiveProps(_ old: PinMessageCellProps, _ new: PinMessageCellProps) -> Bool {
        self.setupBubbleView(props: new)
        avatar.props.avatarKey = new.fromChatter?.avatarKey ?? ""
        avatar.props.id = new.fromChatter?.id ?? ""
        if let fromChatter = new.fromChatter {
            name.props.text = new.getDisplayName?(fromChatter)
        } else {
            name.props.text = ""
        }
        contentWrapper.setSubComponents([new.contentComponent])
        sendTime.props.text = new.sendTime
        fromChat.props.text = new.fromChat ?? ""
        let funcProps = TappedImageComponentProps()
        funcProps.image = Resources.pinFunction.ud.withTintColor(UIColor.ud.iconN2)
        funcProps.iconSize = CGSize(width: 24, height: 24)
        funcProps.onClicked = new.onFunctionButtonClicked
        functionButton.props = funcProps
        if let riskFile = props.subComponents[.riskFile] {
            bottomContainer.setSubComponents([riskFile])
        }
        return true
    }

    private func setupBubbleView(props: PinMessageCellProps) {
        var bubbleSubComponents: [ComponentWithContext<PinContext>] = [topContainer, seperateLine, contentWrapper, bottomContainer]
        contentWrapper.style.display = .flex
        seperateLine.style.display = props.showSeperateLine ? .flex : .none
        var hasDocPreview = false
        // doc预览
        if let docPreview = props.subComponents[.docsPreview], docPreview._style.display == .flex {
            hasDocPreview = true
            docPreview._style.marginTop = 12
            bubbleSubComponents.append(docPreview)
            if props.onlyHasDocLink {
                contentWrapper.style.display = .none
                seperateLine.style.display = .none
            }
        }
        // url预览
        if !hasDocPreview, let urlPreview = props.subComponents[.urlPreview], urlPreview._style.display == .flex {
            urlPreview._style.marginTop = 12
            bubbleSubComponents.append(urlPreview)
            if props.onlyHasURLLink {
                contentWrapper.style.display = .none
                seperateLine.style.display = .none
            }
        }
        if props.fromChat != nil {
            bubbleSubComponents.append(fromChat)
        }
        bubbleContainer.style.width = CSSValue(cgfloat: props.contentPreferMaxWidth)
        bubbleContainer.setSubComponents(bubbleSubComponents)
    }
}
