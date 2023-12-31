//
//  SpaceCreatePanelHelper.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/1/15.
//
// swiftlint:disable file_length

import Foundation
import SKFoundation
import SKResource
import RxSwift
import SKUIKit
import UniverseDesignColor
import LarkUIKit
import UniverseDesignToast
import LarkReleaseConfig
import UniverseDesignDialog
import EENavigator
import SpaceInterface
import SKInfra
import UniverseDesignActionPanel
import UniverseDesignIcon
import LarkSetting
import LarkDocsIcon


public struct SpaceCreateConfig {
    /// 只允许创建文件夹，优先级最高
    public let forceCreateFolder: Bool
    /// 不允许创建文件夹
    public let allowCreateFolder: Bool

    public static var `default`: SpaceCreateConfig {
        SpaceCreateConfig(forceCreateFolder: false,
                          allowCreateFolder: true)
    }

    public static var unorganizedFile: SpaceCreateConfig {
        SpaceCreateConfig(forceCreateFolder: false,
                          allowCreateFolder: false)
    }

    public static var personalFolder: SpaceCreateConfig {
        SpaceCreateConfig(forceCreateFolder: true,
                          allowCreateFolder: false)
    }
    
    public static var folderBlock: SpaceCreateConfig {
        SpaceCreateConfig(forceCreateFolder: false,
                          allowCreateFolder: false)
    }
}

// Space 创建上下文，通常和某个具体的列表属性相关，且不会发生改变
public struct SpaceCreateContext {

    public let module: PageModule
    public let mountLocation: WorkspaceCreateLocation
    public var mountLocationToken: String {
        switch mountLocation {
        case .wiki, .default:
            spaceAssertionFailure("wiki or default has not valid mount location token")
            return ""
        case let .folder(token, _):
            return token ?? ""
        }
    }
    public let createConfig: SpaceCreateConfig
    public let folderType: FolderType?

    public static var recent: Self {
        SpaceCreateContext(module: .home(.recent), mountLocation: .default, folderType: nil)
    }

