//
//  InsideMoreDataProvider.swift
//  SpaceKit
//
//  Created by lizechuang on 2021/3/4.
//
//swiftlint:disable file_length
//swiftlint:disable type_body_length

import SKFoundation
import SKUIKit
import SKResource
import EENavigator
import LarkUIKit
import UniverseDesignToast
import RxSwift
import SwiftyJSON
import UniverseDesignDialog
import UniverseDesignColor
import LarkSecurityComplianceInterface
import SpaceInterface
import SKInfra
import LarkTab
import LarkQuickLaunchInterface
import LarkContainer
import LarkStorage
import LarkSplitViewController

open class InsideMoreDataProvider: MoreDataProvider {
    public var docsInfo: DocsInfo
    public var fileEntry: SpaceEntry
    public let dataModel: SpaceManagementAPI
    public var fileSize: Int64
    public weak var hostViewController: UIViewController?

    lazy var shareUrlEncoder: DocsPrivacyEncoder = {
        return DocsPrivacyEncoder(.shareUrl)
    }()

    // 权限
    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    public var userPermissions: UserPermissionAbility?
    public let permissionService: UserPermissionService

    @available(*, deprecated, message: "Use versionPermissionService instead - PermissionSDK")
    public var versionPermissions: UserPermissionAbility?
    public let versionPermissionService: UserPermissionService?

    public var publicPermissionMeta: PublicPermissionMeta?

    public weak var followAPIDelegate: SpaceFollowAPIDelegate?
    public weak var docComponentHostDelegate: DocComponentHostDelegate?

    open var builder: MoreItemsBuilder {
        return .empty
    }
    open var updater: MoreDataSourceUpdater?

    private var disposeBag = DisposeBag()

    var trackerParams: [String: Any]?

    // 外部控制hidden Or disable
    // Drive场景 & UtilMore 前端控制
    public var outsideControlItems: MoreDataOutsideControlItems?
    private var request: DocsRequest<JSON>?
    public var retentionVisable: Bool = false

    public private(set) var isInQuickLaunchWindow: Bool?
    @InjectedUnsafeLazy public var quickLaunchService: QuickLaunchService
    @InjectedUnsafeLazy public var temporaryTabService: TemporaryTabService
    public let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!

    public init(docsInfo: DocsInfo,
                fileEntry: SpaceEntry,
                fileSize: Int64 = 0,
                hostViewController: UIViewController,
                userPermissions: UserPermissionAbility? = nil,
                permissionService: UserPermissionService?,
                versionPermissions: UserPermissionAbility? = nil,
                versionPermissionService: UserPermissionService? = nil,
                publicPermissionMeta: PublicPermissionMeta? = nil,
                outsideControlItems: MoreDataOutsideControlItems? = nil,
                followAPIDelegate: SpaceFollowAPIDelegate?,
                docComponentHostDelegate: DocComponentHostDelegate?,
                trackerParams: [String: Any]? = nil) {
        self.docsInfo = docsInfo
        self.fileEntry = fileEntry
        self.hostViewController = hostViewController
        self.userPermissions = userPermissions
        self.versionPermissions = versionPermissions
        self.permissionService = permissionService ?? permissionSDK.userPermissionService(for: .document(token: docsInfo.token, type: docsInfo.inherentType))
        if let versionInfo = docsInfo.versionInfo {
            self.versionPermissionService = versionPermissionService
            ?? permissionSDK.userPermissionService(for: .document(token: versionInfo.versionToken, type: docsInfo.inherentType))
        } else {
            self.versionPermissionService = versionPermissionService
        }
        self.publicPermissionMeta = publicPermissionMeta
        self.outsideControlItems = outsideControlItems
        self.followAPIDelegate = followAPIDelegate
        self.docComponentHostDelegate = docComponentHostDelegate
        self.dataModel = DocsContainer.shared.resolve(SpaceManagementAPI.self)!
        self.fileSize = fileSize
        self.trackerParams = trackerParams

        // 初始化权限
        self.fetchPermission()
        self.fetchVersionPermission()
        self.fetchPublicPermission()
        self.fetchStatusAggregation()
        self.fetchContainerInfo()
        self.fetchDocsInfoMeta()
        self.launchCustomerService()
        self.setupNetworkObserver()
        self.canShowRetentionItem()
        self.checkIsInQuickLuanchWindow()
    }
    
    public lazy var actionHandler: InsideMoreActionHandler = {
       let handler = createMoreActionHandler()
       return handler
    }()
    
    open func createMoreActionHandler() -> InsideMoreActionHandler {
        return InsideMoreActionHandler(hostVC: hostViewController, spaceAPI: dataModel, from: .more)
    }

    // MARK: - Items & Actions - horizontal
    // 实例可共用Items
    // 置顶能力
    open var feedShortcut: MoreItem? {
        return nil
    }

    // 分享
    open var share: MoreItem? {
        return nil
    }

    // 分享版本
    open var shareVersion: MoreItem? {
        return nil
    }

    // 添加到浮窗
    open var suspend: MoreItem? {
        return nil
    }

