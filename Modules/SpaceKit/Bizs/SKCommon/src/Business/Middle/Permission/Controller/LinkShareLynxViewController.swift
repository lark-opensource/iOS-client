//
//  LinkShareLynxViewController.swift
//  SKCommon
//
//  Created by peilongfei on 2023/4/6.
//  


import SKFoundation
import SKResource
import SKUIKit
import BDXServiceCenter
import LarkUIKit
import UniverseDesignColor
import UniverseDesignDialog
import BDXBridgeKit
import LarkReleaseConfig
import LarkLocalizations
import EENavigator
import SKInfra
import SpaceInterface

class LinkShareLynxViewController: LynxBaseViewController {

    var supportOrientations: UIInterfaceOrientationMask = .portrait

    private let shareEntity: SKShareEntity
    private let permStatistics: PermissionStatistics?
    weak var followAPIDelegate: BrowserVCFollowDelegate?

    private(set) lazy var toastTextView: UITextView = {
        let t = UITextView()
        t.backgroundColor = UDColor.bgFloat
        t.textColor = UDColor.textTitle
        t.textAlignment = .center
        t.isEditable = false
        t.isUserInteractionEnabled = true
        t.isSelectable = true
        t.isScrollEnabled = false
        t.showsHorizontalScrollIndicator = false
        t.showsVerticalScrollIndicator = false
        return t
    }()

    /// mina 动态下发 service & privacy URL 解析
    public static let links: (String, String) = {
        if DocsSDK.isInLarkDocsApp {
            guard let docsManagerDelegate = HostAppBridge.shared.call(GetDocsManagerDelegateService()) as? DocsManagerDelegate else {
                DocsLogger.info("no share link toast URL")
                return ("", "")
            }
            let serviceSite = docsManagerDelegate.serviceTermURL
            let privacySite = docsManagerDelegate.privacyURL
            return (serviceSite, privacySite)
        } else {
            guard let config = CCMKeyValue.globalUserDefault.dictionary(forKey: UserDefaultKeys.shareLinkToastURL) else {
                DocsLogger.info("no share link toast URL")
                return ("", "")
            }
            var serviceSite = ""
            var privacySite = ""
            if var serviceURL = config["service_term_url"] as? String {
                serviceSite = "https://" + serviceURL.replacingOccurrences(of: "{lan}", with: DocsSDK.convertedLanguage)
            } else {
                serviceSite = ""
            }
            if var privacyURL = config["privacy_url"] as? String {
                privacySite = "https://" + privacyURL.replacingOccurrences(of: "{lan}", with: DocsSDK.convertedLanguage)
            } else {
                privacySite = ""
            }
            return (serviceSite, privacySite)
        }
    }()

