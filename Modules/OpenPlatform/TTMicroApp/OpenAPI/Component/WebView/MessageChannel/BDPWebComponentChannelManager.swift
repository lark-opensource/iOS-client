//
//  BDPWebComponentChannelManager.swift
//  TTMicroApp
//
//  Created by 窦坚 on 2021/8/21.
//

import Foundation
import LKCommonsLogging

/**
 channel管理器
 */

@objcMembers
public final class BDPWebComponentChannelManager: NSObject {

    private let log = Logger.oplog(BDPWebComponentChannelManager.self, category: "webviewAPI.BDPWebComponentChannelManager")

    /// BDPWebViewComponentChannel.channelId  :  BDPWebViewComponentChannel
    private var channels: [String: BDPWebComponentChannel]

    public required override init() {
        self.channels = [:]
        log.info("BDPWebComponentChannelManager initiated! ")
    }

    public func addChannel(channel: BDPWebComponentChannel) -> Void {
        objc_sync_enter(self)
        if (self.channels.keys.contains(channel.channelId)) {
            log.warn("channelID is duplicate!")
        }
        self.channels[channel.channelId] = channel
        log.info("BDPWebComponentChannelManager added channel, key=\(channel.channelId)")
        objc_sync_exit(self)
    }

    public func removeChannel(channelId: String) -> Void {
        objc_sync_enter(self)
        if (self.channels.keys.contains(channelId) == false) {
            log.warn("channelID is not in channels!")
            return
        }
        self.channels[channelId] = nil
        log.info("BDPWebComponentChannelManager moved channel, key=\(channelId)")
        objc_sync_exit(self)
    }

    public func getChannelById(channelId: String) -> BDPWebComponentChannel? {
        if self.channels.isEmpty {
            log.error("channels is empty!")
            return nil
        }
        if let channel = self.channels[channelId] {
            return channel
        } else {
            /// monitor
            log.warn("BDPWebComponentChannelManager get channel failed, key=\(channelId)")
            return nil
        }
    }

}
