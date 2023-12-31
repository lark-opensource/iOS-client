//
//  TappedImageComponent.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/10/9.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final public class TappedImageComponentProps: ASComponentProps {
    public var image: UIImage?
    public var iconSize: CGSize = CGSize(width: 0, height: 0)
    public var onClicked: ((UIView) -> Void)?
    public var onLongPressed: ((UIView) -> Void)?
    public var hitTestEdgeInsets: UIEdgeInsets = .zero
}

public final class TappedImageComponent<C: ComponentContext>: ASComponent<TappedImageComponentProps, EmptyState, TappedView, C> {
    private let icon = UIImageViewComponent<C>(props: UIImageViewComponentProps(), style: ASComponentStyle())
    public override init(props: TappedImageComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setSubComponents([icon])
        updateProps(props: props)
    }

    public override func create(_ rect: CGRect) -> TappedView {
        return TappedView(frame: rect)
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.hitTestEdgeInsets = self.props.hitTestEdgeInsets
        var hasGestureHandler: Bool = false
        if let tapped = self.props.onClicked {
            hasGestureHandler = true
            view.onTapped = { view in
                tapped(view)
            }
        }
        if let longPressed = self.props.onLongPressed {
            hasGestureHandler = true
            view.onLongPressed = { view in
                longPressed(view)
            }
        }
        if hasGestureHandler {
            view.initEvent(needLongPress: self.props.onLongPressed != nil)
        } else {
            view.deinitEvent()
        }
    }

    public override func willReceiveProps(_ old: TappedImageComponentProps,
                                          _ new: TappedImageComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }

    private func updateProps(props: TappedImageComponentProps) {
        icon.props.setImage = { $0.set(image: props.image) }
        icon.style.width = CSSValue(cgfloat: props.iconSize.width)
        icon.style.height = CSSValue(cgfloat: props.iconSize.height)
    }
}
