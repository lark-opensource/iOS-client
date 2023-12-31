//
//  ReactionDetailViewModelDependencyImpl.swift
//  LarkChat
//
//  Created by 李晨 on 2019/7/10.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import Swinject
import EENavigator
import UniverseDesignToast
import LarkReactionDetailController
import LarkEmotion
import LarkUIKit
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkCore
import ByteWebImage
import LarkBizAvatar

final class ReactionDetailDependencyImpl: ReactionDetailViewModelDependency, UserResolverWrapper {
    let userResolver: UserResolver

    typealias DetailMessage = LarkReactionDetailController.Message
    typealias DetailReaction = LarkReactionDetailController.Reaction
    typealias DetailChatter = LarkReactionDetailController.Chatter

    private let disposeBag = DisposeBag()
    private let messageAPI: MessageAPI
    private let chatterAPI: ChatterAPI
    var startReactionType: String?

    init(userResolver: UserResolver, messageAPI: MessageAPI, chatterAPI: ChatterAPI) {
        self.userResolver = userResolver
        self.messageAPI = messageAPI
        self.chatterAPI = chatterAPI
    }

    func reactionDetailImage(_ reaction: String, callback: @escaping (UIImage) -> Void) {
        let start = CACurrentMediaTime()
        if let image = EmotionResouce.shared.imageBy(key: reaction) {
            CoreTracker.trackerEmojiLoadDuration(duration: CACurrentMediaTime() - start, emojiKey: reaction, isLocalImage: true)
            callback(image)
        } else {
            var imageView: UIImageView? = UIImageView()
            // 尽量用imageKey发起请求
            var isEmojis: Bool = false; var key: String = reaction
            if let imageKey = EmotionResouce.shared.imageKeyBy(key: reaction) {
                isEmojis = true; key = imageKey
            }
            let resource = LarkImageResource.reaction(key: key, isEmojis: isEmojis)
            let isCache = LarkImageService.shared.isCached(resource: resource, options: .all)
            imageView?.bt.setLarkImage(with: resource,
                                       trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .reaction)
                                       },
                                       completion: { result in
                                           CoreTracker.trackerEmojiLoadDuration(duration: CACurrentMediaTime() - start, emojiKey: reaction, isLocalImage: isCache)
                                           switch result {
                                           case let .success(imageResult):
                                               if let reactionIcon = imageResult.image {
                                                   callback(reactionIcon)
                                               }
                                           case .failure:
                                               break
                                           }
                                           imageView = nil
                                       })
        }
    }

    func reactionDetailFetchReactions(message: DetailMessage, callback: @escaping ([DetailReaction]?, Error?) -> Void) {
        messageAPI
            .fetchLocalMessage(id: message.id)
            .map { (message) -> [DetailReaction] in
                let reactions = message.reactions.map({ (reaction) -> DetailReaction in
                    return DetailReaction(type: reaction.type, chatterIds: reaction.chatterIds, totalCount: Int(reaction.chatterCount))
                })
                return reactions
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (reactions) in
                callback(reactions, nil)
            }, onError: { (error) in
                callback(nil, error)
            }).disposed(by: disposeBag)
    }

    func reactionDetailFetchChatters(message: DetailMessage, reaction: DetailReaction, callback: @escaping ([DetailChatter]?, Error?) -> Void) {
        let chatterIDS = reaction.chatterIds

        let transform: (LarkModel.Chatter.Description.TypeEnum) -> DetailChatter.DescriptionType = { (type) -> DetailChatter.DescriptionType in
            switch type {
            case .onBusiness:
                return .onBusiness
            case .onDefault:
                return .onDefault
            case .onLeave:
                return .onLeave
            case .onMeeting:
                return .onMeeting
            @unknown default:
                assert(false, "new value")
                return .onDefault
            }
        }

        chatterAPI.fetchChatChatters(ids: chatterIDS, chatId: message.channelID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (mapper) in
                let chatters = chatterIDS
                    .compactMap { mapper[$0] }
                    .map({ (chatter) -> DetailChatter in
                        return DetailChatter(
                            id: chatter.id,
                            avatarKey: chatter.avatarKey,
                            displayName: chatter.displayName,
                            descriptionText: chatter.description_p.text,
                            descriptionType: transform(chatter.description_p.type)
                        )
                    })
                callback(chatters, nil)
            }, onError: { (error) in
                callback(nil, error)
            })
            .disposed(by: disposeBag)

    }

    func reactionDetailFetchChatterAvatar(message: DetailMessage, chatter: DetailChatter, callback: @escaping (UIImage) -> Void) {
        var fixedKey = chatter.avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
        var imageView: BizAvatar? = BizAvatar()
        imageView?.setAvatarByIdentifier(chatter.id, avatarKey: fixedKey, scene: .Chat, completion: { result in
            DispatchQueue.main.async {
                if let image = (try? result.get())?.image {
                    callback(image)
                } else if case let .failure(error) = result {
                    ReactionDetailHandler.logger.error(
                        "reaction detail get image faile",
                        additionalData: ["chatterID": chatter.id],
                        error: error)
                }
                imageView = nil
            }
        })
    }

    func reactionDetailClickChatter(message: DetailMessage, chatter: DetailChatter, controller: UIViewController) {
        let body = PersonCardBody(chatterId: chatter.id,
                                  chatId: message.channelID,
                                  source: .chat)
        if Display.phone {
            navigator.push(body: body, from: controller)
        } else {
            navigator.present(
                body: body,
                wrap: LkNavigationController.self,
                from: controller,
                prepare: { vc in
                    vc.modalPresentationStyle = .formSheet
                })
        }
    }
}