    // 收藏
    open var star: MoreItem? {
        MoreItem(type: docsInfo.stared ? .unStar : .star) {
            docsInfo.canShowStarAction && DocsConfigManager.isShowStar
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.star)
                return
            }
            let fileEntry = self.docsInfo.actualFileEntry
            let fileMeta = SpaceMeta(objToken: fileEntry.objToken, objType: fileEntry.docsType)
            let addStar = !self.docsInfo.stared
            let notificationInfo: [String: Any] = [
                "objType": fileEntry.docsType,
                "objToken": fileEntry.objToken,
                "addStar": addStar
            ]
            if !addStar {
                self.dataModel.removeStar(fileMeta: fileMeta) { (error) in
                    guard error == nil else {
                        DocsLogger.error("error \(error.debugDescription)")
                        return
                    }
                    NotificationCenter.default.post(name: Notification.Name.Docs.wikiExplorerStarNode, object: nil, userInfo: notificationInfo)
                    self.showSuccess(with: BundleI18n.SKResource.CreationMobile_Wiki_Favorites_CanceledFavorites_Toast)
                    self.docsInfo.stared = false
                    self.reportCancelStar(file: fileEntry)
                }
            } else {
                self.dataModel.addStar(fileMeta: fileMeta) { (error) in
                    guard error == nil else {
                        DocsLogger.error("error \(error.debugDescription)")
                        return
                    }
                    NotificationCenter.default.post(name: Notification.Name.Docs.wikiExplorerStarNode, object: nil, userInfo: notificationInfo)
                    self.showFavoriteSuccess()
                    self.docsInfo.stared = true
                    self.reportAddStar(file: fileEntry)
                }
            }
        }
    }

    // 快速访问
    open var pin: MoreItem? {
        MoreItem(type: docsInfo.pined ? .unPin : .pin) {
            docsInfo.canShowPinAction
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.pin)
                return
            }
            let fileEntry = self.docsInfo.actualFileEntry
            let fileMeta = SpaceMeta(objToken: fileEntry.objToken, objType: fileEntry.docsType)
            let addPin = !self.docsInfo.pined
            let notificationInfo: [String: Any] = ["targetToken": fileEntry.objToken, "objType": fileEntry.docsType, "addPin": addPin]
            if !addPin {
                self.dataModel.removePin(fileMeta: fileMeta) { (error) in
                    guard error == nil else {
                        DocsLogger.error("error \(error.debugDescription)")
                        return
                    }
                    if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                        self.showSuccess(with: BundleI18n.SKResource.LarkCCM_NewCM_RemovedFromPin_Toast)
                    } else {
                        self.showSuccess(with: BundleI18n.SKResource.Doc_List_RemoveSucccessfully)
                    }
                    self.docsInfo.pined = false
                    self.reportCancelPin(file: fileEntry)
                    // Wiki目录树 和 快速访问列表 本地协同
                    NotificationCenter.default.post(name: Notification.Name.Docs.WikiExplorerPinNode, object: nil, userInfo: notificationInfo)
                    NotificationCenter.default.post(name: Notification.Name.Docs.quickAccessUpdate, object: nil)
                }
            } else {
                self.dataModel.addPin(fileMeta: fileMeta) { (error) in
                    guard error == nil else {
                        DocsLogger.error("error \(error.debugDescription)")
                        return
                    }
                    if UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
                        self.showSuccess(with: BundleI18n.SKResource.LarkCCM_NewCM_AddedToPin_Toast)
                    } else {
                        self.showSuccess(with: BundleI18n.SKResource.Doc_List_AddSuccessfully_QuickAccess)
                    }
                    self.docsInfo.pined = true
                    self.reportAddPin(file: fileEntry, success: error == nil)
                    // Wiki目录树 和 快速访问列表 本地协同
                    NotificationCenter.default.post(name: Notification.Name.Docs.WikiExplorerPinNode, object: nil, userInfo: notificationInfo)
                    NotificationCenter.default.post(name: Notification.Name.Docs.quickAccessUpdate, object: nil)
                }
            }
        }
    }

    // 手动离线
    open var offline: MoreItem? {
        return nil
    }

    // 添加至
    open var addTo: MoreItem? {
        return nil
    }
    // 添加快捷方式
    open var addShortCut: MoreItem? {
        MoreItem(type: .addShortCut) {
            docsInfo.canShowAddToAction && DocsConfigManager.isShowFolder
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.addShortCut)
                return
            }
            let srcFile = self.docsInfo.fileEntry
            if srcFile.isOffline {
                self.showFailure(with: BundleI18n.SKResource.Doc_List_FailedToDragOfflineDoc)
                return
            }
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                guard let self = self else { return }
                self.showShortcutPicker(docsInfo: self.docsInfo)
            }
        }
    }

    private func showShortcutPicker(docsInfo: DocsInfo) {
        let tracker = WorkspacePickerTracker(actionType: .shortcutTo, triggerLocation: .topBar)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_AddShortcutTo_Header_Mob,
                                           action: .createSpaceShortcut,
                                           entrances: .wikiAndSpace,
                                           ownerTypeChecker: { isSingleFolder in
            if isSingleFolder {
                return nil
            } else {
                return BundleI18n.SKResource.CreationMobile_ECM_UnableShortToast
            }
        },
                                           tracker: tracker) { [weak self] location, picker in
            guard let self else { return }
            switch location {
            case let .wikiNode(location):
                self.shortcutDuplicateCheck(objToken: docsInfo.objToken,
                                            objType: docsInfo.type,
                                            location: .wikiNode(location: location),
                                            picker: picker) { showLoading in
                    self.confirmShortcutToWiki(docsInfo: docsInfo, location: location, picker: picker, showLoading: showLoading)
                }
            case let .folder(location):
                self.shortcutDuplicateCheck(objToken: docsInfo.objToken,
                                            objType: docsInfo.type,
                                            location: .folder(location: location),
                                            picker: picker) { showLoading in
                    self.confirmShortcutToSpace(docsInfo: docsInfo, location: location, picker: picker, showLoading: showLoading)
                }
            }
        }
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)
        guard let hostVC = hostViewController else { return }
        Navigator.shared.present(picker, from: hostVC, animated: true)
    }

    private func confirmShortcutToWiki(docsInfo: DocsInfo, location: WikiPickerLocation, picker: UIViewController, showLoading: Bool) {
        let toastView: UIView = picker.view.window ?? picker.view
        if showLoading {
            UDToast.showDefaultLoading(on: toastView)
        }
        dataModel.shortcutToWiki(objToken: docsInfo.token, objType: docsInfo.inherentType, title: docsInfo.name, location: location)
            .subscribe { [weak self] wikiToken in
                guard let self = self else { return }
                let url = DocsUrlUtil.url(type: .wiki, token: wikiToken)
                self.showShortcutSuccess(url: url, toastView: toastView)
                picker.dismiss(animated: true)
            } onError: { [weak self] error in
                guard let self = self else { return }
                let code = (error as NSError).code
                let message: String
                if let wikiError = WikiErrorCode(rawValue: code) {
                    message = wikiError.createShortcutErrorDescription
                } else if let docsError = error as? DocsNetworkError,
                          let errorMessage = docsError.code.errorMessage {
                    message = errorMessage
                } else {
                    message = BundleI18n.SKResource.Doc_List_FolderSelectAdd + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                }
                UDToast.showFailure(with: message, on: toastView)
            }
            .disposed(by: disposeBag)
    }

    private func confirmShortcutToSpace(docsInfo: DocsInfo, location: SpaceFolderPickerLocation, picker: UIViewController, showLoading: Bool) {
        guard location.canCreateSubNode else {
            showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantShortcut_Tooltip)
            return
        }
        let toastView: UIView = picker.view.window ?? picker.view
        if showLoading {
            UDToast.showDefaultLoading(on: toastView)
        }
        dataModel.createShortCut(objToken: docsInfo.token, objType: docsInfo.inherentType, folderToken: location.folderToken)
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                let url: URL
                if location.folderToken.isEmpty {
                    url = UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? DocsUrlUtil.cloudDriveMyFolderURL : DocsUrlUtil.mySpaceURL
                } else {
                    url = DocsUrlUtil.url(type: .folder, token: location.folderToken)
                }
                self.showShortcutSuccess(url: url, toastView: toastView)
                picker.dismiss(animated: true)
            } onError: { [weak self] error in
                guard let self = self else { return }
                let message: String
                if let docsError = error as? DocsNetworkError,
                   let errorMessage = docsError.code.errorMessage {
                    message = errorMessage
                } else {
                    message = BundleI18n.SKResource.Doc_List_FolderSelectAdd + BundleI18n.SKResource.Doc_AppUpdate_FailRetry
                }
                UDToast.showFailure(with: message, on: toastView)
            }
            .disposed(by: disposeBag)
    }

    private func showShortcutSuccess(url: URL, toastView: UIView) {
        let operation = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Wiki_ClickToView_Toast,
                                               displayType: .horizontal)
        let config = UDToastConfig(toastType: .success,
                                   text: BundleI18n.SKResource.CreationMobile_Wiki_Shortcuts_CreateSuccessfully_Toast,
                                   operation: operation,
                                   delay: 5)
        UDToast.showToast(with: config, on: toastView, operationCallBack: { [weak self] _ in
            guard let self = self else { return }
            guard let rootVC = self.hostViewController?.view.window?.rootViewController,
                  let from = UIViewController.docs.topMost(of: rootVC) else { return }
            self.openCopyFileWith(url, from: from)
        })
    }
    
    private func shortcutDuplicateCheck(objToken: String,
                                        objType: DocsType,
                                        location: WorkspacePickerLocation,
                                        picker: UIViewController,
                                        callBack: @escaping ((_ showLoading: Bool) -> Void)) {
        let toastView: UIView = picker.view.window ?? picker.view
        UDToast.showDefaultLoading(on: toastView)
        WorkspaceCrossNetworkAPI.addShortcutDuplicateCheck(objToken: objToken,
                                                           objType: objType,
                                                           location: location)
        .subscribe(onSuccess: { [weak self] stages in
            switch stages {
            case .hasEntity, .hasShortcut:
                UDToast.removeToast(on: toastView)
                self?.confirmAddShortcutInDuplicateStages(stages: stages, picker: picker, compeltion: {
                    callBack(true)
                    DocsTracker.shortcutDuplicateCheckClick(stages: stages, click: "add", fileId: objToken, fileTypeName: objType.name)
                })
            case .normal:
                callBack(false)
            }
        }, onError: { error in
            DocsLogger.error("space.file.more: shortcut duplicate check error: \(error)")
            callBack(false)
        })
        .disposed(by: disposeBag)
    }
    
    private func confirmAddShortcutInDuplicateStages(stages: CreateShortcutStages, picker: UIViewController, compeltion: @escaping (() -> Void)) {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.LarkCCM_Workspace_AddShortcut_Repitition_Title)
        dialog.setContent(text: stages.contentString)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_AddShortcut_Repitition_Cancel_Button, dismissCompletion:  {
            DocsTracker.shortcutDuplicateCheckClick(stages: stages, click: "cancel")
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.LarkCCM_Workspace_AddShortcut_Repitition_Add_Button, dismissCompletion:  {
            compeltion()
        })
        DocsTracker.shortcutDuplicateCheckView(stages: stages)
        picker.present(dialog, animated: true)
    }

    // 删除
    open var delete: MoreItem? {
        MoreItem(type: .delete) {
            guard !isDocComponent else {
                return false
            }
            if docsInfo.isSingleContainerNode {
                if UserScopeNoChangeFG.WWJ.spaceApplyDeleteEnabled {
                    if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                        return permissionService.validate(operation: .isFullAccess).allow && docsInfo.canShowDeleteAction
                    } else {
                        return userPermissions?.isFA == true && docsInfo.canShowDeleteAction
                    }
                } else {
                    return docsInfo.ownerID == User.current.info?.userID && docsInfo.canShowDeleteAction
                }
            } else {
                return docsInfo.ownerID == User.current.info?.userID && docsInfo.canShowDeleteAction
            }
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.delete)
                return
            }
            self.reportClickDeleteFile()
            var typeName = self.docsInfo.type.i18Name
            if self.docsInfo.type == .file {
                typeName = BundleI18n.SKResource.Doc_Contract_DocumentTypeFile
            }
            let name = self.docsInfo.name
            let (title, content) = (BundleI18n.SKResource.Doc_Contract_Remove_Owner_Document_Dialog_Title(typeName, name),
                                                 BundleI18n.SKResource.Doc_Contract_Remove_Owner_Document_Dialog_Content)
            let dialog = UDDialog()
            dialog.setTitle(text: title, checkButton: false)
            dialog.setContent(text: content, checkButton: false)
            dialog.isAutorotatable = true
            dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
            dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_Delete, dismissCompletion: {
                self.actionHandler.deleteFile(docsInfo: self.docsInfo) { deleted in
                    if deleted {
                        self.deleteCurrentFile()
                        NotificationCenter.default.post(name: .Docs.deleteDocInNewHome, object: self.docsInfo.objToken)
                    }
                }
            })
            guard let hostVC = self.hostViewController else { return }
            Navigator.shared.present(dialog, from: hostVC, animated: true)
        }
    }

    // 查看最新文档
    open var sourceDocs: MoreItem? {
        return nil
    }

    // 交由子类自定义实现, 删除成功后业务的处理逻辑
    open func deleteCurrentFile() {}

    // 删除版本
    open func deleteCurrentVersion() {

    }

    // MARK: - Items & Actions - vertical
    // 使用浏览器打开
    open var openInBrowser: MoreItem? {
        MoreItem(type: .openInBrowser) { () -> Bool in
            return SKDisplay.pad && !CacheService.isDiskCryptoEnable()
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.openInBrowser)
                return
            }
            guard let shareUrl = self.docsInfo.shareUrl, !shareUrl.isEmpty else {
                DocsLogger.error("openInBrowser shareUrl is nil")
                return
            }
            self.shareUrlEncoder.generate(origin: shareUrl) { (dst) in
                guard var url = URL(string: dst) else {
                    DocsLogger.error("openInBrowser ulr is invalid")
                    return
                }
                url = url.docs.addQuery(parameters: ["from": "ipad_browser"])
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }

    // 文档信息
    open var readingData: MoreItem {
        MoreItem(type: .readingData(fileEntry.docsType)) { (_, _) in
        }
    }

    // 设置时区
    open var timeZone: MoreItem? {
        return nil
    }

    // 自定义Icon
    open var docsIcon: MoreItem? {
        return nil
    }

    // 文档订阅 ⚠️失败需要重置
    open var subscribe: MoreItem? {
        MoreItem(type: .subscribe, style: .mSwitch(isOn: docsInfo.subscribed, needLoading: true)) { [weak self] () -> Bool in
            guard let self = self else { return false }
            var canShowSubscribeAction = self.docsInfo.canShowSubscribeAction
            if canShowSubscribeAction {
                let hasEditPermission: Bool
                if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                    hasEditPermission = permissionService.validate(operation: .edit).allow
                } else {
                    hasEditPermission = self.userPermissions?.canEdit() ?? false
                }
                if !docsInfo.isSameTenantWithOwner && !hasEditPermission {
                    canShowSubscribeAction = false
                }
            }
            return canShowSubscribeAction
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            let fileEntry = self.docsInfo.actualFileEntry
            let hasSubscribed = self.docsInfo.subscribed
            let isSubscribed = !hasSubscribed
            self.subscribe(isSubscribe: isSubscribed, subType: .docUpdate) { [weak self] in
                self?.docsInfo.subscribed = !hasSubscribed
                if isSubscribed {
                    self?.showSuccess(with: BundleI18n.SKResource.Doc_Facade_SubscribeSuccess)
                    self?.reportAddSubscrible(file: fileEntry)
                } else {
                    self?.showTips(with: BundleI18n.SKResource.Doc_Facade_UnsubscribeSuccess)
                    self?.reportCancelSubscrible(file: fileEntry)
                }
            } failure: { [weak self] in
                self?.docsInfo.subscribed = hasSubscribed
            }
        }
    }

    // 订阅文档评论更新
    open var commentSubscribe: MoreItem? {
        MoreItem(type: .subscribeComment, style: .mSwitch(isOn: docsInfo.subscribedComment, needLoading: true)) { [weak self] () -> Bool in
            guard let self = self else { return false }
            return self.docsInfo.canShowSubscribeCommentAction
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            let isOn = self.docsInfo.subscribedComment
            let isSubscribed = !isOn
            self.subscribe(isSubscribe: isSubscribed, subType: .commentUpdate) { [weak self] in
                guard let self = self else { return }
                self.docsInfo.subscribedComment = !isOn
                if isSubscribed {
                    self.showTips(with: BundleI18n.SKResource.CreationMobile_FollowComment_On_Toast)
                } else {
                    self.showTips(with: BundleI18n.SKResource.CreationMobile_FollowComment_Off_Toast)
                }
                let cacheInstance = DocsContainer.shared.resolve(CommentSubScribeCacheInterface.self)
                cacheInstance?.setCommentSubScribe(!isOn, self.docsInfo.encryptedObjToken)
            } failure: { [weak self] in
                self?.docsInfo.subscribedComment = isOn
            }
        }
    }

    // 设置密级入口
    open var sensitivtyLabel: MoreItem? {
        nil
    }

    // 多维表格高级权限设置
    open var bitableAdvancedPermissions: MoreItem? {
        nil
    }

    // 权限设置
    open var publicPermissionSetting: MoreItem? {
        return nil
    }

    // 正文宽高设置
    open var widescreenModeSwitch: MoreItem? {
        return nil
    }

    // 翻译
    open var translate: MoreItem? {
        return nil
    }

    // 查找
    open var searchReplace: MoreItem? {
        return nil
    }

    // 申请编辑权限
    open var applyEditPermission: MoreItem? {
        return nil
    }

    // 历史记录
    open var historyRecord: MoreItem? {
        return nil
    }

    open var savedVersionList: MoreItem? {
        return nil
    }

    // 目录
    open var catalog: MoreItem? {
        return nil
    }


    // 是否能创建副本
    private func canExportSnap() -> Bool {
        //判断是否要添加副本action
        var canExportSnap = true
        if self.docsInfo.inherentType.isSupportCopy == false {
            canExportSnap = false
        }
        if self.docsInfo.isFromWiki == true, self.docsInfo.isVersion == false {
            canExportSnap = false
        }
        return canExportSnap
    }

    // 创建副本
    open var copyFile: MoreItem? {
        let canCreateCopy: Bool
        let createCopyVisable: Bool
        let createCopyEnable: Bool
        let permissionCompletion: () -> Void
        let validateResut = validateResult(type: .copyFile)
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            let response = permissionService.validate(operation: .createCopy)
            canCreateCopy = response.allow
            createCopyVisable = !response.result.needHidden
            createCopyEnable = !response.result.needDisabled
            permissionCompletion = { [weak self] in
                guard let self, let hostViewController = self.hostViewController else { return }
                let message: String
                if self.outsideControlItems?[.disable]?.contains(.copyFile) == true { // 说明是前端控制置灰的，目前只有 bitable 前端会控制这个置灰
                    message = BundleI18n.SKResource.Bitable_AdvancedPermission_UnableToMakeCopy
                } else {
                    message = BundleI18n.SKResource.LarkCCM_Perms_SaveTemplate_NoCopyPerm_Toast_Mob
                }
                response.didTriggerOperation(controller: hostViewController, message)
            }
        } else {
            createCopyVisable = true
            canCreateCopy = validateResut.allow && (userPermissions?.canDuplicate() ?? false)
            createCopyEnable = canCreateCopy
            permissionCompletion = {}
        }
        return MoreItem(type: .copyFile, preventDismissal: createCopyEnable && !canCreateCopy) { () -> Bool in
            docsInfo.canShowCopyAction && createCopyVisable
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable && createCopyEnable && self.canExportSnap()
        } handler: { [weak self] (item, _) in
            guard let self = self else { return }
            permissionCompletion()
            if canCreateCopy {
                self.actionHandler.copyFileWithPicker(docsInfo: self.docsInfo, fileSize: self.fileSize)
                return
            }
            if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
                // FG 开的弹 Toast 逻辑都在 permissionCompletion 里
                if canCreateCopy, !DocsNetStateMonitor.shared.isReachable {
                    self.handleDisableEvent(.copyFile)
                }
                return
            }
            if !DocsNetStateMonitor.shared.isReachable || !validateResut.allow {
                self.handleDisableEvent(.copyFile)
                return
            }
            guard item.state.isEnable else {
                if !validateResut.allow, validateResut.validateSource == .fileStrategy {
                    CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmCreateCopy, fileBizDomain: .ccm,
                                                                 docType: self.docsInfo.type, token: self.docsInfo.token)
                    return
                }
                if !validateResut.allow {
                    self.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
                }

                if self.outsideControlItems?[.disable]?.contains(.copyFile) == true { // 说明是前端控制置灰的，目前只有 bitable 前端会控制这个置灰
                    self.showTips(with: BundleI18n.SKResource.Bitable_AdvancedPermission_UnableToMakeCopy)
                } else {
                    self.showTips(with: BundleI18n.SKResource.LarkCCM_Perms_SaveTemplate_NoCopyPerm_Toast_Mob)
                }
                return
            }
        }
    }
    
    open var retention: MoreItem? {
        MoreItem(type: .retention, prepareCheck: {
            LKFeatureGating.retentionEnable && retentionVisable && !isVC
        }, prepareEnable: {
            DocsNetStateMonitor.shared.isReachable
        }, handler: {[weak self] _, _ in
            guard let self = self, let hostVC = self.hostViewController else { return }
            let params: [String: Any] = [
                "module": self.docsInfo.fromModule as Any,
                "sub_module": self.docsInfo.fromSubmodule as Any,
                "file_id": DocsTracker.encrypt(id: self.docsInfo.token),
                "file_type": self.docsInfo.type.name,
                "sub_file_type": self.docsInfo.fileType as Any
            ]
            let vc = RetentionViewController(token: self.docsInfo.objToken, type: self.docsInfo.type.rawValue, statiscticParams: params)
            if SKDisplay.pad {
                Navigator.shared.present(vc, from: UIViewController.docs.topLast(of: hostVC) ?? hostVC)
            } else {
                Navigator.shared.push(vc, from: UIViewController.docs.topLast(of: hostVC) ?? hostVC)
            }
        })
    }
    // 交由子类自定义实现
    open func openCopyFileWith(_ fileUrl: URL, from: UIViewController) {}

    // 保存为我的模板V1
    open var saveAsTemplateV1: MoreItem? {
        return nil
    }

    // 转换为模板
    open var changeTemplateTag: MoreItem? {
        return nil
    }

    // 保存为我的模板V2
    open var saveAsTemplateV2: MoreItem? {
        return nil
    }

    // 导出
    open var exportDocument: MoreItem? {
        return nil
    }
    
    open var workbench: MoreItem? {
        return nil
    }
    

    // 客服
    open var customerService: MoreItem? {
        MoreItem(type: .customerService) { () -> Bool in
            LKFeatureGating.suiteHelpServiceDoc
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self, let hostVC = self.hostViewController else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.customerService)
                return
            }
            self.reportClickCustomService()
            if let followAPIDelegate = self.followAPIDelegate, !SKDisplay.pad {
                followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .setFloatingWindow(getFromVCHandler: { fromVC in
                    let service: LarkOpenEvent
                    if let fromVC = fromVC {
                        service = LarkOpenEvent.customerService(controller: fromVC)
                    } else {
                        service = LarkOpenEvent.customerService(controller: UIViewController.docs.topLast(of: hostVC) ?? hostVC)
                    }
                    NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification), object: service)
                })))
            } else {
                let service = LarkOpenEvent.customerService(controller: UIViewController.docs.topLast(of: hostVC) ?? hostVC)
                NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification), object: service)
            }
        }
    }

    // 举报
    open var report: MoreItem? {
        MoreItem(type: .report) { () -> Bool in
            if UserScopeNoChangeFG.PLF.appealV2Enable { return false }
            if DomainConfig.envInfo.isFeishuBrand {
                return LKFeatureGating.spaceReportEnable
            } else {
                return UserScopeNoChangeFG.TYP.larkTnsReport
            }
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self, let hostVC = self.hostViewController else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.report)
                return
            }
            let newURL: URL
            // 这个跟lark确认了，先保留，不适配KA
            let params = "{\"obj_token\":\"\(self.docsInfo.objToken)\",\"obj_type\":\(self.docsInfo.type.rawValue)}".urlEncoded()
            let domain = DomainConfig.larkReportDomain
            let feishuDomain = DomainConfig.suiteReportDomain
            let lang = DocsSDK.currentLanguage.rawValue
            let reportPath = SettingConfig.tnsReportConfig?.reportPath ?? TnsReportConfig.default.reportPath
            if DomainConfig.envInfo.isFeishuBrand {
                guard let url = URL(string: "https://\(feishuDomain)/report/?type=docs&params=\(params)") else {
                    spaceAssertionFailure("feishu appeal URL is nil")
                    return
                }
                newURL = url
            } else {
                if SKFoundationConfig.shared.isStagingEnv {
                    let boe_env = KVPublic.Common.ttenv.value()
                    let urlString = "https://" + domain + reportPath + "/?type=docs&params=\(params)&lang=\(lang)&x-tt-env=\(boe_env)"
                    guard let url = URL(string: urlString) else {
                        spaceAssertionFailure("lark appeal URL is nil")
                        return
                    }
                    newURL = url
                } else {
                    let urlString = "https://" + domain + reportPath + "/?type=docs&params=\(params)&lang=\(lang)"
                    guard let url = URL(string: urlString) else {
                        spaceAssertionFailure("feishu appeal URL is nil")
                        return
                    }
                    newURL = url
                }
            }
            if let followAPIDelegate = self.followAPIDelegate {
                DispatchQueue.main.async {
                    followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .openUrl(url: newURL.absoluteString)))
                }
            } else {
                // 因为单品内需要针对Lark的webview单独设置UA，需要引入LarkMessengerInterface，因此抛到上层进行处理
                let vc = UIViewController.docs.topLast(of: hostVC) ?? hostVC
                HostAppBridge.shared.call(LarkURLService(url: newURL, from: vc))
            }
        }
    }

    // 举报V2
    open var reportV2: MoreItem? {
        MoreItem(type: .report) { () -> Bool in
            guard UserScopeNoChangeFG.PLF.appealV2Enable else { return false }
            if DomainConfig.envInfo.isFeishuBrand {
                return LKFeatureGating.spaceReportEnable
            } else {
                return UserScopeNoChangeFG.TYP.larkTnsReport
            }
        } prepareEnable: { () -> Bool in
            DocsNetStateMonitor.shared.isReachable
        } handler: { [weak self] (item, _) in
            guard let self = self, let hostVC = self.hostViewController else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.report)
                return
            }
            guard let reportURL = AppealLinkTool.reportLink(token: self.docsInfo.objToken, type: self.docsInfo.type) else {
                spaceAssertionFailure("report URL is nil")
                return
            }
            if let followAPIDelegate = self.followAPIDelegate {
                DispatchQueue.main.async {
                    followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .openUrl(url: reportURL.absoluteString)))
                }
            } else {
                // 因为单品内需要针对Lark的webview单独设置UA，需要引入LarkMessengerInterface，因此抛到上层进行处理
                let vc = UIViewController.docs.topLast(of: hostVC) ?? hostVC
                HostAppBridge.shared.call(LarkURLService(url: reportURL, from: vc))
            }
        }
    }

    // 重命名
    open var rename: MoreItem? {
        return nil
    }

    // 重命名版本
    open var renameVersion: MoreItem? {
        return nil
    }

    // 删除版本
    open var deleteVersion: MoreItem? {
        return nil
    }

    // 保存到本地
    open var saveToLocal: MoreItem? {
        return nil
    }

    // 导入为在线文档
    open var importAsDocs: MoreItem? {
        return nil
    }

    // 其他应用打开
    open var openWithOtherApp: MoreItem? {
        return nil
    }

    // 复制链接
    open var copyLink: MoreItem {
        return MoreItem(type: .copyLink) {  () -> Bool in
            UserScopeNoChangeFG.PLF.shareChannelDisable == false
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            guard let url = self.docsInfo.shareUrl else {
                spaceAssertionFailure("Invalid URL")
                return
            }
            let isSuccess = SKPasteboard.setString(url,
                                   psdaToken: PSDATokens.Pasteboard.docs_share_link_do_copy,
                              shouldImmunity: true)
            if isSuccess {
                self.showSuccess(with: BundleI18n.SKResource.Doc_Facade_CopyLinkSuccessfully)
            }
        }
    }

    open var quickLaunch: MoreItem? {
        let itemType: MoreItemType = self.isInQuickLaunchWindow == true ? .unpinFromQuickLaunch : .pinToQuickLaunch
        let isEnableQuickLaunch = quickLaunchService.isQuickLauncherEnabled
        DocsLogger.info("quickLaunch enable: \(isEnableQuickLaunch)")
        return MoreItem(type: itemType) { () -> Bool in
            return isInQuickLaunchWindow != nil && isEnableQuickLaunch  && !isVC
        } prepareEnable: { () -> Bool in
            return true
        } handler: { [weak self] (_, _) in
            guard let self = self else { return }
            guard let isIn = self.isInQuickLaunchWindow else { return }
            var hostVC = self.hostViewController
            // Wiki和版本文档都有父容器
            if self.docsInfo.isFromWiki || self.docsInfo.isVersion {
                hostVC = self.hostViewController?.parent
            }
            guard let containable = hostVC as? TabContainable else { return }
            if isIn {
                self.quickLaunchService.unPinFromQuickLaunchWindow(vc: containable)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        DocsLogger.info("quickLaunch unPinFromQuickLaunchWindow finish")
                    }).disposed(by: self.disposeBag)
            } else {
                self.quickLaunchService.pinToQuickLaunchWindow(vc: containable)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        DocsLogger.info("quickLaunch pinToQuickLaunchWindow finish")
                    }).disposed(by: self.disposeBag)
            }
        }
    }
    
    public var showNewTab: Bool {
        var isMainScene: Bool = true
        if #available(iOS 13.0, *),
           let scene = hostViewController?.currentScene()?.sceneInfo {
            //分屏场景只在主scene上展示按钮
            isMainScene = scene.isMainScene()
        }
        let isEnableQuickLaunch = quickLaunchService.isQuickLauncherEnabled
        return SKDisplay.pad && isEnableQuickLaunch && isInQuickLaunchWindow != nil && !isVC && isMainScene && hostViewController?.isMyWindowRegularSize() == true
    }
    
    open var openInNewTab: MoreItem? {
        return MoreItem(type: .openInNewTab) { () -> Bool in
            showNewTab
        } prepareEnable: { () -> Bool in
            return true
        } handler: { [weak self] (_, _) in
           guard let self = self, let fromVC = self.hostViewController else { return }
            if self.isDocComponent, let url = URL(string: self.docsInfo.urlForSuspendable()) {
                Navigator.shared.docs.showDetailOrPush(url, from: fromVC)
                return
            }
            var hostVC = self.hostViewController
            if self.docsInfo.isFromWiki || self.docsInfo.isVersion {
                hostVC = self.hostViewController?.parent
            }
            guard let containable = hostVC as? TabContainable else { return }
            self.temporaryTabService.showTab(containable)
            // 点击 在标签页中打开 如果此时把 VC 左拉到全屏，切换回云文档Tab会出现类型白屏的情况（云文档Tab没有展示出来）
            if UserScopeNoChangeFG.TYP.openBlankScreen && fromVC.isMyWindowRegularSizeInPad == true {
                guard let vc = hostVC?.lkSplitViewController as? SplitViewController else {
                    DocsLogger.error("InsideMoreDataProvider openInNewTab:vc is not SplitViewController")
                    return
                }
                DocsLogger.info("InsideMoreDataProvider openInNewTab:show docs tab")
                vc.updateSplitMode(.oneOverSecondary, animated: false)
            }
        }
    }
    /// 反馈文档内容过期
    open var reportOutdate: MoreItem? {
        guard let freshStatus = self.docsInfo.freshInfo?.freshStatus else { return nil }
        return MoreItem(
            type: .reportOutdate,
            newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil),
            prepareCheck: {
                guard UserScopeNoChangeFG.ZYP.docFreshnessEnable else { return false }
                guard docsInfo.isSameTenantWithOwner else { return false }
                return !docsInfo.isOwner && freshStatus.shouldShowFeedbackEntry
            },
            prepareEnable: {
                return DocsNetStateMonitor.shared.isReachable
            },
            handler: { [weak self] (_, _) in
                guard let self = self else { return }
                guard let hostVC = self.hostViewController else { return }
                let vc = FreshnessReportViewController(docsInfo: self.docsInfo)
                vc.hostVC = hostVC
                vc.supportOrientations = hostVC.supportedInterfaceOrientations
                if hostVC.isMyWindowRegularSizeInPad {
                    vc.modalPresentationStyle = .formSheet
                    vc.transitioningDelegate = vc.panelFormSheetTransitioningDelegate
                } else {
                    vc.modalPresentationStyle = .overFullScreen
                    vc.transitioningDelegate = vc.panelTransitioningDelegate
                }
                Navigator.shared.present(vc, from: hostVC, animated: true)
            })
    }

    /// 文档时效性
    open var docFreshness: MoreItem? {
        guard let freshInfo = self.docsInfo.freshInfo else { return nil }
        let style: MoreStyle
        if I18nUtil.currentLanguage == I18nUtil.LanguageType.zh_CN && freshInfo.shouldShowFreshStatusLabel() {
            style = .rightIndicator(icon: freshInfo.freshStatus.icon,
                                    title: freshInfo.freshStatus.name)
        } else {
            // 国际化文案内容区域不足，不展示新鲜度信息
            style = .normal
        }
        return MoreItem(
            type: .docFreshness,
            style: style,
            newTagInfo: (true, docsInfo.type, docsInfo.isOwner, nil),
            prepareCheck: {
                guard UserScopeNoChangeFG.ZYP.docFreshnessEnable else { return false }
                guard docsInfo.isSameTenantWithOwner else { return false }
                return docsInfo.isOwner
            },
            prepareEnable: {
                return DocsNetStateMonitor.shared.isReachable
            },
            handler: { [weak self] (_, _) in
                guard let self = self else { return }
                guard let hostVC = self.hostViewController else { return }
                let dependency = FreshSettingDependency(freshInfo: freshInfo,
                                                        objToken: self.docsInfo.objToken,
                                                        objType: self.docsInfo.type,
                                                        statisticParams: self.trackerParams ?? [:])
                let vc = FreshnessSettingViewController(dependency: dependency)
                vc.hostVC = hostVC
                vc.supportOrientations = hostVC.supportedInterfaceOrientations
                if SKDisplay.pad, hostVC.isMyWindowRegularSize() {
                    vc.modalPresentationStyle = .formSheet
                    vc.transitioningDelegate = vc.panelFormSheetTransitioningDelegate
                } else {
                    vc.modalPresentationStyle = .overFullScreen
                    vc.transitioningDelegate = vc.panelTransitioningDelegate
                }
                Navigator.shared.present(vc, from: hostVC, animated: true)
            })
    }

    open var spaceMoveTo: MoreItem? {
        return MoreItem(type: .moveTo) {
            return UserScopeNoChangeFG.ZYP.spaceMoveToEnable && !isVC
        } prepareEnable: { [weak self] in
            guard DocsNetStateMonitor.shared.isReachable else { return false }
            guard self?.docsInfo.containerInfo != nil else { return false }
            return true
        } handler: { [weak self] (item, _) in
            guard let self else { return }
            guard item.state.isEnable else {
                self.handleDisableEvent(.moveTo)
                return
            }
            let context = SpaceMoveInteractionHelper.MoveContext(docsInfo: self.docsInfo)
            self.actionHandler.moveWithPicker(context: context)
        }
    }
}

