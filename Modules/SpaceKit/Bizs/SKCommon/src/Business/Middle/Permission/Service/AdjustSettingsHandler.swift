//
//  AdjustSettingsHandler.swift
//  SKCommon
//
//  Created by peilongfei on 2023/5/4.
//  


import SKFoundation
import UniverseDesignColor
import UniverseDesignDialog
import UniverseDesignToast
import EENavigator
import SKResource
import SKInfra
import SwiftyJSON
import LarkReleaseConfig
import RxSwift
import SpaceInterface

enum AdjustSettingsStatus {
    case success
    case fail
    case disabled
}

class AdjustSettingsHandler {

    let token: String
    let type: ShareDocsType
    let isSpaceV2: Bool
    let isWiki: Bool
    let wikiToken: String?
    let permissionManager: PermissionManager?
    var permStatistics: PermissionStatistics?
    weak var followAPIDelegate: BrowserVCFollowDelegate?

    let disposeBag = DisposeBag()

    var userPermission: UserPermissionAbility? {
        return permissionManager?.getUserPermissions(for: token)
    }
    var publicPermission: PublicPermissionMeta? {
        return permissionManager?.getPublicPermissionMeta(token: token)
    }
    var secLabelRequest: DocsRequest<JSON>?
    var secLabelList: SecretLevelLabelList?
    var shareExternalReason: Int = 0
    var sharePartnerTenantReason: Int = 0

    init(token: String, type: ShareDocsType, isSpaceV2: Bool, isWiki: Bool, wikiToken: String? = nil, followAPIDelegate: BrowserVCFollowDelegate? = nil) {
        self.token = token
        self.type = type
        self.isSpaceV2 = isSpaceV2
        self.isWiki = isWiki
        self.wikiToken = wikiToken
        self.followAPIDelegate = followAPIDelegate
        self.permissionManager = DocsContainer.shared.resolve(PermissionManager.self)
        getSecLabelList().subscribe().disposed(by: disposeBag)
    }

    public func toAdjustSettingsIfEnabled(sceneType: AdjustSettingsSceneType, topVC: UIViewController?, completion: @escaping (AdjustSettingsStatus) -> Void) {
        guard let topVC = topVC else { return }
        UDToast.docs.showMessage(BundleI18n.SKResource.Doc_Facade_Loading, on: topVC.view, msgType: .loading)
        isAdjustSettingsEnabled(sceneType: sceneType).subscribe { flag in
            UDToast.removeToast(on: topVC.view)
            if flag {
                let sceneType = self.getRealSceneType(sceneType: sceneType)
                self.toAdjustSettingsVC(sceneType: sceneType, topVC: topVC, completion: completion)
            } else {
                completion(.disabled)
            }
        } onError: { error in
            DocsLogger.error("AdjustSettingsHandler failed!", error: error)
            UDToast.removeToast(on: topVC.view)
            completion(.disabled)
        }.disposed(by: disposeBag)
    }

