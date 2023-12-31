//
//  BTJSService+Card.swift
//  DocsSDK
//
//  Created by linxin on 2020/3/20.
// swiftlint:disable all
import UIKit
import HandyJSON
import SwiftyJSON
import SKCommon
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import RxSwift
import EENavigator
import UniverseDesignToast
import UniverseDesignColor
import LarkUIKit
import SKInfra
import SpaceInterface

extension BTJSService {
    func updateViewMeta(_ param: [String: Any]) {
        guard let vc = cardVC else {
            DocsLogger.error("updateViewMeta error, cardvc is nil")
            return
        }
    }
    
    // 判断当前action是否需要处理
    func shouldHandleCardAction(action: BTActionFromJS) -> Bool {
        // 如果现在已经在显示 card，则 handle action
        if let cardVC = cardVC, cardVC.willAppear {
            return true
        }
        
        // 当卡片关闭，或者没有卡片时
        DocsLogger.btInfo("[SYNC] shouldHandleCardAction card is nil or close")
        return !BTUtil.notNeedHandleActionWhenCardClose.contains(action)
    }
    
    func handleCardAction(_ param: [String: Any]) {
        BTActionParamsModel.desrializedGlobalAsync(with: param, callbackInMainQueue: true) { [weak self] model in
            guard let actionParams = model, let self = self else {
                DocsLogger.btInfo("[SYNC] invalid actionParams \(param)")
                return
            }
            let logParams: [String: Any] = [
                "allParams": actionParams.data.logString.encryptToShort ?? "",
                "currentTaskAction": (self.actionQueueManager.currentActionTask as? BTCardActionTask)?.actionParams.action ?? ""
            ]
            DocsLogger.btInfo("[SYNC] received card action: \(actionParams.action), params: \(logParams)")
            
            if (!UserScopeNoChangeFG.ZJ.btCardUpdateFieldActionFixDisable && !self.shouldHandleCardAction(action: actionParams.action)) {
                DocsLogger.btError("[SYNC] card action: \(actionParams.action) not need handle")
                return
            }
            
            var cardAction = BTCardActionTask()
            cardAction.actionParams = actionParams
            let permissionObj: BasePermissionObj?
            if !UserScopeNoChangeFG.ZYS.recordCopySupportRevert, cardAction.actionParams.action == .showIndRecord || cardAction.actionParams.action == .showAddRecord {
                permissionObj = BasePermissionObj(objToken: actionParams.data.baseId, objType: .bitable)
            } else {
                permissionObj = BasePermissionObj.parse(param)
            }
            let baseContext = BaseContextImpl(baseToken: actionParams.data.baseId, service: self, permissionObj: permissionObj, from: "card")
            if actionParams.action == .closeCard {
                // 关闭卡片就不要等了，直接关闭(否则队列可能等很久20s才执行)
                self.handleCardActionTask(cardActionTask: cardAction, baseContext: baseContext)
                return
            }
            self.actionQueueManager.taskExecuteBlock = { [weak self] task in
                guard let actionTask = task as? BTCardActionTask else {
                    return
                }
                self?.handleCardActionTask(cardActionTask: actionTask, baseContext: baseContext)
            }
            self.actionQueueManager.addTask(task: cardAction)
        }
    }

    private func updateMediaHelper(cardActionTask: BTCardActionTask) {
        let baseId = cardActionTask.actionParams.data.baseId
        let callback = cardActionTask.actionParams.callback
        let tableId = cardActionTask.actionParams.data.tableId
        if uploadMediaHelper == nil {
            uploadMediaHelper = BTUploadMediaHelper(fileToken: baseId,
                                                    tableID: tableId,
                                                    jsCallBack: callback,
                                                    delegate: self)
        } else {
            uploadMediaHelper?.updateUploadingAttachmentsWhenNoNet()
            /// 这里有些 cardAction 的参数可能会为空
            if cardActionTask.actionParams.action != .formFieldsValidate {
                if !tableId.isEmpty {
                    uploadMediaHelper?.tableID = tableId
                }
                if !baseId.isEmpty {
                    uploadMediaHelper?.fileToken = baseId
                }
                if !callback.isEmpty {
                    uploadMediaHelper?.jsCallBack = callback
                }
            }
        }
    }

    // ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
    // ==========================在下面函数新增代码，请求务必阅读这里的注释==============================
    // ⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️⚠️
    // 请保证所有的路径都最终调用 cardActionTask.completedBlock() 一次，否则卡片事件队列将阻塞不响应事件
    private func handleCardActionTask(cardActionTask: BTCardActionTask, baseContext: BaseContext) {
        
        updateMediaHelper(cardActionTask: cardActionTask)
        
        if geoLocationHelper == nil {
            geoLocationHelper = BTFetchGeoLocationHelper(actionParams: cardActionTask.actionParams, delegate: self)
        } else {
            if cardActionTask.actionParams.action != .formFieldsValidate {
                geoLocationHelper?.actionParams = cardActionTask.actionParams
            }
        }

        switch cardActionTask.actionParams.action {
        case .showCard, .switchCard:
            // 不管 cardVC 是否已经展示，收到 showCard 消息必须先关闭表单结果页面，避免切换表单视图页面没有关闭
            closeFormResultView()
            // 记录新建模式跳转记录详情的场景下，前端部分计算有一点点延迟，这里如果立即去刷新显示，可能会出现一些数据闪烁的现象，因此，这里进行一个短暂的等待，可以缓解闪烁
            let needWaitSomeTime = cardVC?.viewModel.mode == .submit && cardActionTask.actionParams.action == .showCard && cardActionTask.actionParams.data.preMockRecordId?.isEmpty == false
            if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable, needWaitSomeTime {
                cardVC?.submitView.update(iconType: .done)  // 显示一个提交成功的动画
                let delayDuration = 0.8
                DispatchQueue.main.asyncAfter(deadline: .now() + delayDuration) { [weak self] in
                    self?.handleShowCard(cardActionTask: cardActionTask, baseContext: baseContext)
                }
            } else {
                handleShowCard(cardActionTask: cardActionTask, baseContext: baseContext)
            }
        case .showManualSubmitCard:
            guard responseToCard(actionTask: cardActionTask) == false else {
                handleSubmitModeReport()
                return
            }
            DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
            showCard(actionTask: cardActionTask, baseContext: baseContext, viewMode: .submit)
            handleSubmitModeReport()
        case .submitResult:
            if responseToCard(actionTask: cardActionTask) {
                DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
                if cardVC?.viewModel.mode.isForm == true {
                    showFormResult(cardActionTask: cardActionTask)
                } else {
                    handleSubmitResult(cardActionTask: cardActionTask)
                }
                cardActionTask.completedBlock()
            } else {
                DocsLogger.btInfo("[SYNC] first handling \(cardActionTask.actionParams.action)")
                showCard(actionTask: cardActionTask, baseContext: baseContext)
            }
        case .closeCard:
            closeFormResultView()
            guard responseToCard(actionTask: cardActionTask) == false else { return }
            DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
            cardActionTask.completedBlock()
        case .bitableIsReady:
            guard responseToCard(actionTask: cardActionTask) == false else { return }
            DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
            bitableReady(actionTask: cardActionTask, viewMode: nil)
            if !UserScopeNoChangeFG.YY.bitableCardQueueBlockedFixDisable {
                cardActionTask.completedBlock()
            }
        case .setCardHidden:
            guard responseToCard(actionTask: cardActionTask) == false else { return }
            DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
            if !UserScopeNoChangeFG.YY.bitableCardQueueBlockedFixDisable {
                cardActionTask.completedBlock()
            }
        case .setCardVisible:
            guard responseToCard(actionTask: cardActionTask) == false else { return }
            DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
            if !UserScopeNoChangeFG.YY.bitableCardQueueBlockedFixDisable {
                cardActionTask.completedBlock()
            }
        case .showIndRecord:
            guard responseToCard(actionTask: cardActionTask) == false else { return }
            DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
            if !UserScopeNoChangeFG.ZYS.recordCopySupportRevert {
                baseContext.manualUpdatePermissionData()
            }
            clearAttachFileWhenOpenCardAsFollower()
            showCard(actionTask: cardActionTask, baseContext: baseContext, viewMode: .indRecord)
            let service = (self.navigator?.currentBrowserVC as? BitableBrowserViewController)?.container.getPlugin(BTContainerLoadingPlugin.self)
            service?.hideAllSkeleton(from: "showIndRecord")
        case .showAddRecord:
            if !UserScopeNoChangeFG.ZYS.recordCopySupportRevert {
                baseContext.manualUpdatePermissionData()
            }
            showAddRecordCard(actionTask: cardActionTask, baseContext: baseContext)
            let service = (self.navigator?.currentBrowserVC as? BitableBrowserViewController)?.container.getPlugin(BTContainerLoadingPlugin.self)
            service?.hideAllSkeleton(from: "showAddRecord")
        case .addRecordResult:
            addRecordResult(actionTask: cardActionTask, baseContext: baseContext)
            cardActionTask.completedBlock()
        default:
            guard responseToCard(actionTask: cardActionTask) == false else { return }
            DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
            cardActionTask.completedBlock()
        }
    }
    
    func handlePerformNotify(_ params: [String: Any]) {
        DocsLogger.btInfo("[SYNC] handling performNotifyAction")
        guard let actionStr = params["action"] as? String,
        let action = BTPerformNotifyAction(rawValue: actionStr) else {
            DocsLogger.btInfo("[SYNC] invalid perfrom aciton")
            return
        }
        switch action {
        case .tableSwitched:
            handleSwitchTable(params)
        }

    }
    
    func handleShowCard(cardActionTask: BTCardActionTask, baseContext: BaseContext) {
        guard responseToCard(actionTask: cardActionTask) == false else { return }
        DocsLogger.btInfo("[SYNC] handling \(cardActionTask.actionParams.action)")
        clearAttachFileWhenOpenCardAsFollower()
        showCard(actionTask: cardActionTask, baseContext: baseContext)
    }
    
    private func handleSwitchTable(_ params: [String: Any]) {
        DocsLogger.btInfo("[SYNC] handling performNotifyAction tableSwitched")
        guard let baseID = params["baseId"] as? String, let tableID = params["tableId"] as? String else {
            DocsLogger.btInfo("[SYNC] invalid params")
            return
        }
        uploadMediaHelper?.switchTable(with: baseID, tableID: tableID)
    }
    private func responseToCard(actionTask: BTCardActionTask) -> Bool {
        // 如果现在已经在显示 card，则 respond to action
        if let cardVC = cardVC, cardVC.willAppear {
            DocsLogger.btInfo("[SYNC] cardVC is showing, going up the responder chain")
            cardVC.respond(to: actionTask)
            return true
        }
        return false
    }
    
    private func bitableReady(actionTask: BTCardActionTask, viewMode: BTViewMode? = nil) {
        // 不太可能走到，在vc未出现之前，走到这里没意义，出现之后走viewmodel的respond
        cardVC?.viewModel.bitableIsReady = true
    }

