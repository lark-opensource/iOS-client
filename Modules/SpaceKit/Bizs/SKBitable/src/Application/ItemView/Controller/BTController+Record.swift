//
// Created by duanxiaochen.7 on 2020/3/16.
// Affiliated with DocsSDK.
//
// Description:
// swiftlint:disable file_length


import Foundation
import UIKit
import EENavigator
import LarkUIKit
import SKCommon
import SKInfra
import SKBrowser
import SKUIKit
import SKFoundation
import SKResource
import RxSwift
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignDialog
import SpaceInterface
import LarkLocationPicker
import UniverseDesignActionPanel
import UniverseDesignFont
import UniverseDesignMenu
import UniverseDesignIcon
import LarkSetting
import SpaceInterface

// MARK: - BTRecordDelegate
protocol BTRecordDelegate: AnyObject {
    var baseContext: BaseContext { get }
    var isTransitioningSize: Bool { get }
    var isPresenterRole: Bool { get }
    var cardPresentMode: CardPresentMode { get }
    var holdDataProvider: BTHoldDataProvider? { get }
    func didClickHeaderButton(action: BTActionFromUser)
    func didCloseBanner()
    func didClickMoreButton(record: BTRecordModel,sourceView: UIView)
    func didClickShareButton(recordID: String, recordTitle: String, sourceView: UIView)
    func recordViewOperateCover(view: BTRecord, sourceView: UIView)
    func didClickUser(_ userId: String)
    func logAttachmentEvent(action: String, attachmentCount: Int?)
    func newLogAttachmentEvent(_ event: AttachmentLogEvent)
    func logAttachmentOperate(action: String)
    func previewAttachments(_: [BTAttachmentModel], atIndex: Int)
    func previewAttachments(_: [BTAttachmentModel], atIndex: Int, inFieldWithID: String)
    func deleteAttachment(data: BTAttachmentModel, inFieldWithID: String)
    func previewLocalAttachments(_: [PendingAttachment.LocalFile], atIndex: Int)
    func deletePendingAttachment(data: PendingAttachment)
    func cancelUploadingAttachment(data: BTMediaUploadInfo)
    func openLinkedRecord(withID: String, allLinkedRecordIDs: [String], linkFieldModel: BTFieldModel)
    func beginModifyLinkage(fromLinkField: BTFieldLinkCellProtocol)
    func cancelLinkage(fromFieldID: String, toRecordID: String, inFieldModel: BTFieldModel)
    func updateCheckboxValue(inFieldWithID: String, toSelected: Bool)
    func showDescriptionPanel(withAttrText: NSAttributedString, forFieldID: String, fieldName: String, fromButton: UIButton)
    func setDescriptionLimitState(forFieldID: String, to: Bool)
    func didTapView(withAttributes: [NSAttributedString.Key: Any], inFieldModel: BTFieldModel?)
    func didDoubleTap(_ sender: BTRecord, field: BTFieldModel)
    func openUrl(_ url: String, inFieldModel: BTFieldModel)
    func startEditing(_: BTFieldCellProtocol, newEditAgent: BTBaseEditAgent?)
    func didEndEditingField()
    func didClickHiddenFieldsDisclosureItem(toDisclosed: Bool)
    func didClickDelete(sourceView: UIView)
    func currentEditPanelRect(in: BTRecord) -> CGRect
    func saveEditing(animated: Bool)
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, setViewScrollable: (Bool) -> Void)
    func showDeleteAlert(_ alert: UIViewController)
    func generateHapticFeedback()
    func didClickSubmitForm()
    func didScrollUp()
    func didScrollDown()
    func didScroll(_ scrollView: UIScrollView)
    func didScrollToField(id: String, recordID: String)
    func didEndScrollingAnimation(in: BTRecord)
    func isCurrentCard(id: String) -> Bool
    func getCopyPermission() -> BTCopyPermission?
    func textViewOfField(_ field: BTFieldModel, shouldAppyAction action: BTTextViewMenuAction) -> Bool
    func presentViewController(_ vc: UIViewController)
    func didClickGeoLocation(_ geoLocation: BTGeoLocationModel, on field: BTFieldCellProtocol)
    func track(event: String, params: [String: Any])
    func didClickRetry(request: BTGetCardListRequest)
    func didClicksubmitTopTips() // 表单顶部先填写再添加记录提示
    func didClickChatter(_ model: BTCapsuleModel)
    ///更新当前按钮字段的状态
    func updateButtonFieldStatus(to status: BTButtonFieldStatus, inRecordWithID recordID: String, inFieldWithID fieldID: String)
    /// 点击了button字段
    func didClickButtonField(inRecordWithID recordID: String, inFieldWithID fieldID: String)
    /// 点击了顶部CTA提示按钮
    func didClickCTANoticeMore()
    /// 点击了阶段字段
    func didClickStageField(with recordID: String, fieldModel: BTFieldModel)
    /// 点击阶段详情的终止
    func didClickStageDetailCancel(sourceView: UIView, fieldModel: BTFieldModel, cancelOptionId: String)
    /// 点击阶段详情的阶段完成
    func didClickStageDetailDone(fieldModel: BTFieldModel, currentOptionId: String)
    /// 点击阶段详情的阶段重置阶段
    func stageDetailFieldClickRevert(sourceView: UIView, fieldModel: BTFieldModel, currentOptionId: String)
    /// 点击阶段详情的阶段恢复流程
    func stageDetailFieldClickRecover(fieldModel: BTFieldModel)
    // 切换itemView
    func didClickTab(index: Int, recordID: String)
    // 流程字段切换流程
    func didChangeStage(recordID: String,
                        stageFieldId: String,
                        selectOptionId: String)
    
    // 切换卡片
    func switchCardToRight()
    func switchCardToLeft()
    
    // 获取当前卡片的global Index, 总的卡片数量
    func getCurrentRecordIndex() -> (current: Int, total: Int)?
    
    // recordHeader 左上角的关闭icon的iconType
    func getRecordHeaderCloseIconType() -> CloseIconType
    
    // 隐藏右下角的翻页器
    func hideSwitchCardBottomPanelView(hidden: Bool)
    
    
    func shouldHighlightField(recordId: String, fieldId: String) -> Bool
    
    var shouldResetContentOffsetForReuse: Bool { get }
    
    ///订阅&&取消订阅
    func recordSubscribe(recordId: String, isSubscribe: Bool, isPassive: Bool, scene: BTViewModel.SubscribeScene, completion: ((BTRecordSubscribeCode) -> Void)?)
    ///获取远端订阅状态
    func fetchRemoteRecordSubscribeStatus(recordId: String, completion: ((BTRecordSubscribeStatus) -> Void)?)
    ///获取本地订阅状态
    func fetchLocalRecordSubscribeStatus(recordId: String) -> BTRecordSubscribeStatus
    ///卡片是否支持订阅功能
    func recordEnableSubscribe(record: BTRecordModel) -> Bool
    /// 是否可以编辑封面
    func canEditAttachmentCover() -> Bool

    // 质量埋点
    func isBitableReady() -> Bool
    func currentRecordId() -> String
    func hasReportTTU() -> Bool
    func hasReportTTV() -> Bool
    func update(hasTTU: Bool)
    func update(hasTTV: Bool)
    
    func didClickCatalogueBaseName()
    func didClickCatalogueTableName()
}

extension BTController {
    
    /// 打开关联卡片最多层级
    static var linkedRecordMaxCardLevel: Int { 10 }
    
    fileprivate static let moreMenuWidth: CGFloat = 180.0
}

extension BTController: BTCardEmptyViewDelegate {
    
    func onEmptyPrimaryButtonClick(_ sender: BTCardEmptyView) {
        if sender.state == .recordWillBeAddedSilently {
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "add_another"
            trackParams["target"] = "none"
            DocsTracker.newLog(enumEvent: .bitableAddRecordTimeoutClick, parameters: trackParams)
        }
        
        switch sender.state {
        case .none, .tableNotExist, .noRecordAddPerm:
            break
        case .recordWillBeAddedSilently, .recordAddSuccessButNoViewPerm, .recordAddSuccessButNoShareToken:
            sender.state = .none
            didClickHeaderButton(action: .continueSubmit)
        }
    }
    
    func onEmptySecondaryButtonClick(_ sender: BTCardEmptyView) {
        if sender.state == .recordWillBeAddedSilently {
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "open_table"
            trackParams["target"] = "none"
            DocsTracker.newLog(enumEvent: .bitableAddRecordTimeoutClick, parameters: trackParams)
        }
        
        switch sender.state {
        case .none, .tableNotExist, .noRecordAddPerm:
            break
        case .recordWillBeAddedSilently, .recordAddSuccessButNoViewPerm, .recordAddSuccessButNoShareToken:
            let token = self.viewModel.actionParams.data.baseId
            let url = DocsUrlUtil.url(type: .bitable, token: token)
                .docs
                .addOrChangeEncodeQuery(
                    parameters: [
                        "table": self.viewModel.actionParams.data.tableId,
                        "view": self.viewModel.actionParams.data.viewId,
                        "record": self.viewModel.actionParams.data.recordId,
                        "from": OpenDocsFrom.other.rawValue,
                        CCMOpenTypeKey: CCMOpenType.recordMessage.rawValue
                    ]
                )
            Navigator.shared.push(url, from: self)
        }
    }
    
    func onEmptyBackButtonClick(_ sender: BTCardEmptyView) {
        if sender.state == .recordWillBeAddedSilently {
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "back"
            trackParams["target"] = "none"
            DocsTracker.newLog(enumEvent: .bitableAddRecordTimeoutClick, parameters: trackParams)
        }
        
        switch sender.state {
        case .none, .tableNotExist, .noRecordAddPerm:
            break
        case .recordWillBeAddedSilently, .recordAddSuccessButNoViewPerm, .recordAddSuccessButNoShareToken:
            closeThisCard()
        }
    }
}

extension BTController: BTRecordDelegate {
    var holdDataProvider: BTHoldDataProvider? {
        return viewModel.dataService?.holdDataProvider
    }
    
    func canEditAttachmentCover() -> Bool {
        return viewModel.canEditAttachmentCover
    }

    func hasReportTTU() -> Bool {
        return viewModel.hasTTU
    }

    func hasReportTTV() -> Bool {
        return viewModel.hasTTV
    }

    func update(hasTTU: Bool) {
        viewModel.hasTTU = hasTTU
    }

    func update(hasTTV: Bool) {
        viewModel.hasTTV = hasTTV
    }

    func isBitableReady() -> Bool {
        return viewModel.bitableIsReady
    }

    func currentRecordId() -> String {
        return viewModel.currentRecordID
    }
    
    func isCurrentCard(id: String) -> Bool {
        return id == currentCard?.recordID
    }
    
    var isPresenterRole: Bool {
        return spaceFollowAPIDelegate?.followRole == .presenter
    }
    
    var cardPresentMode: CardPresentMode {
        return self.currentCardPresentMode
    }
    
    func showDeleteAlert(_ alert: UIViewController) {
        Navigator.shared.present(alert, from: self)
    }
    
    func shouldHighlightField(recordId: String, fieldId: String) -> Bool {
        temporarilyHighlightField?.recordId == recordId && temporarilyHighlightField?.fieldId == fieldId
    }
    
    var shouldResetContentOffsetForReuse: Bool {
        // 字段定位滚动和高亮结束前，record reuse 不重置字段列表的 offset，防止卡片抖动
        hasDoneInitialScroll && temporarilyHighlightField == nil
    }
    
    func handlePanGesture(_ gesture: UIPanGestureRecognizer, setViewScrollable: (Bool) -> Void) {
        BTItemViewAttachmentCoverHelper.attachmentCoverHandlePanGesture(gesture, currentCard: currentCard)
        if UserScopeNoChangeFG.ZJ.btCardReform {
            dismissTransition.handlePanGesture(gesture)
        } else {
            dismissTransition.handlePanGesture(gesture, setViewScrollable: { scrollable in
                setViewScrollable(scrollable)
                cardsView.isScrollEnabled = scrollable
            })
        }
    }
    
    func saveEditing(animated: Bool) {
        currentEditAgent?.stopEditing(immediately: !animated, sync: true)
    }
    
    func currentEditPanelRect(in record: BTRecord) -> CGRect {
        guard let editingAgent = currentEditAgent, let currentCard = currentCard else {
            return .zero
        }
        let editPanelRectInView = editingAgent.editingPanelRect
        return currentCard.convert(editPanelRectInView, from: view)
    }