// MARK: - HUD
extension InsideMoreDataProvider {
    private var viewForHUD: UIView? {
        guard let hostVC = hostViewController else { return nil }
        return hostVC.view.window ?? hostVC.view
    }

    public func showFailure(with: String) {
        guard let viewForHUD = self.viewForHUD else {
            return
        }
        UDToast.showFailure(with: with, on: viewForHUD)
    }

    public func showSuccess(with: String) {
        guard let viewForHUD = self.viewForHUD else {
            return
        }
        UDToast.showSuccess(with: with, on: viewForHUD)
    }

    public func showTips(with: String) {
        guard let viewForHUD = self.viewForHUD else {
            return
        }
        UDToast.showTips(with: with, on: viewForHUD)
    }

    public func showWarning(with: String) {
        guard let viewForHUD = self.viewForHUD else {
            return
        }
        UDToast.showWarning(with: with, on: viewForHUD)
    }

    public func showOfflineToast(text: String, buttonText: String) {
        guard let viewForHUD = self.viewForHUD else {
            return
        }
        let opeartion = UDToastOperationConfig(text: buttonText, displayType: .horizontal)
        let config = UDToastConfig(toastType: .info, text: text, operation: opeartion)
        UDToast.showToast(with: config, on: viewForHUD, delay: 2, operationCallBack: { _ in
            NetworkFlowHelper.dataTrafficFlag = true
            UDToast.removeToast(on: viewForHUD)
        })
    }

