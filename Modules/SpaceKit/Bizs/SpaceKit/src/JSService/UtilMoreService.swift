//  Created by Songwen on 2018/10/23.
// swiftlint:disable file_length line_length

import WebKit
import SwiftyJSON
import EENavigator
import LarkUIKit
import LarkAlertController
import SKCommon
import SKDoc
import SKFoundation
import SKBrowser
import SKUIKit
import UniverseDesignToast
import SKResource
import HandyJSON
import RxSwift
import RxCocoa
import SKWikiV2
import LarkSuspendable
import SpaceInterface
import SKInfra
import LarkContainer

class UtilMoreService: BaseJSService, UDDialogInputDelegate {
    var callbackFunc: DocsJSCallBack?
    
    let permissionManager = DocsContainer.shared.resolve(PermissionManager.self)!
    var moreViewDataModel: SpaceManagementAPI?
    private(set) lazy var workbenchManager = WorkbenchRequestManager.shared
    private var readingDataRequest: ReadingDataRequest?
    private var filePermissionRequest: DocsRequest<[String: Any]>?
    private weak var readingDataViewController: ReadingDetailControllerType?
    private var frontReaingDataExeBlock: ((ReadingInfo) -> Void)?
    private(set) var readinfos: [ReadingItemInfo] = []
    private var disableItems: [MoreItemType] = [] // 前端控制导灰Items
    private var readingCache: (DocsReadingInfoModel?, ReadingInfo?) = (nil, nil)
    internal var badges: [String] = []
    
    // 即将删除的代码，转移到 SKBitable
    @available(*, deprecated, message: "This method is deprecated")
    weak var adPermVC: BitableAdPermSettingVC?
    
    var searchUIManager: SearchReplaceUIManager?
    var searchCallBackList = [DocsJSService: String]()

    let bag = DisposeBag()
    private weak var moreVCV2: MoreViewControllerV2?
    //防抖，0.1s内来自前端的more菜单调用不响应
    // disable-lint: magic number
    private var throttle = SKThrottle(interval: 0.1)
    // enable-lint: magic number
    private weak var readingDataReceived: PublishRelay<[ReadingPanelInfo]>?
    /// more面板数据源，持有用于保留网络请求相关回调操作
    private var provider: UtilMoreDataProvider?
    private var currentTopMost: UIViewController? {
        guard let currentBrowserVC = navigator?.currentBrowserVC else {
            return nil
        }
        return UIViewController.docs.topMost(of: currentBrowserVC)
    }
    
    // wikiMoreActionHandler
    private lazy var wikiMoreActionHandler: WikiMoreActionHandler? = {
        guard let docsInfo = hostDocsInfo, let hostVC = currentTopMost else {
            return nil
        }
        let browser = navigator?.currentBrowserVC as? WikiContextProxy
        let synergyUUID = browser?.wikiContextProvider?.synergyUUID
        return WikiMoreActionHandler(docsInfo: docsInfo, hostViewController: hostVC, synergyUUID: synergyUUID)
    }()
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
    
    func showMoreView(params: [String: Any]) {
        guard let docsInfo = hostDocsInfo else {
            spaceAssertionFailure("docsInfo is nil")
            DocsLogger.error("docsInfo is nil")
            return
        }
        if docsInfo.isOriginDriveFile {
            guard let shadowFileManger = DocsContainer.shared.resolve(DriveShadowFileManagerProtocol.self) else { return }
            guard let browserVC = navigator?.currentBrowserVC as? BaseViewController,
                  let shadowId = docsInfo.shadowFileId else {
                DocsLogger.warning("shadow file open more fail, no browserVC")
                return
            }
            shadowFileManger.showMorePanel(id: shadowId, from: browserVC, sourceView: nil, sourceRect: nil)
            return
        }
        if docsInfo.inherentType.supportCommentWhenLandscape {
            self.showMoreViewAfterCheckOrientation(params: params)
        } else {
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                self?.showMoreViewAfterCheckOrientation(params: params)
            }
        }
    }
    
    func showMoreViewAfterCheckOrientation(params: [String: Any]) {
        guard let topMost = currentTopMost, let docsInfo = hostDocsInfo else {
            spaceAssertionFailure("currentTopMost or docsInfo is nil")
            DocsLogger.error("currentTopMost or docsInfo is nil")
            return
        }
        guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
            spaceAssertionFailure("token: \(DocsTracker.encrypt(id: docsInfo.token))  permisson service is nil")
            DocsLogger.error("token: \(DocsTracker.encrypt(id: docsInfo.token))  permisson service is nil")
            return
        }
        let userPermissions = model?.permissionConfig.hostUserPermissions
        DocsLogger.info("show new MoreViewController \(docsInfo.type)")
        self.handleBadges(params)
        let provider = self.initializeMoreDataProviderWith(docsInfo: docsInfo,
                                                           hostViewController: topMost,
                                                           userPermissions: userPermissions,
                                                           permissionService: permissionService,
                                                           params: params,
                                                           trackerParams: DocsParametersUtil.createCommonParams(by: docsInfo))
        let viewModel = MoreViewModel(dataProvider: provider,
                                      docsInfo: docsInfo,
                                      onboardingConfig: handleGuideConfig(params))
        let moreVC = MoreViewControllerV2(viewModel: viewModel)
        moreVC.watermarkConfig.needAddWatermark = hostDocsInfo?.shouldShowWatermark ?? true
        if docsInfo.inherentType.supportLandscapeShow {
            moreVC.supportOrientations = currentTopMost?.supportedInterfaceOrientations ?? .portrait
        }
        self.moreVCV2 = moreVC
        self.readingDataReceived = viewModel.readingDataReceived
        self.handleMoreViewModel(viewModel)
        self.moreViewDataModel = provider.dataModel
        self.provider = provider
        
        ui?.uiResponder.resign()
        let focusInBrowserVC = navigator?.currentBrowserVC?.isFirstResponder ?? false
        if !focusInBrowserVC {
            //除了上面的uiResponder.resign，还要确保在点击more时browservc能变成FirstResponder，如果FirstResponder停留在WebView，在more菜单dismiss后webview会重新becomeFirstResponder,会导致非预期的滚动(比如在more中点击目录位置https://meego.feishu.cn/larksuite/issue/detail/3583783)
            DocsLogger.info("currentBrowserVC becomeFirstResponder")
            navigator?.currentBrowserVC?.becomeFirstResponder()
        }
        
        if SKDisplay.pad, ui?.hostView.isMyWindowRegularSize() ?? false {
            let browserVC = navigator?.currentBrowserVC as? BaseViewController
            browserVC?.showPopover(to: moreVC, at: -1)
        } else {
            let isInVCFollow = self.hostDocsInfo?.isInVideoConference ?? false
            if isInVCFollow {
                moreVC.modalPresentationStyle = .overFullScreen
            }
            navigator?.presentViewController(moreVC, animated: true, completion: nil)
        }
        requestWordCount()
    }

    func handleGuideConfig(_ params: [String: Any]) -> MoreOnboardingConfig? {
        guard let guideConfig = params["guideConfig"] as? [String: Any] else {
            return nil
        }
        guard model?.vcFollowDelegate == nil else {
            DocsLogger.onboardingInfo("VC Follow 时不能显示引导")
            return nil
        }
        guard let action = guideConfig["action"] as? String else {
            DocsLogger.onboardingError("最关键的引导 key 没给")
            let undefined = "mobile_illegal_onboarding_item"
            model?.jsEngine.callFunction(DocsJSCallBack.notifyGuideFinish,
                                         params: ["action": undefined,
                                                  "status": "failed"],
                                         completion: nil)
            return nil
        }
        guard let id = OnboardingID(rawValue: action) else {
            DocsLogger.onboardingError("我不能播放 \(action)!!")
            model?.jsEngine.callFunction(DocsJSCallBack.notifyGuideFinish,
                                         params: ["action": action,
                                                  "status": "failed"],
                                         completion: nil)
            return nil
        }
        return MoreOnboardingConfig(id: id,
                                    currentIndex: guideConfig["currentIndex"] as? Int,
                                    totalCount: guideConfig["totalCount"] as? Int,
                                    isLast: guideConfig["isLast"] as? Bool,
                                    nextID: guideConfig["nextID"] as? String,
                                    shouldCheckDependencies: guideConfig["shouldCheckDependencies"] as? Bool)
    }

    func handleBadges(_ params: [String: Any]) {
        if let badges = params["badges"] as? [String] {
            self.badges = badges
        }
        
        let params: [String: Any] = ["panelName": "more_panel", "badges": []]
        self.model?.jsEngine.callFunction(DocsJSCallBack.sheetClearBadges, params: params, completion: nil)
    }
}