    func didClickHiddenFieldsDisclosureItem(toDisclosed flag: Bool) {
        viewModel.nativeUpdateHiddenFields(toDisclosed: flag)
        viewModel.notifyModelUpdate()
        viewModel.jsUpdateHiddenFields(toDisclosed: flag)

        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = "hidden_fields"
        trackParams["target"] = "none"
        trackParams["status"] = flag ? "open" : "close"
        
        if UserScopeNoChangeFG.ZJ.btCardReform {
            trackParams["version"] = "v2"
            trackParams["card_type"] = currentCardPresentMode == .card ? "card" : "drawer"
        }
        
        DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: trackParams)
    }
    

    func didClickDelete(sourceView: UIView) {
        //actionsheet仅支持竖屏，在弹出之前先转到竖屏
        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
        
        let tips = BundleI18n.SKResource.Doc_Block_DeleteRecordQuery
        let textLabel = UILabel()
        textLabel.font = UDFont.title4
        textLabel.text = tips
        textLabel.numberOfLines = 1

        //24为文字两边的边距
        let preferredContentWidth = textLabel.intrinsicContentSize.width + 24
        let source = UDActionSheetSource(sourceView: sourceView,
                                         sourceRect: sourceView.bounds,
                                         preferredContentWidth: 304)

        var config: UDActionSheetUIConfig
        if SKDisplay.pad {
            config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
        } else {
            config = UDActionSheetUIConfig(isShowTitle: true)
        }
        
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(tips)
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Common_ButtonDelete, textColor: UDColor.functionDangerContentDefault) { [weak self] in
            guard let self = self else {
                return
            }
            let recordID = self.viewModel.currentRecordID
            self.viewModel.deleteRecord(recordID: recordID)
            var trackParams = ["click": "delete_record",
                               "target": "none"]
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                trackParams["version"] = "v2"
                trackParams["card_type"] = self.currentCardPresentMode == .card ? "card" : "drawer"
            }
            
            self.track(event: DocsTracker.EventType.bitableCardClick.rawValue, params: trackParams)
        }
        actionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel)
        self.deleteActionSheet = actionSheet
        showDeleteAlert(actionSheet)
    }

    
    func didClickHeaderButton(action: BTActionFromUser) {
        switch action {
        case .exit: 
            if viewModel.mode == .addRecord {
                self.closeAddRecord(closeConfirm: { [weak self] in
                    self?.closeThisCard()
                })
                return
            } else if viewModel.mode == .submit, UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
                self.closeAddRecord(closeConfirm: { [weak self] in
                    self?.closeThisCard()
                })
                return
            }
            closeThisCard() // exit 事件统一在 dismiss 中上报
        default:
            if action == .confirm {
                currentEditAgent?.stopEditing(immediately: true, sync: true)
            }
            
            delegate?.cardDidClickHeaderButton(self,
                                               action: action,
                                               currentBaseID: viewModel.actionParams.data.baseId,
                                               currentTableID: viewModel.actionParams.data.tableId,
                                               originBaseID: viewModel.actionParams.originBaseID,
                                               originTableID: viewModel.actionParams.originTableID,
                                               callback: viewModel.actionParams.callback)
        }
    }
    
    func didClicksubmitTopTips() {
        viewModel.updateProAddSubmitTopTipShowed(true)
        delegate?.cardDidClickSubmitTopTip(self,
                                           currentBaseID: viewModel.actionParams.data.baseId,
                                           currentTableID: viewModel.actionParams.data.tableId,
                                           callback: viewModel.actionParams.callback)
    }

    func closeThisCard(completion: (() -> Void)? = nil) {
        willAppear = false
        /// 如果是phone且不是分享记录卡片，会使用push打开，因此使用pop关闭
        if isPushed || (UserScopeNoChangeFG.ZJ.btCardReform && SKDisplay.pad && self.viewModel.mode.isLinkedRecord) {
            viewModel.markDismissing()
            self.navigationController?.popViewController(animated: true)
            completion?()
            return
        }
        
        if viewModel.mode.isForm {
            delegate?.cardCloseForm()
            if UserScopeNoChangeFG.QYK.btSwitchFormInSheetFixDisable {
                afterRealDismissal()
            }
            completion?()
        } else if viewModel.mode.isIndRecord {
            viewModel.markDismissing()
            delegate?.cardCloseIndRecord()
        } else if viewModel.mode == .addRecord {
            viewModel.markDismissing()
            delegate?.cardCloseAddRecord()
        } else if viewModel.mode.isStage {
            viewModel.markDismissing()
            self.stageClickDismiss()
        } else {
            viewModel.markDismissing()
            presentingViewController?.dismiss(animated: true, completion: completion)
        }
    }
    
    func closeAllCards(animated: Bool = true, completion: (() -> Void)? = nil) {
        willAppear = false
        needCloseAllCardsWhenAppear = false
        if viewModel.mode.isForm {
            delegate?.cardCloseForm()
            if UserScopeNoChangeFG.QYK.btSwitchFormInSheetFixDisable {
                afterRealDismissal()
            }
            completion?()
        } else if viewModel.mode == .addRecord {
            // addRecord 不支持关闭
            completion?()
        } else {
            viewModel.markDismissing()
            delegate?.cardCloseAll(animated: animated, completion: completion)
        }
    }
    
    /// Base 外新建提交结果回调
    func handleBaseAddSubmitResult(_ result: BTAddRecordResult) {
        guard UserScopeNoChangeFG.YY.baseAddRecordPage else {
            return
        }
        unlockViewEditingAfterRecordSubmit()
        
        DocsLogger.info("handleBaseAddSubmitResult start")
        switch result.result {
        case .successed:
            submitView.update(iconType: .done, animated: true)
            handleBaseAddSubmitSuccess(result: result)
        case .failed:
            handleBaseAddSubmitFailure(result: result)
        }
    }
    
    private func handleBaseAddSubmitSuccess(result: BTAddRecordResult) {
        // 部分字段没有提交成功，先弹 Toast
        if let submitResult = result.submitResult, let unpermittedFields = submitResult.unpermittedFields, !unpermittedFields.isEmpty {
            let maxNameNumber = 5
            let maxNameLength = 10
            var names = unpermittedFields.prefix(maxNameNumber).map { name in
                if name.count > maxNameLength {
                    return name.prefix(maxNameLength).appending("...")
                } else {
                    return name
                }
            }
            if unpermittedFields.count > maxNameNumber {
                names.append("...")
            }
            let fieldNames = names.joined(separator: "、")
            let tips = BundleI18n.SKResource.Bitable_QuickAdd_PermissionChangeNotSubmitted_Toast(fieldNames)
            UDToast.showTips(with: tips, on: navigationController?.view ?? self.view)
        }
        
        if let recordId = result.submitResult?.recordId, !recordId.isEmpty, UserScopeNoChangeFG.YY.baseAddRecordPageAutoSubscribeEnable {
            // 该场景自动订阅
            viewModel.dataService?.triggerRecordSubscribeForSubmitIfNeeded(recordId: recordId)
        }
        
        let displayDelayTime: TimeInterval = 0.5
        
        if let submitSuccessTime = result.submitResult?.submitSuccessTime {
            // 有这个点说明提交成功
            BTRecordSubmitReportHelper.reportBaseAddRecordSubmitSuccess(submitSuccessTime: submitSuccessTime)
        }
        
        // 1. 提交成功，轮询失败
        if let codeNum = result.applyResult?.errorCode, let errorCode = AddRecordApplyResult.ErrorCode(rawValue: codeNum) {
            switch errorCode {
            case .timeout:
                emptyView.updateStateAfterDelay(state: .recordWillBeAddedSilently, delay: displayDelayTime)
                let trackParams = viewModel.getCommonTrackParams()
                DocsTracker.newLog(enumEvent: .bitableAddRecordTimeoutView, parameters: trackParams)
                BTRecordSubmitReportHelper.reportBaseAddRecordApplyEnd(result: "timeout")
            case .noViewPerm:
                emptyView.updateStateAfterDelay(state: .recordAddSuccessButNoViewPerm, delay: displayDelayTime)
                BTRecordSubmitReportHelper.reportBaseAddRecordApplyEnd(result: "no_permission")
            }
            return
        }
        // 2. 提交成功，轮询成功
        guard let applyResult = result.applyResult, applyResult.status == .done else {
            // 2.0 不应该出现这种情况，success 时 status 必须是1，不然前端代码有问题
            DocsLogger.error("handleBaseAddSubmitResult error, result: \(result)")
            emptyView.updateStateAfterDelay(state: .recordWillBeAddedSilently, delay: displayDelayTime)
            BTRecordSubmitReportHelper.reportBaseAddRecordApplyEnd(result: "success")
            return
        }
        
        guard let recordToken = applyResult.recordShareToken, !recordToken.isEmpty else {
            // 2.1 submit 成功，submit 结果查询成功：code==0, status==1，但是 record 的 shareToken 还未生成
            DocsLogger.warning("handleBaseAddSubmitResult error: no record token")
            emptyView.updateStateAfterDelay(state: .recordAddSuccessButNoShareToken, delay: displayDelayTime)
            BTRecordSubmitReportHelper.reportBaseAddRecordApplyEnd(result: "no_share_token")
            return
        }
        guard let addToken = viewModel.hostDocsInfo?.token,
              let docsUrl = viewModel.dataService?.hostDocUrl,
              let recordURL = DocsUrlUtil.constructBaseRecordURL(recordToken, host: DocsUrlUtil.getHostFromDocsUrl(docsUrl)) else {
            // 2.2 生成记录详情链接失败，不应该出现这种情况
            spaceAssertionFailure("url should not be empty!")
            DocsLogger.error("handleBaseAddSubmitResult error: generate add url failed")
            emptyView.updateStateAfterDelay(state: .recordWillBeAddedSilently, delay: displayDelayTime)
            BTRecordSubmitReportHelper.reportBaseAddRecordApplyEnd(result: "no_rul")
            return
        }
        // 2.3 提交成功，轮询成功且拿到 shareToken，跳转记录详情页
        DocsLogger.info("handleBaseAddSubmitResult success!")
        BTRecordSubmitReportHelper.reportBaseAddRecordApplyEnd(result: "success")
        let jumpURL = recordURL.docs.addEncodeQuery(parameters: ["add_token": addToken, CCMOpenTypeKey: "quickadd_submit"])
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDelayTime, execute: { [weak self] in
            guard let self = self else {
                return
            }
            self.pushURLAndRemoveCurrentCardVCIfPossible(jumpURL)
        })
    }
    
    private func getSubmitFailedTipsFromSettings(code: Int) -> String? {
        do {
            let settings = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "bitable_config"))
            guard let base_add = settings["base_add"] as? [String: Any] else {
                return nil
            }
            guard let config = base_add["submit_failed_tips"] as? [String: String] else {
                return nil
            }
            return config[String(code)]
        } catch {
            DocsLogger.btError("getSubmitFailedTipsFromSettings faild: \(error)")
        }
        return nil
    }
    
    private func handleBaseAddSubmitFailure(result: BTAddRecordResult) {
        BTRecordSubmitReportHelper.reportBaseAddRecordSubmitFail(code: result.submitResult?.errorCode)
        
        if let codeNum = result.submitResult?.errorCode, let tips = getSubmitFailedTipsFromSettings(code: codeNum) {
            // 支持 Settings 动态化配置的 Tips
            DocsLogger.error("handleBaseAddSubmitResult error, code: \(codeNum), tips:\(tips)")
            UDToast.showFailure(with: tips, on: self.view)
            emptyView.state = .none
            submitView.update(iconType: .initial)
            return
        }
        
        guard let codeNum = result.submitResult?.errorCode, let errorCode = AddRecordSubmitResult.ErrorCode(rawValue: codeNum) else {
            // submit 失败了：未知原因
            DocsLogger.error("handleBaseAddSubmitResult error, no code: \(result)")
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_QuickAdd_FailedSubmissionRetry_Toast, on: self.view)
            emptyView.state = .none
            submitView.update(iconType: .initial)
            return
        }
        DocsLogger.error("handleBaseAddSubmitResult error, code: \(codeNum)")
        
        switch errorCode {
        case .baseNotFound, .baseIsDeleted, .tableNotExist:
            // emptyView.state = .tableNotExist
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_QuickAdd_TableDeleted_Toast, on: self.view)
            emptyView.state = .none
            submitView.update(iconType: .initial)
        case .baseNoPerm, .noRecordAddPerm:
            // emptyView.state = .noRecordAddPerm
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_QuickAdd_NoRecordAccess_Desc, on: self.view)
            emptyView.state = .none
            submitView.update(iconType: .initial)
        case .errOverRowQuotaLimit, .errExceedMaxRecord:
            // 行数限制，不能再添加记录
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_QuickAdd_RecordLimitReached_Desc, on: self.view)
            emptyView.state = .none
            submitView.update(iconType: .initial)
        }
    }
    
    private func pushURLAndRemoveCurrentCardVCIfPossible(_ url: URL) {
        DocsLogger.info("card vc replace open url start!")
        Navigator.shared.push(url, from: self) { _, _ in
            DocsLogger.info("card vc replace open url finish!")
            guard let nav = self.navigationController, let browser = self.delegate?.cardGetBrowserController() as? BrowserViewController else {
                DocsLogger.error("find nav failed!")
                return
            }
            guard !browser.isTemporaryChild else {
                DocsLogger.info("remove current in Temporary complete!")
                browser.temporaryTabService.removeTab(id: browser.tabContainableIdentifier)
                return
            }
            guard nav.viewControllers.contains(browser), nav.viewControllers.count > 1 else {
                DocsLogger.error("remove current failed: \(nav.viewControllers)")
                return
            }
            DocsLogger.info("remove current card vc from nav stack success!")
            let vcStack = nav.viewControllers
            let rmStack = vcStack.filter({ $0 != browser })
            nav.setViewControllers(rmStack, animated: false)
        }
    }
    
    func didCloseBanner() {
        if UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            viewModel.tableModel.update(filterTipClosed: true)
        } else {
            viewModel.tableModel.update(isFiltered: false)
        }
        viewModel.notifyModelUpdate()
        cardsView.isScrollEnabled = false
    }
    
    // nolint: duplicated_code
    private func getCoverAction(sourceView: UIView, showBottomBorder: Bool = false) -> UDMenuAction {
        var action = UDMenuAction(
            title:  BundleI18n.SKResource.Bitable_ItemView_SetCover_Option,
            icon: UDIcon.imageOutlined.ud.resized(to: CGSize(width: 20, height: 20)),
            tapHandler: { [weak self] in
                guard let self = self else {
                    DocsLogger.error("tap cover card failed, self is nil")
                    return
                }
                guard let card = self.currentCard else {
                    DocsLogger.error("tap cover card failed, self.currentCard is nil")
                    return
                }
                self.recordViewOperateCover(view:card, sourceView: sourceView)
            }
        )
        action.customIconHandler = { imageView in
            imageView.image = UDIcon.imageOutlined.ud.withTintColor(UDColor.iconN2).ud.resized(to: CGSize(width: 20, height: 20))
        }
        action.titleTextColor = UDColor.textTitle
        action.showBottomBorder = showBottomBorder
        return action
    }
    
    // nolint: duplicated_code
    private func getAddNewRecordAction(sourceView: UIView, showBottomBorder: Bool = false) -> UDMenuAction {
        var action = UDMenuAction(
            title:  BundleI18n.SKResource.Bitable_QuickAdd_NewRecord_Option,
            icon: UDIcon.addnewOutlined.ud.resized(to: CGSize(width: 20, height: 20)),
            tapHandler: { [weak self] in
                guard let self = self else {
                    DocsLogger.error("tap cover card failed, self is nil")
                    return
                }
                guard let card = self.currentCard else {
                    DocsLogger.error("tap cover card failed, self.currentCard is nil")
                    return
                }
                // 继续添加
                card.continueSubmit()
            }
        )
        action.customIconHandler = { imageView in
            imageView.image = UDIcon.addnewOutlined.ud.withTintColor(UDColor.iconN2).ud.resized(to: CGSize(width: 20, height: 20))
        }
        action.titleTextColor = UDColor.textTitle
        action.showBottomBorder = showBottomBorder
        return action
    }
    
    // nolint: duplicated_code
    private func getDeleteAction(sourceView: UIView, showBottomBorder: Bool = false) -> UDMenuAction {
        var action = UDMenuAction(
            title: BundleI18n.SKResource.Doc_Block_DeleteRecord,
            icon: UDIcon.deleteTrashOutlined,
            tapHandler: { [weak self] in
                guard let self = self else {
                    DocsLogger.error("delete card failed, self is nil")
                    return
                }
                guard let card = self.currentCard else {
                    DocsLogger.error("delete card failed, self.currentCard is nil")
                    return
                }
                DocsLogger.info("did click delete button in card more button and will delete record")
                card.deleteRecord(sourceView: sourceView)
            }
        )
        action.customIconHandler = { imageView in
            imageView.image = UDIcon.deleteTrashOutlined.ud.withTintColor(UDColor.colorfulRed)
        }
        action.titleTextColor = UDColor.colorfulRed
        return action
    }
    
    // nolint: duplicated_code
    private func getIndRecordNewAction(url: URL, addToken: String, sourceView: UIView, showBottomBorder: Bool = false) -> UDMenuAction {
        var continueAction = UDMenuAction(
            title: BundleI18n.SKResource.Bitable_QuickAdd_NewRecord_Option,
            icon: UDIcon.moreAddOutlined,
            tapHandler: { [weak self] in
                guard let self = self else {
                    DocsLogger.error("open origin base fail, self is nil")
                    return
                }
                guard let addFromUrl = DocsUrlUtil.constructBaseAddURL(addToken, host: DocsUrlUtil.getHostFromDocsUrl(url), parameters: [CCMOpenTypeKey: "quickadd_another"]) else {
                    DocsLogger.error("generate add from url failed")
                    return
                }
                self.pushURLAndRemoveCurrentCardVCIfPossible(addFromUrl)
                
                var trackParams = viewModel.getCommonTrackParams()
                trackParams["click"] = "create_next_record"
                trackParams["target"] = "none"
                DocsTracker.newLog(enumEvent: .bitableShareRecordMoreClick, parameters: trackParams)
            }
        )
        continueAction.customIconHandler = { imageView in
            imageView.image = UDIcon.moreAddOutlined.ud.withTintColor(UDColor.iconN2)
        }
        continueAction.shouldInvokeTapHandlerAfterMenuDismiss = true
        continueAction.titleTextColor = UDColor.textTitle
        return continueAction
    }
    
    // nolint: duplicated_code
    private func getViewTableAction(sourceView: UIView, showBottomBorder: Bool = false) -> UDMenuAction {
        var action = UDMenuAction(
            title: BundleI18n.SKResource.Bitable_ShareSingleRecord_ViewTable_Button,
            icon: UDIcon.fileLinkBitableOutlined,
            tapHandler: { [weak self] in
                guard let self = self else {
                    DocsLogger.error("open origin base fail, self is nil")
                    return
                }
                let token = self.viewModel.actionParams.data.baseId
                let url = DocsUrlUtil.url(type: .bitable, token: token)
                    .docs
                    .addOrChangeEncodeQuery(
                        parameters: [
                            "table": self.viewModel.actionParams.data.tableId,
                            "view": self.viewModel.actionParams.data.viewId,
                            "record": self.viewModel.actionParams.data.recordId,
                            "from": OpenDocsFrom.other.rawValue,
                            CCMOpenTypeKey: CCMOpenType.recordMessage.rawValue
                        ]
                    )
                Navigator.shared.push(url, from: self)
                self.track(event: DocsTracker.EventType.bitableShareClick.rawValue, params: ["click": "open_table", "target": "ccm_bitable_content_page_view"])
                
                var trackParams = viewModel.getCommonTrackParams()
                trackParams["click"] = "open_table"
                trackParams["target"] = "none"
                DocsTracker.newLog(enumEvent: .bitableShareRecordMoreClick, parameters: trackParams)
            }
        )
        action.customIconHandler = { imageView in
            imageView.image = UDIcon.fileLinkBitableOutlined.ud.withTintColor(UDColor.iconN2)
        }
        action.titleTextColor = UDColor.textTitle
        return action
    }
    
    func didClickMoreButton(record: BTRecordModel, sourceView: UIView) {
        let dispatchTime: DispatchTime
        if SKDisplay.pad {
            dispatchTime = DispatchTime.now()
        } else {
            if UIApplication.shared.statusBarOrientation != .portrait {
                dispatchTime = DispatchTime.now() + 0.75 // PM UX 设计：横屏不支持操作，需要先转屏幕。为了避免UD Bug，需要在动画时间后进行
            } else {
                dispatchTime = DispatchTime.now()
            }
        }
        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
        DispatchQueue.main.asyncAfter(deadline: dispatchTime) { [weak self] in
            guard let self = self else {
                DocsLogger.btError("[BTController] self is nil")
                return
            }
            guard let card = self.currentCard else {
                DocsLogger.error("show more menu error, self.currentCard is nil")
                return
            }
            let realSourceView = card.headerView.moreButton
            var actions: [UDMenuAction] = []
            let shouldShowCover = self.viewModel.shouldShowCoverOperationInMenu
            let shouldShowAddNewRecord = UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable && viewModel.preMockRecordId?.isEmpty == false
            let shouldShowDelete = record.deletable
            if shouldShowCover {
                let showBottomBorder = shouldShowDelete && !shouldShowAddNewRecord
                var action = getCoverAction(sourceView: sourceView, showBottomBorder: showBottomBorder)
                actions.append(action)
            }
            
            if shouldShowAddNewRecord {
                let showBottomBorder = shouldShowDelete
                var action = getAddNewRecordAction(sourceView: sourceView, showBottomBorder: showBottomBorder)
                actions.append(action)
            }
            
            if shouldShowDelete {
                var action = getDeleteAction(sourceView: realSourceView)
                actions.append(action)
            }
            
            if UserScopeNoChangeFG.YY.baseAddRecordPage, record.viewMode.isIndRecord {
                if let url = self.viewModel.dataService?.hostDocUrl, let addToken = url.queryParameters["add_token"] {
                    var continueAction = getIndRecordNewAction(url: url, addToken: addToken, sourceView: sourceView)
                    actions.append(continueAction)
                }
                
                var action = getViewTableAction(sourceView: sourceView)
                actions.append(action)
            }
            
            var style = UDMenuStyleConfig.defaultConfig()
            var menuMinWidth = BTController.moreMenuWidth
            if shouldShowCover {
                menuMinWidth = 132
                style.menuItemSeperatorColor = UDColor.lineDividerDefault
            }
            style.menuMinWidth = menuMinWidth
            DocsLogger.info("did click card more button and will show more menu")
            let menu = UDMenu(actions: actions, style: style)
            menu.showMenu(sourceView: realSourceView, sourceVC: self)
            var trackParams = ["click": "more",
                               "target": "none"]
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                trackParams["version"] = "v2"
                trackParams["card_type"] = self.currentCardPresentMode == .card ? "card" : "drawer"
            }
            
            self.track(event: DocsTracker.EventType.bitableCardClick.rawValue, params: trackParams)
            
            if UserScopeNoChangeFG.YY.baseAddRecordPage {
                reportMoreView()
            }
        }
    }
    
    private func reportMoreView() {
        if viewModel.mode == .indRecord {
            var trackParams = viewModel.getCommonTrackParams()
            DocsTracker.newLog(enumEvent: .bitableShareRecordMoreView, parameters: trackParams)
        }
    }
    
    func didClickShareButton(recordID: String, recordTitle: String, sourceView: UIView) {
        let shareType = (viewModel.mode == .addRecord || viewModel.mode == .submit) ? BitableShareSubType.addRecord : BitableShareSubType.record
        let preShareToken: String? = viewModel.mode == .addRecord ? viewModel.bizData.hostDocInfo.token : nil
        
        if viewModel.mode == .addRecord {
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "share"
            trackParams["target"] = "none"
            trackParams["share_type"] = "record"
            trackParams["record_type"] = "add_record"
            DocsTracker.newLog(enumEvent: .bitableShareClick, parameters: trackParams)
        } else if viewModel.mode == .submit {
            // 埋点 ccm_bitable_record_create_click
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "share"
            trackParams["target"] = "none"
            DocsTracker.newLog(enumEvent: .bitableRecordCreateClick, parameters: trackParams)
        } else {
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "share_record"
            trackParams["target"] = "ccm_bitable_external_permission_view"
            trackParams["share_type"] = shareType.trackString
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                trackParams["version"] = "v2"
                trackParams["card_type"] = self.currentCardPresentMode == .card ? "card" : "drawer"
            }
            DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: trackParams)
        }
        // 唤起分享面板
        view.window?.endEditing(true)
        let docsInfo = editorDocsInfo // base@docx 场景不支持分享，因此在独立bitable场景下这里可以使用宿主信息
        do {
            let baseId = viewModel.actionParams.data.baseId
            let tableId = viewModel.actionParams.data.tableId
            let viewId = viewModel.actionParams.data.viewId
            var title = recordTitle.isEmpty ? BundleI18n.SKResource.Doc_Block_UnnamedRecord : recordTitle
            if shareType == .addRecord {
                title = BundleI18n.SKResource.Bitable_QuickAdd_AddRecordToTable_Desc(viewModel.actionParams.data.baseNameAdaptedForUntitled)
            }
            let param = BitableShareParam(
                baseToken: baseId,
                shareType: shareType,
                tableId: tableId,
                title: title,
                viewId: viewId,
                recordId: recordID,
                preShareToken: preShareToken
            )
            let entity = SKShareEntity(
                objToken: baseId,
                type: ShareDocsType.bitableSub(shareType).rawValue,
                title: title,
                isOwner: docsInfo.isOwner,
                ownerID: docsInfo.ownerID ?? "",
                displayName: docsInfo.displayName,
                tenantID: docsInfo.tenantID ?? "",
                isFromPhoenix: docsInfo.isFromPhoenix,
                shareUrl: docsInfo.shareUrl ?? "",
                enableShareWithPassWord: true,
                enableTransferOwner: true,
                onlyShowSocialShareComponent: true,
                bitableShareEntity: BitableShareEntity(param: param, docUrl: viewModel.dataService?.hostDocUrl)
            )
            entity.shareHandlerProvider = self
            let vc = SKShareViewController(
                entity,
                delegate: self,
                router: self,
                source: .content,
                isInVideoConference: docsInfo.isInVideoConference ?? false
            )
            vc.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark ?? true
            
            let nav = LkNavigationController(rootViewController: vc)

            if SKDisplay.pad, self.view.isMyWindowRegularSize() {
                vc.modalPresentationStyle = .popover
                vc.popoverPresentationController?.backgroundColor = UDColor.bgFloat
                
                nav.modalPresentationStyle = .popover
                // 不要在这里统一设置 popoverPresentationController.backgroundColor, 原因是 more 面板不能设置此属性，各个调用方自己保证 or 通过布局处理
                nav.popoverPresentationController?.sourceView = sourceView
                nav.popoverPresentationController?.permittedArrowDirections = .up

                present(nav, animated: true, completion: nil)

            } else {
                nav.modalPresentationStyle = .overFullScreen
                BTUtil.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                    self?.present(nav, animated: false, completion: nil)
                }
            }
        } catch {
            DocsLogger.error("handleBitableShareService error: \(error)")
        }
        
    }

    func recordViewOperateCover(view: BTRecord, sourceView: UIView) {
        let vc = BTItemViewAttachmentCoverHelper.operateItemViewCover(
            hostVC: self,
            recordModel: view.recordModel,
            sourceView: sourceView,
            editEngine: viewModel,
            trackParams: viewModel.getCommonTrackParams(),
            baseContext: baseContext
        )
        currentOperateAttachmentCoverVC = vc
        present(vc, animated: true)

        var params = viewModel.getCommonTrackParams()
        params.merge(other: ["click": "cover", "target": "ccm_bitable_card_attachment_cover_setting_view"])
        DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: params)

        DocsTracker.newLog(
            enumEvent: .bitableCardAttachmentCoverSettingViewShow,
            parameters: viewModel.getCommonTrackParams()
        )
    }
    
    func didClickUser(_ userId: String) {
        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
        HostAppBridge.shared.call(ShowUserProfileService(userId: userId, fromVC: self))
    }
    
    func didClickChatter(_ model: BTCapsuleModel) {
        switch model.chatterType {
        case .user:
            BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
            HostAppBridge.shared.call(ShowUserProfileService(userId: model.id, fromVC: self))
        case .group:
            guard !model.token.isEmpty else {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Group_UnableToJoinGroup_Toast, on: self.view)
                DocsLogger.error("[BTController] didClickChatter linkToken is empty")
                return
            }
            BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
            var appLink = URLComponents()
            appLink.scheme = "https"
            appLink.host = DomainSettingManager.shared.currentSetting["applink"]?.first ?? ""
            appLink.path = "/client/chat/chatter/add_by_link"
            let query = URLQueryItem(name: "link_token", value: model.token)
            appLink.queryItems = [query]
            if let url = appLink.url {
                Navigator.shared.push(url, from: self)
            }
            var params = viewModel.getCommonTrackParams()
            params.merge(other: ["click": "click", "chat_id": model.id])
            DocsTracker.newLog(enumEvent: .bitableGroupFieldEntranceClick, parameters: params)
        }
    }
    
    func logAttachmentEvent(action: String, attachmentCount: Int?) {
        var params = viewModel.getCommonTrackParams()
        let businessParams = [
            "table_id": viewModel.actionParams.data.tableId,
            "view_id": viewModel.actionParams.data.viewId,
            "bitable_view_type": viewModel.tableModel.viewType,
            "action": action
        ]
        params.merge(other: businessParams)
        if let count = attachmentCount {
            params["attach_number"] = "\(count)"
        }
        DocsTracker.log(enumEvent: .bitableAttachmentOperation, parameters: params)
    }
    
    func logAttachmentOperate(action: String) {
        var params = viewModel.getCommonTrackParams()
        let businessParams = [
            "click": action,
            "target": "none"
        ]
        params.merge(other: businessParams)
        DocsTracker.newLog(enumEvent: .bitableAttachmentOperateClick, parameters: params)
    }

    func newLogAttachmentEvent(_ event: AttachmentLogEvent) {
        var params = viewModel.getCommonTrackParams()
        switch event {
        case let .operateClick(action, isOnlyCamera):
            params["click"] = action.rawValue
            params["target"] = "none"
            if let isOnlyCamera = isOnlyCamera {
                params["is_phone_restricted"] = "\(isOnlyCamera)"
            }
            if action == .add {
                params["target"] = "ccm_bitable_card_attachment_choose_view"
            }
            DocsTracker.newLog(enumEvent: .bitableCardAttachmentOperateClick, parameters: params)
        case .attachmentChooseViewShow:
            DocsTracker.newLog(enumEvent: .bitableCardAttachmentChooseView, parameters: params)
        case let .attachmentChooseViewClick(action):
            params["click"] = action.rawValue
            params["target"] = "none"
            DocsTracker.newLog(enumEvent: .bitableCardAttachmentChooseViewClick, parameters: params)
        }
    }
    
    func logUploadType(type: String) {
        var params = viewModel.getCommonTrackParams()
        params["attach_file_type"] = type
        DocsTracker.log(enumEvent: .bitableUploadType, parameters: params)
    }

    func deleteAttachment(data: BTAttachmentModel, inFieldWithID fieldID: String) {
        viewModel.deleteAttachment(data: data, inFieldWithID: fieldID)
    }

    func previewAttachments(_ attachments: [BTAttachmentModel], atIndex: Int) {
        guard let previewAttachmentsModel = createPreviewAttachmentsModel(attachments, atIndex: atIndex, inFieldWithID: "") else {
            DocsLogger.btError("[ACTION] createPreviewAttachmentsModel fail")
            return
        }
        BTAttachmentsPreview.attachmentsPreview(
            hostVC: self,
            spaceFollowAPIDelegate: self.spaceFollowAPIDelegate,
            previewAttachmentsModel: previewAttachmentsModel
        )
    }

    func previewAttachments(_ attachments: [BTAttachmentModel], atIndex: Int, inFieldWithID fieldID: String) {
        guard let previewAttachmentsModel = createPreviewAttachmentsModel(attachments, atIndex: atIndex, inFieldWithID: fieldID) else {
            DocsLogger.btError("[ACTION] createPreviewAttachmentsModel fail")
            return
        }
        BTAttachmentsPreview.attachmentsPreview(hostVC: self,
                                                driveDelegate: self,
                                                spaceFollowAPIDelegate: self.spaceFollowAPIDelegate,
                                                previewAttachmentsModel: previewAttachmentsModel)
    }

    private func createPreviewAttachmentsModel(_ attachments: [BTAttachmentModel], atIndex: Int, inFieldWithID fieldID: String) -> AttachmentsPreviewParams? {
        guard let recordID = self.currentCard?.recordID else {
            DocsLogger.btError("[ACTION] previewAttachments cannot get current recordID")
            return nil
        }
        self.currentPreviewAttachmentBTFieldID = fieldID
        var permissionToken = viewModel.hostDocsInfo?.objToken
        if UserScopeNoChangeFG.YY.bitableReferPermission {
            permissionToken = viewModel.baseContext.permissionObj.objToken
        }
        if viewModel.mode.isIndRecord {
            permissionToken = viewModel.actionParams.data.baseId
        }
        let hostTenantID: String?
        if let permissionToken {
            hostTenantID = viewModel.hostDocsInfo?.getBlockTenantId(srcObjToken: permissionToken)
        } else {
            hostTenantID = viewModel.hostDocsInfo?.tenantID
        }
        let previewAttachmentsModel = AttachmentsPreviewParams(atIndex: atIndex,
                                                               fieldID: fieldID,
                                                               recordID: recordID,
                                                               tableID: self.viewModel.actionParams.data.tableId,
                                                               attachments: attachments,
                                                               attachFrom: ENativeOpenAttachFrom.cardAttachPreview.rawValue,
                                                               permissionToken: permissionToken,
                                                               hostTenantID: hostTenantID)
        return previewAttachmentsModel
    }

    func previewLocalAttachments(_ attachments: [PendingAttachment.LocalFile], atIndex: Int) {
        guard !attachments.isEmpty else {
            return
        }
        self.currentPreviewAttachmentBTFieldID = nil
        self.currentPreviewAttachmentToken = nil
        DocsLogger.btInfo("[ACTION] previewLocalAttachments \(atIndex)/\(attachments.count)")
        var index = atIndex
        if atIndex < 0 || atIndex >= attachments.count {
            spaceAssertionFailure("[ACTION] previewLocalAttachments index is invalid")
            index = 0
        }
        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
        let localDependency = BTLocalDependencyImpl()
        let files = attachments.map { localFile -> DriveSDKLocalFileV2 in
            return DriveSDKLocalFileV2(fileName: localFile.fileName,
                                       fileType: nil,
                                       fileURL: localFile.fileURL,
                                       fileId: localFile.fileURL.lastPathComponent,
                                       dependency: localDependency)
        }
        
        let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: false)
        let body = DriveSDKLocalFileBody(files: files,
                                         index: index,
                                         appID: DKSupportedApp.bitableLocal.rawValue,
                                         thirdPartyAppID: nil,
                                         naviBarConfig: config)
        Self.show(body: body, from: self)
    }
    
    private static func show<T: Body>(body: T, from: NavigatorFrom, completion: Handler? = nil) {
        if !UserScopeNoChangeFG.YY.bitablePreviewFileFullscreenDisable {
            Navigator.shared.present(body: body, from: from, prepare: { $0.modalPresentationStyle = .overFullScreen }, completion: completion)
        } else {
            Navigator.shared.push(body: body, from: from, completion: completion)
        }
    }

    func deletePendingAttachment(data: PendingAttachment) {
        uploader?.removePendingAttachment(data)
    }

    func cancelUploadingAttachment(data: BTMediaUploadInfo) {
        uploader?.cancelUploadingAttachment(data)
    }
    
    func didClickStageField(with recordID: String, fieldModel: BTFieldModel) {
        
        let actionParams = BTActionParamsModel(
            action: .showCard,
            data: BTPayloadModel(
                baseId: viewModel.actionParams.data.baseId,
                tableId: viewModel.actionParams.data.tableId,
                viewId: viewModel.actionParams.data.viewId,
                recordId: recordID,
                bizType: viewModel.actionParams.data.bizType,
                fieldId: fieldModel.fieldID,
                highLightType: .none,
                colors: viewModel.actionParams.data.colors,
                showConfirm: false,
                showCancel: false
            ),
            callback: viewModel.actionParams.callback,
            timestamp: Date().timeIntervalSince1970 * 1000,
            transactionId: viewModel.actionParams.transactionId,
            originBaseID: viewModel.actionParams.originBaseID,
            originTableID: viewModel.actionParams.originTableID
        )

        var actionTask = BTCardActionTask()
        actionTask.actionParams = actionParams
        actionTask.setCompleted {}
        
        let size: CGSize
        if let window = view.window {
            size = window.bounds.size
        } else {
            size = SKDisplay.windowBounds(view).size
            DocsLogger.btError("[UI] create bt-vc use unexpected init size: \(size)")
        }
        
        let linkedController: BTController
        if ViewCapturePreventer.isFeatureEnable {
            linkedController = BTSecureController(
                actionTask: actionTask,
                viewMode: .stage(origin: viewModel.mode),
                recordIDs: [recordID],
                stageFieldId: fieldModel.fieldID,
                delegate: delegate,
                uploader: uploader,
                geoFetcher: geoFetcher,
                baseContext: viewModel.baseContext,
                dataService: viewModel.dataService,
                initialSize: size
            )
        } else {
            linkedController = BTController(
                actionTask: actionTask,
                viewMode: .stage(origin: viewModel.mode),
                recordIDs: [recordID],
                stageFieldId: fieldModel.fieldID,
                delegate: delegate,
                uploader: uploader,
                geoFetcher: geoFetcher,
                baseContext: viewModel.baseContext,
                dataService: viewModel.dataService
            )
        }
        
        linkedController.allowCapture = self.allowCapture
        linkedController.watermarkConfig.needAddWatermark = watermarkConfig.needAddWatermark
        linkedController.linkFromType = fieldModel.compositeType
        self.linkedController = linkedController
        linkedController.linkingController = self
        linkedController.viewModel.kickoff()
    }
    
    func openLinkedRecord(withID recordID: String, allLinkedRecordIDs: [String], linkFieldModel: BTFieldModel) {
        guard !viewModel.mode.isIndRecord else {
            // 分享记录卡片不支持跳转 link 的记录
            return
        }
        
        guard viewModel.mode != .addRecord else {
            // 快捷新建记录不支持跳转 link 的记录
            return
        }
        
        guard linkFieldModel.uneditableReason != .isOnDemand else {
            // 按需加载的文档不支持跳转 link 的记录
            BTFiledUtils.showUneditableToast(fieldModel: linkFieldModel, view: view)
            return
        }
        
        var trackParams = ["click": "relate_record",
                           "target": "none"]
        
        if UserScopeNoChangeFG.ZJ.btCardReform {
            trackParams["version"] = "v2"
            trackParams["card_type"] = self.currentCardPresentMode == .card ? "card" : "drawer"
        }
        
        track(event: DocsTracker.EventType.bitableCardClick.rawValue, params: trackParams)
        let sourceBaseID = viewModel.actionParams.data.baseId
        var destinationBaseID = linkFieldModel.property.baseId
        let sourceTableID = viewModel.actionParams.data.tableId
        var destinationTableID = linkFieldModel.property.tableId
        let callback = viewModel.actionParams.callback

        if let createdLinkedController = self.linkedController {
            DocsLogger.btInfo("[ACTION][LINK] found pending linkedController with tableId \(createdLinkedController.viewModel.actionParams.data.tableId)")
            destinationBaseID = createdLinkedController.viewModel.actionParams.data.baseId
            destinationTableID = createdLinkedController.viewModel.actionParams.data.tableId
            delegate?.cardLink(action: .forwardLinkTable,
                               originBaseID: viewModel.actionParams.originBaseID,
                               originTableID: viewModel.actionParams.originTableID,
                               sourceBaseID: sourceBaseID,
                               sourceTableID: sourceTableID,
                               destinationBaseID: destinationBaseID,
                               destinationTableID: destinationTableID,
                               callback: callback)
            return
        }
        var level = 0
        var linkingController = linkingController
        while linkingController != nil {
            if linkingController?.viewModel.mode.isStage != true {
                level += 1
            }
            linkingController = linkingController?.linkingController
        }
        guard level <= Self.linkedRecordMaxCardLevel else {
            if let window = view.window {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Relation_TooManyCardsOpened, on: window)
            }
            return
        }

        let linkActionParams = BTActionParamsModel(
            action: .showCard,
            data: BTPayloadModel(
                baseId: linkFieldModel.property.baseId,
                tableId: linkFieldModel.property.tableId,
                viewId: linkFieldModel.property.viewId,
                recordId: recordID,
                bizType: viewModel.actionParams.data.bizType,
                fieldId: linkFieldModel.fieldID,
                highLightType: .none,
                colors: viewModel.actionParams.data.colors,
                showConfirm: false,
                showCancel: false
            ),
            callback: viewModel.actionParams.callback,
            timestamp: Date().timeIntervalSince1970 * 1000,
            transactionId: viewModel.actionParams.transactionId,
            originBaseID: viewModel.actionParams.originBaseID,
            originTableID: viewModel.actionParams.originTableID
        )

        var actionTask = BTCardActionTask()
        actionTask.actionParams = linkActionParams
        actionTask.setCompleted {}
        
        let size: CGSize
        let sizeValid: Bool
        if !UserScopeNoChangeFG.ZJ.btCardReform {
            if let window = view.window {
                size = window.bounds.size
                sizeValid = true
            } else {
                size = SKDisplay.windowBounds(view).size
                DocsLogger.btError("[UI] create bt-vc use unexpected init size: \(size)")
                sizeValid = false
            }
        } else {
            if let card = self.view {
                size = card.bounds.size
                sizeValid = true
            } else {
                size = self.view.frame.size
                DocsLogger.btError("[UI] create bt-vc use unexpected init size: \(size)")
                sizeValid = false
            }
        }
        let event = DocsTracker.EventType.bitableCapturePreventViewInitSize
        DocsTracker.newLog(enumEvent: event, parameters: ["width": size.width,
                                                          "height": size.height,
                                                          "is_valid": sizeValid.description])
        let linkedController: BTController
        if ViewCapturePreventer.isFeatureEnable {
            linkedController = BTSecureController(
                actionTask: actionTask,
                viewMode: .link,
                recordIDs: allLinkedRecordIDs,
                delegate: delegate,
                uploader: uploader,
                geoFetcher: geoFetcher,
                baseContext: viewModel.baseContext,
                dataService: viewModel.dataService,
                initialSize: size
            )
        } else {
            linkedController = BTController(
                actionTask: actionTask,
                viewMode: .link,
                recordIDs: allLinkedRecordIDs,
                delegate: delegate,
                uploader: uploader,
                geoFetcher: geoFetcher,
                baseContext: viewModel.baseContext,
                dataService: viewModel.dataService
            )
        }

        // 然后前端会去组装关联表的数据，必要的话会从后端下载 clientVars，所以要等 tableRecordsDataLoaded 事件过来之后再 fetch、present
        // 👆相关的逻辑写在 BTController.respond(to:) 方法里
        linkedController.allowCapture = self.allowCapture
        linkedController.watermarkConfig.needAddWatermark = watermarkConfig.needAddWatermark

        delegate?.cardLink(action: .forwardLinkTable,
                           originBaseID: viewModel.actionParams.originBaseID,
                           originTableID: viewModel.actionParams.originTableID,
                           sourceBaseID: sourceBaseID,
                           sourceTableID: sourceTableID,
                           destinationBaseID: destinationBaseID,
                           destinationTableID: destinationTableID,
                           callback: callback)
        // 然后前端会去组装关联表的数据，必要的话会从后端下载 clientVars，所以要等 tableRecordsDataLoaded 事件过来之后再 fetch、present
        // 👆相关的逻辑写在 BTController.respond(to:) 方法里
        linkedController.linkFromType = linkFieldModel.compositeType
        self.linkedController = linkedController
        DocsLogger.btInfo("[ACTION][LINK] creating linkedController for \(linkedController.viewModel.actionParams.data.tableId) succeeded, wait for data")
    }

    func beginModifyLinkage(fromLinkField: BTFieldLinkCellProtocol) {
        let linkFieldModel = fromLinkField.fieldModel
        let sourceBaseID = viewModel.actionParams.data.baseId
        var destinationBaseID = linkFieldModel.property.baseId
        let sourceTableID = viewModel.actionParams.data.tableId
        var destinationTableID = linkFieldModel.property.tableId
        let callback = viewModel.actionParams.callback

        if let currentLinkEditAgent = currentEditAgent as? BTLinkEditAgent {
            destinationBaseID = currentLinkEditAgent.currentLinkingBaseID
            destinationTableID = currentLinkEditAgent.currentLinkingTableID
        }

        startEditing(fromLinkField, newEditAgent: nil)

        delegate?.cardLink(action: .forwardLinkTable,
                           originBaseID: viewModel.actionParams.originBaseID,
                           originTableID: viewModel.actionParams.originTableID,
                           sourceBaseID: sourceBaseID,
                           sourceTableID: sourceTableID,
                           destinationBaseID: destinationBaseID,
                           destinationTableID: destinationTableID,
                           callback: callback)

        // 然后前端会去组装关联表的数据，必要的话会从后端下载 clientVars，所以要等 tableRecordsDataLoaded 事件过来之后再 fetch、show
        // 👆相关的逻辑写在 BTController.respond(to:) 方法里

        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = "add_record"
        trackParams["target"] = "none"
        trackParams["location"] = "plus_sign"
        trackParams["field_type"] = linkFieldModel.compositeType.fieldTrackName
        DocsTracker.newLog(enumEvent: .bitableCardLinkFieldClick, parameters: trackParams)
    }

    func cancelLinkage(fromFieldID: String, toRecordID: String, inFieldModel: BTFieldModel) {
        viewModel.cancelLinkage(fromFieldID: fromFieldID, toRecordID: toRecordID)
        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = "delete"
        trackParams["target"] = "none"
        trackParams["field_type"] = inFieldModel.compositeType.fieldTrackName
        DocsTracker.newLog(enumEvent: .bitableCardLinkFieldClick, parameters: trackParams)
    }

    func updateCheckboxValue(inFieldWithID fieldID: String, toSelected selected: Bool) {
        viewModel.didUpdateCheckbox(inFieldWithID: fieldID, toStatus: selected)
    }

    func showDescriptionPanel(withAttrText attrText: NSAttributedString, forFieldID fieldID: String, fieldName: String, fromButton button: UIButton) {
        setDescriptionIndicator(ofFieldID: fieldID, selected: true)
        let panel = BTFieldDescriptionPanel(fieldID: fieldID, fieldName: fieldName, delegate: self)
        panel.updateDescription(attrText: attrText)
        let nav = SKNavigationController(rootViewController: panel)
        nav.transitioningDelegate = panel.panelTransitioningDelegate
        if SKDisplay.pad {
            nav.modalPresentationStyle = .popover // 内部会自动降级
            nav.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            nav.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            nav.popoverPresentationController?.sourceView = button
            nav.popoverPresentationController?.sourceRect = button.bounds
            nav.popoverPresentationController?.popoverLayoutMargins = UIEdgeInsets(top: 18, left: 18, bottom: 18, right: 18)
        } else {
            nav.modalPresentationStyle = .overCurrentContext
        }
        Navigator.shared.present(nav, from: self)
        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = "description_icon"
        trackParams["target"] = "none"

        if UserScopeNoChangeFG.ZJ.btCardReform {
            trackParams["version"] = "v2"
            trackParams["card_type"] = self.currentCardPresentMode == .card ? "card" : "drawer"
        }
        
        DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: trackParams)
    }

    func setDescriptionLimitState(forFieldID fieldID: String, to newState: Bool) {
        viewModel.tableModel.update(descriptionIsLimited: newState, forFieldID: fieldID)
        viewModel.notifyModelUpdate()
    }
    
    func didDoubleTap(_ sender: BTRecord, field: BTFieldModel) {
        guard field.uneditableReason == .isExtendField else {
            return
        }
        DocsLogger.info("getFieldExtendCellTooltip invoke", component: BTFieldExtConst.logTag)
        viewModel.dataService?.asyncJsRequest(
            biz: .card,
            funcName: .asyncJsRequest,
            baseId: viewModel.tableModel.baseID,
            tableId: viewModel.tableModel.tableID,
            params: [
                "router": BTAsyncRequestRouter.getFieldExtendCellTooltip.rawValue,
                "tableId": viewModel.tableModel.tableID,
                "data": [
                    "fieldId": field.fieldID,
                    "recordId": field.recordID,
                ]
            ],
            overTimeInterval: 5,
            responseHandler: { [weak self] response in
                guard let self = self else {
                    return
                }
                switch response {
                case .success(let resp):
                    if let msg = resp.data["msg"] as? String, !msg.isEmpty {
                        UDToast.showWarning(with: msg, on: self.view)
                        DocsLogger.info("getFieldExtendCellTooltip suc, msg: \(msg)", component: BTFieldExtConst.logTag)
                    } else {
                        DocsLogger.error("getFieldExtendCellTooltip suc, no msg", component: BTFieldExtConst.logTag)
                    }
                case .failure(let error):
                    DocsLogger.error("getFieldExtendCellTooltip fail", error: error, component: BTFieldExtConst.logTag)
                }
            },
            resultHandler: { result in
                DocsLogger.info("getFieldExtendCellTooltip call result: \(result)", component: BTFieldExtConst.logTag)
            }
        )
    }

    func didTapView(withAttributes attributes: [NSAttributedString.Key: Any], inFieldModel: BTFieldModel?) {
        let trackingEventBlock: () -> Void = { [weak viewModel] in
            if let fieldModel = inFieldModel {
                let stringForTrack = fieldModel.compositeType.fieldTrackName
                
                var trackParams = ["click": "link",
                                   "target": "none",
                                   "field_type": stringForTrack]
                
                if UserScopeNoChangeFG.ZJ.btCardReform {
                    trackParams["version"] = "v2"
                    trackParams["card_type"] = self.currentCardPresentMode == .card ? "card" : "drawer"
                }
                viewModel?.trackBitableEvent(eventType: DocsTracker.EventType.bitableCardClick.rawValue,
                                             params: trackParams)
                //新增一个埋点，如果是 email 类型需要新增埋点
                //https://bytedance.feishu.cn/sheets/W7PasfsQyhQrNStdKwlcvFK4nDh
                if fieldModel.compositeType.uiType == .email {
                    var trackParams = ["click": "email_address",
                                       "field_type": stringForTrack]
                    viewModel?.trackBitableEvent(eventType: DocsTracker.EventType.bitableMailCellClick.rawValue,
                                                 params: trackParams)
                }
            }
        }
        
        
        if !UserScopeNoChangeFG.QYK.btNavigatorCardCloseFixDisable, self.currentCardPresentMode == .card {
            
            // 关闭所有卡片
            let block: EENavigator.Handler = { [weak self] _, _ in
                guard let self = self else { return }
                self.closeAllCards()
                self.afterRealDismissal()
            }
            
            BTUtil.didTapView(hostVC: self.presentingViewController ?? self,
                              hostDocsInfo: self.viewModel.bizData.hostDocInfo, // base@docx 场景下，这里与宿主判断
                              isJira: viewModel.tableModel.bizType == "jira",
                              withAttributes: attributes,
                              openURLByVCFollowIfNeed: openURLByVCFollowIfNeed,
                              trackingEventBlock: trackingEventBlock,
                              completion: block)
        } else {
            BTUtil.didTapView(hostVC: self,
                              hostDocsInfo: self.viewModel.bizData.hostDocInfo, // base@docx 场景下，这里与宿主判断
                              isJira: viewModel.tableModel.bizType == "jira",
                              withAttributes: attributes,
                              openURLByVCFollowIfNeed: openURLByVCFollowIfNeed,
                              trackingEventBlock: trackingEventBlock)
        }
        
    }
    
    func openUrl(_ url: String, inFieldModel: BTFieldModel) {
        openUrl(url)
    }
    
    func openUrl(_ url: String) {
        guard let uRL = URL(string: url.urlEncoded()) else {
            DocsLogger.btError("[ACTION] open url fail \(url.encryptToShort)")
            return
        }
        
        // iPad present card的case下，push完URL 要把卡片关了，否则url 会出现在卡片的下方
        let block: EENavigator.Handler = { [weak self] _,_ in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.closeAllCards(animated: true, completion: nil)
                self.afterRealDismissal()
            }
        }
        
        if !UserScopeNoChangeFG.QYK.btNavigatorCardCloseFixDisable, self.currentCardPresentMode == .card {
            if !openURLByVCFollowIfNeed(uRL, false) {
                Navigator.shared.push(uRL, from: self, completion: block)
            }
        } else {
            if !openURLByVCFollowIfNeed(uRL, false) {
                Navigator.shared.push(uRL, from: self)
            }
        }
    }
    
    /// 交由 VCFollow 进行打开。
    private func openURLByVCFollowIfNeed(_ url: URL, _ isNeedTransOrientation: Bool) -> Bool {
      
        let handler: () -> Void = {
            func dismissSelf() {
                self.dismiss(animated: false) {
                    /// 这里把转屏放在这里是希望在视图 dismiss 掉之后再转屏，否则 dismiss 和 转屏同时出现的过程中，体验会比较差。
                    if isNeedTransOrientation {
                        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
                    }
                    self.afterRealDismissal()
                }
            }
            /// 当前可能弹出类似字段描述的视图。
            if let presentingVC = self.presentingViewController {
                presentingVC.dismiss(animated: false) {
                    dismissSelf()
                }
            } else {
                dismissSelf()
            }
        }
        
        if OperationInterceptor.interceptUrlIfNeed(url.absoluteString,
                                                   from: self.delegate?.cardGetBrowserController(),
                                                   followDelegate: nil,
                                                   handler: SKDisplay.pad ? nil : handler) {
            //先判断DocComponent是否拦截
            return true
        }
        
        guard let followAPIDelegate = self.spaceFollowAPIDelegate else {
            return false
        }
        
        followAPIDelegate.follow(nil, onOperate: .vcOperation(value: .openUrlWithHandlerBeforeOpen(url: url.absoluteString, handler: handler)))
        return true
    }

    func startEditing(_ field: BTFieldCellProtocol, newEditAgent: BTBaseEditAgent?) {
        viewModel.tableModel.update(editingRecord: nil, editingField: nil)
        currentEditAgent?.stopEditing(immediately: false, sync: true)
        viewModel.tableModel.update(editingRecord: viewModel.currentRecordID, editingField: field.fieldID)
        viewModel.tableModel.update(errorMsg: "", forFieldID: field.fieldID)
        viewModel.notifyModelUpdate()
        delegate?.cardDidStartEditing(isForm: viewModel.mode.isForm)
        self.updateSwitchCardBottomPanelViewVisibility(visible: false)
        self.updateSubmitViewVisibility(visible: false)
        switch field.fieldModel.compositeType.uiType {
        case .text, .barcode, .number, .url, .phone, .currency, .email:
            currentEditAgent = newEditAgent
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            currentEditAgent?.startEditing(field)
            currentEditingField = field
        case .dateTime:
            currentEditAgent = BTDateEditAgent(fieldID: field.fieldID, recordID: viewModel.currentRecordID)
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            currentEditAgent?.startEditing(field)
            currentEditingField = field

        case .singleSelect, .multiSelect:
            currentEditAgent = BTOptionEditAgent(
                fieldID: field.fieldID,
                recordID: viewModel.currentRecordID,
                gestureManager: self,
                isSingle: field.fieldModel.compositeType.uiType == .singleSelect
            )
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            currentEditAgent?.startEditing(field)
            currentEditingField = field

        case .attachment:
            currentEditAgent = BTAttachmentEditAgent(
                fieldID: field.fieldID,
                recordID: viewModel.currentRecordID,
                delegate: self
            )
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            currentEditAgent?.startEditing(field)
            currentEditingField = field
        case .singleLink, .duplexLink:
            currentEditAgent = BTLinkEditAgent(
                fieldID: field.fieldID,
                recordID: viewModel.currentRecordID,
                gestureManager: self
            )
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            
            if let field = field as? BTFieldLinkCellProtocol,
               field.fieldModel.property.fields.isEmpty || !field.fieldModel.property.tableVisible {
                // 这两个场景下不需要去走网络请求，直接打开空面板，现有数据足够
                currentEditAgent?.startEditing(field)
            } else {
                // startEditing 需要在 tableRecordsDataLoaded 事件通知过来之后触发，写在了 BTController.respond(to:) 里
            }
            currentEditingField = field
        case .location:
            let geoEditAgent = BTGeoLocationEditAgent(fieldID: field.fieldID, recordID: viewModel.currentRecordID)
            geoEditAgent.delegate = self
            currentEditAgent = geoEditAgent
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            currentEditAgent?.startEditing(field)
            currentEditingField = field
        case .progress:
            currentEditAgent = BTProgressEditAgent(fieldID: field.fieldID, recordID: viewModel.currentRecordID)
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            currentEditAgent?.startEditing(field)
            currentEditingField = field
        case .group, .user:
            currentEditAgent = BTChatterEditAgent(fieldID: field.fieldID,
                                                 recordID: viewModel.currentRecordID,
                                                 chatterType: (field as? BTFieldChatterCellProtocol)?.chatterType ?? .user)
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            currentEditAgent?.startEditing(field)
            currentEditingField = field
        case .rating:
            currentEditAgent = newEditAgent
            currentEditAgent?.coordinator = self
            currentEditAgent?.baseDelegate = self
            currentEditAgent?.startEditing(field)
            currentEditingField = field
        default: ()
        }
        var parmas = ["click": "cell_content_change",
                      "field_type": field.fieldModel.compositeType.uiType.rawValue]
        if field.fieldModel.isInStage {
            parmas["edit_cell_type"] = "stage_record_board"
        }
        DocsTracker.newLog(enumEvent: .bitableCellEdit, parameters: parmas)

    }
    
    func didEndEditingField() {
        self.updateSwitchCardBottomPanelViewVisibility(visible: true)
        delegate?.cardDidStopEditing(isForm: viewModel.mode.isForm)
        DispatchQueue.main.async { [weak self] in
            // 放到下一个 runloop 执行，因为显示隐藏的判断条件依赖了一些在本 runloop 状态设置完成
            self?.updateSubmitViewVisibility(visible: true)
        }
    }
    
    func generateHapticFeedback() {
        hapticFeedbackGenerator.selectionChanged()
    }

    func didClickSubmitForm() {
        DocsLogger.btInfo("[ACTION] submit form for tableID: \(viewModel.actionParams.data.tableId)")
        //fix: https://bits.bytedance.net/meego/larksuite/issue/detail/3123548?parentUrl=%2Flarksuite%2FissueView%2Fb0XeV04Qsh
        //点提交之前把还在编辑态未同步到前端的数据同步到前端
        if let editAgent = currentEditAgent {
            editAgent.stopEditing(immediately: true, sync: true)
        }
        delegate?.cardDidClickHeaderButton(self,
                                           action: .confirmForm,
                                           currentBaseID: viewModel.actionParams.data.baseId,
                                           currentTableID: viewModel.actionParams.data.tableId,
                                           originBaseID: viewModel.actionParams.originBaseID,
                                           originTableID: viewModel.actionParams.originTableID,
                                           callback: viewModel.actionParams.callback)
    }
    
    //MARK: 订阅相关 start
    func recordSubscribe(recordId: String, isSubscribe: Bool, isPassive: Bool = false, scene: BTViewModel.SubscribeScene = .normal, completion: ((BTRecordSubscribeCode) -> Void)?) {
        let token = viewModel.baseContext.baseToken
        let tableId = viewModel.tableValue.tableId
        viewModel.subscribeRecord(token: token, tableID: tableId, recordId: recordId, isSubscribe: isSubscribe, scene: scene) { [weak self] code, shouldShowAlertView in
            guard let self = self else {
                DocsLogger.btError("record subscribe behaviour failed, self is nil")
                return
            }
            if !isPassive {
                //主动操作
                if code == .success {
                    //缓存订阅状态
                    self.storeRecordSubscribeStatus(recordId: recordId, status: isSubscribe ? .subscribe : .unSubscribe)
                    if isSubscribe == false {
                        //缓存编辑触发自动订阅状态
                        self.storeRecordAutoSubscribeStatus(recordId: recordId, status: .editNoAutoSub)
                    }
                    //展示自动订阅弹窗
                    if shouldShowAlertView {
                        self.showAutoSubscribeAlertView(recordId: recordId)
                    } else {
                        UDToast.showSuccess(with: code.codeTitle(isSubscribe: isSubscribe), on: self.view)
                    }
                } else {
                    UDToast.showFailure(with: code.codeTitle(isSubscribe: isSubscribe), on: self.view)
                }
                completion?(code)
                self.currentCard?.updateHeader()
            } else {
                //被动操作
                if code == .success {
                    self.storeRecordSubscribeStatus(recordId: recordId, status: .subscribe)
                    completion?(code)
                    self.currentCard?.updateHeader()
                }
            }
        }
        trackRecordSubscribeBehaviour(recordId: recordId, isSubscribe: isSubscribe, isPassive: isPassive)
    }
    ///获取Record订阅状态
    func fetchRemoteRecordSubscribeStatus(recordId: String, completion: ((BTRecordSubscribeStatus) -> Void)? = nil)  {
        let token = viewModel.baseContext.baseToken
        let tableId = viewModel.tableValue.tableId
        viewModel.fetchRecordSubscribeState(token: token, tableID: tableId, recordId: recordId) { [weak self] state, autoScribeStatus in
            if state != .unknown {
                self?.storeRecordSubscribeStatus(recordId: recordId, status: state)
            }
            
            if autoScribeStatus == .editNoAutoSub {
                self?.storeRecordAutoSubscribeStatus(recordId: recordId, status: autoScribeStatus)
            }
            completion?(state)
        }
    }
    
    func fetchLocalRecordSubscribeStatus(recordId: String) -> BTRecordSubscribeStatus {
        guard let subscribeHelper = self.delegate else {
            DocsLogger.btError("fetch local record subscribe status failed, delegate is nil")
            return .unknown
        }
        return subscribeHelper.getRecordSubscribeStatusFromLocalCache(recordId: recordId)
    }
    
    func storeRecordSubscribeStatus(recordId: String, status: BTRecordSubscribeStatus) {
        guard let subscribeHelper = self.delegate else {
            DocsLogger.btError("store record subscribe status failed, delegate is nil")
            return
        }
        return subscribeHelper.storeRecordSubscribeStatus(recordId: recordId, status: status)
    }
    
    func storeRecordAutoSubscribeStatus(recordId: String, status: BTRecordAutoSubStatus) {
        guard let subscribeHelper = self.delegate else {
            DocsLogger.btError("store record autoSubscribe status failed, delegate is nil")
            return
        }
        return subscribeHelper.storeRecordAutoSubscribeStatus(recordId: recordId, status: status)
    }
    
    func recordEnableSubscribe(record: BTRecordModel) -> Bool {
        guard let subscribeHelper = self.delegate else {
            DocsLogger.btError("record enable subscribe failed, delegate is nil")
            return false
        }
        if record.isArchvied {
            // 被归档的记录不能被订阅
            DocsLogger.btInfo("record can not subscribe, record is isArchvied")
            return false
        }
        return subscribeHelper.recordEnableSubscribe(baseContext:viewModel.baseContext, viewMode: record.viewMode)
    }
    
    private func showAutoSubscribeAlertView(recordId: String) {
        if SKDisplay.pad {
            showAutoSubscribeAlertViewifIPad(recordId)
        } else {
            showAutoSubscribeAlertViewifPhone()
        }
    }
    
    private func showAutoSubscribeAlertViewifPhone() {
        let subscribeAlertView = BTRecordAutoSubscribeAlertView.init(closeAutoSubscribeCallBack: { [weak self] in
            guard let self = self else {
                DocsLogger.btError("record update autoSubscribe failed")
                return
            }
            self.updateAutoSubscribeStatus(behaviour: .confirmNoAutoSubscribe)
            self.trackAutoSubscribeAlertViewClick(isCloseAutoSubscribe: true)
        }, cancelCallBack: { [weak self] in
            guard let self = self else {
                DocsLogger.btError("record update autoSubscribe cancel failed")
                return
            }
            self.updateAutoSubscribeStatus(behaviour: .cancel)
            self.trackAutoSubscribeAlertViewClick(isCloseAutoSubscribe: false)
        })
        view.addSubview(subscribeAlertView)
        subscribeAlertView.snp.makeConstraints { make in
            make.left.right.bottom.top.equalToSuperview()
        }
        subscribeAlertView.showAppearAnimation()
        trackShowAutoSubscribeAlertView()
    }
    
    private func showAutoSubscribeAlertViewifIPad(_ recordId: String) {
        guard let card = currentCard, let subscribePV = card.headerView.subscribeButton.superview else {
            DocsLogger.btError("showAutoSubscribeAlertViewifIPad failed because layer error")
            return
        }
        guard recordId == card.recordID else {
            DocsLogger.btError("showAutoSubscribeAlertViewifIPad failed because of recordId")
            return
        }
        let panel = BTRecordAutoSubscribeAlertController { [weak self] in
            guard let self = self else {
                DocsLogger.btError("record update autoSubscribe failed")
                return
            }
            self.updateAutoSubscribeStatus(behaviour: .confirmNoAutoSubscribe)
            self.trackAutoSubscribeAlertViewClick(isCloseAutoSubscribe: true)
        } cancelCallBack: { [weak self] in
            guard let self = self else {
                DocsLogger.btError("record update autoSubscribe cancel failed")
                return
            }
            self.updateAutoSubscribeStatus(behaviour: .cancel)
            self.trackAutoSubscribeAlertViewClick(isCloseAutoSubscribe: false)
        }
        let sourceRect = self.view.convert(card.headerView.subscribeButton.frame, from: subscribePV)
        panel.modalPresentationStyle = .popover
        panel.preferredContentSize = panel.alertContentSize
        panel.popoverPresentationController?.sourceView = self.view
        panel.popoverPresentationController?.sourceRect = sourceRect
        panel.popoverPresentationController?.permittedArrowDirections = [.up]
        panel.popoverPresentationController?.backgroundColor = UDColor.bgFloatBase.withAlphaComponent(0.9)
        present(panel, animated: true)
        trackShowAutoSubscribeAlertView()
    }
    
    private func disableCurrentBaseAutoSubscribe() {
        isCloseRecordAutoSubscribe = true
    }
    
    private func updateAutoSubscribeStatus(behaviour: BTRecordAutoSubscribeAlertBehavior) {
        switch behaviour {
        case .confirmNoAutoSubscribe:
            self.viewModel.updateAutoSubscribeStatus(token: viewModel.baseContext.baseToken, behaviour: .confirmNoAutoSubscribe) { [weak self] editNoNeedToSubscribe in
                guard let self = self else {
                    return
                }
                if editNoNeedToSubscribe {
                    self.disableCurrentBaseAutoSubscribe()
                }
            }
        case .cancel:
            self.viewModel.updateAutoSubscribeStatus(token: viewModel.baseContext.baseToken, behaviour: .cancel)
        }
    }
    
    private func trackRecordSubscribeBehaviour(recordId: String, isSubscribe: Bool, isPassive: Bool) {
        guard let card = currentCard else { return }
        var trackParams = viewModel.getCommonTrackParams()
        if !isPassive {
            if card.viewMode.isIndRecord {
                let clickValue = isSubscribe ? "subscribe" : "cancel_subscribe"
                trackParams["target"] = "none"
                trackParams["click"] = clickValue
                DocsTracker.newLog(enumEvent: .bitableShareClick, parameters: trackParams)
            } else {
                let clickValue = isSubscribe ? "subscribe" : "cancel_subscribe"
                trackParams["target"] = "none"
                trackParams["click"] = clickValue
                DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: trackParams)
            }
        } else {
            trackParams["target"] = "none"
            trackParams["click"] = "subscribe"
            DocsTracker.newLog(enumEvent: .bitableCardAutoSubscribeClick, parameters: trackParams)
        }
    }
    
    private func trackShowAutoSubscribeAlertView() {
        let trackParams = viewModel.getCommonTrackParams()
        DocsTracker.newLog(enumEvent: .bitableRecordUnsubscribeView, parameters: trackParams)
    }
    
    private func trackAutoSubscribeAlertViewClick(isCloseAutoSubscribe: Bool) {
        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = isCloseAutoSubscribe ? "cancel_subscribe" : "cancel"
        trackParams["target"] = "none"
        DocsTracker.newLog(enumEvent: .bitableRecordUnsubscribeViewClick, parameters: trackParams)
    }
    //MARK: 订阅相关 end

    func didScrollUp() {
        delegate?.cardDidScrollUp(isForm: viewModel.mode.isForm)
    }

    func didScrollDown() {
        delegate?.cardDidScrollDown(isForm: viewModel.mode.isForm)
    }
    
    func didScroll(_ scrollView: UIScrollView) {
        delegate?.cardDidScroll(scrollView, isForm: viewModel.mode.isForm)
    }

    func didScrollToField(id: String, recordID: String) {
        guard recordID == currentCard?.recordID else { return }
        
        if !UserScopeNoChangeFG.ZJ.btCardReform {
            diffableDataSource?.updateTopFieldID(id)
        }

        if isPresenterRole {
            currentStatusChange(topFieldId: id)
        }
    }
    
    func didEndScrollingAnimation(in: BTRecord) {
        guard let editingField = currentEditingField, let currentCard = currentCard else {
            return
        }
        (editingField as? BTFieldCollectionScrollEventObserver)?.fieldCollectionDidEndScrollingAnimation()
    }
    
    // 即将被删除的方法，请不要再使用
    private func getCopyPermissionTokens() -> (baseToken: String, objToken: String?) {
        if viewModel.mode.isIndRecord {
            // 分享 Record 模式下，文档 url token 实际是 record 的 shareToken
            // 权限校验时用前端传来的 base token
            let baseToken = viewModel.actionParams.data.baseId
            return (baseToken, baseToken)
        }
        if UserScopeNoChangeFG.YY.bitableReferPermission {
            let baseToken = viewModel.actionParams.data.baseId
            let objToken = viewModel.dataService?.hostDocInfo.token
            return (baseToken, objToken)
        }
        let baseToken = viewModel.dataService?.hostDocInfo.token ?? ""
        // 这里保留之前线上的逻辑，objToken 实际映射的是 url 解析的 token
        let objToken = viewModel.dataService?.hostDocInfo.objToken
        return (baseToken, objToken)
    }
    
    func getCopyPermission() -> BTCopyPermission? {
        if UserScopeNoChangeFG.YY.bitableReferPermission {
            return viewModel.baseContext.copyOrCutAvailability
        }
        return delegate?.cardGetCopyPermission(getCopyPermissionTokens())
    }
    
    func textViewOfField(_ field: BTFieldModel, shouldAppyAction action: BTTextViewMenuAction) -> Bool {
        let event: DocsTracker.EventType = field.editable ? .bitableEditMenuClick : .bitableReadMenuClick
        viewModel.trackEvent(eventType: event.rawValue, params: ["click": action.rawValue])
        if UserScopeNoChangeFG.ZYS.recordCopySupportRevert, viewModel.mode.isIndRecord {
            // 记录分享场景下，和 web Android 对齐，暂不支持复制
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_ShareSingleRecord_CannotCopyRecord_Desc, on: self.view)
            return false
        }
        switch action {
        case .copy, .cut:
            if UserScopeNoChangeFG.YY.bitableReferPermission {
                return viewModel.baseContext.checkCopyOrCutAvailabilityWithToast(view: self.view)
            }
            let copyPermission = delegate?.cardGetCopyPermission(getCopyPermissionTokens())
            switch copyPermission {
            case .allow, .allowBySingleDocumentProtect:
                return true
            case let .fromPermissionSDK(response):
                // cardGetCopyPermission 方法不走 permissionSDK，先简单处理
                spaceAssertionFailure("cardGetCopyPermission should never return fromPermissionSDK result")
                if response.allow {
                    return true
                }
            default: break
            }
            let docsInfo = editorDocsInfo
            BTUtil.showToastWhenCopyProhibited(copyPermisson: copyPermission, isSameTenant: docsInfo.isSameTenantWithOwner, on: view, token: docsInfo.token)
            PermissionStatistics.shared.reportDocsCopyClick(isSuccess: false)
            return false
        }
    }
    
    func presentViewController(_ vc: UIViewController) {
        Navigator.shared.present(vc, from: self)
    }
    
    func didClickGeoLocation(_ geoLocation: BTGeoLocationModel, on field: BTFieldCellProtocol) {
        guard let location = geoLocation.location else {
            return
        }
        guard geoLocation.isLocationValid else {
            DocsLogger.error("geo location is invalid:(\(location.latitude), \(location.longitude))")
            if let window = view.window {
                UDToast.showFailure(with: BundleI18n.SKResource.Bitable_Field_UnableToOpenMap, on: window)
            }
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let setting = LocationSetting(
            name: geoLocation.name ?? "", // POI name
            description: geoLocation.fullAddress ?? "", // POI address
            center: coordinate,
            zoomLevel: 14.5,
            isCrypto: false
        )
        let targetVC = OpenLocationController(setting: setting)
        Navigator.shared.push(targetVC, from: self)
        
        
        let params: [String: Any] = [
            "input_type": field.fieldModel.property.inputType.trackText,
            "click": "words",
            "target": "none"
        ]
        viewModel.trackEvent(eventType: DocsTracker.EventType.bitableGeoCardClick.rawValue, params: params)
    }
    
    func track(event: String, params: [String: Any]) {
        viewModel.trackEvent(eventType: event, params: params)
    }
    
    func didClickRetry(request: BTGetCardListRequest) {
        viewModel.fetchDataManager.disposeRequest(request: request)
    }
    // CTA Notice 点击更多
    func didClickCTANoticeMore() {
        self.delegate?.didClickCTANoticeMore(with: viewModel.actionParams)
    }
    // 阶段详情点击终止流程
    func didClickStageDetailCancel(sourceView: UIView, fieldModel: BTFieldModel, cancelOptionId: String) {
        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
        let tips = BundleI18n.SKResource.Bitable_Flow_RecordCard_ConfirmEndFlow_PopUp_Title
        let textLabel = UILabel()
        textLabel.font = UDFont.title4
        textLabel.text = tips
        textLabel.numberOfLines = 1

        // 24为文字两边的边距
        let preferredContentWidth = textLabel.intrinsicContentSize.width + 24
        let source = UDActionSheetSource(sourceView: sourceView,
                                         sourceRect: sourceView.bounds,
                                         preferredContentWidth: preferredContentWidth)

        var config: UDActionSheetUIConfig
        if SKDisplay.pad {
            config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
        } else {
            config = UDActionSheetUIConfig(isShowTitle: true)
        }
        
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(tips)
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Flow_RecordCard_EndStep_Text, textColor: UDColor.functionDangerContentDefault) { [weak self] in
            guard let self = self else {
                return
            }
            // 终止流程
            let params: [String: Any] = [
                "router": StageAsyncRequestRouter.markStageCanceled.rawValue,
                "tableId": self.viewModel.tableModel.tableID,
                "baseId": self.viewModel.tableModel.baseID,
                "data": [
                    "baseId": self.viewModel.tableModel.baseID,
                    "fieldId": fieldModel.fieldID,
                    "optionId": cancelOptionId,
                    "recordId": self.currentCard?.recordID ?? "",
                ],
            ]
            self.viewModel.dataService?.asyncJsRequest(biz: .stage,
                                                       funcName: .asyncJsRequest,
                                                       baseId: self.viewModel.tableModel.baseID,
                                                       tableId: self.viewModel.tableModel.tableID,
                                                       params: params,
                                                       overTimeInterval: 10,
                                                       responseHandler: { reponse in
                                                           DocsLogger.btInfo("[Stage Detail] Cancel Stage Response \(reponse)")
                                                       }, resultHandler: { result in
                                                           DocsLogger.btInfo("[Stage Detail] Cancel Stage Result \(result)")
                                                       })
            if let recordId = self.currentCard?.recordID {
                self.viewModel.dataService?.triggerPassiveRecordSubscribeIfNeeded(recordId: recordId)
            }
            DocsLogger.btInfo("[Stage Detail] stage detail click cancel")
            var trackParams = ["click": "stage_suspend",
                               "card_type": self.currentCardPresentMode == .card ? "card" : "drawer"]
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                trackParams["version"] = "v2"
            }
            
            self.track(event: DocsTracker.EventType.bitableCardClick.rawValue, params: trackParams)
        }

        actionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_Common_ButtonCancel)
        self.deleteActionSheet = actionSheet
        Navigator.shared.present(actionSheet, from: self)
    }
    
    // 阶段字段点击完成流程
    func didClickStageDetailDone(fieldModel: BTFieldModel, currentOptionId: String) {
        let params: [String: Any] = [
            "router": StageAsyncRequestRouter.markStepDone.rawValue,
            "tableId": viewModel.tableModel.tableID,
            "baseId": viewModel.tableModel.baseID,
            "data": [
                "fieldId": fieldModel.fieldID,
                "optionId": currentOptionId,
                "recordId": currentCard?.recordID ?? "",
                "stackViewId": viewModel.tableMeta.stackViewId ?? ""
            ]
        ]
        DocsLogger.btInfo("[Stage Detail] click finish stage")

        var trackParams = ["click": "stage_node_complete",
                           "target": "none",
                           "card_type": currentCardPresentMode == .card ? "card" : "drawer"
                          ]
        
        if UserScopeNoChangeFG.ZJ.btCardReform {
            trackParams["version"] = "v2"
        }
        self.track(event: DocsTracker.EventType.bitableCardClick.rawValue, params: trackParams)
        self.viewModel.dataService?.asyncJsRequest(biz: .stage,
                                                   funcName: .asyncJsRequest,
                                                   baseId: viewModel.tableModel.baseID,
                                                   tableId: viewModel.tableModel.tableID,
                                                   params: params,
                                                   overTimeInterval: 10,
                                                   responseHandler: { [weak self] reponse in
            switch reponse {
            case let .success(data):
                if data.result == 0, fieldModel.property.stages.last(where: { $0.type == .defualt })?.id == currentOptionId {
                self?.showAnimation()
            }
            case .failure:
                break
            }
            DocsLogger.btInfo("[Stage Detail] Done Stage Response \(reponse)")
        }, resultHandler: { result in
            DocsLogger.btInfo("[Stage Detail] Done Stage Result \(result)")
        })
        if let recordId = self.currentCard?.recordID {
            self.viewModel.dataService?.triggerPassiveRecordSubscribeIfNeeded(recordId: recordId)
        }
    }
    
    
    private func showAnimation() {
        guard !animationView.isAnimationPlaying, let view = view else { return }
        view.addSubview(animationView)
        let size = Display.pad ? 400 : 250
        animationView.frame.size = CGSize(width: size, height: size)
        animationView.frame.center = view.center
        animationView.play() { [weak self] _ in
            self?.animationView.removeFromSuperview()
        }
    }
    
    func stageDetailFieldClickRevert(sourceView: UIView, fieldModel: BTFieldModel, currentOptionId: String) {
        BTUtil.forceInterfaceOrientationIfNeed(to: .portrait)
        let optionName = fieldModel.property.stages.first(where: { $0.id == currentOptionId })?.name ?? ""
        let tips = BundleI18n.SKResource.Bitable_Flow_RecordCard_Mobile_ConfirmBackToStep_Desc(optionName)
        let textLabel = UILabel()
        textLabel.font = UDFont.title4
        textLabel.text = tips
        
        //24为文字两边的边距, 40为popover距离卡片左右的间距
        let preferredContentWidth: CGFloat
        if UserScopeNoChangeFG.ZJ.btCardReform {
            textLabel.numberOfLines = 0
            preferredContentWidth = min(textLabel.intrinsicContentSize.width + 24, currentCard?.frame.width ?? cardMinWidthOnCardMode - 40 * 2)
        } else {
            textLabel.numberOfLines = 1
            preferredContentWidth = textLabel.intrinsicContentSize.width + 24
        }
        let source = UDActionSheetSource(sourceView: sourceView,
                                         sourceRect: sourceView.bounds,
                                         preferredContentWidth: preferredContentWidth)
        
        var config: UDActionSheetUIConfig
        if SKDisplay.pad {
            config = UDActionSheetUIConfig(isShowTitle: true, popSource: source)
        } else {
            config = UDActionSheetUIConfig(isShowTitle: true)
        }
        
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(tips)
        actionSheet.addItem(text: BundleI18n.SKResource.Bitable_Flow_RecordCard_Mobile_ConfirmBackToStep_ConfirmButton,
                            textColor: UDColor.functionDangerContentDefault) { [weak self] in
            guard let self = self else {
                return
            }
            let params: [String: Any] = [
                "router": StageAsyncRequestRouter.revertStep.rawValue,
                "tableId": self.viewModel.tableModel.tableID,
                "baseId": self.viewModel.tableModel.baseID,
                "data": [
                    "fieldId": fieldModel.fieldID,
                    "optionId": currentOptionId,
                    "recordId": self.currentCard?.recordID ?? ""
                ]
            ]
            
            var trackParams = ["click": "stage_rollback",
                               "target": "none",
                               "card_type": self.currentCardPresentMode == .card ? "card" : "drawer"
                              ]
            
            if UserScopeNoChangeFG.ZJ.btCardReform {
                trackParams["version"] = "v2"
            }
            
            self.track(event: DocsTracker.EventType.bitableCardClick.rawValue, params: trackParams)
            self.viewModel.dataService?.asyncJsRequest(biz: .stage,
                                                       funcName: .asyncJsRequest,
                                                       baseId: self.viewModel.tableModel.baseID,
                                                       tableId: self.viewModel.tableModel.tableID,
                                                       params: params,
                                                       overTimeInterval: 10,
                                                       responseHandler: { reponse in
                DocsLogger.btInfo("[Stage Detail] Revert Stage Response \(reponse)")
            }, resultHandler: { result in
                DocsLogger.btInfo("[Stage Detail] Revert Stage Result \(result)")
            })
            if let recordId = self.currentCard?.recordID {
                self.viewModel.dataService?.triggerPassiveRecordSubscribeIfNeeded(recordId: recordId)
            }
        }
        actionSheet.setCancelItem(text: BundleI18n.SKResource.Bitable_Flow_RecordCard_Mobile_ConfirmBackToStep_CancelButton)
        self.deleteActionSheet = actionSheet
        Navigator.shared.present(actionSheet, from: self)
    }
    
    func stageDetailFieldClickRecover(fieldModel: BTFieldModel) {
        let params: [String: Any] = [
            "router": StageAsyncRequestRouter.markStageRecover.rawValue,
            "tableId": viewModel.tableModel.tableID,
            "baseId": viewModel.tableModel.baseID,
            "data": [
                "fieldId": fieldModel.fieldID,
                "recordId": currentCard?.recordID ?? ""
            ]
        ]
        
        var trackParams = ["click": "stage_recover",
                           "target": "none",
                           "card_type": self.currentCardPresentMode == .card ? "card" : "drawer"
                          ]
        
        if UserScopeNoChangeFG.ZJ.btCardReform {
            trackParams["version"] = "v2"
        }
        
        self.track(event: DocsTracker.EventType.bitableCardClick.rawValue, params: trackParams)
        self.viewModel.dataService?.asyncJsRequest(biz: .stage,
                                                   funcName: .asyncJsRequest,
                                                   baseId: viewModel.tableModel.baseID,
                                                   tableId: viewModel.tableModel.tableID,
                                                   params: params,
                                                   overTimeInterval: 500,
                                                   responseHandler: { reponse in
            DocsLogger.btInfo("[Stage Detail] Revert Stage Response \(reponse)")
        }, resultHandler: { result in
            DocsLogger.btInfo("[Stage Detail] Revert Stage Result \(result)")
        })
        if let recordId = self.currentCard?.recordID {
            self.viewModel.dataService?.triggerPassiveRecordSubscribeIfNeeded(recordId: recordId)
        }
    }
    
    func didClickTab(index: Int, recordID: String) {
        guard let recordIndex = viewModel.tableModel.records.firstIndex(where: { $0.recordID == recordID }) else {
            return
        }
        var recordModel = viewModel.tableModel.records[recordIndex]
        
        guard index >= 0, index < recordModel.itemViewTabs.count else {
            return
        }
        
        let clickTab = recordModel.itemViewTabs[index]
        var trackParams = viewModel.getCommonTrackParams()
        
        switch clickTab.type {
        case .detail:
            recordModel.update(viewMode: viewModel.mode)
            recordModel.resetStageFieldType()
            // 点击stage tab埋点上报
            trackParams["click"] = "tab_detail"
        case .stage:
            recordModel.update(viewMode: .stage(origin: viewModel.mode))
            // 点击stage tab埋点上报
            
            trackParams["click"] = "tab_stage"
            trackParams["target"] = "ccm_bitable_stage_field_detail_setting_view"
        }
        
        trackParams["version"] = "v2"
        trackParams["card_type"] = currentCardPresentMode == .card ? "card" : "drawer"
        DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: trackParams)
        recordModel.update(currentItemViewIndex: index)
        recordModel.resetFieldsErrorMsg()
        if let tabsIndex = recordModel.wrappedFields.firstIndex(where: { $0.extendedType == .itemViewTabs }) {
            var tabsModel = recordModel.wrappedFields[tabsIndex]
            tabsModel.update(currentItemViewIndex: index)
            recordModel.update(tabsModel, for: tabsIndex)
        }
        viewModel.tableModel.updateRecord(recordModel, for: recordIndex)
        
        updateModel(viewModel.tableModel)
    }
    
    func didChangeStage(recordID: String,
                        stageFieldId: String,
                        selectOptionId: String) {
        guard let recordIndex = viewModel.tableModel.records.firstIndex(where: { $0.recordID == recordID }) else {
            return
        }
        
        var recordModel = viewModel.tableModel.records[recordIndex]
        // 切换阶段，字段的错误信息需要清除
        recordModel.resetFieldsErrorMsg()
        if let stageFieldIndex = recordModel.wrappedFields.firstIndex(where: { $0.fieldID == stageFieldId }) {
            var stageFieldModel = recordModel.wrappedFields[stageFieldIndex]
            stageFieldModel.update(currentStageOptionId: selectOptionId)
            recordModel.update(stageFieldModel, for: stageFieldIndex)
        }
        
        viewModel.tableModel.updateRecord(recordModel, for: recordIndex)
        updateModel(viewModel.tableModel)
    }
    
    func hideSwitchCardBottomPanelView(hidden: Bool) {
        updateSwitchCardBottomPanelViewVisibility(visible: !hidden)
    }
    
    func didClickCatalogueBaseName() {
        let baseURL = DocsUrlUtil.url(type: .bitable, token: viewModel.tableModel.baseID)
            .docs
            .addOrChangeEncodeQuery(
                parameters: [
                    CCMOpenTypeKey: "quickadd_topbar"
                ]
            )
        openUrl(baseURL.absoluteString)
    }
    
    func didClickCatalogueTableName() {
        let baseURL = DocsUrlUtil.url(type: .bitable, token: viewModel.tableModel.baseID)
            .docs
            .addOrChangeEncodeQuery(
                parameters: [
                    "table": viewModel.tableModel.tableID,
                    CCMOpenTypeKey: "quickadd_topbar"
                ]
            )
        openUrl(baseURL.absoluteString)
    }
}