    private func showFavoriteSuccess() {
        guard let hostController = hostViewController else {
            return
        }
        let view: UIView = hostController.view.window ?? hostController.view
        let operation = UDToastOperationConfig(text: BundleI18n.SKResource.CreationMobile_Wiki_AddtoFav_GoToButton,
                                               displayType: .auto)
        let config = UDToastConfig(toastType: .success,
                                   text: BundleI18n.SKResource.CreationMobile_Wiki_Favorites_AddedFavorites_Toast,
                                   operation: operation)
        UDToast.showToast(with: config, on: view, delay: 2, operationCallBack: { [weak self, weak hostController] _ in
            guard let hostController, let self else {
                return
            }
            let view: UIView = hostController.view.window ?? hostController.view
            UDToast.removeToast(on: view)
            self.openFavoriteList()
        })
    }

    private func openFavoriteList() {
        if let followAPIDelegate {
            followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .setFloatingWindow(getFromVCHandler: { fromVC in
                guard let fromVC else {
                    return
                }
                LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
                    Navigator.shared.docs.showDetailOrPush(DocsUrlUtil.spaceFavoriteList,
                                                           wrap: LkNavigationController.self,
                                                           from: fromVC)
                }
            })))
        } else {
            guard let hostController = hostViewController else {
                spaceAssertionFailure("get hostVC failed when open favorite list")
                return
            }
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
                Navigator.shared.push(DocsUrlUtil.spaceFavoriteList, from: hostController)
            }
        }
    }
}

