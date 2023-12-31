//
//  DataService+Undo.swift
//  MailSDK
//
//  Created by majx on 2020/8/26.
//

import Foundation
import RustPB
import RxSwift

extension DataService {
    func undoMailAction(by uuid: String, feedCardID: String?) -> Observable<(Email_Client_V1_MailUndoResponse)> {
        var req = Email_Client_V1_MailUndoRequest()
        req.uuid = uuid
        if let feedCardID = feedCardID {
            req.feedCardID = feedCardID
        }
        return sendAsyncRequest(req).map({ (resp: Email_Client_V1_MailUndoResponse) -> Email_Client_V1_MailUndoResponse in
            return resp
        }).observeOn(MainScheduler.instance)
    }
}
