//
//  MailUnsubscribeManager.swift
//  MailSDK
//
//  Created by Fawaz Tahir on 2020/10/2.
//

import Foundation
import RxSwift
import RustPB

enum MailUnsubscribeState {
    case hide
    case subscribedMailTo
    case subscribedOneClick
    case subscribedRedirect(String)
}

class MailUnsubscribeManager {

    enum MailUnsubscribeError: Error {
        case unsubscribePostFailure
    }

    static func shouldShowUnsubscribeMenu(for messageItem: MailMessageItem) -> Bool {
        switch unsubscribeState(for: messageItem) {
        case .hide:
            return false
        case .subscribedMailTo, .subscribedOneClick, .subscribedRedirect:
            return true
        }
    }

    static func unsubscribeState(for mail: MailMessageItem) -> MailUnsubscribeState {
        switch mail.message.unsubscribeOption.unsubscribeType {
        case .none: return .hide
        case .mailto: return .subscribedMailTo
        case .oneClick: return .subscribedOneClick
        case .redirect: return .subscribedRedirect(mail.message.unsubscribeOption.redirectedURL)
        @unknown default: return .hide
        }
    }

    static func unsubscribe(for messageId: String, in threadId: String) -> Observable<Email_Client_V1_MailUnsubscribeResponse> {
        guard let service = MailDataServiceFactory.commonDataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return service.unsubscribeMessage(id: messageId, threadID: threadId)
            .do(onError: { error in
                MailLogger.error("unsubscribe request failed", error: error)
            })
            .flatMap({ (response) -> Observable<Email_Client_V1_MailUnsubscribeResponse> in
                MailLogger.info("unsubscribe request succ")
                switch response.result {
                case .succeed:
                    MailLogger.info("unsubscribe succ")
                    return Observable.just(response)
                case .notSupport:
                    MailLogger.info("unsubscribe failed")
                    return Observable.error(MailUnsubscribeError.unsubscribePostFailure)
                @unknown default:
                    MailLogger.info("unsubscribe unknown response")
                    return Observable.error(MailUnsubscribeError.unsubscribePostFailure)
                }
            })
    }
}
