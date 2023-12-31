//
//  MessageBurnServiceImp.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/2/15.
//

import Foundation
import LarkModel
import LKCommonsLogging
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import SuiteAppConfig
import LarkSetting
import LarkSafety
import UIKit

private let expireDays = 7 * 24 * 3600 // 7天

public final class MessageBurnServiceImp: MessageBurnService {
    private let ntpServer: ServerNTPTimeService
    private static let logger = Logger.log(MessageBurnServiceImp.self, category: "MessageBurnServiceImp")

    public init(ntpServer: ServerNTPTimeService) {
        self.ntpServer = ntpServer
    }

    public func isBurned(message: Message) -> Bool {
        // message是否支持焚毁
        guard message.burnLife > 0 else {
            return false
        }

        // 先判断 dmessage.isBurned，已经焚毁的直接返回
        if message.isBurned {
            log(message)
            return message.isBurned
        }

        // 兜底销毁时间
        let isExpire = self.ntpServer.serverTime - Int64(message.createTime) > expireDays

        // 开始倒计时 && (达到销毁时间 || 达到兜底时间）
        let isBurnedOfRead = message.burnTime > 0 &&
            message.burnLife > 0 &&
            ((message.burnTime / 1000) < self.ntpServer.serverTime || isExpire)

        // 未开始倒计时 && 达到兜底时间
        let isBurnedOfUnread = (message.burnTime == 0 && message.burnLife > 0 && isExpire)

        let isBurned = (isBurnedOfRead || isBurnedOfUnread)
        if isBurned {
            log(message)
        }
        return isBurned
    }

    private func log(_ message: Message) {
        Self.logger.info(
            """
            Secret Chat Service isBurned
            \(message.channel.id)
            \(message.id)
            \(message.position)
            \(message.isBurned)
            \(message.burnLife)
            \(message.burnTime)
            \(message.meRead)
            \(self.ntpServer.serverTime)
            """
        )
    }
}
