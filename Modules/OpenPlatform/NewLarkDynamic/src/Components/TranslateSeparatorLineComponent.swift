//
//  TranslateSeparatorLineComponent.swift
//  NewLarkDynamic
//
//  Created by MJXin on 2022/7/7.
//

import Foundation
import EEFlexiable
import AsyncComponent
import LKCommonsLogging

final public class TranslateSplitLineComponent<C: LDContext>: ASComponent<TranslateSplitLineComponent.Props, EmptyState, UIView, C> {
    private let lineMarginLeft = CSSValue(cgfloat: 10)
    private let lineHeight = CSSValue(cgfloat: 1)
    private let lineColor = UIColor.ud.N500
    private let labelFont = UIFont.ud.caption1
    private let labelColor = UIColor.ud.N500
    
    public final class Props: ASComponentProps {
        var text: String?
        public init(text: String?) { self.text = text }
    }
    private lazy var lineComponent: UIViewComponent<C> = {
        let lineStyle = ASComponentStyle()
        lineStyle.marginLeft = lineMarginLeft
        lineStyle.flexGrow = 1
        lineStyle.height = lineHeight
        lineStyle.backgroundColor = UIColor.ud.lineDividerDefault
        return UIViewComponent<C>(props: .empty, style: lineStyle)
    }()
    
    private lazy var labelComponent: UILabelComponent<C> = {
        let labelProps = UILabelComponentProps()
        labelProps.text = props.text
        labelProps.font = labelFont
        labelProps.textColor = labelColor
        let labelStyle = ASComponentStyle()
        labelStyle.backgroundColor = UIColor.clear
        return UILabelComponent<C>(props: labelProps, style: labelStyle)
    }()
    
    
    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        style.alignItems = .center
        super.init(props: props, style: style, context: context)
        labelComponent.props.text = props.text
        setSubComponents([labelComponent, lineComponent])
    }
    
    public override func willReceiveProps(_ old: Props, _ new: Props) -> Bool {
        labelComponent.props.text = new.text
        return true
    }
    
    deinit {
    }
}
