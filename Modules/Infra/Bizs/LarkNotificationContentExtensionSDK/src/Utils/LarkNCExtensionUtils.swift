//
//  LarkNCExtensionUtils.swift
//  LarkNotificationContentExtensionSDK
//
//  Created by shin on 2023/3/9.
//

import Foundation
import LarkHTTP

enum LarkNCExtensionUtils {
    /// 生成请求需要的HTTP Body
    static func generateHTTPBody(request: LarkHTTP.Message,
                                 command: LarkNCExtensionPB_Improto_Command) -> Data
    {
        do {
            var requestPacket = LarkNCExtensionPB_Improto_Packet()
            requestPacket.cid = String.randomStr(len: 40)
            requestPacket.cmd = command
            requestPacket.payloadType = .pb2
            requestPacket.payload = try request.serializedData()

            let httpBody = try requestPacket.serializedData()
            LarkNCESDKLogger.logger.info("Generate HTTP Body Success")
            return httpBody
        } catch {
            LarkNCESDKLogger.logger.error("Generate HTTP Body Failed")
            assertionFailure("should never reach here!")
        }

        assertionFailure("should never reach here!")
        return Data()
    }
}
