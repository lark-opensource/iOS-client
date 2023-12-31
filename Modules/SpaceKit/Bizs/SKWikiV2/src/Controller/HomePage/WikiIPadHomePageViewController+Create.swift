//
//  WikiIPadHomePageViewController+Create.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2023/9/25.
//

import Foundation
import SKWorkspace
import SKCommon
import SKFoundation
import SpaceInterface
import SKResource
import SKInfra
import UniverseDesignToast
import UniverseDesignIcon
import LarkUIKit
import RxCocoa
import RxSwift

extension WikiIPadHomePageViewController {

    func confirmCreate(sourceView: UIView, createType: WorkspaceCreatePanelType) {
        guard viewModel.isReachable else {
            // 无网不处理
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet,
                                on: view.window ?? view)
            return
        }
        switch createType {
        case .create:
            showCreateTypePanel(sourceView: sourceView)
        case .upload:
            showUploadTypePanel(sourceView: sourceView)
        case .template:
            // wiki 首页不应该出现模板
            spaceAssertMainThread()
        }
    }

    private func showCreateTypePanel(sourceView: UIView) {
        let items = getCreateTypeItems()
        let controller = WorkspaceCreateTypePickerController(items: items, sourceView: sourceView)
        userResolver.navigator.present(controller, from: self)
    }

    private func getCreateTypeItems() -> [SpaceCreatePanelItem] {
        var items: [SpaceCreatePanelItem] = []
        let wikiCreateDocxEnable = LKFeatureGating.createDocXEnable
        if wikiCreateDocxEnable {
            items.append(
                WikiCreateItem.docX(enable: true) { [weak self] in
                    WikiStatistic.clickCreateNewView(fileType: DocsType.docX.name)
                    self?.showPickerForCreate(type: .docX)
                }.createPanelItem
            )
        } else {
            items.append(
                WikiCreateItem.docs(enable: true) { [weak self] in
                    WikiStatistic.clickCreateNewView(fileType: DocsType.doc.name)
                    self?.showPickerForCreate(type: .doc)
                }.createPanelItem
            )
        }

        items.append(
            WikiCreateItem.sheet(enable: true) { [weak self] in
                WikiStatistic.clickCreateNewView(fileType: DocsType.sheet.name)
                self?.showPickerForCreate(type: .sheet)
            }.createPanelItem
        )

        if UserScopeNoChangeFG.PXR.baseWikiSpaceHasSurveyEnable, let template = TemplateModel.createBlankSurvey(templateSource: .wikiHomepageLarkSurvey) {
            ///多维表格
            if LKFeatureGating.bitableEnable {
                items.append(
                    WikiCreateItem.nonSquareBase(enable: true) { [weak self] in
                        WikiStatistic.clickCreateNewView(fileType: DocsType.bitable.name)
                        self?.showPickerForCreate(type: .bitable)
                    }.createPanelItem
                )
            }
            ///问卷入口
            let wikiSurveyItem = WikiCreateItem.bitableSurvey(enable: true) { [weak self] in
                let track = CreateNewClickParameter.wikiHomePageNewSurvey
                WikiStatistic.clickCreateNewViewByTemplate(click: track.clickValue, target: track.targetValue)
                self?.showPickerForCreate(type: .bitable, templateModel: template)
            }
            items.append(wikiSurveyItem.createPanelItem)
            ///思维笔记
            if LKFeatureGating.mindnoteEnable {
                items.append(
                    WikiCreateItem.mindnote(enable: true) { [weak self] in
                        WikiStatistic.clickCreateNewView(fileType: DocsType.mindnote.name)
                        self?.showPickerForCreate(type: .mindnote)
                    }.createPanelItem
                )
            }
        } else {
            ///思维笔记
            if LKFeatureGating.mindnoteEnable {
                items.append(
                    WikiCreateItem.mindnote(enable: true) { [weak self] in
                        WikiStatistic.clickCreateNewView(fileType: DocsType.mindnote.name)
                        self?.showPickerForCreate(type: .mindnote)
                    }.createPanelItem
                )
            }
            ///多维表格
            if LKFeatureGating.bitableEnable {
                items.append(
                    WikiCreateItem.nonSquareBase(enable: true) { [weak self] in
                        WikiStatistic.clickCreateNewView(fileType: DocsType.bitable.name)
                        self?.showPickerForCreate(type: .bitable)
                    }.createPanelItem
                )
            }
        }

        if !UserScopeNoChangeFG.LJY.disableCreateDoc, wikiCreateDocxEnable {
            items.append(
                WikiCreateItem.docs(enable: true) { [weak self] in
                    WikiStatistic.clickCreateNewView(fileType: DocsType.doc.name)
                    self?.showPickerForCreate(type: .doc)
                }.createPanelItem
            )
        }
        return items
    }

    private func getUploadTypeItems() -> [SpaceCreatePanelItem] {
        let uploadFile = WikiCreateItem.uploadFile(enable: true) { [weak self] in
            WikiStatistic.clickCreateNewView(fileType: "upload_file")
            self?.uploadHelper.selectFileWithPicker(allowInSpace: true)
            let biz = CreateNewClickParameter.bizParameter(for: "", module: .wikiHome)
            DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: "file"), bizParms: biz, mountPoint: "wiki")
            DocsTracker.isSpaceOrWikiUpload = true
        }.createPanelItem
        let uploadImage = WikiCreateItem.uploadImage(enable: true) { [weak self] in
            WikiStatistic.clickCreateNewView(fileType: "upload_picture")
            self?.uploadHelper.selectImagesWithPicker(allowInSpace: true)
            let biz = CreateNewClickParameter.bizParameter(for: "", module: .wikiHome)
            DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: "picture"), bizParms: biz, mountPoint: "wiki")
            DocsTracker.isSpaceOrWikiUpload = true
        }.createPanelItem
        return [uploadFile, uploadImage]
    }

    private func showUploadTypePanel(sourceView: UIView) {
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        guard precheckUploadPermission() else { return }
        let uploadItems = getUploadTypeItems()
        let controller = WorkspaceCreateTypePickerController(items: uploadItems, sourceView: sourceView)
        userResolver.navigator.present(controller, from: self)
    }

    private func precheckUploadPermission() -> Bool {
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let request = PermissionRequest(token: "", type: .file, operation: .upload, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: self)
            return response.allow
        } else {
            let validateResult = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
            if !validateResult.allow {
                switch validateResult.validateSource {
                case .fileStrategy:
                    CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
                case .securityAudit:
                    UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                        on: self.view.window ?? self.view)
                case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                    DocsLogger.info("unknown type or dlp type")
                }
            }
            return validateResult.allow
        }
    }

    private func showPickerForCreate(type: DocsType, templateModel: TemplateModel? = nil) {
        let tracker = WorkspacePickerTracker(actionType: .createFile, triggerLocation: .wikiHome)
        let config = WorkspacePickerConfig(title: BundleI18n.SKResource.LarkCCM_Wiki_CreateIn_Header_Mob,
                                           action: .createWiki,
                                           entrances: .wikiAndSpace,
                                           tracker: tracker) { [weak self] location, picker in
            guard let self = self else { return }
            switch location {
            case let .folder(location):
                self.confirmCreateInSpace(type: type, location: location, templateModel: templateModel, picker: picker)
            case let .wikiNode(location):
                self.confirmCreate(type: type, spaceID: location.spaceID, wikiToken: location.wikiToken, template: templateModel, picker: picker)
            }
        }
        let picker = WorkspacePickerFactory.createWorkspacePicker(config: config)
        userResolver.navigator.present(picker, from: self)
    }

    private func confirmCreateInSpace(type: DocsType, location: SpaceFolderPickerLocation, templateModel: TemplateModel? = nil, picker: UIViewController) {
        guard location.canCreateSubNode else {
            UDToast.showFailure(with: BundleI18n.SKResource.LarkCCM_Workspace_FolderPerm_CantNew_Tooltip, on: picker.view.window ?? picker.view)
            return
        }
        UDToast.showLoading(with: BundleI18n.SKResource.Doc_Wiki_CreateDialog,
                            on: picker.view.window ?? picker.view,
                            disableUserInteraction: true)
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: .docCreate, module: .wikiHome, ccmOpenSource: .wiki)
        let director = DocsCreateDirectorV2(type: type,
                                            ownerType: location.folderType.ownerType,
                                            name: nil,
                                            in: location.folderToken,
                                            trackParamters: trackParameters)
        director.makeSelfReferenced()
        director.handleRouter = false
        ///模版创建
        if let template = templateModel {
            var templateSource: TemplateCenterTracker.TemplateSource? = nil
            if let s = template.templateSource {
                templateSource = TemplateCenterTracker.TemplateSource(rawValue: s)
            }
            director.createByTemplate(templateObjToken: template.objToken , templateId: template.id, templateType: template.templateMainType, templateCenterSource: nil, templateSource: templateSource, statisticsExtra: nil) { [weak self] _, controller, _, _, error in
                guard let self = self else { return }

                UDToast.removeToast(on: picker.view.window ?? picker.view)
                if let error = error {
                    UDToast.showFailure(with: error.localizedDescription, on: picker.view.window ?? picker.view)
                    return
                }
                guard let controller = controller else { return }
                self.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.userResolver.navigator.docs.showDetailOrPush(controller, wrap: LkNavigationController.self, from: self)
                }
            }
        } else {
            ///DocsType创建
            director.create { [weak self] _, controller, _, _, error in
                guard let self = self else { return }
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                if let error = error {
                    UDToast.showFailure(with: error.localizedDescription, on: picker.view.window ?? picker.view)
                    return
                }
                guard let controller = controller else { return }
                self.dismiss(animated: true) { [weak self] in
                    guard let self = self else { return }
                    self.userResolver.navigator.docs.showDetailOrPush(controller, wrap: LkNavigationController.self, from: self)
                }
            }
        }
    }

    private func confirmCreate(type: DocsType, spaceID: String, wikiToken: String, template: TemplateModel? = nil, picker: UIViewController) {
        WikiStatistic.createFromHomePage(docsType: type,
                                         targetWikiToken: wikiToken)
        UDToast.showLoading(with: BundleI18n.SKResource.Doc_Wiki_CreateDialog,
                            on: picker.view.window ?? picker.view,
                            disableUserInteraction: true)
        WikiNetworkManager.shared.createNode(spaceID: spaceID,
                                             parentWikiToken: wikiToken,
                                             template: template,
                                             objType: type,
                                             synergyUUID: nil)
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] newNode in
                guard let self = self else { return }
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                picker.dismiss(animated: true) {
                    WikiRouter.gotoWikiDetail(WikiNodeMeta(wikiToken: newNode.meta.wikiToken,
                                                           objToken: newNode.meta.objToken,
                                                           docsType: newNode.meta.objType,
                                                           spaceID: spaceID),
                                              userResolver: self.userResolver,
                                              extraInfo: ["from": "tab_create",
                                                            CCMOpenTypeKey: CCMOpenType.wikiCreateNew.trackValue],
                                              fromVC: self)
                    WikiStatistic.clickFileLocationSelect(targetSpaceId: spaceID,
                                                          fileId: newNode.meta.objToken,
                                                          fileType: newNode.meta.objType.name,
                                                          filePageToken: newNode.meta.wikiToken,
                                                          viewTitle: .createFile,
                                                          originSpaceId: "none",
                                                          originWikiToken: "none",
                                                          isShortcut: false,
                                                          triggerLocation: .wikiHome,
                                                          targetModule: .wiki,
                                                          targetFolderType: nil)
                }
            } onError: { error in
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                DocsLogger.error("\(error)")
                UDToast.removeToast(on: picker.view.window ?? picker.view)
                UDToast.showFailure(with: error.addErrorDescription, on: picker.view.window ?? picker.view)
            }
            .disposed(by: bag)
    }
}