    init(shareEntity: SKShareEntity, userPermission: UserPermissionAbility, permStatistics: PermissionStatistics?, needCloseBarItem: Bool, openPasswordShare: Bool, followAPIDelegate: BrowserVCFollowDelegate?, isNewLarkForm: Bool) {
        self.shareEntity = shareEntity
        self.permStatistics = permStatistics
        self.followAPIDelegate = followAPIDelegate
        super.init(nibName: nil, bundle: nil)
        shareContextID = UUID().uuidString
        let hasAttachmentField = shareEntity.formsCallbackBlocks.formHasAttachmentField()
        let hasUserField = shareEntity.formsCallbackBlocks.formHasUserField()
        let isUserToC = User.current.info?.isToNewC == true
        let docPasswordEnable = SettingConfig.shareWithPasswordConfig?.docEnable ?? false
        let folderPasswordEnable = SettingConfig.shareWithPasswordConfig?.folderEnable ?? false

        let params = [
            "isNewLarkForm": isNewLarkForm,
            "isFormsNewShareEnable": true,
            "url": shareEntity.shareUrl,
            "token": shareEntity.objToken,
            "type": shareEntity.type.fixedRawValueForBitableSubType,
            "spaceId": shareEntity.spaceID,
            "isWiki": shareEntity.isFromWiki,
            "isContainerFA": userPermission.canManageMeta(),
            "isSpaceV2": shareEntity.spaceSingleContainer,
            "shareToken": shareEntity.shareToken ?? "",
            "shareType": shareEntity.shareType ?? 0,
            "isConstraintExternal": shareEntity.bitableConstraintExternal,
            "hasAttachmentField": hasAttachmentField,
            "hasUserField": hasUserField,
            "isUserToC": isUserToC,
            "isOversea": !DomainConfig.envInfo.isChinaMainland,
            "secretFGEnable": LKFeatureGating.sensitivtyLabelEnable,
            "searchFGEnable": UserScopeNoChangeFG.PLF.searchEntityEnable,
            "appDisplayName": LanguageManager.bundleDisplayName,
            "statisticParams": permStatistics?.commonParameters ?? [:],
            "closeInsteadOfBack": needCloseBarItem,
            "docPasswordEnable": docPasswordEnable,
            "folderPasswordEnable": folderPasswordEnable,
            "shareExternalSettingEnable": UserScopeNoChangeFG.PLF.shareExternalSettingEnable,
            "openPasswordShare": openPasswordShare,
            "customPasswordEnable": UserScopeNoChangeFG.PLF.customPasswordEnable
        ] as [String : Any]

        var logInfo = params
        logInfo["url"] = DocsTracker.encrypt(id: shareEntity.shareUrl)
        logInfo["token"] = shareEntity.objToken.encryptToken
        logInfo["shareToken"] = shareEntity.shareToken?.encryptToken
        DocsLogger.info("LinkShareLynxViewController initialProperties", extraInfo: logInfo)

        initialProperties = params
        templateRelativePath = "pages/link-share-panel/template.js"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UDColor.bgBase
        navigationBar.customizeBarAppearance(backgroundColor: UDColor.bgBase)
        statusBar.backgroundColor = UDColor.bgBase
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        lynxView?.triggerLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }

    override func registerBizHandlers(for lynxView: BDXLynxViewProtocol) {
        super.registerBizHandlers(for: lynxView)

        let eventHandlers: [BridgeHandler] = [
            ScopePickerBridgeHandler(hostController: self),
            NotifyPublicPermissionUpdatedBridgeHandler()
        ]
        eventHandlers.forEach { (handler) in
            lynxView.registerHandler(handler.handler, forMethod: handler.methodName)
        }

        lynxView.registerHandler({ _, _, params, callback in
            guard let text = params?["data"] as? String else {
                DocsLogger.error("setPrimaryClip: no params")
                return
            }
            DocsLogger.info("handle ccm.setPrimaryClip")
            let isSuccess = SKPasteboard.setString(text,
                                   psdaToken: PSDATokens.Pasteboard.docs_share_link_do_copy,
                                   shouldImmunity: true)
            callback(BDXBridgeStatusCode.succeeded.rawValue, ["isSuccess": isSuccess])
        }, forMethod: "ccm.setPrimaryClip")

        lynxView.registerHandler({ [weak self] _, _, params, callback in
            guard let isRead = params?["isRead"] as? Bool else {
                DocsLogger.error("showAnyOneLinkShareTipsDialog: no params")
                return
            }
            DocsLogger.info("handle ccm.permission.showAnyOneLinkShareTipsDialog")
            self?.showAnyOneAccessAlertByState(isRead: isRead, callback: callback)
        }, forMethod: "ccm.permission.showAnyOneLinkShareTipsDialog")

        lynxView.registerHandler({ [weak self] _, _, params, callback in
            callback(BDXBridgeStatusCode.succeeded.rawValue, nil)
            guard let self else { return }
            guard let code = params?["code"] as? Int,
                  let type = params?["type"] as? Int,
                  let scene = RealNameAuthService.Scene(rawValue: code) else {
                DocsLogger.error("showRealNameAuthDialog get code failed, code: \(String(describing: params?["code"]))")
                return
            }
            let isFolder = type == DocsType.folder.rawValue
            DocsLogger.info("handle showRealNameAuthDialog, scene: \(scene)")
            RealNameAuthService.showRealNameAuthDialog(scene: scene, isFolder: isFolder, fromVC: self)
        }, forMethod: "ccm.permission.showRealNameAuthDialog")

        lynxView.registerHandler({ [weak self] _, _, params, callback in
            guard let self else {
                callback(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
                return
            }
            guard let params,
                  let token = params["token"] as? String,
                  let type = params["type"] as? Int else {
                DocsLogger.error("showCustomPasswordSetting get token type failed")
                spaceAssertionFailure("showCustomPasswordSetting get token type failed")
                callback(BDXBridgeStatusCode.invalidParameter.rawValue, nil)
                return
            }
            let ruleSet: PasswordRuleSet
            if let data = params["data"] as? String,
               let jsonData = data.data(using: .utf8) {
                do {
                    let decoder = JSONDecoder()
                    PasswordDecodeHelper.setup(decoder: decoder)
                    ruleSet = try decoder.decode(PasswordRuleSet.self, from: jsonData)
                } catch {
                    ruleSet = .empty
                    DocsLogger.error("parse password rule failed, fallback to empty ruleSet", error: error)
                    spaceAssertionFailure()
                }
            } else {
                DocsLogger.error("password rule data not found, fallback to empty ruleSet")
                ruleSet = .empty
            }
            let customViewModel = CustomPasswordViewModel(objToken: token,
                                                          objType: DocsType(rawValue: type),
                                                          ruleSet: ruleSet)
            let customController = CustomPasswordViewController(viewModel: customViewModel)
            customController.updateCallback = { password in
                callback(BDXBridgeStatusCode.succeeded.rawValue, [
                    "code": password == nil ? -1 : 0,
                    "password": password
                ])
            }
            customController.modalPresentationStyle = .formSheet
            Navigator.shared.present(customController, from: self)
        }, forMethod: "ccm.permission.showCustomPasswordSetting")
    }
}

extension LinkShareLynxViewController: ScopePickerBridgeDelegate {

