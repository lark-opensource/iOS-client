//
//  MailEditLabelsViewModel.swift
//  MailSDK
//
//  Created by majx on 2019/10/28.
//

import Foundation
import RxSwift
import RustPB

struct MailManageLabelsDataSource {
    static let `default` = MailManageLabelsDataSource()
    private var dataService: DataService? = MailDataServiceFactory.commonDataService
    private var disposeBag = DisposeBag()

    func addLabel(name: String, bgColor: String, fontColor: String, parentID: String?) -> Observable<Email_Client_V1_MailAddLabelResponse> {
        guard let dataService = dataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.mailAddLabel(name: name, bgColor: bgColor.lowercased(), fontColor: fontColor.lowercased(), parentID: parentID)
    }

    func deleteLabel(labelId: String) -> Observable<Email_Client_V1_MailDeleteLabelResponse> {
        guard let dataService = dataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.mailDeleteLabel(labelId: labelId)
    }

    func updateLabel(labelId: String, name: String, bgColor: String, fontColor: String, parentID: String, applyToAll: Bool) -> Observable<Email_Client_V1_MailUpdateLabelResponse> {
        guard let dataService = dataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.mailUpdateLabel(labelId: labelId, name: name, bgColor: bgColor.lowercased(), fontColor: fontColor.lowercased(), parentID: parentID, applyToAll: applyToAll)
    }
}

struct MailManageFolderDataSource {
    static let `default` = MailManageFolderDataSource()
    private var dataService: DataService? = MailDataServiceFactory.commonDataService
    private var disposeBag = DisposeBag()

    func addFolder(name: String, parentID: String?) -> Observable<Email_Client_V1_MailAddFolderResponse> {
        guard let dataService = dataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.mailAddFolder(name: name, parentID: parentID)
    }

    func deleteFolder(folderID: String) -> Observable<Email_Client_V1_MailDeleteFolderResponse> {
        guard let dataService = dataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.mailDeleteFolder(folderID: folderID)
    }

    func updateFolder(folderID: String, name: String, parentID: String?, orderIndex: Int64?) ->
    Observable<Email_Client_V1_MailUpdateFolderResponse> {
        guard let dataService = dataService else {
            return Observable.error(MailUserLifeTimeError.serviceDisposed)
        }
        return dataService.mailUpdateFolder(folderID: folderID, name: name, parentID: parentID, orderIndex: orderIndex)
    }
}
