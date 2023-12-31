//
//  InMeetKeyManager.swift
//  ByteView
//
//  Created by ZhangJi on 2023/4/28.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewSetting

extension InMeetMeeting {
    /// 判断端到端加密会议
    var isE2EeMeeing: Bool {
        self.inMeetKeyManager != nil
    }
    /// 会中秘钥
    var inMeetingKey: InMeetingKey? {
        self.inMeetKeyManager?.inMeetingKey
    }
}

final class InMeetKeyManager {
    private let session: MeetingSession
    private(set) var inMeetingKey: InMeetingKey

    private var chatEncryptErrors: [Int: Int] = [:]
    private var chatDecryptErrors: [Int: Int] = [:]

    init(session: MeetingSession, e2EeKey: E2EEKey? = nil) {
        self.session = session
        if let e2EeKey = e2EeKey, let meetingKey = e2EeKey.meetingKey {
            // videoChatInfo有key就使用videoChatInfo的key
            if let oldKey = session.inMeetingKey, oldKey.e2EeKey.meetingKey != meetingKey {
                // 收到的秘钥与本端不一致
                E2EeTracks.trackMeetingKeyStatus()
            }
            self.inMeetingKey = InMeetingKey.createMeetingKeyWith(e2EeKey: e2EeKey)
        } else {
            // videoChatInfo没有key,看session是否创建过key,没有再创建
            self.inMeetingKey = session.inMeetingKey ?? InMeetingKey.createMeetingKeyBy(account: session.account)
        }
        session.isE2EeMeeting = true
        session.inMeetingKey = self.inMeetingKey
        Logger.getLogger("meeting_key").info("init InMeetKeyManager with key: \(self.inMeetingKey)")

        session.push?.meetingKeyExchange.addObserver(self) { [weak self] in
            self?.didReceiveMeetingKeyExchange($0)
        }
    }

    deinit {
        E2EeTracks.trackEncryptErrors(encryptErrors: chatEncryptErrors, decryptErrors: chatDecryptErrors, type: .chat)
    }

    func didReceiveMeetingKeyExchange(_ exchangePush: PushE2EEKeyExchange) {
        let request = SendE2EEKeyExchangeRequest(exchangePush: exchangePush, key: inMeetingKey.e2EeKey)
        session.httpClient.send(request)
    }

    func handleEncryptError(_ errorCode: Int, type: E2EeTracks.EncryptType, isEncrypt: Bool) {
        guard type == .chat else { return }
        if isEncrypt {
            if let count = chatEncryptErrors[errorCode] {
                chatEncryptErrors[errorCode] = count + 1
            } else {
                chatEncryptErrors[errorCode] = 1
            }
        } else {
            if let count = chatDecryptErrors[errorCode] {
                chatDecryptErrors[errorCode] = count + 1
            } else {
                chatDecryptErrors[errorCode] = 1
            }
        }
    }
}

struct InMeetingKey {
    private(set) var encryptAlgorithm: EncryptAlgorithnm
    private(set) var e2EeKey: E2EEKey
    private(set) var length: Int

    static func createMeetingKeyBy(account: ByteviewUser, encryptAlgorithm: EncryptAlgorithnm = .aes256Gcm) -> InMeetingKey {
        let length = lark_sdk_resource_encrypt_aead_key_len(encryptAlgorithm.rustValue)
        let point = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
        lark_sdk_resource_encrypt_key_fill(point, length)
        let key = Data(bytesNoCopy: point, count: length, deallocator: .custom{
            lark_sdk_resource_encrypt_free_buf($0.bindMemory(to: UInt8.self, capacity: $1), $1)
        })
        let e2EeKey = E2EEKey(version: 0, issuer: account, meetingKey: key)
        Logger.getLogger("meeting_key").info("create meeting key: \(e2EeKey), encryptAlgorithm: \(encryptAlgorithm)")
        return InMeetingKey(encryptAlgorithm: encryptAlgorithm, e2EeKey: e2EeKey, length: length)
    }

    static func createMeetingKeyWith(e2EeKey: E2EEKey, encryptAlgorithm: EncryptAlgorithnm = .aes256Gcm) -> InMeetingKey {
        let length = lark_sdk_resource_encrypt_aead_key_len(encryptAlgorithm.rustValue)
        return InMeetingKey(encryptAlgorithm: encryptAlgorithm, e2EeKey: e2EeKey, length: length)
    }
}

enum EncryptAlgorithnm: Int {
    case chaCha20Poly1305 = 1
    case aes256Gcm

    var rustValue: ResourceEncryptAlgorithm {
        return ResourceEncryptAlgorithm(rawValue: UInt32(self.rawValue))
    }
}