    private func showCard(actionTask: BTCardActionTask, baseContext: BaseContext, viewMode: BTViewMode? = nil) {
        closeFeed()
        closeFormResultView()
        let size: CGSize
        let sizeValid: Bool
        if let window = ui?.editorView.window {
            size = window.bounds.size
            sizeValid = true
        } else {
            size = ui?.editorView.bounds.size ?? SKDisplay.activeWindowBounds.size
            DocsLogger.btError("[UI] create bt-vc use unexpected init size: \(size)")
            sizeValid = false
        }
        let event = DocsTracker.EventType.bitableCapturePreventViewInitSize
        DocsTracker.newLog(enumEvent: event, parameters: ["width": size.width,
                                                          "height": size.height,
                                                          "is_valid": sizeValid.description])
        
        var accurateActionTask = actionTask
        if UserScopeNoChangeFG.PXR.bitableRecordFieldHLEnable, viewMode == .indRecord, accurateActionTask.actionParams.data.fieldId.isEmpty, let currentUrl = self.model?.hostBrowserInfo.currentURL, recordEnableSubscribe(baseContext: baseContext, viewMode: viewMode) {
            let parameger = currentUrl.queryParameters
            if let field = (parameger["field"]) {
                accurateActionTask.actionParams.data.updateField(field: field, highLightType: .temporary)
            }
        }
        let btvc: BTController
        if ViewCapturePreventer.isFeatureEnable {
            btvc = BTSecureController(
                actionTask: accurateActionTask,
                viewMode: viewMode,
                delegate: self,
                uploader: uploadMediaHelper,
                geoFetcher: geoLocationHelper,
                baseContext: baseContext,
                dataService: self,
                initialSize: size
            )
        } else {
            btvc = BTController(
                actionTask: accurateActionTask,
                viewMode: viewMode,
                delegate: self,
                uploader: uploadMediaHelper,
                geoFetcher: geoLocationHelper,
                baseContext: baseContext,
                dataService: self
            )
        }
        btvc.isRootController = true
        if !UserScopeNoChangeFG.YY.bitableReferPermission {
            btvc.allowCapture = hasCopyPermissionDeprecated
        }
        if !UserScopeNoChangeFG.YY.bitableRecordShareCatalogueDisable {
            btvc.viewModel.updateBaseName(baseName: accurateActionTask.actionParams.data.baseName)
        }
        btvc.viewModel.updateActionParams(accurateActionTask.actionParams)
        btvc.viewModel.updateCurrentRecordID(accurateActionTask.actionParams.data.recordId)
        btvc.viewModel.updateCurrentRecordGroupValue(accurateActionTask.actionParams.data.groupValue)
        cardVC = btvc
        //增加水印
        if !UserScopeNoChangeFG.YY.bitableReferPermission {
            btvc.watermarkConfig.needAddWatermark = model?.hostBrowserInfo.docsInfo?.shouldShowWatermark ?? true
        }
        if let bvc = self.registeredVC as? BrowserViewController {
            bvc.orientationDirector?.needSetPortraitWhenDismiss = false
        }
        if viewMode ==  .indRecord, 
            UserScopeNoChangeFG.YY.bitablePerfOpenInRecordShare,
            let meta = actionTask.actionParams.data.tableMeta,
            let value = actionTask.actionParams.data.recordsData {
            // 记录分享支持数据直出
            cardVC?.viewModel.updateRecord(meta: meta, value: value)
            cardVC?.viewModel.notifyTableInit()
        } else {
            cardVC?.viewModel.kickoff()
        }

        handleOpenRecordReport(viewMode: viewMode, btvc: btvc, actionTask: actionTask)
        if UserScopeNoChangeFG.XM.cardOpenLoadingEnable {
            // 非表单先出Controller，走额外处理
            let isFormCard = (viewMode?.isForm ?? false) || actionTask.actionParams.data.viewType == .form
            showCardRightNow(isFormCard: isFormCard)
        }
    }
    
    private func showAddRecordCard(actionTask: BTCardActionTask, baseContext: BaseContext) {
        guard let meta = actionTask.actionParams.data.tableMeta,
              let value = actionTask.actionParams.data.recordsData else {
            actionTask.completedBlock()
            return
        }
        
        if holdDataProvider == nil {
            // 对于 Base 外新建记录场景，需要构造本地提交数据管理器
            holdDataProvider = BTHoldDataProvider()
        }
        
        if let cardVC = cardVC {
            // 已加载过，直接更新数据
            cardVC.hasUnSubmitCellValue = false
            cardVC.viewModel.updateCurrentRecordID(actionTask.actionParams.data.recordId)
            cardVC.viewModel.updateAddRecord(meta: meta, value: value, baseName: actionTask.actionParams.data.baseName)
            cardVC.viewModel.notifyModelUpdate()
            cardVC.submitView.update(iconType: .initial)
            actionTask.completedBlock()
            return
        }
        // 防截屏埋点
        let size: CGSize
        let sizeValid: Bool
        if let window = ui?.editorView.window {
            size = window.bounds.size
            sizeValid = true
        } else {
            size = ui?.editorView.bounds.size ?? SKDisplay.activeWindowBounds.size
            DocsLogger.btError("[UI] create bt-vc use unexpected init size: \(size)")
            sizeValid = false
        }
        let event = DocsTracker.EventType.bitableCapturePreventViewInitSize
        DocsTracker.newLog(enumEvent: event, parameters: ["width": size.width,
                                                          "height": size.height,
                                                          "is_valid": sizeValid.description])
        let viewMode = BTViewMode.addRecord
        var accurateActionTask = actionTask
        let btvc: BTController
        if ViewCapturePreventer.isFeatureEnable {
            btvc = BTSecureController(
                actionTask: accurateActionTask,
                viewMode: viewMode,
                delegate: self,
                uploader: uploadMediaHelper,
                geoFetcher: geoLocationHelper,
                baseContext: baseContext,
                dataService: self,
                initialSize: size
            )
        } else {
            btvc = BTController(
                actionTask: accurateActionTask,
                viewMode: viewMode,
                delegate: self,
                uploader: uploadMediaHelper,
                geoFetcher: geoLocationHelper,
                baseContext: baseContext,
                dataService: self
            )
        }
        btvc.isRootController = true
        if !UserScopeNoChangeFG.YY.bitableReferPermission {
            btvc.allowCapture = hasCopyPermissionDeprecated
        }
        btvc.viewModel.updateActionParams(accurateActionTask.actionParams)
        btvc.viewModel.updateCurrentRecordID(accurateActionTask.actionParams.data.recordId)
        btvc.viewModel.updateCurrentRecordGroupValue(accurateActionTask.actionParams.data.groupValue)
        cardVC = btvc
        //增加水印
        if !UserScopeNoChangeFG.YY.bitableReferPermission {
            btvc.watermarkConfig.needAddWatermark = model?.hostBrowserInfo.docsInfo?.shouldShowWatermark ?? true
        }
        if let bvc = self.registeredVC as? BrowserViewController {
            bvc.orientationDirector?.needSetPortraitWhenDismiss = false
        }
        // TODO: 这里两个数据直接填入
        cardVC?.viewModel.updateAddRecord(meta: meta, value: value, baseName: actionTask.actionParams.data.baseName)
        cardVC?.viewModel.notifyTableInit()
        
        handleOpenRecordReport(viewMode: viewMode, btvc: btvc, actionTask: actionTask)
        
        container?.addRecordPlugin.showAddRecord(cardVC: btvc)
    }
    
    private func addRecordResult(actionTask: BTCardActionTask, baseContext: BaseContext) {
        container?.addRecordPlugin.addRecordResult(actionTask: actionTask, baseContext: baseContext)
    }
    
    private func handleSubmitModeReport() {
        guard UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable else {
            return
        }
        guard let cardVC = cardVC else {
            return
        }
        // 埋点 ccm_bitable_record_create_view
        var trackParams = cardVC.viewModel.getCommonTrackParams()
        DocsTracker.newLog(enumEvent: .bitableRecordCreateView, parameters: trackParams)
    }

    private func handleOpenRecordReport(
        viewMode: BTViewMode?,
        btvc: BTController,
        actionTask: BTCardActionTask
    ) {
        guard let vc = self.registeredVC as? BrowserViewController else {
            return
        }
        let openBaseTraceId = vc.fileConfig?.getOpenFileTraceId()
        guard let traceId = BTStatisticManager.shared?.createNormalTrace(parentTrace: openBaseTraceId) else {
            return
        }
        let recordConsumer = BTOpenRecordConsumer()
        let cellConsumer = BTRecordCellConsumer()
        BTStatisticManager.shared?.addNormalConsumer(traceId: traceId, consumer: recordConsumer)
        BTStatisticManager.shared?.addNormalConsumer(traceId: traceId, consumer: cellConsumer)

        // 除了高级权限、form、分享记录，其他归类为普通 card
        let realModel = actionTask.actionParams.data.viewType == .form ? .form : (viewMode ?? BTViewMode.card)
        BTOpenRecordReportHelper.reportStart(
            traceId: traceId,
            viewMode: realModel,
            isBitableReady: actionTask.actionParams.data.bitableIsReady,
            recordId: actionTask.actionParams.data.recordId
        )
        btvc.context.openRecordTraceId = traceId
        btvc.context.openBaseTraceId = openBaseTraceId
    }

    private func showForm(_ formVC: BTController, parentVC: BrowserViewController) {
        if let actionTask = actionQueueManager.currentActionTask as? BTCardActionTask,
           actionTask.actionParams.action == .submitResult {
            showFormResult(cardActionTask: actionTask)
        }
        // 表单作为childVC 不需要重复添加水印了
        formVC.watermarkConfig.needAddWatermark = false
        
        if let container = container {
            container.getOrCreatePlugin(BTContainerFormViewPlugin.self).showForm(formVC: formVC)
            relayoutToolbarsContainer(browserVC: parentVC, cardVC: cardVC)
        } else {
            if isShowOnboarding(parentVC), let topView = parentVC.children.last?.view, topView.superview == parentVC.view {
                // 当前顶层上正显示 onboarding 视图，不应当盖在 onboarding 之上
                parentVC.addChild(formVC)
                parentVC.view.insertSubview(formVC.view, belowSubview: topView)
            } else {
                parentVC.addChild(formVC)
                parentVC.view.addSubview(formVC.view)
            }
            formVC.didMove(toParent: parentVC)
            formVC.view.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.bottom.equalTo(parentVC.editor)
            }
            relayoutToolbarsContainer(browserVC: parentVC, cardVC: cardVC)
        }
    }
    
    /// 展示表单提交结果页面
    private func showFormResult(cardActionTask: BTCardActionTask) {
        guard let browserVC = navigator?.currentBrowserVC as? BrowserViewController,
              let cardVC = cardVC, cardVC.viewModel.tableModel.tableID == cardActionTask.actionParams.data.tableId else {
            DocsLogger.btInfo("[SYNC] Cannot show FormResultView")
            closeFormResultView()
            return
        }
        let param = cardActionTask.actionParams.data
        let formResultData = BitableFormResultView.FormResultViewData(title: param.forbiddenSubmitReason.title,
                                                                      description: param.forbiddenSubmitReason.reason,
                                                                      resubmitEnable: !param.forbiddenSubmit,
                                                                      baseId: param.baseId,
                                                                      tableId: param.tableId,
                                                                      actionCallback: cardActionTask.actionParams.callback)
        formResultView.update(data: formResultData)
        setFABHidden(false, isForm: true)
        guard formResultView.superview == nil else {
            DocsLogger.btInfo("[SYNC] FormResultView is showing")
            return
        }
        formResultView.snp.removeConstraints()
        formResultView.removeFromSuperview()
        cardVC.view.addSubview(formResultView)
        formResultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        relayoutToolbarsContainer(browserVC: browserVC, cardVC: cardVC)
    }
    
    private func handleSubmitResult(cardActionTask: BTCardActionTask) {
        guard let cardVC = cardVC,
                cardVC.viewModel.tableModel.tableID == cardActionTask.actionParams.data.tableId else {
            return
        }
        if cardActionTask.actionParams.data.submitResultCode == .canceled || cardActionTask.actionParams.data.submitResultCode == .unknown {
            // 报错后，重置按钮状态
            cardVC.unlockViewEditingAfterRecordSubmit()
        }
    }

    func closeFeed() {
        if let service = model?.jsEngine.fetchServiceInstance(CommentFeedService.self) {
            service.closePanel()
        }
    }

    /// 在ms 下，作为 follower的情况下，打开卡片时先手动清除当前的附件状态。
    /// 因为前端会打开附件的时候去关闭老的附件。如果卡片先打开再去关闭附件就会有问题，所以需要客户端手动清除。
    func clearAttachFileWhenOpenCardAsFollower() {
        if let spaceFollowAPI = (self.navigator?.currentBrowserVC as? BrowserViewController)?.spaceFollowAPIDelegate,
           spaceFollowAPI.followRole == .follower {
            spaceFollowAPI.follow(nil, onOperate: .exitAttachFile)
        }
    }

    func closeFormResultView() {
        guard formResultView.superview != nil else { return }
        DocsLogger.btInfo("[SYNC] closeFormResultView")
        formResultView.removeFromSuperview()
    }

    private func isShowOnboarding(_ parentVC: UIViewController) -> Bool {
        return OnboardingManager.shared.getCurrentTopOnboardingID(in: parentVC) == .bitableExposeCatalogIntro
    }
}

extension BTJSService: BitableFormResultViewDelegate {
    func refillForm(baseId: String, tableId: String, callback: String) {
        let param: [String: Any] = [
            "action": BTActionFromUser.submitResult.rawValue,
            "baseId": baseId,
            "tableId": tableId
        ]
        self.callFunction(DocsJSCallBack(rawValue: callback), tableId: tableId, params: param, completion: nil)
        
        if var trackParams = cardVC?.viewModel.getCommonTrackParams() {
            trackParams["click"] = "fill_again"
            trackParams["target"] = "ccm_bitable_content_page_view"
            DocsTracker.newLog(enumEvent: .bitableFormClick, parameters: trackParams)
        }
    }
}