extension WikiIPadHomePageViewController {
    func jumpToCreateWikiPicker(sourceView: UIView) {
        let isReachable = viewModel.isReachable
        var items = [WikiCreateItem]()
        let wikiCreateDocxEnable = LKFeatureGating.createDocXEnable
        if wikiCreateDocxEnable {
            items.append(
                .docX(enable: isReachable) { [weak self] in
                    guard isReachable else { return }
                    WikiStatistic.clickCreateNewView(fileType: DocsType.docX.name)
                    self?.showPickerForCreate(type: .docX)
                }
            )
        } else {
            items.append(
                .docs(enable: isReachable) { [weak self] in
                    guard isReachable else { return }
                    WikiStatistic.clickCreateNewView(fileType: DocsType.doc.name)
                    self?.showPickerForCreate(type: .doc)
                }
            )
        }

        items.append(
            .sheet(enable: isReachable) { [weak self] in
                guard isReachable else { return }
                WikiStatistic.clickCreateNewView(fileType: DocsType.sheet.name)
                self?.showPickerForCreate(type: .sheet)
            }
        )
        // Base相关
        items.append(contentsOf: generateBaseItems())

        if !UserScopeNoChangeFG.LJY.disableCreateDoc, wikiCreateDocxEnable {
            items.append(
                .docs(enable: isReachable) { [weak self] in
                    guard isReachable else { return }
                    WikiStatistic.clickCreateNewView(fileType: DocsType.doc.name)
                    self?.showPickerForCreate(type: .doc)
                }
            )
        }
        // 上传相关
        items.append(contentsOf: generateUploadItems())

        let createVC = WikiCreateViewController(items: items)
        createVC.setupPopover(sourceView: sourceView, direction: [.up, .down])
        createVC.dismissalStrategy = [.larkSizeClassChanged]
        userResolver.navigator.present(createVC, from: self)
    }
    
