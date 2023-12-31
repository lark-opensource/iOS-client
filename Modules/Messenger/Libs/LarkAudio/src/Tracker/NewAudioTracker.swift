//
//  NewAudioTracker.swift
//  LarkAudio
//
//  Created by ZhangHongyun on 2021/3/28.
//

import Foundation
import UIKit
import Homeric
import LarkContainer
import LKCommonsTracker
import LarkAccountInterface
import RustPB
import AVFoundation

final class NewAudioTracker: NSObject {

    let userID: String
    init(userID: String) {
        self.userID = userID
    }

    var netStatus: Int?

    /// 用户点击录音按钮
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrUserTouchButton(sessionId: String) {
        let params = ["user_id": userID,
                      "source_id": sessionId,
                      "net_status": netStatus ?? 0,
                      "timestamp": Date().timeIntervalSince1970] as [String: Any]
        let event = TeaEvent(Homeric.ASL_ASR_USER_TOUCH_BUTTON, params: params)
        Tracker.post(event)
    }

    /// 用户开始录音并请求ASR
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrRecordingStart(sessionId: String) {
        var params = ["user_id": userID,
                      "source_id": sessionId,
                      "net_status": netStatus ?? 0,
                      "timestamp": Date().timeIntervalSince1970] as [String: Any]
        let inputs = AVAudioSession.sharedInstance().currentRoute.inputs
        if !inputs.isEmpty {
            let input = inputs[0]
            params["audio_input_device"] = input.description
        }
        let event = TeaEvent(Homeric.ASL_ASR_RECORDING_START_DEV, params: params)
        Tracker.post(event)
    }

    /// 发送完最后一个语音包
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrSendEndPacket(sessionId: String) {
        let params = ["user_id": userID,
                      "source_id": sessionId,
                      "net_status": netStatus ?? 0,
                      "timestamp": Date().timeIntervalSince1970] as [String: Any]
        let event = TeaEvent(Homeric.ASL_ASR_SEND_END_PACKET_DEV, params: params)
        Tracker.post(event)
    }

    /// 收到最后一个响应包
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrReceiveEndResponse(sessionId: String, isSuccess: Bool) {
        let params = ["user_id": userID,
                      "source_id": sessionId,
                      "is_success": isSuccess ? 1 : 0,
                      "net_status": netStatus ?? 0,
                      "timestamp": Date().timeIntervalSince1970] as [String: Any]
        let event = TeaEvent(Homeric.ASL_ASR_RECEIVE_END_RESPONSE_DEV, params: params)
        Tracker.post(event)
    }

    /// ASR第一个非空结果上屏
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrFirstPartialOnScreen(sessionId: String) {
        let params = ["user_id": userID,
                      "source_id": sessionId,
                      "timestamp": Date().timeIntervalSince1970] as [String: Any]
        let event = TeaEvent(Homeric.ASL_ASR_FIRST_PARTIAL_ON_SCREEN_DEV, params: params)
        Tracker.post(event)
    }

    /// 用户松手结束录音
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrRecordingStop(sessionId: String) {
        let params = ["user_id": userID,
                      "source_id": sessionId,
                      "timestamp": Date().timeIntervalSince1970] as [String: Any]
        let event = TeaEvent(Homeric.ASL_ASR_RECORDING_STOP_DEV, params: params)
        Tracker.post(event)
    }

    /// ASR final上屏
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrFinalResultOnScreen(sessionId: String) {
        let params = ["user_id": userID,
                      "source_id": sessionId,
                      "net_status": netStatus ?? 0,
                      "timestamp": Date().timeIntervalSince1970] as [String: Any]
        let event = TeaEvent(Homeric.ASL_ASR_FINAL_RESULT_ON_SCREEN_DEV, params: params)
        Tracker.post(event)
    }

    /// ASR最终结果为空
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrFinalResultEmpty(sessionId: String) {
        let params = ["user_id": userID,
                      "source_id": sessionId]
        let event = TeaEvent(Homeric.ASL_ASR_FINAL_RESULT_EMPTY_DEV, params: params)
        Tracker.post(event)
    }

    /// ASR识别完成后取消
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrFinishThenCancel(sessionId: String) {
        let params = ["user_id": userID,
                      "source_id": sessionId]
        let event = TeaEvent(Homeric.ASL_ASR_FINISH_THEN_CANCEL_DEV, params: params)
        Tracker.post(event)
    }

    /// ASR识别完成后编辑
    /// - Parameter sessionId: 一次ASR交互过程中的id
    func asrFinishThenEdit(sessionId: String) {
        let params = ["user_id": userID,
                      "source_id": sessionId]
        let event = TeaEvent(Homeric.ASL_ASR_FINISH_THEN_EDIT_DEV, params: params)
        Tracker.post(event)
    }

}
