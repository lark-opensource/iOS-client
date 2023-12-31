//
//  TopComponent.swift
//  LarkChat
//
//  Created by Ping on 2023/2/20.
//

import UIKit
import Foundation
import AsyncComponent

public final class TopComponent<C: Context>: ASLayoutComponent<C> {
    /// ephemeral
    lazy var topIcon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(image: Resources.ephemeral_card_mark) }
        let style = ASComponentStyle()
        style.display = .flex
        style.width = UIFont.ud.caption1.rowHeight.css
        style.height = style.width
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    /// 顶部标记
    lazy var topLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.font = UIFont.ud.caption1
        props.textColor = UIColor.ud.N900
        props.text = BundleI18n.LarkMessageCore.Lark_Legacy_EphemeralVisibility

        let style = ASComponentStyle()
        style.flexShrink = 0
        style.backgroundColor = .clear
        style.marginRight = 4
        style.marginLeft = 3
        return UILabelComponent<C>(props: props, style: style)
    }()

    public init(
        key: String = "",
        style: ASComponentStyle,
        context: C? = nil
    ) {
        style.flexDirection = .row
        style.alignItems = .center
        style.marginBottom = 4
        style.height = 18
        super.init(key: key, style: style, context: context, [])
        setSubComponents([topIcon, topLabel])
    }
}
