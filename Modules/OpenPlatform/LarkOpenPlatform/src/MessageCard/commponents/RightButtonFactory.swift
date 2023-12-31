//
//  TranslateFeedBackButton.swift
//  LarkOpenPlatform
//
//  Created by zhangjie on 2022/7/12.
//

import Foundation
import UIKit
import LarkMessageCore
import LarkMessageBase
import AsyncComponent
import UniverseDesignIcon

class RightButtonFactory {

    static func create<C>(name:String, action: (() -> Void)?, style: ASComponentStyle) -> RightButtonComponent<C> {
        let props = RightButtonComponentProps()
        props.icon = UDIcon.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        props.iconSize = CGSize(width: 10.auto(), height: 10.auto())
        props.iconAndLabelSpacing = 2
        props.text = name
        props.font = UIFont.ud.caption1
        props.textColor = UIColor.ud.textCaption
        props.onViewClicked = { _ in
            action?()
        }
        style.backgroundColor = .clear
        style.alignContent = .flexStart
        style.alignSelf = .flexStart
        return RightButtonComponent(props: props, style: style)
    }

}
