//
//  BDPWebComponentChannel.swift
//  TTMicroApp
//
//  Created by 窦坚 on 2021/8/20.
//

import Foundation
import LKCommonsLogging

/**
 webview组件（BDPWebviewComponent）与  小程序（BDPJSRuntime） 间的映射关系
 */

@objcMembers
public final class BDPWebComponentChannel: NSObject {
    private static let CHANNELID_PREFFIX: String = "MESSAGE_CHANNEL_"

    private let log = Logger.oplog(BDPWebComponentChannel.self, category: "webviewAPI.BDPWebComponentChannel")

    /// 通道ID
    public var channelId: String
    /// BDPJSRuntime uniqueID
    public private(set) var jsRuntimeId: BDPUniqueID
    /// 组件ID 协议属性
    public private(set) var webViewComponentId: NSInteger

    public required init(jsRuntimeId: BDPUniqueID, webviewComponentId: NSInteger) {
        self.jsRuntimeId = jsRuntimeId
        self.webViewComponentId = webviewComponentId
        self.channelId = BDPWebComponentChannel.generateChannelId(webviewComponentId: webViewComponentId)
        log.info("BDPWebComponentChannel initiated, channelId: " + self.channelId + " for webViewComponent: " + String(webViewComponentId) + " and jsruntime: \(jsRuntimeId)")
    }

    public static func generateChannelId(webviewComponentId: NSInteger) -> String {
        return BDPWebComponentChannel.CHANNELID_PREFFIX + "\(webviewComponentId)"
    }

}
