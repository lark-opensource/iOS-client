//
//  ChatCardSummaryComponent.swift
//  Todo
//
//  Created by 白言韬 on 2021/5/23.
//

import Foundation
import AsyncComponent
import EEFlexiable
import RichLabel

// nolint: magic number
class ChatCardSummaryComponentProps: ASComponentProps {
    var textInfo: ChatCardRichTextInfo?
    var linkHandler: ChatCardLinkHandler?
    var preferMaxLayoutWidth: CGFloat?

    var checkboxInfo: ChatCardCheckboxInfo = .init(checkState: .enabled(isChecked: false))
}

class ChatCardSummaryComponent<C: Context>: ASComponent<ChatCardSummaryComponentProps, EmptyState, UIView, C> {

    private lazy var checkboxComponent: ChatCardCheckboxComponent<C> = {
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.marginTop = 13.5
        style.marginRight = 8
        style.flexShrink = 0
        return ChatCardCheckboxComponent(props: .init(), style: style)
    }()

    private lazy var textComponent: RichLabelComponent<C> = {
        let props = RichLabelProps()
        props.numberOfLines = 5
        props.lineSpacing = 4
        props.outOfRangeText = AttrText(string: "\u{2026}", attributes: [.foregroundColor: UIColor.ud.textTitle])

        var style = ASComponentStyle()
        style.marginTop = 12
        style.backgroundColor = .clear
        style.flexShrink = 1

        return RichLabelComponent(props: props, style: style)
    }()

    override init(props: ChatCardSummaryComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignContent = .stretch
        style.flexDirection = .row
        setSubComponents([checkboxComponent, textComponent])
    }

    override func willReceiveProps(_ old: ChatCardSummaryComponentProps, _ new: ChatCardSummaryComponentProps) -> Bool {
        guard let textInfo = new.textInfo else {
            return true
        }

        let textProps = textComponent.props
        textInfo.attachToRichLabel(textProps, with: new.linkHandler)
        textProps.preferMaxLayoutWidth = (new.preferMaxLayoutWidth ?? 370) - 16.auto() - 8
        textComponent.props = textProps

        let checkboxProps = checkboxComponent.props
        checkboxProps.checkState = new.checkboxInfo.checkState
        checkboxProps.enabledCheckAction = new.checkboxInfo.enabledCheckAction
        checkboxProps.disabledCheckAction = new.checkboxInfo.disabledCheckAction
        checkboxProps.isMilesone = new.checkboxInfo.isMilesone
        checkboxComponent.props = checkboxProps
        return true
    }

}
