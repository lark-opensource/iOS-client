// longweiwei

import Foundation
import EENavigator
import RxSwift
import RustPB
import LarkUIKit
import LarkAlertController

extension MailHomeController: ThreadActionsBarDelegate, MailEditLabelsDelegate {

    func didHandleActionType(type: ActionType) {
        if type == .read && viewModel.currentFilterType == .unread {
            exitMultiSelect()
        }
    }

    func onChangeLabelClick(bar: ThreadActionsBar) {
        showupEditLabelsPage(threadIDs: bar.threadIDs, threadLabels: threadActionBar.threadLabels, scene: .homeMulti)
    }

    func moreActionDidClick(sender: UIControl) {
        let actionStyles = MailMessageListActionFactory().threadActionBarMoreActions(
            threadActions: threadActionBar.threadActions,
            labelId: threadActionBar.labelIds.first ??
                Mail_LabelId_Inbox,
            forceMore: self.needForceMore())
        let lowerItems = actionStyles.map { (config) -> MailActionItem in
            let temp = MailActionItem(title: config.title,
                                      icon: config.icon,
                                      udGroupNumber: config.type.threadGroupNumber) { [weak self] _ in
                self?.didClickMoreAction(actionType: config.type)
            }
            return temp
        }
        let popoverSourceView = rootSizeClassIsSystemRegular ? threadActionBar.moreBtn : nil
        var sections = [MoreActionSection]()
        var sectionItems = lowerItems
            .sorted(by: { item1, item2 in
                return item1.udGroupNumber < item2.udGroupNumber
            })
            .reduce(into: [[MailActionItemProtocol]]()) { tempo, item in
                if let lastArray = tempo.last {
                    if lastArray.first?.udGroupNumber == item.udGroupNumber {
                        let head: [[MailActionItemProtocol]] = Array(tempo.dropLast())
                        let tail: [[MailActionItemProtocol]] = [lastArray + [item]]
                        tempo = head + tail
                    } else {
                        tempo.append([item])
                    }
                } else {
                    tempo = [[item]]
                }
            }
        for sectionItem in sectionItems {
            sections.append(MoreActionSection(layout: .vertical, items: sectionItem))
        }
        let moreVC = MoreActionViewController.makeMoreActionVC(
            headerConfig: nil,
            sectionData: sections,
            popoverSourceView: popoverSourceView,
            arrowUp: nil)
        navigator?.present(moreVC, from: self, animated: false, completion: nil)
    }

    func showupEditLabelsPage(threadIDs: [String], threadLabels: [MailFilterLabelCellModel], scene: MailEditLabelsScene) {
        if threadIDs.isEmpty {
            return
        }
        let labelsVC = MailEditLabelsViewController(threadLabels: threadLabels,
                                                    semiSelectedLabels: threadActionBar.semiCheckedLabels,
                                                    threadId: threadIDs.first ?? Mail_LabelId_Inbox,
                                                    fromLabel: viewModel.currentLabelId,
                                                    accountContext: userContext.getCurrentAccountContext())
        labelsVC.multiSelectFlag = scene == .homeMulti || scene == .searchMulti
        labelsVC.multiSelectDelegate = self
        if scene == .homeSwipeAction {
            labelsVC.editLabelDelegate = self
        }
        labelsVC.scene = scene
        let nav = LkNavigationController(rootViewController: labelsVC)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        navigator?.present(nav, from: self, animated: true)
    }

    func showEditLabelToast(_ toast: String, uuid: String) {
        ActionToast.removeToast(on: self.view)
        MailRoundedHUD.remove(on: self.view)
        MailRoundedHUD.showSuccess(with: toast, on: self.view)
    }

    func didClickMoreAction(actionType: ActionType) {
        switch actionType {
        case .changeLabels: showupEditLabelsPage(threadIDs: threadActionBar.threadIDs, threadLabels: threadActionBar.threadLabels, scene: .homeMulti)
        case .deleteDraft: deleteDraftConfirm(handler: {})
        default:
            threadActionBar.didClickMoreAction(actionType: actionType)
        }
    }

    func didMultiMutLabelForThread() {
        exitMultiSelect()
    }

    func didMoveMultiLabel(newFolderToast: String, undoInfo: (String, String)) {
        exitMultiSelect()
        showMoveToNewFolderToast(newFolderToast, undoInfo: undoInfo)
    }

    func didClickExitButton() {
        exitMultiSelect()
        threadActionBar.removeFromSuperview()
    }

    func deleteDraftConfirm(handler: @escaping () -> Void) {
        showDeleteDraftConfirm { [weak self] in
            self?.threadActionBar.multiDeleteDraft()
            handler()
        }
    }

