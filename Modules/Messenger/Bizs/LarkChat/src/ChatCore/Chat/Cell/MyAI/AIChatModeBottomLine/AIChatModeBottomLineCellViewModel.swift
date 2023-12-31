//
//  AIChatModeBottomLineCellViewModel.swift
//  LarkChat
//
//  Created by ByteDance on 2023/6/20.
//

import Foundation
import LarkMessageCore
import LarkMessageBase
import AsyncComponent
import LarkModel

class AIChatModeBottomLineCellViewModel: ChatCellViewModel, HasCellConfig {
    var message: Message
    var cellConfig: ChatCellConfig = ChatCellConfig()
    enum Status {
        case loading
        case hasMore
        case none
    }
    var status: Status = .none {
        didSet {
            guard status != oldValue else { return }
            self.calculateRenderer()
            if let viewModelId = self.id {
                self.context.reloadRow(byViewModelId: viewModelId, animation: .none)
            }
        }
    }
    lazy var showMoreBlock: (() -> Void) = { [weak self] in
        guard let self = self else { return }
        self.status = .loading
        self.context.loadMoreMyAIChatModeThread(chatModeId: self.aiChatModeId, threadId: self.threadId)
    }
    final override var identifier: String {
        return "ai_chat_mode_bottom_line"
    }

    final override var id: String? {
        return "\(identifier)_\(aiChatModeId)"
    }

    var threadId: String {
        return message.threadId
    }
    var aiChatModeId: Int64 {
        return message.aiChatModeID
    }

    init(rootMessage: Message, context: ChatContext) {
        self.message = rootMessage
        super.init(context: context, binder: AIChatModeBottomLineComponentBinder(context: context))
        self.calculateRenderer()
    }

    func successLoadMore(hasMore: Bool) {
        if hasMore {
            self.status = .hasMore
        } else {
            self.status = .none
        }
    }
}

public final class AIChatModeBottomLineComponentBinder: ComponentBinder<ChatContext> {
    private lazy var _component: AIChatModeBottomLineComponent = .init(props: .init(), style: .init(), context: nil)
    private var props: AIChatModeBottomLineComponent.Props = .init()

    public final override var component: ComponentWithContext<ChatContext> {
        return _component
    }

    public override func update<VM: ViewModel>(with vm: VM, key: String? = nil) {
        guard let vm = vm as? AIChatModeBottomLineCellViewModel else {
            assertionFailure()
            return
        }
        props.showMoreBlock = vm.showMoreBlock
        props.status = vm.status
        _component.props = props
    }

    public override func buildComponent(key: String? = nil, context: ChatContext? = nil) {
        let style = ASComponentStyle()
        style.paddingLeft = 12
        style.paddingRight = 12
        style.alignContent = .stretch
        style.justifyContent = .center
        _component = AIChatModeBottomLineComponent(
            props: self.props,
            style: style,
            context: context
        )
    }
}