    func showScopePicker(needLockTips: Bool, defaultScopeType: PermissionScopeType, completion: @escaping (PermissionScopeType?) -> Void) {
        let singlePageItem = ScopeSelectItem(title: BundleI18n.SKResource.CreationMobile_Wiki_Page_Current_tab,
                                             subTitle: nil,
                                             selected: defaultScopeType == .singlePage,
                                             scopeType: .singlePage)
        var item2SubTitle: String?
        if needLockTips {
            item2SubTitle = BundleI18n.SKResource.CreationMobile_Wiki_Perm_ExternalShare_Current_notice
        }
        let containerItem = ScopeSelectItem(title: BundleI18n.SKResource.CreationMobile_Wiki_Page_CurrentNSub_tab,
                                            subTitle: item2SubTitle,
                                            selected: defaultScopeType == .container,
                                            scopeType: .container)
        let models: [ScopeSelectItem] = [singlePageItem, containerItem]

        let confirmCompletion: (UIViewController, PermissionScopeType) -> Void = { _, type in
            completion(type)
        }
        let cancelCompletion: (UIViewController, PermissionScopeType) -> Void = { _, _ in
            completion(nil)
        }
        if SKDisplay.pad, isMyWindowRegularSize() {
            let viewController = IpadScopeSelectViewController(items: models)
            viewController.confirmCompletion = confirmCompletion
            viewController.cancelCompletion = cancelCompletion
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: self)
        } else {
            let viewController = ScopeSelectViewController(items: models)
            viewController.confirmCompletion = confirmCompletion
            viewController.cancelCompletion = cancelCompletion
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: self)
        }
        permStatistics?.reportPermissionScopeChangeView()
        permStatistics?.reportPermissionSetClick(click: .isShareOutside, target: .permissionScopeChangeView)
    }
}

