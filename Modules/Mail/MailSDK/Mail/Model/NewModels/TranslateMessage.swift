//
//  TranslateMessage.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/6/1.
//

import Foundation

enum TranslateMessageResult: Int {
    case succeed = 0
    case notSupport
    case sameLanguage
    case blobDetected
    case backendError
    case partialSupport
    case ignored
}

struct TranslateMessage {
    let threadId: String
    let messageId: String
    let translatedSubject: String
    let translatedBodyPlainText: String
    var translatedBody: String
    let result: TranslateMessageResult
    let sourceLans: [String]
    let showOriginalText: Bool
}
