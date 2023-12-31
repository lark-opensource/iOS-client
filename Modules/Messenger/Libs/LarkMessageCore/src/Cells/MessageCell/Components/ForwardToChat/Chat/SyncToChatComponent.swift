//
//  File.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/15.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import RichLabel
import LarkModel
import LarkMessageBase
import UniverseDesignCardHeader

public protocol SyncToChatComponentContext: ComponentContext { }

public protocol SyncToChatComponentDelegate: AnyObject {
    func replyViewTapped(_ rootMessage: Message?)
}

final public class SyncToChatComponentProps: ASComponentProps {
    public weak var delegate: SyncToChatComponentDelegate?
    public var message: Message?
    public var attributedText: NSAttributedString?
    public var outofRangeText: NSAttributedString?
    public var font: UIFont?
    public var textColor: UIColor = UIColor.ud.N400
    public var padding: CSSValue = 12
}

public final class SyncToChatComponent<C: SyncToChatComponentContext>: ASComponent<SyncToChatComponentProps, EmptyState, TappedView, C> {

    public override init(props: SyncToChatComponentProps, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.flexGrow = 1
        style.alignSelf = .stretch
        label.props.numberOfLines = 1
        setUpProps(props: props)
        gradientSyncToChatView.setSubComponents([label])
        setSubComponents([gradientSyncToChatView])
    }

    private lazy var label: RichLabelComponent<C> = {
        let props = RichLabelProps()
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.paddingLeft = 6
        return RichLabelComponent<C>(props: props, style: style)
    }()

    private lazy var gradientSyncToChatView: SyncToChatViewComponent<C> = {
        let props = SyncToChatViewComponent<C>.Props()
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.flexGrow = 1
        return SyncToChatViewComponent<C>(props: props, style: style)
    }()

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        view.initEvent(needLongPress: false)
        return view
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.onTapped = { [weak self] _ in
            self?.props.delegate?.replyViewTapped(self?.props.message?.syncToChatThreadRootMessage)
        }
    }

    public override func willReceiveProps(_ old: SyncToChatComponentProps,
                                          _ new: SyncToChatComponentProps) -> Bool {
        setUpProps(props: new)
        return true
    }
}

fileprivate extension SyncToChatComponent {
    func setUpProps(props: SyncToChatComponentProps) {
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
            mutText.addAttributes([.paragraphStyle: paragraphStyle],
                                  range: NSRange(location: 0, length: mutText.length))
            label.props.attributedText = mutText
        } else {
            label.props.attributedText = nil
        }

        gradientSyncToChatView.style.paddingLeft = props.padding
        gradientSyncToChatView.style.paddingRight = props.padding
        gradientSyncToChatView.style.paddingTop = props.padding

        gradientSyncToChatView.style.display = .flex
        setSubComponents([gradientSyncToChatView])
    }
}