// MARK: - 权限
extension InsideMoreDataProvider {
    public var isCurFileOwner: Bool {
        guard let ownderID = docsInfo.ownerID, let userID = User.current.info?.userID else { return false }
        return ownderID == userID
    }

    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    public func hasEditPermission() -> Bool {
        guard let permissionsLo = userPermissions else {
            return false
        }
        return permissionsLo.canEdit()
    }

    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    public func hasExportPermission() -> Bool {
        if docsInfo.ownerID == User.current.info?.userID { return true }
        guard let permissionsLo = userPermissions else {
            return false
        }
        return permissionsLo.canExport()
    }

    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    public func hasPreviewPermission() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            return permissionService.validate(operation: .preview).allow
        } else {
            guard let permissionsLo = userPermissions else {
                return false
            }
            return permissionsLo.canPreview()
        }
    }

    public func fetchPublicPermission() {
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        permissionManager.fetchPublicPermissions(token: docsInfo.objToken, type: docsInfo.type.rawValue) { [weak self] (result, error) in
            DocsLogger.info("get publicPermissions finish", extraInfo: nil, error: error, component: nil)
            guard error == nil, let self = self else { return }
            self.publicPermissionMeta = result
            if let updater = self.updater {
                updater(self.builder)
            }
        }
    }

    public func fetchPermission() {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            fetchPermissionV2()
        } else {
            legacyFetchPermission()
        }
    }

    private func fetchPermissionV2() {
        DocsLogger.info("start fetch permission with PermissionSDK for \(docsInfo.objTokenInLog)")
        permissionService.updateUserPermission().subscribe { [weak self] _ in
            guard let self else { return }
            DocsLogger.info("more view controller update user permission service success", component: LogComponents.permission)
            if let updater = self.updater {
                updater(self.builder)
            }
        } onError: { error in
            DocsLogger.error("more view controller update user permission service error", error: error, component: LogComponents.permission)
        }
        .disposed(by: disposeBag)
    }

    private func legacyFetchPermission() {
        DocsLogger.info("start fetch permission for \(docsInfo.objTokenInLog)")
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        permissionManager.fetchUserPermissions(token: docsInfo.objToken, type: docsInfo.type.rawValue) { [weak self] (info, error) in
            guard let info = info, let self = self else {
                DocsLogger.error("more view controller fetch user permission error", error: error, component: LogComponents.permission)
                return
            }
            self.userPermissions = info.mask
            if let updater = self.updater {
                updater(self.builder)
            }
        }
    }

    public func fetchVersionPermission() {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            fetchVersionPermissionV2()
        } else {
            legacyFetchVersionPermission()
        }
    }

    private func fetchVersionPermissionV2() {
        guard let versionPermissionService else { return }
        DocsLogger.info("start fetch version permission for \(docsInfo.objTokenInLog)")
        versionPermissionService.updateUserPermission().subscribe { [weak self] _ in
            guard let self else { return }
            DocsLogger.info("more view controller update version user permission service success", component: LogComponents.permission)
            if let updater = self.updater {
                updater(self.builder)
            }
        } onError: { error in
            DocsLogger.error("more view controller update version user permission service error", error: error, component: LogComponents.permission)
        }
    }

    private func legacyFetchVersionPermission() {
        guard let versionInfo = docsInfo.versionInfo else { return }
        DocsLogger.info("start fetch version permission for \(docsInfo.objTokenInLog)")
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        permissionManager.fetchUserPermissions(token: versionInfo.versionToken, type: docsInfo.type.rawValue) { [weak self] (info, error) in
            guard let info = info, let self = self else {
                DocsLogger.error("more view controller fetch user permission error", error: error, component: LogComponents.permission)
                return
            }
            self.versionPermissions = info.mask
            if let updater = self.updater {
                updater(self.builder)
            }
        }
    }

    public func fetchDocsInfoMeta() {
        DocsInfoDetailHelper.detailUpdater(for: docsInfo).updateDetail(for: docsInfo)
            .subscribe(onSuccess: { [weak self] in
                guard let self = self else { return }
                self.docsInfo.updatePhoenixShareURLIfNeed()
                if let updater = self.updater {
                    updater(self.builder)
                }
            }, onError: { error in
                let errmsg: String = {
                    let nsErr = error as NSError
                    return "\(nsErr.code):\(nsErr.domain)"
                }()
                DocsLogger.error("fetchDocsInfoMeta error: \(errmsg)")
            })
            .disposed(by: disposeBag)
    }

    public func fetchStatusAggregation() {
        var objToken = docsInfo.objToken
        var objType = docsInfo.type
        if let wikiInfo = docsInfo.wikiInfo {
            objToken = wikiInfo.wikiToken
            objType = .wiki
        }
        let infoTypes: Set<DocsInfoDetailHelper.AggregationInfoType> = [.isStared, .isPined, .isSubscribed, .objUrl]
        DocsInfoDetailHelper.getAggregationInfo(token: objToken, objType: objType, infoTypes: infoTypes, scence: .objDetail)
            .subscribe( onSuccess: { [weak self] result in
                guard let self = self else {
                    DocsLogger.info("Request AggregationInfo error: self is dealloc")
                    return
                }
                switch result {
                case let .success(info):
                    // wiki 的收藏状态不从 aggregation info 接口获取，这里不更新 stared 属性
                    if objType != .wiki, let isStared = info.isStared {
                        self.docsInfo.stared = isStared
                    }
                    // wiki 的pin状态不从 aggregation info 接口获取，这里不更新 pined 属性
                    if objType != .wiki, let isPined = info.isPined {
                        self.docsInfo.pined = isPined
                    }
                    if let isSubscribed = info.isSubscribed {
                        self.docsInfo.subscribed = isSubscribed
                    }
                    if let subscribedComment = info.isSubscribedComment {
                        self.docsInfo.subscribedComment = subscribedComment
                    }

                    if let updater = self.updater {
                        updater(self.builder)
                    }
                    if self.docsInfo.shareUrl == nil || self.docsInfo.shareUrl?.isEmpty == true {
                        if let url = info.url, url.isEmpty == false {
                            self.docsInfo.shareUrl = url
                        } else if objType == .wiki { // 兜底方案，通过拼接的方式
                            self.docsInfo.shareUrl = DocsUrlUtil.url(type: .wiki, token: objToken).absoluteString
                        }
                    }
                    self.docsInfo.updatePhoenixShareURLIfNeed()
                default:
                    // 失败不影响后续流程，不走更新操作
                    DocsLogger.info("Request AggregationInfo failed")
                }
            }, onError: { (error) in
                DocsLogger.error("get status aggregation failed with error", error: error)
            }).disposed(by: disposeBag)
    }

    public func fetchContainerInfo() {
        // 如果已经在 wiki 中打开，这里不再请求 containerInfo
        if docsInfo.isFromWiki {
            return
        }
        // containerInfo 已知就不再请求
        if docsInfo.containerInfo != nil {
            return
        }
        WorkspaceCrossNetworkAPI.getContainerInfo(objToken: docsInfo.token, objType: docsInfo.inherentType)
            .subscribe { [weak self] containerInfo, logID in
                guard let self = self else { return }
                guard let containerInfo = containerInfo else {
                    DocsLogger.info("fetch containerInfo found is_exist false", extraInfo: ["log-id": logID as Any])
                    return
                }
                self.docsInfo.update(containerInfo: containerInfo)
                if LKFeatureGating.phoenixEnabled {
                    self.docsInfo.updatePhoenixShareURLIfNeed()
                }
                if let updater = self.updater {
                    updater(self.builder)
                }
            } onError: { error in
                DocsLogger.error("fetch containerInfo failed with error", error: error)
            }
            .disposed(by: disposeBag)
    }

    // 联系客服需要初始化一些数据
    private func launchCustomerService() {
        HostAppBridge.shared.call(LaunchCustomerService())
    }

    // 返回 isEditor、adminBlocked
    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    public func canEdit(_ token: FileListDefine.ObjToken) -> (Bool, Bool) {
        let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
        // 这里可以信任 permissionManager 缓存，在 UpdateUserPermissionService 设置 UserDefaults 的时候，permissionManager 的缓存也设置过了
        guard let permission = permissionManager.getUserPermissions(for: token) else {
            return (false, false)
        }
        return (permission.canEdit(), permission.adminBlocked())
    }

    public enum ApplyEditScene {
        case userPermission
        case auditExempt
    }

    // 判断是否要添加申请编辑权限
    public func canApplyEditPermission() -> ApplyEditScene? {
        if canApplyEditAuditExempt() {
            // audit 管控但 FG 没开，先不允许申请权限
            guard UserScopeNoChangeFG.WWJ.auditPermissionControlEnable else { return nil }
            return .auditExempt
        }
        // owner不展示
        if docsInfo.ownerID == User.current.info?.userID { return nil }
        //申请编辑权限目前只支持doc sheet mindnote file docx bitable
        let supportType: [DocsType] = [.doc, .sheet, .mindnote, .file, .docX, .bitable]
        if supportType.contains(docsInfo.type) == false {
            return nil
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            return permissionService.validate(operation: .edit).allow ? nil : .userPermission
        } else {
            guard let userPermissions = userPermissions else {
                return nil
            }
            return userPermissions.canEdit() ? nil : .userPermission
        }
    }

    public func canApplyEditAuditExempt() -> Bool {
        guard UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation else { return false }
        let response = permissionService.validate(operation: .edit)
        guard case let .forbidden(denyType, _) = response.result else { return false }
        return denyType == .blockByUserPermission(reason: .blockByAudit)
    }

    // 判断是否展示保留标签
    private func canShowRetentionItem() {
        guard !docsInfo.isFromWiki else {
            DocsLogger.info("retention item can not support wiki")
            return
        }
        guard LKFeatureGating.retentionEnable else {
            DocsLogger.info("retention item featureGating state is closed")
            return
        }
        guard let host = SettingConfig.retentionDomainConfig else {
            DocsLogger.warning("get retention host error")
            return
        }
        let path = "https://" + host + OpenAPI.APIPath.retentionItemVisible
        let params: [String: Any] = ["token": docsInfo.objToken, "entityType": docsInfo.type.entityType]
        request = DocsRequest<JSON>(url: path, params: params)
            .set(method: .GET)
            .start(result: { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    DocsLogger.error("docs more item - Retention error: \(error.localizedDescription)")
                    return
                }
                guard let json = result else {
                    return
                }

                if let status = json["data"]["data"]["canSetRetentionLabel"].bool,
                   let updater = self.updater {
                    self.retentionVisable = status
                    updater(self.builder)
                }
            })
    }

    func checkIsInQuickLuanchWindow() {
        var hostVC = self.hostViewController
        if self.docsInfo.isFromWiki || self.docsInfo.isVersion {
            hostVC = self.hostViewController?.parent
        }
        guard let containable = hostVC as? TabContainable else {
            DocsLogger.warning("hostVC is not TabContainable")
            return
        }
        quickLaunchService.findInQuickLaunchWindow(vc: containable)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] isIn in
                guard let self = self else { return }
                self.isInQuickLaunchWindow = isIn
                if let updater = self.updater {
                    updater(self.builder)
                }
            }.disposed(by: self.disposeBag)
    }
}