extension UtilMoreService {
    
    func requestWordCount() {
        requestOpenReadingDataPanel(false)
    }
}

extension UtilMoreService: BitableAdPermSettingVCDelegate {
    var jsService: SKExecJSFuncService? {
        model?.jsEngine
    }
}

extension UtilMoreService: BrowserViewLifeCycleEvent {
    func browserWillClear() {
        searchUIManager = nil
        workbenchManager.clearAllRequest()
    }
    
    func browserDidDismiss() {
        moreVCV2?.dismiss(animated: false)
        moreVCV2 = nil
        moreViewDataModel = nil
    }
}

extension UtilMoreService: DocsJSServiceHandler {
    func atViewController(type: AtViewType) -> AtListView? {
        guard let m = self.model else { return nil }
        guard m.requestAgent.currentUrl?.host != nil,
            let fileType = m.hostBrowserInfo.docsInfo?.type,
            let token = m.hostBrowserInfo.token else { spaceAssertionFailure(); return nil }
        let chatID = m.hostBrowserInfo.chatId
        let atConfig = AtDataSource.Config(chatID: chatID, sourceFileType: fileType, location: type, token: token)
        let dataSource = AtDataSource(config: atConfig)
        return AtListView(dataSource, type: type)
    }
    
    var handleServices: [DocsJSService] {
        
        var result: [DocsJSService] = [
            .moreEvent,
            .historyEvent,
            .search,
            .switchSearchResult,
            .clearSearchResult,
            .updateSearchResult,
            .exitSearchResult,
            .sheetOpenSearch,
            .receiveWordCount,
            .simulateOpenSearch,
            .secretSetting
        ]
        return result
    }
    
    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.historyEvent.rawValue:
            if let callbackFuncStr = params["callback"] as? String {
                callbackFunc = DocsJSCallBack(callbackFuncStr)
            }
        case DocsJSService.moreEvent.rawValue:
            if let window = currentTopMost?.view.window {
                UDToast.removeToast(on: window)
            }
            throttle.schedule({[weak self] in
                self?.showMoreView(params: params)
            }, jobId: DocsJSService.moreEvent.rawValue)
        case DocsJSService.updateSearchResult.rawValue:
            guard let current = params["currentIndex"] as? Int, let total = params["totalNum"] as? Int else { return }
            handleJsUpdateSearch(current: current, total: total)
        case DocsJSService.receiveWordCount.rawValue:
            didReceiveReadingData(data: params)
        case DocsJSService.exitSearchResult.rawValue:
            removeSearchView()
        case DocsJSService.simulateOpenSearch.rawValue:
            handleSimulateOpenSearch()
        case DocsJSService.sheetOpenSearch.rawValue:
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                self.handleSimulateOpenSearch()
            }
        case DocsJSService.secretSetting.rawValue:
            self.showSensitivtyLabelSetting(hostDocsInfo?.secLabel, fromToolBar: true)
        default:
            let cmd = DocsJSService(rawValue: serviceName)
            if let callBack = params["callback"] as? String {
                registerCallBack(event: cmd, with: callBack)
            }
        }
    }
}

extension UtilMoreService {
    /// 需要获取navigator相关信息用于UIActivityViewController的展示
    func moreViewShowExportDocumentVC(editorEnable: Bool, shouldHideLongPic: Bool) {
        guard let hostVC = navigator?.currentBrowserVC as? BaseViewController, let docsInfo = hostDocsInfo else {
            spaceAssertionFailure("fail to get host vc when try to present sort vc")
            return
        }
        if CacheService.isDiskCryptoEnable() {
            //KACrypto
            DocsLogger.error("[KACrypto] 开启KA加密不能导出文档")
            UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_ECM_ShareSecuritySettingKAToast, on: hostVC.view.window ?? hostVC.view)
            return
        }
        guard let popoverInfo = hostVC.obtainPopoverInfo(at: -1) else {
            spaceAssertionFailure("fail to get browserVC or popoverInfo when try to present exportDocumentVC")
            return
        }
        let hideLongPic = shouldHideLongPic || model?.hostBrowserInfo.isInVideoConference == true
        let needFromSheet = SKDisplay.pad && (ui?.hostView.isMyWindowRegularSize() ?? false)
        let body: ExportDocumentViewControllerBody = ExportDocumentViewControllerBody(docsInfo: docsInfo,
                                                                                      hostSize: hostVC.view.bounds.size,
                                                                                      isFromSpaceList: false,
                                                                                      hideLongPicAlways: hideLongPic,
                                                                                      needFormSheet: needFromSheet,
                                                                                      isEditor: editorEnable,
                                                                                      hostViewController: hostVC,
                                                                                      module: .home(.recent),
                                                                                      containerID: nil,
                                                                                      containerType: nil,
                                                                                      popoverSourceFrame: popoverInfo.sourceFrame,
                                                                                      padPopDirection: popoverInfo.direction,
                                                                                      sourceView: popoverInfo.sourceView,
                                                                                      proxy: self)
        Navigator.shared.present(body: body, from: hostVC, animated: true)
    }
}

extension UtilMoreService: ExportLongImageProxy {
    func handleExportSheetText() {
        spaceAssertionFailure("不可能在这里触发 sheet 卡片模式分享的逻辑")
    }

    func handleExportSheetLongImage(with params: [String: Any]) {
        guard let docsInfo = hostDocsInfo, let hostView = self.ui?.hostView,
        let hostController = navigator?.currentBrowserVC else {
            DocsLogger.error("docsInfo or host is nil")
            return
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard let service = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                spaceAssertionFailure()
                return
            }
            let response = service.validate(operation: .export)
            response.didTriggerOperation(controller: hostController)
            guard response.allow else { return }
            if CacheService.showFailureIfDiskCryptoEnable(on: hostView) { return }
        } else {
            if DlpManager.showTipsIfUnSafe(on: hostView, with: docsInfo, action: .EXPORT) ||
                CacheService.showFailureIfDiskCryptoEnable(on: hostView) {
                return
            }
        }
        self.model?.jsEngine.callFunction(DocsJSCallBack.sheetClickExport, params: params, completion: nil)
    }

    func handleExportDocsLongImage() {
        guard let docsInfo = hostDocsInfo,
              let hostView = self.ui?.hostView,
              let hostController = navigator?.currentBrowserVC else {
            DocsLogger.error("docsInfo or hostView is nil")
            return
        }
        if UserScopeNoChangeFG.WWJ.permissionSDKEnableInCreation {
            guard let service = model?.permissionConfig.getPermissionService(for: .hostDocument) else {
                spaceAssertionFailure()
                return
            }
            let response = service.validate(operation: .export)
            response.didTriggerOperation(controller: hostController)
            guard response.allow else { return }
            if CacheService.showFailureIfDiskCryptoEnable(on: hostView) { return }
        } else {
            if DlpManager.showTipsIfUnSafe(on: hostView, with: docsInfo, action: .EXPORT) ||
                CacheService.showFailureIfDiskCryptoEnable(on: hostView) {
                return
            }
        }
        self.model?.jsEngine.simulateJSMessage(DocsJSService.screenShotStart.rawValue, params: [:])
    }
}

// MARK: - ReadingDataFrontDataSource

