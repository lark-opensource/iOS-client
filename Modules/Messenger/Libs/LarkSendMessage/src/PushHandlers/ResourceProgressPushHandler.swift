//
//  ResourceProgressPushHandler.swift
//  Action
//
//  Created by qihongye on 2018/9/19.
//

import Foundation
import RustPB // Media_V1_PushResourceProgressResponse
import LarkRustClient // BaseRustPushHandler

final public class ResourceProgressPushHandler: UserPushHandler {
    private var progressService: ProgressService? { try? userResolver.resolve(assert: ProgressService.self) }

    public func process(push message: RustPB.Media_V1_PushResourceProgressResponse) {
        let progress = Progress(totalUnitCount: 100)
        progress.completedUnitCount = Int64(message.progress)
        self.progressService?.update(key: message.key, progress: progress, rate: -1)
    }
}
