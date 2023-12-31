//
//  BTJSService.swift
//  DocsSDK
//
//  Created by maxiao on 2019/11/20.

import SKUIKit
import HandyJSON
import SwiftyJSON
import RxCocoa
import RxSwift
import RxRelay
import SKFoundation
import SKCommon
import SpaceInterface
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignDialog
import UniverseDesignProgressView
import UniverseDesignIcon
import SKResource
import EENavigator
import SKBrowser
import UIKit
import SKInfra
import UniverseDesignMenu
import LKCommonsLogging

///前端异步请求Model
struct BTAsyncRequestModel {
    var timer: Timer? //请求超时计时器
    var responseHandler: ((Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void)? //请求回调
}

struct BTAsyncRequestError: Error {    
    enum ErrorCode: Int {
        case requestTimeOut
        case requestFailed
        case dataFormatError
    }

    let code: ErrorCode
    let domain: String
    let description: String
    
    init(code: ErrorCode, domain: String, description: String) {
        self.code = code
        self.domain = domain
        self.description = description
    }
}

struct BTAsyncResponseModel: HandyJSON {
    var requestId: String = "" //异步请求ID
    var router: BTAsyncRequestRouter = .Unkonwn //异步请求router
    var result: Int = -1 //异步请求结果
    var errorResult: String = "" //异步请求错误信息
    var data: [String: Any] = [:] //异步请求数据
}

final class BTJSService: BaseJSService {
    
    static let logger = Logger.formsBaseLog(BTJSService.self, category: "BTJSService")
    
    var container: BTContainer? {
        get {
            return (registeredVC as? BitableBrowserViewController)?.container
        }
    }
    
    weak var jiraVC: BTJiraMenuController?
    
    var cardVC: BTController?
    
    var operationController: BTFieldOperationController?
    
    var editController: BTFieldEditController?
    
    var fieldEditViewModel: BTFieldEditViewModel?
    
    var permissionObj: BasePermissionObj?
    
    var editControllerTemporaryhidden: Bool = false
    
    var fieldEditCurrentMode: BTFieldEditMode = .edit
    
    weak var groupStatisticsVC: BTFieldGroupingAnimateViewController?
    
    // 记录popover模式下指向的位置
    var sourceRect: CGRect?
    
    // 记录当前user面板是否选择通知
    var notifiesEnable: Bool = true
    
    var uploadMediaHelper: BTUploadMediaHelper?
    
    var geoLocationHelper: BTFetchGeoLocationHelper?
    
    let bag = DisposeBag()
    
    var modifyFieldCallback = DocsJSCallBack("")
    
    var actionQueueManager = BTTaskQueueManager()

    //存放异步前端请求callback
    var asyncRequestHandler = ThreadSafeDictionary<String, BTAsyncRequestModel>()
    
    /// 筛选界面
    var filterPanelManager: BTFilterPanelManager?
    /// 排序界面
    var sortPanelManager: BTSortPanelManager?
    
    /// 布局界面（表格视图卡片样式）
    var tableLayoutManager: BTTableLayoutManager?
    
    /// 筛选排序布局合并
    var viewActionManager: BTViewActionManager?
    
    /// 点更多的Menu
    var moreMenu: UDMenu?
    
    //缓存基础数据
    var btCommonData: BTCommonData = BTCommonData()
    let filterOptionsSubject = PublishSubject<Bool>()
    var fieldEditBag = DisposeBag()
    
    /// 订阅状态缓存
    var recordsSubscribeInfoCache : [String: BTRecordSubscribeStatus] = [:]
    
    /// 是否允许编辑触发自动订阅缓存
    var recordsAutoSubscribeInfoCache : [String: BTRecordAutoSubStatus] = [:]
    
    // 画册面板预览附件缓存
    var previewAttachmentsModel = AttachmentsPreviewParams()
    
    var currentTopMost: UIViewController? {
        guard let currentBrowserVC = navigator?.currentBrowserVC else {
            return nil
        }
        return UIViewController.docs.topMost(of: currentBrowserVC)
    }
    