public enum BTCopyPermission {
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    case allow
    // 兜底用
    case refuseByUser
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    case refuseByAdmin
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    case refuseByDlp(DlpCheckStatus)
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    case refuseByFileStrategy
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    case refuseBySecurityAudit
    case allowBySingleDocumentProtect
    case fromPermissionSDK(response: PermissionResponse)
}

protocol BTControllerDelegate: AnyObject {

    func cardLink(action: BTActionFromUser,
                  originBaseID: String,
                  originTableID: String,
                  sourceBaseID: String,
                  sourceTableID: String,
                  destinationBaseID: String,
                  destinationTableID: String,
                  callback: String)

    func cardDidLoadInitialData(isFormCard: Bool)

    func cardDidClickHeaderButton(_ card: BTController,
                                  action: BTActionFromUser,
                                  currentBaseID: String,
                                  currentTableID: String,
                                  originBaseID: String,
                                  originTableID: String,
                                  callback: String)
    
    func cardDidClickSubmitTopTip(_ card: BTController,
                                  currentBaseID: String,
                                  currentTableID: String,
                                  callback: String)

    func card(_ card: BTController,
              didSwitchTo newRecordID: String,
              from originalRecordID: String,
              newRecordGroupValue: String,
              currentBaseID: String,
              currentTableID: String,
              topFieldId: String,
              originBaseID: String,
              originTableID: String,
              callback: String)

    func card(_ controller: BTController,
              tableID: String?,
              viewID: String?,
              didChangeOrientationTo orientation: UIDeviceOrientation)

    func cardCloseAll(animated: Bool, completion: (() -> Void)?)

    func cardDidClose(shouldSetCardVcNil: Bool)

    func cardCloseForm()
    
    func cardCloseIndRecord()
    
    func cardCloseAddRecord()

    func cardDidOpen(_ card: BTController,
                     currentBaseID: String,
                     currentTableID: String,
                     originBaseID: String,
                     originTableID: String,
                     isFormCard: Bool,
                     callback: String)

    func cardDidScrollUp(isForm: Bool)

    func cardDidScrollDown(isForm: Bool)
    
    func cardDidScroll(_ scrollView: UIScrollView, isForm: Bool)

    func cardDidStartEditing(isForm: Bool)

    func cardDidStopEditing(isForm: Bool)
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func cardGetCopyPermission(_ tokens: (baseToken: String, objToken: String?)) -> BTCopyPermission?
    
    func cardGetBrowserController() -> UIViewController?
    
    func cardGetBitableBrowserController() -> UIViewController?
        
    func didClickCTANoticeMore(with acitonParmas: BTActionParamsModel)
    
    func recordEnableSubscribe(baseContext: BaseContext, viewMode: BTViewMode?) -> Bool
    
    func storeRecordSubscribeStatus(recordId: String, status: BTRecordSubscribeStatus)
    
    func storeRecordAutoSubscribeStatus(recordId: String, status: BTRecordAutoSubStatus)
    
    func getRecordSubscribeStatusFromLocalCache(recordId: String) -> BTRecordSubscribeStatus
    
    func getUploadingStatus(baseID: String, tableID: String, recordID: String, fieldIDs: [String]) -> BTUploadingAttachmentsStatus
}

extension BTJSService: BTControllerDelegate {

    func cardLink(action: BTActionFromUser,
                  originBaseID: String,
                  originTableID: String,
                  sourceBaseID: String,
                  sourceTableID: String,
                  destinationBaseID: String,
                  destinationTableID: String,
                  callback: String) {
        DocsLogger.btInfo("[ACTION] js [LINK] \(sourceTableID) -> \(destinationTableID)")
        /**
         外层永远传 origin (第 0 层卡片) 的 tableID，前端依赖这个 ID 决定代码执行在哪个 card component 中；
         内层如果是 forward 则传 destination，如果是 backward 则传 source。
         例：A --> B --> C，A 是 origin
         A forward to B: 外层 A，内层 B
         B forward to C: 外层 A，内层 C
         C backward to B: 外层 A，内层 C
         B backward to A: 外层 A，内层 B
         */

        var innerBaseID: String = ""
        var innerTableID: String = ""
        if action == .forwardLinkTable {
            innerBaseID = destinationBaseID
            innerTableID = destinationTableID
        } else if action == .backwardLinkTable {
            innerBaseID = sourceBaseID
            innerTableID = sourceTableID
        } else {
            DocsLogger.btError("[ACTION] cardLink received wrong parameters")
            return
        }
        let param: [String: Any] = [
            "action": action.rawValue,
            "baseId": originBaseID,
            "tableId": originTableID,
            "payload": ["baseId": innerBaseID, "tableId": innerTableID]
        ]
        callFunction(DocsJSCallBack(rawValue: callback), tableId: originTableID, params: param, completion: nil)
    }

    func cardCloseForm() {
        DocsLogger.btInfo("[ACTION] cardCloseForm")
        guard let bvc = self.registeredVC as? BrowserViewController else {
            DocsLogger.btError("[ACTION] vc type not correct when exiting form")
            return
        }
        closeFormResultView()
        cardVC?.willMove(toParent: nil)
        cardVC?.view.removeFromSuperview()
        cardVC?.removeFromParent()
        relayoutToolbarsContainer(browserVC: bvc, cardVC: nil)
    }
    
    func cardCloseIndRecord() {
        DocsLogger.btInfo("[ACTION] cardCloseIndRecord")
        guard let bvc = self.registeredVC as? BrowserViewController, let cvc = cardVC, cvc.viewModel.mode.isIndRecord else {
            DocsLogger.btError("[ACTION] vc type not correct when exiting ind record")
            return
        }
        if !UserScopeNoChangeFG.YY.bitableRecordShareFixDisable {
            bvc.back()
            return
        }
        bvc.dismiss(animated: false) {
            bvc.back()
        }
    }
    
    func cardCloseAddRecord() {
        DocsLogger.btInfo("[ACTION] cardCloseAddRecord")
        guard let bvc = self.registeredVC as? BrowserViewController else {
            DocsLogger.btError("[ACTION] vc type not correct when exiting ind record")
            return
        }
        bvc.back()
        return
    }

    func cardDidLoadInitialData(isFormCard: Bool) {
        if (!UserScopeNoChangeFG.XM.cardOpenLoadingEnable) {
            // 关闭FG走原来的逻辑
            showCardRightNow(isFormCard: isFormCard)
        }
    }
    