    private func generateBaseItems() -> [WikiCreateItem] {
        let isReachable = viewModel.isReachable
        var items = [WikiCreateItem]()
        if UserScopeNoChangeFG.PXR.baseWikiSpaceHasSurveyEnable, let template = TemplateModel.createBlankSurvey(templateSource: .wikiHomepageLarkSurvey) {
            ///多维表格
            if LKFeatureGating.bitableEnable {
                items.append(
                    .nonSquareBase(enable: isReachable) { [weak self] in
                        guard isReachable else { return }
                        WikiStatistic.clickCreateNewView(fileType: DocsType.bitable.name)
                        self?.showPickerForCreate(type: .bitable)
                    }
                )
            }
            ///问卷入口
            let wikiSurveyItem = WikiCreateItem.bitableSurvey(enable: isReachable){ [weak self] in
                guard isReachable else { return }
                let track:CreateNewClickParameter = .wikiHomePageNewSurvey
                WikiStatistic.clickCreateNewViewByTemplate(click: track.clickValue, target: track.targetValue)
                self?.showPickerForCreate(type: .bitable, templateModel: template)
            }
            items.append(wikiSurveyItem)
            ///思维笔记
            if LKFeatureGating.mindnoteEnable {
                items.append(
                    .mindnote(enable: isReachable) { [weak self] in
                        guard isReachable else { return }
                        WikiStatistic.clickCreateNewView(fileType: DocsType.mindnote.name)
                        self?.showPickerForCreate(type: .mindnote)
                    }
                )
            }
        } else {
            ///思维笔记
            if LKFeatureGating.mindnoteEnable {
                items.append(
                    .mindnote(enable: isReachable) { [weak self] in
                        guard isReachable else { return }
                        WikiStatistic.clickCreateNewView(fileType: DocsType.mindnote.name)
                        self?.showPickerForCreate(type: .mindnote)
                    }
                )
            }
            ///多维表格
            if LKFeatureGating.bitableEnable {
                items.append(
                    .nonSquareBase(enable: isReachable) { [weak self] in
                        guard isReachable else { return }
                        WikiStatistic.clickCreateNewView(fileType: DocsType.bitable.name)
                        self?.showPickerForCreate(type: .bitable)
                    }
                )
            }
        }
        
        return items
    }
    
