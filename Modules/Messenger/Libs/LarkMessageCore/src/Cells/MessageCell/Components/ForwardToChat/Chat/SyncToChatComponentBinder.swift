//
//  SyncToChatComponentBinder.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/15.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase

public final class SyncToChatCompontentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: SyncToChatComponentContext & ReplyViewModelContext>: NewComponentBinder<M, D, C> {
    private let style = ASComponentStyle()
    private let props = SyncToChatComponentProps()
    private lazy var _component: SyncToChatComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: SyncToChatComponent<C> {
        return _component
    }
    private let syncToChatViewModel: SyncToChatComponentViewModel<M, D, C>?
    private let syncToChatActionHandler: SyncToChatComponentActionHandler<C>?
    private let padding: CSSValue

    public init(
        key: String? = nil,
        context: C? = nil,
        syncToChatViewModel: SyncToChatComponentViewModel<M, D, C>?,
        syncToChatActionHandler: SyncToChatComponentActionHandler<C>?,
        padding: CSSValue = 12
    ) {
        self.syncToChatViewModel = syncToChatViewModel
        self.syncToChatActionHandler = syncToChatActionHandler
        self.padding = padding
        super.init(key: key, context: context, viewModel: syncToChatViewModel, actionHandler: syncToChatActionHandler)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = SyncToChatComponent<C>(props: props, style: style, context: context)
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.syncToChatViewModel else {
            assertionFailure()
            return
        }
        vm.replyViewTapped = { [weak self] rootMessage, chat in
            self?.syncToChatActionHandler?.replyViewTapped(replyMessage: rootMessage, chat: chat)
        }
        vm.replyImageTapped = { [weak self] imageView, replyMessage, chat, messageID, permissionPreview, dynamicAuthorityEnum in
            self?.syncToChatActionHandler?.replyImageTapped(
                imageView: imageView,
                replyMessage: replyMessage,
                chat: chat,
                messageID: messageID,
                permissionPreview: permissionPreview,
                dynamicAuthorityEnum: dynamicAuthorityEnum
            )
        }
        vm.getReplyMessageSummerize()
        props.message = vm.message
        props.attributedText = vm.attributedText
        props.outofRangeText = vm.outOfRangeText
        props.font = vm.font
        props.delegate = self
        props.textColor = vm.textColor
        props.padding = padding
        _component.props = props
    }
}

extension SyncToChatCompontentBinder: SyncToChatComponentDelegate {
    public func replyViewTapped(_ rootMessage: Message?) {
        guard let chat = self.syncToChatViewModel?.metaModel.getChat() else { return }
        self.syncToChatActionHandler?.replyViewTapped(replyMessage: rootMessage, chat: chat)
    }
}
