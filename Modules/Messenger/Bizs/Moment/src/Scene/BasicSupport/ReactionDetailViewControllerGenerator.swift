//
//  ReactionDetailViewControllerGenerator.swift
//  Moment
//
//  Created by zc09v on 2021/1/21.
//

import UIKit
import Foundation
import LarkReactionDetailController
import LarkEmotion
import LarkContainer
import LarkMessengerInterface
import RxSwift
import LarkUIKit
import EENavigator
import ByteWebImage
import LarkBizAvatar
import LKCommonsLogging
import UniverseDesignToast
import LarkRustClient

final class ReactionDetailViewControllerGenerator: ReactionDetailViewModelDelegate, UserResolverWrapper {
    let userResolver: UserResolver
    private let id: String
    private let reactions: [RawData.ReactionList]
    private let disposeBag: DisposeBag = DisposeBag()
    let startReactionType: String?
    @ScopedInjectedLazy private var postAPI: PostApiService?
    @ScopedInjectedLazy var momentsConfigAndSettingService: MomentsConfigAndSettingService?
    static let logger = Logger.log(ReactionDetailViewControllerGenerator.self, category: "Module.Moments.ReactionDetailViewControllerGenerator")

    init(userResolver: UserResolver, id: String, reactionType: String?, reactions: [RawData.ReactionList]) {
        self.userResolver = userResolver
        self.id = id
        self.startReactionType = reactionType
        self.reactions = reactions
    }

    func generator() -> UIViewController {
        let message = LarkReactionDetailController.Message(id: self.id, channelID: "")
        let controller = ReactionDetailVCFactory.create(message: message, dependency: self)
        return controller
    }

    func reactionDetailImage(_ reaction: String, callback: @escaping (UIImage) -> Void) {
        if let image = EmotionResouce.shared.imageBy(key: reaction) {
            callback(image)
        }
    }

    func reactionDetailFetchReactions(message: LarkReactionDetailController.Message, callback: @escaping ([LarkReactionDetailController.Reaction]?, Error?) -> Void) {
        let reactions = self.reactions.map { (reactionInfo) -> LarkReactionDetailController.Reaction in
            return LarkReactionDetailController.Reaction(type: reactionInfo.type, chatterIds: [], totalCount: Int(reactionInfo.count))
        }
        return callback(reactions, nil)
    }

    func reactionDetailFetchChatters(message: LarkReactionDetailController.Message,
                                     reaction: LarkReactionDetailController.Reaction,
                                     callback: @escaping ([LarkReactionDetailController.Chatter]?, Error?) -> Void) {
        self.postAPI?.reactionsList(byID: self.id, reactionType: reaction.type, pageToken: "", count: 500)
            .subscribe { (result) in
                var chatters = result.users.map { (user) -> LarkReactionDetailController.Chatter in
                    var chatterType: LarkReactionDetailController.Chatter.ChatterType
                    switch user.momentUserType {
                    case .user:
                        chatterType = .user
                    case .nickname:
                        chatterType = .nickName
                    @unknown default: chatterType = .user
                    }
                    return LarkReactionDetailController.Chatter(id: user.userID,
                                                                avatarKey: user.avatarKey,
                                                                displayName: user.displayName,
                                                                descriptionText: "",
                                                                descriptionType: .onDefault,
                                                                chatterType: chatterType)
                }
                /// 判断是否有匿名点赞
                if result.anonymousUserCount != 0 {
                    /// 添加匿名内容，并获取匿名头像
                    self.getAnonyousUserAvatarKey(callBack: { avatarKey in
                        chatters.append(LarkReactionDetailController.Chatter(id: "0",
                                                                             avatarKey: avatarKey,
                                                                             displayName: BundleI18n.Moment.Moments_NumSpectator_Title(result.anonymousUserCount),
                                                                             descriptionText: "",
                                                                             descriptionType: .onDefault,
                                                                             chatterType: .anonymous))
                        callback(chatters, nil)
                    })
                } else {
                    callback(chatters, nil)
                }
            } onError: { [weak self] (error) in
                callback(nil, error)
                if let error = error as? RCError {
                    switch error {
                    case .businessFailure(errorInfo: let info):
                        switch info.code {
                            //MOMENTS_PERMISSION_ERROR
                        case 330_300:
                            //没有公司圈权限
                            DispatchQueue.main.async {
                                guard let mainSceneWindow = self?.userResolver.navigator.mainSceneWindow else { return }
                                UDToast.showFailure(with: info.displayMessage, on: mainSceneWindow, error: error)
                            }
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
            }.disposed(by: self.disposeBag)
    }
    /// 获取匿名头像
    func getAnonyousUserAvatarKey(callBack: ((String) -> Void)?) {
        self.momentsConfigAndSettingService?.getUserCircleConfigWithFinsih({ (config) in
            callBack?(config.anonymousAvatarKey)
        }, onError: { error in
            callBack?("")
            Self.logger.error("getAnonyousUserAvatarKey configAndSetting error", error: error)
        })
    }

    func reactionDetailFetchChatterAvatar(message: LarkReactionDetailController.Message, chatter: LarkReactionDetailController.Chatter, callback: @escaping (UIImage) -> Void) {
        var fixedKey = chatter.avatarKey.replacingOccurrences(of: "lark.avatar/", with: "")
        fixedKey = fixedKey.replacingOccurrences(of: "mosaic-legacy/", with: "")
        var imageView: BizAvatar? = BizAvatar()
        imageView?.setAvatarByIdentifier(chatter.id, avatarKey: fixedKey, scene: .Moments, completion: { result in
            if let image = (try? result.get())?.image {
                callback(image)
            }
            imageView = nil
        })
    }

    func reactionDetailClickChatter(message: LarkReactionDetailController.Message, chatter: LarkReactionDetailController.Chatter, controller: UIViewController) {
        if chatter.chatterType == .user {
            MomentsNavigator.pushUserAvatarWith(userResolver: userResolver,
                                                userID: chatter.id,
                                                from: controller,
                                                source: .reaction,
                                                trackInfo: nil)
        } else if chatter.chatterType == .nickName {
            MomentsNavigator.pushNickNameAvatarWith(userResolver: userResolver,
                                                    userID: chatter.id,
                                                    userInfo: (chatter.displayName, chatter.avatarKey),
                                                    from: controller)
        }
    }
}
