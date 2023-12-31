//
//  CommentFeedService+Callback.swift
//  SKBrowser
//
//  Created by huayufan on 2022/1/14.
//  


import SKFoundation
import LarkWebViewContainer

extension CommentFeedService {
    
    enum FeedEventListenerAction: String {
        case change
        case readMessage
        case toggleMute // 切换`免打扰`状态
    }
    
    func callFunction(for action: FeedEventListenerAction, params: [String: Any]?) {
        guard let callback = feedCallback else {
           messageQueue.append((action, params ?? [:]))
           DocsLogger.feedInfo("feed callback is nil action: \(action.rawValue)")
           return
        }
        DocsLogger.feedInfo("feed callback action: \(action.rawValue) success")
        var pa = params ?? [:]
        pa["action"] = action.rawValue
        callback.callbackSuccess(param: pa)
    }
    
    func callIfNeed() {
        // 先发送队列里面的
        for message in messageQueue {
            DocsLogger.feedInfo("feed callback messageQueue action: \(message.0.rawValue)")
            callFunction(for: message.0, params: message.1)
        }
        // 清空队列
        messageQueue = []
    }
}