    private func isAdjustSettingsEnabled(sceneType: AdjustSettingsSceneType) -> Single<Bool> {
        guard UserScopeNoChangeFG.PLF.shareExternalSettingEnable else {
            DocsLogger.info("AdjustSettingsHandler: fg disable!")
            return .just(false)
        }
        guard isSpaceV2 else {
            DocsLogger.info("AdjustSettingsHandler: is not spaceV2!")
            return .just(false)
        }
        if type == .folder || type == .minutes || type == .sync {
            DocsLogger.info("AdjustSettingsHandler: disable type(\(type)!")
            return .just(false)
        }

        return getUserPermissionAndPublicPermission(sceneType: sceneType).flatMap { [weak self] (userPermission, publicPermission) -> Single<Bool> in
            guard let self = self else { return .just(false) }
            let docsInfo = DocsInfo(type: .init(rawValue: self.type.rawValue), objToken: self.token)
            self.permStatistics = PermissionStatistics(docsInfo: docsInfo)
            if case .imShareExternalMember = sceneType {
                self.permStatistics?.reportImUrlRenderClick()
            }

            guard userPermission.isFA else {
                DocsLogger.info("AdjustSettingsHandler: is not FA!")
                return .just(false)
            }

            guard let shareExternal = userPermission.actions[.shareExternal] else {
                DocsLogger.warning("AdjustSettingsHandler: shareExternal is nil")
                return .just(false)
            }
            self.shareExternalReason = shareExternal.rawValue
            guard let sharePartnerTenant = userPermission.actions[.sharePartnerTenant] else {
                DocsLogger.warning("AdjustSettingsHandler: sharePartnerTenantResult is nil")
                return .just(false)
            }
            self.sharePartnerTenantReason = sharePartnerTenant.rawValue

            let sceneType = self.getRealSceneType(sceneType: sceneType)
            switch sceneType {
            case .inviteExternalMember, .imShareExternalMember:
                switch shareExternal.authResult {
                case .specialShareExternal, .externalAccessClose:
                    return .just(true)
                case .secLabel:
                    return self.checkUsabledSecLabel(sceneType: sceneType)
                default:
                    DocsLogger.info("AdjustSettingsHandler: shareExternalResult is \(shareExternal.authResult)")
                    return .just(false)
                }

            case .inviteExternalPartnerTenantMember, .imShareExternalPartnerTenantMember:
                switch sharePartnerTenant.authResult {
                case .externalAccessClose:
                    return .just(true)
                case .secLabel:
                    return self.checkUsabledSecLabel(sceneType: sceneType)
                default:
                    DocsLogger.info("AdjustSettingsHandler: shareExternalResult is \(sharePartnerTenant.authResult)")
                    return .just(false)
                }

            case .passwordShare, .wechatShare, .momentsShare, .qqShare, .weiboShare, .externalShare:
                guard let linkShareEntityValue = publicPermission.linkShareEntityV2?.rawValue else {
                    DocsLogger.warning("AdjustSettingsHandler: linkShareEntityValue is nil")
                    return .just(false)
                }
                guard linkShareEntityValue != 4 && linkShareEntityValue != 5 else {
                    DocsLogger.info("AdjustSettingsHandler: linkShareEntityValue is \(linkShareEntityValue)")
                    return .just(false)
                }
                let linkShareBlockType = publicPermission.blockOptions?.linkShareEntity(with: .anyoneCanRead)
                if linkShareBlockType == nil || linkShareBlockType == BlockOptions.BlockType.none {
                    return .just(true)
                } else if linkShareBlockType == .currentLimit {
                    return .just(true)
                } else if linkShareBlockType == .secretControl {
                    return self.checkUsabledSecLabel(sceneType: sceneType)
                } else {
                    DocsLogger.info("AdjustSettingsHandler: linkShareBlockType is \(linkShareBlockType.debugDescription)")
                    return .just(false)
                }

            case .calenderDocCard:
                return .just(true)

            default:
                DocsLogger.warning("AdjustSettingsHandler: sceneType is \(sceneType)")
                return .just(false)
            }
        }
    }

    private func getUserPermissionAndPublicPermission(sceneType: AdjustSettingsSceneType) -> Single<(UserPermissionAbility, PublicPermissionMeta)> {
        // IM 场景中没有权限的协同，需要每次都拉取新权限信息
        switch sceneType {
        case .imShareExternalMember, .imShareExternalPartnerTenantMember:
            return requestUserPermissionAndPublicPermission()
        default:
            if let userPermission = userPermission, let publicPermission = publicPermission {
                return .just((userPermission, publicPermission))
            } else {
                return requestUserPermissionAndPublicPermission()
            }
        }
    }

    private func requestUserPermissionAndPublicPermission() -> Single<(UserPermissionAbility, PublicPermissionMeta)> {
        guard let permissionManager = permissionManager else {
            DocsLogger.error("AdjustSettingsHandler: permissionManager is nil")
            return .never()
        }
        let userPermissionsRequest = permissionManager.fetchUserPermission(token: token, type: type.rawValue)
        let publicPermissionsRequest = permissionManager.fetchPublicPermission(token: token, type: type.rawValue)
        return Single.zip(userPermissionsRequest, publicPermissionsRequest)
            .subscribeOn(MainScheduler.instance)
    }

    private func checkUsabledSecLabel(sceneType: AdjustSettingsSceneType) -> Single<Bool> {
        return getSecLabelList().map { secLabelList in
            let usableSecLabels = secLabelList.labels.filter { secLabel in
                if !secLabel.enableProtect {
                    return true
                }

                switch sceneType {
                case .inviteExternalMember, .inviteExternalPartnerTenantMember, .imShareExternalMember, .imShareExternalPartnerTenantMember:
                    let externalAccessSwitch = secLabel.control.externalAccess
                    return externalAccessSwitch != false

                case .wechatShare, .passwordShare, .momentsShare, .qqShare, .weiboShare, .externalShare:
                    let externalAccessSwitch = secLabel.control.externalAccess
                    let linkShareEntity = secLabel.control.linkShareEntity
                    if externalAccessSwitch != false {
                        if let linkShareEntityValue = linkShareEntity?.rawValue {
                            return linkShareEntityValue > 3
                        } else {
                            return true
                        }
                    }
                    return false

                default: return false
                }
            }
            return usableSecLabels.count > 0
        }
    }