extension BTController: DriveSDKAttachmentDelegate {
    func onAttachmentClose() {
        DocsLogger.btInfo("[ACTION] onAttachmentClose")
        self.currentPreviewAttachmentBTFieldID = nil
        self.currentPreviewAttachmentToken = nil
    }
    
    func onAttachmentSwitch(to index: Int, with fileID: String) {
        DocsLogger.btInfo("[ACTION] onAttachmentSwitch: \(index)")
        guard let curFieldID = currentPreviewAttachmentBTFieldID,
              let fieldModel = currentCard?.recordModel.getFieldModel(id: curFieldID) else {
            DocsLogger.btError("[ACTION] cannot find fieldModel")
            return
        }
        guard let currentAttachment = fieldModel.attachmentValue.first(where: { $0.attachmentToken == fileID }),
              let indexInAttachments = fieldModel.attachmentValue.firstIndex(where: { $0.attachmentToken == fileID }) else {
            DocsLogger.btError("[ACTION] cannot find current attachment")
            return
        }
        let isSwitch = self.currentPreviewAttachmentToken != nil
        self.currentPreviewAttachmentToken = fileID
        
        if isSwitch {
            logAttachmentEvent(action: "switch", attachmentCount: nil)
        }
        
        guard self.spaceFollowAPIDelegate != nil else { return }
        //MagicShare兼容旧版本逻辑，因为旧版本不支持一次打开多个附件，这里在切换附件时模拟一个一个打开
        //1.先关闭前一个附件
        viewModel.bizData.jsFuncService?.callFunction(DocsJSCallBack.onAttachFileExit, params: [:], completion: nil)
        
        //2.打开新的附件
        let attachFileParams: [String: Any] =
        ["bussinessId": "bitable_attach",
         "file_token": currentAttachment.attachmentToken,
         "mount_node_token": currentAttachment.mountToken,
         "mount_point": currentAttachment.mountPointType,
         "file_size": currentAttachment.size,
         "file_mime_type": currentAttachment.mimeType,
         "extra": currentAttachment.extra,
         "fieldId": curFieldID,
         "index": indexInAttachments,
         "table_id": self.viewModel.actionParams.data.tableId,
         "recordId": self.currentCard?.recordID ?? "",
         "from": ENativeOpenAttachFrom.cardAttachPreview.rawValue]
        self.spaceFollowAPIDelegate?.follow(self,
                                            onOperate: .nativeStatus(funcName:
                                                                        DocsJSCallBack.notifyAttachFileOpen.rawValue,
                                                                     params: attachFileParams))
    }

