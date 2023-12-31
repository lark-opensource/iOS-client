//
//  CalendarTagComponent.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/23.
//

import Foundation
import CalendarFoundation
import AsyncComponent
import EEFlexiable
import LarkTag
import UIKit

final public class CalendarTagComponentProps: ASComponentProps {
    public var tagString: String?
    public var tagStyle: LarkTag.Style?
    public var textColor: UIColor?
    public var backgroundColor: UIColor?
    public var height: CGFloat = 16.0
}

public final class CalendarTagComponent<C: AsyncComponent.Context>: ASComponent<CalendarTagComponentProps, EmptyState, UIView, C> {

    private var tagLabel: UILabelComponent<C>?
    public override init(props: CalendarTagComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setUpStyle()
        let tagStyle = props.tagStyle ?? .init(
            textColor: props.textColor ?? .white,
            backColor: props.backgroundColor ?? .gray
        )
        let tag = Tag(title: props.tagString,
                      image: nil,
                      style: tagStyle,
                      type: .customTitleTag)
        let label = makeLabel(tag)
        self.tagLabel = label

        setSubComponents([label])
    }

    private func makeLabel(_ tag: Tag) -> UILabelComponent<C> {
        let props = UILabelComponentProps()
        props.text = tag.title
        props.font = UIFont.ud.caption0
        props.textColor = tag.style.textColor
        props.textAlignment = .center

        let style = ASComponentStyle()
        style.paddingLeft = 4
        style.paddingRight = 4
        style.paddingTop = 2
        style.paddingBottom = 2
        style.cornerRadius = 4
        style.backgroundColor = tag.style.backColor

        return UILabelComponent(props: props, style: style)
    }

    public override func update(view: UIView) {
        if let color = props.textColor {
            self.tagLabel?.props.textColor = color
        }

        if let color = props.backgroundColor {
            self.tagLabel?.style.backgroundColor = color
        }

        if let tagString = props.tagString {
            self.tagLabel?.props.text = tagString
        }
    }

    public override func willReceiveProps(_ old: CalendarTagComponentProps,
                                          _ new: CalendarTagComponentProps) -> Bool {
        self.tagLabel?.props.text = new.tagString
        return true
    }

    func setUpStyle() {
        style.alignItems = .stretch
        style.flexShrink = 0
        style.flexGrow = 0
        style.height = CSSValue(cgfloat: props.height)
    }
}
