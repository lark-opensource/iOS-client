//
//  DataService+utils.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/4/20.
//

import Foundation
import RustPB
import RxSwift
import ServerPB

extension DataService {

    func markMailRiskEvent(riskEvent: ServerPB_Mails_MailRiskEvent, params: [String: String]) -> Observable<()> {
        var req = ServerPB_Mails_UploadMailRiskEventRequest()
        req.event = riskEvent
        req.params = params
        return sendPassThroughAsyncRequest(req, serCommand: .mailRiskEventUpload)
            .observeOn(MainScheduler.instance).map { (resp: SendStatusByMessageIDResp) -> () in
                return ()
            }
    }
}
