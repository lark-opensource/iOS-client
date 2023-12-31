//
//  TimeFormatProxy.swift
//  MailSDK
//
//  Created by majx on 2020/8/24.
//

import Foundation

public protocol TimeFormatProxy {
    func relativeDate(_ timestamp: Int64, showTime: Bool) -> String
    func mailDraftTimeFormat(_ timestamp: Int64, languageId: String?) -> String
    func mailScheduleSendTimeFormat(_ timestamp: Int64) -> String
    func mailAttachmentTimeFormat(_ timestamp: Int64) -> String
    func mailSendStatusTimeFormat(_ timestamp: Int64) -> String
    func mailLargeAttachmentTimeFormat(_ timestamp: Int64) -> String
    func mailReadReceiptTimeFormat(_ timestamp: Int64, languageId: String?) -> String
}
