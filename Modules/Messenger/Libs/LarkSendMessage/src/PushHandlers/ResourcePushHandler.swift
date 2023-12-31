//
//  ResourcePushHandler.swift
//  LarkSDK
//
//  Created by huangjianming on 2019/9/2.
//

import Foundation
import LarkRustClient // BaseRustPushHandler
import RustPB // Media_V1_PushResourceResponse

final public class ResourcePushHandler: UserPushHandler {
    private var progressService: ProgressService? { try? userResolver.resolve(assert: ProgressService.self) }

    public func process(push message: RustPB.Media_V1_PushResourceResponse) {
        let progress = Progress(totalUnitCount: 100)
        progress.completedUnitCount = 100
        self.progressService?.update(key: message.key, progress: progress, rate: -1)
    }

}
