//
//  MessageCardPinComponent.swift
//  LarkOpenPlatform
//
//  Created by MJXin on 2022/6/15.
//

import Foundation
import Foundation
import UIKit
import AsyncComponent
import LarkModel
import LarkMessageCore
import LarkChat
import LKCommonsLogging
import NewLarkDynamic
import EEFlexiable
import RustPB

final class MessageCardPinComponent<C: MessageCardPreviewContext>: ASComponent<MessageCardPinComponent.Props, EmptyState, MessageCardPreview, C> {
    
    // 设计稿定义内边距
    private let padding: CSSValue = 12
    
    final class Props: ASComponentProps {
        public var cardContent: CardContent
        public var subTitle: String? = nil
        public var iconProperty: RichTextElement.ImageProperty? = nil
        public init(card: CardContent) {
            self.cardContent = card
            self.subTitle = card.header.hasSubtitle ? card.header.subtitle : nil
            self.iconProperty = card.header.hasIcon ? card.header.icon : nil
        }
    }
    
    private var ldHeaderProps = LDHeaderComponent<MessageCardPreviewContext>.Props()
    private var ldHeaderStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.height = 0
        style.top = 0
        style.flexShrink = 0
        style.overflow = .scroll
        return style
    }()
    private var ldHeaderComponent: LDHeaderComponent<MessageCardPreviewContext>
    private var dynamicComponent: LDRootComponent<MessageCardPreviewContext>
    
    private static func updateDarkModeStyle(cardContent: CardContent) -> RustPB.Basic_V1_RichText {
        let version = cardContent.version
        let style = MessageCardStyleManager.shared.messageCardStyle()
        let darkprocess = RichTextDarkModePreProcessor(
            cardVersion: Int(version),
            cardStyle: style,
            styleCache: MessageCardStyleManager.shared)
        let darkmodeRichText = darkprocess.richTextApplyDarkMode(originRichText: cardContent.richText)
        return darkmodeRichText
    }

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        let hasHeader = !props.cardContent.header.isEmptyTitle()

        if hasHeader {
            let headerContent = props.cardContent.header
            ldHeaderProps.text = headerContent.getTitle() ?? ""
            ldHeaderProps.textColor = headerContent.color
            ldHeaderProps.backgroundColors = headerContent.backgroundColors
            ldHeaderProps.theme = headerContent.theme
            ldHeaderProps.subTitle = props.subTitle
            ldHeaderProps.iconProperty = props.iconProperty
            ldHeaderStyle.height = YGValueAuto
        }
        self.ldHeaderComponent = LDHeaderComponent<MessageCardPreviewContext>(props: ldHeaderProps, style: ldHeaderStyle, context: context)
        let dynamicStyle = ASComponentStyle()
        dynamicStyle.flexShrink = 0
        dynamicStyle.overflow = .scroll
        dynamicStyle.paddingTop = hasHeader ? 0 : padding
        dynamicStyle.paddingLeft = padding
        dynamicStyle.paddingBottom = padding
        dynamicStyle.paddingRight = padding

        let richText = Self.updateDarkModeStyle(cardContent: props.cardContent)
        self.dynamicComponent = LDRootComponent<MessageCardPreviewContext>(
            props: LDRootComponentProps(
                richtext: richText,
                cardContent: props.cardContent
            ),
            style: dynamicStyle,
            context: context
        )

        style.flexWrap = .noWrap
        style.flexDirection = .column
        style.alignItems = .stretch
        style.overflow = .scroll

        super.init(props: props, style: style, context: context)

        let subs = [self.ldHeaderComponent, self.dynamicComponent] as? [ComponentWithContext<C>] ?? []
        setSubComponents(subs)
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        let hasHeader = !props.cardContent.header.isEmptyTitle()
        ldHeaderComponent.style.height = hasHeader ? YGValueAuto : 0
        ldHeaderProps.text = new.cardContent.header.title
        ldHeaderProps.textColor = new.cardContent.header.color
        ldHeaderProps.backgroundColors = new.cardContent.header.backgroundColors ?? []
        ldHeaderProps.theme = new.cardContent.header.theme ?? ""
        ldHeaderComponent.props = ldHeaderProps
        ldHeaderProps.subTitle = new.subTitle
        ldHeaderProps.iconProperty = new.iconProperty
        let richText = Self.updateDarkModeStyle(cardContent: props.cardContent)
        dynamicComponent.props = LDRootComponentProps(richtext: richText,
                                                      cardContent:  props.cardContent)
        return true
    }
}