extension UtilMoreService: ReadingDataFrontDataSource {
    func requestData(request: ReadingDataRequest, docs: DocsInfo, finish: @escaping (ReadingInfo) -> Void) {
        if !readinfos.isEmpty {
            finish(readinfos)
        }
        self.frontReaingDataExeBlock = finish
    }
    
    // 请求阅读数据的回调，如果是doc 会调用两边
    func requestRefresh(info: DocsReadingData?, data: [ReadingPanelInfo], avatarUrl: String?, error: Bool) {
        if let data = info {
            switch data {
            case .words(let readingInfo):
                if readingInfo != nil {
                  self.readingCache.1 = readingInfo
                }
            case .details(let docsReadingInfoModel):
                if docsReadingInfoModel != nil {
                   self.readingCache.0 = docsReadingInfoModel
                }
            case .fileMeta: // FIXME: use unknown default setting to fix warning
                break
            @unknown default:
                break
            }
        }
        self.readingDataViewController?.refresh(info: info, data: data, avatarUrl: avatarUrl, success: !error)
        self.readingDataReceived?.accept(data)
        if error, readingDataViewController != nil {
            guard let hostView = self.ui?.hostView else { return }
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: hostView)
        }
    }
}

extension UtilMoreService {
    
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        model?.jsEngine.callFunction(function, params: params, completion: { (_, error) in
            guard error == nil else {
                DocsLogger.error(String(describing: error))
                return
            }
        })
    }
    
    private func registerCallBack(event: DocsJSService, with callBack: String) {
        searchCallBackList[event] = callBack
    }
    
    func requestOpenReadingDataPanel(_ needShowVC: Bool = true) {
        guard let docsInfo = hostDocsInfo else { return }
        //统计
        let params = ["action": "file_within_info_page",
                      "file_type": docsInfo.type.name,
                      "file_id": DocsTracker.encrypt(id: docsInfo.objToken),
                      "module": "doc"]
        DocsTracker.log(enumEvent: DocsTracker.EventType.clickReadingInfo, parameters: params)
        
        //前后端的数据请求都需要时间，先放假数据去跑loading
        let fakeData = ReadingDataRequest.fakeData(info: docsInfo)
        if needShowVC, let hostVC = navigator?.currentBrowserVC {
            let supportNewDetailInfoTypes = DocDetailInfoViewController.supportDocTypes
            if supportNewDetailInfoTypes.contains(docsInfo.inherentType) {
                let vc = DocDetailInfoViewController(docsInfo: docsInfo,
                                                     hostView: hostVC.view,
                                                     permission: model?.permissionConfig.hostUserPermissions,
                                                     permissionService: model?.permissionConfig.getPermissionService(for: .hostDocument))
                if docsInfo.inherentType.supportLandscapeShow {
                    vc.supportOrientations = hostVC.supportedInterfaceOrientations ?? .portrait
                }
                var cacheData: [DocsReadingData] = []
                if let detailsModel = readingCache.0 {
                    cacheData.append(.details(detailsModel))
                }
                if let wordsModel = readingCache.1 {
                    cacheData.append(.words(wordsModel))
                }
                if !cacheData.isEmpty {
                    vc.refreshCache(cacheData)
                }
                vc.needRefresh = { [weak self] type in
                    switch type {
                    case .all:
                        self?.readingDataRequest?.request()
                        self?.requestFetchReadingData()
                    case .onlyWords:
                        self?.requestFetchReadingData()
                    case .onlyDetails:
                        self?.readingDataRequest?.request()
                    }
                }
                vc.openDocumentActivity = { [weak self] _, _ in
                    self?.showOperationHistoryPanel()
                }
                vc.watermarkConfig.needAddWatermark = hostDocsInfo?.shouldShowWatermark ?? true
                readingDataViewController = vc
                let nav = LkNavigationController(rootViewController: vc)
                if SKDisplay.pad, hostVC.isMyWindowRegularSize() {
                    nav.modalPresentationStyle = .formSheet
                } else {
                    nav.modalPresentationStyle = .overFullScreen
                }
                navigator?.presentViewController(nav, animated: false, completion: nil)
            } else if needShowVC {
                DocsLogger.warning("[doc detail] goto old page show:\(needShowVC) hostVC:\( navigator?.currentBrowserVC) type:\(docsInfo.inherentType)")
//                let readingViewcontroller = ReadingDataViewController(docsInfo, readingPanelInfo: fakeData, hostSize: hostVC.view.bounds.size, fromVC: hostVC)
//                readingViewcontroller.delegate = self
//                readingViewcontroller.watermarkConfig.needAddWatermark = hostDocsInfo?.shouldShowWatermark ?? true
//                readingDataViewController = readingViewcontroller
//                navigator?.presentViewController(readingViewcontroller, animated: true, completion: nil)
            }
        }
        //发起真正的数据请求
        readingDataRequest = ReadingDataRequest(docsInfo)
        readingDataRequest?.dataSource = self
        readingDataRequest?.request()
        requestFetchReadingData()
    }
    
    /// 设置5s超时 请求3次
    func requestFetchReadingData(retryCount: Int = 3) {
        guard let docsInfo = hostDocsInfo else { return }
        DocsLogger.info("fetch web reading data isRetrying: \(retryCount != 3)", component: LogComponents.docsDetailInfo)
        let supportTypes = DocDetailInfoViewController.supportDocTypes
        if supportTypes.contains(docsInfo.inherentType) {
            model?.jsEngine.callFunction(DocsJSCallBack.fetchWordCount, params: nil, completion: { (_, error) in
                guard error == nil else {
                    DocsLogger.error("fetch web reading data error", error: error, component: LogComponents.docsDetailInfo)
                    DispatchQueue.main.async {
                        self.readingDataViewController?.refresh(info: .words(nil), data: [], avatarUrl: nil, success: false)
                    }
                    return
                }
              }
            )
            //TODO: 这里的逻辑太怪，后面看看优化
            let noWordCountTypes: [DocsType] = [.mindnote, .sheet, .bitable, .slides]
            if noWordCountTypes.contains(docsInfo.inherentType) {
                let message = DocsJSService.receiveWordCount.rawValue
                model?.jsEngine.simulateJSMessage(message, params: [:])
            }
            guard retryCount > 0 else {
                DocsLogger.error("fetch web reading data timeout", component: LogComponents.docsDetailInfo)
                // 超时了
                if self.readinfos.isEmpty {
                    self.readingDataViewController?.refresh(info: .words(nil), data: [], avatarUrl: nil, success: false)
                }
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) { [weak self] in
                guard let self = self else { return }
                if self.readinfos.isEmpty {
                    self.requestFetchReadingData(retryCount: retryCount - 1)
                }
            }
            
        }
    }
    
