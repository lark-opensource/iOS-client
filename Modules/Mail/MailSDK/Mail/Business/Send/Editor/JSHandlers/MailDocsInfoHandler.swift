//
//  MailDocsInfoHandler.swift
//  MailSDK
//
//  Created by zhongtianren on 2019/9/5.
//

import UIKit
import RxSwift
import LKCommonsLogging
import EENavigator
import WebKit
import LarkGuideUI
import RustPB
import ServerPB
import UniverseDesignActionPanel

enum DocsPerm: String {
    case read = "1"
    case edit = "4"
    case manage = "8"
}

enum CollaOpType: String {
    case subject = "subject"
    case to = "to"
    case cc = "cc"
    case bcc = "bcc"
    case from = "from"
    case attachment = "attachments"
}

protocol MailDocsInfoDelegate: AnyObject {
    func requestEvaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?)
    func currentViewController() -> UIViewController
    func getDocsInfo(url: String) -> MailClientDocsPermissionConfig?
    func currentAttachments() -> [MailSendAttachment]
    func setSubject(_ subject: String)
    func removeAddress(index: Int)
    func updateAddress(addressModels: [MailAddressCellViewModel], type: CollaOpType)
    func getWebview() -> WKWebView
    func resignEditorFocus()
    func showNoSharePermissionToast()
    func appendDocInfo(url: String, model: DocShareModel)
    func fetchDraftDocInfos(originUrls: [String])
    func editorAIClick()
}

extension EditorJSService {
    static let fetchDocs = EditorJSService(rawValue: "biz.mail.fetchDocs")
    static let clickDocsPerm = EditorJSService(rawValue: "biz.mail.clickDocsPermission")
    static let fetchDocsPermInfo = EditorJSService(rawValue: "biz.mail.fetchDocsPermInfo")
    static let collaOnUpdate = EditorJSService(rawValue: "biz.collaboration.on.update")
    static let emailAddress = EditorJSService(rawValue: "biz.core.getCurrentEmailAddress")
    static let searchAtUser = EditorJSService(rawValue: "biz.mail.searchAtUser")
    static let draftDocUrls = EditorJSService(rawValue: "biz.mail.getDocsUrl")
    static let expandQuote = EditorJSService(rawValue: "biz.mail.expandHistoryQuote")
    static let callAI = EditorJSService(rawValue: "biz.mail.doAiCompletion")
}

struct DocsCallBackModel {
    let url: String
    let callback: String
}

class MailDocsInfoHandler: EditorJSServiceHandler {
    private static let logger = Logger.log(MailHomeController.self, category: "Module.MailDocsInfoHandler")
    weak var delegate: MailDocsInfoDelegate?
    let disposeBag = DisposeBag()
    private var pendingRequestWorkItem: DispatchWorkItem?
    var callbackModels = [DocsCallBackModel]()

    internal var handleServices: [EditorJSService] = [.fetchDocs,
                                                      .clickDocsPerm,
                                                      .fetchDocsPermInfo,
                                                      .searchAtUser,
                                                      .draftDocUrls,
                                                      .expandQuote,
        .callAI]

    func handle(params: [String: Any], serviceName: String) {
        if serviceName == EditorJSService.fetchDocs.rawValue {
            handleFetchDocsEvent(params)
        } else if serviceName == EditorJSService.clickDocsPerm.rawValue {
            handleClickDocsPerm(params)
        } else if serviceName == EditorJSService.fetchDocsPermInfo.rawValue {
            fetchDocsPermInfo(params)
        } else if serviceName == EditorJSService.searchAtUser.rawValue {
            handleSearchAtUser(params)
        } else if serviceName == EditorJSService.draftDocUrls.rawValue {
            handleDraftUrls(params)
        } else if serviceName == EditorJSService.expandQuote.rawValue {
            handleExpandQuote()
        } else if serviceName == EditorJSService.callAI.rawValue {
            handleCallAI()
        }
    }
    func handleDraftUrls(_ params: [String: Any]) {
        guard let docInfo = params["links"] as? [[String: Any]] else {
            MailLogger.info("handleDraftUrls parse err")
            return
        }
        var textLinks: [String] = []
        docInfo.forEach { item in
            if let url = item["docUrl"] as? String {
                textLinks.append(url)
            }
        }
        self.delegate?.fetchDraftDocInfos(originUrls: textLinks)
    }
    func handleExpandQuote() {
        if FeatureManager.open(.docAuthOpt, openInMailClient: false) {
            let jsStr = "window.command.fetchDocBlockUrls()"
            self.delegate?.requestEvaluateJavaScript(jsStr, completionHandler: nil)
        }
    }

