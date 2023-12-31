//
//  LarkLiveWebBridgeDelegate.swift
//  LarkLive
//
//  Created by yangyao on 2021/6/16.
//

import Foundation
import LarkWebViewContainer
import UIKit

public final class LarkLiveWebBridgeDelegate: LarkWebViewBridgeDelegate {
    private let logger = Logger.live

    private let viewModel: LiveWebViewModel
    init(viewModel: LiveWebViewModel) {
        self.viewModel = viewModel
    }

    public func invoke(with message: APIMessage, webview: LarkWebView, callback: APICallbackProtocol) {
        // data 是 [String:Any] 类型，any 需要强转
        logger.info("receive message from web bridge, api: \(message.apiName), data: \(message.data)")
        let data = message.data
        let callbackID = message.callbackID
        let extra = message.extra

        let event = data["live_event"] as? Int ?? 0
        let version = data["version"] as? String
        if let params = data["params"] as? [String: Any] {
            let liveHost = params["live_host"] as? String
            let liveID = params["live_id"] as? String
            let liveType = params["live_type"] as? Int ?? 0
            let streamLink = params["stream_link"] as? String
            let muted = params["muted"] as? Bool ?? false
            let delay = params["delay"] as? Int
            let content = params["content"] as? String
            let danmaku = params["danmaku_active"] as? Bool ?? false
            let playerType = params["player_type"] as? String
            let floatViewOrientation = params["orientation"] as? String
            
            let liveEvent = LarkLiveEvent(rawValue: event) ?? .unknown
            let liveData = LarkLiveData(liveHost: liveHost,
                                      liveID: liveID,
                                      liveLink: webview.url?.absoluteString,
                                      streamLink: streamLink,
                                      muted: muted,
                                      danmaku: danmaku,
                                      delay: delay,
                                      content: content,
                                      playerType: playerType,
                                      floatViewOrientation: floatViewOrientation)
            viewModel.onWebLiveStateChanged(event: liveEvent, data: liveData)
        }
    }
}
