// longweiwei

import Foundation
import RxSwift
import LarkAlertController
import EENavigator
import Homeric
import LarkUIKit
import RustPB
import UniverseDesignIcon
import UIKit
import UniverseDesignToast
import Reachability

protocol ThreadActionsBarDelegate: AnyObject {
    func moreActionDidClick(sender: UIControl)
    func showupEditLabelsPage(threadIDs: [String], threadLabels: [MailFilterLabelCellModel], scene: MailEditLabelsScene)
    func didMultiMutLabelForThread()
    func didClickExitButton()
    func deleteDraftConfirm(handler: @escaping () -> Void)
    func cancelScheduleSendConfirm()
    func deletePermanently(labelID: String, threadIDs: [String], handler: @escaping () -> Void)
    /// 注意！！！ 这里不一定回调加全了，如果需要使用请检查逻辑按需补全。
    func didHandleActionType(type: ActionType)
    func didMoveMultiLabel(newFolderToast: String, undoInfo: (String, String)) // uuid labelName
    func onChangeLabelClick(bar: ThreadActionsBar)
    func presentVC(vc: UIViewController)
    func presentSpamAlert(type: SpamAlertType, content: SpamAlertContent, action: @escaping (Bool) -> Void)
    func needForceMore() -> Bool
    // 埋点用的
    func multiSelectNewCoreEvent(actionType: String)
    func makeSendVCEmlAsAttachment(infos: [EmlAsAttachmentInfo])
    func handleBlockSender(labelID: String, threadIDs: [String])
}

class ThreadActionsBar: UINavigationBar {

    var backBlock: (() -> Void)?
    weak var actionDelegate: ThreadActionsBarDelegate?
    private let multiMutLabelBag = DisposeBag()
    private let emlBag = DisposeBag()

    // Data TODO: view内不该持有数据，尚未做分离
    var searchResultItems: [MailSearchCallBack]?
    var homeResultItems: [MailThreadListCellViewModel]?

    var labelIds: [String] = [String]()
    var threadIDs: [String] = [String]()
    var fromLabelID: String = ""
    
    let accountContext: MailAccountContext

    /// 标记垃圾邮件 Alert 需要使用
    var spamAlertContent = SpamAlertContent()

    var threadLabels: [MailFilterLabelCellModel] = []
    var semiCheckedLabels: [MailFilterLabelCellModel] = [] // 半选中状态的label
    private(set) var threadActions: [MailIndexedThreadAction] = []

    // UI
    let backButton = UIButton(type: .custom)
    let selectedTitleLabel = UILabel()
    lazy var moreBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.moreOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.addTarget(self, action: #selector(moreActionDidClick(sender:)), for: .touchUpInside)
        button.tintColor = UIColor.ud.iconN1
        return button
    }()
    
    var barItemStackView = UIStackView()
    let emlAsAttachmentMaxCnt = 50

