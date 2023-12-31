//
//  SpaceListSlideDelegateProxyV2.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/7/2.
//
//  swiftlint:disable file_length line_length


import Foundation
import RxSwift
import RxRelay
import SKUIKit
import SwiftyJSON
import SKResource
import SKFoundation
import SKCommon
import EENavigator
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignDialog
import LarkUIKit
import UIKit
import LarkEMM
import SpaceInterface
import SKInfra
import SKWorkspace
import LarkContainer

enum SpaceManagementError: Error {
    case handlerReferenceError
    case userCancelled
}

// 新版本 SpaceListViewModel 使用
protocol SpaceListSlideDelegateHelperV2: AnyObject {
    var slideActionInput: PublishRelay<SpaceSection.Action> { get }
    var slideTracker: SpaceSubSectionTracker { get }
    var interactionHelper: SpaceInteractionHelper { get }
    var listType: SKObserverDataType? { get }     // 用来标识列表
    var userID: String { get }
    func refreshForMoreAction()
    func handleDelete(for entry: SpaceEntry)
}

extension SpaceListSlideDelegateHelperV2 {
    
    var userResolver: UserResolver {
        let compatibleMode = CCMUserScope.compatibleMode
        let ur = try? Container.shared.getUserResolver(userID: self.userID, compatibleMode: compatibleMode)
        return ur ?? Container.shared.getCurrentUserResolver(compatibleMode: compatibleMode) //TODO.chensi 是否需要兜底
    }
}

class SpaceListSlideDelegateProxyV2 {

    private(set) weak var helper: SpaceListSlideDelegateHelperV2?
    let wikiInteractionHelper = WikiInteractionHandler()
    let disposeBag = DisposeBag()

    private let networkFlowHelper = NetworkFlowHelper()
    
    init(helper: SpaceListSlideDelegateHelperV2) {
        self.helper = helper
    }

    func checkIsColorfulEgg(file: SpaceEntry) -> Bool {
        return file.name == "!~!~193278~!~!"
    }

    func showFailure(with: String) {
        helper?.slideActionInput.accept(.showHUD(.failure(with)))
    }

    func showSuccess(with: String) {
        helper?.slideActionInput.accept(.showHUD(.success(with)))
    }

    func showTips(with: String) {
        helper?.slideActionInput.accept(.showHUD(.tips(with)))
    }
    
    func showManualOffline(text: String, buttonText: String) {
        helper?.slideActionInput.accept(.showHUD(.tipsmanualOffline(text: text, buttonText: buttonText)))
    }
}

