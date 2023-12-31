//
//  FoldMessageContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by liluobin on 2022/9/16.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkUIKit

struct FoldMessageContentConfig {
    public static var contentMaxWidth: CGFloat {
        return 480
    }
}

final class FoldMessageContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: PageContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = FoldMessageContentComponent<C>.Props()
    private lazy var _component: FoldMessageContentComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: FoldMessageContentComponent<C> {
        return _component
    }
    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "FoldMessageContent"
        _component = FoldMessageContentComponent(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? FoldMessageContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        props.foldCount = vm.totalCount
        props.foldUserCount = vm.userLength
        props.foldStyle = vm.style
        props.foldChatters = vm.users
        props.hasMore = vm.hasMore
        props.recallTextLinks = vm.textLinks
        props.richDelegate = vm
        props.approveViewDelegate = vm
        props.chatterViewDelegate = vm
        props.richStyleSheets = vm.styleSheets
        props.richElement = vm.getRichElement()
        props.showFollowBtn = vm.showFollowButton
        props.propagationSelectors = vm.propagationSelectors
        props.recallAttributedStr = vm.recallAtrr
        props.tapBlock = { [weak vm] in
            vm?.pushToFoldDetail()
        }
        switch vm.style {
        case .card:
            var width = vm.contentPreferMaxWidth
            if Display.pad {
                width = min(width, FoldMessageContentConfig.contentMaxWidth)
            }
            style.width = CSSValue(cgfloat: width)
        case .none:
            style.width = 0
        case .noMessages, .recallByAdmin(_):
            style.width = CSSValue(cgfloat: vm.contentPreferMaxWidth)
        }
        _component.props = props
    }
}