    var uiHostViewMaskToBounds: Bool?
    
    /// 底部众多工具栏容器
    lazy var toolbarsContainer: BTToolbarsContainerView = {
        let isNeedSafeArea = self.model?.vcFollowDelegate == nil
        let bottomSafeArea = isNeedSafeArea ? (self.navigator?.currentBrowserVC?.view.safeAreaInsets.bottom) ?? 0 : 0
        let container = BTToolbarsContainerView(bottomSafeArea: bottomSafeArea)
        container.fabContainerView.delegate = self
        container.toolbarView.delegate = self
        return container
    }()
    
    /// 表单提交结果页面
    lazy var formResultView: BitableFormResultView = {
        let view = BitableFormResultView()
        view.delegate = self
        return view
    }()
    
    var uiEventMonitor: BTUIEventMonitor?
    
    var fabUIEventMonitor: BTUIEventMonitor?
        
    lazy var maskView = UIView()
    
    var callBack = DocsJSCallBack("")
    
    var editorObserver: NSKeyValueObservation?
    
    var holdDataProvider: BTHoldDataProvider?
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        DocsLogger.btInfo("[LifeCycle] ---BTJSService init---")
        model.browserViewLifeCycleEvent.addObserver(self)
        if !UserScopeNoChangeFG.YY.bitableReferPermission {
            model.permissionConfig.hostPermissionEventNotifier.addObserver(self)
        }
        
            // 联系客服需要初始化一些数据(这个是异步的，不能等到联系的时候再调用这个)
            HostAppBridge.shared.call(LaunchCustomerService())
    }
    
    /// 通知前端下掉AI配置面板
    @objc
    func dismissAiForm() {
        maskView.removeFromSuperview()
        let args = BTHideAiConfigFormArgs(fieldId: self.editController?.viewModel.fieldEditModel.fieldId ?? "",
                                          tableId: self.editController?.viewModel.fieldEditModel.tableId ?? "")
        self.hideAiConfigFormAPI(args: args, completion: {})
    }
    
    func setUIAttribute(maskToBounds: Bool) {
        guard let ui = self.ui else {
            DocsLogger.btError("can not get UI from BTJSService")
            return
        }
        // 弹出一次AIPrompt 会先调用一次 maskToBounds 为true, 下掉时再调用一次 maskToBounds 为 false
        if maskToBounds {
            uiHostViewMaskToBounds = ui.hostView.layer.masksToBounds
            if !ui.hostView.layer.masksToBounds {
                ui.hostView.layer.masksToBounds = maskToBounds
            }
        } else {
            guard let uiHostViewMaskToBounds = uiHostViewMaskToBounds else {
                DocsLogger.btError("can not get uiViewMaskToBounds from BTJSService")
                return
            }
            ui.hostView.layer.masksToBounds = uiHostViewMaskToBounds
            self.uiHostViewMaskToBounds = nil
        }
    }
    
    deinit {
        self.stopUIEventMonitor()
        DocsLogger.btInfo("[LifeCycle] ---BTJSService deinit---")
    }
    
}

