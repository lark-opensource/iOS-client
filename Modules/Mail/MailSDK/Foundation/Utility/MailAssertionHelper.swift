//
//  MailAssertionHelper.swift
//  MailSDK
//
//  Created by bytedance on 2019/7/02.
//

import Foundation

enum MailAssertionType {
    case messageListSafeArea

    var message: String {
        switch self {
        case .messageListSafeArea:
            return "MailMessageList safeArea error"
        }
    }
}

func mailAssertionFailure(
    _ type: MailAssertionType,
    error: Error? = nil,
    ignoreLog: Bool = false, // 是否不上传埋点
    file: StaticString = #fileID,
    line: UInt = #line) {
        mailAssertionFailure(type.message, error: error, ignoreLog: ignoreLog, file: file, line: line)
    }

func mailAssertionFailure(
    _ message: String,
    error: Error? = nil,
    ignoreLog: Bool = false,
    file: StaticString = #fileID,
    line: UInt = #line) {
        assertionFailure()
        errorLog("Mail AssertionFailure \(message)", message: message, error: error,
                 ignoreLog: ignoreLog, file: file, line: line)
    }

private func errorLog(
    _ title: String,
    message: String,
    error: Error? = nil,
    ignoreLog: Bool = false, // 是否不上传埋点
    file: StaticString,
    line: UInt) {
        MailLogger.error(title, extraInfo: ["file": file, "line": line, "message": message], error: error)

        guard !ignoreLog else { return }
        // 埋点
        let event = MailAPMEventSingle.Assert()
        event.endParams.append(MailAPMEventSingle.Assert.EndParam.message(message))
        if let error = error {
            event.endParams.append(MailAPMEventSingle.Assert.EndParam.error_message("\(error)"))
        }
        event.endParams.append(MailAPMEventConstant.CommonParam.status_exception)
        event.markPostStart()
        event.postEnd()
    }