    public static var favorites: Self {
        SpaceCreateContext(module: .favorites, mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var quickAccess: Self {
        SpaceCreateContext(module: .home(.quickaccess), mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var manualOfflines: Self {
        SpaceCreateContext(module: .offline, mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var subordinateRecent: Self {
        SpaceCreateContext(module: .subordinateRecent, mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var personal: Self {
        SpaceCreateContext(module: .personal(.belongtome), mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var shared: Self {
        SpaceCreateContext(module: .shared(.sharetome), mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var unorganizedFile: Self {
        SpaceCreateContext(module: .personal(.belongtome), mountLocationToken: "", folderType: nil, ownerType: nil, createConfig: .unorganizedFile)
    }

    /// 云空间首页改版后新的个人文件夹列表
    public static var personalFolder: Self {
        SpaceCreateContext(module: .personal(.belongtome), mountLocationToken: "", folderType: nil, ownerType: nil, createConfig: .personalFolder)
    }

    public static var personalFolderRoot: Self {
        SpaceCreateContext(module: .personalFolderRoot, mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var sharedFolderRoot: Self {
        SpaceCreateContext(module: .sharedFolderRoot, mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var newShareFolderRoot: Self {
        SpaceCreateContext(module: .shareFolderV2Root, mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public static var spaceNewHome: Self {
        SpaceCreateContext(module: .home(.recent), mountLocation: .myLibrary, folderType: nil)
    }
    
    public static func bitableHome(_ module: PageModule) -> Self {
        SpaceCreateContext(module: module, mountLocationToken: "", folderType: nil, ownerType: nil)
    }

    public var inShareRoot: Bool {
        switch module {
        case .shared, .sharedFolderRoot:
            return true
        default:
            return false
        }
    }

    public init(module: PageModule,
                mountLocation: WorkspaceCreateLocation,
                folderType: FolderType?,
                createConfig: SpaceCreateConfig = .default) {
        self.module = module
        self.folderType = folderType
        self.mountLocation = mountLocation
        self.createConfig = createConfig
    }

    public init(module: PageModule,
                mountLocationToken: String,
                folderType: FolderType?,
                ownerType: Int?,
                createConfig: SpaceCreateConfig = .default) {
        self.module = module
        self.folderType = folderType
        self.createConfig = createConfig
        if let ownerType = ownerType {
            mountLocation = .folder(token: mountLocationToken, ownerType: ownerType)
        } else {
            let ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
            mountLocation = .folder(token: mountLocationToken, ownerType: ownerType)
        }
    }
}

// Space 创建意图，表明从某个列表的某个创建入口发起了创建逻辑
public struct SpaceCreateIntent {
    public let context: SpaceCreateContext
    public let source: FromSource
    public let createButtonLocation: CreateButtonLocation
    public init(context: SpaceCreateContext, source: FromSource, createButtonLocation: CreateButtonLocation) {
        self.context = context
        self.source = source
        self.createButtonLocation = createButtonLocation
    }
}

public enum CreateButtonLocation: String {
    case blankPage = "blank_page" //空白页面新建按钮
    case bottomRight = "bottom_right" //右下角悬浮新建按钮
}

public struct SpaceCreatePanelHelper {
    public typealias Item = SpaceCreatePanelItem
    public typealias CreateHandler = Item.CreateHandler
    public typealias CreateEvent = Item.CreateEvent

    private let createButtonLocation: CreateButtonLocation
    private let trackParameters: DocsCreateDirectorV2.TrackParameters
    private let mountLocation: WorkspaceCreateLocation
    private var folderToken: String? {
        if case let .folder(token, _) = mountLocation {
            return token
        } else {
            return nil
        }
    }
    private weak var createDelegate: DocsCreateViewControllerDelegate?
    private(set) weak var createRouter: DocsCreateViewControllerRouter?
    var bizParameter: SpaceBizParameter {
        return CreateNewClickParameter.bizParameter(for: folderToken ?? "", module: trackParameters.module)
    }
    private let dataRequester = TemplateDataProvider()

    public init(trackParameters: DocsCreateDirectorV2.TrackParameters,
                mountLocation: WorkspaceCreateLocation,
                createDelegate: DocsCreateViewControllerDelegate?,
                createRouter: DocsCreateViewControllerRouter?,
                createButtonLocation: CreateButtonLocation) {
        self.trackParameters = trackParameters
        self.mountLocation = mountLocation
        self.createDelegate = createDelegate
        self.createRouter = createRouter
        self.createButtonLocation = createButtonLocation
        if case .baseHomePage = trackParameters.module {
        } else {
            reportClick(parm: ["action": "open"])
            DocsTracker.reportSpaceCreateNewView(bizParms: bizParameter)
        }
    }

    public func generateItemsForLark(intent: SpaceCreateIntent, reachable: Observable<Bool>) -> [Item] {
        var items: [Item] = []
        items.append(contentsOf: generateCloudDocItmesForLark(intent: intent,
                                                              preferNonSquareBaseIcon: false,
                                                              reachable: reachable))
        items.append(contentsOf: generateUploadItemForLark(intent: intent, reachable: reachable))
        return items
    }
    
    // 新建云文档（docx/doc/sheet/mindnote/bitable/slides）
    public func generateCloudDocItmesForLark(intent: SpaceCreateIntent, preferNonSquareBaseIcon: Bool, reachable: Observable<Bool>) -> [Item] {
        var items: [Item] = []
        // 注意不要随意调整 items 的添加顺序，最终会表现在创建面板的顺序上
        if DocsType.docX.enabledByFeatureGating && LKFeatureGating.createDocXEnable {
            items.append(createDocX(enableState: reachable))
        } else {
            items.append(createDocs())
        }
        items.append(createSheet(enableState: reachable))
        
       
        if UserScopeNoChangeFG.PXR.baseCCMSpaceHasSurveyEnable {
            if DocsType.enableDocTypeDependOnFeatureGating(type: .bitable) {
                items.append(createBitable(preferNonSquareBaseIcon: preferNonSquareBaseIcon, enableState: reachable))
            }
            items.append(createSurveyEntranceForDocs(enableState: reachable))
            if DocsType.mindnoteEnabled {
                items.append(createMindNote(enableState: reachable))
            }
        } else {
            if DocsType.mindnoteEnabled {
                items.append(createMindNote(enableState: reachable))
            }
            if DocsType.enableDocTypeDependOnFeatureGating(type: .bitable) {
                items.append(createBitable(preferNonSquareBaseIcon: preferNonSquareBaseIcon, enableState: reachable))
            }
        }
        if !UserScopeNoChangeFG.LJY.disableCreateDoc, DocsType.docX.enabledByFeatureGating, LKFeatureGating.createDocXEnable {
            items.append(createDocs())
        }

        if DocsConfigManager.isShowFolder && intent.context.createConfig.allowCreateFolder {
            // 共享空间根目录，禁止创建文件夹
            if intent.context.inShareRoot {
                items.append(createFolder(enableState: .just(false)))
            } else {
                items.append(createFolder(enableState: reachable))
            }
        }
        return items
    }
    
    // 上传
    public func generateUploadItemForLark(intent: SpaceCreateIntent, reachable: Observable<Bool>) -> [Item] {
        var items: [Item] = []
        // 共享空间根目录或admin禁用的场景，禁止上传文件
        let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
        let request = PermissionRequest(token: "", type: .file,
                                        operation: .upload,
                                        bizDomain: .ccm,
                                        tenantID: nil)
        let response = permissionSDK.validate(request: request)
        switch response.result {
        case .allow:
            items.append(uploadImage(enableState: reachable))
            items.append(uploadFile(enableState: reachable))
        case let .forbidden(_, preferUIStyle):
            switch preferUIStyle {
            case .hidden:
                break
            case .disabled:
                items.append(uploadImage(enableState: .just(false)))
                items.append(uploadFile(enableState: .just(false)))
            case .default:
                items.append(uploadImage(enableState: reachable))
                items.append(uploadFile(enableState: reachable))
            }
        }
        return items
    }

    public func createCancelHandler(isSubAction: Bool = false) -> () -> Void {
        let cancelHanlder = { [weak createDelegate] in
            createDelegate?.createCancelled()
            if isSubAction {
                reportClick(parm: ["sub_action": "cancel"])
            } else {
                reportClick(parm: ["action": "cancel"])
            }
        }
        return cancelHanlder
    }

    private func reportClick(parm: [AnyHashable: Any]) {
        let inFolder: Bool
        if case let .folder(token, _) = mountLocation, token?.isEmpty == false {
            inFolder = true
        } else {
            inFolder = false
        }
        var module = trackParameters.module.rawValue
        if module == "shared_space" { module = "sharetome" }
        if module == "personal_folder" { module = "personal" }
        var parameters: [AnyHashable: Any] = ["module": module,
                                              "is_folder": String(inFolder),
                                              "icon_type": createButtonLocation.rawValue]
        parameters.merge(other: parm)
        DocsTracker.log(enumEvent: .clickNewIcon, parameters: parameters)
    }
}

// MARK: - Online Docs
extension SpaceCreatePanelHelper {

    public func createDocs() -> Item {
        let clickHandler = createHandler(type: .doc, name: nil)
        return Item.Lark.docs(clickHandler: clickHandler)
    }

    public func createDocX(enableState: Observable<Bool>) -> Item {
        let clickHandler = createHandler(type: .docX, name: nil)
        return createInDiffrentLocation {
            return Item.Lark.docX(clickHandler: clickHandler)
        } wikiCreateItem: { canOfflineCreate in
            // wiki离线新建docx使用单独的FG控制
            if canOfflineCreate {
                return Item.Lark.docX(enableState: .just(true), clickHandler: clickHandler)
            }
            return Item.Lark.docX(enableState: enableState, clickHandler: clickHandler)
        }
    }

    public func createSheet(enableState: Observable<Bool>) -> Item {
        let clickHandler = createHandler(type: .sheet, name: nil)
        return createInDiffrentLocation {
            return Item.Lark.sheet(clickHandler: clickHandler)
        } wikiCreateItem: { canOfflineCreate in
            // wiki离线新建sheet使用单独的FG控制
            if canOfflineCreate {
                return Item.Lark.sheet(enableState: .just(true), clickHandler: clickHandler)
            }
            return Item.Lark.sheet(enableState: enableState, clickHandler: clickHandler)
        }
    }

    public func createBitable(preferNonSquareBaseIcon: Bool, enableState: Observable<Bool>) -> Item {
        let clickHandler = createHandler(type: .bitable, name: nil)
        if preferNonSquareBaseIcon {
            return Item.Lark.nonSquareBase(enableState: enableState, clickHandler: clickHandler)
        } else {
            return Item.Lark.bitable(enableState: enableState, clickHandler: clickHandler)
        }
    }
    
    public func createSurveyEntranceForDocs(enableState: Observable<Bool>) -> Item {
        return Item.Lark.bitableSurvey(enableState: enableState) { event in
            DocsLogger.info("create lark survey for Docs")
            guard event.itemEnable else { return }
            event.createController.dismiss(animated: true) { [weak createRouter] in
                let vc = self.createLarkSurveyV5Controller(templateSource: .spaceHomepageLarkSurvey, targetPopVC: createRouter?.routerImpl?.parent)
                if SKDisplay.pad {
                    vc.modalPresentationStyle = .formSheet
                    vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
                    vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
                    let nav = LkNavigationController(rootViewController: vc)
                    createRouter?.routerPresent(vc: nav, animated: true, completion: nil)
                } else {
                    createRouter?.routerPush(vc: vc, animated: true)
                }
                let biz = bizParameter
                DocsTracker.reportSpaceCreateNewClick(params: .spaceHomePageNewSurvey, bizParms: biz)
            }
        }
    }
    
    public func createMindNote(enableState: Observable<Bool>) -> Item {
        let clickHandler = createHandler(type: .mindnote, name: nil)
        return createInDiffrentLocation {
            // space 离线新建mindnote使用单独的FG控制
            let enableState = RealTimeFG.LJW.mindnoteOfflineCreateEnable ? .just(true) : enableState
            return Item.Lark.mindNote(enableState: enableState, clickHandler: clickHandler)
        } wikiCreateItem: { canOfflineCreate in
            // wiki 离线新建mindnote使用单独的FG控制
            if canOfflineCreate {
                return Item.Lark.mindNote(enableState: .just(true), clickHandler: clickHandler)
            }
            return Item.Lark.mindNote(enableState: enableState, clickHandler: clickHandler)
        }
    }
    
    // space与wiki的离线新建使用不同的FG控制，使用该方法区分不同控制状态的item
    // wikiCreateItem 闭包中的Bool类型值用来区分是否是支持离线新建，仅创建至文档库下根节点支持
    private func createInDiffrentLocation(spaceCreateItem: () -> Item, wikiCreateItem: (Bool) -> Item) -> Item {
        switch mountLocation {
        case let .wiki(location):
            // 创建至wiki的location为nil表示创建至文档库根节点
            return wikiCreateItem(location == nil)
        case .folder:
            return spaceCreateItem()
        case .`default`:
            let location = try? WorkspaceCreateDirector.getDefaultCreateLocation()
            guard let location else {
                return spaceCreateItem()
            }
            switch location {
            case let .wiki(location):
                // 创建至wiki的location为nil表示创建至文档库根节点
                return wikiCreateItem(location == nil)
            case .folder, .`default`:
                return spaceCreateItem()
            }
        }
    }

    private func createHandler(type: DocsType, name: String?) -> CreateHandler {
        let templateTrackParamter = trackParameters
        return { event in
            guard event.itemEnable else { return }
            event.createController.dismiss(animated: true) { [weak createRouter] in
                let vc = TemplateCenterViewController(
                    initialType: .gallery,
                    objType: type.rawValue,
                    mountLocation: mountLocation,
                    targetPopVC: createRouter?.routerImpl?.parent,
                    createBlankDocs: true,
                    source: .createBlankDocs
                )
                vc.trackParamter = templateTrackParamter
                if SKDisplay.pad {
                    vc.modalPresentationStyle = .formSheet
                    vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
                    vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
                    let nav = LkNavigationController(rootViewController: vc)
                    createRouter?.routerPresent(vc: nav, animated: true, completion: nil)
                } else {
                    createRouter?.routerPush(vc: vc, animated: true)
                }
                let biz = bizParameter
                DocsTracker.reportSpaceCreateNewClick(params: .docs(type: type, toTemplateCenter: true),
                                                      bizParms: biz)
            }
        }
    }

    // 目前只有创建文件夹会走到此场景
    private func createByDirectorHandler() -> (DocsType, Int, String?) -> Void {
        return { [weak createDelegate, weak createRouter] (type, ownerType, name) in
            let director = DocsCreateDirectorV2(type: type, ownerType: ownerType, name: name, in: folderToken ?? "", trackParamters: trackParameters)
            director.router = createRouter
            director.createVCDelegate = createDelegate
            director.handleRouter = true
            director.makeSelfReferenced()
            director.create { (token, _, type, _, _) in
                if let token = token {
                    let biz = bizParameter
                    biz.update(fileID: token, fileType: type)
                    DocsTracker.reportSpaceCreateNewClick(params: CreateNewClickParameter.param(for: type),
                                                          bizParms: biz)
                    if type == .folder {
                        createRouter?.createFolderComplete(folderToken: token)
                    }
                }
            }
            reportClick(parm: ["action": type.name])
        }
    }

    ///bitable Home 页面通过模板中心打开
    public func openTemplateCenter(createBlankDocs: Bool = false) -> UIViewController {
        var source: TemplateCenterTracker.EnterTemplateSource = .bitableHomeCreateWorkbench
        if case let .baseHomePage(context: context) = bizParameter.module, context.containerEnv == .larkTab {
            source = .bitableHomeCreateLarktab
        }
        let templateTrackParamter = trackParameters
        var targetPopVC: UIViewController?
        if UserScopeNoChangeFG.LYL.enableHomePageV4 {
            targetPopVC = createRouter?.routerImpl
        } else {
            targetPopVC = createRouter?.routerImpl?.parent
        }
        let vc = TemplateCenterViewController(
            initialType: .gallery,
            objType: DocsType.bitable.rawValue,
            mountLocation: mountLocation,
            targetPopVC: targetPopVC,
            createBlankDocs: createBlankDocs,
            source: source,
            enterSource: source.rawValue
        )
        vc.trackParamter = templateTrackParamter
        if SKDisplay.pad {
            vc.modalPresentationStyle = .formSheet
            vc.preferredContentSize = TemplateCenterViewController.preferredContentSize
            vc.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
            let nav = LkNavigationController(rootViewController: vc)
            createRouter?.routerPresent(vc: nav, animated: true, completion: nil)
        } else {
            createRouter?.routerPush(vc: vc, animated: true)
        }
        
        DocsTracker.reportSpaceCreateNewClick(enumEvent: .baseHomepageLandingClick,
                                              params: .baseTemplates,
                                              bizParms: bizParameter,
                                              userNewLog: true)

        return vc
    }
    
    public func createBitableAddButtonHandler(sourceView: UIView) -> UIViewController {
        DocsLogger.info("create bitable click add button")
        if case let .baseHomePage(context) = bizParameter.module, context.containerEnv == .workbench, !UserScopeNoChangeFG.YY.bitableWorkbenchNewEnable {
            return self.openTemplateCenter(createBlankDocs: true)
        }
        
        var firstItems: [SKOperationBaseItem] = []
        
        func generateOperationItem() -> SKOperationBaseItem {
            var item = SKOperationBaseItem()
            item.imageNoTint = true
            item.imageSize = CGSize(width: 24, height: 24)
            item.titleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
            item.customViewHeight = 64
            item.background = (normal: UDColor.bgFloat, highlighted: UDColor.fillHover)
            return item
        }
        
        func surveyItemShouldShowRedBadge() -> Bool {
            let shouldShow = !OnboardingManager.shared.hasFinished(.baseHomepageEntranceSurveyNew)
            return shouldShow
        }
        
        func surveyItemRedBadgeDidShow() {
            OnboardingManager.shared.markFinished(for: [.baseHomepageEntranceSurveyNew])
        }
        
        var item0 = generateOperationItem()
        if UserScopeNoChangeFG.QYK.btSquareIcon {
            item0.image = LarkDocsIconForBase.Base.base_default_icon
        } else {
            item0.image = UDIcon.fileBitableColorful
        }
        
        item0.title = BundleI18n.SKResource.Bitable_Workspace_NewBase_Button
        item0.clickHandler = {
            guard let fromVC = createRouter?.routerImpl else {
                return
            }
            DocsLogger.info("create bitable click blank docs button")
            self.createBlankDocs(.bitable, fromVC: fromVC, targetPopVC: nil, mountLocation: mountLocation, ccmOpenSource: bizParameter.module.generateCCMOpenCreateSource(), templateSource: nil)
        }
        firstItems.append(item0)
        
        if case let .baseHomePage(context) = bizParameter.module, context.containerEnv == .larkTab, UserScopeNoChangeFG.PXR.baseHomepageHasSurveyEnable {
            var surveyItem = generateOperationItem()
            surveyItem.image = UDIcon.fileFormColorful
            surveyItem.title = BundleI18n.SKResource.Bitable_Homepage_NewForm_Button
            surveyItem.shouldShowRedBadge = surveyItemShouldShowRedBadge()
            surveyItem.clickHandler = {
                DocsLogger.info("create lark survey from base home page")
                self.openLarkSurveyForm(bizParameter:bizParameter)
                surveyItemRedBadgeDidShow()
            }
            firstItems.append(surveyItem)
        }
        
        if let newFormTemplate = getNewFormTemplate() {
            var item1 = generateOperationItem()
            item1.image = UDIcon.fileFormColorful
            item1.title = BundleI18n.SKResource.Bitable_Workspace_NewForm_Button
            item1.clickHandler = {
                DocsLogger.info("create bitable click new form button")
                self.createBitableForm(newFormTemplate: newFormTemplate)
            }
            firstItems.append(item1)
        } else {
            DocsLogger.error("invalid newFormTemplate")
        }
        
        var item2 = generateOperationItem()
        item2.image = UDIcon.templateColorful
        item2.title = BundleI18n.SKResource.Bitable_Workspace_TemplateCenter_Button
        item2.clickHandler = {
            DocsLogger.info("create bitable click template center button")
            _ = self.openTemplateCenter()
        }
        firstItems.append(item2)
        
        var cancelItem = SKOperationBaseItem()
        cancelItem.title = BundleI18n.SKResource.Bitable_Common_ButtonCancel
        cancelItem.background = (normal: UDColor.bgFloat, highlighted: UDColor.fillHover)
        cancelItem.titleAlignment = .center
        
        let operationVC = SKOperationController(config: SKOperationControllerConfig(
            items: [
                firstItems,
                [cancelItem]
            ],
            background: UDColor.bgFloatBase)
        )

        if createRouter?.routerImpl?.isMyWindowRegularSizeInPad == true {
            operationVC.modalPresentationStyle = .popover
            operationVC.popoverPresentationController?.sourceView = sourceView
            operationVC.popoverPresentationController?.sourceRect = sourceView.bounds
            operationVC.popoverPresentationController?.permittedArrowDirections = [.down]
            operationVC.popoverPresentationController?.delegate = operationVC
            operationVC.preferredContentSize = CGSize(width: 375, height: 466)
            createRouter?.routerPresent(vc: operationVC, animated: true, completion: nil)
        } else {
            operationVC.updateLayoutWhenSizeClassChanged = false
            let nav = SKNavigationController(rootViewController: operationVC)
            nav.modalPresentationStyle = .overFullScreen
            nav.update(style: .clear)
            nav.transitioningDelegate = operationVC.panelTransitioningDelegate
            createRouter?.routerPresent(vc: nav, animated: true, completion: nil)
        }
        
        return operationVC
    }
    
    public func createBlankDocs(_ docsType: DocsType, fromVC: UIViewController, targetPopVC: UIViewController?, mountLocation: WorkspaceCreateLocation, ccmOpenSource: CCMOpenCreateSource, templateSource: TemplateCenterTracker.TemplateSource?) {
        
        let enable = DocsNetStateMonitor.shared.isReachable || docsType.isSupportOfflineCreate
        guard enable else {
            DocsLogger.error("Doc_List_OperateFailedNoNet")
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_OperateFailedNoNet, on: fromVC.view.window ?? fromVC.view)
            return
        }
        UDToast.showLoading(with: BundleI18n.SKResource.Doc_List_TemplateCreateLoading,
                            on: fromVC.view,
                            disableUserInteraction: true)
        var trackParams = DocsCreateDirectorV2.TrackParameters.default()
        trackParams.ccmOpenSource = ccmOpenSource
        let director = WorkspaceCreateDirector(location: mountLocation,
                                               trackParameters: trackParams)
        director.create(docsType: docsType) { [weak fromVC] token, vc, docsType, _, error in
            guard let fromVC = fromVC else {
                return
            }
            UDToast.removeToast(on: fromVC.view)
            if let error = error {
                DocsLogger.error("create docs error", error: error)
                UDToast.showFailure(with: error.localizedDescription, on: fromVC.view.window ?? fromVC.view)
            }
            if let targetVC = vc {
                createRouter?.routerPush(vc: targetVC, animated: true)
            }
            if let token = token {
                TemplateCenterTracker.reportSuccessCreateBlankDocs(
                    docsToken: token,
                    docsType: docsType,
                    templateSource: templateSource
                )
                if docsType == .bitable, ccmOpenSource.isBaseHome {
                    DocsTracker.reportSpaceCreateNewClick(enumEvent: .baseHomepageLandingClick,
                                                          params: .baseNew(targetFileToken: token),
                                                          bizParms: bizParameter,
                                                          userNewLog: true)
                }
            }
        }
    }
    
    private func createBitableForm(newFormTemplate: [String: Any]) {
        guard let fromVC = createRouter?.routerImpl else {
            DocsLogger.error("createBitableForm fromVC invalid")
            return
        }
        let createWithTemplateHandler = createByTemplateHandler(trackParameters: DocsCreateDirectorV2.TrackParameters(source: trackParameters.source, module: trackParameters.module, ccmOpenSource: trackParameters.module.generateCCMOpenCreateSource(isBaseForm: true))) { fileToken in
            DocsTracker.reportSpaceCreateNewClick(enumEvent: .baseHomepageLandingClick,
                                                  params: .baseFormNew(targetFileToken: fileToken),
                                                  bizParms: bizParameter,
                                                  userNewLog: true)
        }
        let createTime: Double = newFormTemplate["createTime"] as? Double ?? 0
        let id: String = newFormTemplate["id"] as? String ?? ""
        let name: String = newFormTemplate["name"] as? String ?? ""
        let objToken: String = newFormTemplate["objToken"] as? String ?? "" // require
        let objType: Int = newFormTemplate["objType"] as? Int ?? 8 // require
        let updateTime: Double = newFormTemplate["updateTime"] as? Double ?? 0
        let source: TemplateModel.Source = TemplateModel.Source(rawValue: newFormTemplate["source"] as? Int ?? 1) ?? .system // require
        createWithTemplateHandler(.init(
            createTime: createTime,
            id: id,
            name: name,
            objToken: objToken,
            objType: objType,
            updateTime: updateTime,
            source: source
        ), fromVC)
    }
    
    private func openLarkSurveyForm(bizParameter:SpaceBizParameter) {
        guard let fromVC = createRouter?.routerImpl else {
            DocsLogger.error("createBitableForm fromVC invalid")
            return
        }
        
        let dataProvider = TemplateDataProvider()
        let templateSource = TemplateCenterTracker.TemplateSource.baseHomepageLarkSurvey.rawValue
        dataProvider.templateSource = templateSource
        let vm = TemplateCenterViewModel(depandency: (networkAPI: dataProvider, cacheAPI: dataProvider),
                                                         shouldCacheFilter: false)
        vm.templateSource = templateSource
        let vc = TemplateCenterViewController(
                viewModel: vm,
                initialType: .gallery,
                templateCategory: nil,
                objType: DocsType.bitable.rawValue,
                mountLocation: mountLocation,
                targetPopVC:fromVC,
                source: .promotionalDocs,
                enterSource: nil,
                templateSource: .baseHomepageLarkSurvey
         )
        createRouter?.routerPush(vc: vc, animated: true)
        DocsTracker.reportSpaceCreateNewClick(enumEvent: .baseHomepageLandingClick,
                                              params: .baseHomePageNewSurvey,
                                              bizParms: bizParameter,
                                              userNewLog: true)
    }
    
    public func createLarkSurveyV5Controller(templateSource: TemplateCenterTracker.TemplateSource, targetPopVC: UIViewController?) -> TemplateCenterViewController {
        let dataProvider = TemplateDataProvider()
        dataProvider.templateSource = templateSource.rawValue
        let vm = TemplateCenterViewModel(depandency: (networkAPI: dataProvider, cacheAPI: dataProvider),
                                         shouldCacheFilter: false)
        vm.templateSource = templateSource.rawValue
        let vc = TemplateCenterViewController(
            viewModel: vm,
            initialType: .gallery,
            templateCategory: nil,
            objType: DocsType.bitable.rawValue,
            mountLocation: mountLocation,
            targetPopVC:targetPopVC,
            source: .promotionalDocs,
            enterSource: nil,
            templateSource: templateSource
        )
        return vc
    }
    
    
    
    private func getNewFormTemplate() -> [String: Any]? {
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_base_homepage"))
            return settings["newFormTemplate"] as? [String: Any]
        } catch {
            DocsLogger.error("ccm_base_homepage get settings error", error: error)
        }
        return nil
    }
}

// MARK: - Template
extension SpaceCreatePanelHelper {
    // 跳转到模板中心的路由
    private func templateCenterMaker() -> () -> TemplateCenterViewController {
        return { [weak createRouter] in
            let vc = TemplateCenterViewController(
                mountLocation: mountLocation,
                targetPopVC: createRouter?.routerImpl,
                source: .fromNewcreateTemplateicon
            )
            vc.trackParamter = trackParameters
            DocsTracker.log(enumEvent: .templateMoreButton, parameters: nil)
            reportClick(parm: ["action": "template_more"])
            DocsTracker.reportSpaceCreateNewClick(params: .templatesMore,
                                                  bizParms: bizParameter)
            return vc
        }
    }

    // 构造套件中使用模板创建的ViewModel
    public func generateTemplateViewModel() -> SpaceCreatePanelTemplateViewModel {
        let createWithTemplateHandler = createByTemplateHandler()
        let templateCenterProvider = templateCenterMaker()
        let dataProvider = TemplateDataProvider()
        return SpaceCreatePanelTemplateViewModel(templateProvider: dataProvider,
                                                 templateCache: dataProvider,
                                                 createByTemplateHandler: createWithTemplateHandler,
                                                 moreTemplateHandler: { [weak createRouter] createController in
            createController.dismiss(animated: true) {
                let templateVC = templateCenterProvider()
                if SKDisplay.pad {
                    templateVC.modalPresentationStyle = .formSheet
                    templateVC.preferredContentSize = TemplateCenterViewController.preferredContentSize
                    templateVC.popoverPresentationController?.containerView?.backgroundColor = UIColor.ud.N1000.withAlphaComponent(0.3)
                    let nav = LkNavigationController(rootViewController: templateVC)
                    createRouter?.routerPresent(vc: nav, animated: true, completion: nil)
                } else {
                    createRouter?.routerPush(vc: templateVC, animated: true)
                }
            }
        })
    }

    private func createByTemplateHandler(trackParameters: DocsCreateDirectorV2.TrackParameters? = nil, successHandler: ((_ fileToken: String) -> Void)? = nil) -> (TemplateModel, UIViewController) -> Void {
        let createWithTemplateHandler = createWithTemplate(trackParameters: trackParameters, successHandler: successHandler)
        return { [weak createRouter] template, createController in
            guard DocsNetStateMonitor.shared.isReachable else {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_NoInternetClickMoreToast,
                                       on: createController.view.window ?? createController.view)
                DocsLogger.error("no network, create fail")
                return
            }
            UDToast.showLoading(with: BundleI18n.SKResource.Doc_List_TemplateCreateLoading,
                                   on: createController.view.window ?? createController.view,
                                   disableUserInteraction: true)
            createWithTemplateHandler(template) { [weak createRouter] (_, browserVC, _, _, error) in
                UDToast.removeToast(on: createController.view.window ?? createController.view)
                if let error = error {
                    let message: String
                    if let docsError = error as? DocsNetworkError {
                        message = docsError.code.templateErrorMsg()
                    } else {
                        message = BundleI18n.SKResource.Doc_List_TemplateGeneralErrorToast
                    }
                    QuotaAlertPresentor.shared.showQuotaAlertIfNeed(type: .createByTemplate,
                                                                    defaultToast: message,
                                                                    error: error,
                                                                    from: createController,
                                                                    token: template.objToken)
                    return
                }
                guard let browserVC = browserVC else {
                    spaceAssertionFailure("template suggestion create success but no vc created")
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_List_TemplateLoadingFailedToast,
                                           on: createController.view.window ?? createController.view)
                    return
                }
                createController.dismiss(animated: true) {
                    createRouter?.routerPush(vc: browserVC, animated: true)
                }
            }
        }
    }
    // 点击新建面板下推荐的模板会走到此处
    private func createWithTemplate(trackParameters: DocsCreateDirectorV2.TrackParameters? = nil, successHandler: ((_ fileToken: String) -> Void)? = nil) -> (TemplateModel, @escaping CreateCompletion) -> Void {
        return { (template, completion) in
            var extra = TemplateCenterTracker.formateStatisticsInfoForCreateEvent(source: .spaceTemplate, categoryName: nil, categoryId: nil)
            extra?[SKCreateTracker.sourceKey] = FromSource.spaceTemplate.rawValue
            let director = WorkspaceCreateDirector(location: mountLocation,
                                                   trackParameters: trackParameters ?? self.trackParameters)
            let tCompletion: CreateCompletion = { (token, vc, type, url, error) in
                completion(token, vc, type, url, error)
                if let id = token {
                    let biz = bizParameter
                    biz.update(fileID: id, fileType: type)
                    DocsTracker.reportSpaceCreateNewClick(params: .templates(template: template, fileType: type, fileToken: id),
                                                          bizParms: biz)
                    successHandler?(id)
                }
            }
            
            director.create(
                template: template,
                templateCenterSource: nil,
                templateSource: template.shouldUseNewForm() ? template.newFormEnumberType() : nil,
                completion: tCompletion
            )
        }
    }
}

// MARK: - Folder
extension SpaceCreatePanelHelper {

    private func showInputDialogWhenCreateFolder(
        createRouter: DocsCreateViewControllerRouter?,
        completion: @escaping (DocsType, Int, String?) -> Void) {
        let config = UDDialogUIConfig()
        config.contentMargin = .zero
        let dialog = UDDialog(config: config)
        let target = CreateNewFolderClickParameter.eventType(for: trackParameters.module)
        let textField = dialog.addTextField(placeholder: BundleI18n.SKResource.Doc_Facade_InputName)
        dialog.setTitle(text: BundleI18n.SKResource.Doc_Facade_CreateFolder)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCompletion: {
            DocsTracker.reportSpaceCreateNewFolderClick(params: .cancel(false, target: target), bizParms: bizParameter)
        })
        let createButton = dialog.addPrimaryButton(text: BundleI18n.SKResource.Doc_Facade_Create, dismissCompletion: { [weak dialog] in
            let ownerType: Int = {
                if case let .folder(_, ownerType) = mountLocation {
                    return ownerType
                } else {
                    return SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
                }
            }()
            completion(.folder, ownerType, dialog?.textField.text)
            DocsTracker.reportSpaceCreateNewFolderClick(params: .create(false, target: target), bizParms: bizParameter)
        })
        dialog.bindInputEventWithConfirmButton(createButton)
        createRouter?.routerPresent(vc: dialog, animated: true) {
            textField.becomeFirstResponder()
        }
        reportClick(parm: ["action": DocsType.folder.name])
        DocsTracker.reportSpaceCreateNewFolderView(false, bizParms: bizParameter)
    }
    public func directlyCreateFolder() {
        let createFolderHandler = createByDirectorHandler()
        showInputDialogWhenCreateFolder(createRouter: createRouter,
                                        completion: createFolderHandler)
    }

    public func createFolder(enableState: Observable<Bool>) -> Item {
        let createFolderHandler = createByDirectorHandler()
        let clickHandler: () -> Void = { [weak createRouter] in
            showInputDialogWhenCreateFolder(createRouter: createRouter,
                                            completion: createFolderHandler)
        }
        return Item.Lark.folder(enableState: enableState) { event in
            guard event.itemEnable else { return }
            event.createController.dismiss(animated: true, completion: clickHandler)
        }
    }
}

// MARK: - Drive Upload
extension SpaceCreatePanelHelper {

    public func uploadImage(enableState: Observable<Bool>) -> Item {
        let uploadDriveHandler = createUploadDriveHandler()
        let uploadImageHandler: CreateHandler = { event in
            uploadDriveHandler(event, true)
        }
        return Item.Lark.uploadImage(enableState: enableState, clickHandler: uploadImageHandler)
    }

    public func uploadFile(enableState: Observable<Bool>) -> Item {
        let uploadDriveHandler = createUploadDriveHandler()
        let uploadFileHandler: CreateHandler = { event in
            uploadDriveHandler(event, false)
        }
        return Item.Lark.uploadFile(enableState: enableState, clickHandler: uploadFileHandler)
    }

    private func createUploadDriveHandler() -> (CreateEvent, Bool) -> Void {
        return { [weak createRouter] event, isPhoto in
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let request = PermissionRequest(token: "", type: .file,
                                            operation: .upload,
                                            bizDomain: .ccm,
                                            tenantID: nil)
            let response = permissionSDK.validate(request: request)
            response.didTriggerOperation(controller: event.createController)
            guard response.allow else { return }
            // admin 的判断在 enable 之前
            guard event.itemEnable else { return }
            event.createController.dismiss(animated: true) {
                let type: DocsType = isPhoto ? .mediaFile : .file
                let director = DriveCreateDirectorV2(type: type, in: folderToken ?? "", fromVC: createRouter?.routerImpl)
                director.upload { (type, finish) in
                    let biz = bizParameter
                    biz.update(fileID: nil, fileType: .file, driveType: isPhoto ? "image": "file")
                    if !finish {
                        DocsTracker.reportSpaceFileChooseClick(params: .cancel, bizParms: biz, mountPoint: "explorer")
                    } else {
                        if type == .file {
                            DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: "file"), bizParms: biz, mountPoint: "explorer")
                        } else {
                            DocsTracker.reportSpaceFileChooseClick(params: .confirm(fileType: "picture"), bizParms: biz, mountPoint: "explorer")
                        }
                        DocsTracker.isSpaceOrWikiUpload = true
                    }
                }
                reportClick(parm: ["sub_action": isPhoto ? "image": "file"])
                let biz = bizParameter
                biz.update(fileID: nil, fileType: .file, driveType: isPhoto ? "image": "file")
                DocsTracker.reportSpaceCreateNewClick(params: isPhoto ? .imageUpload : .fileUpload, bizParms: biz)
                DocsTracker.reportSpaceFileChooseView(bizParms: biz)
            }
        }
    }
}

public protocol DocsCreateViewControllerDelegate: AnyObject {
    func createComplete(token: String?, type: DocsType, error: Error?)
    func createCancelled()
}

public protocol DocsCreateViewControllerRouter: RouterProtocol {
    func createFolderComplete(folderToken: String)
}

public extension DocsCreateViewControllerRouter {
    func createFolderComplete(folderToken: String) {}
}
