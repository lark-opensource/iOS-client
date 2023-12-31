//
//  UploadFilePushHandler.swift
//  Lark-Rust
//
//  Created by liuwanlin on 2017/12/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB // Media_V1_PushUploadFileResponse
import LarkRustClient // BaseRustPushHandler
import LarkContainer

final public class UploadFilePushHandler: UserPushHandler {
    private var progressService: ProgressService? { try? userResolver.resolve(assert: ProgressService.self) }

    public func process(push message: RustPB.Media_V1_PushUploadFileResponse) {
        let progress = Progress(totalUnitCount: 100)
        progress.completedUnitCount = Int64(message.progress)
        let fileUploadInfo = PushUploadFile(
            localKey: message.localKey,
            key: message.key,
            progress: progress,
            state: message.state,
            type: message.type,
            rate: message.rate
        )
        self.progressService?.dealUploadFileInfo(fileUploadInfo)
    }
}
