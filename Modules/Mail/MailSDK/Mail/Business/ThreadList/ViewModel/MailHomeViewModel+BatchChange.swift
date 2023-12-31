//
//  MailHomeViewModel+BatchChange.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/13.
//

import Foundation
import RxRelay
import RustPB
import RxSwift
import UniverseDesignToast

// MARK: - MailStrangerThreadCellDelegate
extension MailHomeViewModel {
    /// 后端处理数据迁移，需要block用户操作
    /// 清空垃圾/举报邮件场景
    func mailBatchChangesEnd(_ change: MailBatchEndChange) {
        guard sessionIDs.contains(change.sessionID) else {
            return
        }
        self.sessionIDs.lf_remove(object: change.sessionID)
        if change.code == 1 {
            self.$uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_ThreadList_Emptied, isSuccess: true, selecteAll: true, sessionID: ""))
        } else {
            self.$uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_ThreadList_ActionFailed, isSuccess: false, selecteAll: true, sessionID: ""))
        }
    }
    
    /// Stranger操作场景
    func mailBatchResultChanges(_ sessionInfos: [MailBatchChangeInfo]) {
        MailLogger.info("[mail_stranger] receive push by cache updated, sessions: \(sessionInfos.map({ $0.sessionID })) \(sessionInfos.map({ $0.status })) \(sessionInfos.map({ $0.progress }))")
        processLongTaskSessions(sessionInfos)
    }
    
    func showBatchChangeLoadingIfNeeded() {
        let sessionInfos = Store.settingData.getBatchChangeSessionInfos()
        MailLogger.info("[mail_stranger] longtask check local batch change, sessions: \(sessionInfos.map({ $0.sessionID })) \(sessionInfos.map({ $0.status }))")
        processLongTaskSessions(sessionInfos, showToast: false)
    }
    
    private func processLongTaskSessions(_ sessions: [MailBatchChangeInfo], showToast: Bool = true) {
        loadingDisposeBag = DisposeBag()
        let cancelSessionIDs = sessions.filter({ $0.status == .canceled }).map({ $0.sessionID })
        if let loadingSession = self.longTaskLoadingVC?.sessionInfo, cancelSessionIDs.contains(loadingSession.sessionID) {
            MailLogger.info("[mail_stranger] longtask req cancel by user in current longtask, keep loading and wait for push")
            if let session = sessions.first(where: { $0.status != .canceled }) {
                MailLogger.info("[mail_stranger] longtask response at once")
                self.showLongTaskLoadingIfNeeded(session) // 立刻响应，无需要等待500ms
            }
        } else if let session = sessions.first(where: { $0.status != .canceled }) { /// 用户手动操作取消，标记cancel, 则直接dismiss
            self.showLongTaskLoadingIfNeeded(session)
        } else {
            self.$uiElementChange.accept(.handleLongTaskLoading(nil, show: false))
        }
    }
    
    private func showLongTaskLoadingIfNeeded(_ session: MailBatchChangeInfo) {
        let affectedThreadCount = session.totalCount
        /// 开关陌人生模式
        if let req = session.request as? Email_Client_V1_MailUpdateAccountRequest {
            // 只有关闭陌生人操作场景可重试
            if !req.account.mailSetting.enableStranger {
                $uiElementChange.accept(.handleLongTaskLoading(session, show: session.status != .success)) // 需要测试直接失败push的case
                if session.status == .success {
                    $uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_StrangerInbox_EmailsSentToInbox_Toast,
                                                               isSuccess: true, selecteAll: false, sessionID: session.sessionID))
                }
            } else if session.status != .success {
                // 开启失败的情况需要弹Toast, 且无法重试
                $uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_StrangerInbox_UnableTurnStrangerInboxOnTryAgain_Toast,
                                                           isSuccess: false, selecteAll: false, sessionID: session.sessionID))
            } else {
                MailLogger.info("[mail_stranger] not need to show longtask loading")
            }
        /// 允许拒绝陌生人信件
        } else if let manageReq = session.request as? Email_Client_V1_MailManageStrangerRequest {
//                        /// 出长任务loading
//                        self?.$uiElementChange.accept(.handleLongTaskLoading(session, show: session.status == .processing))
            /// 成功提示
            if session.status == .success {
                if manageReq.isSelectAll {
                    if manageReq.manageType == .allow { // TODOSTRANGER
                        $uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_StrangerEmail_AllEmailsAllowed_Toast, isSuccess: true,
                                                                   selecteAll: true, sessionID: session.sessionID))
                    } else {
                        $uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_StrangerEmail_AllEmailsRejected_Toast, isSuccess: true,
                                                                   selecteAll: true, sessionID: session.sessionID))
                    }
                } else {
                    if manageReq.manageType == .allow {
                        $uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_StrangerMail_SenderAllowed_Toast,
                                                                   isSuccess: true, selecteAll: false, sessionID: session.sessionID))
                    } else {
                        $uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_StrangerMail_SenderRejected_Toast,
                                                                   isSuccess: true, selecteAll: false, sessionID: session.sessionID))
                    }
                }
                $uiElementChange.accept(.handleLongTaskLoading(session, show: false))
            } else {
                /// 需要后端error code支持不同文案提示
                $uiElementChange.accept(.handleLongTaskLoading(session, show: session.status != .success))
            }
        }
    }

    func didClickStrangerReply(_ cell: MailStrangerThreadCell, cellModel: MailThreadListCellViewModel, status: Bool) {
        if let cellIndexRow = strangerViewModel.mailThreads.all.firstIndex(where: { $0.threadID == cellModel.threadID }) {
            var datasource = strangerViewModel.mailThreads.all
            datasource.remove(at: cellIndexRow)
            strangerViewModel.setThreadsListOfLabel(Mail_LabelId_Stranger, mailList: datasource)
            strangerViewModel.$dataState.accept(.refreshed(data: datasource, resetLoadMore: false))
            if datasource.isEmpty {
                /// 乐观更新UI
                $uiElementChange.accept(.dismissStrangerCardList)
            }
        } else {
            MailLogger.error("[mail_stranger] cardlist optimistic reply threadID: \(cellModel.threadID) doesn't contains in strangerVM datasource")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.short) { [weak self] in
            self?.manageStrangerThread(threadIDs: [cellModel.threadID], status: status,
                                       isSelectAll: false, maxTimestamp: cellModel.lastmessageTime + 1,
                                       fromList: cellModel.fromList)
        }
    }

    func manageStrangerThread(threadIDs: [String]?, status: Bool, isSelectAll: Bool, maxTimestamp: Int64?, fromList: [String]?, showToastDirectly: Bool = false) {
        MailLogger.info("[mail_stranger] homeViewModel manageStrangerThread status: \(status) threadIds: \(threadIDs ?? []) isSelectAll: \(isSelectAll)")
        // TEST CODE
//        var req = Email_Client_V1_MailManageStrangerRequest()
//        req.manageType = status ? .allow : .reject
//        if let threadIds = threadIDs {
//            req.threadIds = threadIds
//        }
//        req.isSelectAll = isSelectAll
//        Store.settingData.updateBatchChangeSession(batchChangeInfo: MailBatchChangeInfo(sessionID: "123", request: req, status: .processing, totalCount: 0, progress: 0))
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
//            let batchResultChange = MailBatchResultChange(sessionID: "123", scene: .stranger, status: .processing, totalCount: 0, progress: 0.3)
//            PushDispatcher.shared.acceptMailBatchChangePush(push: .batchResultChange(batchResultChange))
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
//                let batchResultChange = MailBatchResultChange(sessionID: "123", scene: .stranger, status: .processing, totalCount: 0, progress: 0.8)
//                PushDispatcher.shared.acceptMailBatchChangePush(push: .batchResultChange(batchResultChange))
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
//                    let batchResultChange = MailBatchResultChange(sessionID: "123", scene: .stranger, status: .success, totalCount: 0, progress: 0.8)
//                    PushDispatcher.shared.acceptMailBatchChangePush(push: .batchResultChange(batchResultChange))
//                })
//            })
//        })
//        return

        var request = Email_Client_V1_MailManageStrangerRequest()
        request.manageType = status ? .allow : .reject
        if let threadIds = threadIDs { request.threadIds = threadIds }
        request.isSelectAll = isSelectAll
        if let timeStamp = maxTimestamp {
            request.maxTimestamp = timeStamp
        }
        if let list = fromList {
            request.fromList = list
        }

        var hasShowMockLoading: Bool = false
        // 500ms内仍未收到响应则直接弹出Loading
        if isSelectAll {
            Observable.just(())
            .delay(.milliseconds(timeIntvl.normalMili), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                MailLogger.info("[mail_stranger] show Loading for user haven't response within 500ms")
                Store.settingData.updateBatchChangeSession(batchChangeInfo: MailBatchChangeInfo(sessionID: "manageStrangerThreadRespNotReach", request: request, status: .processing, totalCount: 0, progress: 0))
                hasShowMockLoading = true
            }).disposed(by: loadingDisposeBag)
        }
        
        MailDataServiceFactory
            .commonDataService?.manageStrangerThread(type: status ? .allow : .reject, threadIds: threadIDs, isSelectAll: isSelectAll, maxTimestamp: maxTimestamp, fromList: fromList)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                if isSelectAll {
                    self.loadingDisposeBag = DisposeBag()
                    MailLogger.info("[mail_stranger] homeViewModel manageStrangerThread sessionID: \(response.sessionID) hasShowMockLoading: \(hasShowMockLoading)")
                    Store.settingData.updateBatchChangeSession(batchChangeInfo: MailBatchChangeInfo(sessionID: response.sessionID, request: request, status: .processing, totalCount: 0, progress: 0), replaceSessionID: hasShowMockLoading ? "manageStrangerThreadRespNotReach" : "")
                } else {
                    let text = {
                        if status {
                            return BundleI18n.MailSDK.Mail_StrangerMail_SenderAllowed_Toast
                        } else {
                            return BundleI18n.MailSDK.Mail_StrangerMail_SenderRejected_Toast
                        }
                    }()
                    if showToastDirectly {
                        if let topViewController = UIApplication.shared.windows.first?.rootViewController {
                            var currentViewController = topViewController
                            while let presentedViewController = currentViewController.presentedViewController {
                                currentViewController = presentedViewController
                            }
                            UDToast.showSuccess(with: text, on: currentViewController.view)
                        }
                    } else {
                        self.$uiElementChange.accept(.showFeedBackToast(text, isSuccess: true, selecteAll: false, sessionID: ""))
                    }
                }
            }, onError: { [weak self] (error) in
                MailLogger.error("[mail_stranger] send manageStrangerThread request failed error: \(error) hasShowMockLoading: \(hasShowMockLoading)")
                if isSelectAll {
                    self?.loadingDisposeBag = DisposeBag()
                    if hasShowMockLoading {
                        Store.settingData.updateBatchChangeSession(batchChangeInfo: MailBatchChangeInfo(sessionID: "manageStrangerThreadRespNotReach",
                                                                                                        request: request, status: .failed, totalCount: 0, progress: 0))
                    } else {
                        self?.$uiElementChange.accept(.showFeedBackToast(BundleI18n.MailSDK.Mail_StrangerInbox_UnableSendToInboxRetry_Text, isSuccess: false, selecteAll: false, sessionID: ""))
                    }
                }
            }).disposed(by: disposeBag)
        
        var actionType = ""
        if isSelectAll {
            actionType = status ? "allow_all_sender" : "reject_all_sender"
        } else {
            actionType = status ? "allow_sender" : "reject_sender"
        }
        let value = NewCoreEvent.labelTransfor(labelId: currentLabelId,
                                               allLabels: labels)
        NewCoreEvent.threadListThreadAction(isMultiSelected: true,
                                            position: "thread_hover",
                                            actionType: actionType,
                                            filterType: currentFilterType,
                                            labelItem: value,
                                            displayType: Store.settingData.threadDisplayType())
    }
    
    func needShowStrangerModeEmpty() -> Bool { // 陌生人卡片有数据时，正常邮件空状态UI需要异化
        guard userContext.featureManager.open(.stranger, openInMailClient: false) && StrangerCardConst.strangerInLabels.contains(currentLabelId) else { return false }
        return !strangerViewModel.mailThreads.all.isEmpty
    }

    func blockStrangerEmptyOnboardTip() {
        let kvStore = MailKVStore(space: .user(id: userContext.user.userID), mSpace: .global, mailBiz: .threadList)
        let didShowEmptyTips = kvStore.bool(forKey: "mail_stranger_thread_empty_tips")
        MailLogger.info("[mail_stranger] didShowEmptyTips: \(didShowEmptyTips)")
        if !didShowEmptyTips {
            kvStore.set(true, forKey: "mail_stranger_thread_empty_tips")
        }
    }

    func updateVisitStrangerTimestampIfNeeded(_ labelId: String) {
        if (currentLabelId == Mail_LabelId_Stranger && labelId != Mail_LabelId_Stranger) ||
            (currentLabelId != Mail_LabelId_Stranger && labelId == Mail_LabelId_Stranger) {
            let nowTimestamp = Int64(Date().milliTimestamp) ?? 0
            Store.settingData.updateCurrentSettings(.lastVisitStrangerLabelTimestamp(nowTimestamp))
        }
    }
}