//    func requestOpenIconPanel() {
//        guard IconPickerViewController.canOpenIconPicker() else {
//            IconPickerViewController.showErrorIfExist()
//            return
//        }
//
//        guard let model = model, let docsInfo = model.hostBrowserInfo.docsInfo else { return }
//        var iconData: IconData?
//        if let iconKey = docsInfo.customIcon?.iconKey, let iconType = docsInfo.customIcon?.iconType {
//            iconData = (iconKey, iconType)
//        }
//        let viewController = IconPickerViewController(token: docsInfo.objToken, iconData: iconData, model: model)
//        // let navigationController = LkNavigationController(rootViewController: viewController)
//        navigator?.presentViewController(viewController, animated: true, completion: nil)
//    }
    
    private func didReceiveReadingData(data: [String: Any]) {
        DocsLogger.info("fetch web reading data success", component: LogComponents.docsDetailInfo)
        var infos: [ReadingItemInfo] = [ReadingItemInfo]()
        if let wordCount = data["wordCount"] as? Int {
            infos.append(ReadingItemInfo(.wordNumber, String(wordCount)))
        }
        if let charNumber = data["characterCount"] as? Int {
            infos.append(ReadingItemInfo(.charNumber, String(charNumber)))
        }
        self.readinfos = infos
        if let block = self.frontReaingDataExeBlock {
            block(infos)
        }
    }

    func handleRename() {
        let isVersion = self.hostDocsInfo?.isVersion ?? false
        if isVersion,
           let token = self.hostDocsInfo?.sourceToken,
           let type = self.hostDocsInfo?.inherentType {
            DocsVersionManager.shared.requestAllVersionNames(token: token, type: type)
        }
        //logic from moreviewcontroller+itemaction
        let alert = LarkAlertController()
        var title: String
        var alertTitle: String
        if isVersion {
            title = self.hostDocsInfo?.versionInfo?.name ?? ""
            alertTitle = BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_RenameV_Button
        } else {
            title = hostDocsInfo?.title ?? ""
            alertTitle = BundleI18n.SKResource.Doc_More_RenameSheetTitle
        }
        let pointId = ClipboardManager.shared.getEncryptId(token: hostDocsInfo?.objToken)
        alert.textField.input.pointId = pointId //控制单一文档复制的逻辑
        alert.setTitle(text: alertTitle, inputView: true)
        let textField = alert.addTextField(placeholder: isVersion ? BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_SaveAsVersion_Name_Placeholder(hostDocsInfo?.title ?? "") : BundleI18n.SKResource.Doc_More_RenameSheetPlaceholder, text: title)

        if let baseTextField = textField.input as? SKBaseTextField,
           let forbiddenBlock = getCopyForbiddenBlockWhenRename(pointID: pointId) {
            baseTextField.copyForbiddenBlock = { [weak alert] in
                guard let alert else { return }
                forbiddenBlock(alert)
            }
        }

        alert.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel, dismissCheck: { [weak self] () -> Bool in
            if let docInfo = self?.hostDocsInfo, docInfo.isVersion {
                var params = ["click": "cancel", "target": "none"]
                params.merge(other: DocsParametersUtil.createCommonParams(by: docInfo))
                if self?.hostDocsInfo?.inherentType == .sheet {
                    DocsTracker.newLog(enumEvent: .sheetRenameVersionClick, parameters: params)
                } else {
                    DocsTracker.newLog(enumEvent: .docsRenameVersionClick, parameters: params)
                }
            }
            return true
        })
        alert.inputDelegate = self
        alert.isAutorotatable = true
        let renameConfirmButton = alert.addPrimaryButton(text: isVersion ? BundleI18n.SKResource.Doc_Facade_Confirm : BundleI18n.SKResource.Doc_Normal_OK, dismissCheck: { [weak alert, weak self] () -> Bool in
            guard let newName = alert?.textField.text, newName.isEmpty == false else { return true }
            if let docInfo = self?.hostDocsInfo, docInfo.isVersion {
                var params = ["click": "confirm", "target": "none"]
                params.merge(other: DocsParametersUtil.createCommonParams(by: docInfo))
                if self?.hostDocsInfo?.inherentType == .sheet {
                    DocsTracker.newLog(enumEvent: .sheetRenameVersionClick, parameters: params)
                } else {
                    DocsTracker.newLog(enumEvent: .docsRenameVersionClick, parameters: params)
                }
            }
            // 如果是版本，要检查新名字是否已经存在
            if self?.hostDocsInfo?.isVersion ?? false,
               let token = self?.hostDocsInfo?.sourceToken,
               let type = self?.hostDocsInfo?.inherentType,
               DocsVersionManager.shared.hasSameVersionName(token: token, type: type, newName: newName) {
                alert?.showErrorTips(BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_SaveAsVersion_ExistSame)
                return false
            }
            self?._doRename(newName)
            return true
        })
        alert.bindInputEventWithConfirmButton(renameConfirmButton, initialText: title)
        //使用了新的方式，alert在show完需要focus到textField
        self.navigator?.currentBrowserVC?.present(alert, animated: true) {
            alert.textField.becomeFirstResponder()
        }
        
        if isVersion {
            if hostDocsInfo?.inherentType == .sheet {
                DocsTracker.newLog(enumEvent: .sheetRenameVersion, parameters: nil)
            } else {
                DocsTracker.newLog(enumEvent: .docsRenameVersion, parameters: nil)
            }
        }
    }

    private func getCopyForbiddenBlockWhenRename(pointID: String?) -> ((UIViewController) -> Void)? {
        guard let permissionService = model?.permissionConfig.getPermissionService(for: .hostDocument) else { return nil }
        let response = permissionService.validate(operation: .copyContent)
        guard case let .forbidden(denyType, _) = response.result else { return nil } // 有复制权限，不拦截
        guard case let .blockByUserPermission(reason) = denyType else {
            return {
                response.didTriggerOperation(controller: $0, BundleI18n.SKResource.Doc_Doc_CopyFailed)
            }
        }
        switch reason {
        case .blockByServer, .unknown, .userPermissionNotReady, .blockByAudit:
            if pointID != nil {
                // 有 pointID，说明可以命中单文档粘贴保护，这里假设走到重命名逻辑一定有编辑权限，允许复制
                return nil
            }
        case .blockByCAC, .cacheNotSupport:
            break
        }
        
        return {
            response.didTriggerOperation(controller: $0, BundleI18n.SKResource.Doc_Doc_CopyFailed)
        }
    }

    func checkInputContent(dialog: LarkAlertController, input: String) -> Bool {
        if self.hostDocsInfo?.isVersion ?? false,
           let token = self.hostDocsInfo?.sourceToken,
           let type = self.hostDocsInfo?.inherentType,
            DocsVersionManager.shared.hasSameVersionName(token: token, type: type, newName: input) {
                dialog.showErrorTips(BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_SaveAsVersion_ExistSame)
            return false
        }
        
        return true
    }
    
    func inputFieldHasEdit(dialog: LarkAlertController) {
        if let docInfo = self.hostDocsInfo, docInfo.isVersion {
            var params = ["click": "version_name_input_box", "target": "none"]
            params.merge(other: DocsParametersUtil.createCommonParams(by: docInfo))
            if docInfo.inherentType == .sheet {
                DocsTracker.newLog(enumEvent: .sheetRenameVersionClick, parameters: params)
            } else {
                DocsTracker.newLog(enumEvent: .docsRenameVersionClick, parameters: params)
            }
        }
    }

    private func showToast(text: String, success: Bool = true) {
        guard !text.isEmpty else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_500) { [weak self] in
            guard let hostView = self?.ui?.hostView else { return }
            let view = hostView.window ?? hostView
            if success {
                UDToast.showSuccess(with: text, on: view)
            } else {
                UDToast.showFailure(with: text, on: view)
            }
        }
    }

    private func _doRename(_ newTitle: String) {
        guard let info = hostDocsInfo, let dataModel = moreViewDataModel else {
            return
        }
        ui?.loadingAgent.startLoadingAnimation()
        switch info.inherentType {
        case .sheet:
            if info.isVersion, let versionInfo = info.versionInfo {
                DocsVersionManager.shared.renameVersion(token: versionInfo.versionToken, type: info.inherentType, name: newTitle) { token, result in
                    guard token == versionInfo.versionToken else {
                        return
                    }
                    self.renameVersionComplete(newTitle: newTitle, error: result ? nil : NSError())
                }
            } else {
                dataModel.renameSheet(objToken: info.objToken, wikiToken: info.wikiInfo?.wikiToken, newName: newTitle) { [weak self] (error) in
                    self?.renameComplete(newTitle: newTitle, error: error)
                }
            }
        case .bitable:
            dataModel.renameBitable(objToken: info.objToken, wikiToken: info.wikiInfo?.wikiToken, newName: newTitle) { [weak self] (error) in
                self?.renameComplete(newTitle: newTitle, error: error)
            }
        case .slides:
            dataModel.renameSlides(objToken: info.objToken, wikiToken: info.wikiInfo?.wikiToken, newName: newTitle) { [weak self]
                (error) in
                self?.renameComplete(newTitle: newTitle, error: error)
                
            }
        case .docX, .wiki:
            if info.isVersion {
                DocsVersionManager.shared.renameVersion(token: info.versionInfo!.versionToken, type: info.inherentType, name: newTitle) { token, result in
                    guard token == info.versionInfo!.versionToken else {
                        return
                    }
                    self.renameVersionComplete(newTitle: newTitle, error: result ? nil : NSError())
                }
            }
            
        default:
            return
        }
    }

    private func renameComplete(newTitle: String, error: Error?) {
        self.ui?.loadingAgent.stopLoadingAnimation()
        guard error == nil else {
            if let err = error as? DocsNetworkError, err.code != .success {
                self.showToast(text: err.errorMsg, success: false)
            } else {
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_RenameFailed, success: false)
            }
            return
        }
        self.hostDocsInfo?.title = newTitle
        self.ui?.displayConfig.setNavigation(title: newTitle)
        self.callFunction(.setTitle, params: ["title": newTitle], completion: nil)
        self.showToast(text: BundleI18n.SKResource.Doc_Facade_RenameSuccessfully)
    }
    
    private func renameVersionComplete(newTitle: String, error: Error?) {
        self.ui?.loadingAgent.stopLoadingAnimation()
        guard error == nil else {
            if let err = error as? DocsNetworkError, err.code != .success {
                self.showToast(text: err.errorMsg, success: false)
            } else {
                self.showToast(text: BundleI18n.SKResource.Doc_Facade_RenameFailed, success: false)
            }
            return
        }
        self.hostDocsInfo?.versionInfo?.name = newTitle
        self.ui?.displayConfig.setNavigation(title: newTitle)
        self.showToast(text: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_VnameSaved_Toast)
        guard let token = self.hostDocsInfo?.sourceToken, let type = self.hostDocsInfo?.inherentType, let versionToken = self.hostDocsInfo?.versionInfo?.versionToken else {
            return
        }
        DocsVersionManager.shared.requestAllVersionNames(token: token, type: type)
        DocsVersionManager.shared.updateVersinName(token: token, vertionToken: versionToken, type: type, name: newTitle)
    }

    func showOperationHistoryPanel() {
        guard let info = hostDocsInfo else {
            spaceAssertionFailure()
            return
        }
        let token = info.objToken
        let type = info.type
        guard let hostVC = navigator?.currentBrowserVC else {
            spaceAssertionFailure()
            return
        }
        DocumentActivityAPI.open(objToken: token, objType: type, from: hostVC) { [weak self] controller in
            self?.navigator?.presentViewController(controller, animated: true, completion: nil)
        }
        .disposed(by: bag)
    }
    
    
    func showTimeZoneSetting() {
        guard let model = self.model,
              let info = model.hostBrowserInfo.docsInfo,
              let hostView = self.ui?.hostView else {
                  DocsLogger.error("btGetBaseTimeZone docsInfo is nil")
                  return
              }
        
        func openTimeZoneSetting(timeZone: String) {
            let isIpadAndNoSplit = SKDisplay.pad && hostView.isMyWindowRegularSize()
            let timeZoneSettingVC = TimeZoneSettingController(timeZone: timeZone, isIpadAndNoSplit: isIpadAndNoSplit, model: model)
            if let docsInfo = model.hostBrowserInfo.docsInfo {
                timeZoneSettingVC.commonTrackParamsSetByOutsite = DocsParametersUtil.createCommonParams(by: docsInfo)
            }
            if isIpadAndNoSplit, let topMost = self.currentTopMost {
                let navVC = LkNavigationController(rootViewController: timeZoneSettingVC)
                navVC.modalPresentationStyle = .formSheet
                Navigator.shared.present(navVC, from: topMost, animated: true)
            } else {
                self.navigator?.pushViewController(timeZoneSettingVC)
            }
        }
        
        model.jsEngine.callFunction(DocsJSCallBack.btGetBaseTimeZone, params: ["baseId": info.objToken], completion: { info, error in
            if let error = error {
                DocsLogger.error("btGetBaseTimeZone error: \(error)")
            } else if let timeZone = (info as? [String: Any])?["timeZone"] as? String {
                openTimeZoneSetting(timeZone: timeZone)
            } else {
                openTimeZoneSetting(timeZone: "")
                DocsLogger.error("btGetBaseTimeZone openTimeZoneSetting with current timeZone info: \(info)")
            }
        })
    }
}