    func handleEmitEvent(event: BTEmitEvent, router: BTAsyncRequestRouter) {
        switch event {
        case .dataLoaded:
            if let linkEditAgent = currentEditAgent as? BTLinkEditAgent {
                linkEditAgent.handleEmitEvent(event: event, router: router)
            }
            
            if let linkedController = linkedController {
                DocsLogger.btInfo("[EmitEvent] linkedController handle dataLoaded router:\(router)")
                if let linkEditAgent = linkedController.currentEditAgent as? BTLinkEditAgent {
                    linkEditAgent.handleEmitEvent(event: event, router: router)
                }
                //有关联卡片，向上抛
                linkedController.handleEmitEvent(event: event, router: router)
            }
            
            viewModel.handleDataLoaded(router: router)
        }
    }
    
    func updateButtonFieldStatus(to status: BTButtonFieldStatus,
                                 inRecordWithID recordID: String,
                                 inFieldWithID fieldID: String) {
        viewModel.tableModel.update(recordID: recordID, fieldID: fieldID, buttonStatus: status)
        didUpdateModel(model: viewModel.tableModel)
    }
    
    func didClickButtonField(inRecordWithID recordID: String, inFieldWithID fieldID: String) {
        DocsLogger.btInfo("[BTButton] click")
        let params: [String: Any] = ["router": BTAsyncRequestRouter.clickButtonField.rawValue,
                                     "tableId": viewModel.actionParams.data.tableId,
                                     "data": ["tableId": viewModel.actionParams.data.tableId,
                                              "viewId": viewModel.actionParams.data.viewId,
                                              "recordId": recordID,
                                              "fieldId": fieldID]]
        
        func showFailureToast(message: String) {
            removeToast()
            UDToast.showFailure(with: message, on: self.rootWindow() ?? self.view)
        }
        
        func removeToast() {
            UDToast.removeToast(on: self.rootWindow() ?? self.view)
        }
        
        viewModel.dataService?.asyncJsRequest(biz: .card,
                                              funcName: .asyncJsRequest,
                                              baseId: viewModel.actionParams.data.baseId,
                                              tableId: viewModel.actionParams.data.tableId,
                                              params: params,
                                              overTimeInterval: nil,
                                              responseHandler: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let data):
                guard data.result == BTButtonFieldTriggerResultCode.success.rawValue else {
                    DocsLogger.btError("[BTButton] click response failed result:\(data.result)")
                    self.updateButtonFieldStatus(to: .general, inRecordWithID: recordID, inFieldWithID: fieldID)
                    if data.result == BTButtonFieldTriggerResultCode.failed.rawValue {
                        let errorMsg = data.errorResult.isEmpty ? BundleI18n.SKResource.Bitable_Automation_ClickButton_LoadingActionFailed_Toast("-1") : data.errorResult
                        showFailureToast(message: errorMsg)
                    }
                    return
                }
                removeToast()
                self.updateButtonFieldStatus(to: .done, inRecordWithID: recordID, inFieldWithID: fieldID)
            case .failure(let error):
                DocsLogger.btError("[BTButton] click response failed code:\(error.code)")
                self.updateButtonFieldStatus(to: .general, inRecordWithID: recordID, inFieldWithID: fieldID)
                showFailureToast(message: BundleI18n.SKResource.Bitable_Automation_ClickButton_LoadingActionFailed_Toast("-1"))
            }
        },
                                              resultHandler: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                DocsLogger.btInfo("[BTButton] click request success")
                self.updateButtonFieldStatus(to: .loading, inRecordWithID: recordID, inFieldWithID: fieldID)
            case .failure:
                DocsLogger.btError("[BTButton] click request failed")
                self.updateButtonFieldStatus(to: .general, inRecordWithID: recordID, inFieldWithID: fieldID)
                showFailureToast(message: BundleI18n.SKResource.Bitable_Automation_ClickButton_LoadingActionFailed_Toast("-1"))
            }
        })
    }
    
    func getCurrentRecordIndex() -> (current: Int, total: Int)? {
        let recordID = viewModel.currentRecordID
        let currentIndex: Int
        if viewModel.mode == .link {
            currentIndex = viewModel.recordIDs.firstIndex(where: { $0 == recordID }) ?? 0
        } else if viewModel.currentRecordIndex >= 0, viewModel.currentRecordIndex < viewModel.tableValue.records.count {
            currentIndex = viewModel.tableValue.records[viewModel.currentRecordIndex].globalIndex
        } else {
            return nil
        }
        let total = viewModel.tableValue.total
        return (current: currentIndex, total: total)
    }
    
    func switchCardToLeft() {
        viewModel.fpsTrace.startRecordListScrollToAndAutoStop()
        DocsLogger.btInfo( "[action] switch to left card")
        let index = self.viewModel.currentRecordIndex - 1
        showBitableNotReadyToast()
        revertAttachmentCoverIfNeeded(index: index)
        scrollToDesignatedCard(at: index, animated: true) {
            self.switchCard(pageIndex: index, fetch: true)
            /// 更新悬浮窗下标
            self.switchCardBottomPanelView.updateTextLabel()
        }
        
        // 左翻页埋点上报
        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = "previous_record"
        trackParams["target"] = "none"
        trackParams["card_type"] = currentCardPresentMode == .card ? "card" : "drawer"
        trackParams["version"] = "v2"
        DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: trackParams)
    }
    
    func switchCardToRight() {
        viewModel.fpsTrace.startRecordListScrollToAndAutoStop()
        DocsLogger.btInfo( "[action] switch to right card")
        let index = self.viewModel.currentRecordIndex + 1
        showBitableNotReadyToast()
        revertAttachmentCoverIfNeeded(index: index)
        scrollToDesignatedCard(at: index, animated: true) {
            self.switchCard(pageIndex: index, fetch: true)
            /// 更新悬浮窗下标
            self.switchCardBottomPanelView.updateTextLabel()
        }
        
        // 右翻页埋点上报
        var trackParams = viewModel.getCommonTrackParams()
        trackParams["click"] = "next_record"
        trackParams["target"] = "none"
        trackParams["card_type"] = currentCardPresentMode == .card ? "card" : "drawer"
        trackParams["version"] = "v2"
        DocsTracker.newLog(enumEvent: .bitableCardClick, parameters: trackParams)
    }

    private func revertAttachmentCoverIfNeeded(index: Int) {
        guard let pageCount = diffableDataSource?.getRecordCount() else {
            return
        }
        guard index >= 0, index < pageCount, index < cardsView.numberOfItems(inSection: 0) else {
            return
        }
        let indexPath = IndexPath(item: index, section: 0)
        guard let recordCell = cardsView.cellForItem(at: indexPath) as? BTRecord else {
            return
        }
        recordCell.fieldsView.revertAttachmentCover()
    }
    
    func getRecordHeaderCloseIconType() -> CloseIconType {
        guard !UserScopeNoChangeFG.QYK.btSideCardCloseFixDisable else {
            return self.currentCardPresentMode == .card ? .closeOutlined : .leftOutlined
        }
        
        if SKDisplay.pad, !self.viewModel.mode.isLinkedRecord {
            return .closeOutlined
        } else {
            return .leftOutlined
        }
    }
}

