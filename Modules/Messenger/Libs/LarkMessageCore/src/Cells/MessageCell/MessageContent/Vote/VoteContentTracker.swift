//
//  VoteContentTracker.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/25.
//

import Foundation
import Homeric
import LKCommonsTracker

final class VoteContentTracker {
    static func trackClickVoteItem(voteId: String, isSingle: Bool, selectStatus: Bool) {
        Tracker.post(TeaEvent(Homeric.EX_PLATFORM_CLICK_VOTE_ITEMS, params: [
            "select_status": selectStatus,
            "vote_id": voteId,
            "vote_type": isSingle ? "single" : "multi"
            ])
        )
    }

    static func trackClickVoteSubmit(voteId: String, isSingle: Bool, itemCount: Int) {
        Tracker.post(TeaEvent(Homeric.EX_PLATFORM_CLICK_VOTE_SUBMIT, params: [
            "item_count": itemCount,
            "vote_id": voteId,
            "vote_type": isSingle ? "single" : "multi"
            ])
        )
    }
}
