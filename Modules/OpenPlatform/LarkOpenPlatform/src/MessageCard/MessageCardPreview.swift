//
//  MessageCardPreview.swift
//  LarkOpenPlatform
//
//  Created by 李论 on 2020/1/13.
//

import UIKit
import LarkModel
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import NewLarkDynamic
import EENavigator
import RustPB
import LKCommonsLogging
private let logger = Logger.log(LDContext.self, category: "LarkNewDynamic.MessageCardPreviewComponent")

final class MessageCardPreview: UIView {
}

final class MessageCardPreviewComponent<C: MessageCardPreviewContext>: ASComponent<MessageCardPreviewComponent.Props, EmptyState, MessageCardPreview, C> {
    final class Props: ASComponentProps {
        public var headerTitle: String?
        public var headerTitleColor: UIColor?
        public var headerBackgroundColors: [UIColor]?
        public var theme: String?
        public var cardContent: Basic_V1_CardContent
        public var subTitle: String? = nil
        public var iconProperty: RichTextElement.ImageProperty? = nil
        public init(card: Basic_V1_CardContent) {
            self.cardContent = card
            self.subTitle = card.cardHeader.hasSubtitle ? card.cardHeader.subtitle : nil
            self.iconProperty = card.cardHeader.hasIcon ? card.cardHeader.icon : nil
        }
    }

    var ldHeaderProps = LDHeaderComponent<MessageCardPreviewContext>.Props()
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

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {

        if props.cardContent.hasCardHeader {
            let headerContent = props.cardContent.cardHeader
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
        dynamicStyle.paddingTop = props.cardContent.hasCardHeader ? 0 : 12
        dynamicStyle.paddingLeft = 12
        dynamicStyle.paddingBottom = 12
        dynamicStyle.paddingRight = 12

        let richText = Self.updateDarkModeStyle(cardContent: props.cardContent)
        self.dynamicComponent = LDRootComponent<MessageCardPreviewContext>(
            props: LDRootComponentProps(richtext: richText,
                                        cardContent: CardContent.transform(cardContent: props.cardContent)),
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
    
    private static func updateDarkModeStyle(cardContent: Basic_V1_CardContent) -> RustPB.Basic_V1_RichText {
        let version = cardContent.cardVersion
        let style = MessageCardStyleManager.shared.messageCardStyle()
        let darkprocess = RichTextDarkModePreProcessor(cardVersion: Int(version),
                                                       cardStyle: style,
                                                       styleCache: MessageCardStyleManager.shared)
        let darkmodeRichText = darkprocess.richTextApplyDarkMode(originRichText: cardContent.richtext)
        return darkmodeRichText
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        let hasHeader = !(new.headerTitle?.isEmpty ?? true)
        ldHeaderComponent.style.height = hasHeader ? YGValueAuto : 0
        ldHeaderProps.text = new.headerTitle ?? ""
        ldHeaderProps.textColor = new.headerTitleColor
        ldHeaderProps.backgroundColors = new.headerBackgroundColors ?? []
        ldHeaderProps.theme = new.theme ?? ""
        ldHeaderComponent.props = ldHeaderProps
        ldHeaderProps.subTitle = new.subTitle
        ldHeaderProps.iconProperty = new.iconProperty
        let richText = Self.updateDarkModeStyle(cardContent: props.cardContent)
        dynamicComponent.props = LDRootComponentProps(richtext: richText,
                                                      cardContent: CardContent.transform(cardContent: props.cardContent))
        return true
    }
}