    func showDeleteDraftConfirm(handler: @escaping () -> Void) {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_DiscardSelectedDraftsICU_Desc(num: threadActionBar.threadIDs.count), alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_DiscardDraftBtn, dismissCompletion: {
            handler()
        })
        navigator?.present(alert, from: self)
    }

    func cancelScheduleSendConfirm() {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_SendLater_CancelScheduledAlert, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_SendLater_AlertBack)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_SendLater_AlertCancelAll, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.threadActionBar.cancelScheduledSend()
        })
        navigator?.present(alert, from: self)
    }

    func deletePermanently(labelID: String, threadIDs: [String], handler: @escaping () -> Void) {
        let alert = LarkAlertController()
        alert.setContent(text: BundleI18n.MailSDK.Mail_ThreadAction_DeleteForeverConfirm, alignment: .center)
        alert.addSecondaryButton(text: BundleI18n.MailSDK.Mail_Alert_Cancel)
        alert.addDestructiveButton(text: BundleI18n.MailSDK.Mail_Alert_Delete, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            MailRoundedHUD.showLoading(on: self.view, disableUserInteraction: false)
            if labelID == Mail_LabelId_Outbox {
                Store.updateOutboxMail(threadId: threadIDs.first, messageId: threadIDs.first, action: .delete)
                    .subscribe(onNext: { [weak self] (_) in
                        guard let self = self else { return }
                        MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DeleteThreadsSuccess, on: self.view)
                        self.didMultiMutLabelForThread()
                        handler()
                    }, onError: { (_) in
                        MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_Toast_OperationFailed, on: self.view,
                                                           event: ToastErrorEvent(event: .thread_delete_forever_fail,
                                                                                  scene: .threadlist))
                    }).disposed(by: self.disposeBag)
            } else {
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
            }
        })
        navigator?.present(alert, from: self)
    }
    func makeSendVCEmlAsAttachment(infos: [EmlAsAttachmentInfo]) {
        guard infos.count > 0 else { return }
        var statInfo = MailSendStatInfo(from: .emlAsAttachment,
                                                newCoreEventLabelItem: "none")
        statInfo.emlAsAttachmentInfos = infos
        let vc = MailSendController.makeSendNavController(accountContext: userContext.getCurrentAccountContext(),
                                                          action: .new,
                                                          labelId: self.viewModel.currentLabelId,
                                                          statInfo: statInfo,
                                                          trackerSourceType: .new)
        userContext.navigator.present(vc, from: self)
    }

    func presentVC(vc: UIViewController) {
        navigator?.present(vc, from: self)
    }
    
    func presentSpamAlert(type: SpamAlertType, content: SpamAlertContent, action: @escaping (Bool) -> Void) {
        LarkAlertController.showSpamAlert(type: type, content: content, from: self, navigator: userContext.navigator, userStore: userContext.userKVStore, action: action)
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
        let labelsMenuController = self.getTagMenu()
        let value = NewCoreEvent.labelTransfor(labelId: labelsMenuController.viewModel.selectedID,
                                               allLabels: labelsMenuController.viewModel.labels)
        NewCoreEvent.threadListThreadAction(isMultiSelected: true,
                                            position: "thread_bar",
                                            actionType: actionType,
                                            filterType: viewModel.currentFilterType,
                                            labelItem: value,
                                            displayType: Store.settingData.threadDisplayType())
    }
    
    func handleBlockSender(labelID: String, threadIDs: [String]) {
        let models: [MailThreadListCellViewModel] = self.viewModel.listViewModel.mailThreads.all.filter { model in
            threadIDs.contains(model.threadID)
        }
        let blockItems: [BlockItem] = models.compactMap { model in
            if let data = model.originData, data.thread.displayAddress.count > 0 {
                return BlockItem(threadId: model.threadID,
                                 messageId: nil,
                                 addressList: data.thread.displayAddress)
            } else {
                return nil
            }
        }
        self.senderBlocker = BlockSenderManager(accountContext: self.userContext.getCurrentAccountContext(),
                                                labelID: labelID,
                                                scene: .homeThread,
                                                originBlockItems: blockItems)
        self.senderBlocker?.delegate = self
        senderBlocker?.showPopupMenu(fromVC: self)
    }
}

extension MailHomeController: MultiSelectTagDelegate {
    func changeLables(addLabels: [String], deleteLabels: [String], toast: String, scene: MailEditLabelsScene) {
        threadActionBar.changeLabels(addLabelIds: addLabels, removeLabelIds: deleteLabels, threadCounts: selectedRows.count, toast: toast, supportUndo: scene == .homeSwipeAction)
    }
}

extension MailHomeController: BlockSenderDelegate {
    func addBlockSuccess(isAllow: Bool, num: Int) {
        exitMultiSelect()
        if !isAllow {
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_BlockSender_SenderBlocked_Toast(num), on: self.view)
        } else {
            MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_TrustSender_SenderTrusted_Toast(num), on: self.view)
        }
    }
}
