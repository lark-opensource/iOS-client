//
//  IconViewComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/3.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel
import LarkMessageBase
import RichLabel

final public class IconViewComponentProps: SafeASComponentProps {
    public var icon: UIImage?

    private var _attributedText: NSAttributedString?
    public var attributedText: NSAttributedString? {
        get {
            safeRead {
                self._attributedText
            }
        }
        set {
            safeWrite {
                self._attributedText = newValue
            }
        }
    }
    public var tapableRangeList: [NSRange] = []
    public var textLinkList: [LKTextLink] = []
    public weak var delegate: LKLabelDelegate?
    public var iconSize: CGSize = CGSize(width: 12, height: 12)
    public var iconMarginBottom: CGFloat?
    public var iconAndLabelSpacing: CGFloat = 3
    public var height: CGFloat = 15
    public var numberOfLines: Int = 1
    /// icon按钮居中展示
    public var alignIconCenter: Bool = false

    private var _onViewClicked: (() -> Void)?
    public var onViewClicked: (() -> Void)? {
        get {
            safeRead {
                self._onViewClicked
            }
        }
        set {
            safeWrite {
                self._onViewClicked = newValue
            }
        }
    }
}

public final class IconViewComponent<C: ComponentContext>: ASComponent<IconViewComponentProps, EmptyState, TappedView, C> {
    public override init(props: IconViewComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        super.init(props: props, style: style, context: context)

        setSubComponents([icon, label])
        updateProps(props: props)
    }

    public override func create(_ rect: CGRect) -> TappedView {
        return TappedView(frame: rect)
    }

    public override func update(view: TappedView) {
        super.update(view: view)

        if let tapped = self.props.onViewClicked {
            view.initEvent(needLongPress: false)
            view.onTapped = { _ in
                tapped()
            }
        } else {
            view.deinitEvent()
        }
    }

    private func updateProps(props: IconViewComponentProps) {
        label.props.attributedText = props.attributedText
        label.props.numberOfLines = props.numberOfLines
        label.props.tapableRangeList = props.tapableRangeList
        label.props.delegate = props.delegate
        label.props.textLinkList = props.textLinkList

        icon.props.setImage = { $0.set(image: props.icon) }
        icon.style.width = CSSValue(cgfloat: props.iconSize.width)
        icon.style.height = CSSValue(cgfloat: props.iconSize.height)
        /// 如果需要所有的子View居中，忽略边距
        if props.alignIconCenter {
            icon.style.alignSelf = .center
            icon.style.marginBottom = 0
            icon.style.marginTop = 0
        } else {
            if let iconMarginBottom = props.iconMarginBottom {
                icon.style.alignSelf = .flexEnd
                icon.style.marginBottom = CSSValue(cgfloat: iconMarginBottom)
            } else {
                icon.style.alignSelf = .flexStart
                icon.style.marginTop = CSSValue(cgfloat: 2)
            }
        }
    }

    private lazy var icon: UIImageViewComponent<C> = {
        let style = ASComponentStyle()
        style.alignSelf = .flexStart
        return UIImageViewComponent<C>(props: UIImageViewComponentProps(), style: style)
    }()

    private lazy var label: RichLabelComponent<C> = {
        let props = RichLabelProps()

        let style = ASComponentStyle()
        style.alignSelf = .center
        style.marginLeft = CSSValue(cgfloat: self.props.iconAndLabelSpacing)
        style.backgroundColor = .clear
        return RichLabelComponent(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: IconViewComponentProps,
                                          _ new: IconViewComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }
}
