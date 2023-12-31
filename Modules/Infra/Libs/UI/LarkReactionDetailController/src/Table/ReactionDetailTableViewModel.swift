//
//  ReactionDetailTableViewModel.swift
//  LarkChat
//
//  Created by kongkaikai on 2018/12/12.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa

protocol ReactionDetailTableViewModelDelegate: AnyObject {
    func reactionDetailTableClickChatter(message: Message, chatter: Chatter)
    func reactionDetailTableFetchChatters(
        message: Message,
        reaction: Reaction,
        callback: @escaping ([Chatter]?, Error?) -> Void
    )
    func reactionDetailTableFetchChatterAvatar(
        message: Message,
        chatter: Chatter,
        callback: @escaping (UIImage) -> Void
    )
    func reactionCustomFooter(message: Message, reaction: Reaction, chatters: [Chatter]) -> UIView?
}

final class ReactionDetailTableViewModel {

    let message: Message
    var reaction: Reaction {
        didSet {
            if reaction.type == oldValue.type { return }
            self.chatters = []
        }
    }
    weak var delegate: ReactionDetailTableViewModelDelegate?

    private(set) var chatters: [Chatter] = []
    private(set) var error: Error?

    var reloadData: Driver<Void> { return _reloadData.asDriver(onErrorJustReturn: ()) }
    private var _reloadData = PublishSubject<Void>()

    var startLoading: Driver<Void> { return _startLoading.asDriver(onErrorJustReturn: ()) }
    private var _startLoading = PublishSubject<Void>()

    init(message: Message, reaction: Reaction, delegate: ReactionDetailTableViewModelDelegate) {
        self.delegate = delegate
        self.message = message
        self.reaction = reaction

        startLoadChatters()
    }

    func reload() {
        startLoadChatters()
    }

    func startLoadChatters() {
        _startLoading.onNext(())
        let reactionType = self.reaction.type
        self.delegate?.reactionDetailTableFetchChatters(
            message: message,
            reaction: reaction,
            callback: { [weak self] (chatters, error) in
                guard let `self` = self else { return }
                if self.reaction.type != reactionType { return }
                self.chatters = chatters ?? []
                self.error = error
                self._reloadData.onNext(())
            })
    }

    private func sort(chatters: [Chatter]) -> [Chatter] {
        return chatters.sorted(by: { self.index(for: $0.id) < self.index(for: $1.id) })
    }

    private func index(for chatterId: String) -> Int {
        return reaction.chatterIds.firstIndex(of: chatterId) ?? 0
    }

    func chatter(at index: Int) -> Chatter? {
        guard index > -1,
            index < chatters.count else {
                return nil
        }
        return chatters[index]
    }

    func showPersonCard(at index: Int) {
        guard let chatter = chatter(at: index) else { return }
        self.delegate?.reactionDetailTableClickChatter(message: message, chatter: chatter)
    }
}
