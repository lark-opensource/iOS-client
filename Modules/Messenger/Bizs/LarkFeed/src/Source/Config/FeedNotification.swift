//
//  FeedNotification.swift
//  LarkFeed
//
//  Created by liuxianyu on 2021/11/19.
//

import Foundation

public struct FeedNotification {
    public static let didChangeDebugMode: NSNotification.Name = NSNotification.Name("lark.feed.debugmode.did.change")
    public static let needReloadMsgFeedList: Notification.Name = NSNotification.Name("lark.feed.msgfeedlist.need.reload")
}
