//
//  LKContentFixPushHandler.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/8.
//

import Foundation
import RustPB
import LarkRustClient

final class LKContentFixPushHandler: UserPushHandler {

    func process(push message: Settings_V1_PushSettings) throws {
        // 配置LKStringFix
        if let config = StringFixConfig(fieldGroups: message.fieldGroups) {
            LKStringFix.shared.reloadConfig(config)
        }
    }
}
