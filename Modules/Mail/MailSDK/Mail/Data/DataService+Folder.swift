//
//  DataService+Folder.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/12/14.
//

import Foundation
import RustPB
import RxSwift

extension DataService {
    func mailAddFolder(name: String, parentID: String?) -> Observable<Email_Client_V1_MailAddFolderResponse> {
        var request = Email_Client_V1_MailAddFolderRequest()
        request.folderName = name
        if let parentID = parentID, parentID != Mail_FolderId_Root, !parentID.isEmpty {
            request.parentID = parentID
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailAddFolderResponse) -> Email_Client_V1_MailAddFolderResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailUpdateFolder(folderID: String, name: String, parentID: String?, orderIndex: Int64?) -> Observable<Email_Client_V1_MailUpdateFolderResponse> {
        var request = Email_Client_V1_MailUpdateFolderRequest()
        request.folderID = folderID
        request.folderName = name
        if let parentID = parentID, !parentID.isEmpty {
            request.parentID = parentID
        }
        if let orderIndex = orderIndex {
            request.orderIndex = orderIndex
        }
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailUpdateFolderResponse) -> Email_Client_V1_MailUpdateFolderResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func mailDeleteFolder(folderID: String) -> Observable<Email_Client_V1_MailDeleteFolderResponse> {
        var request = Email_Client_V1_MailDeleteFolderRequest()
        request.folderID = folderID
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailDeleteFolderResponse) -> Email_Client_V1_MailDeleteFolderResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }

    func searchInWhichFolder(messageIds: [String]) -> Observable<Email_Client_V1_MailSearchInWhichFolderResponse> {
        var request = Email_Client_V1_MailSearchInWhichFolderRequest()
        request.messageIds = messageIds
        return sendAsyncRequest(request, transform: { (response: Email_Client_V1_MailSearchInWhichFolderResponse) -> Email_Client_V1_MailSearchInWhichFolderResponse in
            return response
        }).observeOn(MainScheduler.instance)
    }
}