extension BTController: ShareViewControllerDelegate, ShareRouterAbility {
    func requestShareToLarkServiceFromViewController() -> UIViewController? {
        return self
    }
    
    func didShareViewClicked(assistType: ShareAssistType) {
        if viewModel.mode == .addRecord {
            guard UserScopeNoChangeFG.YY.baseAddRecordPage else {
                return
            }
        } else if viewModel.mode == .submit {
            guard UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable else {
                return
            }
        } else {
           return
        }
        var trackParams = viewModel.getCommonTrackParams()
        trackParams["target"] = "none"
        if assistType == .feishu {
            trackParams["click"] = "share_to_feishu"
        } else if assistType == .fileLink {
            trackParams["click"] = "copy_link"
        } else if assistType == .qrcode {
            trackParams["click"] = "qrcode"
        }
        if viewModel.mode == .submit {
            DocsTracker.newLog(enumEvent: .bitableRecordCreateClick, parameters: trackParams)
        } else if viewModel.mode == .addRecord {
            trackParams["share_type"] = "record"
            trackParams["record_type"] = "add_record"
            DocsTracker.newLog(enumEvent: .bitableShareClick, parameters: trackParams)
        }
    }
}

extension BTController: SKShareHandlerProvider {
    var shareToLarkHandler: ShareToLarkService.ContentType.TextShareCallback? {
        { [weak self] userIds, chatIds in
            DispatchQueue.main.async {
                guard let wrapper = self?.view.affiliatedWindow else {
                    DocsLogger.error("share to lark callback, toast failed due to nil self or window")
                    return
                }
                guard !userIds.isEmpty || !chatIds.isEmpty else {
                    DocsLogger.error("share to lark callback, toast failed due to empty object")
                    return
                }
                UDToast.showSuccess(with: BundleI18n.SKResource.CreationMobile_mention_sharing_success, on: wrapper)
            }
        }
    }
}
