//
//  ForwardThreadContentComponentBinder.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2023/3/29.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase

public protocol ForwardThreadBinderContext: ForwardThreadViewModelContext & ForwardThreadComponentContext {}

/// 「转发话题外露回复」需求：话题回复、话题使用一套逻辑 & 使用嵌套UI
final class ForwardThreadContentComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ForwardThreadBinderContext>: NewComponentBinder<M, D, C> {
    private var forwardThreadProps = ForwardThreadContentComponent<C>.Props()
    private var forwardThreadComponent: ForwardThreadContentComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ForwardThreadContentComponent<C> { return forwardThreadComponent }

    /// 用TouchView屏蔽点击事件
    private var touchComponent: TouchViewComponent<C> = .init(props: .init(), style: .init(), context: nil)

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        let forwardThreadStyle = ASComponentStyle()
        if let vm = self.viewModel as? ForwardThreadContentViewModel, vm.addBorderBySelf {
            forwardThreadStyle.cornerRadius = ForwardThreadContentConfig.cornerRadius
            forwardThreadStyle.boxSizing = .borderBox
            forwardThreadStyle.border = Border(BorderEdge(width: 1, color: UIColor.ud.lineBorderCard, style: .solid))
            forwardThreadStyle.backgroundColor = UIColor.ud.bgBody
        }
        self.forwardThreadComponent = ForwardThreadContentComponent(props: self.forwardThreadProps, style: forwardThreadStyle, context: context)

        // 点击统一跳转到内层话题
        let touchComponentProps = TouchViewComponentProps()
        touchComponentProps.onTapped = { [weak self] in
            guard let `self` = self, let vm = self.viewModel, let actionHandler = self.actionHandler as? ForwardThreadContentActionHandler else { return }
            actionHandler.tapAction(chat: vm.metaModel.getChat(), message: vm.metaModel.message, content: vm.metaModel.message.content as? MergeForwardContent)
        }
        let touchComponentStyle = ASComponentStyle()
        touchComponentStyle.top = 0
        touchComponentStyle.bottom = 0
        touchComponentStyle.width = 100%
        touchComponentStyle.position = .absolute
        self.touchComponent = TouchViewComponent(props: touchComponentProps, style: touchComponentStyle, context: context)
        var children = self.forwardThreadComponent.children
        children.append(touchComponent)
        self.forwardThreadComponent.setSubComponents(children)
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.viewModel as? ForwardThreadContentViewModel else {
            assertionFailure()
            return
        }
        self.forwardThreadProps.delegate = vm
        self.forwardThreadProps.contentMaxWidth = vm.contentMaxWidth()
        self.forwardThreadProps.message = vm.metaModel.message
        self.forwardThreadProps.subMessageIsForwardThread = vm.subMessageIsForwardThread(vm.metaModel.message)
        self.forwardThreadProps.senderInfo = vm.senderInfo(vm.metaModel.message)
        self.forwardThreadProps.tripInfo = vm.tripInfo(vm.metaModel.message)
        self.forwardThreadProps.replyInfo = vm.replyInfo(vm.metaModel.message)
        self.forwardThreadProps.needPaddingBottom = vm.needPaddingBottom

        // 触发component.willReceiveProps
        self.forwardThreadComponent.props = self.forwardThreadProps
    }
}