//extension UtilMoreService: ReadingDataViewControllerDelegate {
//    func readingDataViewControllerDidDismiss(_ controller: ReadingDataViewController) {
//        readingDataRequest?.cancel()
//        readingDataRequest = nil
//    }
//}

extension UtilMoreService {
    func handleCatalogDetails() {
        guard let hostVC = navigator?.currentBrowserVC as? BaseViewController,
                let docsInfo = hostDocsInfo else {
            DocsLogger.error("currentBrowserVC is nil")
            return
        }
        if SKDisplay.pad, hostDocsInfo?.isVersion ?? false {
            ui?.catalog?.configIPadCatalog(true, autoPresentInEmbed: false, complete: nil)
            CCMKeyValue.globalUserDefault.set(true, forKey: UserDefaultKeys.docxIpadCatalogDisplayLastScene)
            
        } else {
            if docsInfo.inherentType == .docX {
                ui?.catalog?.setCatalogOrentations(hostVC.supportedInterfaceOrientations)
            }
            ui?.catalog?.showCatalogDetails()
        }
    }
    
    func showVersionListPanel() {
        guard let docsInfo = hostDocsInfo else {
            return
        }
        let browserVC = navigator?.currentBrowserVC as? BrowserViewController
        let vm = DocsVersionsPanelViewModel(token: docsInfo.token, type: docsInfo.inherentType, fromSource: FromSource.sourceVersionList)
        let versionPanelVC = DocsVersionViewController(title: BundleI18n.SKResource.LarkCCM_Docx_VersionMgmt_View_SavedVs_Mob, currentVersionToken: nil, viewModel: vm, shouldShowDragBar: !(SKDisplay.pad && ui?.hostView.isMyWindowRegularSize() ?? false))
        versionPanelVC.delegate = browserVC
        ui?.uiResponder.resign()
        let focusInBrowserVC = navigator?.currentBrowserVC?.isFirstResponder ?? false
        if !focusInBrowserVC {
            //除了上面的uiResponder.resign，还要确保在点击more时browservc能变成FirstResponder，如果FirstResponder停留在WebView，在more菜单dismiss后webview会重新becomeFirstResponder,会导致非预期的滚动(比如在more中点击目录位置https://meego.feishu.cn/larksuite/issue/detail/3583783)
            DocsLogger.info("currentBrowserVC becomeFirstResponder")
            navigator?.currentBrowserVC?.becomeFirstResponder()
        }

        if SKDisplay.pad, ui?.hostView.isMyWindowRegularSize() ?? false {
            let browserVC = navigator?.currentBrowserVC as? BaseViewController
            browserVC?.showPopover(to: versionPanelVC, at: -1)
        } else {
            navigator?.presentViewController(versionPanelVC, animated: true, completion: nil)
        }
    }
}

extension ServiceStatistics where Self: UtilMoreService {
    func makeParameters(with action: String) -> [AnyHashable: Any]? {
        return ["file_id": encryptedToken,
                "module": module]
    }
}
extension UtilMoreService: ServiceStatistics {}

extension UtilMoreService {
    func handleApplyEditPermission(scene: InsideMoreDataProvider.ApplyEditScene) {
        switch scene {
        case .userPermission:
            applyEditUserPermission()
        case .auditExempt:
            applyEditAuditExempt()
        }
    }

