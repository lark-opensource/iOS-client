//
//  MailHomeController+Stranger.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/3/10.
//

import Foundation
import RustPB
import UniverseDesignToast
import LarkSplitViewController
import EENavigator
import LarkUIKit

extension MailHomeController: MailLongTaskLoadingDelegate {
    func showStrangerCardListViewIfNeeded() {
        guard enableStranger() else {
            return
        }
        MailLogger.info("[mail_stranger] cardList showStrangerCardListViewIfNeeded, start to fetch cards")
        viewModel.$bindStrangerVM.accept(viewModel.strangerViewModel)
        viewModel.strangerViewModel.getMailListFromLocal(filterType: viewModel.currentFilterType)
        headerViewManager.showStrangerCardListView(viewModel.strangerViewModel)
    }

    func resetStrangerCardListView() {
        guard userContext.featureManager.open(.stranger, openInMailClient: false) else {
            return
        }
        MailLogger.info("[mail_stranger] cardList resetStrangerCardListView")
        viewModel.strangerViewModel.cancelGetThreadList()
        viewModel.strangerViewModel.cleanMailThreadCache()
        headerViewManager.tableHeaderView.strangerCardListView?.clearSelectedStatus()
        headerViewManager.dismissStrangerCardListView()
        if markSelectedThreadId == nil && rootSizeClassIsRegular {
            navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
        }
        viewModel.strangerCardList?.batchConfirmAlert?.dismiss(animated: true)
        viewModel.strangerCardList?.batchConfirmAlert = nil
        viewModel.batchConfirmAlert?.dismiss(animated: true)
        viewModel.batchConfirmAlert = nil
    }

    func enableStranger() -> Bool {
        if let account = Store.settingData.getCachedCurrentAccount(), !account.isShared,
           account.mailSetting.enableStranger,
           StrangerCardConst.strangerInLabels.contains(viewModel.currentLabelId),
           userContext.featureManager.open(.stranger, openInMailClient: false) {
            return true
        } else {
            return false
        }
    }

    func msgListManageStrangerThread(threadIDs: [String]?, status: Bool, isSelectAll: Bool, maxTimestamp: Int64?, fromList: [String]?) {
        MailLogger.info("[mail_stranger] msgListManageStrangerThread threadIDs: \(threadIDs ?? []) \(status)")
        /// iPad需要退出读信
        enterThread(with: nil)
        viewModel.manageStrangerThread(threadIDs: threadIDs, status: status, isSelectAll: isSelectAll,
                                       maxTimestamp: maxTimestamp, fromList: fromList, showToastDirectly: true)
    }

    func retryManageStrangerThread(type: Email_Client_V1_MailManageStrangerRequest.ManageType, threadIds: [String]?, isSelectAll: Bool, maxTimestamp: Int64) {
        viewModel.manageStrangerThread(threadIDs: threadIds, status: type == .allow, isSelectAll: isSelectAll, maxTimestamp: maxTimestamp, fromList: nil) // 只有全选能重试，全选不传fromList
    }

    func showFeedBackToast(toast: String, isSuccess: Bool, selecteAll: Bool, sessionID: String) {
        MailRoundedHUD.remove(on: self.view)
        if self.view.window != nil {
            _showToast(toast: toast, isSuccess: isSuccess, view: self.view)
        } else if let cardList = viewModel.strangerCardList {
            if isSuccess {
                if selecteAll {
                    cardList.accountContext.navigator.pop(from: cardList) { [weak self] in
                        self?._showToast(toast: toast, isSuccess: isSuccess, view: self?.view ?? cardList.view)
                    }
                } else {
                    if cardList.view.window == nil {
                        viewModel.cardListToastList.append((toast, isSuccess))
                    } else {
                        _showToast(toast: toast, isSuccess: isSuccess, view: cardList.view)
                    }
                }
            } else {
                _showToast(toast: toast, isSuccess: isSuccess, view: cardList.view)
            }
        } else {
            viewModel.toastList.append((toast, isSuccess))
        }
        if isInMailTab() && !sessionID.isEmpty {
            Store.settingData.clearBatchChangeSessionIDs(sessionID, forceClear: true) // 在tab上显示toast并消费
        }
    }

    private func _showToast(toast: String, isSuccess: Bool, view: UIView) {
        if let loading = viewModel.longTaskLoadingVC {
            loading.dismiss(animated: true)
            viewModel.longTaskLoadingVC = nil
        }
        if isSuccess {
            UDToast.showSuccess(with: toast, on: view)
        } else {
            UDToast.showFailure(with: toast, on: view)
        }
    }

    func showStrangerReplyToastIfNeeded() {
        MailLogger.info("[mail_stranger] longtask showStrangerReplyToastIfNeeded toastList: \(viewModel.toastList.count) shouldShowLongTask: \(viewModel.shouldShowLongTask) \(isInMailTab())")
        guard !viewModel.toastList.isEmpty else {
            if let loading = viewModel.longTaskLoadingVC, viewModel.shouldShowLongTask {
                navigator?.present(loading, from: self, animated: false)
                viewModel.shouldShowLongTask = false
            }
            return
        }
        if let lastToast = viewModel.toastList.last {
            if lastToast.1 {
                UDToast.showSuccess(with: lastToast.0, on: self.view)
            } else {
                UDToast.showFailure(with: lastToast.0, on: self.view)
            }
            viewModel.toastList.removeAll()
        }
    }
    
