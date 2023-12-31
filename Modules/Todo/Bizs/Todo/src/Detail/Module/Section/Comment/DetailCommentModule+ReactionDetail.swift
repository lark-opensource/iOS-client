//
//  DetailCommentModule+ReactionDetail.swift
//  Todo
//
//  Created by 张威 on 2021/4/14.
//

import LarkFoundation
import LarkMenuController
import EENavigator
import CTFoundation
import TodoInterface
import LarkContainer
import LarkNavigator
import LarkUIKit
import LarkActionSheet
import RxSwift
import RxCocoa
import LarkEmotion
import LarkReactionDetailController

// nolint: magic number
extension DetailCommentModule {

    final class ReactionDetailDependency: UserResolverWrapper {

        let focusType: String
        let reactions: [DetailCommentReactionInfo]
        var userResolver: LarkContainer.UserResolver

        @ScopedInjectedLazy private var routeDependency: RouteDependency?
        @ScopedInjectedLazy private var fetchApi: TodoFetchApi?

        init(resolver: UserResolver, focusType: String, reactions: [DetailCommentReactionInfo]) {
            self.userResolver = resolver
            self.focusType = focusType
            self.reactions = reactions
        }

        func makeViewController() -> UIViewController {
            return ReactionDetailVCFactory.create(message: .init(id: "FIXME", channelID: "FIXME"), dependency: self)
        }

    }

}

extension DetailCommentModule.ReactionDetailDependency: ReactionDetailViewModelDelegate {

    typealias Message = LarkReactionDetailController.Message
    typealias Chatter = LarkReactionDetailController.Chatter
    typealias Reaction = LarkReactionDetailController.Reaction

    var startReactionType: String? { focusType }

    func reactionDetailImage(_ reaction: String, callback: @escaping (UIImage) -> Void) {
        if let image = EmotionResouce.shared.imageBy(key: reaction) {
            callback(image)
        }
    }

    func reactionDetailFetchReactions(message: Message, callback: @escaping ([Reaction]?, Error?) -> Void) {
        let reactions: [Reaction] = self.reactions.map { info in
            return .init(type: info.reactionKey, chatterIds: info.users.map(\.id), totalCount: info.users.count)
        }
        return callback(reactions, nil)
    }

    func reactionDetailFetchChatters(message: Message, reaction: Reaction, callback: @escaping ([Chatter]?, Error?) -> Void) {
        guard let targetReaction = self.reactions.first(where: { $0.reactionKey == reaction.type }) else {
            callback([], nil)
            return
        }
        fetchApi?.getUsers(byIds: targetReaction.users.map(\.id)).take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { users in
                    let chatters = users.map { user -> LarkReactionDetailController.Chatter in
                        return .init(
                            id: user.userID,
                            avatarKey: user.avatarKey,
                            displayName: user.name,
                            descriptionText: "",
                            descriptionType: .onDefault
                        )
                    }
                    callback(chatters, nil)
                },
                onError: { err in
                    callback([], err)
                }
            )
    }

    func reactionDetailFetchChatterAvatar( message: Message, chatter: Chatter, callback: @escaping (UIImage) -> Void) {
        // 参考: LarkChat.ReactionDetailDependencyImpl
        var fixedKey = chatter.avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
        var imageView: UIImageView? = UIImageView()
        imageView?.bt.setLarkImage(with: .avatar(key: fixedKey, entityID: chatter.id)) { result in
            switch result {
            case .success(let imageResult):
                if let image = imageResult.image {
                    callback(image)
                }
            case .failure(let error):
                Detail.logger.error("reaction detail get image faile. chatter.id: \(chatter.id), err: \(error)")
            }
            imageView = nil
        }
    }

    func reactionDetailClickChatter( message: Message, chatter: Chatter, controller: UIViewController) {
        var routeParams = RouteParams(from: controller)
        routeParams.openType = .push
        routeDependency?.showProfile(with: chatter.id, params: routeParams)
    }

}
