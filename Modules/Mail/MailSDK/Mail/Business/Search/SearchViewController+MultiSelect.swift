// longweiwei

import Foundation
import EENavigator
import RxSwift
import LarkUIKit
import LarkSplitViewController
import LarkAlertController
import RustPB

extension MailSearchViewController: ThreadActionsBarDelegate {

    func didHandleActionType(type: ActionType) {}

    func onChangeLabelClick(bar: ThreadActionsBar) {
        showupEditLabelsPage(threadIDs: bar.threadIDs, threadLabels: threadActionBar.threadLabels, scene: .searchMulti)
    }

    func moreActionDidClick(sender: UIControl) {
        // TODO: 多个label_id
        let actionStyles = MailMessageListActionFactory().threadActionBarMoreActions(threadActions: threadActionBar.threadActions, labelId: "currentLabelId", forceMore: self.needForceMore())
        let lowerItems = actionStyles.map { (config) -> MailActionItem in
            let temp = MailActionItem(title: config.title, icon: config.icon) { [weak self] _ in
                self?.didClickMoreAction(actionType: config.type)
            }
            return temp
        }
        let popoverSourceView = rootSizeClassIsSystemRegular ? sender : nil
        let moreVC = MoreActionViewController.makeMoreActionVC(headerConfig: nil,
                                                               sectionData: [MoreActionSection(layout: .vertical, items: lowerItems)],
                                                               popoverSourceView: popoverSourceView,
                                                               arrowUp: nil)
        navigator?.present(moreVC, from: self, animated: false, completion: nil)
    }

    func showupEditLabelsPage(threadIDs: [String], threadLabels: [MailFilterLabelCellModel], scene: MailEditLabelsScene) {
        let labelsVC = MailEditLabelsViewController(threadLabels: threadLabels,
                                                    semiSelectedLabels: threadActionBar.semiCheckedLabels,
                                                    threadId: threadActionBar.threadIDs.first ?? Mail_LabelId_Inbox,
                                                    fromLabel: Mail_LabelId_SEARCH,
                                                    accountContext: accountContext)
        labelsVC.multiSelectFlag = true
        labelsVC.multiSelectDelegate = self
        labelsVC.scene = scene
        let nav = LkNavigationController(rootViewController: labelsVC)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        navigator?.present(nav, from: self, animated: true)
    }

    func didMultiMutLabelForThread() {
        exitMultiSelect()
    }

    func didMoveMultiLabel(newFolderToast: String, undoInfo: (String, String)) {
        if Display.pad {
            navigator?.showDetail(SplitViewController.makeDefaultDetailVC(), wrap: LkNavigationController.self, from: self)
        }
        exitMultiSelect()
        DispatchQueue.main.asyncAfter(deadline: .now() + timeIntvl.normal) { // 因为连续dismiss，callback回调了但window还没回到主页，所以出toast时机需要延迟
            MailRoundedHUD.showSuccess(with: newFolderToast, on: self.view)
        }
    }

    func didClickMoreAction(actionType: ActionType) {
        switch actionType {
        case .changeLabels: showupEditLabelsPage(threadIDs: threadActionBar.threadIDs, threadLabels: threadActionBar.threadLabels, scene: .searchMulti)
        default:
            let fromLabel: String? = {
                if FeatureManager.open(.searchTrashSpam, openInMailClient: true) {
                    if actionType == .notSpam {
                        return Mail_LabelId_Spam
                    } else {
                        return searchLabel
                    }
                } else {
                    return nil
                }
            }()
            threadActionBar.didClickMoreAction(actionType: actionType, fromLabel: fromLabel)
        }
    }

    func didClickExitButton() {
        exitMultiSelect()
        threadActionBar.removeFromSuperview()
    }
    
    func presentSpamAlert(type: SpamAlertType, content: SpamAlertContent, action: @escaping (Bool) -> Void) {
        LarkAlertController.showSpamAlert(type: type, content: content, from: self, navigator: accountContext.navigator, userStore: accountContext.userKVStore, action: action)
    }

