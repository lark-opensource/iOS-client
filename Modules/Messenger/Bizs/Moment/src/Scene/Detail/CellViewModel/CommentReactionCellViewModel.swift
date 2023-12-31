//
//  CommentReactionCellViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/1/26.
//

import Foundation
import LarkFoundation
import LarkMessageBase
import LarkContainer

final class CommentReactionCellViewModel: BaseReactionCellViewModel<RawData.CommentEntity> {
    private var getPostEntityCallBack: () -> RawData.PostEntity?
    private var postEntity: RawData.PostEntity? {
        return getPostEntityCallBack()
    }
    init(userResolver: UserResolver,
         entity: RawData.CommentEntity,
         getPostEntityCallBack: @escaping () -> RawData.PostEntity?, context: BaseMomentContext, binder: ComponentBinder<BaseMomentContext>) {
        self.getPostEntityCallBack = getPostEntityCallBack
        super.init(userResolver: userResolver, entity: entity, context: context, binder: binder)
        let momentsAccountService = try? userResolver.resolve(assert: MomentsAccountService.self)
        canReaction = postEntity?.canCurrentAccountReaction(momentsAccountService: momentsAccountService) ?? true
    }

    override func doReactionWithAction(_ action: Bool) {
        Tracer.trackCommunityTabReaction(reaction: .reaction_list,
                                         contentType: .comment,
                                         source: .postDetail,
                                         postID: nil,
                                         commentID: self.entity.id,
                                         action: action)
    }

    override func reactionForAnonymous() -> Bool {
        return self.postEntity?.post.isAnonymous ?? false || self.entity.comment.isAnonymous
    }
}
