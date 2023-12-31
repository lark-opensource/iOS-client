//
//  ReactionComponentBinder.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/1/28.
//

import UIKit
import Foundation
import LarkModel
import LarkEmotion
import AsyncComponent
import LarkMessageBase

final class ReactionComponentBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ReactionViewModelContext & PageContext>: NewComponentBinder<M, D, C> {
    private let style = ASComponentStyle()
    private let props = ReactionViewComponent<C>.Props()
    private lazy var _component: ReactionViewComponent<C> = .init(props: .init(), style: .init(), context: nil)
    private var reactonViewModel: ReactionViewModel<M, D, C>?
    private var reactionActionHandler: ReactionActionHandler<C>?

    public override var component: ComponentWithContext<C> {
        return _component
    }

    public init(
        key: String? = nil,
        context: C? = nil,
        reactonViewModel: ReactionViewModel<M, D, C>?,
        reactionActionHandler: ReactionActionHandler<C>?
    ) {
        self.reactonViewModel = reactonViewModel
        self.reactionActionHandler = reactionActionHandler
        super.init(key: key, context: context, viewModel: reactonViewModel, actionHandler: reactionActionHandler)
    }

    public override func buildComponent(key: String? = nil, context: C? = nil) {
        _component = ReactionViewComponent<C>(props: props, style: style, context: context)
    }

    public override func syncToBinder(key: String?) {
        guard let vm = self.reactonViewModel else {
            assertionFailure()
            return
        }
        props.identifier = vm.vmIdentifier
        props.padding = UIEdgeInsets(top: -3, left: -3, bottom: -3, right: -3)
        // 自定义表情上线后需要过滤vm里面违规的表情
        props.reactions = vm.reactions.filter({ reaction in
            let isDeleted = EmotionResouce.shared.isDeletedBy(key: reaction.type)
            return isDeleted == false
        })
        props.getChatterDisplayName = { [weak vm] chatter in
            return vm?.getReactionChatterDisplayName(chatter) ?? ""
        }
        props.delegate = self
        switch vm.reactionType {
        case .blue:
            props.textColor = vm.context.getColor(for: .Reaction_Foreground, type: .mine)
            props.separatorColor = vm.context.getColor(for: .Message_BubbleSplitLine, type: .mine)
        case .gray:
            props.textColor = vm.context.getColor(for: .Reaction_Foreground, type: .other)
            props.separatorColor = vm.context.getColor(for: .Message_BubbleSplitLine, type: .other)
        }
        props.tagBgColor = vm.rectionTagBg()
        if let marginTop = vm.marginTop {
            style.marginTop = marginTop
        }
        if let marginHoriz = vm.marginHoriz {
            style.marginLeft = marginHoriz
            style.marginRight = marginHoriz
        }
        _component._style = style
        _component.props = props
    }
}

extension ReactionComponentBinder: ReactionViewDelegate {
    public func reactionDidTapped(_ reaction: LarkModel.Reaction, tapType: ReactionActionType) {
        guard let chat = self.viewModel?.metaModel.getChat(), let message = self.viewModel?.metaModel.message else { return }
        self.reactionActionHandler?.reactionDidTapped(chat: chat, message: message, reaction: reaction, tapType: tapType)
    }

    public func reactionAbsenceCount(_ reaction: LarkModel.Reaction) -> Int? {
        return self.reactonViewModel?.reactionAbsenceCount(reaction)
    }

    public func reactionTagIconActionAreaEdgeInsets() -> UIEdgeInsets? {
        return self.reactonViewModel?.reactionTagIconActionAreaEdgeInsets()
    }
}