// MARK: - 其他限制
extension InsideMoreDataProvider {
    // VC中隐藏翻译、历史记录、删除、浮窗、移动到
    public var isVC: Bool {
        return docsInfo.isInVideoConference ?? false
    }
    
    public var isDocComponent: Bool {
        return self.docComponentHostDelegate != nil
    }
}

// MARK: 网络状态监听
extension InsideMoreDataProvider {
    private func setupNetworkObserver() {
        DocsNetStateMonitor.shared.addObserver(self) { [weak self] (_, _) in
            DispatchQueue.main.async { [weak self] in
                self?.refreshItems()
            }
        }
    }

    private func refreshItems() {
        guard let updater = updater else {
            DocsLogger.info("refresh items failed because updater is nil")
            return
        }
        updater(builder)
    }
}

// MARK: 无网处理
extension InsideMoreDataProvider {
    public func handleDisableEvent(_ itemType: MoreItemType) {
        if !DocsNetStateMonitor.shared.isReachable {
            self.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet)
            return
        }

        /// 合规sdk鉴权失败提示
        switch itemType {
        case .copyFile, .exportDocument, .saveToLocal, .openWithOtherApp, .saveAsTemplate, .importAsDocs:
            let validateResult = validateResult(type: itemType)
            if !validateResult.allow, validateResult.validateSource == .fileStrategy {
                showInterceptDialogFor(type: itemType)
                return
            }
            if !validateResult.allow, validateResult.validateSource == .securityAudit {
                self.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
                return
            }
        default: break
        }


