//
//  DetailKeyBoadTracker.swift
//  Moment
//
//  Created by liluobin on 2021/3/17.
//

import Foundation
import UIKit

final class DetailKeyBoadTracker {
    private let source: MomentsDetialPageSource?
    private let showKeyboardWhenEnter: Bool
    var action: Tracer.ActionType?
    var trackerSource: Tracer.ReplySource?

    init(source: MomentsDetialPageSource?, showKeyboardWhenEnter: Bool) {
        self.source = source
        self.showKeyboardWhenEnter = showKeyboardWhenEnter
        configEvent()
    }
    func configEvent() {
        if let source = source, showKeyboardWhenEnter {
            action = .btn
            if source == .feed {
                trackerSource = .feed
            } else if source == .profile {
                trackerSource = .profile
            }
        }
    }

    func uploadDataWithForReplay(contenType: Tracer.ContentType, postID: String?, commentID: String?) {
        /// 键盘点击
        if isIntputBox() {
            Tracer.trackCommunityTabReply(action: .inputBox, contentType: contenType, source: .detail, postID: postID, commentID: commentID)
        /// 事件来源
        } else if let trackerSource = trackerSource,
                  let action = action {
            Tracer.trackCommunityTabReply(action: action, contentType: contenType, source: trackerSource, postID: postID, commentID: commentID)
        }
    }

    func uploadDataWithForReplaySend(contenType: Tracer.ContentType, postID: String?, commentID: String?) {
        /// 键盘点击
        if isIntputBox() {
            Tracer.trackCommunityTabReplySend(action: .inputBox, contentType: contenType, source: .detail, postID: postID, commentID: commentID)
        /// 事件来源
        } else if let trackerSource = trackerSource,
                  let action = action {
            Tracer.trackCommunityTabReplySend(action: action, contentType: contenType, source: trackerSource, postID: postID, commentID: commentID)
        }
    }

    func isIntputBox() -> Bool {
        return trackerSource == nil && action == nil
    }

    func clearData() {
        action = nil
        trackerSource = nil
    }
}