    init(frame: CGRect, accountContext: MailAccountContext) {
        self.accountContext = accountContext
        super.init(frame: frame)
        tintColor = UIColor.ud.bgBody
        titleTextAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17.0)]
        isTranslucent = false
        shadowImage = UIImage()
        setBackgroundImage(UIImage.ud.fromPureColor(UIColor.ud.bgBody), for: .default)
        backgroundColor = UIColor.ud.bgBody

        backButton.setImage(UDIcon.leftOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        backButton.addTarget(self, action: #selector(backItemTapHandler), for: .touchUpInside)
        backButton.tintColor = UIColor.ud.iconN1
        addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.left.equalTo(6)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
        }
        
        barItemStackView.axis = .horizontal
        barItemStackView.alignment = .center
        barItemStackView.spacing = 24
        barItemStackView.setContentHuggingPriority(.required, for: .horizontal)
        barItemStackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        addSubview(barItemStackView)
        barItemStackView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.top.height.equalToSuperview()
        }

        selectedTitleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
        selectedTitleLabel.textColor = UIColor.ud.textTitle
        selectedTitleLabel.isUserInteractionEnabled = false
        selectedTitleLabel.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelMultiSelectTitle
        addSubview(selectedTitleLabel)
        selectedTitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(backButton.snp.right).offset(-2)
            make.top.height.equalToSuperview()
            make.right.lessThanOrEqualTo(barItemStackView.snp.left).offset(-12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setThreadActions(_ actions: [MailIndexedThreadAction], scheduleSendCount: Int = 0, needUpdateUI: Bool = false) {
        var actionsMutable = actions
        // 当且仅当选中的邮件全为read状态时，可进行unread操作。只要选中邮件中含有unread邮件，对应的button为read操作
        var unreadIndexes = [Int]()
        var readIndexes = [Int]()
        for (index, indexedAction) in actionsMutable.enumerated() {
            if indexedAction.action == .unRead {
                unreadIndexes.append(index)
            } else if indexedAction.action == .read {
                readIndexes.append(index)
            }
        }

        // 只有已读.
        // 只有未读.
        // 同时有已读未读.
        if !unreadIndexes.isEmpty && !readIndexes.isEmpty {
            unreadIndexes.reverse()
            for unreadIndex in unreadIndexes {
                actionsMutable.remove(at: unreadIndex)
            }
        }
        let set = Set(actionsMutable.map { $0 })
        actionsMutable = set.sorted { (a, b) -> Bool in
            a.index < b.index
        }
        // PM 要求 archive 和 move to inbox 不能同时出现, 当同时出现时, 只显示 archive.
        var containsArchive = false
        var containsMoveToInbox = false
        var moveToInboxIndex = -1
        for (index, threadAction) in actionsMutable.enumerated() {
            if threadAction.action == .archive {
                containsArchive = true
            }
            if threadAction.action == .moveToInbox {
                containsMoveToInbox = true
                moveToInboxIndex = index
            }
        }
        if containsArchive && containsMoveToInbox {
            actionsMutable.remove(at: moveToInboxIndex)
        }

        // 定时发送中，当选中的邮件只有一封时，取消定时发送按钮的文案不同
        if scheduleSendCount <= 1 {
            actionsMutable.removeAll(where: { $0.action == .cancelAllScheduleSend })
        } else {
            actionsMutable.removeAll(where: { $0.action == .cancelScheduleSend })
        }

        self.threadActions = actionsMutable

        if needUpdateUI {
            triggerActionsUIUpdate()
        }
    }

    func eraseThreadActions(needUpdateUI: Bool = true) {
        threadActions.removeAll()
        if needUpdateUI {
            triggerActionsUIUpdate()
        }
    }

    // Independent a method for reducing call setActions redundancy.
    func triggerActionsUIUpdate() {
        setActions()
    }

    func updateTitle(_ selectedCount: Int) {
        selectedTitleLabel.text = BundleI18n.MailSDK.Mail_ThreadAction_Multi_selected(selectedCount)
    }

    private func setActions() {
        let actionsFactory = MailMessageListActionFactory()
        let actions = actionsFactory.threadActionBarTopActions(threadActions: threadActions, labelId: fromLabelID, autoRead: false)

        let arrangedSubviews = barItemStackView.arrangedSubviews
        for subview in arrangedSubviews {
            barItemStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        for styleConfig in actions {
            if let forceMore = self.actionDelegate?.needForceMore(), forceMore == true {
                break
            }
            var selector: Selector = #selector(doNothinng)
            switch styleConfig.type {
            case .archive: selector = #selector(archiveMail)
            case .trash: selector = #selector(trashMail)
            case .unRead: selector = #selector(unreadMail)
            case .read: selector = #selector(readMail)
            case .spam: selector = #selector(spamMail)
            case .notSpam: selector = #selector(notSpamMail)
            case .delete: selector = #selector(deleteOutboxMail)
            case .edit: selector = #selector(editOutboxMail)
            case .deleteDraft: selector = #selector(deleteDraft)
            case .deletePermanently: selector = #selector(deletePermanently)
            case .moveToInbox: selector = #selector(moveToInbox)
            case .changeLabels: selector = #selector(onChangeLabelsClick)
            case .blockSender: selector = #selector(handleBlockSender)
            default:
                break
            }
            if styleConfig.type == .edit {
                continue
            }
            let button = UIButton(type: .custom)
            button.setImage(styleConfig.icon.withRenderingMode(.alwaysTemplate), for: .normal)
            button.addTarget(self, action: selector, for: .touchUpInside)
            button.tintColor = UIColor.ud.iconN1
            barItemStackView.addArrangedSubview(button)
            button.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 24, height: 24))
            }
        }
        if !actionsFactory.threadActionBarMoreActions(threadActions: threadActions, labelId: fromLabelID, forceMore: self.actionDelegate?.needForceMore() ?? false).isEmpty
            && fromLabelID != Mail_LabelId_Outbox {
            moreBtn.tintColor = UIColor.ud.iconN1
            barItemStackView.addArrangedSubview(moreBtn)
        }
    }

    func updateActionsLabel(selectedRows: [IndexPath]) {
        // 从数据源中取交集
        let intersectionSet = filterSet(.intersection, selectedRows: selectedRows)
        let unionSet = filterSet(.union, selectedRows: selectedRows)
        threadLabels = Array(intersectionSet).map { MailFilterLabelCellModel(pbModel: $0) }
        semiCheckedLabels = Array(unionSet.symmetricDifference(intersectionSet)).map { MailFilterLabelCellModel(pbModel: $0) }
    }

    enum setType {
        case intersection // 交集
        case union // 并集
    }

    func filterSet(_ type: setType, selectedRows: [IndexPath]) -> Set<MailClientLabel> {
        var flag = false
        let resultSet = selectedRows.reduce(Set<MailClientLabel>.init(), { (set, indexPath) -> Set<MailClientLabel> in
            var res: Set<MailClientLabel> = set
            var labels = [MailClientLabel]()
            if let homeResultItems = homeResultItems, homeResultItems.count > indexPath.row {
                labels = MailTagDataManager.shared.getTagModels(homeResultItems[indexPath.row].labelIDs ?? [])
            }
            if let searchResultItems = searchResultItems, searchResultItems.count > indexPath.row {
                labels = searchResultItems[indexPath.row].viewModel.labels
            }
            let tempSet = Set<MailClientLabel>(labels)
            if flag {
                if type == .intersection {
                    res = res.intersection(tempSet)
                } else if type == .union {
                    res = res.union(tempSet)
                } else {
                    res = tempSet
                }
            } else {
                res = tempSet
                flag = true
            }
            return res
        })
        return resultSet
    }

    @objc
    fileprivate func backItemTapHandler(_ sender: ThreadActionsBar) {
        actionDelegate?.didClickExitButton()
    }

    func didClickMoreAction(actionType: ActionType, fromLabel: String? = nil) {
        switch actionType {
        case .archive: archiveMail()
        case .trash: trashMail()
        case .unRead: unreadMail()
        case .read: readMail()
        case .spam: spamMail()
        case .notSpam: notSpamMail(fromLabel: fromLabel)
        case .changeLabels: actionDelegate?.showupEditLabelsPage(threadIDs: threadIDs, threadLabels: threadLabels, scene: .homeMulti)
        case .moveToInbox: moveToInbox()
        case .moveTo: moveToLabel(threadIDs: threadIDs)
        case .delete: deleteOutboxMail()
        case .edit: editOutboxMail()
        case .deletePermanently: deletePermanently()
        case .moveToImportant: moveToImportant()
        case .moveToOther: moveToOther()
        case .cancelScheduleSend: cancelScheduledSend()
        case .cancelAllScheduleSend: cancelAllScheduledSend()
        case .emlAsAttachment: emlAsAttachment()
        case .blockSender: handleBlockSender()
        case .unknown,
             .contentSearch,
             .flag,
             .unFlag,
             .priority,
             .readReceipt,
             .deleteDraft,
             .sendSeparaly,
             .discardDraft,
             .scheduleSend,
             .saveDraft,
             .contentDarkMode,
             .more,
             .allowStranger,
             .rejectStranger:
            break
        }
    }

}

