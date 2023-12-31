//
//  VoteButtonComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/23.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import EEFlexiable

final public class VoteButtonComponentProps: ASComponentProps {
    public var height: CGFloat = 32.auto()
    public var text: String = ""
    public var enable: Bool = false
    public var onViewClicked: (() -> Void)?
}

public final class VoteButtonComponent<C: ComponentContext>: ASComponent<VoteButtonComponentProps, EmptyState, TappedView, C> {
    public override init(props: VoteButtonComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        style.justifyContent = .center
        style.alignItems = .center
        style.border = Border(
            BorderEdge(width: 1,
                       color: UIColor.ud.lineBorderComponent,
                       style: .solid))
        super.init(props: props, style: style, context: context)
        updateUI(props: props)
        setSubComponents([title])
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

    // Title
    private lazy var title: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.body2
        props.numberOfLines = 1

        let style = ASComponentStyle()
        style.alignSelf = .stretch
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: VoteButtonComponentProps,
                                          _ new: VoteButtonComponentProps) -> Bool {
        updateUI(props: new)
        return true
    }

    private func updateUI(props: VoteButtonComponentProps) {
        style.height = CSSValue(cgfloat: props.height)
        style.cornerRadius = 6

        title.props.text = props.text
        title.props.textColor = props.enable ? UIColor.ud.textTitle : UIColor.ud.textDisable
    }
}