    func showCardRightNow(isFormCard: Bool) {
        DocsLogger.btInfo("[LifeCycle] BTController cardDidLoadInitialData")
        DocsLogger.btInfo("[ACTION] js presenting base bt card isFormCard: \(isFormCard)")
        guard let cardVC = cardVC,
              let browserVC = navigator?.currentBrowserVC as? BrowserViewController else { return }

        if isFormCard {
            showForm(cardVC, parentVC: browserVC)
            relayoutToolbarsContainer(browserVC: browserVC, cardVC: cardVC)
            return
        } else if cardVC.viewModel.mode == .addRecord {
            // 添加记录走直出流程
            return
        }

        let isInVCFollow = browserVC.isInVideoConference
        let isIndRecord = cardVC.viewModel.mode.isIndRecord
        let isInTemplatePreview = cardVC.showCardActionTask?.actionParams.data.openSource == .templatePreview

        if !UserScopeNoChangeFG.YY.bitableRecordShareFixDisable, isIndRecord, let container = container {
            container.indRecordPlugin.showIndRecord(cardVC: cardVC)
            relayoutToolbarsContainer(browserVC: browserVC, cardVC: cardVC)
            return
        }
        
        let nav = BTNavigationController(rootViewController: cardVC).construct { it in
            if UserScopeNoChangeFG.ZJ.btCardReform,
               UserScopeNoChangeFG.ZJ.btItemViewPresentModeFixDisable {
                it.modalPresentationStyle = (isInVCFollow || BTNavigator.isReularSize(browserVC)) ? .overCurrentContext : .overFullScreen
            } else {
                it.modalPresentationStyle = (isInVCFollow || isIndRecord || isInTemplatePreview) ? .overCurrentContext : .overFullScreen
            }
            
            it.transitioningDelegate = isIndRecord ? nil : cardVC
        }

        //VC Follow进入bitable卡片
        browserVC.spaceFollowAPIDelegate?.follow(browserVC, add: cardVC)
        if SKDisplay.phone {
            //fix: https://meego.feishu.cn/larksuite/issue/detail/3431261?parentUrl=%2Flarksuite%2FissueView%2Fb0XeV04Qsh
            //横屏状态下退出文档到最近列表，再次打开文档，文档竖屏显示
            //但是UIDevice.current.orientation的值还是上次横屏的状态，导致打开卡片时自动转到横屏了
            //所以需要重置下UIDevice.current.orientation的值来解决这个问题
            LKDeviceOrientation.setOritation(LKDeviceOrientation.convertMaskOrientationToDevice(UIApplication.shared.statusBarOrientation))
        }
        
        // 如果是iphone，且不是分享记录卡片 就使用 push的方式打开卡片
        if self.cardVC?.isPushed ?? false {
            browserVC.navigationController?.pushViewController(cardVC, animated: !isIndRecord)
        } else {
            safePresent {
                Navigator.shared.present(nav,
                                         from: UIViewController.docs.topMost(of: browserVC) ?? browserVC,
                                         animated: !isIndRecord)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000) {
            //避免BTController present失败导致后续task无法执行
            cardVC.showCardActionTask?.completedBlock()
            cardVC.showCardActionTask = nil
        }
    }
    
    func safePresent(safe: @escaping (() -> Void)) {
        if let presentedVC = registeredVC?.presentedViewController {
            suppendCommenVCIfNeed(presentedVC)
            presentedVC.dismiss(animated: true, completion: safe)
        } else {
            safe()
        }
    }

    func card(_ card: BTController,
              didSwitchTo newRecordID: String,
              from originalRecordID: String,
              newRecordGroupValue: String,
              currentBaseID: String,
              currentTableID: String,
              topFieldId: String,
              originBaseID: String,
              originTableID: String,
              callback: String) {
        DocsLogger.btInfo("[ACTION] js switch from \(originalRecordID) to \(newRecordID)")
        let param: [String: Any] = [
            "action": BTActionFromUser.switch.rawValue,
            "baseId": originBaseID,
            "tableId": originTableID,
            "payload": [
                "baseId": currentBaseID,
                "tableId": currentTableID,
                "newRecordId": newRecordID,
                "oldRecordId": originalRecordID,
                "groupValue": newRecordGroupValue,
                "topFieldId": topFieldId
            ]
        ]
        callFunction(DocsJSCallBack(rawValue: callback), tableId: currentTableID, params: param, completion: nil)
    }

    func cardDidClickHeaderButton(_ card: BTController,
                                  action: BTActionFromUser,
                                  currentBaseID: String,
                                  currentTableID: String,
                                  originBaseID: String,
                                  originTableID: String,
                                  callback: String) {
        DocsLogger.btInfo("[ACTION] js did click header action: \(action.rawValue)")
        let param: [String: Any] = [
            "action": action.rawValue,
            "baseId": originBaseID,
            "tableId": originTableID,
            "payload": [
                "baseId": currentBaseID,
                "tableId": currentTableID
            ]
        ]
        callFunction(DocsJSCallBack(rawValue: callback), tableId: originTableID, params: param, completion: nil)
    }
    
    func cardDidClickSubmitTopTip(_ card: BTController,
                                  currentBaseID: String,
                                  currentTableID: String,
                                  callback: String) {
        DocsLogger.btInfo("[ACTION] user did click SubmitTopTip action: \(BTActionFromUser.setSubmitTopTipShow.rawValue)")
        let param: [String: Any] = [
            "baseId": currentBaseID,
            "tableId": currentTableID,
            "submitTopTipShowed": true
        ]
        DocsTracker.newLog(enumEvent: .bitableCardLimitedTipsClick, parameters: ["click": "cancel"])
        callFunction(.setSubmitTopTipShow, tableId: currentTableID, params: param, completion: nil)
    }

    func card(_ controller: BTController,
              tableID: String?,
              viewID: String?,
              didChangeOrientationTo orientation: UIDeviceOrientation) {
        // 如果是 sheets，要埋点
        guard model?.hostBrowserInfo.docsInfo?.type == .sheet else { return }
        var params: [String: String] = [:]
        params["file_id"] = model?.hostBrowserInfo.docsInfo?.encryptedObjToken ?? ""
        params["file_type"] = "bitable"
        params["mode"] = "default"
        params["module"] = "sheet"
        params["attr_op_status"] = "effective"
        params["orientation"] = orientation.isLandscape ? "landscape" : "portrait"
        params["action"] = orientation.isLandscape ? "enter_landscape" : "exit_landscape"
        params["source"] = "mobile_rotation"
        params["is_record_card_open"] = "1"
        getViewType(tableID: tableID, viewID: viewID) { (stViewType) -> Void in
            if let stViewType = stViewType {
                params["bitable_view_type"] = stViewType
                DocsTracker.log(enumEvent: .sheetOperation, parameters: params)
            }
        }
    }

    /// 前端关闭的会走这里
    func cardCloseAll(animated: Bool, completion: (() -> Void)? = nil) {
        let isPushed = cardVC?.isPushed
        uploadMediaHelper?.removeAllPendingAttachments()
        actionQueueManager.reset()
        if let topMost = topMostOfBrowserVC() {
            suppendCommenVCIfNeed(topMost)
        }
        
        var bitableBrowserVC: BrowserViewController?
        if UserScopeNoChangeFG.QYK.btNavigatorCardCloseFixDisable {
            guard let browserVC = navigator?.currentBrowserVC as? BrowserViewController else {
                DocsLogger.btError("cardCloseAll browserVC find error: \(String(describing: navigator?.currentBrowserVC))")
                return
            }
            bitableBrowserVC = browserVC
        }
        
        if !UserScopeNoChangeFG.YY.bitableRecordShareFixDisable, cardVC?.viewModel.mode.isIndRecord == true, let container = self.container {
            container.indRecordPlugin.closeIndRecord()
            completion?()
            self.resumeCommentVC()
        } else if isPushed ?? false {
            guard let VC = cardVC else {
                DocsLogger.btError("cardCloseAll error: \(String(describing: cardVC))")
                return
            }
            popAllCardsSafely(VC: VC, completion: completion)
            self.resumeCommentVC()
        } else {
            if !UserScopeNoChangeFG.QYK.btNavigatorCardCloseFixDisable {
                cardVC?.presentingViewController?.dismiss(animated: animated, completion: { [weak self] in
                    completion?()
                    self?.resumeCommentVC()
                })
            } else {
                bitableBrowserVC?.dismiss(animated: animated, completion: { [weak self] in
                    completion?()
                    self?.resumeCommentVC()
                })
            }
        }
        cardVC = nil
    }
    
    func popAllCardsSafely(VC: BTController, completion: (() -> Void)? = nil) {
        // 正常情况下，一定会走 if 分支，只有VC已经被pop，才会走else分支
        if VC.navigationController?.viewControllers.contains(VC) == true {
            VC.navigationController?.popToViewController(VC, animated: false)
            VC.navigationController?.popViewController(animated: true)
        } else {
            DocsLogger.btError("BTController was poped abnormally")
            VC.afterRealDismissal()
        }
        completion?()
    }

    /// 手动关闭的会走这里。
    func cardDidClose(shouldSetCardVcNil: Bool = true) {
        DispatchQueue.main.async {
            if shouldSetCardVcNil {
                self.cardVC = nil
            }
            self.uploadMediaHelper?.removeAllPendingAttachments()
            self.actionQueueManager.reset()
            self.resumeCommentVC()
        }
    }

    func cardDidOpen(_ card: BTController,
                     currentBaseID: String,
                     currentTableID: String,
                     originBaseID: String,
                     originTableID: String,
                     isFormCard: Bool,
                     callback: String) {
        DocsLogger.btInfo("[ACTION] js did open card of table \(currentTableID)")
        let param: [String: Any] = [
            "action": BTActionFromUser.open.rawValue,
            "baseId": originBaseID,
            "tableId": originTableID,
            "isForm": isFormCard,
            "payload": [
                "baseId": currentBaseID,
                "tableId": currentTableID
            ]
        ]
        callFunction(DocsJSCallBack(rawValue: callback), tableId: originTableID, params: param, completion: nil)
    }

    func cardDidScrollUp(isForm: Bool) {
        setFABHidden(true, isForm: isForm)
    }

    func cardDidScrollDown(isForm: Bool) {
        setFABHidden(false, isForm: isForm)
    }
    
    func cardDidScroll(_ scrollView: UIScrollView, isForm: Bool) {
        if isForm {
            if let container = container {
                container.formViewPlugin.didScroll(scrollView)
            }
        }
    }

    func cardDidStartEditing(isForm: Bool) {
        setFABHidden(true, isForm: isForm)
    }

    func cardDidStopEditing(isForm: Bool) {
        setFABHidden(false, isForm: isForm)
    }
    
    func cardGetBitableBrowserController() -> UIViewController? {
        if !UserScopeNoChangeFG.QYK.btCardPresentFromSideErrorFixDisable {
            if let VC = self.registeredVC?.parent as? BitableBrowserViewController {
                return self.registeredVC?.parent
            }
            return self.registeredVC
        } else {
            return cardGetBrowserController()
        }
    }
    
    func cardGetBrowserController() -> UIViewController? {
        guard UserScopeNoChangeFG.ZJ.btItemViewIPadFixDisable else {
            return self.registeredVC
        }
        
        return self.navigator?.currentBrowserVC
    }
    
    
    func getUploadingStatus(baseID: String, tableID: String, recordID: String, fieldIDs: [String]) -> BTUploadingAttachmentsStatus {
        return uploadMediaHelper?.getUploadingStatus(baseID: baseID, tableID: tableID, recordID: recordID, fieldIDs: fieldIDs) ?? .allUploaded
    }

    func setFABHidden(_ isHidden: Bool, isForm: Bool, isDashboardShare: Bool = false) {
        /// 暂时只有表单有这个逻辑
        /// 仪表盘分享（通用分享组件）也要支持这个逻辑
        guard isForm || isDashboardShare else { return }
        toolbarsContainer.setFABHide(isHidden)
    }
    
    //MARK: 订阅start
    func recordEnableSubscribe(baseContext: BaseContext, viewMode: BTViewMode?) -> Bool {
        //Record旧版本不支持订阅功能
        guard UserScopeNoChangeFG.ZJ.btCardReform else {
            return false
        }
        guard UserScopeNoChangeFG.PXR.bitableRecordSubscribeEnable, let docsType = model?.hostBrowserInfo.docsInfo?.inherentType else {
            return false
        }
        if docsType == .sheet {
            return false
        } else if docsType == .bitable {
            //MockBitable不支持订阅，比如仪表盘下钻场景
            if baseContext.baseToken.hasPrefix("mockBitable") {
                return false
            }
            //高级权限新增记录场景不支持订阅
            if viewMode == .submit {
                return false
            }
            //模板预览场景不支持订阅
            if let browserVC = ui?.hostView.affiliatedViewController as? BrowserViewController, browserVC.isFromTemplatePreview {
                return false
            }
            return true
        } else if docsType == .docX || docsType == .doc {
            //docX refer场景支持订阅
            let permission = baseContext.permissionObj
            let isDocRefer = permission.objType == .bitable && permission.objToken == baseContext.baseToken
            return isDocRefer
        } else {
            return false
        }
    }
    
    func storeRecordSubscribeStatus(recordId: String, status: BTRecordSubscribeStatus) {
        self.recordsSubscribeInfoCache[recordId] = status
    }
    
    func storeRecordAutoSubscribeStatus(recordId: String, status: BTRecordAutoSubStatus) {
        self.recordsAutoSubscribeInfoCache[recordId] = status
    }
    
    func getRecordSubscribeStatusFromLocalCache(recordId: String) -> BTRecordSubscribeStatus {
        if let cacheStatus = self.recordsSubscribeInfoCache[recordId] {
            return cacheStatus
        }
        return .unknown
    }
    
    func getRecordAutoSubscribeStatusFromLocalCache(recordId: String) -> BTRecordAutoSubStatus {
        if let cacheStatus = self.recordsAutoSubscribeInfoCache [recordId] {
            return cacheStatus
        }
        //默认允许编辑触发自动订阅
        return .editAutoSubDefault
    }
    //MARK: 订阅end
    
}

// MARK: - 评论冲突处理
extension BTJSService {
    /// 为了解决评论上 present 卡片的问题。当第一个 presentVC 是可以 Comment 的时候先 suppend
    /// https://meego.feishu.cn/larksuite/issue/detail/4962599
    func suppendCommenVCIfNeed(_ checkVC: UIViewController) {
        CommentSuppendAndResumeManager.suppendIfNeed(checkVC, by: self.model?.jsEngine,
                                                     isInMagicShare: isInVideoConference)
    }
    
    func resumeCommentVC() {
        CommentSuppendAndResumeManager.resume(by: self.model?.jsEngine, isInMagicShare: isInVideoConference)
    }
}

protocol BTDataBizInfo: AnyObject {
    var isInVideoConference: Bool { get }
    var hostDocInfo: DocsInfo { get }
    var hostDocUrl: URL? { get }
    var hostChatId: String? { get }
    var jsFuncService: SKExecJSFuncService? { get }
    // Native 记录新建编辑数据管理器
    var holdDataProvider: BTHoldDataProvider? { get }
}

/// 需要比较带字段详细信息的接口，统一使用，便于后续扩展
struct BTJSFieldInfoArgs {
    var index: Int? //当前字段在表格中列的index，新增选项时需要
    var id: String?
    var fieldID: String?
    var fieldName: String?
    var compositeType: BTFieldCompositeType?
    var fieldDescription: BTDescriptionModel?
    var allowEditModes: AllowedEditModes?
    var extendConfig: [String: Any]?
    var extendInfo: FieldExtendInfo.ExtendInfo?
}

struct BTJSFetchCardArgs {
    var baseData: BTBaseData
    var recordID: String
    var groupValue: String?
    var startFromLeft: Int
    var fetchCount: Int
    var requestingForInvisibleRecords: Bool
    var viewMode: BTViewMode = .card
    var fieldIds: [String] = []
}

struct BTJSFetchLinkCardArgs {
    var baseData: BTBaseData
    var bizTableId: String
    var bizFieldId: String
    var recordIDs: [String]?
    var startFromLeft: Int
    var fetchCount: Int
    var fieldIDs: [String]?
    var searchKey: String?
}

struct BTJSSearchRecordsArgs {
    var keyword: String
    var baseID: String
    var tableID: String
    var fieldID: String // 当前字段的 fieldId
    var fieldIDs: [String]? // 指定搜索的范围，默认为空，代表在全部字段的全部值中搜索匹配记录
    var caseInsensitive: Bool? // 是否忽略大小写，默认 true
}

struct BTExecuteCommandArgs {
    var command: BTCommands
    var tableID: String
    var viewID: String
    var fieldInfo: BTJSFieldInfoArgs
    var property: Any?
    var checkConfirmValue: [String: Any]?
    var extraParams: Any?
}

struct BTCheckConfirmAPIArgs {
    var tableID: String
    var viewID: String
    var fieldInfo: BTJSFieldInfoArgs
    var property: Any?
    var extraParams: Any?
    var generateAIContent: Bool?
}

struct BTShowAiConfigFormArgs {
    var isNewField: Bool
    var baseId: String
    var fieldId: String
    var fieldUIType: String
}

struct BTHideAiConfigFormArgs {
    var fieldId: String
    var tableId: String
}

struct BTFieldTypeChangeArgs {
    var fieldId: String
    var tableId: String
    var targetUIType: String
}

struct BTGetBitableCommonDataArgs {
    var type: BTEventType
    var tableID: String?
    var viewID: String?
    var fieldID: String?
    var extraParams: [String: Any]?
}

struct BTGetPermissionDataArgs {
    var entity: String
    var tableID: String?
    var viewID: String?
    var recordID: String?
    var fieldIDs: [String]?
    var operation: [OperationType]
}

struct BTSaveFieldArgs {
    var originBaseID: String
    var originTableID: String
    var currentBaseID: String
    var currentTableID: String
    var currentViewID: String
    var currentRecordID: String
    var currentFieldID: String
    var callback: String
    var editType: BTFieldEditType?
    var value: Any?
}

struct BTCreateAndLinkRecordArgs {
    var originBaseID: String
    var originTableID: String
    var callback: String
    var sourceLocation: BTFieldLocation
    var targetLocation: BTFieldLocation
    var value: Any?
}

struct BTDeleteRecordArgs {
    var originBaseID: String
    var originTableID: String
    var callback: String
    var currentBaseID: String
    var currentTableID: String
    var currentViewID: String
    var recordID: String
}

struct BTHiddenFieldsDisclosureArgs {
    var originBaseID: String
    var originTableID: String
    var callback: String
    var currentBaseID: String
    var currentTableID: String
    var toDisclosed: Bool
}

enum AsyncJSRequestBiz: String {
    case card = "Card"
    case toolBar = "Toolbar"
    case stage = "Stage"
}

protocol BTDataService: BTDataBizInfo {

