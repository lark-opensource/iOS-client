//
//  NetDiagnosePushHandler.swift
//  LarkMine
//
//  Created by huanglx on 2021/12/20.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel

//接收网络诊断push
public struct PushLarkApiReachable: PushMessage {
    public let larkApiReachable: RustPB.Tool_V1_PushLarkApiReachable
    public init(larkApiReachable: RustPB.Tool_V1_PushLarkApiReachable) {
        self.larkApiReachable = larkApiReachable
    }
}

final class PushLarkApiReachableHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Tool_V1_PushLarkApiReachable) throws {
        guard let pushCenter = self.pushCenter else { return }
        pushCenter.post(PushLarkApiReachable(larkApiReachable: message))
    }
}
