//
//  ThreadDetailSystemCellComponent.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/21.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent
import RichLabel
import LarkMessageBase

final class ThreadDetailSystemCellComponent: ASComponent<ThreadDetailSystemCellComponent.Props, EmptyState, UIView, ThreadDetailContext> {
    final class Props: ASComponentProps {
        var labelAttrText = NSAttributedString(string: "")
        var textLinks: [LKTextLink] = []
    }

    override func update(view: UIView) {
        super.update(view: view)
        // 多选态消息整个消息屏蔽点击事件，只响应cell层的显示时间和选中事件
        view.isUserInteractionEnabled = context?.isPreview != true
    }

    override func render() -> BaseVirtualNode {
        style.backgroundColor = UIColor.clear
        style.alignContent = .stretch
        style.width = CSSValue(cgfloat: context?.maxCellWidth ?? UIScreen.main.bounds.width)

        let labelProps = RichLabelProps()
        labelProps.attributedText = props.labelAttrText
        labelProps.backgroundColor = UIColor.clear
        labelProps.textLinkList = props.textLinks
        labelProps.numberOfLines = 0
        labelProps.linkAttributes = [NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.textLinkNormal]

        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        labelStyle.marginLeft = 58
        labelStyle.marginRight = 16
        labelStyle.marginTop = 12
        labelStyle.marginBottom = 12
        labelStyle.flexGrow = 1
        let label = RichLabelComponent<ThreadDetailContext>(props: labelProps, style: labelStyle)
        setSubComponents([label, createSeperateLine()])
        return super.render()
    }

    private func createSeperateLine() -> ComponentWithContext<ThreadDetailContext> {
        let style = ASComponentStyle()
        style.position = .absolute
        style.left = 52
        style.bottom = 0
        style.width = 100%
        style.height = CSSValue(cgfloat: 1)
        style.backgroundColor = UIColor.ud.N50
        return UIViewComponent<ThreadDetailContext>(props: .empty, style: style)
    }
}