    // 直接调用 DocsJSCallback

    func getTableRecordIDList(baseID: String,
                              tableID: String,
                              fieldID: String,
                              resultHandler: @escaping (BTTableRecordIDList?, Error?) -> Void)

    func searchRecordsByKeyword(args: BTJSSearchRecordsArgs,
                                resultHandler: @escaping ([String]?, Error?) -> Void) // 返回匹配的 recordIDs

    /// 拉取与视图无关的卡片数据（需要指定 recordID 数组）
    func fetchRecords(baseID: String,
                      tableID: String,
                      recordIDs: [String],
                      fieldIDs: [String]?, // 指定拉取的字段列，默认为空，代表返回全部字段的值
                      resultHandler: @escaping (BTTableValue?, Error?) -> Void)

    func fetchTableMeta(baseID: String,
                        tableID: String,
                        viewID: String,
                        viewMode: BTViewMode,
                        fieldIds: [String],
                        resultHandler: @escaping (BTTableMeta?, Error?) -> Void)

    func getViewType(tableID: String?,
                     viewID: String?,
                     resultHandler: @escaping (String?) -> Void)

    func executeCommands(args: BTExecuteCommandArgs,
                         resultHandler: @escaping (BTExecuteFailReson?, Error?) -> Void)
    
    func checkConfirmAPI(args: BTCheckConfirmAPIArgs,
                         resultHandler: @escaping (Result<CheckConfirmResult, Error>) -> Void
    )
    
    func showAiConfigFormAPI(args: BTShowAiConfigFormArgs, completion:  @escaping () -> Void)
    
    func hideAiConfigFormAPI(args: BTHideAiConfigFormArgs, completion:  @escaping () -> Void)
    
    func checkFieldTypeChangeAPI(args: BTFieldTypeChangeArgs, completion:  @escaping ([String: Any]) -> Void)
    
    func openAiPrompt()
    
    func getBitableCommonData(args: BTGetBitableCommonDataArgs,
                              resultHandler: @escaping (Any?, Error?) -> Void)

    func getPermissionData(args: BTGetPermissionDataArgs,
                           resultHandler: @escaping (Any?, Error?) -> Void)

    // 调用 performCardsAction 过来的 callback string

    func saveField(args: BTSaveFieldArgs)
    
    func quickAddViewClick(args: BTSaveFieldArgs)

    func createAndLinkRecord(args: BTCreateAndLinkRecordArgs,
                             resultHandler: ((Result<Any?, Error>) -> Void)?)

    func toggleHiddenFieldsDisclosure(args: BTHiddenFieldsDisclosureArgs)

    func deleteRecord(args: BTDeleteRecordArgs)

    ///用户在选择面板选择通知
    func saveNotifyStrategy(notifiesEnabled: Bool)

    ///获取当前文档上次用户通知选择，默认是true
    func obtainLastNotifyStrategy() -> Bool

    ///bitable字段分组统计获取数据接口
    func obtainGroupData(anchorId: String,
                         childrenAnchorId: String?,
                         direction: String,
                         tableId: String,
                         resultHandler: @escaping (BTGroupingStatisticsObtainGroupData?, Error?) -> Void)

    /// bitable异步数据请求接口，请求发送后等待前端回调response传回数据
    /// 若前端在20s内未回调该请求的response，则会触发超时逻辑，回传超时错误给业务方
    /// 注意：responseHandler的调用时机可能早于resultHandler，注意时序问题
    /// - Parameters:
    ///   - funcName: 请求前端对应接口
    ///   - tableId: 适配 docx 中可能出现多 base 场景，必须传 tableId 用于回调正确的 base
    ///   - params: 请求参数
    ///   - overTimeInterval: 超时时间
    ///   - responseHandler: 异步请求数据返回回调
    ///   - resultHandler: 请求完成回调
    func asyncJsRequest(biz: AsyncJSRequestBiz,
                        funcName: DocsJSCallBack,
                        baseId: String,
                        tableId: String,
                        params: [String: Any],
                        overTimeInterval: Double?,
                        responseHandler: @escaping(Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                        resultHandler: ((Result<Any?, Error>) -> Void)?)
    
    /// 拉取与视图有关的卡片数据（需要指定 viewID、起点、偏移量等），bitable按需加载改造新接口
    func fetchCardList(args: BTJSFetchCardArgs,
                       resultHandler: @escaping (BTTableValue?, Error?) -> Void)

    /// 获取视图Meta信息
    func getViewMeta(viewId: String, tableId: String, extra: [String: Any]?, responseHandler: @escaping (Result<BTViewMeta, Error>) -> Void)

    /// 拉取关联卡片数据（需要指定 viewID、起点、偏移量等），bitable按需加载改造新接口
    func fetchLinkCardList(args: BTJSFetchLinkCardArgs,
                           resultHandler: @escaping (BTTableValue?, Error?) -> Void)
    
    func getItemViewData(type: BTItemViewDataType,
                         tableId: String,
                         payload: [String: Any],
                         resultHandler: ((Result<Any?, Error>) -> Void)?)
    
    ///卡片被动订阅
    func triggerPassiveRecordSubscribeIfNeeded(recordId: String)
    /// 提交记录后自动订阅
    func triggerRecordSubscribeForSubmitIfNeeded(recordId: String)
}

extension BTJSService: BTDataService {
    var hostDocInfo: DocsInfo { model?.hostBrowserInfo.docsInfo ?? DocsInfo(type: .unknownDefaultType, objToken: "") }
    var hostDocUrl: URL? { model?.hostBrowserInfo.currentURL }
    var hostChatId: String? { model?.hostBrowserInfo.chatId }
    var jsFuncService: SKExecJSFuncService? { model?.jsEngine }

    func getTableRecordIDList(
        baseID: String,
        tableID: String,
        fieldID: String,
        resultHandler: @escaping (BTTableRecordIDList?, Error?) -> Void
    ) {
        let params: [String: Any] = [
            "baseId": baseID,
            "tableId": tableID,
            "fieldId": fieldID
        ]
        
        DocsLogger.btInfo("[SYNC] js fetch record ID list params: \(params.jsonString?.encryptToShort ?? "")")
        callFunction(
            DocsJSCallBack.btGetTableRecordIDList,
            tableId: tableID,
            params: params,
            completion: { (data, error) in
                if let error = error {
                    DocsLogger.btError("[SYNC] js get record ID list failed, error: \(error.localizedDescription)")
                    resultHandler(nil, error)
                    return
                }
                guard let dicData = data as? [String: Any],
                      let result = BTTableRecordIDList.deserialize(from: dicData) else {
                    let error = NSError(domain: "bitable", code: 999, userInfo: nil)
                    DocsLogger.btError("[SYNC] js get record ID list failed data: \(String(describing: data))")
                    resultHandler(nil, error)
                    return
                }
                DocsLogger.btInfo("[SYNC] js get recordID list: \(dicData)")
                resultHandler(result, nil)
            })
    }

    func searchRecordsByKeyword(args: BTJSSearchRecordsArgs, resultHandler: @escaping ([String]?, Error?) -> Void) {
        var params: [String: Any] = [
            "baseId": args.baseID,
            "tableId": args.tableID,
            "keywords": args.keyword,
            "fieldId": args.fieldID
        ]
        if let fieldIDs = args.fieldIDs {
            params["fieldIds"] = fieldIDs
        }
        if let caseInsensitive = args.caseInsensitive {
            params["ignoreCase"] = caseInsensitive
        }
        
        DocsLogger.btInfo("[SYNC] js search record ID list by keyword baseId:\(args.baseID) tableId:\(args.tableID) fieldId: \(args.fieldID)")
        callFunction(
            DocsJSCallBack.btSearchRecords,
            tableId: args.tableID,
            params: params,
            completion: { (data, error) in
                if let error = error {
                    DocsLogger.btError("[SYNC] js search record ID list by keyword failed, error: \(error.localizedDescription)")
                    resultHandler(nil, error)
                    return
                }
                guard let dicData = data as? [String: Any],
                    let result = BTTableRecordIDList.deserialize(from: dicData) else {
                    let error = NSError(domain: "bitable", code: 1000, userInfo: nil)
                    DocsLogger.btError("[SYNC] js search record ID list by keyword decode failed data: \(String(describing: data))")
                    resultHandler(nil, error)
                    return
                }
                DocsLogger.btInfo("[SYNC] js searched recordID list: \(dicData)")
                resultHandler(result.recordIds, nil)
            })
    }

    func fetchTableMeta(
        baseID: String,
        tableID: String,
        viewID: String,
        viewMode: BTViewMode = .card,
        fieldIds: [String] = [],
        resultHandler: @escaping (BTTableMeta?, Error?) -> Void
    ) {
        var params: [String: Any] = [
            "baseId": baseID,
            "tableId": tableID,
            "viewId": viewID,
        ]
        
        if viewMode.isStage {
            params["tableType"] = viewMode.trackValue
            if !fieldIds.isEmpty {
                params["fieldIds"] = fieldIds
            }
        }

        DocsLogger.btInfo("[SYNC] js fetch meta params: \(params.jsonString?.encryptToShort ?? "")")
        //请求meta信息
        callFunction(
            DocsJSCallBack.btGetTableMeta,
            tableId: tableID,
            params: params,
            completion: { (data, error) in
                if let error = error {
                    DocsLogger.btError("[SYNC] js get meta failed, error: \(error.localizedDescription)")
                    resultHandler(nil, error)
                    return
                }
                guard let dicData = data as? [String: Any] else {
                    let error = NSError(domain: "bitable", code: 1001, userInfo: nil)
                    DocsLogger.btError("[SYNC] js get table meta failed")
                    resultHandler(nil, error)
                    return
                }
                BTTableMeta.desrializedGlobalAsync(with: dicData, callbackInMainQueue: true) { model in
                    guard let result = model else {
                        let error = NSError(domain: "bitable", code: 1001, userInfo: nil)
                        DocsLogger.btError("[SYNC] desrialized table meta failed")
                        resultHandler(nil, error)
                        return
                    }
                    resultHandler(result, nil)
                }
            })
    }

    func fetchRecords(
        baseID: String,
        tableID: String,
        recordIDs: [String],
        fieldIDs: [String]? = nil,
        resultHandler: @escaping (BTTableValue?, Error?) -> Void
    ) {
        var params: [String: Any] = [
            "baseId": baseID,
            "tableId": tableID,
            "recordIds": recordIDs
        ]
        if let fieldIDs = fieldIDs {
            params["fieldIds"] = fieldIDs
        }
        
        DocsLogger.btInfo("[SYNC] js fetch records params: \(params.jsonString?.encryptToShort ?? "")")
        callFunction(
            DocsJSCallBack.btGetRecordsData,
            tableId: tableID,
            params: params,
            completion: { (data, error) in
                if let error = error {
                    DocsLogger.btError("[SYNC] js get records data failed, error: \(error.localizedDescription)")
                    resultHandler(nil, error)
                    return
                }
                guard let dicData = data as? [String: Any] else {
                    let error = NSError(domain: "bitable", code: 1003, userInfo: nil)
                    DocsLogger.btError("[SYNC] js get records data failed, data is \(String(describing: data))")
                    resultHandler(nil, error)
                    return
                }
                BTTableValue.desrializedGlobalAsync(with: dicData, callbackInMainQueue: true) { model in
                    guard let result = model else {
                        let error = NSError(domain: "bitable", code: 1003, userInfo: nil)
                        DocsLogger.btError("[SYNC] js get records data decode failed, data is \(String(describing: data))")
                        resultHandler(nil, error)
                        return
                    }
                    DocsLogger.btInfo("[SYNC] js get records data, record count: \(result.records.count)")
                    resultHandler(result, nil)
                }
            })
    }
    
