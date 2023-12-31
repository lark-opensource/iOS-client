//
//  JSServicesManager.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/12/3.
//
//https://bytedance.feishu.cn/space/doc/doccnTt4OZ8y7o5VpJPYAJlkIRh

import Foundation
import SKCommon
import SKFoundation
import LarkWebViewContainer
import SpaceInterface
import SKInfra
import LarkContainer

extension DocsJSServicesManager: BrowserViewLifeCycleEvent {
    public func browserWillClear() {
        clearWork?.cancel()
        clearWork = geneClearItem()
        DocsLogger.info("in browserWillClear, gen clearwork, cancelDelay=\(cancelDelayReleaseJsbFg)")
        if cancelDelayReleaseJsbFg {
            clearWork?.perform()
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1, execute: clearWork!)
        }
    }
}

public final class DocsJSServicesManager: JSServicesManager {

    public private(set) weak var ui: BrowserUIConfig?
    public private(set) weak var model: BrowserModelConfig?
    public internal(set) weak var navigator: BrowserNavigator?
    private let cancelDelayReleaseJsbFg = LKFeatureGating.cancelDelayReleaseJsbFg

    private func geneClearItem() -> DispatchWorkItem {
        return  DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            DocsLogger.info("clear work called")
            self.unRegister(handlers: self.businessServices)
            self.businessServices.removeAll(keepingCapacity: false)
            self.clearWork = nil
        }
    }
    private var clearWork: DispatchWorkItem?
    private var baseServices = [JSServiceHandler]()
    private var businessServices = [JSServiceHandler]()

    //新DocsWebViewV2的Bridge，新WebViewGA暂时转发到旧Bridge处理
    weak var lkwBridge: LarkWebViewBridge?
    var lkwAPIHandler: LarkWebViewAPIHandler?

    init(navigator: BrowserNavigator?, userResolver: UserResolver) {
        self.navigator = navigator
        super.init(userResolver: userResolver)
    }

    override public func register(handler: JSServiceHandler) -> JSServiceHandler {
        //LKW: 注册旧Brige时同步到新Bridge上
        if let lkwAPIHandler = self.lkwAPIHandler {
            handler.handleServices.forEach { jsService in
                lkwBridge?.registerAPIHandler(lkwAPIHandler, name: jsService.rawValue)
            }
        }
        return super.register(handler: handler)
    }

    func registerServices(ui: BrowserUIConfig?, model: BrowserModelConfig?, fileType: DocsType?) {
        self.ui = ui
        self.model = model
        if clearWork?.isCancelled ?? true {
            DocsLogger.info("in registerServices, clear work nil or finished")
        } else {
            DocsLogger.info("in registerServices, clear work not finished ,perform")
            // perform 以后，clearwork会是nil，先保存起来
            // 不cancel的话，会再次执行，导致services 被移除
            let work = clearWork
            clearWork?.perform()
            work?.cancel()
        }
        clearWork = nil
        if baseServices.isEmpty {
            registerBaseService()
        }
        if UserScopeNoChangeFG.HZK.fixRepeatRegisterJsb {
            if businessServices.isEmpty {
                fileType.map { registerBusinessHandlerFor($0) }
            }
        } else {
            fileType.map { registerBusinessHandlerFor($0) }
        }
    }

    public func registerBusinessService(handler: DocsJSServiceHandler) {
         businessServices.append(register(handler: handler))
    }

    private func registerBaseService() {
        DocsLogger.info("registerBaseService ")
        baseServices.append(contentsOf: registerNetStatus())
        guard let ui = self.ui, let model = self.model else { return }
        baseServices.append(register(handler: UtilLoadingService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: MinaConfigChange(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: NotifyReadyService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: PreloadReadyService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: FgConfigChange(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilDataService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilLoggerService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: CommentTeaService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilShowPermissionPanelService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilBatchLoggerService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilFetchService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilFetchSSRService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilShowMessage(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: RNDataService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UpdateUserPermissionService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilNotifyEventService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: PreloadHtmlServices(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilFullscreenService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: GetOnboardingStatusesService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: SetOnboardingFinishedService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: GetInfoService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: OrientationControlService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilShowQuotaDialog(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilSetKeyValueService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: UtilGetKeyValueService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: NotifyClearDoneService(ui: ui, model: model, navigator: navigator)))
        baseServices.append(register(handler: EditStatusService(ui: ui, model: model, navigator: navigator)))
        if #available(iOS 13.0, *) {
            baseServices.append(register(handler: DarkModeThemeService(ui: ui, model: model, navigator: navigator)))
        } else {
            baseServices.append(register(handler: MockDarkModeThemeService(ui: ui, model: model, navigator: navigator)))
        }

        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        userResolver.docs.moduleManager.registerJSServices(type: .base, ui: ui, model: model, navigator: navigator) { (handler) in
            baseServices.append(register(handler: handler))
        }
    }

    private func registerBusinessHandlerFor(_ fileType: DocsType) {
        DocsLogger.info("registerBusinessHandlerFor \(fileType)")
        registerBusinessForCommon()
        switch fileType {
        case .doc, .docX:
            registerDocSerivce()
        case .sheet:
            registerSheetService()
        case .mindnote:
            registerMindnoteService()
        case .slides:
            registerSlidesService()
        default: ()
        }
    }

    private func registerBusinessForCommon() {
        guard let ui = self.ui, let model = self.model else { return }
        businessServices.append(register(handler: UtilShowPage(ui: ui, model: model, navigator: navigator)))
//        businessServices.append(register(handler: TranslationOrignalContentService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: RightBottomBtnFeatureService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: TranslationLoadingService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: TranslationService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilShowMenuServices(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilLongPicService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: CommentShowCardsService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: CommentNative2JSService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: CommonParamsService(ui: ui, model: model, navigator: navigator)))

        businessServices.append(register(handler: GetBrowserVCLayoutInfoService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: OpenCommentImageService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: CommentRequestNative(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilFilePreviewService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilAttachFilePreviewService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilFailEventService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilKeyboardService(ui.uiResponder)))
        businessServices.append(register(handler: UtilProfileService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilSyncService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilOpenImgService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilTitleService(ui.displayConfig)))
        businessServices.append(register(handler: UtilPartialLoadingService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilLikeListService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: KeyboardService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: KeyboardHeightService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: ReportService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UploadImageV2Service(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: NavigationMenuService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: NavigationMenuInterceptionService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: NavigationTitleService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: NavigationContextMenuService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: NavigationPaddingService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: ClipboardService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilToastService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilImpactFeedbackService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilOpenDocService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilBackPageService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilAlertService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilActionSheetService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: KeyboardInfoService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilToggleTitlebarService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilToggleSwipeGestureService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilSave2ImageService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilAtService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilShareService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: MultiTaskService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: KeyboardGetTypeService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: ReminderService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilWebLifeCycleService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: ReactionService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilBottomPopupService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilDocsInfoUpdateService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilSetStatusService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilOrientionService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilFocusableService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilDocsShortcutService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: CustomHeaderService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: AnnouncementService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: ShowMoreDialogService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilKeyDownRecordService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilTemplateService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: SecretLevelService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: DLPService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilShowTimePickerService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: PermissionSSCUpgradeService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: TNSRedirectService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilPeformanceService(ui: ui, model: model, navigator: navigator)))

        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        userResolver.docs.moduleManager.registerJSServices(type: .commonBusiness, ui: ui, model: model, navigator: navigator) { (handler) in
            businessServices.append(register(handler: handler))
        }
    }

    //监听网络状态
    private func registerNetStatus() -> [JSServiceHandler] {
        let config = SKBaseNetStatusPluginConfig(executeJsService: self, netstatusService: DocsNetStateMonitor.shared)
        let plugin = SKBaseNetStatusPlugin(config)
        plugin.logPrefix = model?.jsEngine.editorIdentity ?? ""
        return [register(handler: plugin)]
    }

    private func registerDocSerivce() {
        guard let ui = self.ui, let model = self.model else { return }
        let browserDependency = getSKBrowserDependency()
        browserDependency?.registerDocService(type: .individualBusiness, ui: ui, model: model, navigator: navigator) { (handler) in
            businessServices.append(register(handler: handler))
        }
    }

    private func registerSheetService() {
        guard let ui = self.ui, let model = self.model else { return }
        let browserDependency = getSKBrowserDependency()
        browserDependency?.registerSheetService(type: .individualBusiness, ui: ui, model: model, navigator: navigator) { (handler) in
            businessServices.append(register(handler: handler))
        }
    }

    private func registerMindnoteService() {
        guard let ui = self.ui, let model = self.model else { return }
        let browserDependency = getSKBrowserDependency()
        browserDependency?.registerMindnoteService(type: .individualBusiness, ui: ui, model: model, navigator: navigator) { (handler) in
            businessServices.append(register(handler: handler))
        }
    }
    
    private func registerSlidesService() {
        guard let ui = self.ui, let model = self.model else { return }
        let browserDependency = getSKBrowserDependency()
        browserDependency?.registerSlidesService(type: .individualBusiness, ui: ui, model: model, navigator: navigator) { (handler) in
            businessServices.append(register(handler: handler))
        }
    }
    
    private func getSKBrowserDependency() -> SKBrowserDependency? {
        userResolver.docs.browserDependency
    }
    
    func registerDocsCustomService(toolConfig: BrowserToolConfig) {
        guard let ui = self.ui, let model = self.model else {
            spaceAssertionFailure("Invalid")
            return
        }
        businessServices.append(register(handler: UtilAtFinderService(ui: ui, model: model, navigator: navigator, tool: toolConfig)))
        businessServices.append(register(handler: CommentFeedService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: AIChatModeService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: CommentInputService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: CommentSendStatisticService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: NavigationToolbarService(ui: ui, model: model, navigator: navigator, tool: toolConfig)))
        businessServices.append(register(handler: UserGuideService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: VCFollowService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: PositionKeeperService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilDomainService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: PencilkitService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilTaskAssigneeService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilPowerConsumptionTrackService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilDowngradeService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: DocContentReactionService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: UtilMSFloatWindowService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: InlineAIService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: AssociateAppService(ui: ui, model: model, navigator: navigator)))
    }

    func registerShareCustomService(toolConfig: BrowserToolConfig) {
        guard let ui = self.ui, let model = self.model else {
            spaceAssertionFailure("Invalid")
            return
        }
        businessServices.append(register(handler: PickMediaService(ui: ui, model: model, navigator: navigator, tool: toolConfig)))
        businessServices.append(register(handler: PickFileService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: SelectIconService(ui: ui, model: model, navigator: navigator)))
        businessServices.append(register(handler: PickH5ImageService(ui: ui, model: model, navigator: navigator)))
    }
}

extension DocsJSServicesManager: SKExecJSFuncService {
    //为了避免循环引用。直接使用model.jsEngine 会导致引用到docsBrowserview
    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }
}