        switch itemType {
        case .copyFile:
            self.showFailure(with: BundleI18n.SKResource.LarkCCM_Perms_SaveTemplate_NoCopyPerm_Toast_Mob)
        case .importAsDocs(_):
            self.showFailure(with: BundleI18n.SKResource.Doc_List_MakeImportToOnlineFileForbidden)
        case .moveTo:
            let type = (docsInfo.type == .folder) ? BundleI18n.SKResource.Doc_Facade_Folder : BundleI18n.SKResource.Doc_Facade_Document
            self.showFailure(with: BundleI18n.SKResource.Doc_List_MakeMoveForbidden(type))
        case .delete, .deleteVersion:
            self.showFailure(with: BundleI18n.SKResource.Doc_List_MakeRemoveForbidden)
        case .rename, .renameVersion:
            let fileType = docsInfo.type.i18Name
            let tip = BundleI18n.SKResource.Doc_Facade_MoreRenameTips(fileType)
            self.showFailure(with: tip)
        case .exportDocument:
            self.showFailure(with: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
        case .openWithOtherApp, .saveToLocal:
            if !self.hasPreviewPermission() {
                self.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast)
                return
            }
            self.showTips(with: BundleI18n.SKResource.Doc_Document_ExportNoPermission)
        case .historyRecord:
            self.showTips(with: BundleI18n.SKResource.Doc_Facade_MoreHistoryTips)
        case .saveAsTemplate:
            self.showTips(with: BundleI18n.SKResource.Doc_List_SaveCustomTemplFailed)
        case .translated:
            self.showFailure(with: BundleI18n.SKResource.LarkCCM_Docs_MagicShare_Translate_NotSupported_Tooltip)
        case .share, .shareVersion, .addTo, .star, .unStar, .subscribe, .addToSuspend, .cancelSuspend,
                .addShortCut, .deleteShortcut, .searchReplace, .translate, .openInBrowser,
                .readingData, .docsIcon, .catalog, .widescreenModeSwitch, .publicPermissionSetting,
                .operationHistory, .customerService, .uploadLog, .feedShortcut, .unFeedShortcut,
                .pin, .unPin, .report, .manualOffline, .cancelManualOffline, .applyEditPermission,
                .switchToTemplate, .pano, .copyLink, .removeFromList, .bitableAdvancedPermissions,
                .setHidden, .setDisplay, .subscribeComment, .documentActivity, .sensitivtyLabel, .wikiClipTop, .wikiUnClip,
                .retention, .timeZone, .openSourceDocs, .savedVersionList, .removeFromWiki, .entityDeleted,
                .workbenchAdded, .workbenchNormal, .pinToQuickLaunch, .unpinFromQuickLaunch,
                .docFreshness, .reportOutdate, .openInNewTab, .unassociateDoc, .quickAccessFolder, .unQuickAccessFolder:
            DocsLogger.error("moreItem handle disable event error")
            assertionFailure("Not set moreItem disable handler event")
        }
    }

    public func handleDisableWikiDeleteEvent(wikiInfo: WikiInfo) {
        guard DocsNetStateMonitor.shared.isReachable else {
            self.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet)
            return
        }
        let state = wikiInfo.wikiNodeState
        var disableReason = BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
        if !state.parentMovePermission {
            if state.parentIsRoot {
                //无空间一级页面可管理权限
                disableReason = BundleI18n.SKResource.LarkCCM_Workspace_DeleteGrayed_SpacePerm_Tooltip
            } else {
                //无父节点可管理权限
                disableReason = BundleI18n.SKResource.LarkCCM_Workspace_DeletePage_ParentPerm_Tooltip
            }
        }
        self.showFailure(with: disableReason)
    }
}

