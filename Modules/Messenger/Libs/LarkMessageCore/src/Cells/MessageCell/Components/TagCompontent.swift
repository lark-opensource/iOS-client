//
//  TagComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/5/11.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkTag

final public class TagComponentProps: ASComponentProps {
    public var tags: [Tag] = []
    public var autoSort: Bool = true
    public var space: CGFloat = 6.0
    public var maxTagCount: Int = 2
    /// Only for image type.
    public var height: CGFloat = 14.0
    /// Only for text type.
    public var font: UIFont = UIFont.ud.caption2
    public var labelPaddingLeft: CSSValue = 4
    public var labelPaddingRight: CSSValue = 4
    public var labelCornerRadius: CGFloat = 2
    public var labelHeight: CSSValue = UIFont.ud.caption2.figmaHeight.css
    /// Maximum height of all tags.
    public var maxHeight: CGFloat {
        return max(height, font.pointSize + 4)
    }
}

public final class TagComponent<C: AsyncComponent.Context>: ASComponent<TagComponentProps, EmptyState, UIView, C> {

    public override init(props: TagComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.alignItems = .stretch
        style.flexShrink = 0
        style.flexGrow = 0

        super.init(props: props, style: style, context: context)
        setUpProps(props: props)
    }

    private func factory(for tag: Tag, isLast: Bool) -> ComponentWithContext<C> {
        if TagType.titleTypes.contains(tag.type) {
            return makeLabel(tag, isLast: isLast)
        } else {
            return makeIcon(tag, isLast: isLast)
        }
    }

    private func makeLabel(_ tag: Tag, isLast: Bool) -> UILabelComponent<C> {
        let props = UILabelComponentProps()
        props.text = tag.title
        props.textColor = tag.style.textColor
        props.textAlignment = .center
        props.font = self.props.font
        let style = ASComponentStyle()
        style.paddingLeft = self.props.labelPaddingLeft
        style.paddingRight = self.props.labelPaddingRight
        style.cornerRadius = self.props.labelCornerRadius
        style.height = self.props.labelHeight
        style.backgroundColor = tag.style.backColor
        if !isLast {
            style.marginRight = CSSValue(cgfloat: self.props.space)
        }

        return UILabelComponent(props: props, style: style)
    }

    private func makeIcon(_ tag: Tag, isLast: Bool) -> UIImageViewComponent<C> {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(image: tag.image) }

        let style = ASComponentStyle()
        style.height = CSSValue(cgfloat: self.props.maxHeight)
        style.aspectRatio = 1
        if !isLast {
            style.marginRight = CSSValue(cgfloat: self.props.space)
        }

        return UIImageViewComponent<C>(props: props, style: style)
    }

    public override func willReceiveProps(_ old: TagComponentProps,
                                          _ new: TagComponentProps) -> Bool {
        setUpProps(props: new)
        return true
    }
}

fileprivate extension TagComponent {
    func setUpProps(props: TagComponentProps) {
        style.display = props.tags.isEmpty ? .none : .flex
        guard !props.tags.isEmpty else { return }

//        style.height = CSSValue(cgfloat: props.height)
        var sorted = (props.autoSort ? props.tags.sorted(by: { $0.type < $1.type }) : props.tags)

        if sorted.count > props.maxTagCount {
            sorted = Array(sorted.prefix(props.maxTagCount))
        }

        var subComponents: [ComponentWithContext<C>] = []
        for (index, tag) in sorted.enumerated() {
            guard index < props.maxTagCount else { break }
            subComponents.append(factory(for: tag, isLast: index == sorted.count - 1))
        }
        setSubComponents(subComponents)
    }
}