    private func applyEditAuditExempt() {
        guard let docsInfo = hostDocsInfo,
              let hostController = currentTopMost else {
            spaceAssertionFailure("docsInfo or hostController found nil when apply edit exempt")
            return
        }
        guard let userResolver = model?.userResolver else {
            spaceAssertionFailure("userResolver found nil when apply edit exempt")
            return
        }
        var userName = ""
        var tenantName = ""
        if let currentUserInfo = User.current.info {
            userName = currentUserInfo.nameForDisplay()
            tenantName = (currentUserInfo.isToNewC ? BundleI18n.SKResource.Doc_Permission_PersonalAccount : currentUserInfo.tenantName) ?? ""
            if userName.isEmpty {
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                if let userInfo = dataCenterAPI?.userInfo(for: currentUserInfo.userID) {
                    userName = userInfo.nameForDisplay()
                    tenantName = (userInfo.isToNewC ? BundleI18n.SKResource.Doc_Permission_PersonalAccount : userInfo.tenantName) ?? ""
                }
            }
        }

        var currentUserName = ""
        if !userName.isEmpty {
            currentUserName = "\(tenantName)-\(userName)"
        }
        var config = SKApplyPanelConfig(userInfo: .empty,
                                        title: BundleI18n.SKResource.Doc_Resource_ApplyEditPerm,
                                        placeHolder: BundleI18n.SKResource.Doc_Facade_AddRemarks,
                                        actionName: BundleI18n.SKResource.Doc_Facade_ApplyFor) { _ in
            BundleI18n.SKResource.LarkCCM_CM_Sharing_AskForFurtherEditPerm_Desc(currentUserName)
        }
        config.actionHandler = { [weak self] controller, reason in
            self?.confirmApplyEditExempt(docsInfo: docsInfo, controller: controller, reason: reason)
        }
        let controller = SKApplyPanelController.createController(config: config)
        userResolver.navigator.present(controller, from: hostController, animated: true)
    }

    private func confirmApplyEditExempt(docsInfo: DocsInfo, controller: UIViewController, reason: String?) {
        let toastView: UIView = controller.view.window ?? controller.view
        UDToast.showLoading(with: BundleI18n.SKResource.LarkCCM_Perm_PermissionRequesting_Mobile,
                            on: toastView)
        AuditExemptAPI.requestExempt(objToken: docsInfo.objToken,
                                     objType: docsInfo.type,
                                     exemptType: .edit,
                                     reason: reason)
        .subscribe { [weak controller, weak toastView] in
            guard let controller, let toastView else { return }
            UDToast.removeToast(on: toastView)
            UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Permission_SendRequestSuccessfully, on: toastView)
            controller.dismiss(animated: true)
        } onError: { [weak toastView] error in
            DocsLogger.error("apply edit exempt failed", error: error)
            guard let toastView else { return }
            UDToast.removeToast(on: toastView)
            let exemptError = AuditExemptAPI.parse(error: error)
            switch exemptError {
            case .tooFrequent:
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Permission_SendRequestMaxCount, on: toastView)
            case .other:
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_SendRequestFail, on: toastView)
            }
        }
        .disposed(by: bag)
    }

    private func applyEditUserPermission() {
        guard let docsInfo = hostDocsInfo,
              let currentTopMost = currentTopMost else {
            return
        }
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = permissionManager.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        var ownerName = docsInfo.displayName
        if ownerName.count <= 0 {
            ownerName = docsInfo.ownerName ?? ""
        }
        let vc = AskOwnerForInviteCollaboratorViewController(ownerName: ownerName,
                                                             ownerID: docsInfo.ownerID ?? "",
                                                             permStatistics: permStatistics) { [weak self] (message) in
            guard let self = self else { return }
            self.requestFilePermission(message: message)
            permStatistics.reportPermissionReadWithoutEditClick(click: .apply,
                                                                target: .noneTargetView,
                                                                isAddNotes: message.count > 0)
        } cancelCallback: { [weak self] in
            guard let self = self else { return }
            self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: nil, isCancel: true)
        }
        if docsInfo.inherentType.supportLandscapeShow {
            vc.supportOrientations = currentTopMost.supportedInterfaceOrientations ?? .portrait
        }
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .overCurrentContext
        nav.update(style: .clear)
        let isInVCFollow = self.hostDocsInfo?.isInVideoConference ?? false
        // ms下横屏展示空间很小，排版样式需要重新布局，先转到竖屏
        if isInVCFollow {
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
                Navigator.shared.present(nav, from: currentTopMost, animated: false)
            }
        } else {
            Navigator.shared.present(nav, from: currentTopMost, animated: false)
        }
    }

    private func requestFilePermission(message: String?) {
        guard let docsInfo = hostDocsInfo else {
            return
        }
        var params = ["token": docsInfo.objToken,
                      "obj_type": docsInfo.type.rawValue,
                      "permission": 4] as [String: Any]
        if message?.isEmpty == false {
            params.updateValue(message ?? "", forKey: "message")
        }
        
        filePermissionRequest = DocsRequest(path: OpenAPI.APIPath.requestFilePermissionUrl, params: params)
        filePermissionRequest?.start(rawResult: { [weak self] (data, response, _) in
            guard let self = self else { return }
            guard let hostView = self.ui?.hostView else { return }

            if let response = response as? HTTPURLResponse, response.statusCode == 429 {
                UDToast.showFailure(with: BundleI18n.SKResource.Doc_Permission_SendRequestMaxCount, on: hostView)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
                return
            }
            guard let jsonData = data,
                  let json = jsonData.json else {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_SendRequestFail, on: hostView)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
                return
            }
            guard let code = json["code"].int else {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_SendRequestFail, on: hostView)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
                return
            }
            guard code == 0 else {
                let statistics = CollaboratorStatistics(docInfo: CollaboratorAnalyticsFileInfo(fileType: docsInfo.type.name,
                                                                         fileId: docsInfo.objToken),
                                                        module: docsInfo.type.name)
                let fromView = UIViewController.docs.topMost(of: self.navigator?.currentBrowserVC)?.view
                let manager = CollaboratorBlockStatusManager(requestType: .requestPermissionForBiz, fromView: fromView, statistics: statistics)
                manager.showRequestPermissionForBizFaliedToast(json, ownerName: docsInfo.displayName)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
                return
            }
            if let resultData = json["data"].dictionary,
                let result = resultData["ret"]?.bool, Bool(result) {
                UDToast.showSuccess(with: BundleI18n.SKResource.Doc_Permission_SendRequestSuccessfully, on: hostView)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 1, message: message)
                return
            } else {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_SendRequestFail, on: hostView)
                self.reportClickSendApplyEditPermission(docsInfo: docsInfo, status: 0, message: message)
            }
        })
    }

    func reportClickSendApplyEditPermission(docsInfo: DocsInfo, status: Int, message: String?, isCancel: Bool = false) {
        let note = (message?.isEmpty ?? true) ? "0" : "1"
        let params: [String: Any] = ["file_type": docsInfo.type.name,
                                      "file_id": docsInfo.encryptedObjToken,
                                      "action": isCancel ? "cancel" : "send",
                                      "permission": "edit",
                                      "note": note,
                                      "status": String(status)]
        DocsTracker.log(enumEvent: .clickSendApplyEditPermission, parameters: params)
    }
}

extension UtilMoreService {
    func showForcibleWarning() {
        guard let hostVC = navigator?.currentBrowserVC else { return }
        UDToast.showWarning(with: BundleI18n.SKResource.LarkCCM_Workspace_SecLeviI_Requird_Toast,
                            operationText: BundleI18n.SKResource.LarkCCM_Workspace_Security_Button_Set,
                            on: hostVC.view.window ?? hostVC.view) { [weak self] _ in
            self?.moreVCV2?.dismiss(animated: true, completion: {
                self?.showSensitivtyLabelSetting(self?.hostDocsInfo?.secLabel, fromToolBar: true)
            })
        }
    }
    
    func showSensitivtyLabelSetting(_ level: SecretLevel?, fromToolBar: Bool) {
        guard let level = level else {
            DocsLogger.warning("level nil")
            return
        }
        guard let docsInfo = hostDocsInfo,
              let topVC = navigator?.currentBrowserVC else {
            return
        }
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = permissionManager.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)