extension BTJSService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        var result: [DocsJSService] = [
                .updateTableInfo,
                .bitableChooseAttachment,
                .bitableCheckAttachmentValid,
                .bitablePreviewAttachment,
                .bitableDeleteAttachment,
                .bitableUploadAttachment,
                .bitableGetLocation,
                .bitableReverseGeocodeLocation,
                .bitableScanCode,
                .bitableChooseLocation,
                .bitableOpenLocation,
                .openFullScreen,
                .closeFullScreen,
                .formConfiguration,
                .safeArea,
                .jiraActionSheet,
                .updateViewMeta,
                .performCardAction,
                .exitDocument,
                .getPendingEdit,
                .startUploadAttachments,
                .openFieldEditPanel,
                .openStatPanel,
                .sendGroupData,
                .asyncJsResponse,
                .bitableFAB,
                .formShare,
                .formsShare,
                .formsUnmount,
                .chooseContact,
                .bitableShare,
                .openCoverFiles,
                .btEmitEvent,
                .performPanelsAction,
                .performNotifyAction,
                .contactService,
                .goToProfile,
                .openWebPage,
                .showLinkedDocx,
                .hideLinkedDocx,
                .searchDocument,
                .showAiOnBoarding,
                .setEditPanelVisibility,
                .showHeader,
                .baseMore,
                .viewSetting
        ]
        return result
    }
    
    // swiftlint:disable cyclomatic_complexity
    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.btInfo("[SYNC] bitable JSService \(serviceName)")
        switch DocsJSService(serviceName) {
        case .bitableChooseAttachment:
            chooseAttachment(params)
        case .bitableCheckAttachmentValid:
            checkAttachmentValid(params)
        case .bitablePreviewAttachment:
            previewAttachment(params)
        case .bitableDeleteAttachment:
            deleteAttachment(params)
        case .bitableUploadAttachment:
            uploadAttachment(params)
        case .bitableGetLocation:
            getLocation(params)
        case .bitableReverseGeocodeLocation:
            reverseGeocodeLocation(params)
        case .bitableScanCode:
            scanCode(params)
        case .bitableChooseLocation:
            chooseLocation(params)
        case .bitableOpenLocation:
            openLocation(params)
        case .openFullScreen:
            openFullScreen()
        case .closeFullScreen:
            closeFullScreen()
        case .formConfiguration:
            formConfiguration(params)
        case .safeArea:
            safeArea(params)
        case .updateTableInfo:
            handleUpdateTableInfo(params)
        case .jiraActionSheet:
            handleJiraActionSheet(params)
        case .updateViewMeta:
            updateViewMeta(params)
        case .performCardAction:
            handleCardAction(params)
        case .exitDocument:
            guard let bvc = self.registeredVC as? BrowserViewController else { return }
            closeBrowserVC(bvc)
            closeFormResultView()
        case .getPendingEdit:
            getPendingEdit(params: params)
        case .startUploadAttachments:
            startUploadAttachments(params: params)
        case .bitableFAB:
            handleBitableFABService(params)
        case .formShare:
            handleFormShareService(params)
        case .formsShare:
            formsShare(params)
        case .formsUnmount:
            formsUnmount(params)
        case .chooseContact:
            chooseContact(params)
        case .bitableShare:
            handleBitableShareService(params)
        case .openFieldEditPanel:
            handleFieldEditService(params)
        case .openStatPanel:
            handleStatService(params)
        case .sendGroupData:
            handleGroupRequestData(params)
        case .asyncJsResponse:
            handleAsyncJsResponse(params)
        case .openCoverFiles:
            handleOpenCoverFilesService(params)
        case .btEmitEvent:
            handleEmitEvent(params)
        case .performPanelsAction:
            handlePreformPanelsAction(params)
        case .performNotifyAction:
            handlePerformNotify(params)
        case .contactService:
            contactService(params)
        case .goToProfile:
            goToProfile(params)
        case .openWebPage:
            openWebPage(params)
        case .showLinkedDocx:
            showLinkedDocx(params)
        case .hideLinkedDocx:
            hideLinkedDocx()
        case .searchDocument:
            searchDocument(params: params)
        case .showAiOnBoarding:
            showAiOnBoarding(params)
        case .setEditPanelVisibility:
            setEditPanelVisibility(params)
        case .showHeader:
            showHeader(params)
        case .baseMore:
            handleMore(params)
        case .viewSetting:
            handlePreformPanelsAction(params)
        default:
            DocsLogger.btError("[SYNC] wrong \(serviceName)(\(params))")
        }
    }
    private func searchDocument(params: [String: Any]) {
        let searchText = params["searchText"] as? String
        let docTypes = params["docTypes"] as? [String]
        let callback = params["callback"] as? String
        let searchAPI = DocsContainer.shared.resolve(DocSearchAPI.self)
        searchAPI?.searchDoc(searchText, docTypes: docTypes, callback: { [weak self] (results, error) in
            DocsLogger.info("searchDoc callback")
            guard let self = self else {
                DocsLogger.warning("self released")
                return
            }
            guard let callback = callback else {
                DocsLogger.warning("callback is nil")
                return
            }
            guard let model = self.model else {
                DocsLogger.warning("self.model is nil")
                return
            }
            guard error == nil, let results = results else {
                DocsLogger.error("search failed", error: error)
                model.jsEngine.callFunction(
                    DocsJSCallBack(callback),
                    params: [
                        "error": "search failed"
                    ],
                    completion: nil
                )
                return
            }
            model.jsEngine.callFunction(
                DocsJSCallBack(callback),
                params: [
                    "results": results.map({ item in
                        var result: [String: Any] = [:]
                        if let token = item.id {
                            result["token"] = token
                        }
                        if let title = item.title {
                            result["title"] = title
                        }
                        return result
                    })
                ],
                completion: nil
            )
        })
    }
    
    func openFullScreen() {
        if let vc = navigator?.currentBrowserVC as? BrowserViewController {
            if !vc.forceFull {
                vc.forceFullScreen()
            }
        }
    }
    
    func closeFullScreen() {
        if let vc = navigator?.currentBrowserVC as? BrowserViewController {
            if vc.forceFull {
                vc.cancelForceFullScreen()
            }
        }
    }
    
    private func closeBrowserVC(_ bvc: BrowserViewController) {
        bvc.closeButtonItemAction()
    }
    
    private func getPendingEdit(params: [String: Any]) {
        guard let baseToken = params["baseToken"] as? String,
              let tableId = params["tableId"] as? String,
              let viewId = params["viewId"] as? String,
              let recordId = params["recordId"] as? String,
              let callback = params["callback"] as? String else {
            return
        }
        let pendingAttachments = uploadMediaHelper?.pendingAttachments(
            baseID: baseToken,
            tableID: tableId,
            viewID: viewId,
            recordID: recordId
        )
        var pendingEdits: [String: [String: Any]] = [:]
        pendingAttachments?.forEach { info in
            pendingEdits[info.location.fieldID] = ["pendingType": 0]
        }
        DocsLogger.btInfo("[SYNC] pendingEdits count: \(pendingEdits.count)")
        model?.jsEngine.callFunction(DocsJSCallBack(callback), params: pendingEdits, completion: nil)
    }
    
    private func startUploadAttachments(params: [String: Any]) {
        guard let baseToken = params["baseToken"] as? String,
              let tableId = params["tableId"] as? String,
              let viewId = params["viewId"] as? String,
              let recordId = params["recordId"] as? String,
              let callback = params["callback"] as? String else {
            return
        }
        guard let vc = self.cardVC else { return }
        
        let progressViewLayoutConfig = UDProgressViewLayoutConfig(linearSmallCornerRadius: 2,
                                           linearBigCornerRadius: 4,
                                           linearProgressDefaultHeight: 4,
                                           linearProgressRegularHeight: 12,
                                           linearHorizontalMargin: 12,
                                           linearVerticalMargin: 4,
                                           valueLabelWidth: 40,
                                           valueLabelHeight: 20,
                                           circleProgressWidth: 24,
                                           circleProgressLineWidth: 2,
                                           circularHorizontalMargin: 4,
                                           circularverticalMargin: 2)
                
        let progressBar = UDProgressView(
            config: UDProgressViewUIConfig(type: .circular, barMetrics: .default, layoutDirection: .horizontal, showValue: false),
            layoutConfig: progressViewLayoutConfig)

        let dialog = UDDialog()
        let label = UILabel()
        let contentView = dialogContentView(progressBar: progressBar, label: label)
        dialog.setTitle(text: BundleI18n.SKResource.Bitable_Attachment_UploadPopupTitle)
        dialog.setContent(view: contentView)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel, dismissCheck: { [weak self] () -> Bool in
            self?.uploadMediaHelper?.cancelUploadWaitingAttachments()
            self?.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: ["code": 1], completion: nil)
            return true
        })
        Navigator.shared.present(dialog, from: vc)
        let tableInfo = BTUploadTableInfo(tableID: tableId, viewID: viewId, recordID: recordId, baseID: baseToken)
        uploadMediaHelper?.uploadWaitingAttachments(with: tableInfo,
                                                    progress: { completedByte, totalByte in
                DocsLogger.btInfo("[SYNC] uploadWaitingAttachments update progress")
                /// 上传总字节数为0，不做处理直接返回
                guard totalByte > 0 else {
                    DocsLogger.btError("uploadAttachmentsByte is 0")
                    return
                }
                /// 总上传进度小于1%，直接置为 1%
                let totalProgress = min(max(1, completedByte * 100 / totalByte), 100)
                progressBar.setProgress(CGFloat(totalProgress) / 100, animated: false)
                label.text = "\(totalProgress)%"
            }, completion: { [weak self, weak dialog] success in
                guard let `self` = self else { return }
                dialog?.dismiss(animated: true, completion: nil)
                var callBackParams: [String: Any] = [:]
                DocsLogger.btInfo("[SYNC] all attachment upload isSuccess: \(success)")
                callBackParams["code"] = success ? 0 : 1
                self.model?.jsEngine.callFunction(DocsJSCallBack(callback), params: callBackParams, completion: nil)
            })
        
    }

    private func dialogContentView(progressBar: UDProgressView, label: UILabel) -> UIView {
        let contentView = UIView()
        let centerLayoutGuide = UILayoutGuide()
        label.textColor = UDColor.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(label)

        contentView.addSubview(progressBar)
        contentView.addLayoutGuide(centerLayoutGuide)
        centerLayoutGuide.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.bottom.equalToSuperview().inset(6)
        }
        progressBar.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(20)
            make.width.height.equalTo(18)
        }
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(-20)
        }
        return contentView
    }
    
    private func handleAsyncJsResponse(_ params: [String: Any]) {
        guard let responseModel = BTAsyncResponseModel.deserialize(from: params) else {
            DocsLogger.btError("[BTAsyncRequest] FE params deserialize failed")
            return
        }
          
        DocsLogger.btInfo("[BTAsyncRequest] router: \(responseModel.router)")
        guard var requestModel = asyncRequestHandler.value(ofKey: responseModel.requestId) else {
            DocsLogger.btError("[BTAsyncRequest] no handler to dispose async response requestId:\(responseModel.requestId)")
            return
        }
        //请求完成后移除
        asyncRequestHandler.removeValue(forKey: responseModel.requestId)

        requestModel.timer?.invalidate()
        requestModel.timer = nil
        requestModel.responseHandler?(.success(responseModel))
    }

    private func handleEmitEvent(_ params: [String: Any]) {
        DocsLogger.btInfo("[EmitEvent] reveive event params:\(params.jsonString?.encryptToShort ?? "")")
        guard let event = params["event"] as? String,
              let btEvent = BTEmitEvent(rawValue: event) else {
            DocsLogger.btError("[EmitEvent] not define")
            return
        }

        guard let data = params["data"] as? [String: Any],
              let router = data["router"] as? String,
              let btRouter = BTAsyncRequestRouter(rawValue: router) else {
            DocsLogger.btError("[EmitEvent] data is nil")
            return
        }
        
        DocsLogger.btInfo("[EmitEvent] handle event:\(btEvent) router:\(btRouter)")
        
        switch btRouter {
        case .getCardList, .getLinkCardList, .getRecordsData:
            cardVC?.handleEmitEvent(event: btEvent, router: btRouter)
        default:
            break
        }
    }
    
    /// 前端将一些通用的信息传递过来（使客户端无需读取 meta 或 data 即可使用）
    private func handleUpdateTableInfo(_ param: [AnyHashable: Any]) {
        DocsLogger.info("handleUpdateTableInfo invoke")
        if let json = param["syncData"] as? [String: Any] {
            do {
                let tableData = try CodableUtility.decode(BTGlobalTableInfo.TableData.self, withJSONObject: json)
                DocsLogger.info("handleUpdateTableInfo syncData update, table:\(tableData.tableId), sync: \(tableData.isSyncTable)")
                BTGlobalTableInfo.updateCurrentTableInfo(tableData)
            } catch {
                DocsLogger.error("handleUpdateTableInfo sync decode error: \(error)")
            }
        }
        if let json = param["currentView"] as? [String: Any] {
            do {
                let viewData = try CodableUtility.decode(BTGlobalTableInfo.ViewData.self, withJSONObject: json)
                DocsLogger.info("handleUpdateTableInfo viewData update, viewId:\(viewData.viewId)")
                BTGlobalTableInfo.updateCurrentViewInfo(viewData)
            } catch {
                DocsLogger.error("handleUpdateTableInfo viewData decode error: \(error)")
            }
        }
    }

    func openWebPage(_ params: [String: Any]) {
        if let flag = params["flag"] as? String {
            if let hostVC = navigator?.currentBrowserVC {
                let urlString = flag == "moreGantee" ? BundleI18n.SKResource.Bitable_Billing_GanttView_LearnMoreHelpCenter_Feishu : BundleI18n.SKResource.Bitable_Billing_RecordLimit_LearnMoreHelpCenter_Feishu
                if var urlComponents = URLComponents(string: urlString) {
                    if let domain = DomainConfig.helperCenterDomain {
                        urlComponents.host = domain
                    } else {
                        DocsLogger.error("openWebPage error, get bitable_learn_more_domain error")
                    }
                    if let url = urlComponents.url ?? URL(string: urlString) {
                        Navigator.shared.open(url, from: hostVC)
                    } else {
                        DocsLogger.error("openWebPage error, urlComponents.url or urlString init is nil")
                    }
                } else {
                    DocsLogger.error("openWebPage error, URLComponents init error url: \(urlString)")
                }
            } else {
                DocsLogger.error("openWebPage error, navigator?.currentBrowserVC is nil")
            }
        } else {
            DocsLogger.error("openWebPage error, flag is nil")
        }
    }
    
    
    func showLinkedDocx(_ params: [String: Any]) {
        guard let plugin = container?.getOrCreatePlugin(BTContainerLinkedDocxPlugin.self) else {
            DocsLogger.error("[BTJSService] showLinkedDocx can't find BTContainerLinkedDocxPlugin")
            return
        }
        plugin.showLinkedDocx(params)
    }
    
    func hideLinkedDocx() {
        guard let plugin = container?.getOrCreatePlugin(BTContainerLinkedDocxPlugin.self) else {
            DocsLogger.error("[BTJSService] showLinkedDocx can't find BTContainerLinkedDocxPlugin")
            return
        }
        plugin.hideLinkedDocx()
    }
    
    private func isShowOnboarding(_ parentVC: UIViewController) -> Bool {
        return OnboardingManager.shared.getCurrentTopOnboardingID(in: parentVC) == .bitableExposeCatalogIntro
    }

    private func showHeader(_ params: [String: Any]) {
        let model = BTShowHeaderModel.deserialized(with: params)
        guard let bvc = self.registeredVC as? BitableBrowserViewController else {
            DocsLogger.btError("[showHeader] registeredVC is not BitableBrowserViewController")
            return
        }
        DocsLogger.btInfo("[showHeader] JSService show header \(params)")
        bvc.switchBaseHeader(model)
    }
}