    // nolint: duplicated_code
    func fetchCardList(args: BTJSFetchCardArgs,
                       resultHandler: @escaping (BTTableValue?, Error?) -> Void) {
        var params: [String: Any] = [
            "baseId": args.baseData.baseId,
            "tableId": args.baseData.tableId,
            "offset": args.startFromLeft,
            "length": args.fetchCount,
            "recordId": args.recordID,
            "includeInvisible": args.requestingForInvisibleRecords,
        ]
        
        if let groupValue = args.groupValue {
            params["groupValue"] = groupValue
        }
        
        if args.viewMode.isStage {
            params["tableType"] = args.viewMode.trackValue
            if !args.fieldIds.isEmpty {
                params["fieldIds"] = args.fieldIds
            }
        }
        
        DocsLogger.btInfo("[SYNC] js get CardList params: \(params.jsonString?.encryptToShort ?? "")")
        callFunction(
            DocsJSCallBack.btGetCardList,
            tableId: args.baseData.tableId,
            params: params,
            completion: { (data, error) in
                if let error = error {
                    DocsLogger.btError("[SYNC] js get data failed, error: \(error.localizedDescription)")
                    resultHandler(nil, error)
                    return
                }
                guard let dicData = data as? [String: Any] else {
                    let error = NSError(domain: "bitable", code: 1002, userInfo: nil)
                    DocsLogger.btError("[SYNC] js get data failed, data is \(String(describing: data))")
                    resultHandler(nil, error)
                    return
                }
                BTTableValue.desrializedGlobalAsync(with: dicData, callbackInMainQueue: true) { model in
                    guard let result = model else {
                        let error = NSError(domain: "bitable", code: 1002, userInfo: nil)
                        DocsLogger.btError("[SYNC] js get data decode failed, data is \(String(describing: data))")
                        resultHandler(nil, error)
                        return
                    }
                    DocsLogger.btInfo("[SYNC] js get table data, record count: \(result.records.count)")
                    resultHandler(result, nil)
                }
            })
    }

    func getViewMeta(viewId: String, tableId: String, extra: [String: Any]?, responseHandler: @escaping (Result<BTViewMeta, Error>) -> Void) {
        var params: [String: Any] = [
            "viewId": viewId,
            "tableId": tableId
        ]
        params["extra"] = extra

        guard let model = model else {
            DocsLogger.error("getViewMeta error, model is nil")
            responseHandler(.failure(BTViewMetaError.modelNil))
            return
        }
        DocsLogger.btInfo("[SYNC] js getViewMeta viewId: \(viewId.encryptToShort) tableId:\(tableId.encryptToShort)")

        callFunction(DocsJSCallBack.getViewMeta, tableId: tableId, params: params) { res, err in
            if let err = err {
                DocsLogger.error("getViewMeta error, js err", error: err)
                responseHandler(.failure(err))
                return
            }
            guard let res = res else {
                DocsLogger.error("getViewMeta error, res is nil")
                responseHandler(.failure(BTViewMetaError.jsResIsNil))
                return
            }

            let viewMeta: BTViewMeta
            do {
                viewMeta = try CodableUtility.decode(BTViewMeta.self, withJSONObject: res)
            } catch {
                DocsLogger.error("getViewMeta error, decode error", error: error)
                responseHandler(.failure(error))
                return
            }

            responseHandler(.success(viewMeta))
        }
            
    }

    // nolint: duplicated_code
    func fetchLinkCardList(args: BTJSFetchLinkCardArgs,
                           resultHandler: @escaping (BTTableValue?, Error?) -> Void) {
        var params: [String: Any] = [
            "baseId": args.baseData.baseId,
            "tableId": args.baseData.tableId,
            "offset": args.startFromLeft,
            "length": args.fetchCount,
            "bizTableId": args.bizTableId,
            "bizFieldId": args.bizFieldId
        ]

        if let recordIDs = args.recordIDs,
           !recordIDs.isEmpty {
            params["recordIdList"] = recordIDs
        }

        if let fieldIDs = args.fieldIDs {
            params["fieldIds"] = fieldIDs
        }
        
        DocsLogger.btInfo("[SYNC] js link card list params: \(params.jsonString?.encryptToShort ?? "")")
        if let searchKey = args.searchKey {
            params["keywords"] = searchKey
        }
        
        callFunction(
            DocsJSCallBack.btGetLinkCardList,
            tableId: args.baseData.tableId,
            params: params,
            completion: { (data, error) in
                if let error = error {
                    DocsLogger.btError("[SYNC] js link card list for, error: \(error.localizedDescription)")
                    resultHandler(nil, error)
                    return
                }
                guard let dicData = data as? [String: Any] else {
                    let error = NSError(domain: "bitable", code: 1002, userInfo: nil)
                    DocsLogger.btError("[SYNC] js link card list for, data is \(String(describing: data))")
                    resultHandler(nil, error)
                    return
                }
                BTTableValue.desrializedGlobalAsync(with: dicData, callbackInMainQueue: true) { model in
                    guard let result = model else {
                        let error = NSError(domain: "bitable", code: 1002, userInfo: nil)
                        DocsLogger.btError("[SYNC] js link card list for, data is \(String(describing: data))")
                        resultHandler(nil, error)
                        return
                    }
                    DocsLogger.btInfo("[SYNC] js link card list for, record count: \(result.records.count)")
                    resultHandler(result, nil)
                }
            })
    }

    func getViewType(tableID: String?, viewID: String?, resultHandler: @escaping (String?) -> Void) {
        var params: [String: Any] = [:]
        if let tableID = tableID {
            params["tableId"] = tableID
        }
        if let viewID = viewID {
            params["viewId"] = viewID
        }
        
        DocsLogger.btInfo("[SYNC] js getViewType params:\(params.jsonString?.encryptToShort ?? "")")
        
        callFunction(DocsJSCallBack.getViewType, tableId: tableID, params: params, completion: { type, error in
            if let error = error {
                DocsLogger.btError("[SYNC] js getViewType failed, error: \(error.localizedDescription)")
                resultHandler(nil)
                return
            }
            guard let viewType = type as? String else {
                DocsLogger.btInfo("[SYNC] js getViewType 返回的类型是 \(String(describing: type))")
                resultHandler(nil)
                return
            }
            resultHandler(viewType)
        })
    }

    func executeCommands(args: BTExecuteCommandArgs, resultHandler: @escaping (BTExecuteFailReson?, Error?) -> Void) {
        let logParams: [String: Any] = [
            "type": "\(args.fieldInfo.compositeType?.uiType.rawValue)",
            "tableId": args.tableID,
            "viewId": args.viewID,
            "fieldId": args.fieldInfo.fieldID,
            "fieldIndex": args.fieldInfo.index
        ]
        DocsLogger.btInfo("[SYNC] js executeCommands command: \(args.command) params: \(logParams)")
        var data: [String: Any?] = [:]

        if let property = args.property {
            data["property"] = property
        }

        var params: [String: Any] = [
            "cmd": args.command.rawValue,
            "viewId": args.viewID,
            "tableId": args.tableID
        ]
        if let checkConfirmValue = args.checkConfirmValue {
            params["checkConfirmValue"] = checkConfirmValue
        }

        if let index = args.fieldInfo.index {
            params["index"] = index
        }
        
        if let id = args.fieldInfo.id {
            data["id"] = id
        }
        
        if let fieldID = args.fieldInfo.fieldID {
            data["id"] = fieldID
            params["fieldId"] = fieldID
        }

        if let fieldName = args.fieldInfo.fieldName {
            data["name"] = fieldName
        }
        
        if let compositeType = args.fieldInfo.compositeType {
            data["type"] = compositeType.type.rawValue
            data["fieldUIType"] = compositeType.uiType.rawValue
            if let editModes = args.fieldInfo.allowEditModes,
               let editModesMaps = compositeType.getAllowEditModesMap(by: editModes) {
                data["allowedEditModes"] = editModesMaps
            }
        }

        if let fieldDescription = args.fieldInfo.fieldDescription {
            data["description"] = fieldDescription.toJSON() ?? ""
        }
        
        if let extendConfig = args.fieldInfo.extendConfig {
            params.merge(other: extendConfig)
        }
        
        if let extendInfo = args.fieldInfo.extendInfo {
            data["extendInfo"] = extendInfo.toJsonOrNil()
        }

        if let extraParams = args.extraParams as? [String: Any] {
            params.merge(other: extraParams)
        }

        if !data.isEmpty {
            params["data"] = data
        }
        
        if self.editController?.generateAIContent ?? false {
            params["generateAIContent"] = true
        }
        
        callFunction(.btExecuteBitableCommands, tableId: args.tableID, params: params, completion: { result, error in
            if let dic = result as? [String: Any],
               let res = dic["result"] as? Int,
               res == -1 {
                DocsLogger.info("btExecuteBitableCommands return result == -1")
                resultHandler(BTExecuteFailReson.holding, error)
                return
            }
            //调试的时候发现返回的字典并不是[String: Int]，而是[String: Any]，所以guard let result = result as? [String: Int]一定不满足？@ zoujie 建议检查一下，疑似线上缺陷
            guard let result = result as? [String: Int],
                  let resultCode = result["reason"] else {
                DocsLogger.btError("[SYNC] js executeCommands failed with error: \(String(describing: error?.localizedDescription))")
                resultHandler(nil, error)
                return
            }
            DocsLogger.btInfo("[SYNC] js executeCommands result: \(resultCode)")
            // 成功 = 2, 失败 = 1， 无需执行 = 0
            resultHandler(BTExecuteFailReson(rawValue: resultCode), error)
        })
    }
    
    func openAiPrompt() {
        DocsLogger.btInfo("notify front end openAiPrompt")
        self.model?.jsEngine.callFunction(callBack, params: ["onBoardingKey": "base_field_ai_exinfo_mobile"], completion: nil)
    }
    
    func checkFieldTypeChangeAPI(args: BTFieldTypeChangeArgs, completion: @escaping ([String: Any])  -> Void) {
        var params: [String: Any] = [
            "fieldId": args.fieldId,
            "targetUIType": args.targetUIType
        ]
        
        callFunction(.btCheckFieldTypeChange, tableId: args.tableId, params: params, completion: { result, error in
            if let error = error {
                DocsLogger.btError("checkFieldTypeChangeAPI error:\(error)")
                return
            }
            guard let result = result as? [String: Any] else {
                DocsLogger.btError("checkFieldTypeChangeAPI error, has no result")
                return
            }
            completion(result)
        })
    }
    
    func showAiConfigFormAPI(args: BTShowAiConfigFormArgs, completion: @escaping () -> Void) {
        let params: [String: Any] = [
            "isNewField": args.isNewField,
            "baseId": args.baseId,
            "fieldId": args.fieldId,
            "fieldUIType": args.fieldUIType
        ]
        callFunction(.btShowAIConfigForm, tableId: nil, params: params, completion: { result, error in
            
            if let error = error {
                DocsLogger.btError("showAiConfigFormAPI error: \(error)")
                return
            }
            completion()
            DispatchQueue.main.async {
                self.setUIAttribute(maskToBounds: true)
            }
        })
    }
    
    func hideAiConfigFormAPI(args: BTHideAiConfigFormArgs, completion: @escaping () -> Void) {
        let params: [String: Any] = [
            "fieldId": args.fieldId,
            "tableId": args.tableId
        ]
        callFunction(.btHideAIConfigForm, tableId: nil, params: params, completion: { result, error in
            
            if let error = error {
                DocsLogger.btError("hideAIConfigFormAPI error: \(error)")
                return
            }
            completion()
            DispatchQueue.main.async {
                self.setUIAttribute(maskToBounds: false)
            }
        })
    }
    
