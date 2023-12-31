//
//  DataService+Schedule.swift
//  MailSDK
//
//  Created by majx on 2020/12/5.
//

import Foundation
import RustPB
import RxSwift

extension DataService {
    func cancelScheduleSend(by messageId: String?, threadIds: [String], feedCardID: String?) -> Observable<(Email_Client_V1_MailCancelScheduleSendResponse)> {
        var req = Email_Client_V1_MailCancelScheduleSendRequest()
        req.threadIds = threadIds
        if let msgId = messageId {
            req.messageID = msgId
        }
        if let feedCardID = feedCardID {
            req.feedCardID = feedCardID
        }
        return sendAsyncRequest(req).map({ (resp: Email_Client_V1_MailCancelScheduleSendResponse) -> Email_Client_V1_MailCancelScheduleSendResponse in
            return resp
        }).observeOn(MainScheduler.instance)
    }

    func getScheduleSendMessageCount() -> Observable<(Email_Client_V1_MailGetScheduleMessageCountResponse)> {
        let req = Email_Client_V1_MailGetScheduleMessageCountRequest()
        return sendAsyncRequest(req).map({ (resp: Email_Client_V1_MailGetScheduleMessageCountResponse) -> Email_Client_V1_MailGetScheduleMessageCountResponse in
            return resp
        }).observeOn(MainScheduler.instance)
    }
}