    func handleLongTaskLoading(session: MailBatchChangeInfo?, show: Bool) {
        MailLogger.info("[mail_stranger] longtask handleLongTaskLoading session: \(session?.sessionID ?? "") \(String(describing: session?.status)) show: \(show)")
        guard let sessionInfo = session, show else {
            viewModel.longTaskLoadingVC?.dismiss(animated: false)
            viewModel.longTaskLoadingVC = nil
            return
        }
        if viewModel.longTaskLoadingVC == nil {
            viewModel.longTaskLoadingVC = MailLongTaskLoadingViewController(sessionInfo: sessionInfo)
            viewModel.longTaskLoadingVC?.modalPresentationStyle = .overFullScreen
            viewModel.longTaskLoadingVC?.delegate = self
            viewModel.longTaskLoadingVC?.closeHandler = { [weak self] in
                MailLogger.info("[mail_stranger] longtask oauthLoadingVC closeHandler")
                self?.dismissLongTaskLoading()
                self?.viewModel.longTaskLoadingVC?.dismiss(animated: false) // view.removeFromSuperview()
                self?.viewModel.longTaskLoadingVC = nil
                self?.viewModel.shouldShowLongTask = false
            }
            if let loading = self.viewModel.longTaskLoadingVC, isInMailTab(),
               UIApplication.shared.keyWindow?.rootViewController?.presentedViewController == nil,
               (self.navigationController?.viewControllers.count ?? 0) < 2 {
                MailLogger.info("[mail_stranger] longtask longTaskLoadingVC showup✨")
                navigator?.present(loading, from: self, animated: false)
            } else {
                MailLogger.info("[mail_stranger] longtask longTaskLoadingVC can't show because not in mail tab or presenting other vc")
                viewModel.shouldShowLongTask = true
            }
            viewModel.toastList.removeAll()
        } else {
            if let currentSessionID = viewModel.longTaskLoadingVC?.sessionInfo.sessionID, viewModel.longTaskLoadingVC?.sessionInfo.status != .canceled,
               (currentSessionID.isEmpty ||
                currentSessionID == "manageStrangerThreadRespNotReach" ||
                (!currentSessionID.isEmpty && currentSessionID == sessionInfo.sessionID)) {
                viewModel.longTaskLoadingVC?.sessionInfo = sessionInfo
                MailLogger.info("[mail_stranger] longtask longTaskLoadingVC exist: \(viewModel.longTaskLoadingVC != nil) sessionInfo: \(sessionInfo.sessionID) isViewLoaded: \(viewModel.longTaskLoadingVC?.isViewLoaded ?? false) window: \(viewModel.longTaskLoadingVC?.view.window != nil) isInMailTab(): \(isInMailTab())")
                viewModel.shouldShowLongTask = true
                viewModel.toastList.removeAll()
            } else {
                MailLogger.error("[mail_stranger] longtask receive disorderly session push")
            }
        }
    }
    
    private func dismissLongTaskLoading() {
        guard !(viewModel.longTaskLoadingVC?.cancelInFailCase ?? false) else {
            MailLogger.info("[mail_stranger] longtask cancelInFailCase, not use to cancalLongTask")
            if let shouldCancelSessionID = viewModel.longTaskLoadingVC?.sessionInfo.sessionID {
                Store.settingData.clearBatchChangeSessionIDs(shouldCancelSessionID)
            }
            return
        }
        if let sessionID = viewModel.longTaskLoadingVC?.sessionInfo.sessionID {
            Store.settingData.clearBatchChangeSessionIDs(sessionID) // 乐观更新并本地push，UI即时响应，同时发请求取消
            MailDataServiceFactory
                .commonDataService?.cancelLongTask(sessionID: sessionID)
                .subscribe(onNext: { (_) in
                    MailLogger.info("[mail_stranger] longtask cancelLongTask success")
                }, onError: { (error) in
                    MailLogger.error("[mail_stranger] longtask cancelLongTask failed error: \(error)")
                }).disposed(by: disposeBag)
        }
    }
}

extension MailHomeController: MailStrangerCardListControllerDelegate {
    func strangerCardSelectAllHandler(status: Bool) {
        viewModel.manageStrangerThread(threadIDs: nil, status: status, isSelectAll: true,
                                       maxTimestamp: (viewModel.strangerViewModel.mailThreads.all.first?.lastmessageTime ?? 0) + 1,
                                       fromList: nil)
    }

    func strangerCardListItemReplyHandler(threadIDs: [String]?, status: Bool, maxTimestamp: Int64?, fromList: [String]?) {
        /// need pop to mail home
        viewModel.manageStrangerThread(threadIDs: threadIDs, status: status, isSelectAll: false, maxTimestamp: maxTimestamp, fromList: fromList)
    }
}
