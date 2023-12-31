//
//  AudioMessageRecognitionPushHandler.swift
//  LarkSDK
//
//  Created by 李晨 on 2019/7/9.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import RxSwift
import LKCommonsLogging

final class AudioMessageRecognitionPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    static var logger = Logger.log(AudioMessageRecognitionPushHandler.self, category: "Rust.PushHandler")

    private var userPushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    private var messageAPI: MessageAPI? { try? userResolver.resolve(assert: MessageAPI.self) }
    private let disposeBag = DisposeBag()

    func process(push message: RustPB.Im_V1_PushAudioMessageRecognitionResult) {

        WebSocketStatusPushHandler.logger.debug(
            "AudioMessageRecognitionPush: \(message.messageID), \(message.seqID), \(message.isEnd)"
        )
        messageAPI?.fetchLocalMessage(id: message.messageID).subscribe(onNext: { [weak self] (messageModel) in
            let result = PushAudioMessageRecognitionResult(
                channelID: messageModel.channel.id,
                messageID: message.messageID,
                seqID: message.seqID,
                result: message.result,
                isEnd: message.isEnd,
                diffIndexSlice: message.diffIndexSlice
            )
            self?.userPushCenter?.post(result)
        }).disposed(by: self.disposeBag)
    }
}
