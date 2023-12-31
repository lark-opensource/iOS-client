//
//  VoteContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/21.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase

public struct VoteContentConfig {
    public static var contentMaxWidth: CGFloat = 400
}

final class VoteContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VoteContentComponentContext & VoteContentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = VoteContentComponent<C>.Props()
    private lazy var _component: VoteContentComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: VoteContentComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "VoteContent"
        _component = VoteContentComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? VoteContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        vm.pharseRichText()
        props.contentPreferMaxWidth = min(VoteContentConfig.contentMaxWidth, vm.contentPreferMaxWidth)
        props.selectTypeLabelText = vm.selectTypeLabelText
        props.title = vm.title
        props.content = vm.content
        props.footerText = vm.footerText
        props.hasBottomMargin = vm.hasBottomMargin
        props.buttonEnableTitle = vm.buttonEnableTitle
        props.buttonDisableTitle = vm.buttonDisableTitle
        props.submitEnable = vm.submitEnable
        props.onViewClicked = { [weak vm] in
            vm?.onVoteButtonDidClick()
        }
        _component.props = props
    }
}

final class MessageDetailVoteContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VoteContentComponentContext & VoteContentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = VoteContentComponent<C>.Props()
    private lazy var _component: VoteContentComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: VoteContentComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        props.key = key ?? "VoteContent"
        style.cornerRadius = 10
        style.border = Border(BorderEdge(width: 1, color: UDMessageColorTheme.imMessageCardBorder, style: .solid))
        style.boxSizing = .borderBox
        _component = VoteContentComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? VoteContentViewModel<M, D, C>  else {
            assertionFailure()
            return
        }
        vm.pharseRichText()
        props.contentPreferMaxWidth = min(VoteContentConfig.contentMaxWidth, vm.contentPreferMaxWidth)
        props.selectTypeLabelText = vm.selectTypeLabelText
        props.title = vm.title
        props.content = vm.content
        props.footerText = vm.footerText
        props.hasBottomMargin = vm.hasBottomMargin
        props.buttonEnableTitle = vm.buttonEnableTitle
        props.buttonDisableTitle = vm.buttonDisableTitle
        props.submitEnable = vm.submitEnable
        props.onViewClicked = { [weak vm] in
            vm?.onVoteButtonDidClick()
        }
        _component.props = props
    }
}

final class PinVoteContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: VoteContentComponentContext & VoteContentViewModelContext>: ComponentBinder<C> {
    private let style = ASComponentStyle()
    private let props = MessageBriefComponent<C>.Props()
    private lazy var _component: MessageBriefComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override var component: MessageBriefComponent<C> {
        return _component
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = MessageBriefComponent<C>(props: props, style: style, context: context)
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? PinVoteContentViewModel<M, D, C> else {
            assertionFailure()
            return
        }
        vm.pharseRichText()
        props.contentPreferMaxWidth = min(VoteContentConfig.contentMaxWidth, vm.contentPreferMaxWidth)
        props.title = vm.title
        props.content = vm.pinVoteContent
        props.setIcon = { [weak vm] view in
            view.image = vm?.pinVoteIcon
        }
        _component.props = props
    }
}
