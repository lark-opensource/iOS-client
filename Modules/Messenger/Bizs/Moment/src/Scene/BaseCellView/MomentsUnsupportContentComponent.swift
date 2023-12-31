//
//  MomentsUnsupportContentComponent.swift
//  Moment
//
//  Created by liluobin on 2021/1/28.
//

import Foundation
import UIKit
import EEFlexiable
import AsyncComponent

public final class MomentsUnsupportContentComponent<C: BaseMomentContext>: ASComponent<MomentsUnsupportContentComponent.Props, EmptyState, UIView, C> {

    public final class Props: ASComponentProps {
        var tipText: String = ""
        var marginLeft: CGFloat = 0
    }

    private lazy var label: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.systemFont(ofSize: 14)
        props.textColor = UIColor.ud.textPlaceholder
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return UILabelComponent<C>(props: props, style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .center
        label.props.text = props.tipText
        setSubComponents([label])
    }

    public override func willReceiveProps(_ old: MomentsUnsupportContentComponent.Props,
                                          _ new: MomentsUnsupportContentComponent.Props) -> Bool {
        label.props.text = new.tipText
        return true
    }

}
