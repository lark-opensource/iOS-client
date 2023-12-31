//
//  DocsPreviewLeftInfoViewComponent.swift
//  LarkMessageCore
//
//  Created by LiXiaolin on 2019/11/27.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkModel
import LarkMessageBase
import RichLabel
import UniverseDesignColor

final public class DocsPreviewLeftInfoViewComponentProps: ASComponentProps {
    public var icon: UIImage?
    public var text: String?
    public var textColor: UIColor = UDColor.N900
    public var font: UIFont = UIFont.ud.body2
    public var iconSize: CGSize = .square(UIFont.ud.body2.pointSize)
    public var iconAndLabelSpacing: CGFloat = 4
    public var height: CGFloat = UIFont.ud.body2.rowHeight
    public var width: CGFloat = 0
    weak var delegate: LKLabelDelegate?
    public var linkRange: NSRange?
    public var lineSpacing: CGFloat = 0
    public var onLabelClicked: (() -> Void) = {}
}

public final class DocsPreviewLeftInfoViewComponent<C: ComponentContext>: ASComponent<DocsPreviewLeftInfoViewComponentProps, EmptyState, TappedView, C> {
    public override init(props: DocsPreviewLeftInfoViewComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.alignItems = .center
        super.init(props: props, style: style, context: context)

        setSubComponents([icon, richLabel])
        updateProps(props: props)
    }

    public override func create(_ rect: CGRect) -> TappedView {
        return TappedView(frame: rect)
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.initEvent(needLongPress: false, cancelsTouchesInView: false)
        view.onTapped = nil
    }

    private func updateProps(props: DocsPreviewLeftInfoViewComponentProps) {
        icon.props.setImage = { $0.set(image: props.icon) }
        icon.style.minWidth = CSSValue(cgfloat: props.iconSize.width)
        icon.style.minHeight = CSSValue(cgfloat: props.iconSize.height)

        icon.style.maxWidth = CSSValue(cgfloat: props.iconSize.width)
        icon.style.maxHeight = CSSValue(cgfloat: props.iconSize.height)

        let attrContent = NSAttributedString(string: props.text ?? "")
        let mutableStr = NSMutableAttributedString(attributedString: attrContent)
        mutableStr.addAttribute(NSAttributedString.Key.font, value: props.font, range: NSRange(location: 0, length: mutableStr.string.count))
        mutableStr.addAttribute(NSAttributedString.Key.foregroundColor, value: props.textColor, range: NSRange(location: 0, length: mutableStr.string.count))

        richLabel.props.attributedText = mutableStr
        richLabel.style.marginLeft = CSSValue(cgfloat: props.iconAndLabelSpacing)
        richLabel.props.numberOfLines = 0

        if props.lineSpacing > 0 {
            richLabel.props.lineSpacing = props.lineSpacing - props.font.pointSize
        }

        icon.style.alignSelf = .flexStart
        richLabel.style.alignSelf = .flexStart

        if let linkRange = props.linkRange,
           linkRange.location < mutableStr.string.count,
           (linkRange.location + linkRange.length) <= mutableStr.string.count {
            mutableStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UDColor.primaryContentDefault, range: linkRange)
            richLabel.props.tapableRangeList = [linkRange]
            richLabel.props.delegate = self
            style.width = CSSValue(cgfloat: props.width)
        }
    }

    private let icon = UIImageViewComponent<C>(props: UIImageViewComponentProps(), style: ASComponentStyle())

    private lazy var richLabel: RichLabelComponent<C> = {
        let props = RichLabelProps()

        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return RichLabelComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: DocsPreviewLeftInfoViewComponentProps,
                                          _ new: DocsPreviewLeftInfoViewComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }
}

extension DocsPreviewLeftInfoViewComponent: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        guard let linkRange = props.linkRange else { return false }
        if range.location == linkRange.location &&
            range.length == linkRange.length {
            props.onLabelClicked()
        }
        return true
    }
}
