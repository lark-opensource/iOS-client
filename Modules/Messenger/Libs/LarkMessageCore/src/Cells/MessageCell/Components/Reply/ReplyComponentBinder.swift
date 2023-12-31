//
//  ReplyComponentBinder.swift
//  Action
//
//  Created by KT on 2019/6/3.
//

import Foundation
import LarkModel
import EEFlexiable
import AsyncComponent
import LarkMessageBase

final class ReplyCompontentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ReplyComponentContext & ReplyViewModelContext>: NewComponentBinder<M, D, C> {
    private let style = ASComponentStyle()
    private let props = ReplyComponentProps()
    private lazy var _component: ReplyComponent<C> = .init(props: .init(), style: .init(), context: nil)
    public override var component: ReplyComponent<C> {
        return _component
    }
    private let replyViewModel: ReplyComponentViewModel<M, D, C>?
    private let replyActionHandler: ReplyComponentActionHandler<C>?
    private let padding: CSSValue

    public init(
        key: String? = nil,
        context: C? = nil,
        replyViewModel: ReplyComponentViewModel<M, D, C>?,
        replyActionHandler: ReplyComponentActionHandler<C>?,
        padding: CSSValue = 12
    ) {
        self.replyViewModel = replyViewModel
        self.replyActionHandler = replyActionHandler
        self.padding = padding
        super.init(key: key, context: context, viewModel: replyViewModel, actionHandler: replyActionHandler)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = ReplyComponent<C>(props: props, style: style, context: context)
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.replyViewModel else {
            assertionFailure()
            return
        }
        vm.replyViewTapped = { [weak self] replyMessage, chat in
            self?.replyActionHandler?.replyViewTapped(replyMessage: replyMessage, chat: chat)
        }
        vm.replyImageTapped = { [weak self] imageView, replyMessage, chat, messageID, permissionPreview, dynamicAuthorityEnum in
            self?.replyActionHandler?.replyImageTapped(
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
        props.bgColors = vm.backgroundColors
        props.colorHue = vm.colorHue
        props.padding = padding
        _component.props = props
    }
}

extension ReplyCompontentBinder: ReplyComponentDelegate {
    public func replyViewTapped(_ replyMessage: Message?) {
        guard let chat = self.replyViewModel?.metaModel.getChat() else { return }
        self.replyActionHandler?.replyViewTapped(replyMessage: replyMessage, chat: chat)
    }
}
