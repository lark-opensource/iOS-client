//
//  DataService+Label.swift
//  MailSDK
//
//  Created by majx on 2019/10/30.
//

import Foundation
import RustPB
import RxSwift

extension DataService {
    func mailAddLabel(name: String, bgColor: String, fontColor: String, parentID: String?) -> Observable<Email_Client_V1_MailAddLabelResponse> {
        var request = Email_Client_V1_MailAddLabelRequest()
        request.labelName = name
        request.bgColor = bgColor
        request.fontColor = fontColor
        if let parentID = parentID {
            request.parentID = parentID
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailAddLabelResponse) -> Email_Client_V1_MailAddLabelResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailUpdateLabel(labelId: String, name: String, bgColor: String, fontColor: String, parentID: String, applyToAll: Bool) -> Observable<Email_Client_V1_MailUpdateLabelResponse> {
        var request = Email_Client_V1_MailUpdateLabelRequest()
        request.labelID = labelId
        request.labelName = name
        request.bgColor = bgColor
        request.fontColor = fontColor
        request.parentID = parentID
        request.applyToAllDescendants = applyToAll
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailUpdateLabelResponse) -> Email_Client_V1_MailUpdateLabelResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailDeleteLabel(labelId: String) -> Observable<Email_Client_V1_MailDeleteLabelResponse> {
        var request = Email_Client_V1_MailDeleteLabelRequest()
        request.labelID = labelId
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailDeleteLabelResponse) -> Email_Client_V1_MailDeleteLabelResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }
}
