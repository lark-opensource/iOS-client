//
//  ProgressComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/23.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import EEFlexiable

final public class ProgressComponentProps: ASComponentProps {
    public var backgroundColor: UIColor = UIColor.ud.N300
    public var progressColor: UIColor = UIColor.ud.colorfulBlue
    public var height: CGFloat = 3
    public var value: CGFloat = 0
}

public final class ProgressComponent<C: ComponentContext>: ASComponent<ProgressComponentProps, EmptyState, UIView, C> {
    public override init(props: ProgressComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .row
        style.alignItems = .stretch

        super.init(props: props, style: style, context: context)
        updateUI(props: props)
        setSubComponents([progress])
    }

    private lazy var progress: UIViewComponent<C> = {
        let props = ASComponentProps()

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UIViewComponent(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: ProgressComponentProps,
                                          _ new: ProgressComponentProps) -> Bool {
        updateUI(props: new)
        return true
    }

    private func updateUI(props: ProgressComponentProps) {
        style.backgroundColor = props.backgroundColor
        style.height = CSSValue(cgfloat: props.height)
        style.cornerRadius = props.height / 2.0

        progress.style.backgroundColor = props.progressColor
        progress.style.cornerRadius = props.height / 2.0
        progress.style.width = (props.value * 100)%
    }
}
