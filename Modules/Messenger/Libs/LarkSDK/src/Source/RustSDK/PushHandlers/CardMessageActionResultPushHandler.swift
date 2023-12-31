//
//  CardMessageActionResultPushHandler.swift
//  Pods
//
//  Created by qihongye on 2019/1/23.
//

import Foundation
import RustPB
import RxSwift
import LarkRustClient
import LarkModel
import LarkContainer
import LarkSDKInterface

final class CardMessageActionResultPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private let disposeBag = DisposeBag()

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Basic_V1_CardMessageActionResult) {
        let loading = message.button.loading
        let cardMessageActionResultPush = PushCardMessageActionResult(
            messageID: message.messageID,
            cardVersion: message.cardVersion,
            pushType: message.type,
            infos: (start: loading.begin, success: loading.success, fail: loading.fail),
            actionID: message.button.actionID,
            errorCode: message.errorCode,
            errorMsg: message.errorMsg
        )
        self.pushCenter?.post(cardMessageActionResultPush)
    }
}