        var wikiToken: String?
        var token = docsInfo.objToken
        if let wikiInfo = docsInfo.wikiInfo {
            wikiToken = wikiInfo.wikiToken
            token = wikiInfo.objToken
        }
        let type = docsInfo.type.rawValue
        let viewFrom: PermissionStatistics.SecuritySettingViewFrom = fromToolBar ? .upperIcon : .moreMenu
        let viewModel = SecretLevelViewModel(level: level, wikiToken: wikiToken, token: token, type: type, permStatistic: permStatistics, viewFrom: viewFrom)
        let isIPad = SKDisplay.pad && topVC.isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretLevelViewController(viewModel: viewModel)
            viewController.delegate = self
            viewController.followAPIDelegate = self.model?.vcFollowDelegate
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: topVC)
        } else {
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
                let viewController = SecretLevelViewController(viewModel: viewModel)
                viewController.delegate = self
                viewController.followAPIDelegate = self.model?.vcFollowDelegate
                let nav = LkNavigationController(rootViewController: viewController)
                nav.modalPresentationStyle = .overFullScreen
                nav.transitioningDelegate = viewController.panelTransitioningDelegate
                LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
                    Navigator.shared.present(nav, from: topVC)
                }
            }
        }
        if fromToolBar {
            permStatistics.reportNavigationBarPermissionSecurityButtonClick()
        } else {
            permStatistics.reportMoreMenuPermissionSecurityButtonClick()
        }
    }
    
    // 即将删除的代码，转移到 SKBitable
    @available(*, deprecated, message: "This method is deprecated")
    func showBitableAdvancedPermissionsSettingVC(_ data: BitableBridgeData) {
        guard let docsInfo = hostDocsInfo,
              let hostView = ui?.hostView,
        let currentTopMost = currentTopMost else {
            return
        }
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = permissionManager.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      userPermission: userPermissions?.reportData,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)

        let isIPad = SKDisplay.pad && hostView.isMyWindowRegularSize()
        
        let vc = BitableAdPermSettingVC(
            docsInfo: docsInfo,
            bridgeData: data,
            delegate: self,
            needCloseBarItem: isIPad,
            permStatistics: permStatistics
        )
        vc.watermarkConfig.needAddWatermark = hostDocsInfo?.shouldShowWatermark ?? true
        if isIPad {
            let navVC = LkNavigationController(rootViewController: vc)
            navVC.modalPresentationStyle = .formSheet
            Navigator.shared.present(navVC, from: currentTopMost, animated: true)
        } else {
            Navigator.shared.push(vc, from: currentTopMost)
        }
        adPermVC = vc
    }

    func showPublicPermissionSettingVC() {
        guard let docsInfo = hostDocsInfo,
              let hostView = ui?.hostView,
        let currentTopMost = currentTopMost else {
            DocsLogger.error("docsInfo or hostView or currentTopMost nil")
            return
        }
        let publicPermissionMeta = permissionManager.getPublicPermissionMeta(token: docsInfo.objToken)
        let userPermissions = permissionManager.getUserPermissions(for: docsInfo.objToken)
        let ccmCommonParameters = CcmCommonParameters(fileId: docsInfo.encryptedObjToken,
                                                      fileType: docsInfo.type.name,
                                                      appForm: (docsInfo.isInVideoConference == true) ? "vc" : "none",
                                                      subFileType: docsInfo.fileType,
                                                      module: docsInfo.type.name,
                                                      userPermRole: userPermissions?.permRoleValue,
                                                      userPermissionRawValue: userPermissions?.rawValue,
                                                      publicPermission: publicPermissionMeta?.rawValue)
        let permStatistics = PermissionStatistics(ccmCommonParameters: ccmCommonParameters)
        let isIPad = SKDisplay.pad && hostView.isMyWindowRegularSize()
        let wikiV2SingleContainer = docsInfo.isFromWiki
        let spaceSingleContainer = (docsInfo.ownerType == 5)
        let fileModel = PublicPermissionFileModel(objToken: docsInfo.objToken,
                                                  wikiToken: docsInfo.wikiInfo?.wikiToken,
                                                  type: ShareDocsType(rawValue: docsInfo.type.rawValue),
                                                  fileType: docsInfo.fileType ?? "",
                                                  ownerID: docsInfo.ownerID ?? "",
                                                  tenantID: docsInfo.tenantID ?? "",
                                                  createTime: docsInfo.createTime ?? 0,
                                                  createDate: docsInfo.createDate ?? "",
                                                  createID: docsInfo.creatorID ?? "",
                                                  wikiV2SingleContainer: wikiV2SingleContainer,
                                                  wikiType: docsInfo.inherentType,
                                                  spaceSingleContainer: spaceSingleContainer)
        guard let url = try? HelpCenterURLGenerator.generateURL(article: .dlpBannerHelpCenter).absoluteString else {
            DocsLogger.error("failed to generate helper center URL when showPublicPermissionSettingVC from dlpBannerHelpCenter")
            return
        }
        var permissionVC: BaseViewController
        if ShareFeatureGating.newPermissionSettingEnable(type: docsInfo.type.rawValue) {
            permissionVC = PublicPermissionLynxController(token: docsInfo.objToken,
                                                          type: ShareDocsType(rawValue: docsInfo.type.rawValue),
                                                          isSpaceV2: spaceSingleContainer,
                                                          isWikiV2: wikiV2SingleContainer,
                                                          needCloseButton: isIPad,
                                                          fileModel: fileModel,
                                                          permStatistics: permStatistics,
                                                          dlpDialogUrl: url,
                                                          followAPIDelegate: model?.vcFollowDelegate)
            (permissionVC as? PublicPermissionLynxController)?.supportOrientations = currentTopMost.supportedInterfaceOrientations
            permissionVC.watermarkConfig.needAddWatermark = hostDocsInfo?.shouldShowWatermark ?? true
        } else {
            permissionVC = PublicPermissionViewController(fileModel: fileModel,
                                                          needCloseBarItem: isIPad,
                                                          permStatistics: permStatistics)
            permissionVC.watermarkConfig.needAddWatermark = hostDocsInfo?.shouldShowWatermark ?? true
        }
        if isIPad {
            let navVC = LkNavigationController(rootViewController: permissionVC)
            navVC.modalPresentationStyle = .formSheet
            Navigator.shared.present(navVC, from: currentTopMost, animated: true)
        } else {
            Navigator.shared.push(permissionVC, from: currentTopMost)
        }
    }
}