extension ThreadActionsBar {

    private func sendMultiRequest(threadIds: [String],
                                  addLabelIds: [String],
                                  removeLabelIds: [String],
                                  reportType: Email_Client_V1_ReportType? = nil,
                                  toastText: String?,
                                  ignoreUnauthorized: Bool = false,
                                  supportUndo: Bool = false,
                                  fromLabel: String? = nil) {
        MailLogger.info("[mail_multi_select] -- sendMultiRequest \(threadIds) - \(addLabelIds) - \(removeLabelIds)")
        let tempWindow = self.window
        MailDataServiceFactory
            .commonDataService?
            .multiMutLabelForThread(threadIds: threadIds,
                                    addLabelIds: addLabelIds,
                                    removeLabelIds: removeLabelIds,
                                    fromLabelID: fromLabel ?? fromLabelID,
                                    ignoreUnauthorized: ignoreUnauthorized,
                                    reportType: reportType)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                if addLabelIds.contains(Mail_LabelId_Trash) {
                    if let window = tempWindow {
                        MailUndoToastFactory.showMailActionToast(by: response.uuid, type: .trash, fromLabel: self.fromLabelID, toastText: threadIds.count > 1 ? BundleI18n.MailSDK.Mail_Notification_Multi_Thread_Trash(threadIds.count) : BundleI18n.MailSDK.Mail_ThreadAction_TrashToast, on: window, feedCardID: nil)
                    } else {
                        mailAssertionFailure("window is nil")
                    }
                } else if let toastText = toastText {
                    if let window = tempWindow, supportUndo {
                        MailUndoToastFactory.showMailActionToast(by: response.uuid, type: .changeLabels,
                                                                 fromLabel: self.fromLabelID, toastText: toastText, on: window, feedCardID: nil)
                    } else {
                        self.showupToast(toastText)
                    }
                }
                self.backBlock?()
            }, onError: { (error) in
                MailLogger.error("Send multiMutLabelForThread request failed error: \(error).")
            }, onCompleted: { [weak self] in
                self?.didMultiMutLabelForThreadAction(addLabelIds, removeLabelIds)
            }).disposed(by: multiMutLabelBag)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "changelabel")
    }

    private func sendMultiDeleteDraftRequest(threadIds: [String],
                                             addLabelIds: [String],
                                             removeLabelIds: [String],
                                             toastText: String) {
        MailDataServiceFactory
            .commonDataService?
            .multiDeleteDraftForThread(threadIds: threadIDs,
                                       fromLabelID: fromLabelID).subscribe(onNext: { () in

                                       }, onError: { (error) in
                                        MailLogger.error("Send multiDeleteDraftForThread request failed error: \(error).")

                                       }, onCompleted: { [weak self] in
                                        self?.didMultiMutLabelForThreadAction([], [Mail_LabelId_Draft])
                                        self?.showupToast(toastText)
                                       }).disposed(by: multiMutLabelBag)
    }

    func didMultiMutLabelForThreadAction(_ addLabelIds: [String], _ removeLabelIds: [String]) {
        actionDelegate?.didMultiMutLabelForThread()
    }

    func showupToast(_ text: String) {
        if text.isEmpty {
            return
        }
        MailRoundedHUD.remove(on: self)
        MailRoundedHUD.showSuccess(with: text, on: self)
    }

    @objc
    func doNothinng() {}

    @objc
    func onChangeLabelsClick() {
        actionDelegate?.onChangeLabelClick(bar: self)
    }

    @objc
    func archiveMail() {
        MailTracker.log(event: Homeric.EMAIL_THREAD_ARCHIVE,
                        params: [MailTracker.isMultiselectParamKey(): true,
                                 MailTracker.sourceParamKey():
                                    MailTracker.source(type: .threadAction),
                                 MailTracker.threadCountParamKey(): threadIDs.count])
        let toastText = threadIDs.count > 1 ? BundleI18n.MailSDK.Mail_Notification_Multi_thread_archive(threadIDs.count) : BundleI18n.MailSDK.Mail_ThreadAction_ArchiveToast
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [Mail_LabelId_Archived],
                         removeLabelIds: [],
                         toastText: toastText)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "archive")
    }

    @objc
    func cancelAllScheduledSend() {
        actionDelegate?.cancelScheduleSendConfirm()
    }

    @objc
    func cancelScheduledSend() {
        let isMultiSelect = threadIDs.count > 1 ? 1: 0
        MailTracker.log(event: "email_thread_scheduledSend_cancel", params: ["source": "thread_action",
                                                                             "is_multiselect": isMultiSelect,
                                                                             "thread_count": threadIDs.count])
        MailDataSource.shared.cancelScheduledSend(messageId: nil, threadIds: threadIDs, feedCardID: nil)
        .subscribe(onNext: { [weak self] _ in
            self?.showupToast(BundleI18n.MailSDK.Mail_SendLater_Cancelsucceed)
        }, onError: { [weak self] (error) in
            guard let `self` = self else { return }
            MailLogger.error("mail cancelScheduledSend error: \(error)")
            self.showupToast(BundleI18n.MailSDK.Mail_SendLater_CancelFailure)
            MailRoundedHUD.remove(on: self)
            MailRoundedHUD.showFailure(with: BundleI18n.MailSDK.Mail_SendLater_CancelFailure, on: self,
                                       event: ToastErrorEvent(event: .schedule_send_cancel_fail))
            }).disposed(by: multiMutLabelBag)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "cancel_time_send")
    }

    @objc
    func trashMail() {
        MailTracker.log(event: Homeric.EMAIL_THREAD_TRASH,
                        params:
                            [MailTracker.isMultiselectParamKey(): true,
                             MailTracker.sourceParamKey():
                                MailTracker.source(type: .threadAction),
                             MailTracker.threadCountParamKey():
                                threadIDs.count])
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [Mail_LabelId_Trash],
                         removeLabelIds: [],
                         toastText: nil)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "trash")
    }

    @objc
    func deleteDraft() {
        actionDelegate?.deleteDraftConfirm(handler: {})
    }

    func multiDeleteDraft() {
        MailTracker.log(event: Homeric.EMAIL_DRAFT_DISCARD, params: [MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction), MailTracker.isMultiselectParamKey(): true])
        sendMultiDeleteDraftRequest(threadIds: threadIDs,
                                    addLabelIds: [],
                                    removeLabelIds: [Mail_LabelId_Draft],
                                    toastText: BundleI18n.MailSDK.Mail_Toast_DiscardMultiDraftsSuccess)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "delete_clean")
    }

    @objc
    func unreadMail() {
        MailTracker.log(event: Homeric.EMAIL_THREAD_MARKASUNREAD,
                        params: [
                            MailTracker.threadCountParamKey(): threadIDs.count,
                            MailTracker.isMultiselectParamKey(): true,
                            MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction)])
        let toastText = threadIDs.count > 1 ? BundleI18n.MailSDK.Mail_Notification_Multi_Thread_Unread(threadIDs.count) : BundleI18n.MailSDK.Mail_ThreadAction_UnreadToast
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [Mail_LabelId_UNREAD],
                         removeLabelIds: [],
                         toastText: toastText)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "marksunread")
    }

    @objc
    func readMail() {
        MailTracker.log(event: Homeric.EMAIL_THREAD_MARKASREAD,
                        params: [
                            MailTracker.threadCountParamKey(): threadIDs.count,
                            MailTracker.isMultiselectParamKey(): true,
                            MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction)])
        let toastText = threadIDs.count > 1 ? BundleI18n.MailSDK.Mail_Notification_Multi_Thread_Read(threadIDs.count) : BundleI18n.MailSDK.Mail_ThreadAction_ReadToast
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [],
                         removeLabelIds: [Mail_LabelId_UNREAD],
                         toastText: toastText)
        actionDelegate?.didHandleActionType(type: .read)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "marksread")
    }

    @objc
    func spamMail() {
        if let window = window {
            actionDelegate?.presentSpamAlert(type: .markSpam, content: spamAlertContent) { [weak self] ignore in
                self?.markSpam(ignoreUnauthorized: ignore)
            }
        } else {
            markSpam(ignoreUnauthorized: false)
        }
    }

    private func markSpam(ignoreUnauthorized: Bool) {
        MailTracker.log(event: Homeric.EMAIL_THREAD_SPAM,
                        params: [
                            MailTracker.isMultiselectParamKey(): true,
                            MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction),
                            MailTracker.threadCountParamKey(): threadIDs.count
                        ])
        let toastText = threadIDs.count > 1 ? BundleI18n.MailSDK.Mail_Notification_Multi_Thread_Spam(threadIDs.count) : BundleI18n.MailSDK.Mail_MarkedAsSpam_Toast
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [Mail_LabelId_Spam],
                         removeLabelIds: [],
                         reportType: .spam,
                         toastText: toastText,
                         ignoreUnauthorized: ignoreUnauthorized)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "spam")
    }

    @objc
    func notSpamMail(fromLabel: String?) {
        if let window = window {
            actionDelegate?.presentSpamAlert(type: .markNormal, content: spamAlertContent) { [weak self] ignore in
                self?.markNotSpam(ignoreUnauthorized: ignore, fromLabel: fromLabel)
            }
        } else {
            markNotSpam(ignoreUnauthorized: false, fromLabel: fromLabel)
        }
    }

    private func markNotSpam(ignoreUnauthorized: Bool, fromLabel: String?) {
        let toastText = threadIDs.count > 1 ? BundleI18n.MailSDK.Mail_Notification_MutiThreadNotSpam2(threadIDs.count) : BundleI18n.MailSDK.Mail_UnmarkedSpamMovetoInbox_Toast
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [Mail_LabelId_Inbox],
                         removeLabelIds: [],
                         reportType: .ham,
                         toastText: toastText,
                         ignoreUnauthorized: ignoreUnauthorized,
                         fromLabel: fromLabel)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "not_spam")
    }

    @objc
    func deleteOutboxMail() {
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [],
                         removeLabelIds: [Mail_LabelId_Outbox],
                         toastText: "")

        actionDelegate?.multiSelectNewCoreEvent(actionType: "outbox_delete")
    }

    @objc
    func editOutboxMail() {
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [Mail_LabelId_Outbox],
                         removeLabelIds: [],
                         toastText: "")

        actionDelegate?.multiSelectNewCoreEvent(actionType: "outbox_edit")
    }

    @objc
    func moveToInbox() {
        let toastText = threadIDs.count > 1 ? BundleI18n.MailSDK.Mail_Notification_Multi_Thread_Inbox(threadIDs.count) : BundleI18n.MailSDK.Mail_ThreadAction_InboxToast
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: [Mail_LabelId_Inbox],
                         removeLabelIds: [],
                         toastText: toastText)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "move_to_inbox")
    }

    @objc
    func moveToLabel(threadIDs: [String], supportUndo: Bool = false, reportTea: Bool = true) {
        if threadIDs.isEmpty {
            return
        }
        let labelsVC = MailMoveToLabelViewController(threadIds: threadIDs, fromLabelId: self.fromLabelID, accountContext: self.accountContext)
        labelsVC.spamAlertContent = spamAlertContent
        if Store.settingData.folderOpen() || Store.settingData.mailClient {
            labelsVC.scene = .moveToFolder
            let isMultiSelect = threadIDs.count > 1 ? 1: 0
            MailTracker.log(event: "email_thread_move_to_folder",
                            params: [
                                MailTracker.sourceParamKey():
                                    MailTracker.source(type: .threadAction),
                                "thread_count": threadIDs.count,
                                "is_multiselect": isMultiSelect])
        }
        let canUndo = accountContext.featureManager.open(FeatureKey(fgKey: .threadCustomSwipeActions, openInMailClient: true)) && supportUndo && !Store.settingData.mailClient // oc func parma type not support, use mailClient flag
        labelsVC.blockMoveToSuccessToast = canUndo
        labelsVC.didMoveLabelCallback = { [weak self] label, newFolderToast, respuuid in
            guard let `self` = self else { return }
            if canUndo {
                self.actionDelegate?.didMoveMultiLabel(newFolderToast: newFolderToast, undoInfo: (respuuid, label.text))
            } else {
                if !newFolderToast.isEmpty {
                    self.actionDelegate?.didMoveMultiLabel(newFolderToast: newFolderToast, undoInfo: ("", label.text))
                }
            }

        }
        let nav = LkNavigationController(rootViewController: labelsVC)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        actionDelegate?.presentVC(vc: nav)

        if reportTea {
            actionDelegate?.multiSelectNewCoreEvent(actionType: "move_to")
        }
    }

    @objc
    func moreActionDidClick(sender: UIControl) {
        actionDelegate?.moreActionDidClick(sender: sender)
    }

    @objc
    func changeLabels(addLabelIds: [String], removeLabelIds: [String], threadCounts: Int, toast: String, supportUndo: Bool = false) {
        if !addLabelIds.isEmpty {
            MailTracker.log(event: Homeric.EMAIL_THREAD_ADDLABEL, params: [MailTracker.isMultiselectParamKey(): true, MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction)])
        }
        if !removeLabelIds.isEmpty {
            MailTracker.log(event: Homeric.EMAIL_THREAD_DELETELABEL,
                            params: [
                                MailTracker.isMultiselectParamKey(): true,
                                MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction)])
        }
        sendMultiRequest(threadIds: threadIDs,
                         addLabelIds: addLabelIds,
                         removeLabelIds: removeLabelIds,
                         toastText: toast,
                         supportUndo: supportUndo)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "changelabel")
    }
    @objc
    func deletePermanently() {
        actionDelegate?.deletePermanently(labelID: fromLabelID, threadIDs: threadIDs, handler: {})
        actionDelegate?.multiSelectNewCoreEvent(actionType: "delete_clean")
    }
    
    @objc
    func handleBlockSender() {
        actionDelegate?.handleBlockSender(labelID: fromLabelID, threadIDs: threadIDs)
    }
    
    @objc
    func moveToImportant() {
        MailTracker.log(event: Homeric.EMAIL_SMARTINBOX_LABEL_CHANGE,
                        params: [MailTracker.toParamKey(): "important",
                                 MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction),
                                 MailTracker.threadIDsParamKey(): threadIDs.map({ $0 }).joined(separator: ", "),
                                 MailTracker.isMultiselectParamKey(): "true"])
        MailDataSource.shared.moveMultiLabelRequest(threadIds: threadIDs,
                                                    fromLabel: fromLabelID,
                                                    toLabel: Mail_LabelId_Important)
            .subscribe(onNext: { [weak self] in
                self?.actionDelegate?.didMultiMutLabelForThread()
                self?.showupToast(BundleI18n.MailSDK.Mail_SmartInbox_MoveToImportant_Success)
            }, onError: { (error) in
                MailLogger.error("mail moveToImportant error: \(error).")
            }).disposed(by: multiMutLabelBag)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "move_to_important")
    }

    @objc
    func moveToOther() {
        MailTracker.log(event: Homeric.EMAIL_SMARTINBOX_LABEL_CHANGE, params: [MailTracker.toParamKey(): "other",
                                                                               MailTracker.sourceParamKey(): MailTracker.source(type: .threadAction),
                                                                               MailTracker.threadIDsParamKey(): threadIDs.map({ $0 }).joined(separator: ", "),
                                                                               MailTracker.isMultiselectParamKey(): "true"])
        MailDataSource.shared.moveMultiLabelRequest(threadIds: threadIDs,
                                                    fromLabel: fromLabelID,
                                                    toLabel: Mail_LabelId_Other)
            .subscribe(onNext: { [weak self] in
                self?.actionDelegate?.didMultiMutLabelForThread()
                self?.showupToast(BundleI18n.MailSDK.Mail_SmartInbox_MoveToOthers_Success)
            }, onError: { (error) in
                MailLogger.error("mail moveToOther error: \(error).")
            }).disposed(by: multiMutLabelBag)

        actionDelegate?.multiSelectNewCoreEvent(actionType: "move_to_other")
    }
    
    func emlAsAttachment() {
        actionDelegate?.multiSelectNewCoreEvent(actionType: "foward_as_attachment")
        guard let reach = Reachability(), reach.connection != .none else {
            UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_UnableToForwardAsAttachment_Toast,
                                on: self.window ?? self)
            return
        }
        if threadIDs.count > self.emlAsAttachmentMaxCnt {
            UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_EmailAttachmentLimit(self.emlAsAttachmentMaxCnt),
                                on: self.window ?? self)
            return
        }
        MailDataServiceFactory
            .commonDataService?.getThreadLastMessageInfoRequest(labelId: fromLabelID, threadIds: threadIDs).subscribe(onNext: { [weak self] (resp) in
                guard let `self` = self else { return }
                let infos = resp.messageInfoList.compactMap { info in
                    EmlAsAttachmentInfo(subject: info.subject, bizId: info.bizID)
                }
                if !infos.isEmpty {
                    self.actionDelegate?.makeSendVCEmlAsAttachment(infos: infos)
                } else {
                    MailLogger.info("multi select emlAsAttachment empty info")
                    UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_UnableToForwardAsAttachment_Toast,
                                        on: self.window ?? self)
                }
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                UDToast.showFailure(with: BundleI18n.MailSDK.Mail_MailAttachment_UnableToForwardAsAttachment_Toast,
                                    on: self.window ?? self)
                MailLogger.error("multi select emlAsAttachment error: \(error).")
            }).disposed(by: emlBag)
        
    }
}