// MARK: more面板处理事件
extension SpaceListSlideDelegateProxyV2: SpaceMoreActionHandler {
    // 全量
    func toggleFavorites(for entry: SpaceEntry) {
        guard let helper = helper else { return }
        let addStar = !entry.stared
        var item = SpaceItem(objToken: entry.objToken, objType: entry.docsType)
        if entry.originInWiki, let wikiToken = entry.bizNodeToken {
            item = SpaceItem(objToken: wikiToken, objType: .wiki)
        }
        helper.interactionHelper.update(isFavorites: addStar, item: item)
            .subscribe { [weak self] in
                guard let self = self else { return }
                let notificationInfo: [String: Any] = [
                    "objType": item.objType,
                    "objToken": item.objToken,
                    "addStar": addStar
                ]
                // 不论是不是 wiki 都要发通知，解决 space shortcut 到 wiki 里的收藏状态不协同
                NotificationCenter.default.post(name: Notification.Name.Docs.wikiExplorerStarNode, object: nil, userInfo: notificationInfo)
                if addStar {
                    self.showFavoriteSuccess()
                } else {
                    self.showSuccess(with: BundleI18n.SKResource.CreationMobile_Wiki_Favorites_CanceledFavorites_Toast)
                }
                entry.updateStaredStatus(addStar)
            } onError: { [weak self] error in
                DocsLogger.error("space.slide.helper --- change star failed", extraInfo: ["isAddStar": addStar], error: error)
                guard let self = self else { return }
                if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                    self.showFailure(with: message)
                    return
               }
                if addStar {
                    self.showFailure(with: BundleI18n.SKResource.Doc_List_AddFailedRetry)
                } else {
                    self.showFailure(with: BundleI18n.SKResource.Doc_List_RemoveFaildRetry)
                }
            }
            .disposed(by: disposeBag)
        helper.slideTracker.reportToggleStar(isStar: addStar, for: entry)
    }

    private func showFavoriteSuccess() {
        guard let helper = helper else { return }

        let operation = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Wiki_AddtoFav_GoToButton,
                                               displayType: .horizontal)
        let config = UDToastConfig(toastType: .success,
                                   text: BundleI18n.SKResource.CreationMobile_Wiki_Favorites_AddedFavorites_Toast,
                                   operation: operation)
        helper.slideActionInput.accept(.showHUD(.custom(config: config, operationCallback: { [weak helper] _ in
            guard let helper = helper else { return }
            helper.slideActionInput.accept(.hideHUD)
            helper.slideActionInput.accept(.openURL(url: DocsUrlUtil.spaceFavoriteList, context: nil))
        })))
    }

    func toggleQuickAccess(for entry: SpaceEntry) {
        guard let helper = helper else { return }
        let addPin = !entry.pined
        var item = SpaceItem(objToken: entry.objToken, objType: entry.docsType)
        //本体在Wiki的Space Shortcut需要取一下WikiToken
        if entry.isShortCut, entry.originInWiki, let wikiToken = entry.bizNodeToken {
            item = SpaceItem(objToken: wikiToken, objType: .wiki)
        }
        let isPinFolderOperate = UserScopeNoChangeFG.MJ.quickAccessFolderEnable && entry.type == .folder
        
        helper.interactionHelper.update(isPin: addPin, item: item)
            .subscribe { [weak self] in
                guard let self = self else { return }
                if addPin {
                    if UserScopeNoChangeFG.WWJ.newSpaceTabEnable && !isPinFolderOperate {
                        self.showSuccess(with: BundleI18n.SKResource.LarkCCM_NewCM_AddedToPin_Toast)
                    } else {
                        self.showSuccess(with: BundleI18n.SKResource.Doc_List_AddSuccessfully_QuickAccess)
                    }
                } else {
                    if UserScopeNoChangeFG.WWJ.newSpaceTabEnable && !isPinFolderOperate {
                        self.showSuccess(with: BundleI18n.SKResource.LarkCCM_NewCM_RemovedFromPin_Toast)
                    } else {
                        self.showSuccess(with: BundleI18n.SKResource.Doc_List_RemoveSucccessfully)
                    }
                }
                entry.updatePinedStatus(addPin)
                // space shortcut 与 wiki状态协同
                let notificationInfo: [String: Any] = ["targetToken": item.objToken, "objType": item.objType, "addPin": addPin]
                NotificationCenter.default.post(name: Notification.Name.Docs.WikiExplorerPinNode, object: nil, userInfo: notificationInfo)
            } onError: { [weak self] error in
                DocsLogger.error("space.slide.helper --- change pin failed", extraInfo: ["isAddPin": addPin], error: error)
                guard let self = self else { return }
                if (error as NSError).code == DocsNetworkError.Code.workspaceExceedLimited.rawValue {
                    self.showFailure(with: BundleI18n.SKResource.Doc_List_AddStarOverLimit)
                    return
                }
                if let docsError = error as? DocsNetworkError,
                    let message = docsError.code.errorMessage {
                    self.showFailure(with: message)
                    return
                }
                if addPin {
                    self.showFailure(with: BundleI18n.SKResource.Doc_List_AddFailedRetry)
                } else {
                    self.showFailure(with: BundleI18n.SKResource.Doc_List_RemoveFaildRetry)
                }
            }
            .disposed(by: disposeBag)
        helper.slideTracker.reportTogglePin(isPin: addPin, for: entry)
    }

    func toggleSubscribe(for entry: SpaceEntry, result: @escaping ((Bool) -> Void)) {
        guard let helper = helper else { return }
        let isAdd = !entry.subscribed
        let item = SpaceItem(objToken: entry.objToken, objType: entry.docsType)
        helper.interactionHelper.update(isSubscribe: isAdd, subType: 0, item: item)
            .subscribe { [weak self] in
                guard let self = self else { return }
                entry.subscribed = isAdd
                if isAdd {
                    self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_SubscribeSuccess)
                } else {
                    self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_UnsubscribeSuccess)
                }
                result(true)
            } onError: { [weak self] error in
                guard let self = self else { return }
                DocsLogger.error("space.slide.helper --- change subscribe failed", extraInfo: ["isAdd": isAdd], error: error)
                if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                    self.showFailure(with: message)
                } else {
                    self.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed)
                }
                result(false)
            }
            .disposed(by: disposeBag)
    }

    func toggleManualOffline(for entry: SpaceEntry) {
        let isSetManualOffline = entry.isSetManuOffline
        let fileSize = entry.fileSize
        let fileName = entry.realName
        var wikiInfo: WikiInfo?
        if entry.type == .wiki, let wikiEntry = entry as? WikiEntry, let info = wikiEntry.wikiInfo {
            wikiInfo = info
        }
        
        ManualOfflineHelper.handleManualOffline(entry.objToken, type: entry.type, wikiInfo: wikiInfo, isAdd: !isSetManualOffline)
        SpaceStatistic.reportManuOfflineAction(for: entry, module: "drive", isAdd: !isSetManualOffline)
        // toast
        
        if isSetManualOffline {
                self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_RemoveSuccessfully)
        } else {
            networkFlowHelper.checkIfNeedToastWhenOffline(fileSize: fileSize, fileName: fileName ?? "", objToken: entry.objToken, block: {[weak self] (toastType) in
                guard let self = self else { return }
                switch toastType {
                case .manualOfflineSuccessToast:
                    self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_EnableManualCache)
                case let .manualOfflineFlowToast(trueSize):
                    let size = FileSizeHelper.memoryFormat(trueSize)
                    let toastText = BundleI18n.SKResource.CreationMobile_Warning_CellularStreaming_OffLineToast(size)
                    self.showManualOffline(text: toastText,
                                           buttonText: BundleI18n.SKResource.CreationMobile_Warning_CellularStreaming_ButtonClose)
                @unknown default:
                    spaceAssertionFailure()
                }
            })
        }
    }

    func toggleHiddenStatus(for entry: SpaceEntry) {
        guard let helper = helper else { return }
        guard let isHidden = entry.isHiddenStatus else { return }
        helper.interactionHelper.update(isHidden: !isHidden, folderToken: entry.objToken)
            .subscribe { [weak self] in
                guard let self = self else { return }
                entry.updateHiddenStatus(!isHidden)
                if isHidden {
                    self.showSuccess(with: BundleI18n.SKResource.Doc_List_DisplaySuccessfully)
                } else {
                    self.showSuccess(with: BundleI18n.SKResource.Doc_List_HiddenSuccessfully)
                }
                self.helper?.refreshForMoreAction()
            } onError: { [weak self] error in
                DocsLogger.error("space.slide.helper --- change hidden status failed with error", error: error)
                // 错误的提示
                if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                    self?.showFailure(with: message)
                } else {
                    self?.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed)
                }
            }
            .disposed(by: disposeBag)
    }
    
    func toggleHiddenStatusV2(for entry: SpaceEntry) {
        guard let helper = helper else { return }
        guard let isHidden = entry.isHiddenStatus else { return }
        helper.interactionHelper.setHiddenV2(isHidden: !isHidden, folderToken: entry.objToken)
            .subscribe { [weak self] in
                guard let self = self else { return }
                entry.updateHiddenStatus(!isHidden)
                if isHidden {
                    self.showSuccess(with: BundleI18n.SKResource.Doc_List_DisplaySuccessfully)
                } else {
                    self.showSuccess(with: BundleI18n.SKResource.Doc_List_HiddenSuccessfully)
                }
                self.helper?.refreshForMoreAction()
            } onError: { [weak self] error in
                DocsLogger.error("space.slide.helper --- change hidden status failed with error", error: error)
                // 错误的提示
                if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                    self?.showFailure(with: message)
                } else {
                    self?.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed)
                }
            }
            .disposed(by: disposeBag)
    }

    /// 复制链接
    func copyLink(for entry: SpaceEntry) {
        guard let urlString = entry.shareUrl else {
            spaceAssertionFailure("Invalid URL")
            return
        }
        var isSuccess = true
        if entry.originInWiki, let wikiToken = entry.bizNodeToken, let url = URL(string: urlString) {
            // 本体在 wiki 的 space shortcut，复制链接时替换成 wiki url
            let wikiURL = WorkspaceCrossRouter.redirect(spaceURL: url, wikiToken: wikiToken)
            //shouldImmunity传true，表示不受复制粘贴保护
            isSuccess = SKPasteboard.setString(wikiURL.absoluteString,
                                   psdaToken: PSDATokens.Pasteboard.docs_share_link_do_copy,
                              shouldImmunity: true)
        } else {
            isSuccess = SKPasteboard.setString(urlString,
                                   psdaToken: PSDATokens.Pasteboard.docs_share_link_do_copy,
                              shouldImmunity: true)
        }
        if isSuccess {
            self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_CopyLinkSuccessfully)
        }
    }

    // 全量
    func importAsDocs(for entry: SpaceEntry) {
        guard let helper = helper else { return }
        let source: DriveStatisticActionSource = LayoutManager.shared.isGrid ? .spaceGrid : .spaceList
        let parseFileViewController = DocsContainer.shared.resolve(DriveVCFactoryType.self)!
            .makeImportToDriveController(file: entry,
                                         actionSource: source,
                                         previewFrom: .docsList)
        helper.slideActionInput.accept(.showDetail(viewController: parseFileViewController))
    }

    func openSensitivtyLabelSetting(entry: SpaceEntry, level: SecretLevel?) {
        guard let level = level else {
            DocsLogger.warning("level nil")
            return
        }
        helper?.slideActionInput.accept(.copyFile(completion: { hostController in
            let hostVC = hostController
            guard let hostView = hostVC.view,
                  let rootVC = hostVC.view.window?.rootViewController,
                  let from = UIViewController.docs.topMost(of: rootVC) else { return }
            let publicPermissionMeta = DocsContainer.shared.resolve(PermissionManager.self)?.getPublicPermissionMeta(token: entry.objToken)
            let userPermissions = DocsContainer.shared.resolve(PermissionManager.self)?.getUserPermissions(for: entry.objToken)
            let ccmCommonParameters = CcmCommonParameters(fileId: DocsTracker.encrypt(id: entry.objToken),
                                                          fileType: entry.type.name,
                                                          appForm: "none",
                                                          subFileType: entry.fileType,
                                                          module: entry.type.name,
                                                          userPermRole: userPermissions?.permRoleValue,
                                                          userPermissionRawValue: userPermissions?.rawValue,
                                                          publicPermission: publicPermissionMeta?.rawValue)
            let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
            let isIPad = SKDisplay.pad && hostView.isMyWindowRegularSize()

            var wikiToken: String?
            var type = entry.type.rawValue
            var token = entry.objToken
            if entry.type == .wiki, let wikiEntry = entry as? WikiEntry,
               let subTypeToken = wikiEntry.wikiInfo?.objToken, let subType = wikiEntry.wikiInfo?.docsType {
                wikiToken = wikiEntry.wikiInfo?.wikiToken
                token = subTypeToken
                type = subType.rawValue
            }
            let viewModel = SecretLevelViewModel(level: level, wikiToken: wikiToken, token: token, type: type, permStatistic: permStatistics, viewFrom: .moreMenu)
            if isIPad {
                let viewController = IpadSecretLevelViewController(viewModel: viewModel)
                viewController.delegate = self
                let nav = LkNavigationController(rootViewController: viewController)
                nav.modalPresentationStyle = .formSheet
                self.helper?.userResolver.navigator.present(nav, from: from)
            } else {
                let viewController = SecretLevelViewController(viewModel: viewModel)
                viewController.delegate = self
                let nav = LkNavigationController(rootViewController: viewController)
                nav.modalPresentationStyle = .overFullScreen
                nav.transitioningDelegate = viewController.panelTransitioningDelegate
                self.helper?.userResolver.navigator.present(nav, from: from)
            }
            permStatistics.reportMoreMenuPermissionSecurityButtonClick()
        }))
    }

    func addToFolder(for entry: SpaceEntry) {
        if entry.isOffline {
            self.showFailure(with: BundleI18n.SKResource.Doc_List_FailedToDragOfflineDoc)
            return
        }
        guard let helper = self.helper else {
            spaceAssertionFailure("no helper")
            DocsLogger.error("no helper")
            return 
        }
        let tracker = WorkspacePickerTracker(actionType: .createFile, triggerLocation: .topBar)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.Doc_Facade_AddTo,
                                           action: .createSpaceShortcut,
                                           entrances: .spaceOnly,
                                           usingLegacyRecentAPI: true,
                                           tracker: tracker) { _, _ in
            spaceAssertionFailure("add file should not call config callback")
        }
        let context = DirectoryEntranceContext(action: .addTo(srcFile: entry), pickerConfig: config)
        let entranceVC = DirectoryEntranceController(userResolver: helper.userResolver, context: context)
        let nav = UINavigationController(rootViewController: entranceVC)
        nav.modalPresentationStyle = .formSheet
        helper.slideActionInput.accept(.present(viewController: nav, popoverConfiguration: nil))
    }

    func delete(entry: SpaceEntry) {
        helper?.handleDelete(for: entry)
    }

    func rename(entry: SpaceEntry) {
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Facade_Rename, inputView: true)
        let textField = dialog.addTextField(placeholder: BundleI18n.SKResource.Doc_Facade_InputName, text: entry.name)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: { [weak self] in
            if let biz = self?.helper?.slideTracker.bizParameter {
                DocsTracker.reportSpaceDriveRenameClick(click: "cancel", bizParms: biz)
            }
        })
        let button = dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Confirm, dismissCompletion: { [weak dialog, weak self] in
            guard let name = dialog?.textField.text, name.isEmpty == false else { return }
            if entry.isSingleContainerNode {
                self?.renameV2(entry: entry, with: name, completion: nil)
            } else {
                self?.rename(entry: entry, with: name, completion: nil)
            }
            if let biz = self?.helper?.slideTracker.bizParameter {
                DocsTracker.reportSpaceDriveRenameClick(click: "confirm", bizParms: biz)
            }
        })
        dialog.bindInputEventWithConfirmButton(button, initialText: entry.realName ?? "")
        helper?.slideActionInput.accept(.present(viewController: dialog, popoverConfiguration: nil, completion: {
            textField.becomeFirstResponder()
        }))
        if let bizParameter = helper?.slideTracker.bizParameter {
            DocsTracker.reportSpaceDriveRenameView(bizParms: bizParameter)
        }
    }

    // 全量
    private func rename(entry: SpaceEntry, with newName: String, completion: ((Error?) -> Void)?) {
        guard let helper = helper else { return }
        helper.slideActionInput.accept(.showHUD(.loading))
        helper.interactionHelper.rename(objToken: entry.objToken, with: newName)
            .subscribe { [weak helper] in
                helper?.slideActionInput.accept(.hideHUD)
                entry.updateName(newName)
                completion?(nil)
            } onError: { [weak helper] error in
                helper?.slideActionInput.accept(.hideHUD)
                DocsLogger.error("space.slide.helper --- failed to rename file", error: error)
                if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                    helper?.slideActionInput.accept(.showHUD(.failure(message)))
                }
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    private func renameV2(entry: SpaceEntry, with newName: String, completion: ((Error?) -> Void)?) {
        guard let helper = helper else { return }
        helper.slideActionInput.accept(.showHUD(.loading))
        helper.interactionHelper.renameV2(isShortCut: entry.isShortCut,
                                          objToken: entry.objToken,
                                          nodeToken: entry.nodeToken,
                                          newName: newName)
            .subscribe { [weak helper] in
                guard let helper = helper else { return }
                helper.slideActionInput.accept(.hideHUD)
                entry.updateName(newName)
                completion?(nil)
            } onError: { [weak helper] error in
                DocsLogger.error("space.slide.helper --- failed to renameV2 file", error: error)
                guard let helper = helper else { return }
                helper.slideActionInput.accept(.hideHUD)
                if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                    helper.slideActionInput.accept(.showHUD(.failure(message)))
                }
                completion?(error)
            }
            .disposed(by: disposeBag)
    }

    // 全量
    func openWithOtherApp(for entry: SpaceEntry, originName: String?, sourceView: UIView) {
        self.helper?.slideActionInput.accept(.openWithAnother(entry, originName: originName, popoverSourceView: sourceView, arrowDirection: .any))
    }

    // 导出PDF&Word
    func exportDocument(for entry: SpaceEntry,
                        originName: String?,
                        haveEditPermission: Bool,
                        sourceView: UIView) {
        if CacheService.isDiskCryptoEnable() {
            //KACrypto
            DocsLogger.error("[KACrypto] 开启KA加密不能导出文档")
            self.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast)
            return
        }

        let docsInfo = entry.transform()
        if let originName {
            docsInfo.title = originName
        }
        if entry.type == .wiki, let wikiFile = (entry as? WikiEntry), let contenType = wikiFile.wikiInfo?.docsType {
            docsInfo.type = contenType
        }
        if !DocsNetStateMonitor.shared.isReachable {
            self.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed)
            return
        }
        let canEditDocument = canEditBiz(entry, haveEditPermission)
        let bizParameter = SpaceBizParameter(module: .home(.recent))
        let body = ExportDocumentViewControllerBody(docsInfo: docsInfo,
                                                    hostSize: .zero,
                                                    isFromSpaceList: true,
                                                    needFormSheet: false,
                                                    isEditor: canEditDocument,
                                                    hostViewController: nil,
                                                    module: bizParameter.module,
                                                    containerID: bizParameter.containerID,
                                                    containerType: bizParameter.containerType,
                                                    popoverSourceFrame: sourceView.bounds,
                                                    padPopDirection: .any,
                                                    sourceView: sourceView)
        
        helper?.slideActionInput.accept(.exportDocument(exportBody: body))
    }
    
    private func canEditBiz(_ file: SpaceEntry, _ haveEditPermission: Bool) -> Bool {
        guard file.type.isBiz else {
            return false
        }
        if file.ownerIsCurrentUser {
            return true
        }
        if haveEditPermission {
            return true
        }
        return false
    }

    // MARK: - 分享
    func share(entry: SpaceEntry, sourceView: UIView, shareSource: ShareSource) {
        guard entry.shareUrl != nil else { return }
        let fileInfo = entry.transform()

        guard DocsNetStateMonitor.shared.isReachable else {
            showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet)
            return
        }

        let bizParameter = SpaceBizParameter(module: helper?.slideTracker.module ?? .home(.recent))

        //refactor 改用路由方式打开
        let body = SKShareViewControllerBody(needPopover: false,
                                             fileInfo: fileInfo,
                                             router: self,
                                             shareVersion: entry.shareVersion,
                                             fileParentToken: entry.parent,
                                             source: shareSource,
                                             popoverSourceFrame: sourceView.bounds,
                                             padPopDirection: .any,
                                             sourceView: sourceView,
                                             bizParameter: bizParameter)
        
        helper?.slideActionInput.accept(.openShare(shareBody: body))
    }


    func saveToLocal(for entry: SpaceEntry, originName: String?) {
        self.helper?.slideActionInput.accept(.saveToLocal(entry, originName: originName))
    }

    

    func handle(disabledAction: MoreItemType, reason: String, entry: SpaceEntry) {
        showFailure(with: reason)
    }

    func handle(disabledAction: MoreItemType, failure: Bool, reason: String, entry: SpaceEntry) {
        if failure {
            showFailure(with: reason)
        } else {
            showTips(with: reason)
        }
    }

    
    func retentionHandle(entry: SpaceEntry) {
        let vc = RetentionViewController(token: entry.objToken, type: entry.type.rawValue, statiscticParams: helper?.slideTracker.params ?? [:])
        if SKDisplay.pad {
            helper?.slideActionInput.accept(.present(viewController: vc))
        } else {
            helper?.slideActionInput.accept(.push(viewController: vc))
        }
    }
}

