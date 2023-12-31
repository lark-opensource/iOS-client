//
//  BTController+AddRecord.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/13.
//

import SKFoundation
import SKResource
import SKBrowser
import UniverseDesignToast
import UniverseDesignDialog
import SKUIKit

extension BTController {
    
    var openFileTraceId: String {
        return (delegate?.cardGetBrowserController() as? BrowserViewController)?.fileConfig?.getOpenFileTraceId() ?? ""
    }
    
    func didClickSubmitView() {
        if let uploadStatus = self.delegate?.getUploadingStatus(baseID: self.viewModel.tableModel.baseID, tableID: self.viewModel.tableModel.tableID, recordID: self.viewModel.currentRecordID, fieldIDs: Array(self.viewModel.tableMeta.fields.keys)) {
            switch uploadStatus {
            case .uploading, .uploadingWithSomeUploadFailed:
                // 提示正在上传
                UDToast.showTips(with: BundleI18n.SKResource.Bitable_QuickAdd_UploadInProgress_Toast, on: self.view)
                return
            case .allUploaded:
                // 上传完成
                break
            case .uploadedWithSomeUploadFailed(let failedCount):
                // 有附件上传失败
                var dialog = UDDialog()
                dialog.setContent(text: BundleI18n.SKResource.Bitable_QuickAdd_NumFilesFailedUpload_PopUp_Desc(failedCount))
                dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_QuickAdd_NumFilesFailedUpload_Cancel_PopUp_Button, dismissCompletion:  { [weak self] in
                    guard let self = self else {
                        return
                    }
                })
                dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_QuickAdd_NumFilesFailedUpload_Submit_PopUp_Button, dismissCompletion:  { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.submitRecord()
                })
                self.present(dialog, animated: true)
                return
            }
        }
        submitRecord()
    }
    
    private func submitRecord() {
        
        EditorManager.shared.tryToPreload()
        
        // 不允许重复点击
        lockViewEditingDuringRecordSubmit()
        
        self.didClickHeaderButton(action: .confirm)
        
        if viewModel.mode == .submit {
            // 埋点 ccm_bitable_record_create_click
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "submit"
            trackParams["target"] = "ccm_bitable_card_view"
            DocsTracker.newLog(enumEvent: .bitableRecordCreateClick, parameters: trackParams)
        } else if viewModel.mode == .addRecord {
            BTRecordSubmitReportHelper.reportBaseAddRecordSubmitStart(cardVC: self)
            
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "submit"
            trackParams["target"] = "none"
            trackParams["share_type"] = "record"
            trackParams["record_type"] = "add_record"
            DocsTracker.newLog(enumEvent: .bitableShareClick, parameters: trackParams)
        }
    }
    
    func lockViewEditingDuringRecordSubmit() {
        DocsLogger.info("wait handleBaseAddSubmitResult start")
        if viewModel.mode == .addRecord {
            triggerAddRecordTimer()
            view.isUserInteractionEnabled = false
        } else if viewModel.mode == .submit {
            // TODO: 只锁编辑区域，原因是可能会有确认弹窗阻断用户操作，这里的超时时间不好计算
            view.isUserInteractionEnabled = false
        }
        
        submitView.update(iconType: .loading)
    }
    
    func unlockViewEditingAfterRecordSubmit() {
        DocsLogger.info("wait handleBaseAddSubmitResult end")
        if viewModel.mode == .addRecord {
            invalidAddRecordTimer()
            view.isUserInteractionEnabled = true
        } else {
            // TODO: 只锁编辑区域，原因是可能会有确认弹窗阻断用户操作，这里的超时时间不好计算
            view.isUserInteractionEnabled = true
        }
        submitView.update(iconType: .initial)
    }
    
    private func triggerAddRecordTimer() {
        let addRecordTimeout: TimeInterval = 25
        let timer = Timer(timeInterval: addRecordTimeout, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // 超时：客户端计时器结束，前端还未回调结果
            DocsLogger.error("wait handleBaseAddSubmitResult timeout")
            UDToast.showFailure(with: BundleI18n.SKResource.Bitable_QuickAdd_FailedSubmissionRetry_Toast, on: self.view)
            self.unlockViewEditingAfterRecordSubmit()
        }
        RunLoop.main.add(timer, forMode: .common)
        recordSubmitTimer = timer
    }
    
    private func invalidAddRecordTimer() {
        recordSubmitTimer?.invalidate()
        recordSubmitTimer = nil
    }
    
    func closeAddRecord(closeConfirm: @escaping (() -> Void), cancelCallback: (() -> Void)? = nil) -> Bool {
        if viewModel.mode == .submit {
            // 埋点 ccm_bitable_record_create_click
            var trackParams = viewModel.getCommonTrackParams()
            trackParams["click"] = "close"
            trackParams["target"] = "none"
            DocsTracker.newLog(enumEvent: .bitableRecordCreateClick, parameters: trackParams)
        }
        
        if !hasUnSubmitCellValue {
            closeConfirm()
            return false
        }
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.SKResource.Bitable_QuickAdd_NotSubmittedRecords_Desc)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Bitable_QuickAdd_ExitWhileEdit_Exit_Button, dismissCompletion:  { [weak self] in
            closeConfirm()
            guard let self = self else {
                return
            }
            if self.viewModel.mode == .submit {
                var trackParams = self.viewModel.getCommonTrackParams()
                trackParams["click"] = "quit"
                trackParams["target"] = "none"
                trackParams["type"] = "inside_base"
                DocsTracker.newLog(enumEvent: .bitableAddRecordQuitClick, parameters: trackParams)
            } else if self.viewModel.mode == .addRecord {
                var trackParams = self.viewModel.getCommonTrackParams()
                trackParams["click"] = "quit"
                trackParams["target"] = "none"
                trackParams["type"] = "individual_page"
                DocsTracker.newLog(enumEvent: .bitableAddRecordQuitClick, parameters: trackParams)
            }
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Bitable_QuickAdd_ExitWhileEdit_Continue_Button, dismissCompletion:  { [weak self] in
            cancelCallback?()
            guard let self = self else {
                return
            }
            if self.viewModel.mode == .submit {
                var trackParams = self.viewModel.getCommonTrackParams()
                trackParams["click"] = "cancel"
                trackParams["target"] = "none"
                trackParams["type"] = "inside_base"
                DocsTracker.newLog(enumEvent: .bitableAddRecordQuitClick, parameters: trackParams)
            } else if self.viewModel.mode == .addRecord {
                var trackParams = self.viewModel.getCommonTrackParams()
                trackParams["click"] = "cancel"
                trackParams["target"] = "none"
                trackParams["type"] = "individual_page"
                DocsTracker.newLog(enumEvent: .bitableAddRecordQuitClick, parameters: trackParams)
            }
        })
        self.present(dialog, animated: true)
        
        if viewModel.mode == .submit {
            // 埋点 ccm_bitable_add_record_quit_view
            var trackParams = self.viewModel.getCommonTrackParams()
            trackParams["type"] = "inside_base"
            DocsTracker.newLog(enumEvent: .bitableAddRecordQuitView, parameters: trackParams)
        } else if viewModel.mode == .addRecord {
            // 埋点 ccm_bitable_add_record_quit_view
            var trackParams = self.viewModel.getCommonTrackParams()
            trackParams["type"] = "individual_page"
            DocsTracker.newLog(enumEvent: .bitableAddRecordQuitView, parameters: trackParams)
        }
        return true
    }
    
    // V1 版本的手势拦截
    func setToggleSwipeGesture(navigationController: UINavigationController?) {
        guard UserScopeNoChangeFG.YY.bitableAddRecordGestureV2Disable else {
            return
        }
        guard let navigationController = navigationController else {
            DocsLogger.error("navigationController invalid")
            return
        }
        if navigationController.responds(to: #selector(getter: UINavigationController.interactivePopGestureRecognizer)) {
            navigationController.interactivePopGestureRecognizer?.addTarget(self, action: #selector(navReceivedPopGesture(_:)))
        }
    }
    
    @objc
    private func navReceivedPopGesture(_ recognizer: UIGestureRecognizer) {
        if recognizer.state == .began {
            guard hasUnSubmitCellValue else {
                return
            }
            guard !didDisAppear else {
                return
            }
            DocsLogger.btInfo("[BTController] navReceivedPopGesture")
            let originEnabled = recognizer.isEnabled
            let breaked = self.closeAddRecord { [weak self] in
                DocsLogger.btInfo("[BTController] navReceivedPopGesture confirm")
                recognizer.isEnabled = originEnabled
                // 必须 async 一下才能关成功
                DispatchQueue.main.async {
                    self?.closeThisCard()
                }
            } cancelCallback: {
                DocsLogger.btInfo("[BTController] navReceivedPopGesture cancel")
                recognizer.isEnabled = originEnabled
            }
            if breaked {
                DocsLogger.btInfo("[BTController] navReceivedPopGesture break")
                recognizer.isEnabled = false
            }
        }
    }
    
    // V2 版本的手势拦截
    
    // 以下时机需要更新
    // hasUnSubmitCellValue 变化时
    // VC didAppear 时
    func updateToggleSwipeGestureIfNeeded() {
        guard !UserScopeNoChangeFG.YY.bitableAddRecordGestureV2Disable else {
            return
        }
        let targetVC: UIViewController?
        if viewModel.mode == .submit, UserScopeNoChangeFG.YY.baseAddRecordPageShareEnable {
            targetVC = self
        } else if viewModel.mode == .addRecord {
            targetVC = self.delegate?.cardGetBrowserController()
        } else {
            return
        }
        guard let targetVC = targetVC else {
            return
        }
        if edgePanGesture == nil {
            let edgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
            self.edgePanGesture = edgePanGesture
            edgePanGesture.edges = .left
            view.addGestureRecognizer(edgePanGesture)
        }
        let shouldBreakGesture = hasUnSubmitCellValue
        targetVC.naviPopGestureRecognizerEnabled = !shouldBreakGesture
    }
    
    @objc 
    private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .began {
            guard hasUnSubmitCellValue else {
                return
            }
            guard !didDisAppear else {
                return
            }
            DocsLogger.btInfo("[BTController] navReceivedPopGesture break")
            _ = self.closeAddRecord { [weak self] in
                DocsLogger.btInfo("[BTController] navReceivedPopGesture confirm")
                // 必须 async 一下才能关成功
                DispatchQueue.main.async { [weak self] in
                    self?.closeThisCard()
                }
            } cancelCallback: {
                DocsLogger.btInfo("[BTController] navReceivedPopGesture cancel")
            }
        }
    }
}
