//
//  ReactionSetNotification.swift
//  Moment
//
//  Created by zc09v on 2021/2/1.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient

protocol ReactionSetNotification: AnyObject {
    var rxReactionSet: PublishSubject<RawData.ReactionSetNofEntity> { get }
}

final class ReactionSetNotificationHandler: ReactionSetNotification {
    let rxReactionSet: PublishSubject<RawData.ReactionSetNofEntity> = .init()

    init(client: RustService) {
        client.register(pushCmd: .momentsPushReactionSetLocalNotification) { [weak self] nofInfo in
            guard let self = self else { return }
            do {
                let rustBody = try RawData.PushReactionSetNof(serializedData: nofInfo)
                let reactionEntities = MomentsDataConverter.convertReactionsToReactionListEntities(entityId: rustBody.entityID,
                                                                                                   entities: rustBody.entities,
                                                                                                   reactions: rustBody.reactionSet.reactions)
               let entity = RawData.ReactionSetNofEntity(id: rustBody.entityID, categoryIds: rustBody.categoryIds, reactionEntities: reactionEntities, reactionSet: rustBody.reactionSet)
                self.rxReactionSet.onNext(entity)
            } catch {
                assertionFailure("serialize update noti payload failed")
            }
        }
    }
}
