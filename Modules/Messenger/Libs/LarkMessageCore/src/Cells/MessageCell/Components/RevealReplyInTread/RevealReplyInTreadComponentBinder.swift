//
//  RevealReplyInTreadComponentBinder.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/9/30.
//

import Foundation
import AsyncComponent
import LarkMessageBase
import EEFlexiable

final class RevealReplyInTreadComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: RevealReplyInTreadContext>: NewComponentBinder<M, D, C> {
    private let style = ASComponentStyle()
    private let props = RevealReplyInTreadComponentProps()
    private lazy var _component: RevealReplyInTreadComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: RevealReplyInTreadComponent<C> {
        return _component
    }

    private let replyInThreadViewModel: RevealReplyInTreadComponentViewModel<M, D, C>?
    private let replyInThreadActionHandler: RevealReplyInThreadComponentActionHandler<C>?

    public init(
        key: String? = nil,
        context: C? = nil,
        replyInThreadViewModel: RevealReplyInTreadComponentViewModel<M, D, C>?,
        replyInThreadActionHandler: RevealReplyInThreadComponentActionHandler<C>?
    ) {
        self.replyInThreadViewModel = replyInThreadViewModel
        self.replyInThreadActionHandler = replyInThreadActionHandler
        super.init(key: key, context: context, viewModel: replyInThreadViewModel, actionHandler: replyInThreadActionHandler)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        // RevealReplyInTreadComponent初始化时，有一些lazy的Component依赖displayInThreadMode属性，需要提前设置
        props.useLightColor = self.replyInThreadViewModel?.useLightColor ?? false
        _component = RevealReplyInTreadComponent<C>(props: props, style: style, context: context)
        _component.style.flexDirection = .column
        _component.style.alignSelf = .stretch
        _component._style.flexGrow = 1
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.replyInThreadViewModel else {
            assertionFailure()
            return
        }
        props.totalReplyCount = vm.totalReplyCount
        props.replyInfos = vm.replyInfos.getImmutableCopy()
        props.useLightColor = vm.useLightColor
        props.replyClick = { [weak self] position in
            guard let vm = self?.replyInThreadViewModel else { return }
            self?.replyInThreadActionHandler?.replyClick(message: vm.message, chat: vm.metaModel.getChat(), position: position)
        }
        props.replyTipClick = { [weak self] in
            guard let vm = self?.replyInThreadViewModel else { return }
            self?.replyInThreadActionHandler?.replyTipClick(message: vm.message, chat: vm.metaModel.getChat())
        }
        props.viewClick = { [weak self] in
            guard let vm = self?.replyInThreadViewModel else { return }
            self?.replyInThreadActionHandler?.replyClick(message: vm.message, chat: vm.metaModel.getChat(), position: nil)
        }
        props.contentPreferMaxWidth = vm.metaModelDependency.getContentPreferMaxWidth(vm.message)
        props.outOfRangeText = vm.outOfRangeText
        _component.props = props
    }
}
