//
//  CommentContainerBaseView+reactionDetail.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/8/26.
//  swiftlint:disable pattern_matching_keywords


import Foundation
import SKFoundation
import Kingfisher
import LarkEmotion
import LarkReactionDetailController
import SpaceInterface
import SKCommon

class CCMReactionDetailDependencyImpl {

    private let reaction: CommentReaction
    
    var needLoadMore: Bool = false

    var notification: NSObjectProtocol?
    
    var lastReactions: [CommentReaction]
    
    var clickAvatar: ((String, UINavigationController) -> Void)?
    
    init(needLoadMore: Bool, reaction: CommentReaction, lastReactions: [CommentReaction]) {
        self.needLoadMore = needLoadMore
        self.reaction = reaction
        self.lastReactions = lastReactions
    }
    
    func onReactionDetailDismissed() {
        reportEvent(.dismiss)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(notification as Any)
    }
}

extension CCMReactionDetailDependencyImpl: ReactionDetailViewModelDelegate {
    
    /// 打开详情界面初始展示的表情key
    public var startReactionType: String? { reaction.reactionKey }
    
    public func reactionDetailImage(_ reaction: String, callback: @escaping (UIImage) -> Void) {
        if let image = EmotionResouce.shared.imageBy(key: reaction) {
            callback(image)
        } else {
            var imageView: UIImageView? = UIImageView()
            // 尽量用imageKey发起请求
            var isEmojis: Bool = false; var key: String = reaction
            if let imageKey = EmotionResouce.shared.imageKeyBy(key: reaction) {
                isEmojis = true; key = imageKey
            }
            imageView?.bt.setLarkImage(with: .reaction(key: key, isEmojis: isEmojis),
                                       completion: { result in
                                        if let reactionIcon = try? result.get().image {
                                            callback(reactionIcon)
                                        }
                                        imageView = nil
                                       })
        }
    }

    public func reactionDetailFetchReactions(message: LarkReactionDetailController.Message, callback: @escaping ([Reaction]?, Error?) -> Void) {

        if needLoadMore { // 需要更新数据等待通知刷新
            notification = NotificationCenter.default.addObserver(
                forName: Notification.Name.ReactionShowDetail,
                object: nil,
                queue: nil) { [weak self] (notification) in
                    if let userInfo = notification.userInfo as? [ReactionNotificationKey: Any],
                        let reactions = userInfo[.reactions] as? [CommentReaction] {
                        self?.lastReactions = reactions
                        callback(self?._convertReactions(), nil)
                    }
                    NotificationCenter.default.removeObserver(notification as Any)
            }
        } else { // 直接刷新
            callback(_convertReactions(), nil)
        }
    }

    private func _convertReactions() -> [Reaction]? {
        let reactions = lastReactions.map({
            return Reaction(
                type: $0.reactionKey,
                chatterIds: $0.userList.map({ $0.userId })
            )
        })

        return reactions
    }

    public func reactionDetailFetchChatters(message: LarkReactionDetailController.Message, reaction: Reaction, callback: @escaping ([Chatter]?, Error?) -> Void) {

        var chatterSet = Set<Chatter>()

        let convertDescriptionType: (CommentReaction.UserDescriptionType?) -> Chatter.DescriptionType = {
            switch $0 {
            case .defaultType, .none:
                return .onDefault
            case .business:
                return .onBusiness
            case .leave:
                return .onLeave
            case .meeting:
                return .onMeeting
            }
        }

        lastReactions.forEach { (r) in
            r.userList.forEach({ (user) in
                chatterSet.insert(
                    Chatter(id: user.userId,
                            avatarKey: user.avatarUrl,
                            // TODO: displayName 待后续接入
//                            displayName: user.displayName,
                            displayName: user.userName,
                            descriptionText: user.description ?? "",
                            descriptionType: convertDescriptionType(user.descType))
                )
            })
        }

        var chattersMap: [String: Chatter] = [:]
        chatterSet.forEach { (c) in
            chattersMap[c.id] = c
        }

        let chatters = reaction.chatterIds.compactMap { (id) -> Chatter? in
            return chattersMap[id]
        }

        callback(chatters, nil)
    }

    public func reactionDetailFetchChatterAvatar(message: LarkReactionDetailController.Message, chatter: Chatter, callback: @escaping (UIImage) -> Void) {
        if let avaterURL = URL(string: chatter.avatarKey) {
            let downloader = ImageDownloader.default
            downloader.downloadImage(with: avaterURL, completionHandler: { result in
                switch result {
                case .success(let value):
                    callback(value.image)
                case .failure(let error):
                    DocsLogger.info("download avater error:\(error)", component: LogComponents.comment)
                default:
                    break
                }
            })
        }
    }

    public func reactionDetailClickChatter(message: LarkReactionDetailController.Message, chatter: Chatter, controller: UIViewController) {
        guard let navvc = controller.navigationController else {
            DocsLogger.info("can not get navigationController for \(controller)")
            return
        }
        clickAvatar?(chatter.id, navvc)
    }
    
    public func reactionDetailClickTab(index: Int, preReaction: Reaction, currentReaction: Reaction) {
        
        reportEvent(.switchTab(oldType: preReaction.type, newType: currentReaction.type))
    }
}

private extension CCMReactionDetailDependencyImpl {
    
    enum Event {
        case switchTab(oldType: String, newType: String)
        case dismiss
    }
    
    func reportEvent(_ event: Event) {
        guard let commentId = reaction.commentId, !commentId.isEmpty else { return }
        var params: [String: Any] = ["reaction_card_id": commentId,
                                     "target": "none"]
        switch event {
        case .switchTab(let oldType, let newType):
            params.merge(other: ["click": "switch_emoji",
                                 "emoji_type_before": oldType,
                                 "emoji_type_after": newType])
        case .dismiss:
            params.merge(other: ["click": "exit"])
        }
        DocsTracker.newLog(enumEvent: .contentReactionDetailClick, parameters: params)
    }
}
