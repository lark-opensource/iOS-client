//
//  DownloadFilePushHandler.swift
//  Lark
//
//  Created by chengzhipeng-bytedance on 2018/2/6.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RustPB
import LarkRustClient
import LarkModel
import LarkSDKInterface

import LarkContainer

typealias PushDownloadFileResponse = RustPB.Media_V1_PushDownloadFileResponse

final class DownloadFilePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: PushDownloadFileResponse) {
        self.pushCenter?.post(
            PushDownloadFile(
                messageId: message.messageID,
                key: message.key,
                path: message.path,
                progress: message.progress,
                state: message.state,
                type: message.type,
                sourceType: message.sourceType,
                sourceID: message.sourceID,
                rate: message.rate,
                isEncrypted: message.isEncrypted,
                error: message.hasError ? message.error : nil
            )
        )
    }
}