extension UtilMoreService: SecretLevelSelectDelegate, SecretModifyOriginalViewDelegate {
    private func showSecretModifyOriginalViewController(viewModel: SecretLevelViewModel) {
        guard let currentTopMost = currentTopMost else {
            DocsLogger.error("currentTopMost nil")
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        let viewModel: SecretModifyViewModel = SecretModifyViewModel(approvalType: viewModel.approvalType,
                                                                     originalLevel: viewModel.level,
                                                                     label: levelLabel,
                                                                     wikiToken: viewModel.wikiToken,
                                                                     token: viewModel.token,
                                                                     type: viewModel.type,
                                                                     approvalDef: viewModel.approvalDef,
                                                                     approvalList: viewModel.approvalList,
                                                                     permStatistic: viewModel.permStatistic,
                                                                     followAPIDelegate: model?.vcFollowDelegate)
        let isIPad = currentTopMost.isMyWindowRegularSize()
        if isIPad {
            let viewController = IpadSecretModifyOriginalViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .formSheet
            Navigator.shared.present(nav, from: currentTopMost)
        } else {
            let viewController = SecretModifyOriginalViewController(viewModel: viewModel)
            viewController.delegate = self
            let nav = LkNavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .overFullScreen
            nav.transitioningDelegate = viewController.panelTransitioningDelegate
            Navigator.shared.present(nav, from: currentTopMost)
        }
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
        let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
        dataCenterAPI?.updateSecurity(objToken: viewModel.wikiToken ?? viewModel.token, newSecurityName: viewModel.label.name)
    }
    func didSubmitApproval(_ view: UIViewController, viewModel: SecretModifyViewModel) {
        guard let currentTopMost = currentTopMost else {
            DocsLogger.error("currentTopMost nil")
            return
        }
        viewModel.reportCcmPermissionSecurityDemotionResultView(success: true)
        let dialog = SecretApprovalDialog.sendApprovaSuccessDialog { [weak self] in
            guard let self = self else { return }
            self.showApprovalCenter(viewModel: viewModel)
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "view_checking")
        } define: {
            viewModel.reportCcmPermissionSecurityDemotionResultClick(click: "known")
        }
        currentTopMost.present(dialog, animated: true, completion: nil)
    }
    func didClickCancel(_ view: UIViewController, viewModel: SecretModifyViewModel) {}
    func shouldApprovalAlert(_ view: UIViewController, viewModel: SecretLevelViewModel) {
        guard let currentTopMost = currentTopMost else {
            DocsLogger.error("currentTopMost nil")
            return
        }
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.info("select level label is nil")
            return
        }
        viewModel.reportCcmPermissionSecurityDemotionResubmitView()
        switch viewModel.approvalType {
        case .SelfRepeatedApproval:
            let dialog = SecretApprovalDialog.selfRepeatedApprovalDialog {
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "cancel")
            } define: { [weak self] in
                guard let self = self else { return }
                self.showSecretModifyOriginalViewController(viewModel: viewModel)
                viewModel.reportCcmPermissionSecurityDemotionResubmitClick(click: "confirm")
            }
            currentTopMost.present(dialog, animated: true, completion: nil)
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
            currentTopMost.present(dialog, animated: true, completion: nil)
        default: break
        }
    }
    private func showApprovalCenter(viewModel: SecretModifyViewModel) {
        guard let from = currentTopMost else {
            DocsLogger.error("currentTopMost nil")
            return
        }
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
        if let followAPIDelegate = viewModel.followAPIDelegate {
            followAPIDelegate.follow(onOperate: .vcOperation(value: .setFloatingWindow(getFromVCHandler: { from in
                guard let from else { return }
                Navigator.shared.push(url, from: from)
            })))
        } else {
            Navigator.shared.push(url, from: from)
        }
    }
    private func showApprovalList(viewModel: SecretLevelViewModel) {
        guard let currentTopMost = currentTopMost else {
            DocsLogger.error("currentTopMost nil")
            return
        }
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
        let vc = SecretLevelApprovalListViewController(viewModel: viewModel, needCloseBarItem: true, followAPIDelegate: model?.vcFollowDelegate)
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = currentTopMost.isMyWindowRegularSizeInPad ? .formSheet :.fullScreen
        Navigator.shared.present(nav, from: currentTopMost)
    }
    private func upgradeSecret(viewModel: SecretLevelViewModel) {
        guard let levelLabel = viewModel.selectedLevelLabel else {
            DocsLogger.error("leve label is nil")
            return
        }
        SecretLevel.updateSecLabel(token: viewModel.token, type: viewModel.type, id: levelLabel.id, reason: "")
            .subscribe { [self] in
                DocsLogger.info("update secret level success")
                let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                dataCenterAPI?.updateSecurity(objToken: viewModel.wikiToken ?? viewModel.token, newSecurityName: levelLabel.name)
                showToast(text: BundleI18n.SKResource.LarkCCM_Docs_SecurityLevel_SetasDefault_Toast, success: true)
            } onError: { [self] error in
                DocsLogger.error("update secret level fail", error: error)
                showToast(text: BundleI18n.SKResource.CreationMobile_SecureLabel_Change_Failed, success: false)
            }
            .disposed(by: bag)
    }

    private func showUpgradeAlert(viewModel: SecretLevelViewModel) {
        guard let currentTopMost = currentTopMost else {
            DocsLogger.error("currentTopMost nil")
            return
        }
        let dialog = SecretApprovalDialog.secretLevelUpgradeDialog { [weak self] in
            guard let self = self else { return }
            self.upgradeSecret(viewModel: viewModel)
        }
        currentTopMost.present(dialog, animated: true, completion: nil)
    }
}

// for wiki copy
extension UtilMoreService {
    // wiki创建副本
    func showWikiCopyFilePanel() {
        guard let handler = wikiMoreActionHandler else {
            spaceAssertionFailure("wiki action handler is nil")
            return
        }
        handler.showWikiCopyFilePanel()
    }
    // wiki创建快捷方式
    func wikiShortcut() {
        guard let handler = wikiMoreActionHandler else {
            spaceAssertionFailure("wiki action handler is nil")
            return
        }
        handler.wikiShortcut()
    }

    // wiki 移动
    func wikiMove() {
        guard let handler = wikiMoreActionHandler else {
            spaceAssertionFailure("wiki action handler is nil")
            return
        }
        handler.moveWiki()
    }

    // wiki删除
    func wikiDelete() {
        guard let handler = wikiMoreActionHandler else {
            spaceAssertionFailure("wiki action handler is nil")
            return
        }
        handler.wikiDelete()
    }
    // 浮窗操作
    func handleSuspendActionWith(addToSuspend: Bool) {
        guard var hostVC = navigator?.currentBrowserVC as? ViewControllerSuspendable,
              let docsInfo = self.hostDocsInfo else {
            DocsLogger.error("document suspend without hostViewController")
            return
        }
        if docsInfo.isFromWiki, let containerVC = hostVC.parent as? ViewControllerSuspendable {
            hostVC = containerVC
        }
        if docsInfo.isVersion, let containerVC = hostVC.parent as? ViewControllerSuspendable {
            hostVC = containerVC
        }
        if addToSuspend {
            SuspendManager.shared.addSuspend(viewController: hostVC, shouldClose: true)
        } else {
            SuspendManager.shared.removeSuspend(byId: hostVC.suspendID)
        }
    }
    
    // 工作台处理
    func handleWorkbenchActionWith(addToWorkbench: Bool) {
        let userId = model?.userResolver.docs.user?.basicInfo?.userID ?? User.current.basicInfo?.userID
        guard let docsInfo = hostDocsInfo, let uid = userId else {
            DocsLogger.error("workbench handleWorkbenchActionWith get params error docsInfo is nil: \(docsInfo == nil) uid is nil: \(userId == nil)")
            return
        }
        
        func trackEventWhenAdd(error: WorkbenchAddError) {
            var params = DocsParametersUtil.createCommonParams(by: docsInfo)
            switch error {
            case .addCommonBlockNotExist:
                params.updateValue("not_included_module", forKey: "sub_type")
            case .addExceedLimit:
                params.updateValue("reach_limit", forKey: "sub_type")
            }
            DocsTracker.newLog(enumEvent: .bitableAddToWorkplaceToastView, parameters: params)
        }
        
        let viewForHUD = ui?.hostView.window ?? UIView()
        if addToWorkbench {
            let querys = model?.hostBrowserInfo.loadedURL?.docs.queryParams
            let args = WorkbenchAddAgrs(token: docsInfo.token,
                                        uid: uid,
                                        name: docsInfo.name ?? "",
                                        viewId: querys?["view"],
                                        tableId: querys?["table"])
            workbenchManager.requestForAddToWorkbench(args: args) { result in
                switch result {
                case .success:
                    UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_ShareToWorkplace_AddedToWorkplace_Toast, on: viewForHUD)
                case .failure(let error):
                    if let addError = error as? WorkbenchAddError {
                        trackEventWhenAdd(error: addError)
                        UDToast.showFailure(with: addError.toast, on: viewForHUD)
                    } else {
                        UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: viewForHUD)
                    }
                }
            }
        } else {
            workbenchManager.requestForRemoveFormWorkbench(token: docsInfo.token, userId: uid) { result in
                switch result {
                case .success:
                    UDToast.showSuccess(with: BundleI18n.SKResource.Bitable_ShareToWorkplace_RemovedFromWorkplace_Toast, on: viewForHUD)
                case .failure(let error):
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_OperateFailed, on: viewForHUD)
                }
            }
        }
    }
}
