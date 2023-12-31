//
//  RightButtonComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/7/1.
//

import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel
import LarkMessageBase
import RichLabel
import LarkInteraction
import UIKit

final public class RightButtonComponentProps: ASComponentProps {
    public var icon: UIImage?
    public var text: String?
    public var font: UIFont = UIFont.ud.body2
    public var textColor: UIColor = UIColor.ud.B700
    public var iconSize: CGSize = .square(UIFont.ud.body2.pointSize)
    public var iconAndLabelSpacing: CGFloat = 2
    public var height: CGFloat = UIFont.ud.body2.rowHeight
    public var onViewClicked: ((TappedView) -> Void)?
}

public final class RightButtonComponent<C: ComponentContext>: ASComponent<RightButtonComponentProps, EmptyState, TappedView, C> {

    public private(set) var tappedView: TappedView?

    public override init(props: RightButtonComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.alignItems = .center
        style.backgroundColor = .clear
        super.init(props: props, style: style, context: context)

        setSubComponents([label, icon])
        updateProps(props: props)
    }

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        view.hitTestEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        self.tappedView = view
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(preferredTintMode: .overlay, prefersShadow: true, prefersScaledContent: true))
            )
            view.addLKInteraction(pointer)
        }
        return view
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        if let tapped = self.props.onViewClicked {
            view.initEvent(needLongPress: false)
            view.onTapped = { view in
                tapped(view)
            }
        } else {
            view.deinitEvent()
        }
    }

    public func currentTappedView() -> TappedView? {
        return self.tappedView
    }

    private func updateProps(props: RightButtonComponentProps) {
        icon.props.setImage = { $0.set(image: props.icon) }
        icon.style.width = CSSValue(cgfloat: props.iconSize.width)
        icon.style.height = CSSValue(cgfloat: props.iconSize.height)

        label.props.text = props.text
        label.props.textColor = props.textColor
        label.props.font = props.font
        label.style.marginRight = CSSValue(cgfloat: props.iconAndLabelSpacing)

        style.height = CSSValue(cgfloat: props.height)
    }

    private let icon = UIImageViewComponent<C>(props: UIImageViewComponentProps(), style: ASComponentStyle())

    private lazy var label: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.textAlignment = .right

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: RightButtonComponentProps,
                                          _ new: RightButtonComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }
}