    func handleSearchAtUser(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String,
                let userId = params["userId"] as? String ,
                let userName = params["username"] as? String else { mailAssertionFailure("unexpected type for callback"); return }
        _ = MailDataServiceFactory.commonDataService?.mailAtContactSearch(keyword: userName, session: "").subscribe(onNext: { [weak self] (list, _) in
            guard let `self` = self else { return }
            let useCn =  BundleI18n.currentLanguage.languageIdentifier.lowercased().contains("zh-")
            for info in list where info.userID == userId {
                let resp = [["address": info.emailAddress,
                             "username": useCn ? info.cnName : info.enName,
                              "userId": info.userID,
                              "department": info.department,
                              "avatar": info.avatarKey]]
                guard let data = try? JSONSerialization.data(withJSONObject: resp, options: []),
                let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json"); return }
                self.delegate?.requestEvaluateJavaScript(callback + "(\(JSONString))", completionHandler: nil)
                break
            }
            
        }, onError: { [weak self] (err) in
            guard let `self` = self else { return }
            self.delegate?.requestEvaluateJavaScript(callback + "([])", completionHandler: nil)
            mailAssertionFailure("fail: \(err)")
        })
    }

    func handleFetchDocsEvent(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String, let docsUrl = params["url"] as? String else { mailAssertionFailure("unexpected type for callback"); return }

        MailTracker.insertLog(insertType: MailTracker.InsertType.add_doc_link)
        MailDataSource.shared.mailGetDocsPermModel(docsUrlStrings: [docsUrl], requestPermissions: true).subscribe(onNext: { [weak self] (resp) in
            guard let `self` = self else { return }
            let models = resp.docs
            guard let model = models[docsUrl] else {
                self.delegate?.requestEvaluateJavaScript(callback + "()", completionHandler: nil)
                mailAssertionFailure("fail to fetch docs info")
                return
            }
            let manageCollaborator = model.userPerm.contains(.manageCollaborator)
            let shareModel = DocShareModel.init(title: model.name,
                                                author: model.ownerName,
                                                docType: model.objectType,
                                                permission: .notShare,
                                                manageCollaborator: manageCollaborator,
                                                token: model.key,
                                                docUrl: model.url)
            self.delegate?.appendDocInfo(url: docsUrl, model: shareModel)
            let perms = model.userPerm.map { permission in
                return permission.rawValue
            }
            var responseObj: [String: Any] = ["name": model.name,
                                              "type": model.type.rawValue]
            if FeatureManager.open(.docAuthOpt, openInMailClient: false) {
                responseObj["userPerm"] = perms
            }
            guard let data = try? JSONSerialization.data(withJSONObject: responseObj, options: []),
                let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json"); return }
            self.delegate?.requestEvaluateJavaScript(callback + "(\(JSONString))", completionHandler: nil)
            }, onError: { [weak self] (_) in
                self?.delegate?.requestEvaluateJavaScript(callback + "()", completionHandler: nil)
        }).disposed(by: disposeBag)
    }