    func deleteDraftConfirm(handler: @escaping () -> Void) {

    }

    func cancelScheduleSendConfirm() {

    }

    func deletePermanently(labelID: String, threadIDs: [String], handler: @escaping () -> Void) {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThreadAction_DeleteForeverConfirm, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_Delete, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            MailRoundedHUD.showLoading(on: self.view, disableUserInteraction: false)
            self.threadActionDataManager
                .deletePermanently(threadIDs: threadIDs, fromLabel: labelID, sourceType: .threadAction).subscribe(onError: { [weak self] (_) in
                    guard let `self` = self else { return }
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view,
                                               event: ToastErrorEvent(event: .thread_delete_forever_fail,
                                                                      scene: .threadlist))
            }, onCompleted: { [weak self] in
                guard let `self` = self else { return }
                MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DeleteThreadsSuccess, on: self.view)
                self.didMultiMutLabelForThread()
                handler()
            }).disposed(by: self.disposeBag)
        })
        accountContext.navigator.present(alert, from: self)
    }
    func makeSendVCEmlAsAttachment(infos: [EmlAsAttachmentInfo]) {
        guard infos.count > 0 else { return }
        var statInfo = MailSendStatInfo(from: .emlAsAttachment,
                                                newCoreEventLabelItem: "none")
        statInfo.emlAsAttachmentInfos = infos
        let vc = MailSendController.makeSendNavController(accountContext: accountContext,
                                                          action: .new,
                                                          labelId: Mail_LabelId_SEARCH,
                                                          statInfo: statInfo,
                                                          trackerSourceType: .new)
        accountContext.navigator.present(vc, from: self)
    }

    func presentVC(vc: UIViewController) {
        navigator?.present(vc, from: self)
    }

    // 是否需要将所有的action都收在more里面
    func needForceMore() -> Bool {
        let limitWidth: CGFloat = 375 //是否收起action的width临界值
        if self.view.bounds.size.width < limitWidth {
            return true
        } else {
            return false
        }
    }

    func multiSelectNewCoreEvent(actionType: String) {
        NewCoreEvent.threadListThreadAction(isMultiSelected: true,
                                            position: "thread_bar",
                                            actionType: actionType,
                                            filterType: .allMail,
                                            labelItem: "EMAIL_SEARCH", // 只有独立搜有多选
                                            displayType: Store.settingData.threadDisplayType(),
                                            isTrashOrSpamList: searchLabel == Mail_LabelId_SEARCH_TRASH_AND_SPAM ? "TRUE" : "FALSE")
    }
    
    func handleBlockSender(labelID: String, threadIDs: [String]) {
        let blockItems: [BlockItem] = self.searchViewModel.allItems().compactMap { model in
            if threadIDs.contains(model.viewModel.threadId) {
                if model.viewModel.addressList.count > 0 {
                    return BlockItem(threadId: model.viewModel.threadId,
                                     messageId: nil,
                                     addressList: model.viewModel.addressList)
                } else {
                    return nil
                }
            } else {
                return nil
            }
        }
        self.senderBlocker = BlockSenderManager(accountContext: self.accountContext,
                                                labelID: labelID,
                                                scene: .searchThread,
                                                originBlockItems: blockItems)
        self.senderBlocker?.delegate = self
        self.senderBlocker?.showPopupMenu(fromVC: self)
    }
}

extension MailSearchViewController: MultiSelectTagDelegate {
    func changeLables(addLabels: [String], deleteLabels: [String], toast: String, scene: MailEditLabelsScene) {
        threadActionBar.changeLabels(addLabelIds: addLabels, removeLabelIds: deleteLabels, threadCounts: selectedRows.count, toast: toast)
    }
}

extension MailSearchViewController: BlockSenderDelegate {
    func addBlockSuccess(isAllow: Bool, num: Int) {
        exitMultiSelect()
        if !isAllow {
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_BlockSender_SenderBlocked_Toast(num), on: self.view)
        } else {
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_TrustSender_SenderTrusted_Toast(num), on: self.view)
        }
    }
}
