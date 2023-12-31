//
//  ReactionViewModel.swift
//  Minutes
//
//  Created by lvdaqian on 2021/3/2.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

struct ReactionViewModel {
    init(reactionKey: String?, count: Int) {
        self.reactionKey = reactionKey
        self.count = count
    }

    let reactionKey: String?
    let count: Int

    init(_ info: ReactionInfo) {
        self.reactionKey = info.emojiCode
        self.count = info.count ?? 0
    }
}