    func handleClickDocsPerm(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String,
            let action = params["permission"] as? Int,
            let userPerms = params["userPerm"] as? [String],
            let currentAction = DocsInMailPermAction(rawValue: action)
            else { mailAssertionFailure("unexpected type for callback"); return }
        guard let vc = delegate?.currentViewController() else { mailAssertionFailure("must get a view controller here to present the sheet"); return }
        let userPerm = userPerms.map { DocsPerm(rawValue: String($0)) }
        

        guard userPerm.count > 0 else {
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_DocPreview_No_perm, on: vc.view)
            mailAssertionFailure("should at least has one perm")
            return
        }
        if FeatureManager.open(.docAuthOpt, openInMailClient: false) {
            guard userPerm.contains(.manage) else {
                MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_LinkSharing_YouNeedPermissionShareDoc_Text,
                                           on: vc.view)
                return
            }
        }
        if let vc = vc as? MailSendController,
           vc.view.window?.traitCollection.horizontalSizeClass == .regular {
            var rect = CGRectZero
            if let rectDic = params["rect"] as? [String: CGFloat] {
                rect = CGRect(x: rectDic["left"] ?? 0.0,
                              y: rectDic["top"] ?? 0.0,
                              width: rectDic["width"] ?? 0.0,
                              height: rectDic["height"] ?? 0.0)
            }
            let scrollHeight: CGFloat = vc.scrollContainer.contentOffset.y
            let webviewOffsetY: CGFloat = vc.scrollContainer.webView.frame.origin.y
            let offsetY = rect.minY + webviewOffsetY - scrollHeight
            let sourceRect = CGRect(x: rect.minX, y: offsetY,
                                    width: rect.width, height: rect.height)
            showDocsPermPopoverView(sendVC: vc,
                                    userPerm: userPerm,
                                    currentAction: currentAction,
                                    callback: callback,
                                    rect: sourceRect)
            return
        }
         
        let source = UDActionSheetSource(sourceView: vc.view, sourceRect: vc.view.bounds)
        let pop = UDActionSheet(config: UDActionSheetUIConfig(isShowTitle: true, popSource: source))
        
        let selectedColor = UIColor.ud.primaryContentDefault
        pop.setTitle(BundleI18n.MailSDK.Mail_DocPreview_Recipients)
        
        if userPerm.contains(.read) {
            let item = UDActionSheetItem(title: BundleI18n.MailSDK.Mail_DocPreview_RecipientsCanRead, titleColor: currentAction == .read ? selectedColor : UIColor.ud.textTitle) { [weak self]  in
                guard let `self` = self else { return }
                self.reportPermissionChange(origin: currentAction, target: .read)
                self.delegate?.requestEvaluateJavaScript(callback + "(\(DocsInMailPermAction.read.rawValue))", completionHandler: nil)
                
            }
            pop.addItem(item)
        }
        if userPerm.contains(.edit) {
            let item = UDActionSheetItem(title: BundleI18n.MailSDK.Mail_DocPreview_RecipientsCanEdit,
                                         titleColor: currentAction == .edit ? selectedColor : UIColor.ud.textTitle) { [weak self]  in
                guard let `self` = self else { return }
                self.reportPermissionChange(origin: currentAction, target: .edit)
                self.delegate?.requestEvaluateJavaScript(callback + "(\(DocsInMailPermAction.edit.rawValue))", completionHandler: nil)
            }
            pop.addItem(item)
        }
        var title = BundleI18n.MailSDK.Mail_DocPreview_RecipientsExistingAccess
        if FeatureManager.open(.docAuthOpt, openInMailClient: false) {
            title = BundleI18n.MailSDK.Mail_LinkSharing_KeepCurrentPermissionSetting_Text
        }
        let item = UDActionSheetItem(title: title, titleColor:  currentAction == .keep ? selectedColor : UIColor.ud.textTitle) { [weak self]  in
            guard let `self` = self else { return }
            self.reportPermissionChange(origin: currentAction, target: .keep)
            self.delegate?.requestEvaluateJavaScript(callback + "(\(DocsInMailPermAction.keep.rawValue))", completionHandler: nil)
        }
        pop.addItem(item)
        pop.setCancelItem(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        vc.present(pop, animated: true, completion: nil)
    }
    private func showDocsPermPopoverView(sendVC: MailSendController,
                                         userPerm: [DocsPerm?],
                                         currentAction: DocsInMailPermAction,
                                         callback: String,
                                         rect: CGRect) {
        var popArray: [PopupMenuActionItem] = []
        let titleItem = PopupMenuActionItem(title:BundleI18n.MailSDK.Mail_DocPreview_Recipients, icon: UIImage()) { (_, _) in
            // nothing
        }
        titleItem.placeHolderTitle = true
        popArray.append(titleItem)
        if userPerm.contains(.read) {
            let titleColor = currentAction == .read ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            let profileItem = PopupMenuActionItem(title:BundleI18n.MailSDK.Mail_DocPreview_RecipientsCanRead,
                                                  icon: UIImage(),
                                                  titleColor: titleColor) { [weak self] (_, _) in
                guard let `self` = self else { return }
                self.reportPermissionChange(origin: currentAction, target: .read)
                self.delegate?.requestEvaluateJavaScript(callback + "(\(DocsInMailPermAction.read.rawValue))", completionHandler: nil)
               
            }
            popArray.append(profileItem)
        }
        if userPerm.contains(.edit) {
            let titleColor = currentAction == .edit ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            let modifyItem = PopupMenuActionItem(title:BundleI18n.MailSDK.Mail_DocPreview_RecipientsCanEdit,
                                                 icon: UIImage(),
                                                 titleColor: titleColor) { [weak self] (_, _) in
                guard let `self` = self else { return }
                self.reportPermissionChange(origin: currentAction, target: .edit)
                self.delegate?.requestEvaluateJavaScript(callback + "(\(DocsInMailPermAction.edit.rawValue))", completionHandler: nil)
            }
            popArray.append(modifyItem)
        }
        var title = BundleI18n.MailSDK.Mail_DocPreview_RecipientsExistingAccess
        if FeatureManager.open(.docAuthOpt, openInMailClient: false) {
            title = BundleI18n.MailSDK.Mail_LinkSharing_KeepCurrentPermissionSetting_Text
        }
        let titleColor = currentAction == .keep ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
        let keepItem = PopupMenuActionItem(title: title,
                                           icon: UIImage(),
                                           titleColor: titleColor) { [weak self] (_, _) in
            guard let `self` = self else { return }
            self.reportPermissionChange(origin: currentAction, target: .keep)
            self.delegate?.requestEvaluateJavaScript(callback + "(\(DocsInMailPermAction.keep.rawValue))", completionHandler: nil)
        }
        popArray.append(keepItem)
        let vc = PopupMenuPoverViewController(items: popArray)
        vc.hideIconImage = true
        vc.modalPresentationStyle = .popover
        vc.popoverPresentationController?.backgroundColor = UIColor.ud.bgBody
        vc.popoverPresentationController?.sourceView = sendVC.view
        vc.popoverPresentationController?.sourceRect = rect
        let spaceLimit: CGFloat = 260
        if rect.maxY + spaceLimit > vc.view.bounds.size.height {
            vc.popoverPresentationController?.permittedArrowDirections = .down
        } else {
            vc.popoverPresentationController?.permittedArrowDirections = .up
        }
        
        sendVC.navigator?.present(vc, from: sendVC)
    }

    
    private func reportPermissionChange(origin: DocsInMailPermAction, target: DocsInMailPermAction) {
        func permMap(action: DocsInMailPermAction) -> String {
            switch action {
            case .edit:
                return "edit"
            case .read:
                return "read"
            case .keep:
                return "retain"
            @unknown default:
                return "retain"
            }
        }
        let event = NewCoreEvent(event: .email_doc_link_edit_click)
        event.params = ["target": "none",
                        "click": "doc_auth",
                        "auth_status": permMap(action: origin),
                        "auth_set": permMap(action: target),
                        "mail_account_type": NewCoreEvent.accountType()]
        event.post()
    }

    func fetchDocsPermInfo(_ params: [String: Any]) {
        guard let docsUrl = params["url"] as? String,
            let callback = params["callback"] as? String
            else { mailAssertionFailure("missing essential params"); return }
        let callbackModel = DocsCallBackModel(url: docsUrl, callback: callback)
        callbackModels.append(callbackModel)
        aggregateDocsPermInfoFetch()
    }

    func aggregateDocsPermInfoFetch() {
        pendingRequestWorkItem?.cancel()
        let workerItem = DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            let docsUrls = self.callbackModels.map { $0.url }
            MailDataSource.shared.mailGetDocsPermModel(docsUrlStrings: docsUrls, requestPermissions: true).subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                let urlModelsDic = resp.docs
                while self.callbackModels.count > 0 {
                    guard let callbackModel = self.callbackModels.popLast(), let model = urlModelsDic[callbackModel.url] else { continue }
                    if !model.userPerm.contains(.manageCollaborator) {
                        self.delegate?.showNoSharePermissionToast()
                        return
                    }
                    let action = self.delegate?.getDocsInfo(url: model.url)?.action.rawValue ?? DocsInMailPermAction.keep.rawValue
                    let responseObj: [String: Any] = ["currentAction": String(action),
                                                      "userPerm": model.userPerm.map { String($0.rawValue) }]
                    guard let data = try? JSONSerialization.data(withJSONObject: responseObj, options: []),
                        let JSONString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { mailAssertionFailure("fail to serialize json"); return }
                    self.delegate?.requestEvaluateJavaScript(callbackModel.callback + "(\(JSONString))", completionHandler: nil)
                }
            }).disposed(by: self.disposeBag)
        }
        pendingRequestWorkItem = workerItem
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short, execute: workerItem)
    }
    func handleCallAI() {
        self.delegate?.editorAIClick()
    }
}


extension DataService {
    /// 是否包含外部地址
    public func checkExternal(addresses: [String]) -> Observable<Bool> {
        var request = ServerPB_Mails_CheckExternalEmailAddressRequest()
        request.mailAddressList = addresses
        request.base = genRequestBase()
        return sendPassThroughAsyncRequest(request,
                                           serCommand: .mailCheckExternalEmailAddress).observeOn(MainScheduler.instance).map { (resp: ServerPB_Mails_CheckExternalEmailAddressResponse) ->
            Bool in
            return resp.externalMailAddressList.count > 0
        }
    }
}


