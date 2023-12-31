//
//  ReplyComponent.swift
//  Action
//
//  Created by KT on 2019/5/29.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import RichLabel
import LarkModel
import LarkMessageBase
import UniverseDesignCardHeader

public protocol ReplyComponentContext: ComponentContext { }

public protocol ReplyComponentDelegate: AnyObject {
    func replyViewTapped(_ replyMessage: Message?)
}

final public class ReplyComponentProps: ASComponentProps {
    public weak var delegate: ReplyComponentDelegate?
    public var message: Message?
    public var attributedText: NSAttributedString?
    public var outofRangeText: NSAttributedString?
    public var font: UIFont?
    public var textColor: UIColor = UIColor.ud.N400
    // 背景是否使用新版本 UDCard 风格
    var colorHue: UDCardHeaderHue?
    // 如果设置colors 需要确保ChatMessageCellComponent masksToBounds为true 否则圆角会有问题。
    public var bgColors: [UIColor] = []
    public var padding: CSSValue = 12
}

public final class ReplyComponent<C: ReplyComponentContext>: ASComponent<ReplyComponentProps, EmptyState, TappedView, C> {

    public override init(props: ReplyComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        label.props.numberOfLines = 1

        setUpProps(props: props)
        gradientReplyView.setSubComponents([label])
        setSubComponents([gradientReplyView])
    }

    private lazy var label: RichLabelComponent<C> = {
        let props = RichLabelProps()
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return RichLabelComponent<C>(props: props, style: style)
    }()

    private lazy var gradientReplyView: ReplyViewComponent<C> = {
        let props = ReplyViewComponent<C>.Props()
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexGrow = 1
        props.bgColors = self.props.bgColors
        return ReplyViewComponent<C>(props: props, style: style)
    }()

    private lazy var udCardHeaderReplyView: UDCardHeaderComponent<C> = {
        let props = UDCardHeaderComponentProps()
        props.layoutType = .top
        let style = ASComponentStyle()
        style.display = .none
        style.flexGrow = 1
        return UDCardHeaderComponent<C>(props: props, style: style)
    }()

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        view.initEvent(needLongPress: false)
        return view
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.onTapped = { [weak self] _ in
            self?.props.delegate?.replyViewTapped(self?.props.message)
        }
    }

    public override func willReceiveProps(_ old: ReplyComponentProps,
                                          _ new: ReplyComponentProps) -> Bool {
        setUpProps(props: new)
        return true
    }
}

fileprivate extension ReplyComponent {
    func setUpProps(props: ReplyComponentProps) {
        guard let font = props.font else { return }
        label.props.outOfRangeText = props.outofRangeText
        label.props.font = font
        if let attrText = props.attributedText {
            let paragraphStyle = NSMutableParagraphStyle()
            /// 这里只展示一行，尽可能多的展示内容
            // swiftlint:disable ban_linebreak_byChar
            paragraphStyle.lineBreakMode = .byCharWrapping
            // swiftlint:enable ban_linebreak_byChar
            let mutText = NSMutableAttributedString(attributedString: attrText)
            mutText.addAttributes([.foregroundColor: props.textColor,
                                   .paragraphStyle: paragraphStyle],
                                  range: NSRange(location: 0, length: mutText.length))
            label.props.attributedText = mutText
        } else {
            label.props.attributedText = nil
        }

        udCardHeaderReplyView.style.paddingLeft = props.padding
        udCardHeaderReplyView.style.paddingRight = props.padding
        udCardHeaderReplyView.style.paddingTop = props.padding
        gradientReplyView.style.paddingLeft = props.padding
        gradientReplyView.style.paddingRight = props.padding
        gradientReplyView.style.paddingTop = props.padding

        if let colorHue = props.colorHue {
            udCardHeaderReplyView.style.display = .flex
            udCardHeaderReplyView.setSubComponents([label])
            setSubComponents([udCardHeaderReplyView])
            udCardHeaderReplyView.props.colorHue = colorHue
            gradientReplyView.style.display = .none
            gradientReplyView.setSubComponents([])
        } else {
            udCardHeaderReplyView.style.display = .none
            udCardHeaderReplyView.setSubComponents([])
            gradientReplyView.style.display = .flex
            gradientReplyView.setSubComponents([label])
            setSubComponents([gradientReplyView])
            gradientReplyView.props.bgColors = props.bgColors
        }
    }
}