    func checkConfirmAPI(args: BTCheckConfirmAPIArgs, resultHandler: @escaping (Result<CheckConfirmResult, Error>) -> Void) {
        let logParams: [String: Any] = [
            "type": "\(args.fieldInfo.compositeType?.uiType.rawValue)",
            "tableId": args.tableID,
            "viewId": args.viewID,
            "fieldId": args.fieldInfo.fieldID,
            "fieldIndex": args.fieldInfo.index
        ]
        DocsLogger.btInfo("[SYNC] js checkConfirmAPI params: \(logParams)")
        var data: [String: Any?] = [:]
        if let property = args.property {
            data["property"] = property
        }
        var params: [String: Any] = [
            "viewId": args.viewID,
            "tableId": args.tableID
        ]
        if let generateAIContent = args.generateAIContent {
            params["generateAIContent"] = generateAIContent
        }
        if let index = args.fieldInfo.index {
            params["index"] = index
        }
        if let fieldID = args.fieldInfo.fieldID {
            data["id"] = fieldID
            params["fieldId"] = fieldID
        }
        if let fieldName = args.fieldInfo.fieldName {
            data["name"] = fieldName
        }
        if let extendInfo = args.fieldInfo.extendInfo {
            params["fieldExtendBean"] = extendInfo
        }
        
        if let compositeType = args.fieldInfo.compositeType {
            data["type"] = compositeType.type.rawValue
            
            data["fieldUIType"] = compositeType.uiType.rawValue
            
            if let editModes = args.fieldInfo.allowEditModes,
               let editModesMaps = compositeType.getAllowEditModesMap(by: editModes) {
                data["allowedEditModes"] = editModesMaps
            }
        }
        
        if let fieldDescription = args.fieldInfo.fieldDescription {
            data["description"] = fieldDescription.toJSON() ?? ""
        }
        
        if let extendConfig = args.fieldInfo.extendConfig {
            params.merge(other: extendConfig)
        }
        
        if let extendInfo = args.fieldInfo.extendInfo {
            data["extendInfo"] = extendInfo.toJsonOrNil()
        }
        
        if let extraParams = args.extraParams as? [String: Any] {
            params.merge(other: extraParams)
        }
        if !data.isEmpty {
            params["data"] = data
        }
        guard let model = model else {
            resultHandler(.failure(CheckConfirmError.hasNoModel))
            DocsLogger.error("checkConfirm error ,model is nil")
            return
        }
        
        callFunction(.btCheckConfirm, tableId: args.tableID, params: params, completion: { result, error in
            if let error = error {
                DocsLogger.error("checkConfirmAPI error", error: error)
                resultHandler(.failure(error))
                return
            }
            guard let result = result as? [AnyHashable: Any] else {
                DocsLogger.error("checkConfirmAPI error, has no result")
                resultHandler(.failure(CheckConfirmError.hasNoResult))
                return
            }
            guard let typeString = result["type"] as? String else {
                DocsLogger.error("checkConfirmAPI error, has no type")
                resultHandler(.failure(CheckConfirmError.hasNoType))
                return
            }
            guard let type = CheckConfirmResultType(rawValue: typeString) else {
                DocsLogger.error("checkConfirmAPI error, new ConfirmResultType error, typeString is \(typeString)")
                resultHandler(.failure(CheckConfirmError.newCheckConfirmResultTypeError))
                return
            }
            let res = CheckConfirmResult(type: type, extra: result["extra"] as? [AnyHashable: Any])
            DocsLogger.btInfo("[SYNC] js checkConfirmAPI result: \(typeString)")
            resultHandler(.success(res))
        })
    }

    func getBitableCommonData(args: BTGetBitableCommonDataArgs, resultHandler: @escaping (Any?, Error?) -> Void) {
        var params: [String: Any] = ["type": args.type.rawValue]

        if let tableID = args.tableID {
            params["tableId"] = tableID
        }

        if let viewID = args.viewID {
            params["viewId"] = viewID
        }

        if let fieldID = args.fieldID, !fieldID.isEmpty {
            params["fieldId"] = fieldID
        }

        DocsLogger.btInfo("[SYNC] js getBitableCommonData params: \(params.jsonString?.encryptToShort ?? "")")
        
        if let extraParams = args.extraParams {
            params.merge(other: extraParams)
        }

        callFunction(.btGetBitableCommonData, tableId: args.tableID, params: params, completion: { result, error in
            if let error = error {
                DocsLogger.btError("[SYNC] js getBitableCommonData failed with error: \(error.localizedDescription)")
                resultHandler(nil, error)
                return
            }
            resultHandler(result, nil)
        })
    }
    
    // 在 docx 中，可能会有多个不同的 bitable 实例，这里的 callback，必须传入对应 bitable 中的一个 tableId，用于在回调时路由到对应的 bitable
    func callFunction(_ function: DocsJSCallBack, tableId: String?, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        var params = params ?? [:]
        if params["tableId"] == nil, let tableId = tableId {
            params["tableId"] = tableId
        }
        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }

    func getPermissionData(args: BTGetPermissionDataArgs, resultHandler: @escaping (Any?, Error?) -> Void) {
        var queryArr: [[String: Any]] = []
        var query: [String: Any] = [
            "entity": args.entity
        ]

        var commonParams: [String: Any] = [:]

        if let tableID = args.tableID {
            commonParams["tableId"] = tableID
        }

        if let viewID = args.viewID {
            commonParams["viewId"] = viewID
        }

        if let recordID = args.recordID {
            commonParams["recordId"] = recordID
        }

        if let fieldIDs = args.fieldIDs {
            //批量请求
            for (index, fieldId) in fieldIDs.enumerated() {
                guard index < args.operation.count else {
                    return
                }
                commonParams["fieldId"] = fieldId
                query["param"] = commonParams
                query["operation"] = args.operation[index].rawValue
                queryArr.append(query)
            }
        } else {
            query["param"] = commonParams
            query["operation"] = args.operation[0].rawValue
            queryArr.append(query)
        }
        
        let params: [String: Any] = ["queryArr": queryArr]

        DocsLogger.btInfo("[SYNC] js getPermissionData params: \(params.jsonString?.encryptToShort ?? "")")
        callFunction(.btGetPermissionData, tableId: args.tableID, params: params, completion: { result, error in
            if let error = error {
                DocsLogger.btError("[SYNC] js getPermissionData failed with error: \(error.localizedDescription)")
                resultHandler(nil, error)
                return
            }
            resultHandler(result, nil)
        })
    }

    func saveField(args: BTSaveFieldArgs) {
        let target: [String: Any] = [
            "baseId": args.currentBaseID,
            "tableId": args.currentTableID,
            "viewId": args.currentViewID,
            "recordId": args.currentRecordID,
            "fieldId": args.currentFieldID
        ]
        var payload: [String: Any?] = [
            "target": target,
            "value": args.value
        ]
        if let editType = args.editType {
            payload["type"] = editType.rawValue
        }
        let params: [String: Any] = [
            "action": BTActionFromUser.editRecord.rawValue,
            "baseId": args.originBaseID,
            "tableId": args.originTableID,
            "payload": payload
        ]

        var logParams: [String: Any] = params
        // 去除value打印，铭感日志治理
        let logPayload: [String: Any?] = [
            "target": target
        ]
        logParams["payload"] = logPayload
        DocsLogger.btInfo("[SYNC] js editRecord params: \(logParams.jsonString?.encryptToShort ?? "")")
        callFunction(DocsJSCallBack(rawValue: args.callback), tableId: args.currentTableID, params: params, completion: { _, error in
            if let error = error {
                DocsLogger.btError("[SYNC] js editRecord failed with error: \(error.localizedDescription)")
                return
            }
        })
        if cardVC?.viewModel.mode == .addRecord || cardVC?.viewModel.mode == .submit {
            cardVC?.hasUnSubmitCellValue = true
        }
        if Thread.isMainThread {
            triggerPassiveRecordSubscribeIfNeeded(recordId: args.currentRecordID)
        } else {
            DispatchQueue.main.async {
                self.triggerPassiveRecordSubscribeIfNeeded(recordId: args.currentRecordID)
            }
        }
    }
    
    func quickAddViewClick(args: BTSaveFieldArgs) {
        let params: [String: Any] = [
            "action": BTActionFromUser.createGroup.rawValue,
            "baseId": args.originBaseID,
            "tableId": args.originTableID,
            "payload": [
                "target": [
                    "tableId": args.currentTableID,
                    "viewId": args.currentViewID,
                    "recordId": args.currentRecordID,
                    "fieldId": args.currentFieldID
                ]
            ]
        ]

        DocsLogger.btInfo("[SYNC] quickAddViewClick params: \(params.jsonString?.encryptToShort ?? "")")
        model?
            .jsEngine
            .callFunction(
                DocsJSCallBack(rawValue: args.callback),
                params: params,
                completion: { _, error in
                    if let error = error {
                        DocsLogger.error("[SYNC] js quickAddViewClick failed)", error: error)
                    }
                }
            )
    }

    func createAndLinkRecord(args: BTCreateAndLinkRecordArgs, resultHandler: ((Result<Any?, Error>) -> Void)?) {
        let target: [String: Any] = [
            "baseId": args.targetLocation.baseID,
            "tableId": args.targetLocation.tableID,
            "fieldId": args.targetLocation.fieldID
        ]
        let source: [String: Any] = [
            "baseId": args.sourceLocation.baseID,
            "tableId": args.sourceLocation.tableID,
            "recordId": args.sourceLocation.recordID,
            "fieldId": args.sourceLocation.fieldID
        ]
        var payload: [String: Any] = [
            "target": target,
            "linkSourceInfo": source
        ]

        if let value = args.value {
            payload["value"] = value
        }

        let params: [String: Any] = [
            "action": BTActionFromUser.addLinkedRecord.rawValue,
            "baseId": args.originBaseID,
            "tableId": args.originTableID,
            "payload": payload
        ]
        
        let logParams: [String: Any] = ["target": target,
                                        "linkSourceInfo": source,
                                        "baseId": args.originBaseID,
                                        "tableId": args.originTableID]

        DocsLogger.btInfo("[SYNC] js addLinkedRecord with primary field params: \(logParams.jsonString?.encryptToShort ?? "")")
        callFunction(DocsJSCallBack(rawValue: args.callback), tableId: args.originTableID, params: params, completion: { data, error in
            if let error = error {
                DocsLogger.btError("[SYNC] js addLinkedRecord failed with error: \(error.localizedDescription)")
                resultHandler?(.failure(error))
                return
            }
            
            resultHandler?(.success(data))
        })
    }

    func toggleHiddenFieldsDisclosure(args: BTHiddenFieldsDisclosureArgs) {
        DocsLogger.btInfo("[SYNC] js did toggle hidden fields to \(args.toDisclosed ? "disclosed" : "non-disclosed")")
        let param: [String: Any] = [
            "action": BTActionFromUser.toggleHiddenFieldsDisclosure.rawValue,
            "baseId": args.originBaseID,
            "tableId": args.originTableID,
            "payload": [
                "baseId": args.currentBaseID,
                "tableId": args.currentTableID,
                "isDisclosed": args.toDisclosed
            ]
        ]
        callFunction(DocsJSCallBack(rawValue: args.callback), tableId: args.originTableID, params: param, completion: { _, error in
            if let error = error {
                DocsLogger.btError("[SYNC] js toggle hidden fields failed with error: \(error.localizedDescription)")
                return
            }
        })
    }

    func deleteRecord(args: BTDeleteRecordArgs) {
        let target: [String: Any] = [
            "baseId": args.currentBaseID,
            "tableId": args.currentTableID,
            "viewId": args.currentViewID,
            "recordId": args.recordID
        ]
        let payload: [String: Any?] = [
            "target": target
        ]
        let params: [String: Any] = [
            "action": BTActionFromUser.deleteRecord.rawValue,
            "baseId": args.originBaseID,
            "tableId": args.originTableID,
            "payload": payload
        ]
        
        DocsLogger.btInfo("[SYNC] js deleteRecord params: \(params.jsonString?.encryptToShort ?? "")")
        callFunction(DocsJSCallBack(rawValue: args.callback), tableId: args.originTableID, params: params, completion: { _, error in
            if let error = error {
                DocsLogger.btError("[SYNC] js deleteRecord failed with error: \(error.localizedDescription)")
                return
            }
        })
    }

    ///用户在选择面板选择通知
    func saveNotifyStrategy(notifiesEnabled: Bool) {
        self.notifiesEnable = notifiesEnabled
    }

    ///获取当前文档上次用户通知选择，默认是true
    func obtainLastNotifyStrategy() -> Bool {
        return self.notifiesEnable
    }

    /// 分组统计分页数据获取
    /// - Parameters:
    ///   - anchorId: 一级分组ID
    ///   - childrenAnchorId: 二级分组ID
    ///   - direction: 拉取数据的方向，"top"/"bottom"
    ///   - resultHandler: 请求结果回调
    func obtainGroupData(anchorId: String,
                         childrenAnchorId: String?,
                         direction: String,
                         tableId: String,
                         resultHandler: @escaping (BTGroupingStatisticsObtainGroupData?, Error?) -> Void) {
        DocsLogger.btInfo("[SYNC] js obtainGroupData anchorId:\(anchorId) childrenAnchorId:\(String(describing: childrenAnchorId)) direction:\(direction)")
        var params: [String: Any] = [
            "anchorId": anchorId,
            "direction": direction
        ]

        if let childrenAnchorId = childrenAnchorId {
            params["childrenAnchorId"] = childrenAnchorId
        }

        callFunction(.obtainGroupData, tableId: tableId, params: params, completion: { data, error in
            guard error == nil else {
                DocsLogger.btError("[SYNC] js obtainGroupData failed")
                return
            }

            guard let dicData = data as? [String: Any],
                  let result = BTGroupingStatisticsObtainGroupData.deserialize(from: dicData) else {
                      let error = NSError(domain: "bitable", code: 1002, userInfo: nil)
                      DocsLogger.btError("[SYNC] js obtainGroupData failed, data is \(String(describing: data))")
                      resultHandler(nil, error)
                      return
                  }
            resultHandler(result, nil)
        })
    }

