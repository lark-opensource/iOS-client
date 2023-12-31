//
//  LKContentFixTask.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/8.
//

import Foundation
import BootManager
import LarkContainer
import LarkRustClient

/// 启动任务，首屏之后执行
final class LKContentFixTask: UserFlowBootTask, Identifiable {
    static var identify = "LKContentFixTask"

    override func execute(_ context: BootContext) {
        LKStringFix.shared.fetchStringFixConfig(rustService: { try? userResolver.resolve(assert: RustService.self) })
    }
}