extension BTJSService: BrowserViewLifeCycleEvent {
    func browserDidDismiss() {
        if let vc = self.registeredVC as? BitableBrowserViewController,
            let traceId = vc.fileConfig?.getOpenFileTraceId() {
            BTOpenFileReportMonitor.reportOpenCancel(
                traceId: traceId,
                extra: [BTStatisticConstant.reason: "browserDidDismiss"]
            )
        }
    }

    /// 直接退出文档时需要做处理。
    func browserWillClear() {
        cardDidClose()
        toolbarsContainer.removeFromSuperview()
        stopUIEventMonitor()
        filterPanelManager = nil
        sortPanelManager = nil
        tableLayoutManager = nil
        self.removeMaskViewForAiForm()
    }
    
    func browserWillAppear() {
        closeBaseCardIfNeed()
    }
    
    func closeBaseCardIfNeed() {
        guard !UserScopeNoChangeFG.ZJ.btItemViewIPadFixDisable else {
            return
        }
        
        let vc = UIViewController.docs.topMost(of: self.registeredVC) ?? self.registeredVC
        if let cardVC = vc as? BTController,
           cardVC.viewModel.mode.isNormalShowRecord,
           cardVC.didAppear,
           cardVC.delegate?.cardGetBrowserController() != self.registeredVC {
            DocsLogger.btError("[BTJSService] not card link vc close card")
            cardVC.dismiss(animated: false)
            cardVC.afterRealDismissal()
        }
    }
    
