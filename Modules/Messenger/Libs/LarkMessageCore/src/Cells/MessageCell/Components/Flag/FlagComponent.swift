//
//  FlagComponent.swift
//  LarkMessageCore
//
//  Created by bytedance on 2022/6/2.
//

import Foundation
import UIKit
import EEFlexiable
import AsyncComponent
import LarkMessageBase
import UniverseDesignIcon

public final class FlagComponent<C: ComponentContext>: ASComponent<FlagComponent.Props, EmptyState, UIView, C> {

    public final class Props: ASComponentProps {
        public var isFlag: Bool = false
        public var flagClickEvent: (() -> Void)?
    }

    public override init(props: FlagComponent.Props, style: ASComponentStyle, context: C? = nil) {
        style.cornerRadius = 0
        super.init(props: props, style: style, context: context)
        setSubComponents([flagIcon])
    }

    private lazy var flagIcon: TappedImageComponent<C> = {
        let props = TappedImageComponentProps()
        props.image = UDIcon.getIconByKey(.flagFilled, iconColor: UIColor.ud.colorfulRed, size: CGSize(width: 16, height: 16))
        props.iconSize = CGSize(width: 16, height: 16)
        props.hitTestEdgeInsets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        let style = ASComponentStyle()
        style.width = 16
        style.height = 16
        return TappedImageComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        flagIcon.props.onClicked = { [weak new] _ in
            if let block = new?.flagClickEvent {
                block()
            }
        }
        self.style.display = new.isFlag ? .flex : .none
        return true
    }
}
