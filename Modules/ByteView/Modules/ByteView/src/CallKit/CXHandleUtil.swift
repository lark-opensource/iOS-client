//
//  CXHandleUtil.swift
//  ByteView
//
//  Created by kiri on 2023/6/16.
//

import Foundation
import CryptoSwift
import CallKit
import Intents
import ByteViewCommon
import ByteViewTracker
import ByteViewUI
import ByteViewNetwork

/// 如果修改 CallKitInfo 相关的，请注意 LarkNotificationContentExtensionSDK/LarkNCEMsgIntentProcessor 中也有一样的配置，需要同步修改
private struct CXHandleInfo: Codable {
    let meetingID: String
    let userID: String
    let inviterID: String
}

final class CXHandleUtil {
    static func updateHandle(_ callUpdate: CXCallUpdate, userId: String, meetingId: String, meetingType: MeetingType, inviterId: String) {
        let info = CXHandleInfo(meetingID: meetingId, userID: userId, inviterID: inviterId)
        if let value = CXHandleCryptor.shared?.makeHandle(meetingType: meetingType == .call ? "call" : "meet", info: info) {
            callUpdate.remoteHandle = CXHandle(type: .generic, value: value)
        }
    }

    /// - returns: meetingId
    static func processPersonHandle(_ handle: INPersonHandle?, currentUserId: String?, shuldShowAlert: Bool = true) -> String? {
        guard let userId = currentUserId, !userId.isEmpty else {
            Logger.callKit.info("processPersonHandle cancelled, currentUserId is nil")
            if shuldShowAlert {
                ByteViewDialog.Builder()
                    .title(I18n.View_MV_AccountError_UnlogPopUpTitle)
                    .message(I18n.View_MV_PleaseLogIn_PopUpExplain)
                    .rightTitle(I18n.View_MV_GotIt_PleaseLogPopUpButton)
                    .rightHandler({ _ in
                        VCTracker.post(name: .vc_meeting_popup_click, params: [.click: "known", .content: "callkit_wrong_login"])
                    })
                    .show()
                VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "callkit_wrong_login"])
            }
            return nil
        }

        guard let handle = handle, handle.type == .unknown, let data = handle.value,
                let info = CXHandleCryptor.shared?.decodeHandle(data) else {
            Logger.callKit.info("processPersonHandle failed, decode INPersonHandle error, hasHandle: \(handle != nil)")
            return nil
        }
        Logger.callKit.info("processPersonHandle success, meetingId: \(info.meetingID), decodedUserId: \(info.userID), currentUserId: \(userId)")
        if info.userID != userId {
            if shuldShowAlert {
                ByteViewDialog.Builder()
                    .title(I18n.View_MV_AccountError_PopUpTitle)
                    .message(I18n.View_MV_SwitchAccountDetail_PopUpExplain)
                    .rightTitle(I18n.View_MV_GotIt_SwitchAccountPopUpButton)
                    .rightHandler({ _ in
                        VCTracker.post(name: .vc_meeting_popup_click,
                                       params: [.click: "known", .content: "callkit_wrong_tenant"])
                    })
                    .show()
                VCTracker.post(name: .vc_meeting_popup_view, params: [.content: "callkit_wrong_tenant"])
            }
            return nil
        } else {
            return info.meetingID
        }
    }
}

private final class CXHandleCryptor {
    static let shared = CXHandleCryptor()

    /// 如果修改 aes 相关的，请注意 LarkNotificationContentExtensionSDK/LarkNCEMsgIntentProcessor 中也有一样的配置，需要同步修改
    private static let aesKey = "CallJumpToDetail"
    private let aes: AES
    init?() {
        guard let aes = try? AES(key: Self.aesKey.bytes, blockMode: ECB(), padding: .pkcs7) else {
            return nil
        }
        self.aes = aes
    }

    func makeHandle(meetingType: String, info: CXHandleInfo) -> String? {
        guard let data = try? JSONEncoder().encode(info),
              let encryptedIdentifier = encrypt(data: data)?.base64EncodedString() else {
            return nil
        }

        return "\(meetingType)#\(encryptedIdentifier)"
    }

    func decodeHandle(_ data: String) -> CXHandleInfo? {
        let components = data.split(separator: "#")
        guard components.count >= 2,
              let data = Data(base64Encoded: String(components[1])),
              let decryptedData = decrypt(data: data),
              let identifier = try? JSONDecoder().decode(CXHandleInfo.self, from: decryptedData) else {
            return nil
        }
        return identifier
    }

    private func encrypt(data: Data) -> Data? {
        guard let encrypted = try? aes.encrypt(data.bytes) else {
            return nil
        }
        return Data(encrypted)
    }

    private func decrypt(data: Data) -> Data? {
        guard let decrypted = try? aes.decrypt(data.bytes) else {
            return nil
        }
        return Data(decrypted)
    }
}
