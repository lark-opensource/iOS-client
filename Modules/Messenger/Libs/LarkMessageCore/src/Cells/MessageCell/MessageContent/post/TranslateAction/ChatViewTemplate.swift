//
//  ChatViewTemplate.swift
//  LarkMessageCore
//
//  Created by chenziyue on 2022/1/11.
//

import Foundation
import UIKit
import LarkMessageCore
import LarkMessageBase
import AsyncComponent
import UniverseDesignIcon

final public class ChatViewTemplate<C: ComponentContext>: NSObject {

    public static func createTranslateFeedbackButton(action: (() -> Void)?, style: ASComponentStyle) -> RightButtonComponent<C> {
        let props = RightButtonComponentProps()
        props.icon = UDIcon.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        props.iconSize = CGSize(width: 12.auto(), height: 12.auto())
        props.iconAndLabelSpacing = 2
        props.text = BundleI18n.LarkMessageCore.Lark_Chat_TranslationFeedbackRateButton
        props.font = UIFont.ud.caption1
        props.textColor = UIColor.ud.textCaption
        props.onViewClicked = { _ in
            action?()
        }
        return RightButtonComponent(props: props, style: style)
    }
    public static func createTranslateMoreActionButton(action: ((UIView) -> Void)?, style: ASComponentStyle) -> RightButtonComponent<C> {
        let props = RightButtonComponentProps()
        props.icon = UDIcon.moreOutlined.ud.withTintColor(UIColor.ud.iconN2)
        props.iconSize = CGSize(width: 16.auto(), height: 16.auto())
        props.iconAndLabelSpacing = 0
        props.onViewClicked = { view in
            action?(view)
        }
        return RightButtonComponent(props: props, style: style)
    }

}
