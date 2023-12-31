//
//  LarkNCEMsgIntentProcessor.swift
//  LarkNotificationContentExtensionSDK
//
//  Created by shin on 2023/3/9.
//

import CryptoSwift
import Foundation
import Intents
import LarkHTTP

struct MsgSendInfo: Codable {
    let meetingID: String
    let userID: String
    let inviterID: String
}

@inline(__always) func _MsgIntentLogInfo(_ log: String) {
    LarkNCESDKLogger.logger.info("\(log)")
#if DEBUG
    NSLog(log)
#endif
}

public enum LarkNCEMsgIntentProcessor {
    private static let aesKey = "CallJumpToDetail"
    
    /// 发送拒绝接听理由
    /// - Parameters:
    ///   - intent: INSendMessageIntent
    ///   - completion: 发送回调，true：成功；false：失败；
    public static func sendRefuseReply(_ intent: INSendMessageIntent, completion: ((Bool) -> Void)? = nil) {
        guard let personHandle = intent.recipients?.first?.personHandle, let value = personHandle.value else {
            _MsgIntentLogInfo("[CallKit]: invalid person handle")
            completion?(false)
            return
        }

        guard let msgContent = intent.content, !msgContent.isEmpty else {
            _MsgIntentLogInfo("[CallKit]: invalid msg content")
            completion?(false)
            return
        }

        guard let aes = try? AES(key: Self.aesKey.bytes, blockMode: ECB(), padding: .pkcs7) else {
            _MsgIntentLogInfo("[CallKit]: init aes error")
            completion?(false)
            return
        }

        let components = value.split(separator: "#")
        guard components.count >= 2,
              let data = Data(base64Encoded: String(components[1])),
              let decryptedData = decrypt(aes, data: data),
              let msgInfo = try? JSONDecoder().decode(MsgSendInfo.self, from: decryptedData)
        else {
            completion?(false)
            return
        }

        let meetingType = components.first ?? ""
        _MsgIntentLogInfo("[CallKit]: msg info \(msgInfo), type:\(meetingType), \(msgContent.hashValue)")
        guard !msgInfo.inviterID.isEmpty, !msgInfo.meetingID.isEmpty else {
            completion?(false)
            return
        }

        let isSingleMeeting = meetingType == "call" ? true : false
        var request = ServerPB_Videochat_RefuseReplyRequest()
        request.meetingID = msgInfo.meetingID
        request.refuseReply = msgContent
        request.inviterUserID = msgInfo.inviterID
        request.isSingleMeeting = isSingleMeeting

        let reqData = LarkNCExtensionUtils.generateHTTPBody(request: request, command: .refuseReply)
        HTTP.POSTForLark(data: reqData) { response in
            _MsgIntentLogInfo("RefuseReply")
            let isError = response.error != nil
            var replyDone = false
            if isError {
                _MsgIntentLogInfo("RefuseReply Failed, err: \(String(describing: response.error))")
            } else {
                do {
                    let replyResp = try ServerPB_Videochat_RefuseReplyResponse(serializedData: response.data)
                    _MsgIntentLogInfo("RefuseReply parsed, single: \(replyResp.hasSingleStatus)_\(replyResp.singleStatus), group: \(replyResp.hasGroupStatus)_\(replyResp.groupStatus)")
                    if isSingleMeeting, replyResp.hasSingleStatus {
                        replyDone = replyResp.singleStatus == .singleSuccess
                    } else if !isSingleMeeting, replyResp.hasGroupStatus {
                        replyDone = replyResp.groupStatus == .groupSuccess
                    }
                } catch(let err) {
                    _MsgIntentLogInfo("RefuseReply parse failed, err: \(String(describing: err))")
                }
                _MsgIntentLogInfo("RefuseReply Success, done: \(replyDone)")
            }
            completion?(!isError && replyDone)
        }
    }

    private static func decrypt(_ aes: AES, data: Data) -> Data? {
        guard let decrypted = try? aes.decrypt(data.bytes) else {
            return nil
        }
        return Data(decrypted)
    }
}