    private func getSecLabelList() -> Single<SecretLevelLabelList> {
        if let secLabelList = secLabelList {
            return .just(secLabelList)
        }
        return SecretLevelLabelList.fetchLabelList()
            .subscribeOn(MainScheduler.instance)
            .do { [weak self] list in
                self?.secLabelList = list
            }
    }

    private func getRealSceneType(sceneType: AdjustSettingsSceneType) -> AdjustSettingsSceneType {
        guard let publicPermission = publicPermission else {
            DocsLogger.info("AdjustSettingsHandler: publicPermission is nil")
            return sceneType
        }
        guard let shareExternalResult = userPermission?.actions[.shareExternal]?.authResult else {
            DocsLogger.warning("AdjustSettingsHandler: shareExternal is nil")
            return sceneType
        }

        let sharePartnerTenantCodes: [UserPermissionAction.AuthResult] = [
            .adminSharePartnerTenantClose,
            .wikiSharePartnerTenantClose,
            .secLabelSharePartnerTenantClose
        ]
        var sceneType = sceneType
        switch sceneType {
        case .inviteExternalMember(let targetTenantId):
            if publicPermission.partnerTenantIds.contains(targetTenantId) {
                if sharePartnerTenantCodes.contains(shareExternalResult) {
                    return .inviteExternalPartnerTenantMember
                }
            }
        case .imShareExternalMember(let targetTenantId):
            if publicPermission.partnerTenantIds.contains(targetTenantId) {
                if sharePartnerTenantCodes.contains(shareExternalResult) {
                    return .imShareExternalPartnerTenantMember
                }
            }
        default: break
        }
        return sceneType
    }
}

extension AdjustSettingsHandler {

    private func toAdjustSettingsVC(sceneType: AdjustSettingsSceneType, topVC: UIViewController?, completion: @escaping ((AdjustSettingsStatus) -> Void)) {
        guard let topVC = topVC else { return }

        func toAdjustSettings() {
            let vc = AdjustSettingsLynxViewController(
                token: token,
                type: type,
                sceneType: sceneType,
                shareExternalReason: shareExternalReason,
                sharePartnerTenantReason: sharePartnerTenantReason,
                isWiki: isWiki,
                wikiToken: wikiToken,
                statisticParams: self.permStatistics?.commonParameters,
                followAPIDelegate: followAPIDelegate
            ) { result in
                switch result {
                case .success:
                    DocsLogger.info("AdjustSettingsHandler: result is success")
                    completion(.success)
                case .otherConstraint, .noUsableSecLabel, .entityTypeError:
                    DocsLogger.info("AdjustSettingsHandler: result is disabled")
                    completion(.disabled)
                case .fail:
                    DocsLogger.info("AdjustSettingsHandler: result is fail")
                    completion(.fail)
                default:
                    DocsLogger.info("AdjustSettingsHandler: result is cancel")
                    break
                }
            }
            vc.modalPresentationStyle = .formSheet
            topVC.present(vc, animated: true, completion: nil)
        }

        switch sceneType {
        case .passwordShare, .wechatShare, .momentsShare, .qqShare, .weiboShare, .externalShare:
            showAnyOneAccessAlertByState(topVC: topVC) {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) {
                    toAdjustSettings()
                }
            }
        default:
            toAdjustSettings()
        }
    }

    private func showAnyOneAccessAlertByState(topVC: UIViewController, callback:@escaping (() -> Void)) {
        permStatistics?.reportPermissionPromptView(fromScene: .shareLink)
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Share_Confirm)
        let textView = makeToastMessage()
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
            self.permStatistics?.reportPermissionPromptClick(click: .confirm,
                                                             target: .noneTargetView,
                                                             fromScene: .shareLink)
            let info = EditLinkInfo(mainStr: "", chosenType: .anyoneRead)
            callback()
            return true
        })
        topVC.present(dialog, animated: true, completion: nil)
    }

    private func makeToastMessage() -> UITextView {
        let toastTextView = UITextView()
        toastTextView.backgroundColor = UDColor.bgFloat
        toastTextView.textColor = UDColor.textTitle
        toastTextView.textAlignment = .center
        toastTextView.isEditable = false
        toastTextView.isUserInteractionEnabled = true
        toastTextView.isSelectable = true
        toastTextView.isScrollEnabled = false
        toastTextView.showsHorizontalScrollIndicator = false
        toastTextView.showsVerticalScrollIndicator = false

        var msg: String = ""
        let typeString: String
        if type == .minutes {
            typeString = BundleI18n.SKResource.CreationMobile_Minutes_name
        } else if type == .wikiCatalog {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Page
        } else {
            typeString = BundleI18n.SKResource.CreationMobile_Common_Document
        }
        //海外
        guard DomainConfig.envInfo.isChinaMainland == true && !ReleaseConfig.isPrivateKA else {
            if type == .folder {
                msg = BundleI18n.SKResource.Doc_Share_FolderBOverseaAnonymousVisit
            } else {
                msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitTips_AddVariable(typeString)
            }
            let attritedMsg: NSMutableAttributedString = NSMutableAttributedString(string: msg)
            let paraph = NSMutableParagraphStyle()
            attritedMsg.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: msg.count))
            attritedMsg.addAttributes([NSAttributedString.Key.paragraphStyle: paraph], range: NSRange(location: 0, length: msg.count))
            toastTextView.attributedText = attritedMsg
            return toastTextView
        }
        //国内
        if type == .folder {
            msg = BundleI18n.SKResource.Doc_Share_FolderBNoExternalAnonymousVisit(BundleI18n.SKResource.Doc_Share_ServiceTerm(), BundleI18n.SKResource.Doc_Share_Privacy)
        } else {
            msg = BundleI18n.SKResource.Doc_Permission_AnonymousVisitWithPrivacyTips_AddVariable(typeString,
                                                                                                 BundleI18n.SKResource.Doc_Share_ServiceTerm(),
                                                                                                 BundleI18n.SKResource.Doc_Share_Privacy)
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
        attritedMsg.addAttributes([NSAttributedString.Key.link: LinkShareLynxViewController.links.0], range: msg.nsrange(fromRange: serviceRange))
        attritedMsg.addAttributes([NSAttributedString.Key.link: LinkShareLynxViewController.links.1], range: msg.nsrange(fromRange: privacyRange))
        toastTextView.attributedText = attritedMsg
        return toastTextView
    }
}