extension SpaceListSlideDelegateProxyV2: ShareRouterAbility {
    public func shareRouterToOtherApp(_ vc: UIViewController) -> Bool {
        return false
    }
}

extension SpaceListSlideDelegateProxyV2: SecretLevelSelectDelegate, SecretModifyOriginalViewDelegate {
    private func showSecretModifyOriginalViewController(viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        helper?.slideActionInput.accept(.copyFile(completion: { hostController in
            let hostVC = hostController
            guard let rootVC = hostVC.view.window?.rootViewController,
                  let from = UIViewController.docs.topMost(of: rootVC) else { return }
            let viewModel: SecretModifyViewModel = SecretModifyViewModel(approvalType: viewModel.approvalType,
                                                                         originalLevel: viewModel.level,
                                                                         label: levelLabel, wikiToken: viewModel.wikiToken, token: viewModel.token,
                                                                         type: viewModel.type, approvalDef: viewModel.approvalDef, approvalList: viewModel.approvalList, permStatistic: viewModel.permStatistic)
            let isIPad = from.isMyWindowRegularSize()
            if isIPad {
                let viewController = IpadSecretModifyOriginalViewController(viewModel: viewModel)
                viewController.delegate = self
                let nav = LkNavigationController(rootViewController: viewController)
                nav.modalPresentationStyle = .formSheet
                self.helper?.userResolver.navigator.present(nav, from: from)
            } else {
                let viewController = SecretModifyOriginalViewController(viewModel: viewModel)
                viewController.delegate = self
                let nav = LkNavigationController(rootViewController: viewController)
                nav.modalPresentationStyle = .overFullScreen
                nav.transitioningDelegate = viewController.panelTransitioningDelegate
                self.helper?.userResolver.navigator.present(nav, from: from)
            }
        }))
    }
    func didClickConfirm(_ view: UIViewController, viewModel: SecretLevelViewModel, didUpdate: Bool, showOriginalView: Bool) {
        guard didUpdate else {
            DocsLogger.error("didUpdate false")
            return
        }
        if showOriginalView {
            showSecretModifyOriginalViewController(viewModel: viewModel)
        } else {
            if viewModel.shouldShowUpgradeAlert {
                showUpgradeAlert(viewModel: viewModel)
            } else {
                upgradeSecret(viewModel: viewModel)
            }
        }
    }
    func didClickCancel(_ view: UIViewController, viewModel: SecretLevelViewModel) {}
    func didSelectRow(_ view: UIViewController, viewModel: SecretLevelViewModel) {}
    func didUpdateLevel(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        helper?.interactionHelper.updateSecLabel(wikiToken: viewModel.wikiToken, token: viewModel.token, name: viewModel.label.name)
    }
    func didSubmitApproval(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        viewModel.reportCcmPermissionSecurityDemotionResultView(success: true)
        let dialog = SecretApprovalDialog.sendApprovaSuccessDialog { [weak self] in
            guard let self = self else { return }
            self.showApprovalCenter(viewModel: viewModel)
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "view_checking")
        } define: {
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "known")
        }
        helper?.slideActionInput.accept(.present(viewController: dialog, popoverConfiguration: nil, completion: {

        }))
    }
    func didClickCancel(_ view: UIViewController, viewModel: SecretModifyViewModel) {}
    func shouldApprovalAlert(_ view: UIViewController, viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.info("select level label is nil")
            return
        }
        viewModel.reportCcmPermissionSecurityDemotionResubmitView()
        switch viewModel.approvalType {
        case .SelfRepeatedApproval:
            let dialog = SecretApprovalDialog.selfRepeatedApprovalDialog {
                viewModel.reportCcmPermissionSecurityDemotionResubmitView()
            } define: { [weak self] in
                guard let self = self else { return }
                self.showSecretModifyOriginalViewController(viewModel: viewModel)
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "confirm")
            }
            helper?.slideActionInput.accept(.present(viewController: dialog, popoverConfiguration: nil, completion: {

            }))
        case .OtherRepeatedApproval:
            let dialog = SecretApprovalDialog.otherRepeatedApprovalDialog(num: viewModel.otherRepeatedApprovalCount, name: levelLabel.name) { [weak self] in
                guard let self = self else { return }
                self.showApprovalList(viewModel: viewModel)
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "member_hover")
            } cancel: {
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "cancel")
            } define: { [weak self] in
                guard let self = self else { return }
                self.showSecretModifyOriginalViewController(viewModel: viewModel)
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "confirm")
            }
            helper?.slideActionInput.accept(.present(viewController: dialog, popoverConfiguration: nil, completion: {

            }))
        default: break
        }
    }
    private func showApprovalCenter(viewModel: SecretModifyViewModel) {
        guard let config = SettingConfig.approveRecordProcessUrlConfig else {
            DocsLogger.error("config is nil")
            return
        }
        guard let instanceId = viewModel.instanceCode else {
            DocsLogger.error("instanceId is nil")
            return
        }
        let urlString = config.url + instanceId
        guard let url = URL(string: urlString) else {
            DocsLogger.error("url is nil")
            return
        }

        helper?.slideActionInput.accept(.copyFile(completion: { [weak self] hostController in
            let hostVC = hostController
            guard let rootVC = hostVC.view.window?.rootViewController,
                  let from = UIViewController.docs.topMost(of: rootVC) else {
                DocsLogger.error("rootVC or from nil")
                return
            }
            self?.helper?.userResolver.navigator.push(url, from: from)
        }))
    }
    private func showApprovalList(viewModel: SecretLevelViewModel) {
        guard let approvalList = viewModel.approvalList else {
            DocsLogger.error("approvalList nil")
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        let viewModel = SecretApprovalListViewModel(label: levelLabel, instances: approvalList.instances(with: levelLabel.id),
                                                    wikiToken: viewModel.wikiToken, token: viewModel.token,
                                                    type: viewModel.type, permStatistic: viewModel.permStatistic,
                                                    viewFrom: .resubmitView)
        helper?.slideActionInput.accept(.copyFile(completion: { hostController in
            let hostVC = hostController
            guard let rootVC = hostVC.view.window?.rootViewController,
                  let from = UIViewController.docs.topMost(of: rootVC) else {
                DocsLogger.error("rootVC or from nil")
                return
            }
            let vc = SecretLevelApprovalListViewController(viewModel: viewModel, needCloseBarItem: true)
            let navVC = LkNavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = from.isMyWindowRegularSizeInPad ? .formSheet :.fullScreen
            self.helper?.userResolver.navigator.present(navVC, from: from)
        }))
    }
    private func upgradeSecret(viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        guard let helper = helper else { return }
        helper.slideActionInput.accept(.showHUD(.loading))
        helper.interactionHelper.updateSecLabel(wikiToken: viewModel.wikiToken, token: viewModel.token, type: viewModel.type, label: levelLabel, reason: "")
            .subscribe { [weak helper] in
                DocsLogger.info("space.slide.helper --- success to update secLabel file")
                guard let helper = helper else { return }
                helper.slideActionInput.accept(.hideHUD)
                helper.slideActionInput.accept(.showHUD(.success(BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast)))
            } onError: { [weak helper] error in
                DocsLogger.error("space.slide.helper --- failed to update secLabel file", error: error)
                guard let helper = helper else { return }
                helper.slideActionInput.accept(.hideHUD)
                if let docsError = error as? DocsNetworkError,
                let message = docsError.code.errorMessage {
                    helper.slideActionInput.accept(.showHUD(.failure(message)))
                } else {
                    helper.slideActionInput.accept(.showHUD(.failure(BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed)))
                }
            }
            .disposed(by: disposeBag)
    }

    private func showUpgradeAlert(viewModel: SecretLevelViewModel) {
        let dialog = SecretApprovalDialog.secretLevelUpgradeDialog { [weak self] in
            guard let self = self else { return }
            self.upgradeSecret(viewModel: viewModel)
        }
        helper?.slideActionInput.accept(.present(viewController: dialog, popoverConfiguration: nil, completion: {

        }))
    }
}
