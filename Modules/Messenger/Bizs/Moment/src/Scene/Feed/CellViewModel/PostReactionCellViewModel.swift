//
//  PostReactionCellViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/1/25.
//
import Foundation
import LarkFoundation
import LarkMessageBase
import LarkModel

/// reactionVM
final class PostReactionCellViewModel: BaseReactionCellViewModel<RawData.PostEntity> {
    override var identifier: String {
        return "post_reaction"
    }

    private lazy var scene: MomentContextScene = {
        return self.context.pageAPI?.scene ?? .unknown
    }()

    override func convertReactionListEntities(_ entities: [RawData.ReactionListEntity]) -> [Reaction] {
        /// 详情页全部展示
        if self.scene == .postDetail {
            return super.convertReactionListEntities(entities)
        }
        /// feed 页面需要定制展示reaction 展示最热的3个 + 自己参与的
        var reactions: [Reaction] = []
        for (index, reactionsEntity) in entities.enumerated() {
            var needShow = false
            if index < 3 {
                needShow = true
            } else {
                needShow = reactionsEntity.reactionList.selfInvolved
            }
            if needShow {
                let reaction = Reaction(type: reactionsEntity.reactionList.type, chatterIds: reactionsEntity.reactionList.firstPageUserIds, chatterCount: 0)
                reaction.chatters = reactionsEntity.firstPageUsers.map({ user in
                    let chatter = Chatter.transform(pb: Chatter.PBModel())
                    chatter.id = user.userID
                    chatter.name = user.displayName
                    return chatter
                })
                reactions.append(reaction)
            }
        }
        return reactions
    }

    override func doReactionWithAction(_ action: Bool) {
        Tracer.trackCommunityTabReaction(reaction: .reaction_list, contentType: .post, source: self.scene, postID: self.entity.id, commentID: nil, action: action)
    }
    /// 返回所属的板块
    override func getCategoryIds() -> [String] {
        return self.entity.post.categoryIds
    }

    override func reactionForAnonymous() -> Bool {
        return self.entity.post.isAnonymous
    }

    override func update(entity: RawData.PostEntity) {
        super.update(entity: entity)
        self.canReaction = entity.canCurrentAccountReaction(momentsAccountService: try? userResolver.resolve(assert: MomentsAccountService.self))
    }
}
