//
//  PushTeamItemChatsHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/3/9.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel

extension Feed_V1_PushTeamItemChats: PushMessage {}

struct PushTeamItemChats: PushMessage {
    let teamChats: [FeedPreview]

    init(teamChats: [FeedPreview]) {
        self.teamChats = teamChats
    }

    var description: String {
        let info = "count: \(teamChats.count), \(teamChats.map { $0.description })"
        return info
    }
}

final class PushTeamItemChatsHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushTeamItemChats) throws {
        guard let pushCenter = self.pushCenter else { return }
        let teamChats: [FeedPreview] = message.teamChats.map { FeedPreview.transformByEntityPreview($0) }
        let push = PushTeamItemChats(teamChats: teamChats)
        FeedContext.log.info("teamlog/pushTeamFeed. \(push.description)")
        pushCenter.post(push)
    }
}
