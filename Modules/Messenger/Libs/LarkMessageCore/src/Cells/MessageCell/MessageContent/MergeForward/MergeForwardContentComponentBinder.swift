//
//  MergeForwardContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/6/18.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase

class MergeForwardContentBaseComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentContext>: NewComponentBinder<M, D, C> {
    let mergeForwardViewModel: MergeForwardContentViewModel<M, D, C>?
    let mergeForwardActionHandler: MergeForwardContentActionHandler<C>?
    init(
        key: String? = nil,
        context: C? = nil,
        mergeForwardViewModel: MergeForwardContentViewModel<M, D, C>?,
        mergeForwardActionHandler: MergeForwardContentActionHandler<C>?
    ) {
        self.mergeForwardViewModel = mergeForwardViewModel
        self.mergeForwardActionHandler = mergeForwardActionHandler
        super.init(key: key, context: context, viewModel: mergeForwardViewModel, actionHandler: mergeForwardActionHandler)
    }
}

class MergeForwardContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentContext>: MergeForwardContentBaseComponentBinder<M, D, C> {
    var props = MergeForwardContentComponent<C>.Props()
    lazy var _component: MergeForwardContentComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: MergeForwardContentComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.mergeForwardViewModel else {
            assertionFailure()
            return
        }
        props.content = vm.contentText
        props.title = vm.title
        props.isDefaultStyle = !vm.isMe
        props.tapAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.tapAction(chat: vm.metaModel.getChat(), message: vm.message)
        }
        props.contentMaxWidth = vm.contentMaxWidth
        _component.props = props
        _component.style.padding = vm.needContentPadding ? 12 : 0
        if vm.addBorderBySelf {
            _component._style.cornerRadius = 10
            _component._style.boxSizing = .borderBox
            _component._style.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineDividerDefault, style: .solid))
        }
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        _component = MergeForwardContentComponent(props: props, style: style, context: context)
    }
}

final class ThreadChatMergeForwardContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentContext>: MergeForwardContentBaseComponentBinder<M, D, C> {
    private var props = MergeForwardContentComponent<C>.Props()
    private var contentComponent: MergeForwardContentComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private lazy var _component: UIViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: UIViewComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.mergeForwardViewModel else {
            assertionFailure()
            return
        }
        props.content = vm.contentText
        props.title = vm.title
        props.tapAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.tapAction(chat: vm.metaModel.getChat(), message: vm.message)
        }
        props.contentMaxWidth = vm.contentMaxWidth
        contentComponent.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let contentStyle = ASComponentStyle()
        self.contentComponent = MergeForwardContentComponent(props: props, style: contentStyle, context: context)
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.padding = 12
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
        _component = UIViewComponent<C>(props: .empty, style: style)
        _component.setSubComponents([contentComponent])
    }
}

final class MessageDetailContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: MergeForwardContentContext>: MergeForwardContentBaseComponentBinder<M, D, C> {
    private var props = MergeForwardContentComponent<C>.Props()
    private lazy var _component: MergeForwardContentComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: MergeForwardContentComponent<C> {
        return _component
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.mergeForwardViewModel else {
            assertionFailure()
            return
        }
        props.content = vm.contentText
        props.title = vm.title
        props.tapAction = { [weak self] in
            guard let vm = self?.mergeForwardViewModel else { return }
            self?.mergeForwardActionHandler?.tapAction(chat: vm.metaModel.getChat(), message: vm.message)
        }
        props.contentMaxWidth = vm.contentMaxWidth
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let style = ASComponentStyle()
        style.padding = 12
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.N300, style: .solid))
        _component = MergeForwardContentComponent(props: props, style: style, context: context)
    }
}