extension AdjustSettingsHandler {

    public func inviteMemberAndRefreshCard(chatId: String, chatType: Int, docCardId: String, topVC: UIViewController?) {
        guard let topVC = topVC else { return }

        let checkCollaboratorsExist = PermissionManager.checkCollaboratorsExist(
            type: type.rawValue,
            token: token,
            ownerId: chatId,
            ownerType: chatType
        )
        let inviteCollaboratorsByAdjustSettings = PermissionManager.inviteCollaboratorsByAdjustSettings(
            type: type.rawValue,
            token: token,
            ownerId: chatId,
            ownerType: chatType
        )
        let updateDocCard = PermissionManager.updateDocCard(
            token: self.token,
            type: self.type.rawValue,
            cardId: docCardId
        )

        UDToast.docs.showMessage(BundleI18n.SKResource.Doc_Facade_Loading, on: topVC.view, msgType: .loading)
        checkCollaboratorsExist.flatMapCompletable { isExist in
            if isExist {
                return updateDocCard
            } else {
                return inviteCollaboratorsByAdjustSettings.andThen(updateDocCard).catchError({ error in
                    return updateDocCard.andThen(.error(error))
                })
            }
        }.subscribe {
            UDToast.removeToast(on: topVC.view)
        } onError: { error in
            DocsLogger.error("inviteMemberAndRefreshCard failed!", error: error)
            UDToast.docs.showMessage(BundleI18n.SKResource.Lark_CM_ExSharing_SetButNotInvited_Toast, on: topVC.view, msgType: .failure)
        }.disposed(by: disposeBag)
    }
}

extension AdjustSettingsHandler {

    static func createController(request: EENavigator.Request) -> UIViewController {
        let queryParams = request.url.queryParameters
        var cardPath = request.url.path
        // path 带有一个前导 /, 需要去掉
        cardPath.removeFirst()
        let shareContextID = request.context[SKLynxRouteHandler.kShareContextID] as? String
        var initialProperties = request.context[SKLynxRouteHandler.kInitialProperties] as? [String: Any] ?? [:]
        // 将 query 参数带入 initialProperties，优先使用 context 中的值
        initialProperties.merge(queryParams) { contextValue, _ in
            return contextValue
        }

        let config = SKLynxConfig(cardPath: cardPath, initialProperties: initialProperties, shareContextID: shareContextID)
        var controller = AdjustSettingsLynxViewController(config: config)
        if let fromVC = request.from.fromViewController {
            if let fromVC = fromVC as? PublicPermissionLynxController {
                controller = AdjustSettingsLynxViewController(config: config, followAPIDelegate: fromVC.followAPIDelegate)
            } else if let fromVC = fromVC as? LinkShareLynxViewController {
                controller = AdjustSettingsLynxViewController(config: config, followAPIDelegate: fromVC.followAPIDelegate)
            }
            controller.supportOrientations = fromVC.supportedInterfaceOrientations
        }
        return controller
    }
}
