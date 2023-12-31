//
//  ExtrackPackagePushHandler.swift
//  LarkSDK
//
//  Created by bytedance on 2021/11/15.
//

import Foundation
import RustPB
import LarkRustClient
import LKCommonsLogging
import LarkSDKInterface
import LarkContainer

final class ExtrackPackagePushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(ExtrackPackagePushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Media_V1_PushExtractPackageStatus) {
        let push: PushExtractPackage
        switch message.status {
        case .error(let err):
            push = PushExtractPackage(status: .failed(error: err), key: message.key)
        case .progress(let progress):
            push = PushExtractPackage(status: .inProgress(progress: progress), key: message.key)
        case .result(let res):
            push = PushExtractPackage(status: .success(result: res), key: message.key)
        @unknown default:
            return
        }
        self.pushCenter?.post(push)
    }
}
