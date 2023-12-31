//
//  DLPFeedBackComponent.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/4/18.
//
import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import RichLabel
import LarkMessageBase

public final class DLPFeedBackComponentProps: ASComponentProps {
    var iconSize: CGSize = CGSize(width: 12, height: 12)
    var attributedText: NSAttributedString?
    var linkList: [LKTextLink] = []
}

public final class DLPFeedBackComponent<C: ComponentContext>: ASComponent<DLPFeedBackComponentProps, EmptyState, UIView, C> {

    private lazy var icon: UIImageViewComponent<C> = {
        let style = ASComponentStyle()
        style.marginRight = 4
        style.marginTop = 2
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(image: Resources.dlp_tip) }
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    private lazy var label: RichLabelComponent<C> = {
        let props = RichLabelProps()
        props.numberOfLines = 0
        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = .clear
        return RichLabelComponent(props: props, style: labelStyle)
    }()

    public override init(props: DLPFeedBackComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .flexStart
        style.marginTop = 4
        setSubComponents([icon, label])
        updateProps(props: props)
    }

    public override func willReceiveProps(_ old: DLPFeedBackComponentProps,
                                          _ new: DLPFeedBackComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }

    private func updateProps(props: DLPFeedBackComponentProps) {
        icon.style.width = CSSValue(cgfloat: props.iconSize.width)
        icon.style.height = CSSValue(cgfloat: props.iconSize.height)
        label.props.attributedText = props.attributedText
        label.props.textLinkList = props.linkList
    }
}