    /// bitable异步数据请求接口，请求发送后等待前端回调response传回数据
    func asyncJsRequest(biz: AsyncJSRequestBiz,
                        funcName: DocsJSCallBack,
                        baseId: String,
                        tableId: String,
                        params: [String: Any],
                        overTimeInterval: Double?,
                        responseHandler: @escaping(Result<BTAsyncResponseModel, BTAsyncRequestError>) -> Void,
                        resultHandler: ((Result<Any?, Error>) -> Void)?) {        
        var currentParams = params
        let requestId = UUID().uuidString
        currentParams["requestId"] = requestId
        currentParams["biz"] = biz.rawValue
        currentParams["baseId"] = baseId

        var requestModel = BTAsyncRequestModel()
        requestModel.responseHandler = responseHandler
        let timer = Timer(timeInterval: overTimeInterval ?? 20, repeats: false) { [weak self] _ in
            requestModel.timer?.invalidate()
            requestModel.timer = nil
                    
            let error = BTAsyncRequestError(code: .requestTimeOut,
                                            domain: "bitable",
                                            description: "request time out")
            responseHandler(.failure(error))
            self?.asyncRequestHandler.removeValue(forKey: requestId)
        }
        RunLoop.main.add(timer, forMode: .common)
        requestModel.timer = timer
        //保存response callback
        self.asyncRequestHandler.updateValue(requestModel, forKey: requestId)
        DocsLogger.btInfo("[SYNC] js asyncJsRequest requestId: \(requestId.encryptToShort) baseId:\(baseId.encryptToShort)")
        
        callFunction(funcName, tableId: tableId, params: currentParams, completion: { (data, error) in
            if let error = error {
                DocsLogger.btError("[SYNC] js asyncJsRequest failed with error: \(error.localizedDescription)")
                requestModel.timer?.invalidate()
                requestModel.timer = nil
                self.asyncRequestHandler.removeValue(forKey: requestId)
                resultHandler?(.failure(error))
                return
            }

            resultHandler?(.success(data))
        })
    }

    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    func cardGetCopyPermission(_ tokens: (baseToken: String, objToken: String?)) -> BTCopyPermission? {
        if UserScopeNoChangeFG.YY.bitableReferPermission {
            // 全量后此方法可删除
            return nil
        }
        guard model != nil else {
            return nil
        }
        let validation = CCMSecurityPolicyService.syncValidate(
            entityOperate: .ccmCopy,
            fileBizDomain: .ccm,
            docType: .bitable,
            token: tokens.baseToken
        )
        guard validation.allow else {
            switch validation.validateSource {
            case .fileStrategy:
                DocsLogger.error("copy validation failed due to fileStrategy")
                return .refuseByFileStrategy
            case .securityAudit:
                DocsLogger.error("copy validation failed due to securityAudit")
                return .refuseBySecurityAudit
            case .dlpDetecting, .dlpSensitive, .ttBlock, .unknown:
                DocsLogger.info("unknown type or dlp type")
                return .allow
            }
        }
        if hasCopyPermissionDeprecated {
            return .allow
        } else if !AdminPermissionManager.adminCanCopy(docType: hostDocInfo.inherentType, token: tokens.baseToken) {
            return .refuseByAdmin
        } else if let status = DlpManager.status(with: tokens.baseToken, type: hostDocInfo.inherentType, action: .COPY) as? DlpCheckStatus, status != .Safe {
            return .refuseByDlp(status)
        } else if let encryptId = ClipboardManager.shared.getEncryptId(token: tokens.objToken), encryptId.count > 0 {
            return .allowBySingleDocumentProtect
        } else {
            return .refuseByUser
        }
    }
    
    func didClickCTANoticeMore(with acitonParmas: BTActionParamsModel) {
        self.callFunction(DocsJSCallBack(rawValue: acitonParmas.callback),
                                         tableId: acitonParmas.data.tableId,
                                          params: [
                                                   "action": BTActionFromUser.clickTip.rawValue,
                                                   "tableId": acitonParmas.data.tableId,
                                                   "transactionId": acitonParmas.transactionId,
                                                   "payload": ["topTipType": acitonParmas.data.topTipType.rawValue]
                                                  ],
                                          completion: nil)
    }
    
    func getItemViewData(type: BTItemViewDataType,
                         tableId: String,
                         payload: [String: Any],
                         resultHandler: ((Result<Any?, Error>) -> Void)?) {
        var params: [String: Any] = [:]
        params["type"] = type.rawValue
        params["payload"] = payload
        callFunction(DocsJSCallBack.getItemViewData,
                     tableId: tableId,
                     params: params,
                     completion: { (data, error) in
            if let error = error {
                resultHandler?(.failure(error))
                DocsLogger.btError("[SYNC] js obtainGroupData failed")
                return
            }

            resultHandler?(.success(data))
        })
    }
    
    func triggerPassiveRecordSubscribeIfNeeded(recordId: String) {
        guard UserScopeNoChangeFG.PXR.bitableRecordCloseAutoSubscribe == false else {
            DocsLogger.btInfo("passive record subscribe fg is closed")
            return
        }
        guard let cardController = cardVC, let card = cardController.currentCard else {
            DocsLogger.btInfo("passive record subscribe is forbidden because of card info")
            return
        }
        guard recordEnableSubscribe(baseContext: cardController.baseContext, viewMode: card.recordModel.viewMode) else {
            DocsLogger.btInfo("passive record subscribe is forbidden because of context")
            return
        }
        guard cardController.isCloseRecordAutoSubscribe == false else {
            DocsLogger.btInfo("passive record subscribe is forbidden because of user close autoSubscribe")
            return
        }
        let subscribeStatus = getRecordSubscribeStatusFromLocalCache(recordId: recordId)
        let autoStatus = getRecordAutoSubscribeStatusFromLocalCache(recordId: recordId)
        if subscribeStatus == .unSubscribe && autoStatus == .editAutoSubDefault {
            cardController.recordSubscribe(recordId: recordId, isSubscribe: true, isPassive: true, scene: .normal, completion: nil)
        } else {
            DocsLogger.btInfo("passive record subscribe is forbidden because of \(subscribeStatus) and \(autoStatus)")
        }
    }
    
    func triggerRecordSubscribeForSubmitIfNeeded(recordId: String) {
        guard UserScopeNoChangeFG.PXR.bitableRecordCloseAutoSubscribe == false else {
            DocsLogger.btInfo("passive record subscribe fg is closed")
            return
        }
        guard let cardController = cardVC else {
            DocsLogger.btInfo("passive record subscribe is forbidden because of card info")
            return
        }
        guard recordEnableSubscribe(baseContext: cardController.baseContext, viewMode: cardController.viewModel.mode) || cardController.viewModel.mode == .addRecord else {
            DocsLogger.btInfo("passive record subscribe is forbidden because of context")
            return
        }
        cardController.recordSubscribe(recordId: recordId, isSubscribe: true, isPassive: true, scene: .addRecord, completion: nil)
    }
}

enum BTFieldEditType: String {
    // 默认，代表全量覆盖更新
    case cover
    // 下面两个代表增量更新，目前只用在附件字段
    case add
    case preAdd
    case delete
    // 附件上传是点击submit，上传前前端不知道是否有选择了附件，所以增加两个local事件
    case localAdd
    case localDelete
}

enum BTEventType: String {
    case colorList = "ColorList" // 颜色id映射
    case buttonColorList = "ButtonColorList" //按钮字段颜色配置
    case colorGroup = "ColorGroup" // 取色板位置
    case getNewOptionId // 获取新增选项字段id
    case getRandomColor // 获取新增选项字段随机颜色
    case getFieldConfigMeta //获取字段的基础属性，包括字段名、类型、字段格式列表等
    case getNewFieldName //获取新建字段的默认名字
    case getNewFieldId //生成fieldId
    case getTableNames //获取当前bitable文档所有的table
    case getFieldList //获取操作条件
    case getNewConditionIds //生成条件ID
}

enum BTCommands: String {
    case setFieldAttr = "SetFieldAttr" // 更改字段属性
    case deleteField = "DeleteField" // 删除字段
    case addField = "AddField" // 新增字段
    case moveField = "MoveField" // 移动字段
    case setExType = "SetExType" // 设置 tableExInfo
}

//权限请求类型
enum OperationType: String {
    case addable
    case deletable
    case editable
    case movable
    case visible
    case copyable
    case pastable
    case cuttable
    case lockable
    case localEditable
}

struct CheckConfirmResult {
    let type: CheckConfirmResultType
    let extra: [AnyHashable: Any]?
}
enum CheckConfirmResultType: String {
    case SetFieldAttr
    case ConfirmConvertType
    case ConfirmKeepNoExistData
    case ConfirmConvertPeople
    case ConfirmExtendFieldDelete
    case ConfirmConvertPeopleForStage
    case ConfirmAIGenerate
}
enum CheckConfirmError: String, Error {
    case hasNoModel
    case hasNoResult
    case hasNoType
    case newCheckConfirmResultTypeError
}

enum BTExecuteFailReson: Int {
    case holding = -9999 // 为避免破坏调用链路result的-1在这里进行数据传递，为了避免遇到-1冲突，这里特意写个-9999
    case unknown = 0
    case tableError = 1 //操作table不存在
    case actionError = 2 //action校验失败
    case notSupport = 3 //对不支持的field，view进行操作
    case nameRepeat = 4 //table，view名字重复
    case lastOne = 5 //最后一个，无法删除
    case fieldTypeNotMatch = 6 //字段类型不匹配
    case recordCountExceeded = 8 //行数超出
    case fieldCountExceeded = 9 //列数超出
    case wrongOptions = 10 //传递的参数问题
    case fieldError = 11 //操作的field不存在
}

enum BTEmitEvent: String {
    case dataLoaded
}

enum BTAsyncRequestRouter: String, HandyJSONEnum {
    case getBitableFieldOptions
    case getCardList
    case getLinkCardList
    case getRecordsData
    case getFieldUserOptions
    case getFieldLinkOptions
    case getFieldLinkByRecordIds
    case getFieldGroupOptions
    case clickButtonField
    case getFieldExtendInfo
    case getExistExtendableFields
    case updateFieldExtendData
    case getFieldExtendCellTooltip
    case getTableLayoutSetting
    case Unkonwn
}

enum StageAsyncRequestRouter: String {
    case markStepDone
    case markStageCanceled
    case revertStep
    case markStageRecover
}

enum BTConditionType: String, HandyJSONEnum, SKFastDecodableEnum {
    case Is = "is" //等于
    case IsNot = "isNot" //不等于
    case Contains = "contains" //包含
    case DoesNotContain = "doesNotContain" //不包含
    case IsEmpty = "isEmpty" //为空
    case IsNotEmpty = "isNotEmpty" //不为空
    case IsGreater = "isGreater" //大于
    case IsGreaterEqual = "isGreaterEqual" //大于等于
    case IsLess = "isLess"//小于
    case IsLessEqual = "isLessEqual" //小于等于
    case Unkonwn //未知条件

    //无下级条件
    var hasNotNextValueType: Bool {
        return self == .IsEmpty || self == .IsNotEmpty
    }

    var tracingString: String {
        switch self {
        case .Is:
            return "is"
        case .IsNot:
            return "is_not"
        case .Contains:
            return "contains"
        case .DoesNotContain:
            return "not_contain"
        case .IsEmpty:
            return "is_empty"
        case .IsNotEmpty:
            return "not_empty"
        case .IsGreater:
            return "greater"
        case .IsGreaterEqual:
            return "greater_or_equal"
        case .IsLess:
            return "less"
        case .IsLessEqual:
            return "less_or_equal"
        case .Unkonwn:
            return ""
        }
    }
}

enum BTConjunctionType: String, CaseIterable {
    case And = "and" //所有
    case Or = "or" //任一
    
    var text: String {
        switch self {
        case .And: return BundleI18n.SKResource.Bitable_Relation_MeetAllCondition
        case .Or: return BundleI18n.SKResource.Bitable_Relation_MeetAnyCondition
        }
    }
}

enum CardPresentMode {
    // card 在base文档区域 右侧栏显示
    case card
    // card 在base文档区域 全屏显示
    case fullScreen
}
