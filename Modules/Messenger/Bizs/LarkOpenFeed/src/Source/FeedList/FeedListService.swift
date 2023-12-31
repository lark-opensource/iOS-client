//
//  FeedListService.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/4/3.
//

import Foundation

public protocol FeedListPageSwitchService: AnyObject {
    func switchToFeedTeamList(teamId: String)
}
