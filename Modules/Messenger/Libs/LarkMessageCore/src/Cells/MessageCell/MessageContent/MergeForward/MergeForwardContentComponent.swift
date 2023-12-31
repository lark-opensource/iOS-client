//
//  MergeForwardContentComponent.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/18.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkZoomable

public protocol MergeForwardContentComponentContext: ComponentContext { }

final class MergeForwardContentComponent<C: Context>: ASComponent<MergeForwardContentComponent.Props, EmptyState, MergeForwardContentView, C> {
    final class Props: ASComponentProps {
        public var titleLines: Int = 2
        public var contentLabelLines: Int = 4
        public var tapAction: (() -> Void)?
        public var title: String = ""
        public var isDefaultStyle: Bool = true
        public var content: NSAttributedString = NSAttributedString(string: "")
        public var titleFont: UIFont = UIFont.ud.title4
        public var titleTextColor: UIColor = UIColor.ud.textTitle
        public var contentFont: UIFont = UIFont.ud.body2
        public var contentMaxWidth: CGFloat = 0
    }

    lazy var lineComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: 2 * Zoom.currentZoom.scale)
        style.height = self.props.titleFont.pointSize.css
        style.backgroundColor = UIColor.ud.colorfulYellow
        return UIViewComponent(props: .empty, style: style)
    }()

    lazy var titleComponent: UILabelComponent<C> = {
        let style = ASComponentStyle()
        style.marginLeft = 5
        style.backgroundColor = UIColor.clear
        let props = UILabelComponentProps()
        props.font = self.props.titleFont
        props.textColor = self.props.titleTextColor
        props.textAlignment = .left
        props.numberOfLines = self.props.titleLines
        return UILabelComponent<C>(props: props, style: style)
    }()

    lazy var topContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .center
        style.height = self.props.titleFont.rowHeight.css
        return ASLayoutComponent(style: style, context: context, [lineComponent, titleComponent])
    }()

    lazy var contentComponent: RichLabelComponent<C> = {
        let style = ASComponentStyle()
        style.marginTop = 10
        style.backgroundColor = UIColor.clear
        style.maxWidth = CSSValue(cgfloat: self.props.contentMaxWidth)
        let props = RichLabelProps()
        props.font = self.props.contentFont
        props.numberOfLines = self.props.contentLabelLines
        props.lineSpacing = 2
        props.outOfRangeText = NSAttributedString(string: "...", attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption])
        return RichLabelComponent(props: props, style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.flexDirection = .column
        style.alignItems = .stretch
        setSubComponents([topContainer, contentComponent])
    }

    override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        titleComponent.props.text = new.title
        titleComponent.props.textColor = self.props.titleTextColor
        contentComponent.props.attributedText = new.content
        contentComponent.style.maxWidth = CSSValue(cgfloat: self.props.contentMaxWidth)
        return true
    }

    public override func update(view: MergeForwardContentView) {
        super.update(view: view)
        view.tapContent = props.tapAction
    }
}
