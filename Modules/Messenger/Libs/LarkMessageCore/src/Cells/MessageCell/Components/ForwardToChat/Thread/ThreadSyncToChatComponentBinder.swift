//
//  ThreadSyncToChatComponentBinder.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/29.
//

import UIKit
import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import RichLabel
import EEFlexiable

final public class ThreadSyncToChatComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ThreadSyncToChatComponentContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = ThreadSyncToChatViewComponentProps()
    private lazy var _component: ThreadSyncToChatViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: ThreadSyncToChatViewComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.numberOfLines = 0
        _component = ThreadSyncToChatViewComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? ThreadSyncToChatComponentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.attributedText = {
            let attributedText = NSMutableAttributedString(string: vm.text)
            attributedText.addAttributes(
                [
                    .font: UIFont.ud.body2,
                    .foregroundColor: UIColor.ud.textCaption
                ],
                range: NSRange(location: 0, length: attributedText.length)
            )
            return attributedText
        }()
        props.onViewClicked = { [weak vm] in
            vm?.syncToChatDidTapped()
        }
        _component.props = props
    }
}

final public class ThreadSyncToChatViewComponentProps: SafeASComponentProps {
    private var _attributedText: NSAttributedString?
    public var attributedText: NSAttributedString? {
        get {
            safeRead {
                self._attributedText
            }
        }
        set {
            safeWrite {
                self._attributedText = newValue
            }
        }
    }
    public var tapableRangeList: [NSRange] = []
    public var textLinkList: [LKTextLink] = []
    public weak var delegate: LKLabelDelegate?
    public var iconSize: CGSize = CGSize(width: 12, height: 12)
    public var iconMarginBottom: CGFloat?
    public var height: CGFloat = 15
    public var numberOfLines: Int = 1

    private var _onViewClicked: (() -> Void)?
    public var onViewClicked: (() -> Void)? {
        get {
            safeRead {
                self._onViewClicked
            }
        }
        set {
            safeWrite {
                self._onViewClicked = newValue
            }
        }
    }
}

public final class ThreadSyncToChatViewComponent<C: ComponentContext>: ASComponent<ThreadSyncToChatViewComponentProps, EmptyState, TappedView, C> {
    public override init(props: ThreadSyncToChatViewComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.backgroundColor = .clear
        super.init(props: props, style: style, context: context)

        setSubComponents([label])
        updateProps(props: props)
    }

    public override func create(_ rect: CGRect) -> TappedView {
        return TappedView(frame: rect)
    }

    public override func update(view: TappedView) {
        super.update(view: view)

        if let tapped = self.props.onViewClicked {
            view.initEvent(needLongPress: false)
            view.onTapped = { _ in
                tapped()
            }
        } else {
            view.deinitEvent()
        }
    }

    private func updateProps(props: ThreadSyncToChatViewComponentProps) {
        label.props.attributedText = props.attributedText
        label.props.numberOfLines = props.numberOfLines
        label.props.tapableRangeList = props.tapableRangeList
        label.props.delegate = props.delegate
        label.props.textLinkList = props.textLinkList
    }

    private lazy var label: RichLabelComponent<C> = {
        let props = RichLabelProps()
        let style = ASComponentStyle()
        style.alignSelf = .center
        style.backgroundColor = .clear
        return RichLabelComponent(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: ThreadSyncToChatViewComponentProps,
                                          _ new: ThreadSyncToChatViewComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }
}