    func browserWillRerender() {
        cardVC?.closeAllCards()
    }

    /// 文档 terminate 时需要进行的操作
    func browserTerminate() {
        if cardVC?.viewModel.mode == .addRecord {
            container?.addRecordPlugin.closeAddRecord()
            return
        }
        cardVC?.needCloseAllCardsWhenAppear = true
        if cardVC?.willDisAppear == false {
            cardVC?.closeAllCards()
        }
        cancelOrDeleteAllUploadTasksIfNeeded()
        
    }
    
    /// 当browserView的分屏发生变化时，会自动调用这个函数，用来做 transitionView 中卡片的重新布局
    func browserDidSplitModeChange() {
        // 修复分享记录中卡片宽度没有达到全屏的bug
        if !UserScopeNoChangeFG.QYK.btSwitchAttachInMSFixDisable {
            cardVC?.reloadCardsView()
        }
        
        // 卡片打开后不可以再点击非卡片区域，所以不会再有browserView的分屏变化
        guard UserScopeNoChangeFG.QYK.btSideCardCloseFixDisable else { return }
        
        guard UserScopeNoChangeFG.ZJ.btCardReform, let browserVC = self.navigator?.currentBrowserVC else { return }
        if SKDisplay.pad, !(cardVC?.viewModel.mode.isForm ?? true), BTNavigator.isReularSize(browserVC) {
            if cardVC?.nextCardPresentMode == .card, cardVC?.currentCardPresentMode == .card {
                cardVC?.cardRelayoutForSplitModeChange()
            } else if cardVC?.nextCardPresentMode != cardVC?.currentCardPresentMode {
                cardCloseAll(animated: true)
            } else {
                
            }
        }
    }
    
    /// 当应用的发生转屏和屏幕大小变化时，除了分享记录的，关闭掉所有的card
    func browserWillTransition(from: CGSize, to: CGSize) {
        // 这个函数下个版本会删除，请不要再添加内容
        guard UserScopeNoChangeFG.QYK.btSideCardCloseFixDisable else { return }
        guard UserScopeNoChangeFG.ZJ.btCardReform else { return }
        if self.cardVC?.viewModel.mode.isIndRecord ?? false { return }
        if cardVC != nil, SKDisplay.pad, !(cardVC?.viewModel.mode.isForm ?? true) {
            self.cardCloseAll(animated: false)
        }
    }
    
    // 通过转屏监听重新布局 maskView
    func browserDidTransition(from: CGSize, to: CGSize) {
        if self.maskView.superview != nil {
            self.removeMaskViewForAiForm()
            self.addMaskViewForAiForm(animate: false)
        }
    }
    
    func browserTraitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // Dark Mode 和 Light Mode 切换时，下掉AI的 maskView
        self.removeMaskViewForAiForm()
    }
}

extension BTJSService: BaseContextService {
    
}
