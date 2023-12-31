//
//  DataService+IM.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/9/25.
//

import Foundation
import RxSwift
import RustPB

extension DataService {
    func createMsgShareDraft(msgID: String,
                             threadID: String,
                             action: Email_Client_V1_MailCreateDraftRequest.CreateDraftAction) ->
    Observable<Email_Client_V1_MailCreateShareMessageDraftResponse> {
        var request = Email_Client_V1_MailCreateShareMessageDraftRequest()
        request.messageID = msgID
        request.threadID = threadID
        request.action = action
        return sendAsyncRequest(request, transform: { (res: Email_Client_V1_MailCreateShareMessageDraftResponse) in
            return res
        }).observeOn(MainScheduler.instance)
    }
}
