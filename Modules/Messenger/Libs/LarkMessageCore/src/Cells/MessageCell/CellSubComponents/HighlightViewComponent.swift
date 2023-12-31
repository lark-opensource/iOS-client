//
//  HighlightViewComponent.swift
//  LarkChat
//
//  Created by Ping on 2023/2/21.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

public final class HighlightViewComponentProps<C: Context>: ASComponentProps {
    // 高亮时背景色
    public var highlightBgColor: UIColor = .clear
    public var highlightBlurColor: UIColor = .clear
    public var showHighlightBlur: Bool = false
}

public final class HighlightViewComponent<C: Context>: ASComponent<HighlightViewComponentProps<C>, EmptyState, UIView, C> {
    // highlight blur view
    private lazy var highlightBlurViewComponent: BlurViewComponent<C> = {
        let props = BlurViewProps()
        props.blurRadius = 25
        let style = ASComponentStyle()
        style.position = .absolute
        style.top = 0
        style.bottom = 0
        style.width = 100%
        return BlurViewComponent<C>(props: props, style: style)
    }()

    public override init(props: HighlightViewComponentProps<C>, style: ASComponentStyle, context: C? = nil) {
        props.key = MessageCommonCell.highlightViewKey
        style.position = .absolute
        style.backgroundColor = UIColor.clear
        style.top = 0
        style.bottom = 0
        style.width = 100%
        super.init(props: props, style: style, context: context)
        setSubComponents([highlightBlurViewComponent])
    }

    public override func willReceiveProps(_ old: HighlightViewComponentProps<C>, _ new: HighlightViewComponentProps<C>) -> Bool {
        self.style.backgroundColor = new.highlightBgColor
        highlightBlurViewComponent.props.fillColor = new.highlightBlurColor
        highlightBlurViewComponent.style.display = new.showHighlightBlur ? .flex : .none
        return true
    }
}