extension LinkShareLynxViewController {
    /// 显示任何人都可以访问、编辑弹框
    private func showAnyOneAccessAlertByState(isRead: Bool, callback:@escaping ((Int, [AnyHashable:Any]?) -> Void)) {
        permStatistics?.reportPermissionPromptView(fromScene: .shareLink)
        let isForm = shareEntity.isForm
        let hasUserField = shareEntity.formsCallbackBlocks.formHasUserField()
        let hasAttachmentField = shareEntity.formsCallbackBlocks.formHasAttachmentField()
        if isForm {
            if hasUserField || hasAttachmentField {
                showFormAnyOneAccessAlertBySpecialField(isRead: isRead, callback: callback)
                return
            }
            return
        }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Share_Confirm)
        let textView = makeToastMessage(isRead: isRead)
        textView.textColor = UDColor.textTitle
        dialog.setContent(view: textView)
        let cancelButtonText = BundleI18n.SKResource.Doc_Facade_Cancel
        let okButtonText = BundleI18n.SKResource.Doc_Facade_Confirm
        dialog.addSecondaryButton(text: cancelButtonText, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else { return true }
            self.permStatistics?.reportPermissionPromptClick(click: .cancel,
                                                             target: .noneTargetView,
                                                             fromScene: .shareLink)
            return true
        })
        dialog.addDestructiveButton(text: okButtonText, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else { return true }
            callback(BDXBridgeStatusCode.succeeded.rawValue, ["actionID": "confirm"])
            self.permStatistics?.reportPermissionPromptClick(click: .confirm,
                                                             target: .noneTargetView,
                                                             fromScene: .shareLink)
            if isRead {
                let info = EditLinkInfo(mainStr: "", chosenType: .anyoneRead)
                self.permStatistics?.reportPermissionShareEditClick(shareEntity: self.shareEntity, editLinkInfo: info)
            } else {
                let info = EditLinkInfo(mainStr: "", chosenType: .anyoneEdit)
                self.permStatistics?.reportPermissionShareEditClick(shareEntity: self.shareEntity, editLinkInfo: info)
            }
            return true
        })
        present(dialog, animated: true, completion: nil)
    }

    // 根据用户是小B/C还是B端以及海内海外版本判断应该显示的文案
    func makeToastMessage(isRead: Bool) -> UITextView {
        var msg: String = ""
        let typeString: String
        if shareEntity.type == .minutes {
            typeString = BundleI18n.SKResource.CreationMobile_Minutes_name
        } else if shareEntity.type == .wikiCatalog {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Page
        } else {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Document
        }
        //海外
        guard DomainConfig.envInfo.isChinaMainland == true && !ReleaseConfig.isPrivateKA else {
            if isRead {
                if shareEntity.type == .folder {
                    msg = BundleI18n.SKResource.Doc_Share_FolderBOverseaAnonymousVisit
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitTips_AddVariable(typeString)
                }
            } else {
                msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditTips_AddVariable(typeString)
            }
            let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
            let paraph = NSMutableParagraphStyle()
            attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
            attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }
        //国内
        if isRead {
            if shareEntity.type == .folder {
                msg = BundleI18n.SKResource.Doc_Share_FolderBNoExternalAnonymousVisit(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
            } else {
                msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitWithPrivacyTips_AddVariable(typeString,
                                                                                                     BundleI18n.SKResource.Doc_Share_ServiceTerm(),
                                                                                                     BundleI18n.SKResource.Doc_Share_Privacy)
            }
        } else {
            msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditWithPrivacyTips_AddVariable(typeString, BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
        }
        // 向文本中插入超链接
        let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
        let paraph = NSMutableParagraphStyle()
        attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
        attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
        guard let serviceRange = msg.range(of: BundleI18n.SKResource.Doc_Share_ServiceTerm()), let privacyRange = msg.range(of: BundleI18n.SKResource.Doc_Share_Privacy) else {
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }
        attritedMsg.addAttributes([NSAttributedString.Key.link: Self.links.0], range: msg.nsrange(fromRange: serviceRange))
        attritedMsg.addAttributes([NSAttributedString.Key.link: Self.links.1], range: msg.nsrange(fromRange: privacyRange))
        toastTextView.attributedText = attritedMsg
        return toastTextView
    }

    /// 有附件和人员字段时bitable表单显示任何人都可以访问、编辑弹框
    private func showFormAnyOneAccessAlertBySpecialField(isRead: Bool, callback:@escaping ((Int, [AnyHashable:Any]?) -> Void)) {
        let hasUserField = shareEntity.formsCallbackBlocks.formHasUserField()
        let hasAttachmentField = shareEntity.formsCallbackBlocks.formHasAttachmentField()

        let dialog = UDDialog()

        var title = ""
        if hasUserField {
            if hasAttachmentField {
                title = BundleI18n.SKResource.Bitable_Form_AttachmentAndPersonFieldNoticeTitle
            } else {
                title = BundleI18n.SKResource.Bitable_Form_PersonFieldNoticeTitle
            }
        } else if hasAttachmentField {
            title = BundleI18n.SKResource.Bitable_Form_AttachmentFieldNoticeTitle
        }

        dialog.setTitle(text: title)
        let textView = makeFormToastMessage(isRead: isRead)
        textView.textColor = UDColor.textTitle

        dialog.setContent(view: textView)
        let okButtonText = BundleI18n.SKResource.Bitable_Common_ButtonGotIt

        dialog.addPrimaryButton(text: okButtonText, dismissCheck: { [weak self] () -> Bool in
            guard let self = self else { return true }
            callback(BDXBridgeStatusCode.succeeded.rawValue, ["actionID": "confirm"])
            self.permStatistics?.reportPermissionPromptClick(click: .confirm,
                                                             target: .noneTargetView,
                                                             fromScene: .shareLink)
            return true
        })

        present(dialog, animated: true, completion: nil)
    }

    // 表单 根据用户是小B/C还是B端以及海内海外版本判断应该显示的文案
    private func makeFormToastMessage(isRead: Bool) -> UITextView {
        var msg: String = ""
        //KA
        guard DomainConfig.envInfo.isChinaMainland == true && !ReleaseConfig.isPrivateKA else {
            if isRead {
                if shareEntity.type == .folder {
                    msg = BundleI18n.SKResource.Doc_Share_FolderBOverseaAnonymousVisit
                } else {
                    msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitTips
                }
            } else {
                msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditTips
            }

            if let formSpecialFieldMessage = makeFormSpecialFieldMessage() {
                msg = formSpecialFieldMessage
            }

            let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
            let paraph = NSMutableParagraphStyle()
            attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
            attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }

        if isRead {
            if shareEntity.type == .folder {
                msg = BundleI18n.SKResource.Doc_Share_FolderBNoExternalAnonymousVisit(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
            } else {
                msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitWithPrivacyTips(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
            }
        } else {
            if shareEntity.isForm {
                msg = BundleI18n.SKResource.Bitable_Form_NoticeForFormSharingDesc(lang: nil)
            } else {
                msg = BundleI18n.SKResource.Doc_Permission_AnonymousEditWithPrivacyTips(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
            }
        }

        if let formSpecialFieldMessage = makeFormSpecialFieldMessage() {
            msg = formSpecialFieldMessage
        }

        let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
        let paraph = NSMutableParagraphStyle()
        attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
        attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
        toastTextView.attributedText = attritedMsg
        return toastTextView
    }

    private func makeFormSpecialFieldMessage() -> String? {
        guard shareEntity.isForm else {
            DocsLogger.info("makeFormSpecialFieldMessage: Is not form")
            return nil
        }

        let hasUserField = shareEntity.formsCallbackBlocks.formHasUserField()
        let hasAttachmentField = shareEntity.formsCallbackBlocks.formHasAttachmentField()

        if hasUserField {
            if hasAttachmentField {
                return BundleI18n.SKResource.Bitable_Form_AttachmentAndPersonFieldNoticeDesc
            } else {
                return BundleI18n.SKResource.Bitable_Form_PersonFieldNoticeDesc
            }
        } else if hasAttachmentField {
            return BundleI18n.SKResource.Bitable_Form_AttachmentFieldNoticeDesc
        }

        return nil
    }
}
