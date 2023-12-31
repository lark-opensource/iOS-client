//
//  MailSendController+Doc.swift
//  MailSDK
//
//  Created by tanghaojin on 2023/4/20.
//

import Foundation
import LarkAlertController
import EENavigator
import RxSwift
import UniverseDesignToast
import UniverseDesignColor
import RustPB

enum MailDocFetchError: Error {
    /// 改造成用户容器后，原先注册到全局容器的服务为 nil 时都抛这个错误
    case initURLFail
    case JSONFormatFail
    case serviceFail
}

extension MailSendController: MailDocShareLinkVCDelegate {
    func checkDocLinkBeforeSend(mailContent: MailContent,
                                                nextStepHandler: @escaping (_ content: MailContent) -> Bool) {
        let directlySendBlock = {
            _ = nextStepHandler(mailContent)
        }
        let showAlertBlock = { [weak self] in
            guard let `self` = self else { return }
            // alert上报
            let event = NewCoreEvent(event: .email_doc_link_send_alert_view)
            event.params = ["mail_account_type": NewCoreEvent.accountType()]
            event.post()
            let cnt = self.noPermissionDocCnt()
            let title = BundleI18n.MailSDK.Mail_MobileLink_EnternalLinkSharing_Title
            let content = BundleI18n.MailSDK.Mail_MobileLink_ExternalLinkSharing_Desc(num: cnt)
            let alert = LarkAlertController()
            alert.setTitle(text: title)
            alert.setContent(text: content, alignment: .center)
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_LinkSharingOff_Enable_Button, dismissCompletion: {[weak self] in
                guard let `self` = self else { return }
                self.gotoShareLinkPage(sendHandler: nextStepHandler,
                                       content: mailContent)
            })
            alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_LinkSharingOff_Enable_SendDirectly_Button, dismissCompletion: {[weak self] in
                guard let `self` = self else { return }
                self.reportDocAlert(docsConfigs: mailContent.docsConfigs)
                _ = nextStepHandler(mailContent)
            })
            alert.addCancelButton()
            self.accountContext.navigator.present(alert, from: self)
        }
        needShowDocLinkAlert(urls: mailContent.docsConfigs.map{$0.docURL},
                             directlySendBlock: directlySendBlock,
                             showAlertBlock: showAlertBlock)
    }
    func gotoShareLinkPage(sendHandler: @escaping (_ content: MailContent) -> Bool,
                           content: MailContent) {
        let vc = MailDocShareLinkViewController(mailContent: content,
                                                accountContext: self.accountContext)
        vc.delegate = self
        vc.sendHandler = sendHandler
        var arrays = self.docInfoArray.values.getImmutableCopy().filter({ model in
            model.permission != .shareRead && model.permission != .shareEdit && model.manageCollaborator
        })
        vc.dataSource = arrays.sorted(by: { $0.sortNum < $1.sortNum })
        //docUrls要排序
        accountContext.navigator.push(vc, from: self)
    }
    func noPermissionDocCnt() -> Int {
        return self.docInfoArray.values.getImmutableCopy().filter({ model in
            model.permission != .shareRead && model.permission != .shareEdit && model.manageCollaborator
        }).count
    }
    func needShowDocLinkAlert(urls: [String],
                              directlySendBlock: @escaping () -> Void,
                              showAlertBlock: @escaping () -> Void) {
        if urls.count <= 0 {
            directlySendBlock()
            return
        }
        guard accountContext.featureManager.open(.docAuthOpt, openInMailClient: false) else {
            directlySendBlock()
            return
        }
        let netShareNotAllOpened =  self.docInfoArray.values.contains { model in
            model.permission != .shareRead &&
            model.permission != .shareEdit &&
            urls.contains(model.docUrl) &&
            model.manageCollaborator
        }
        if !netShareNotAllOpened {
            directlySendBlock()
            return
        }
        var array: [MailAddressCellViewModel] = []
        array.append(contentsOf: viewModel.sendToArray)
        array.append(contentsOf: viewModel.ccToArray)
        array.append(contentsOf: viewModel.bccToArray)
        let addressList = array.filter { model in
            !model.address.isEmpty
        }.map { model in
            model.address
        }
        MailDataServiceFactory.commonDataService?.checkExternal(addresses: addressList).subscribe(onNext: { (hasExtern) in
            if hasExtern {
                showAlertBlock()
            } else {
                directlySendBlock()
            }}, onError: { [weak self] (err) in
                guard let `self` = self else { return }
                MailLogger.info("checkExternal err = \(err)")
                if self.checkExternalTenant() {
                    showAlertBlock()
                } else {
                    directlySendBlock()
                }
            })
    }
    func showNoSharePermissionToast() {
        UDToast.showFailure(with: BundleI18n.MailSDK.Mail_LinkSharing_YouNeedPermissionShareDoc_Text,
                            on: self.view)
    }
    
    // 处理草稿中的doc链接
    func fetchDraftDocInfos(originUrls: [String]) {
        guard accountContext.featureManager.open(.docAuthOpt, openInMailClient: false) else { return }
        let urls = originUrls.filterDuplicates({ $0 })
        guard urls.count > 0 else { return }
        MailDataSource.shared.mailGetDocsPermModel(docsUrlStrings: urls, requestPermissions: true).subscribe(onNext: { [weak self] (resp) in
            guard let `self` = self else { return }
            let models = resp.docs
            var keepUrls: [String] = []
            // 处理正文区文档的权限
            for model in models.values {
                let manageCollaborator = model.userPerm.contains(.manageCollaborator)
                let shareModel = DocShareModel.init(title: model.name,
                                                    author: model.ownerName,
                                                    docType: model.objectType,
                                                    permission: .notShare,
                                                    manageCollaborator: manageCollaborator,
                                                    token: model.key,
                                                    docUrl: model.url)
                
                self.appendDocInfo(url: model.url, model: shareModel)
                // 没有协作权限的，需要设置为保持授权不变
                if !manageCollaborator {
                    keepUrls.append(model.url)
                }
            }
            // 处理无权限的内容
            var weakUrls: [String] = []
            weakUrls.append(contentsOf: resp.noPermUrls)
            weakUrls.append(contentsOf: resp.deletedUrls)
            if weakUrls.count > 0 {
                if let data = try? JSONSerialization.data(withJSONObject: weakUrls, options: []),
                   let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    let jsStr = "window.command.disableDocBlock(\(JSONString))"
                    self.requestEvaluateJavaScript(jsStr, completionHandler: nil)
                }
            }
            // 处理需要保持keep action的内容
            if keepUrls.count > 0 {
                if let data = try? JSONSerialization.data(withJSONObject: keepUrls, options: []),
                   let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                    let jsStr = "window.command.setDocActionKeep(\(JSONString))"
                    self.requestEvaluateJavaScript(jsStr, completionHandler: nil)
                }
            }
            }, onError: { (error) in
                MailLogger.error("fetchDraftDocInfos fail \(error)")
        }).disposed(by: disposeBag)
    }
    
    func appendDocInfo(url: String, model: DocShareModel) {
        guard accountContext.featureManager.open(.docAuthOpt, openInMailClient: false) else { return }
        var copyModel = model
        copyModel.sortNum = docInfoArray.keys.count + 1
        docInfoArray[url] = copyModel
        // 发起http请求
        self.fetchPublicPermission(model: model).subscribe(onNext: { [weak self] (resModel) in
            guard let `self` = self else { return }
            //发起第二个http请求
            self.processChangePermission(url: url, model: resModel)
        }, onError: { [weak self] (_) in
            guard let `self` = self else { return }
            //请求失败默认为不可分享
            if var originModel = self.docInfoArray[url] {
                originModel.forbidReason = BundleI18n.MailSDK.Mail_LinkSharing_UnableToEnableExternalSharing_CheckSettings_Tooltip
                self.replaceDocInfo(url: url, model: originModel)
            }
        }).disposed(by: disposeBag)
    }
    func replaceDocInfo(url: String, model: DocShareModel) {
        if self.docInfoArray[url] != nil {
            var copyModel = model
            copyModel.sortNum = self.docInfoArray[url]?.sortNum ?? Int.max
            self.docInfoArray[url] = copyModel
        }
    }
    func processChangePermission(url: String, model: DocShareModel) {
        if !model.forbidReason.isEmpty {
            replaceDocInfo(url: url, model: model)
        } else {
            self.fetchManagerMeta(model: model).subscribe(onNext: { [weak self] (value) in
                guard let `self` = self else { return }
                var copyModel = model
                copyModel.changePermission = value
                if !value {
                    copyModel.forbidReason = BundleI18n.MailSDK.Mail_LinkSharing_UnableToEnableExternalSharing_CheckSettings_Tooltip
                }
                self.replaceDocInfo(url: url, model: copyModel)
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                self.replaceDocInfo(url: url, model: model)
            }).disposed(by: disposeBag)
        }
    }
    func genShareAction(value: Int) -> Email_Client_V1_DocsPermissionConfig.ShareLinkAction {
        if value == 5 {
            return .shareEdit
        } else if value == 4 {
            return .shareRead
        }
        return .notShare
    }
    
    // 是否可选择互联网可编辑&互联网可阅读的选项
    func fetchManagerMeta(model: DocShareModel) -> Observable<Bool> {
        var req = SendHttpRequest()
        req.url = MailDriveAPI.driveFetchStateActionURL(provider: serviceProvider?.provider.configurationProvider)
        
        req.method = .post
        var header: [String: String] = [:]
        let session = accountContext.user.token ?? ""
        let sessionStr = "session=" + session
        header["Cookie"] = sessionStr
        req.headers = header
        var json: [String: Any] = [:]
        json["token"] = model.token
        json["type"] = model.docType.rawValue
        json["actions"] = ["manage_meta", "manage_single_page_meta"]
        guard let body = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            MailLogger.info("fetchManagerMeta json transform fail")
            return Observable.error(MailDocFetchError.JSONFormatFail)
        }
        req.body = body
        req.retryNum = 3
        if let service = MailDataServiceFactory.commonDataService {
            return service.sendHttpRequest(req: req)
                .observeOn(MainScheduler.instance)
                .map { (resp: SendHttpResponse) -> Bool in
                    guard let json = try? JSONSerialization.jsonObject(with: resp.body, options: []) else {
                        MailLogger.info("fetchManagerMeta parse resp json fail")
                        return false
                    }
                    guard let strJson = json as? [String: Any] else {
                        MailLogger.info("fetchManagerMeta to stringJson fail")
                        return false
                    }
                    guard let dataMap = strJson["data"] as? [String: Any] else {
                        MailLogger.info("fetchManagerMeta to dataMap fail")
                        return false
                    }
                    guard let actions = dataMap["actions"] as? [String: Any] else {
                        MailLogger.info("fetchPublicPermission to permPublic fail")
                        return false
                    }
                    var managerMeta = false
                    var managerSinglePageMeta = false
                    if let meta = actions["manage_meta"] as? Int, meta == 1 {
                        managerMeta = true
                    }
                    if let meta = actions["manage_single_page_meta"] as? Int, meta == 1 {
                        managerSinglePageMeta = true
                    }
                    return managerMeta || managerSinglePageMeta
                }
        } else {
            return Observable.error(MailDocFetchError.serviceFail)
        }
    }
    
    private func reasonMap(value: Int) -> String {
        if value == 1 {
            return BundleI18n.MailSDK.Mail_LinkSharing_WikiSharingDisabled_ContactHelp_Tooltip
        } else if value == 3 {
            return BundleI18n.MailSDK.Mail_LinkSharing_DocsSharingDisabled_ConactHelp_Tooltip
        } else if value == 4 {
            return BundleI18n.MailSDK.Mail_LinkSharing_OrgSharingPermissionOff_ContacHelp_Tooltip
        } else if value == 5 {
            return BundleI18n.MailSDK.Mail_LinkSharing_DocsSharingDisabled_ConactHelp_Tooltip
        } else {
            return BundleI18n.MailSDK.Mail_LinkSharing_UnableToEnableExternalSharing_CheckSettings_Tooltip
        }
    }
    //link_share_entity_v2
    func fetchPublicPermission(model: DocShareModel) -> Observable<DocShareModel> {
        var req = SendHttpRequest()
        req.url = MailDriveAPI.driveFetchPermissionURL(provider: serviceProvider?.provider.configurationProvider,
                                                       token: model.token,
                                                       type: model.docType.rawValue)
        func genDefaultPerm(model: DocShareModel) -> DocShareModel {
            var resModel = model
            resModel.permission = .notShare
            resModel.changePermission = false
            resModel.forbidReason = BundleI18n.MailSDK.Mail_LinkSharing_UnableToEnableExternalSharing_CheckSettings_Tooltip
            return resModel
        }
        func genDefaultWithAction(model: DocShareModel,
                                  action: Email_Client_V1_DocsPermissionConfig.ShareLinkAction, shareOutside: Bool) -> DocShareModel {
            if !shareOutside {
                var perm = genDefaultPerm(model: model)
                perm.forbidReason = BundleI18n.MailSDK.Mail_LinkSharing_DocsSharingDisabled_ConactHelp_Tooltip
                return perm
            }
            var resModel = model
            resModel.permission = action
            return resModel
        }
        req.method = .get
        let session = accountContext.user.token ?? ""
        var header: [String: String] = [:]
        let sessionStr = "session=" + session
        header["Cookie"] = sessionStr
        req.headers = header
        req.retryNum = 3
        if let service = MailDataServiceFactory.commonDataService {
            return service.sendHttpRequest(req: req)
                .observeOn(MainScheduler.instance)
                .map { [weak self] (resp: SendHttpResponse) -> DocShareModel in
                    guard let `self` = self else { return genDefaultPerm(model: model) }
                    guard let json = try? JSONSerialization.jsonObject(with: resp.body, options: []) else {
                        MailLogger.info("fetchPublicPermission parse resp json fail")
                        return genDefaultPerm(model: model)
                    }
                    guard let strJson = json as? [String: Any] else {
                        MailLogger.info("fetchPublicPermission to stringJson fail")
                        return genDefaultPerm(model: model)
                    }
                    guard let dataMap = strJson["data"] as? [String: Any] else {
                        MailLogger.info("fetchPublicPermission to dataMap fail")
                        return genDefaultPerm(model: model)
                    }
                    guard let permPublic = dataMap["perm_public"] as? [String: Any] else {
                        MailLogger.info("fetchPublicPermission to permPublic fail")
                        return genDefaultPerm(model: model)
                    }
                    guard let shareOutside = permPublic["external_access_switch"] as? Bool else {
                        MailLogger.info("fetchPublicPermission to external_access_switch fail")
                        return genDefaultPerm(model: model)
                    }
                    guard let action = permPublic["link_share_entity_v2"] as? Int else {
                        MailLogger.info("fetchPublicPermission to linkShareEntityV2 fail")
                        var perm = genDefaultPerm(model: model)
                        if !shareOutside {
                            perm.forbidReason = BundleI18n.MailSDK.Mail_LinkSharing_DocsSharingDisabled_ConactHelp_Tooltip
                        }
                        return perm
                    }
                    let shareAction = self.genShareAction(value: action)
                    guard let options = permPublic["block_options"] as? [String: Any] else {
                        return genDefaultWithAction(model: model,
                                                    action: shareAction,
                                                    shareOutside: shareOutside)
                    }
                    guard let reasons = options["external_access_switch"] as? [[String: Any]] else {
                        return genDefaultWithAction(model: model,
                                                    action: shareAction,
                                                    shareOutside: shareOutside)
                    }
                    //
                    if reasons.isEmpty {
                        return genDefaultWithAction(model: model,
                                                    action: shareAction,
                                                    shareOutside: shareOutside)
                    }
                    guard let reason = reasons.first?["block_type"] as? Int else {
                        return genDefaultWithAction(model: model,
                                                    action: shareAction,
                                                    shareOutside: shareOutside)
                    }
                    var resModel = genDefaultWithAction(model: model,
                                                        action: shareAction,
                                                        shareOutside: true)
                    resModel.forbidReason = self.reasonMap(value: reason)
                    return resModel
                }
        } else {
            return Observable.error(MailDocFetchError.serviceFail)
        }
    }
    func docPageSendMail(models: [DocShareModel],
                         sendHandler: ((_ content: MailContent) -> Bool)?,
                         content: MailContent) {
        // update docInfoArray
        models.forEach { model in
            if var info = self.docInfoArray[model.docUrl] {
                info.permission = model.permission
                docInfoArray[model.docUrl] = info
            }
        }
        var copyContent = content
        copyContent.docsConfigs = copyContent.docsConfigs.map { config in
            if let model = models.first(where: {$0.docUrl == config.docURL}) {
                var copy = config
                copy.shareLinkAction = model.permission
                return copy
            } else {
                return config
            }
        }
        self.reportDocAlert(docsConfigs: copyContent.docsConfigs)
        _ = sendHandler?(copyContent)
    }

    func reportDocAlert(docsConfigs: [MailClientDocsPermissionConfig]) {
        var linkDeny = 0, linkRead = 0, linkEdit = 0
        for config in docsConfigs {
            if let doc = self.docInfoArray[config.docURL] {
                if doc.permission == .notShare {
                    linkDeny = linkDeny + 1
                } else if doc.permission == .shareRead {
                    linkRead = linkRead + 1
                } else if doc.permission == .shareEdit {
                    linkEdit = linkEdit + 1
                }
            } else {
                if config.shareLinkAction == .notShare {
                    linkDeny = linkDeny + 1
                } else if config.shareLinkAction == .shareRead {
                    linkRead = linkRead + 1
                } else if config.shareLinkAction == .shareEdit {
                    linkEdit = linkEdit + 1
                }
            }
        }
        let event = NewCoreEvent(event: .email_doc_link_send_alert_click)
        event.params = ["target": "none",
                        "click": "confirm_send",
                        "link_deny": linkDeny,
                        "link_read": linkRead,
                        "link_edit": linkEdit,
                        "mail_account_type": NewCoreEvent.accountType()]
        event.post()
    }
}
