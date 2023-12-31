//
//  ReactionDetailViewModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2018/12/11.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkContainer

public typealias ReactionDetailViewModelDelegate = ReactionDetailViewModelDependency

public protocol ReactionDetailViewModelDependency: AnyObject {
    var startReactionType: String? { get }
    func reactionDetailImage(_ reaction: String, callback: @escaping (UIImage) -> Void)
    func reactionDetailFetchReactions(message: Message, callback: @escaping ([Reaction]?, Error?) -> Void)
    func reactionDetailFetchChatters(
        message: Message,
        reaction: Reaction,
        callback: @escaping ([Chatter]?, Error?) -> Void)
    func reactionDetailFetchChatterAvatar(
        message: Message,
        chatter: Chatter,
        callback: @escaping (UIImage) -> Void
    )
    func reactionDetailClickChatter(message: Message, chatter: Chatter, controller: UIViewController)

    /// 是否需要出现自定义底部，用于支撑部分业务有底部提示条的需求
    /// - Parameters:
    ///   - message: message description
    ///   - reaction: reaction description
    ///   - chatter: chatter description
    /// - Returns: 自定义底部View
    func reactionDetailCustomFooter(message: Message, reaction: Reaction, chatters: [Chatter]) -> UIView?

    /// 点击了顶部Segment控件，用于支撑部分业务需要知道具体点了哪个Reaction的需求
    /// - Parameters:
    ///   - index: tab索引
    ///   - preReaction: tab切换之前的reaction对象
    ///   - currentReaction: tab切换之后的reaction对象
    func reactionDetailClickTab(index: Int, preReaction: Reaction, currentReaction: Reaction)
}

public extension ReactionDetailViewModelDependency {
    var startReactionType: String? { return nil }

    func reactionDetailCustomFooter(message: Message, reaction: Reaction, chatters: [Chatter]) -> UIView? { return nil }

    func reactionDetailClickTab(index: Int, preReaction: Reaction, currentReaction: Reaction) {}
}

final class ReactionDetailViewModel {
    typealias StartIndex = Int
    var dependency: ReactionDetailViewModelDependency
    weak var controller: UIViewController?

    var reloadData: Driver<StartIndex?> { return _reloadData.asDriver(onErrorJustReturn: (0)) }
    private var _reloadData = PublishSubject<StartIndex?>()

    private(set) var message: Message
    private(set) var reactions: [Reaction] = []
    private(set) var error: Error?
    private(set) var startIndex: Int = 0

    init(message: Message, dependency: ReactionDetailViewModelDependency) {
        self.dependency = dependency
        self.message = message
    }

    func startLoadMessage() {
        self.dependency
            .reactionDetailFetchReactions(
                message: self.message,
                callback: { [weak self] (reactions, error) in
                    guard let `self` = self else { return }
                    self.set(reactions: reactions ?? [], error: error)
                })
    }

    fileprivate func set(reactions: [Reaction], error: Error? = nil) {
        self.reactions = reactions
        self.error = error

         var startIndex: StartIndex?
        if let type = dependency.startReactionType {
            startIndex = reactions.firstIndex { $0.type == type }
        }

        _reloadData.onNext(startIndex)
    }

    func reaction(at index: Int) -> Reaction? {
        guard index > -1, index < reactions.count else { return nil }
        return reactions[index]
    }

    func configDetailTableController(_ controller: ReactionDetailTableController, at index: Int) {

        // ignore unsupport case
        guard index > -1, index < reactions.count else {
            return
        }

        var viewModel = controller.viewModel
        if viewModel == nil {
            viewModel = ReactionDetailTableViewModel(
                message: message,
                reaction: reactions[index],
                delegate: self
            )
        } else {
            viewModel?.reaction = reactions[index]
        }

        controller.viewModel = viewModel
    }
}

extension ReactionDetailViewModel: ReactionDetailTableViewModelDelegate {
    func reactionDetailTableFetchChatterAvatar(
        message: Message,
        chatter: Chatter,
        callback: @escaping (UIImage) -> Void
    ) {
        self.dependency.reactionDetailFetchChatterAvatar(message: message, chatter: chatter, callback: callback)
    }

    func reactionDetailTableFetchChatters(
        message: Message,
        reaction: Reaction,
        callback: @escaping ([Chatter]?, Error?) -> Void
    ) {
        self.dependency.reactionDetailFetchChatters(message: message, reaction: reaction, callback: callback)
    }

    func reactionDetailTableClickChatter(message: Message, chatter: Chatter) {
        if let controller = self.controller {
            self.dependency.reactionDetailClickChatter(message: message, chatter: chatter, controller: controller)
        }
    }

    func reactionCustomFooter(message: Message, reaction: Reaction, chatters: [Chatter]) -> UIView? {
        return self.dependency.reactionDetailCustomFooter(message: message, reaction: reaction, chatters: chatters)
    }
}