extension InsideMoreDataProvider {
    @available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
    public func showInterceptDialogFor(type: MoreItemType) {
        var operate: LarkSecurityComplianceInterface.EntityOperate = .ccmFileDownload
        switch type {
        case .exportDocument:
            operate = .ccmExport
        case .copyFile, .saveAsTemplate, .importAsDocs:
            operate = .ccmCreateCopy
        case .saveToLocal, .openWithOtherApp:
            operate = .ccmFileDownload
        default:
            spaceAssertionFailure("unknow type")
            break
        }
        CCMSecurityPolicyService.showInterceptDialog(entityOperate: operate, fileBizDomain: .ccm, docType: self.docsInfo.inherentType, token: self.docsInfo.token)
    }
    @available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
    public func validateResult(type: MoreItemType) -> CCMSecurityPolicyService.ValidateResult {
        var operate: LarkSecurityComplianceInterface.EntityOperate = .ccmFileDownload
        switch type {
        case .exportDocument:
            operate = .ccmExport
        case .copyFile, .importAsDocs:
            operate = .ccmCreateCopy
        case .saveAsTemplate:
            if let templateType = docsInfo.templateType, templateType == .pgcTemplate { // `系统模板`不管控
                return CCMSecurityPolicyService.ValidateResult(allow: true, validateSource: .securityAudit)
            } else {
                operate = .ccmCreateCopy
            }
        case .saveToLocal, .openWithOtherApp:
            operate = .ccmFileDownload
        default:
            spaceAssertionFailure("unknow type")
            break
        }
        return CCMSecurityPolicyService.syncValidate(entityOperate: operate, fileBizDomain: .ccm, docType: self.docsInfo.inherentType, token: self.docsInfo.token)
    }
}

// MARK: - 订阅
extension InsideMoreDataProvider {
    enum SubscribeType: Int {
        case docUpdate
        case commentUpdate
    }

    func subscribe(isSubscribe: Bool, subType: SubscribeType, success: @escaping () -> Void, failure: @escaping () -> Void) {
        func showError(error: Error?) {
            if let error = error as NSError?,
               error.domain == "docs.spacekit.unReachable",
               let msg = error.userInfo["errorMsg"] as? String {
                self.showFailure(with: msg)
            } else {
                self.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed)
            }
        }

        func reload() {
            if let updater = self.updater {
                updater(self.builder)
            }
        }

        let fileEntry = self.docsInfo.actualFileEntry
        let fileMeta: SpaceMeta
        if let wikiEntry = fileEntry as? WikiEntry,
           let wikiInfo = wikiEntry.wikiInfo { // wiki类型
            fileMeta = SpaceMeta(objToken: wikiInfo.wikiToken, objType: .wiki)
        } else {
            fileMeta = SpaceMeta(objToken: fileEntry.objToken, objType: fileEntry.docsType)
        }
        if isSubscribe {
            self.dataModel.addSubscribe(fileMeta: fileMeta, subType: subType.rawValue) { (error) in
                guard error == nil else {
                    // Rrefresh
                    showError(error: error)
                    failure()
                    reload()
                    return
                }
                success()
                reload()
            }
        } else {
            self.dataModel.removeSubscribe(fileMeta: fileMeta, subType: subType.rawValue) { (error) in
                guard error == nil else {
                    // Rrefresh
                    showError(error: error)
                    failure()
                    reload()
                    return
                }
                success()
                reload()
            }
        }
    }
}

private extension DocsType {
    // 仅用于文档保留标签设置接口取对应参数使用
    var entityType: String {
        switch self {
        case .doc:
            return "DOC"
        case .sheet:
            return "SHEET"
        case .bitable:
            return "BITABLE"
        case .mindnote:
            return "MINDNOTE"
        case .file:
            return "FILE"
        case .docX:
            return "DOCX"
        case .slides:
            return "SLIDES"
        default:
            DocsLogger.info("retention api can not support the DocsType")
            return ""
        }
    }
}