    private func generateUploadItems() -> [WikiCreateItem] {
        let isReachable = viewModel.isReachable
        var items = [WikiCreateItem]()
        let showOffLineIntercept = { [weak self] in
            guard let self = self else { return }
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet,
                                    on: self.view.window ?? self.view)
        }
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let showAdminIntercept: () -> Void
        let adminEnable: Bool
        if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
            let request = PermissionRequest(token: "", type: .file, operation: .upload, bizDomain: .ccm, tenantID: nil)
            let response = permissionSDK.validate(request: request)
            adminEnable = response.allow
            showAdminIntercept = { [weak self] in
                guard let self else { return }
                response.didTriggerOperation(controller: self)
            }
        } else {
            let validateResult = CCMSecurityPolicyService.syncValidate(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
            showAdminIntercept = { [weak self] in
                guard let self = self else { return }
                switch validateResult.validateSource {
                case .fileStrategy:
                    CCMSecurityPolicyService.showInterceptDialog(entityOperate: .ccmFileUpload, fileBizDomain: .ccm, docType: .file, token: nil)
                case .securityAudit:
                    UDToast.showFailure(with: BundleI18n.SKResource.CreationMobile_ECM_AdminDisableToast,
                                        on: self.view.window ?? self.view)
                case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                    DocsLogger.info("unknown type or dlp type")
                }
            }
            adminEnable = validateResult.allow
        }
        items.append(
            .uploadImage(enable: adminEnable && isReachable) { [weak self] in
                guard let self = self else { return }
                guard isReachable else {
                    showOffLineIntercept()
                    return
                }
                guard adminEnable else {
                    showAdminIntercept()
                    return
                }
                WikiStatistic.clickCreateNewView(fileType: "upload_picture")
                self.uploadHelper.selectImagesWithPicker(allowInSpace: true)
                let biz = CreateNewClickParameter.bizParameter(for: "", module: .wikiHome)
                DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: "picture"), bizParms: biz, mountPoint: "wiki")
                DocsTracker.isSpaceOrWikiUpload = true
            }
        )

        items.append(
            .uploadFile(enable: adminEnable && isReachable) { [weak self] in
                guard let self = self else { return }
                guard isReachable else {
                    showOffLineIntercept()
                    return
                }
                guard adminEnable else {
                    showAdminIntercept()
                    return
                }
                WikiStatistic.clickCreateNewView(fileType: "upload_file")
                self.uploadHelper.selectFileWithPicker(allowInSpace: true)
                let biz = CreateNewClickParameter.bizParameter(for: "", module: .wikiHome)
                DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: "file"), bizParms: biz, mountPoint: "wiki")
                DocsTracker.isSpaceOrWikiUpload = true
            }
        )
        return items
    }
}
