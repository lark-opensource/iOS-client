//
//  ChatterStatusLabelCompontent.swift
//  Action
//
//  Created by KT on 2019/5/12.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import RichLabel
import LarkModel
import LarkMessageBase

public protocol ChatterStatusLabelComponentContext: ComponentContext { }

final public class ChatterStatusLabelProps: SafeASComponentProps {
    public var height: CGFloat = UIFont.ud.caption1.pointSize + 4
    /// props存在多线程读写问题，需要防护
    private var _attriubuteText: NSAttributedString?
    public var attriubuteText: NSAttributedString? {
        get { return safeRead { self._attriubuteText } }
        set { safeWrite { self._attriubuteText = newValue } }
    }
    public var image: UIImage?
    public var showText: Bool = true
    public var showIcon: Bool = true
    public var font: UIFont = UIFont.ud.caption1
    public var rangeLinkMap: [NSRange: URL] = [:]
    public var tapableRangeList: [NSRange] = []
    public var invaildLinkMap: [NSRange: String] = [:]
    public weak var delegate: LKLabelDelegate?
    public var invaildLinkBlock: ((String) -> Void)?
    public var linkAttributesColor: UIColor = UIColor.ud.textLinkNormal
}

public final class ChatterStatusLabelCompontent<C: ChatterStatusLabelComponentContext>: ASComponent<ChatterStatusLabelProps, EmptyState, UIView, C> {

    public override init(props: ChatterStatusLabelProps,
                         style: ASComponentStyle,
                         context: C? = nil) {
        style.alignItems = .center
        style.flexShrink = 1
        style.flexGrow = 0

        super.init(props: props, style: style, context: context)
        setUpProps(props: props)
        setSubComponents([icon, label])
    }

    private lazy var icon: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.image = self.props.image

        let style = ASComponentStyle()
        style.width = 14.auto()
        style.height = 14.auto()
        style.flexShrink = 0
        style.marginRight = 4
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    private lazy var label: RichLabelComponent<C> = {
        let props = RichLabelProps()
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return RichLabelComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: ChatterStatusLabelProps,
                                          _ new: ChatterStatusLabelProps) -> Bool {
        setUpProps(props: new)
        return true
    }
}

fileprivate extension ChatterStatusLabelCompontent {

    func setUpProps(props: ChatterStatusLabelProps) {
        icon.props.setImage = { $0.set(image: props.image) }
        label.props.delegate = props.delegate
        label.props.font = props.font
        label.props.tapableRangeList = props.tapableRangeList
        label.props.rangeLinkMap = props.rangeLinkMap
        label.props.invaildLinkMap = props.invaildLinkMap
        label.props.invaildLinkBlock = props.invaildLinkBlock
        label.props.numberOfLines = 1
        label.props.textCheckingDetecotor = DataCheckDetector
        label.props.linkAttributes = [
            .foregroundColor: props.linkAttributesColor
        ]
        label.props.activeLinkAttributes = [
            LKBackgroundColorAttributeName: UIColor.ud.N200
        ]

        label.props.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes:
            [.font: props.font, .foregroundColor: UIColor.ud.N500])
        label.props.attributedText = props.attriubuteText

        style.height = CSSValue(cgfloat: props.height)
        icon.style.display = self.props.showIcon ? .flex : .none
        label.style.display = self.props.showText ? .flex : .none
    }
}
