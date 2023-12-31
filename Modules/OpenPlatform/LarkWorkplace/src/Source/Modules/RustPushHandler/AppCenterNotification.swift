//
//  AppCenterPushHandler.swift
//  Lark
//
//  Created by yin on 2018/11/26.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkContainer
import LarkRustClient
import RustPB
import LarkSetting
import LarkOPInterface
import LKCommonsLogging

enum AppCenterNotification: String, NotificationName {
    case activeAuxiliaryScene = "workplace.axiliary.scene"
}
