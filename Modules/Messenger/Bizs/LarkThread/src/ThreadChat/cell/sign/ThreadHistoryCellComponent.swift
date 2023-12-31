//
//  ThreadHistoryCellComponent.swift
//  LarkThread
//
//  Created by 李勇 on 2020/10/20.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import LarkMessageCore

final class ThreadHistoryCellComponent<C: SignCellContext>: ASComponent<ASComponentProps, EmptyState, UIView, C> {

    enum Cons {
        static var textFont: UIFont { UIFont.ud.caption0 }
        static var vMargin: CSSValue { 10 }
        static var cellHeight: CSSValue { CSSValue(float: Float(textFont.rowHeight) + 2 * vMargin.value) }
    }

    private lazy var rightLine: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.15)
        style.height = 1
        style.cornerRadius = 0.5
        style.marginLeft = 8
        style.marginRight = 0
        style.flexGrow = 1
        style.alignSelf = .center
        return UIViewComponent(props: .empty, style: style)
    }()

    private lazy var label: UILabelComponent<C> = {
        let labelProps = UILabelComponentProps()
        labelProps.text = BundleI18n.LarkThread.Lark_TopicChannel_PreviousTopics
        labelProps.font = Cons.textFont
        labelProps.textColor = UIColor.ud.N500
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        labelProps.lineBreakMode = .byWordWrapping
        labelProps.numberOfLines = 1

        let labelStyle = ASComponentStyle()
        labelStyle.marginLeft = 16
        labelStyle.alignSelf = .center
        labelStyle.backgroundColor = .clear
        return UILabelComponent<C>(props: labelProps, style: labelStyle)
    }()

    override init(props: ASComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        self.style.height = Cons.cellHeight
        self.style.paddingBottom = Cons.vMargin
        self.style.flexDirection = .row
        setSubComponents([
            label,
            rightLine
        ])
    }

    override func render() -> BaseVirtualNode {
        style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)
        return super.render()
    }
}
