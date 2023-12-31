//
//  NetStatusPushHandler.swift
//  LarkAudio
//
//  Created by bytedance on 2021/6/30.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkSDKInterface

final class NetStatusPushHandler: UserPushHandler {
    func process(push message: Basic_V1_DynamicNetStatusResponse) throws {
        (try? userResolver.resolve(assert: NewAudioTracker.self))?.netStatus = message.netStatus.rawValue
    }
}
