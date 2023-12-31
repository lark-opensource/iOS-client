//
//  URLPreviewComponent.swift
//  Action
//
//  Created by 刘宏志 on 2019/4/8.
//

import UIKit
import Foundation
import LarkMessageBase
import AsyncComponent
import EEFlexiable
import LarkModel
import LarkSetting

public final class URLPreviewComponent<C: Context>: ASComponent<URLPreviewComponent.Props, EmptyState, TappedView, C> {
    public final class Props: ASComponentProps {
        public var title: String = ""
        public var iconURL: String = ""
        public var iconKey: String = ""
        public var content: NSAttributedString = NSAttributedString(string: "")
        public var coverImageSet: ImageSet?
        public var contentTapHandler: (() -> Void)?
        public var videoCoverTapHandler: ((UIImageView) -> Void)?
        public var lineColor: UIColor = UIColor.ud.lineDividerDefault
        public var titleColor: UIColor = UIColor.ud.textTitle
        public var contentColor: UIColor = UIColor.ud.textTitle
        public var contentMaxWidth: CGFloat = 0
        public var needSeperateLine: Bool = true
        public var contentNumberOfLines: Int = 6
        public var needVideoPreview: Bool = true
        public var hasPaddingLeft: Bool = false
    }

    private let containerLeft: CGFloat = 12.0

    private lazy var favicon: URLFaviconComponent<C> = {
        let props = URLFaviconComponent<C>.Props()
        let iconWH: CGFloat = 30.auto()
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: iconWH)
        style.height = CSSValue(cgfloat: iconWH)
        style.flexGrow = 0
        style.flexShrink = 0
        style.cornerRadius = 2.auto()
        return URLFaviconComponent<C>(props: props, style: style)
    }()

    private lazy var titleLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.body1
        props.textColor = self.props.titleColor
        props.textAlignment = .left
        props.lineBreakMode = .byTruncatingTail
        props.numberOfLines = 1
        let style = ASComponentStyle()
        style.marginLeft = 8
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    lazy var iconTitleContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        return ASLayoutComponent(style: style, context: context, [favicon, titleLabel])
    }()

    lazy var contentLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.attributedText = self.props.content
        props.numberOfLines = 6
        props.textAlignment = .left
        props.textColor = self.props.contentColor
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 8
        return UILabelComponent<C>(props: props, style: style)
    }()

    lazy var videoCover: URLVideoCoverImageViewComponent<C> = {
        let props = URLVideoCoverImageViewComponent<C>.Props()
        let style = ASComponentStyle()
        return URLVideoCoverImageViewComponent<C>(props: props, style: style)
    }()

    lazy var line: UIViewComponent<C> = separatorLineFactory()

    lazy var contentRightContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.alignItems = .flexStart
        return ASLayoutComponent(style: style, context: context, [iconTitleContainer, contentLabel, videoCover])
    }()

    lazy var contentContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.alignItems = .stretch
        style.marginTop = 8
        return ASLayoutComponent(style: style, context: context, [contentRightContainer])
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        style.alignItems = .stretch
        style.alignSelf = .stretch
        style.flexGrow = 1
        super.init(props: props, style: style, context: context)
        setSubComponents([line, contentContainer])
    }

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        titleLabel.props.text = new.title
        contentLabel.props.attributedText = new.content
        contentLabel.props.numberOfLines = new.contentNumberOfLines
        contentLabel.style.display = new.content.string.isEmpty ? .none : .flex
        line.style.display = new.needSeperateLine ? .flex : .none
        line.style.backgroundColor = new.lineColor
        titleLabel.props.textColor = new.titleColor
        contentLabel.props.textColor = new.contentColor
        style.maxWidth = CSSValue(cgfloat: new.contentMaxWidth)
        videoCover.props.preferMaxWidth = new.contentMaxWidth
        // 这里必须指定Title容器的maxWidth，否则Title超出
        // 怀疑是UILabel文字计算的问题
        iconTitleContainer.style.maxWidth = CSSValue(cgfloat: new.contentMaxWidth - (new.hasPaddingLeft ? containerLeft : 0))

        if new.hasPaddingLeft {
            self.style.paddingLeft = CSSValue(cgfloat: containerLeft)
        }

        if new.iconURL.isEmpty {
            favicon.props.iconURL = nil
            favicon.props.iconKey = nil
        } else {
            favicon.props.iconKey = new.iconKey
            favicon.props.iconURL = new.iconURL
        }
        // 展示视频封面图
        if let coverImageSet = new.coverImageSet, new.needVideoPreview {
            videoCover.style.marginTop = 8
            videoCover.style.display = .flex
            videoCover.props.coverImageSet = coverImageSet
        } else {
            videoCover.style.marginTop = 0
            videoCover.style.display = .none
            videoCover.props.coverImageSet = nil
        }
        videoCover.props.coverOnTapped = { [weak new] view in
            new?.videoCoverTapHandler?(view)
        }
        return true
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        if let contentTapHandler = self.props.contentTapHandler {
            view.initEvent(needLongPress: false)
            view.onTapped = { _ in
                contentTapHandler()
            }
        } else {
            view.deinitEvent()
            view.onTapped = nil
        }
    }

    // 分割线工厂
    private func separatorLineFactory() -> UIViewComponent<C> {
        let style = ASComponentStyle()
        style.alignSelf = .stretch
        style.height = CSSValue(cgfloat: 1)
        style.backgroundColor = self.props.lineColor
        style.flexGrow = 1
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }
}
