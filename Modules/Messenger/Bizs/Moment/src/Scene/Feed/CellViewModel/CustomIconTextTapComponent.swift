//
//  PostStatusComponent.swift
//  Moment
//
//  Created by zhaochen.09 on 2019/6/3.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel
import LarkMessageBase
import RichLabel
import LarkMessageCore

final public class CustomIconTextTapComponentProps: ASComponentProps {
    public var iconBlock: (() -> UIImage)?
    public var _attributedText = Atomic<NSAttributedString>()
    public var attributedText: NSAttributedString? {
        get { return _attributedText.wrappedValue }
        set { _attributedText.wrappedValue = newValue }
    }
    public var iconSize: CGSize = CGSize(width: 12, height: 12)
    public var iconAndLabelSpacing: CGFloat = 2
    public var onViewClicked: (() -> Void)?
    public var iconNeedRotate: Bool = false
    public var contentPaddingLeft: CGFloat = 0
    public var contentPaddingRight: CGFloat = 0
}

public final class CustomIconTextTapComponent<C: ComponentContext>: ASComponent<CustomIconTextTapComponentProps, EmptyState, TappedView, C> {

    private lazy var contentContainer: ASLayoutComponent<C> = {
        let style = ASComponentStyle()
        style.alignItems = .center
        return ASLayoutComponent<C>(style: style, [icon, label])
    }()

    private lazy var icon: UIRotateImageViewComponent<C> = {
        let style = ASComponentStyle()
        return UIRotateImageViewComponent<C>(props: UIRotateImageViewComponentProps(), style: style)
    }()

    private lazy var label: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.textAlignment = .center
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent(props: props, style: style)
    }()

    public override init(props: CustomIconTextTapComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .center
        setSubComponents([contentContainer])
    }

    public override func create(_ rect: CGRect) -> TappedView {
        let tappedView = TappedView(frame: rect)
        tappedView.initEvent(needLongPress: false)
        return tappedView
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.onTapped = { _ in
            self.props.onViewClicked?()
        }
    }

    private func updateProps(props: CustomIconTextTapComponentProps) {
        icon.props.imageBlock = props.iconBlock
        icon.style.display = props.iconBlock == nil ? .none : .flex
        icon.style.marginRight = CSSValue(cgfloat: props.iconAndLabelSpacing)
        icon.props.needRotate = props.iconNeedRotate
        icon.style.width = CSSValue(cgfloat: props.iconSize.width)
        icon.style.height = CSSValue(cgfloat: props.iconSize.height)
        label.props.attributedText = props.attributedText
        label.props.numberOfLines = 1
        contentContainer.style.paddingLeft = CSSValue(cgfloat: props.contentPaddingLeft)
        contentContainer.style.paddingRight = CSSValue(cgfloat: props.contentPaddingRight)
    }

    public override func willReceiveProps(_ old: CustomIconTextTapComponentProps,
                                          _ new: CustomIconTextTapComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }
}

public final class UIRotateImageViewComponentProps: ASComponentProps {
    public var needRotate: Bool = false
    public var imageBlock: (() -> UIImage)?
}

public final class UIRotateImageViewComponent<C: AsyncComponent.Context>: ASComponent<
    UIRotateImageViewComponentProps,
    EmptyState,
    UIImageView,
    C
> {
    public override func update(view: UIImageView) {
        super.update(view: view)
        if let imageBlock = props.imageBlock {
            view.image = imageBlock()
        }
        if props.needRotate {
            view.lu.addRotateAnimation()
        } else {
            view.lu.removeRotateAnimation()
        }
    }
}
