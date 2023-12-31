//
//  VideoChunkPushHandler.swift
//  LarkSDK
//
//  Created by 李晨 on 2022/1/9.
//

import Foundation
import RustPB // Media_V1_PushChunkyUploadStatusResponse
import LarkRustClient // BaseRustPushHandler
import LarkContainer // PushNotificationCenter
import LKCommonsLogging // Logger

final public class VideoChunkPushHandler: UserPushHandler {
    static var logger = Logger.log(VideoChunkPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    public func process(push message: RustPB.Media_V1_PushChunkyUploadStatusResponse) {
        Self.logger.info("receive chunky push \(message)")
        let result = PushChunkyUploadStatus(uploadID: message.uploadID, status: message.status)
        self.pushCenter?.post(result)
    }
}
