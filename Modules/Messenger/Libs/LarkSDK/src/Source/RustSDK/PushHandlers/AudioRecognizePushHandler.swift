//
//  AudioRecognizePushHandler.swift
//  LarkSDK
//
//  Created by kangkang on 2023/6/14.
//

import Foundation
import LarkSDKInterface
import LarkContainer
import RustPB
import LarkRustClient

final class PushAudioRecognitionHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    func process(push message: Im_V1_SendSpeechRecognitionResponse) {
        let pushAudioRecognition = PushAudioRecognition(push: message)
        self.pushCenter?.post(pushAudioRecognition)
    }
}
