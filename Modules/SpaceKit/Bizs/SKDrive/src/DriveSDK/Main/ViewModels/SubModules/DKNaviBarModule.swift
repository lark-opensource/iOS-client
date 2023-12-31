//
//  DKNaviBarModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/22.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import EENavigator
import SpaceInterface
import SKResource
import LarkSecurityComplianceInterface
import SKInfra

class DKNaviBarModule: DKBaseSubModule {
    /// 业务方配置的导航栏按钮，如“更多”
    private let naviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    /// 预览业务配置的额外的导航栏按钮，如“PPT 演示模式”
    private let additionRightNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    private let additionLeftNaviBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    /// 文件标题
    private let titleRelay: BehaviorRelay<String>
    // 根据fileInfo和permission返回的信息控制更多按钮是否可点
    let moreItemEanble = BehaviorRelay<Bool>(value: true)
    let moreItemVisable = BehaviorRelay<Bool>(value: false)
    
    private var naviBarViewModel: DKNaviBarViewModel
    // 避免密钥删除场景下，moreItem刷新信号触发后重新展示
    private var fileKeyHasBeenDelete: Bool = false
    
    deinit {
        DocsLogger.driveInfo("DKNaviBarModule -- deinit")
    }
    override init(hostModule: DKHostModuleType) {
        titleRelay = BehaviorRelay<String>(value: "")
        // 导航栏按钮配置
        let rightBarItemsChanged = Observable<[DKNaviBarItem]>.combineLatest(naviBarItemsRelay, additionRightNaviBarItemsRelay, resultSelector: +)
        let leftBarItemsChanged = Observable<[DKNaviBarItem]>.combineLatest(BehaviorRelay<[DKNaviBarItem]>(value: []), additionLeftNaviBarItemsRelay, resultSelector: +)
        let naviBarDependencyImpl = DKNaviBarDependencyImpl(titleRelay: titleRelay,
                                                            fileDeleted: BehaviorRelay<Bool>(value: false),
                                                            leftBarItems: leftBarItemsChanged,
                                                            rightBarItems: rightBarItemsChanged)
        naviBarViewModel = DKNaviBarViewModel(dependency: naviBarDependencyImpl)
        super.init(hostModule: hostModule)
        setupNaviBarItems(moreDependency: hostModule.moreDependency)
        hostModule.subModuleActionsCenter.accept(.updateNaviBar(vm: naviBarViewModel))
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.fileInfoRelay.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, weak host] info in
            guard let self = self, let host = host else { return }
            self.titleRelay.accept(info.name)
            self.setupNaviBarItems(moreDependency: host.moreDependency)
        }).disposed(by: bag)
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            host.permissionService.onPermissionUpdated.observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, weak host] _ in
                    guard let self, let host else { return }
                    self.setupNaviBarItems(moreDependency: host.moreDependency)
                    // 这里一定是附件场景
                    // 这里有豁免场景，只看用户权限，More 面板内再做按钮维度的详细权限判断
                    let exportResponse = host.permissionService.validate(exemptScene: .driveAttachmentMoreVisable)
                    let visable: Bool = {
                        switch exportResponse.result {
                        case .allow:
                            return true
                        case let .forbidden(denyType, _)
                            where denyType == .blockByUserPermission(reason: .blockByCAC):
                            DocsLogger.driveInfo("show more item when permission block by CAC")
                            return true
                        default:
                            return false
                        }
                    }()
                    self.moreItemVisable.accept(visable)
                })
                .disposed(by: bag)
        } else {
            host.permissionRelay.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self, weak host] info in
                guard let self = self, let host = host else { return }
                self.setupNaviBarItems(moreDependency: host.moreDependency)
                self.moreItemVisable.accept(info.canExport || (info.userPermissions?.canExportlByCAC() == true))
            }).disposed(by: bag)
        }
        host.fileInfoErrorOb
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak host] error in
            guard let self = self, let err = error else { return }
            self.updateNaviBarMoreItem(with: err)
        }).disposed(by: bag)
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            switch action {
            case let .updateAdditionNavibarItem(leftItems, rightItems):
                self?.additionLeftNaviBarItemsRelay.accept(leftItems)
                self?.additionRightNaviBarItemsRelay.accept(rightItems)
            case .clearNaviBarItems:
                self?.naviBarItemsRelay.accept([])
            default:
                break
            }
        }).disposed(by: bag)
        return self
    }
    
    func setupNaviBarItems(moreDependency: DriveSDKMoreDependency) {
        guard let moreNaviBarItem = setupMoreBarItems(moreDependency: moreDependency), !fileKeyHasBeenDelete else {
            naviBarItemsRelay.accept([])
            return
        }
        let naviBarItems: [DKNaviBarItem] = [moreNaviBarItem]
        DocsLogger.driveInfo("drive.sdk.context.main --- setting up naviBar items", extraInfo: ["naviBarItemsCount": naviBarItems.count])
        naviBarItemsRelay.accept(naviBarItems)
    }

    func updateNaviBarMoreItem(with driveError: DriveError) {
        switch driveError {
        case let .serverError(code):
            switch code {
            case DriveFileInfoErrorCode.fileDeletedOnServerError.rawValue,
                 DriveFileInfoErrorCode.fileNotFound.rawValue,
                 DriveFileInfoErrorCode.noPermission.rawValue,
                 DriveFileInfoErrorCode.humanAuditFailureError.rawValue,
                 DriveFileInfoErrorCode.machineAuditFailureError.rawValue:
                moreItemEanble.accept(false)
            case DriveFileInfoErrorCode.fileKeyDeleted.rawValue:
                setupFileKeyHasBeenDeleteState()
            default:
                break
            }
        default:
            break
        }
    }
    
    // swiftlint:disable cyclomatic_complexity
    private func setupMoreBarItems(moreDependency: DriveSDKMoreDependency) -> DKNaviBarItem? {
        guard let host = hostModule else {
            spaceAssertionFailure("host module not found")
            return nil
        }
        let moreMenuEnable = Observable<Bool>.combineLatest(moreItemEanble, moreDependency.moreMenuEnable) { (r1, r2) -> Bool in
            return r1 && r2
        }
        let visable = Observable<Bool>.combineLatest(moreItemVisable, moreDependency.moreMenuVisable) { (r1, r2) -> Bool in
            return r1 && r2
        }
        let moreDependencyImpl = DKMoreDependencyImpl(moreVisable: visable,
                                                      moreEnable: moreMenuEnable,
                                                      isReachable: host.reachabilityChanged,
                                                      saveToSpaceState: Observable<DKSaveToSpaceState>.never())
        let previewFrom = host.commonContext.previewFrom
        var params: [String: Any] = [:]
        if previewFrom == .recent { params = ["scene": "space"] }
        if previewFrom == .im { params = ["scene": "im"] }
        if previewFrom == .calendar { params = ["scene": "calendar"] }
        var moreItems = moreDependency.actions.compactMap { (moreAction) -> DKMoreItem? in
            let info = fileInfo
            switch moreAction {
            case let .customOpenWithOtherApp(action, callback):
                let state: DKMoreItemState
                var response: PermissionResponse?
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    (state, response) = validate(operation: .openWithOtherApp, bizDomain: previewFrom.permissionBizDomainForDownload)
                } else {
                    state = check(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint, docType: .file, token: info.fileToken)
                }
                return DKMoreItem(type: .openWithOtherApp, itemState: state) { [weak self, weak host] sourceView, sourceRect in
                    guard let self = self else { return }
                    if let customAction = action {
                        host?.previewActionSubject.onNext(.customAction(action: customAction))
                    } else {
                        if let response {
                            self.hostModule?.previewActionSubject.onNext(.customAction(action: { controller in
                                response.didTriggerOperation(controller: controller)
                            }))
                        }
                        switch state {
                        case .normal:
                            self.handleOpenWithOtherApp(sourceView: sourceView, sourceRect: sourceRect, callback: { shareType, success in
                                let info = self.fileInfo.attachmentInfo()
                                callback?(info, shareType, success)
                            })
                        case .forbidden:
                            DocsLogger.error("drive.sdk.context.main --- open with other app forbidden",
                                             traceId: response?.traceID)
                        case .deny:
                            DocsLogger.error("drive.sdk.context.main --- admin deny")
                            self.hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                        case .fileDeny:
                            DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                            self.hostModule?.previewActionSubject.onNext(.dialog(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint, docType: .file, token: info.fileToken))
                        }
                    }
                    DriveStatistic.reportClickEvent(DocsTracker.EventType.driveFileMenuClick,
                                                    clickEventType: DriveStatistic.DriveFileMenuClickEvent.openInOtherApp,
                                                    fileId: info.fileID,
                                                    fileType: info.fileType,
                                                    params: params)
                }
            case let .saveToSpace(handler):
                let state: DKMoreItemState
                var response: PermissionResponse?
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    (state, response) = validate(operation: previewFrom.isAttachment ? .uploadAttachment : .upload,
                                                 bizDomain: .ccm)
                } else {
                    if previewFrom.isAttachment {
                        state = self.check(entityOperate: .ccmAttachmentUpload, fileBizDomain: .ccm, docType: .file, token: info.fileToken)
                    } else {
                        state = self.check(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: info.fileToken)
                    }
                }
                return DKMoreItem(type: .saveToSpace, itemState: state) { [weak self] _, _ in
                    guard let self = self else { return }
                    if let response {
                        self.hostModule?.previewActionSubject.onNext(.customAction(action: { controller in
                            response.didTriggerOperation(controller: controller)
                        }))
                    }
                    switch state {
                    case .normal:
                        self.handleSaveToSpace(handler: handler)
                    case .forbidden:
                        DocsLogger.error("drive.sdk.context.main --- save to space forbidden",
                                         traceId: response?.traceID)
                    case .deny:
                        DocsLogger.error("drive.sdk.context.main --- admin deny")
                        self.hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                    case .fileDeny:
                        DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                        if previewFrom.isAttachment {
                            self.hostModule?.previewActionSubject.onNext(.dialog(entityOperate: .ccmAttachmentUpload, fileBizDomain: .ccm, docType: .file, token: info.fileToken))
                        } else {
                            self.hostModule?.previewActionSubject.onNext(.dialog(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: info.fileToken))
                        }
                    }
                    DriveStatistic.reportClickEvent(DocsTracker.EventType.driveFileMenuClick,
                                                    clickEventType: DriveStatistic.DriveFileMenuClickEvent.saveToDrive,
                                                    fileId: info.fileID,
                                                    fileType: info.fileType,
                                                    params: params)
                }
            case let .forward(handler):
                return DKMoreItem(type: .forwardToChat) { [weak self] _, _ in
                    self?.handleForward(handler: handler)
                    self?.hostModule?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.sendToChat, params: [:])
                }
            case let .saveAlbum(handler):
                let state: DKMoreItemState
                var response: PermissionResponse?
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    (state, response) = validate(operation: .saveFileToLocal, bizDomain: previewFrom.permissionBizDomainForDownload)
                } else {
                    state = self.check(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint, docType: .file, token: info.fileToken)
                }
                return DKMoreItem(type: .saveToAlbum, itemState: state, handler: { [weak self](_, _) in
                    guard let self = self else { return }
                    if let response {
                        self.hostModule?.previewActionSubject.onNext(.customAction(action: { controller in
                            response.didTriggerOperation(controller: controller)
                        }))
                    }
                    switch state {
                    case .normal:
                        self.handleSaveToAlbum(handler: handler)
                    case .forbidden:
                        DocsLogger.error("drive.sdk.context.main --- save to album forbidden",
                                         traceId: response?.traceID)
                    case .deny:
                        DocsLogger.error("drive.sdk.context.main --- admin deny")
                        self.hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                    case .fileDeny:
                        DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                        self.hostModule?.previewActionSubject.onNext(.dialog(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint, docType: .file, token: info.fileToken))
                    }
                    self.hostModule?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.saveImage, params: [:])
                })
            case let .saveToFile(handler):
                let state: DKMoreItemState
                var response: PermissionResponse?
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    (state, response) = validate(operation: .saveFileToLocal, bizDomain: previewFrom.permissionBizDomainForDownload)
                } else {
                    state = self.check(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint, docType: .file, token: info.fileToken)
                }
                return DKMoreItem(type: .saveToFile, itemState: state,handler: { [weak self](_, _) in
                    guard let self = self else { return }
                    if let response {
                        self.hostModule?.previewActionSubject.onNext(.customAction(action: { controller in
                            response.didTriggerOperation(controller: controller)
                        }))
                    }
                    switch state {
                    case .normal:
                        self.handleSaveToFile(handler: handler)
                    case .forbidden:
                        DocsLogger.error("drive.sdk.context.main --- save to file forbidden",
                                         traceId: response?.traceID)
                    case .deny:
                        DocsLogger.error("drive.sdk.context.main --- admin deny")
                        self.hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                    case .fileDeny:
                        DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                        self.hostModule?.previewActionSubject.onNext(.dialog(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint, docType: .file, token: info.fileToken))
                    }
                    self.hostModule?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.saveToFile, params: [:])
                })
            case .openWithOtherApp, .IMSaveToLocal:
                spaceAssertionFailure("attach file not support action: \(moreAction)")
                return nil
            case let .saveToLocal(handler):
                let state: DKMoreItemState
                var response: PermissionResponse?
                if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                    (state, response) = validate(operation: .saveFileToLocal, bizDomain: previewFrom.permissionBizDomainForDownload)
                } else {
                    state = self.check(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint, docType: .file, token: info.fileToken)
                }
                return DKMoreItem(type: .saveToLocal, itemState: state,handler: { [weak self](_, _) in
                    guard let self = self else { return }
                    if let response {
                        self.hostModule?.previewActionSubject.onNext(.customAction(action: { controller in
                            response.didTriggerOperation(controller: controller)
                        }))
                    }
                    switch state {
                    case .normal:
                        self.handleSaveToLocal(handler: handler)
                    case .forbidden:
                        DocsLogger.error("drive.sdk.context.main --- save to local forbidden",
                                         traceId: response?.traceID)
                    case .deny:
                        DocsLogger.error("drive.sdk.context.main --- admin deny")
                        self.hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                    case .fileDeny:
                        DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                        self.hostModule?.previewActionSubject.onNext(.dialog(entityOperate: .ccmFileDownload, fileBizDomain: previewFrom.transfromBizDomainDownloadPoint, docType: .file, token: info.fileToken))
                    }
                    DriveStatistic.reportClickEvent(DocsTracker.EventType.driveFileMenuClick,
                                                    clickEventType: DriveStatistic.DriveFileMenuClickEvent.saveToLocal,
                                                    fileId: info.fileID,
                                                    fileType: info.fileType,
                                                    params: params)
                })
            case let .customUserDefine(provider):
                var customParams: [String: Any] = [:]
                customParams["click"] = provider.actionId
                customParams["target"] = "none"
                return DKMoreItem(type: .customUserDefine, text: provider.text, handler: { [weak self](_, _) in
                    self?.handlerCustomUserDefine(handler: provider.handler)
                    DriveStatistic.reportEvent(DocsTracker.EventType.driveFileMenuClick, fileId: info.fileID, fileType: info.fileType.rawValue, params: customParams)
                })
            case .convertToOnlineFile:
                // 第三方附件不支持配置，只有doc和sheet附件支持转在线文档。其他类型附件暂不支持
                spaceAssertionFailure("attach file not support config convert to online file")
                return nil
            }
        }
        
        if shouldShowImportAsOnlineFile() {
            let state: DKMoreItemState
            var response: PermissionResponse?
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                (state, response) = validate(operation: .importToOnlineDocument)
            } else {
                state = self.check(entityOperate: .ccmCreateCopy, fileBizDomain: previewFrom.transfromBizDomain, docType: .file, token: fileInfo.fileToken)
            }
            let importItem = DKMoreItem(type: .importAsOnlineFile(fileType: fileInfo.fileType), itemState: state, handler: { [weak self](_, _) in
                guard let self = self else { return }
                if let response {
                    self.hostModule?.previewActionSubject.onNext(.customAction(action: { controller in
                        response.didTriggerOperation(controller: controller)
                    }))
                }
                switch state {
                case .normal:
                    self.handleImportAsOnlinFile()
                case .forbidden:
                    DocsLogger.error("drive.sdk.context.main --- import as online file forbidden",
                                     traceId: response?.traceID)
                case .deny:
                    DocsLogger.error("drive.sdk.context.main --- admin deny")
                    self.hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast, type: .failure))
                case .fileDeny:
                    DocsLogger.error("drive.sdk.context.main --- Strategies decision deny")
                    self.hostModule?.previewActionSubject.onNext(.dialog(entityOperate: .ccmCreateCopy, fileBizDomain: previewFrom.transfromBizDomain, docType: .file, token: self.fileInfo.fileToken))
                }
                self.hostModule?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.importAs, params: [:])
            })
            moreItems.append(importItem)
        }

        let cancelItem = DKMoreItem(type: .cancel) { [weak self] (_, _) in
            self?.hostModule?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileMenuClick, clickEventType: DriveStatistic.DriveFileMenuClickEvent.cancel, params: [:])
        }
        moreItems.append(cancelItem)
        DocsLogger.driveInfo("drive.sdk.context.main --- setting up more items", extraInfo: ["moreItemCount": moreItems.count])
        let moreViewModel = DKMoreViewModel(dependency: moreDependencyImpl, moreType: .attach(items: moreItems))
        moreViewModel.itemDidClickAction = { [weak self] in
            // 上报点击"更多"事件，以及更多页面展示的事件
            guard let self = self else { return }
            let mode = self.hostModule?.currentDisplayMode ?? .normal
            let additionParams = ["display": mode.statisticValue]
            self.hostModule?.statisticsService.reportClickEvent(DocsTracker.EventType.driveFileOpenClick, clickEventType: DriveStatistic.DriveFileOpenClickEventType.more, params: additionParams)
            self.hostModule?.statisticsService.reportEvent(DocsTracker.EventType.driveFileMenuView, params: params)
        }
        return moreViewModel
    }

    // MARK: 更多菜单事件处理
    func handleOpenWithOtherApp(sourceView: UIView?, sourceRect: CGRect?, callback: ((String, Bool) -> Void)?) {
        DocsLogger.driveInfo("drive.sdk.context.main --- did click open with other app")
        guard let host = hostModule else {
            spaceAssertionFailure("host module not found")
            return
        }
        let action = DKPreviewAction.downloadAndOpenWithOtherApp(meta: fileInfo.getFileMeta(),
                                                                 previewFrom: host.commonContext.previewFrom,
                                                                 sourceView: sourceView,
                                                                 sourceRect: sourceRect,
                                                                 callback: callback)
        hostModule?.previewActionSubject.onNext(action)
    }

    private func handleSaveToSpace(handler: @escaping (DKSaveToSpaceState) -> Void) {
        DocsLogger.driveInfo("drive.sdk.context.main --- did click save to space")
        // 通知按钮被点击，业务方可以进行数据上报等操作
        // 附件类型保存到云盘按钮只有一种状态，未保存状态，用户可以多次保存
        handler(.unsave)
        hostModule?.netManager.saveToSpace(fileInfo: fileInfo) {[weak self] (result) in
            switch result {
            case .success:
                let action = DKPreviewAction.toast(content: BundleI18n.SKResource.Drive_Sdk_SaveSuccessfully, type: .success)
                self?.hostModule?.previewActionSubject.onNext(action)
            case let .failure(error):
                self?.handleError(error)
            }
        }
    }

    private func handleError(_ error: Error) {
        guard case let DriveError.serverError(code) = error else {
            hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Drive_Drive_SaveFailed, type: .failure))
            return
        }
        if QuotaAlertPresentor.shared.enableTenantQuota && code == DocsNetworkError.Code.createLimited.rawValue {
            hostModule?.previewActionSubject.onNext(.storageQuotaAlert)
        } else if QuotaAlertPresentor.shared.enableUserQuota && code == DocsNetworkError.Code.driveUserStorageLimited.rawValue {
            hostModule?.previewActionSubject.onNext(.userStorageQuotaAlert(token: fileInfo.fileToken))
        } else if SettingConfig.sizeLimitEnable && code == DocsNetworkError.Code.spaceFileSizeLimited.rawValue {
            hostModule?.previewActionSubject.onNext(.saveToSpaceQuotaAlert(fileSize: Int64(fileInfo.size)))
        } else {
            if DlpErrorCode.isDlpError(with: code) {
                PermissionStatistics.shared.reportDlpSecurityInterceptToastView(action: .OPEN, dlpErrorCode: code)
                hostModule?.previewActionSubject.onNext(.toast(content: DlpErrorCode.errorMsg(with: code), type: .failure))
            } else if let docsError = DocsNetworkError(code),
                let message = docsError.code.errorMessage {
                hostModule?.previewActionSubject.onNext(.toast(content: message, type: .failure))
            } else {
                hostModule?.previewActionSubject.onNext(.toast(content: BundleI18n.SKResource.Drive_Drive_SaveFailed, type: .failure))
            }
        }
    }

    private func handleForward(handler: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        DocsLogger.driveInfo("drive.sdk.context.main --- did click forward")
        let info = fileInfo.attachmentInfo()
        hostModule?.previewActionSubject.onNext(.forward(handler: handler, info: info))
    }
    
    private func handleSaveToFile(handler: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        guard let host = hostModule else {
            spaceAssertionFailure("host module not found")
            return
        }
        let info = fileInfo.attachmentInfo()
        hostModule?.previewActionSubject.onNext(.saveToFile(handler: handler, info: fileInfo, previewFrom: host.commonContext.previewFrom))
    }
    
    private func handleSaveToLocal(handler: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        hostModule?.previewActionSubject.onNext(.saveToLocal(handler: handler, info: fileInfo))
    }
    
    private func handleSaveToAlbum(handler: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        guard let host = hostModule else {
            spaceAssertionFailure("host module not found")
            return
        }
        let info = fileInfo.attachmentInfo()
        hostModule?.previewActionSubject.onNext(.saveToAlbum(handler: handler, info: fileInfo, previewFrom: host.commonContext.previewFrom))
    }
    
    private func handleImportAsOnlinFile() {
        guard let host = hostModule else {
            spaceAssertionFailure("host module not found")
            return
        }
        hostModule?.previewActionSubject.onNext(.importAs(convertType: .attachment(info: fileInfo),
                                                          actionSource: .attachmentMore,
                                                          previewFrom: host.commonContext.previewFrom))
    }
    
    private func handlerCustomUserDefine(handler: @escaping (UIViewController, DKAttachmentInfo) -> Void) {
        let info = fileInfo.attachmentInfo()
        hostModule?.previewActionSubject.onNext(.customUserDefine(handler: handler, info: info))
    }
    
    // 判断是否展示转在线文档入口
    private func shouldShowImportAsOnlineFile() -> Bool {
        guard let host = hostModule else {
            spaceAssertionFailure("host module not found")
            return false
        }
        guard host.commonContext.canImportAsOnlineFile else { return false }
        let typeSupport = fileInfo.fileType.canImportAsDocs || fileInfo.fileType.canImportAsSheet || fileInfo.fileType.canImportAsMindnote
        // 是否开启fg
        let fgEnabled = DriveConvertFileConfig.isFeatureGatingEnabled()
        guard typeSupport && fgEnabled else { return false }

        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let response = host.permissionService.validate(operation: .importToOnlineDocument)
            switch response.result {
            case .allow:
                return true
            case let .forbidden(denyType, _) where denyType == .blockByUserPermission(reason: .blockByCAC):
                // 因 CAC 禁止导出时，UI 上需要展示入口
                return true
            default:
                return false
            }
        } else {
            return permissionInfo.canExport
        }
    }
    
    // 设置密钥被删除后顶部状态栏状态
    private func setupFileKeyHasBeenDeleteState() {
        naviBarItemsRelay.accept([])
        naviBarViewModel.titleVisableRelay.accept(false)
        fileKeyHasBeenDelete = true
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    private func check(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) -> DKMoreItemState {
        guard let hostModule = hostModule else { return .normal }
        var state: DKMoreItemState = .normal
        let result = hostModule.cacManager.syncValidate(entityOperate: entityOperate, fileBizDomain: fileBizDomain, docType: docType, token: token)
        if result.allow {
            state = .normal
        } else {
            if result.validateSource == .fileStrategy {
                state = .fileDeny
            }
            if result.validateSource == .securityAudit {
                state = .deny
            }
        }
        return state
    }

    private func validate(operation: PermissionRequest.Operation, bizDomain: PermissionRequest.BizDomain? = nil) -> (DKMoreItemState, PermissionResponse?) {
        guard let permissionService = hostModule?.permissionService else {
            spaceAssertionFailure("host module found nil, operation: \(operation)")
            return (.normal, nil)
        }
        let response: PermissionResponse
        if let bizDomain {
            response = permissionService.validate(operation: operation, bizDomain: bizDomain)
        } else {
            response = permissionService.validate(operation: operation)
        }
        return (
            response.result.needDisabled ? .forbidden : .normal,
            response
        )
    }
}
