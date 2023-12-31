//
//  MailHomeController+SwipeActions.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/9/2.
//

import Foundation
import LarkSwipeCellKit
import RustPB
import RxSwift
import LarkZoomable
import LarkSceneManager
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import LarkAlertController
import EENavigator
import LarkUIKit

public enum MailThreadCellSwipeAction: String {
    case archive
    case read
    case unread
    case trash
    case deleteDraft
    case deletePermanently
    case spam
    case unspam
    case moveTo
    case changeLabels
    case moveToInbox
    case onboardLeft
    case onboardRight
}

extension MailThreadCellSwipeAction {
    func actionTitle() -> String {
        switch self {
        case .archive:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_Archive_Button
        case .read:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_Read_Button
        case .unread:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_UnRead_Button
        case .trash:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_Delete_Button
        case  .deleteDraft:
            return BundleI18n.MailSDK.Mail_DiscardDraft_MenuItem
        case .deletePermanently:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_DeletePermanently_Button
        case .spam:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_Spam_Button
        case .unspam:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_NotSpam_Button
        case .moveTo:
            return BundleI18n.MailSDK.Mail_ThreadAction_MoveToLabel
        case .changeLabels:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_LabelAs_Button
        case .moveToInbox:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_MovetoInbox_Button
        case .onboardLeft, .onboardRight:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_SwipeSettings_Button
        }
    }
    
    func previewTitle() -> String {
        switch self {
        case .read, .unread:
            return BundleI18n.MailSDK.Mail_EmailSwipeActions_MarkasReadUnread_text
        case .archive, .trash, .spam, .moveTo, .changeLabels, .moveToInbox,
                .onboardLeft, .onboardRight, .deleteDraft, .deletePermanently, .unspam:
            return actionTitle()
        }
    }
    
    func actionIcon() -> UIImage {
        switch self {
        case .archive:
            return UDIcon.archiveOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .read:
            return UDIcon.markReadOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .unread:
            return UDIcon.unreadOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .trash, .deleteDraft, .deletePermanently:
            return UDIcon.deleteTrashOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .spam:
            return UDIcon.spamOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .unspam:
            return UDIcon.notspamOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .moveTo:
            return UDIcon.moveOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .changeLabels:
            return UDIcon.labelChangeOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .moveToInbox:
            return UDIcon.inboxOutlined.ud.colorize(color: UIColor.ud.primaryOnPrimaryFill)
        case .onboardLeft:
            return UDIcon.swipeRightOutlined.ud.colorize(color: UIColor.ud.iconN2)
        case .onboardRight:
            return UDIcon.swipeLeftOutlined.ud.colorize(color: UIColor.ud.iconN2)
        }
    }
    
    func actionBgColor() -> UIColor {
        switch self {
        case .archive:
            return UIColor.ud.colorfulTurquoise
        case .read:
            return UIColor.ud.colorfulWathet
        case .unread:
            return UIColor.ud.colorfulWathet
        case .trash, .deleteDraft, .deletePermanently:
            return UIColor.ud.colorfulRed
        case .spam, .unspam:
            return UIColor.ud.colorfulOrange
        case .moveTo, .moveToInbox:
            return UIColor.ud.colorfulIndigo
        case .changeLabels:
            return UIColor.ud.colorfulYellow
        case .onboardLeft, .onboardRight:
            return UIColor.ud.N200
        }
    }
}

extension SwipeActionsOrientation {
    func oriTitle() -> String {
        return self == .left ? BundleI18n.MailSDK.Mail_Settings_RightSwipe_Button : BundleI18n.MailSDK.Mail_Settings_LeftSwipe_Button
    }
}

extension Array where Element == MailThreadCellSwipeAction {
    
    func threadActions(isUnread: Bool) -> [MailThreadCellSwipeAction] {
        return self.map({
            if $0 == .read || $0 == .unread {
                return isUnread ? .read : .unread
            } else {
                return $0
            }
        })
    }
    
    func actionCanDeleteRow() -> Bool {
        return self.contains(.archive) || self.contains(.trash) || self.contains(.moveToInbox)
    }
    
    func actionPreviewTitle() -> String {
        return self.map({ $0.previewTitle() }).joined(separator: "丨").reduce("", { $0 + String($1) })
    }
    
    func recorrectAction(_ currentTagID: String, labelIDs: [String]?) -> [MailThreadCellSwipeAction] {
        if currentTagID == MailLabelId.Folder.rawValue || currentTagID == Mail_LabelId_Inbox ||
            currentTagID == Mail_LabelId_Important || currentTagID == Mail_LabelId_Other || currentTagID == Mail_LabelId_Sent {
            return self
        } else if currentTagID == Mail_LabelId_Draft {
            return self.filter({ $0 != .read && $0 != .unread && $0 != .archive && $0 != .moveTo && $0 != .spam })
                .compactMap({ if $0 == .trash { return .deleteDraft } else { return $0 } })
        } else if currentTagID == Mail_LabelId_Archived {
            return self.compactMap({ if $0 == .archive { return .moveToInbox } else { return $0 } })
        } else if currentTagID == Mail_LabelId_Spam {
            return self.filter({ $0 != .archive })
                .compactMap({
                    if $0 == .archive {
                        return .moveToInbox
                    } else if $0 == .trash {
                        return .deletePermanently
                    } else if $0 == .spam {
                        return .unspam
                    } else {
                        return $0
                    }
                })
        } else if currentTagID == Mail_LabelId_Trash {
            return self.filter({ $0 != .archive && $0 != .spam }).compactMap({ if $0 == .trash { return .deletePermanently } else { return $0 } })
        } else if currentTagID == Mail_LabelId_FLAGGED ||
                    (currentTagID != MailLabelId.Folder.rawValue && !currentTagID.isSystemLabel()) { // 自定义标签 or Flag
            if let labelIDs = labelIDs, let folderID = labelIDs.first(where: { systemFolders.contains($0) })  {
                return recorrectAction(folderID, labelIDs: labelIDs)
            } else {
                return self
            }
        } else if currentTagID == Mail_LabelId_Outbox {
            return []
        } else if currentTagID == Mail_LabelId_Scheduled {
            return self.filter({ $0 != .archive && $0 != .spam && $0 != .moveTo && $0 != .trash })
        }
        return self
    }
    
    func convertToSlideAction() -> [MailSlideActionType] {
        return self.map({
            switch $0 {
            case .read, .unread:
                return Email_Client_V1_SlideAction.SlideActionType.markRead
            case .archive:
                return Email_Client_V1_SlideAction.SlideActionType.archive
            case .trash, .deleteDraft, .deletePermanently:
                return Email_Client_V1_SlideAction.SlideActionType.trash
            case .spam, .unspam:
                return Email_Client_V1_SlideAction.SlideActionType.spam
            case .moveTo, .moveToInbox:
                return Email_Client_V1_SlideAction.SlideActionType.moveTo
            case .changeLabels:
                return Email_Client_V1_SlideAction.SlideActionType.label
            case .onboardLeft, .onboardRight:
                return Email_Client_V1_SlideAction.SlideActionType.markRead
            }
        })
    }

    func removeUnsupport(inSetting: Bool = true) -> [MailThreadCellSwipeAction] {
        let shouldFilter = inSetting ? Store.settingData.clientStatus == .mailClient : Store.settingData.mailClient
        if shouldFilter {
            return self.filter({ $0 != .archive && $0 != .changeLabels && $0 != .spam })
        } else {
            return self
        }
    }
}

extension Array where Element == MailSlideActionType {
    func convertToSwipeAction() -> [MailThreadCellSwipeAction] {
        return self.map({
            switch $0 {
            case Email_Client_V1_SlideAction.SlideActionType.markRead:
                return .read
            case Email_Client_V1_SlideAction.SlideActionType.archive:
                return .archive
            case Email_Client_V1_SlideAction.SlideActionType.trash:
                return .trash
            case Email_Client_V1_SlideAction.SlideActionType.moveTo:
                return .moveTo
            case Email_Client_V1_SlideAction.SlideActionType.label:
                return .changeLabels
            case Email_Client_V1_SlideAction.SlideActionType.spam:
                return .spam
            @unknown default:
                return .read
            }
        })
    }

    func removeUnsupport(inSetting: Bool = true) -> [MailSlideActionType] {
        let shouldFilter = inSetting ? Store.settingData.clientStatus == .mailClient : Store.settingData.mailClient
        if shouldFilter {
            return self.filter({ $0 != Email_Client_V1_SlideAction.SlideActionType.archive && $0 != Email_Client_V1_SlideAction.SlideActionType.label && $0 != Email_Client_V1_SlideAction.SlideActionType.spam})
        } else {
            return self
        }
    }
}

extension MailHomeController {
    /// 根据Setting/FG/Onboard情况配置SwipeActions
    func configThreadListCellVMActions(cellVM: MailThreadListCellViewModel) -> ([MailThreadCellSwipeAction], [MailThreadCellSwipeAction]) {
        guard userContext.featureManager.open(FeatureKey(fgKey: .threadCustomSwipeActions, openInMailClient: true)) else {
            return ([.archive], [cellVM.isUnread ? .read : .unread])
        }
        let isUnread = cellVM.isUnread
        let tagID = viewModel.currentTagID
        let slideAction = Store.settingData.swipeActions.value
        var leftActions: [MailThreadCellSwipeAction] = slideAction.0
            .threadActions(isUnread: isUnread).recorrectAction(tagID, labelIDs: cellVM.labelIDs)
        var rightActions: [MailThreadCellSwipeAction] = slideAction.1
            .threadActions(isUnread: isUnread).recorrectAction(tagID, labelIDs: cellVM.labelIDs)
        if showSwipeActionConfigOnbardingIfNeeded() {
            leftActions.append(.onboardLeft)
            rightActions.append(.onboardRight)
        }
        return (leftActions, rightActions)
    }
    
    func showSwipeActionConfigOnbardingIfNeeded() -> Bool {
        let guideKey = "mobile_email_threadlist_swipe"
        guard let guide = userContext.provider.guideServiceProvider?.guideService else { return false }
        return guide.checkShouldShowGuide(key: guideKey)
    }
}

extension MailHomeController: SwipeTableViewCellDelegate {
    // github example
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
//        guard orientation == .right else { return nil }
//
//        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath, flag in
//            // handle action by updating model with deletion
//        }
//
//        // customize the action appearance
//        deleteAction.image = UIImage(named: "delete")
//
//        return [deleteAction]
//    }

    func tableView(_ tableView: UITableView,
                   editActionsForRowAt indexPath: IndexPath,
                   for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        if isMultiSelecting {
            return nil
        }
        guard let cell = tableView.cellForRow(at: indexPath) as? MailThreadListCell else {
            return nil
        }

        let manager = viewModel
        if let cellViewModel = cell.cellViewModel {
            let threadActions = MailThreadActionCalculator.calculateThreadActions(fromLabel: viewModel.currentTagID,
                                                                                  cellViewModel: cellViewModel).map { (indexedAction) -> ActionType in
                indexedAction.action
            }
            if manager.allowsSwipeDirection(labelId: self.viewModel.currentLabelId,
                                            threadAction: threadActions,
                                            filterType: viewModel.currentFilterType) != nil {
                let swipeActions = configThreadListCellVMActions(cellVM: cellViewModel)
                if orientation == .left {
                    MailLogger.debug("[mail_swipe_actions] editActionsForRowAt orientation left: \(swipeActions.0)")
                    return getActions(swipeActions.0, cell, cellViewModel)
                }

                if orientation == .right {
                    MailLogger.debug("[mail_swipe_actions] editActionsForRowAt orientation right: \(swipeActions.1)")
                    return getActions(swipeActions.1, cell, cellViewModel)
                }
            } else {
                return nil
            }
        }

        return nil
    }

    // 微调左右滑动的样式
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        if orientation == .left, let leftOrientation = viewModel.listViewModel.leftOrientation {
            return leftOrientation
        } else if orientation == .right, let rightOrientation = viewModel.listViewModel.rightOrientation {
            return rightOrientation
        }

        var options = SwipeOptions()

        // 消失动画。。有点模糊
        let style = SwipeExpansionStyle(target: .percentage(0.15),
            additionalTriggers: [],
            elasticOverscroll: true,
            completionAnimation: .fill(.manual(timing: .after)))
        let readStyle = SwipeExpansionStyle(target: .percentage(0.3),
                                            additionalTriggers: [.overscroll(30)],
                                            elasticOverscroll: true,
                                            completionAnimation: .bounce)
        if let cell = tableView.cellForRow(at: indexPath) as? MailThreadListCell, let cellVM = cell.cellViewModel {
            let swipeActions = configThreadListCellVMActions(cellVM: cellVM)
            if orientation == .left {
                let leftActions = swipeActions.0
                options.expansionStyle = (leftActions.count > 1 || leftActions.isEmpty) ? nil : readStyle
                if leftActions.count == 1 && leftActions.actionCanDeleteRow() {
                    options.expansionStyle = style
                    options.transitionStyle = SwipeTransitionStyle.custom(FeedBorderTransitionLayout())
                } else {
                    options.transitionStyle = SwipeOptions().transitionStyle
                }
                options.backgroundColor = leftActions.first?.actionBgColor() ?? .clear
            } else {
                let rightActions = swipeActions.1
                options.expansionStyle = (rightActions.count > 1 || rightActions.isEmpty) ? nil : readStyle
                if rightActions.count == 1 && rightActions.actionCanDeleteRow() {
                    options.expansionStyle = style
                    options.transitionStyle = SwipeTransitionStyle.custom(FeedBorderTransitionLayout())
                } else {
                    options.transitionStyle = SwipeOptions().transitionStyle
                }
                options.backgroundColor = rightActions.first?.actionBgColor() ?? .clear
            }
        }

        options.buttonHorizontalPadding = CGFloat(12)
        options.buttonSpacing = CGFloat(4)
        options.maximumButtonWidth = CGFloat(84)
        options.minimumButtonWidth = CGFloat(84)
        options.buttonWidthStyle = .auto
        options.buttonVerticalAlignment = .center
        
        let angleLimit: Double = 1.4
        // 上下滑动触发机制, 调整角度使横向手势触发概率变小
        // 目前参数定制为拖拽角度小于 35 度触发
        options.shouldBegin = { (x, y) in
            return abs(y) * angleLimit < abs(x)
        }

        if orientation == .left {
            viewModel.listViewModel.leftOrientation = options
        } else {
            viewModel.listViewModel.rightOrientation = options
        }
        return options
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) {
        UDToast.removeToast(on: self.view)
        ActionToast.removeToast(on: self.view)
        viewModel.listViewModel.addChangeFilter()
        
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {
        if let indexPath = indexPath {
            consumOnboardKeyIfNeeded(orientation, indexPath: indexPath)
        }
        viewModel.listViewModel.refreshMailThreadListIfNeeded()
    }
    
    func consumOnboardKeyIfNeeded(_ orientation: SwipeActionsOrientation, indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? MailThreadListCell else { return }
        guard let cellVM = cell.cellViewModel else { return }
        let swipeActions = configThreadListCellVMActions(cellVM: cellVM)
        if (orientation == .left && swipeActions.0.contains(.onboardLeft)) ||
            (orientation == .right && swipeActions.1.contains(.onboardRight)) {
            if userContext.provider.guideServiceProvider?.guideService?.checkShouldShowGuide(key: "mobile_email_threadlist_swipe") ?? false {
                userContext.provider.guideServiceProvider?.guideService?.didShowedGuide(guideKey: "mobile_email_threadlist_swipe")
                viewModel.listViewModel.leftOrientation = nil
                viewModel.listViewModel.rightOrientation = nil
                viewModel.syncDataSource()
                tableView.reloadData()
            }
        }
    }

    func visibleRect(for tableView: UITableView) -> CGRect? {
        tableView.safeAreaLayoutGuide.layoutFrame
    }

    // MARK: Helpers

    func getActions(_ threadActions: [MailThreadCellSwipeAction],
                    _ cell: MailThreadListCell,
                    _ cellViewModel: MailThreadListCellViewModel) -> [SwipeAction] {
        var actions: [SwipeAction] = []
        for action in threadActions {
            let title = action.actionTitle()
            let icon = action.actionIcon()
            let bgColor = action.actionBgColor()
            switch action {
            case .archive:
                var archive = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForArchive(cell, cellModel: cellViewModel)
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&archive, bgColor: bgColor, iconImage: icon)
                actions.append(archive)
            case .read:
                var read = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForReadStatus(cell, cellModel: cellViewModel)
                }
                configAction(&read, bgColor: bgColor, iconImage: icon)
                actions.append(read)
            case .unread:
                var unread = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForReadStatus(cell, cellModel: cellViewModel)
                }
                configAction(&unread, bgColor: bgColor, iconImage: icon)
                actions.append(unread)
            case .trash:
                var trash = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForTrash(cell, cellModel: cellViewModel)
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&trash, bgColor: bgColor, iconImage: icon)
                actions.append(trash)
            case .deleteDraft:
                var deleteDraft = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForDeleteDraft(cell, cellModel: cellViewModel)
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&deleteDraft, bgColor: bgColor, iconImage: icon)
                actions.append(deleteDraft)
            case .deletePermanently:
                var deletePermanently = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForDeletePermanently(cell, cellModel: cellViewModel)
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&deletePermanently, bgColor: bgColor, iconImage: icon)
                actions.append(deletePermanently)
            case .spam:
                var spam = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForSpam(cell, cellModel: cellViewModel)
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&spam, bgColor: bgColor, iconImage: icon)
                actions.append(spam)
            case .unspam:
                var notspam = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForNotSpam(cell, cellModel: cellViewModel)
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&notspam, bgColor: bgColor, iconImage: icon)
                actions.append(notspam)
            case .moveTo:
                var moveTo = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.threadActionBar.moveToLabel(threadIDs: [cellViewModel.threadID], supportUndo: true, reportTea: false)
                    self.statThreadAction("move_to_folder")
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&moveTo, bgColor: bgColor, iconImage: icon)
                actions.append(moveTo)
            case .changeLabels:
                var moveTo = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.showupEditLabelsPage(threadIDs: [cellViewModel.threadID],
                                              threadLabels: MailTagDataManager.shared.getTagModels(cellViewModel.labelIDs ?? []).map({ MailFilterLabelCellModel(pbModel: $0) }),
                                              scene: .homeSwipeAction)
                    self.statThreadAction("change_label")
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&moveTo, bgColor: bgColor, iconImage: icon)
                actions.append(moveTo)
            case .onboardLeft, .onboardRight:
                var onboard = SwipeAction(style: .default, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForSwipeSetting()
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&onboard, bgColor: bgColor, iconImage: icon, onboard: true)
                actions.append(onboard)
            case .moveToInbox:
                var moveToInbox = SwipeAction(style: .destructive, title: title) { [weak self] (_, _, _) in
                    guard let self = self else { return }
                    self.markForMoveToInbox(cell, cellModel: cellViewModel)
                    self.viewModel.listViewModel.refreshMailThreadListIfNeeded()
                }
                configAction(&moveToInbox, bgColor: bgColor, iconImage: icon)
                actions.append(moveToInbox)
            }
        }

        return actions
    }
    
    private func configAction(_ action: inout SwipeAction, bgColor: UIColor, iconImage: UIImage, onboard: Bool = false) {
        action.backgroundColor = bgColor
        action.image = iconImage //.scaled(toPercentage: Zoom.currentZoom.scale)
        action.hidesWhenSelected = true
        action.textAlignment = .center
        action.transitionDelegate = ScaleTransition.default
        let maxFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
        let normalFont = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        let smallFont = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        if onboard {
            action.textColor = UIColor.ud.textCaption
            action.font = normalFont
        } else {
            action.textColor = UIColor.ud.primaryOnPrimaryFill
            action.font = maxFont
        }
        // 多语言适配规则
        guard let title = action.title else { return }
        let normalFontHeightLimit: CGFloat = 20
        let smallFontHeightLimit: CGFloat = 34
        let textWidth: CGFloat = 76
        if title.getTextHeight(font: maxFont, width: textWidth) > normalFontHeightLimit &&
            title.getTextHeight(font: normalFont, width: textWidth) > normalFontHeightLimit {
            action.font = normalFont
            if title.getTextHeight(font: normalFont, width: textWidth) > smallFontHeightLimit &&
                title.getTextHeight(font: smallFont, width: textWidth) > smallFontHeightLimit {
                action.font = smallFont
            }
            let textLengthLimit: Int = 14
            if title.count > textLengthLimit {
                action.title = title.prefix(textLengthLimit - 2) + "..."
            }
        }
    }

    func markForArchive(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        destructiveActionCellHandler(cell)
        threadActionDataManager.archiveMail(threadID: cellModel.threadID, fromLabel: viewModel.currentLabelId,
                                            msgIds: [], sourceType: .threadSlide, on: self.view)
        statMoveAction(type: "archive", threadID: cellModel.threadID)
        statThreadAction("archive")
    }
    
    func markForMoveToInbox(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        destructiveActionCellHandler(cell)
        threadActionDataManager.moveToInbox(threadID: cellModel.threadID, fromLabel: viewModel.currentLabelId, sourceType: .threadSlide, on: self.view)
        statThreadAction("move_to_inbox")
    }
    
    func markForTrash(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        destructiveActionCellHandler(cell)
        threadActionDataManager.trashMail(threadID: cellModel.threadID, fromLabel: viewModel.currentLabelId,
                                          msgIds: [], sourceType: .threadSlide, on: self.view)
        statThreadAction("trash")
    }

    func markForDeleteDraft(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        showDeleteDraftConfirm { [weak self] in
            guard let `self` = self else { return }
            MailDataServiceFactory
                .commonDataService?
                .multiDeleteDraftForThread(threadIds: [cellModel.threadID],
                                           fromLabelID: self.viewModel.currentLabelId).subscribe(onNext: { [weak self] () in
                    guard let `self` = self else { return }
                    MailRoundedHUD.showSuccess(with: BundleI18n.MailSDK.Mail_Toast_DiscardMultiDraftsSuccess, on: self.view)
                    self.destructiveActionCellHandler(cell)
                    self.statMoveAction(type: "undelete", threadID: cellModel.threadID)
                    self.statThreadAction("delete_clean")
                }, onError: { (error) in
                    MailLogger.error("Send multiDeleteDraftForThread request failed error: \(error).")
                }).disposed(by: self.disposeBag)
        }
    }

    func markForDeletePermanently(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        deletePermanently(labelID: viewModel.currentLabelId, threadIDs: [cellModel.threadID], handler: { [weak self] in
            self?.destructiveActionCellHandler(cell)
        })
        statThreadAction("delete_clean")
    }

    func statThreadAction(_ actionType: String) {
        let labelsMenuController = self.getTagMenu()
        let value = NewCoreEvent.labelTransfor(labelId: labelsMenuController.viewModel.selectedID,
                                               allLabels: labelsMenuController.viewModel.labels)
        NewCoreEvent.threadListThreadAction(isMultiSelected: false,
                                            position: "thread_slide",
                                            actionType: actionType,
                                            filterType: viewModel.currentFilterType,
                                            labelItem: value,
                                            displayType: Store.settingData.threadDisplayType())
    }
    
    func markForSpam(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        presentSpamAlert(type: .markSpam, content: SpamAlertContent()) { [weak self] ignore in
            guard let `self` = self else { return }
            self.threadActionDataManager.spamMail(threadID: cellModel.threadID,
                                                  fromLabel: self.viewModel.currentLabelId,
                                                  msgIds: [],
                                                  sourceType: .threadSlide,
                                                  ignoreUnauthorized: ignore,
                                                  on: self.view, handler: { [weak self] in
                self?.destructiveActionCellHandler(cell)
                self?.statThreadAction("spam")
            })
        }
    }

    func markForNotSpam(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        presentSpamAlert(type: .markNormal, content: SpamAlertContent()) { [weak self] ignore in
            guard let `self` = self else { return }
            self.threadActionDataManager.notSpamMail(threadID: cellModel.threadID,
                                                     fromLabel: self.viewModel.currentLabelId,
                                                     sourceType: .threadSlide,
                                                     ignoreUnauthorized: false,
                                                     on: self.view, handler: { [weak self] in
                self?.destructiveActionCellHandler(cell)
                self?.statThreadAction("not_spam")
            })
        }
    }

    func markForSwipeSetting() {
        let settingController = MailSettingWrapper.getSettingController(userContext: userContext)
        settingController.clientDelegate = self
        let nav = LkNavigationController(rootViewController: settingController)
        nav.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        navigator?.present(nav, from: self, completion:  {
            settingController.jumpToSwipeActionsSettingPage()
        })
    }
    
    private func destructiveActionCellHandler(_ cell: MailThreadListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }

        /// 这里的动画，可能与 reloadData 同时进行，所以需要设立一个标记
        /// 当这里刚刚 rows 动画后，延迟执行 reloadData
        self.delayReload = true
        let shouldnotRemoved = self.shouldnotRemoved()
        if !viewModel.datasource.isEmpty {
            if tableView.cellForRow(at: indexPath) != nil, !shouldnotRemoved {
                var datasource = viewModel.datasource
                datasource.remove(at: indexPath.row)
                viewModel.listViewModel.setThreadsListOfLabel(viewModel.currentLabelId, mailList: datasource)
                viewModel.syncDataSource()
                if viewModel.currentLabelId == Mail_LabelId_Draft {
                    tableView.reloadData()
                } else {
                    if datasource.isEmpty {
                        status = .empty
                        tableView.reloadRows(at: [indexPath], with: .left) // 标记归档后马上有thread change进行reload，所以这里不使用delete
                    } else {
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            } else if shouldnotRemoved {
                if viewModel.currentLabelId == Mail_LabelId_Draft {
                    tableView.reloadData()
                } else {
                    tableView.reloadRows(at: [indexPath], with: .left)
                }
            }
        } else {
            if tableView.cellForRow(at: indexPath) != nil {
                clearContentsBeforeAsynchronouslyDisplay = false
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
    }

    private func shouldnotRemoved() -> Bool {
        guard let currentLabelModel = viewModel.currentLabelModel else {
            return false
        }
        if currentLabelModel.tagType == .folder {
            return false
        }
        return !systemLabels.contains(viewModel.currentLabelId) || [Mail_LabelId_FLAGGED, Mail_LabelId_Sent].contains(viewModel.currentLabelId)
    }

    func markForUnreadFilterType(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        let status = cell.isUnread
        self.delayReload = true
        threadActionDataManager.unreadMail(threadID: cellModel.threadID,
                                           fromLabel: viewModel.currentLabelId,
                                           isRead: status,
                                           fromSearch: false,
                                           sourceType: .threadSlide,
                                           on: self.view)
        if !viewModel.datasource.isEmpty {
            if tableView.cellForRow(at: indexPath) != nil {
                clearContentsBeforeAsynchronouslyDisplay = false
                viewModel.syncDataSource()
                tableView.reloadData()
            }
        } else {
            if tableView.cellForRow(at: indexPath) != nil {
                clearContentsBeforeAsynchronouslyDisplay = false
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        }
        if status {
            MailAPMErrorDetector.shared.startDetect(cellModel.threadID)
        }
        statMoveAction(type: status ? "markread" : "markunread", threadID: cellModel.threadID)

        statThreadAction(status ? "marksread" : "marksunread")
        viewModel.listViewModel.$unreadPreloadChange.accept((viewModel.currentLabelId, [cellModel.threadID : status ? .delete : .add]))
    }

    func markForReadStatus(_ cell: MailThreadListCell, cellModel: MailThreadListCellViewModel) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        guard viewModel.currentFilterType != .unread else {
            markForUnreadFilterType(cell, cellModel: cellModel)
            return
        }

        self.delayReload = true
        //handleRefreshedDatas(datasource)

        var datasource = self.viewModel.datasource
        let unread = datasource.changeUnreadState(at: indexPath.row)
        self.viewModel.syncDataSource(datas: datasource)
        cell.setUnread(unread, animated: true)

        tableView.beginUpdates()
        tableView.endUpdates()
        self.threadActionDataManager.unreadMail(threadID: cellModel.threadID,
                                                fromLabel: self.viewModel.currentLabelId,
                                                isRead: !unread,
                                                fromSearch: false,
                                                sourceType: .threadSlide,
                                                on: self.view)
        if !unread {
            MailAPMErrorDetector.shared.startDetect(cellModel.threadID)
        }
        self.statMoveAction(type: unread ? "markunread" : "markread", threadID: cellModel.threadID)
        self.statThreadAction(unread ? "marksread" : "marksunread")
        viewModel.listViewModel.$unreadPreloadChange.accept((viewModel.currentLabelId, [cellModel.threadID : !unread ? .delete : .add]))
    }
}

fileprivate extension UIImage {

    /// 将图片按比例缩放，返回缩放后的图片
    /// - Parameter percentage: 缩放比例
    /// - Parameter opaque: 当前图片是否有透明部分
    func scaled(toPercentage percentage: CGFloat, opaque: Bool = false) -> UIImage? {
        let factor = scale == 1.0 ? UIScreen.main.scale : 1.0
        let newWidth = floor(size.width * percentage / factor)
        let newHeight = floor(size.height * percentage / factor)
        let newRect = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
        let format = imageRendererFormat
        format.opaque = opaque
        format.scale = 0
        return UIGraphicsImageRenderer(size: newRect.size, format: format).image { _ in
            draw(in: newRect)
        }
    }
}

class FeedBorderTransitionLayout: SwipeTransitionLayout {
//    var style: MailBorderLayoutStyle = .dismiss
//    init(style: MailBorderLayoutStyle) {
//        self.style = style
//    }

    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {
    }

    func layout(view: UIView, atIndex index: Int, with context: ActionsViewLayoutContext) {
        if context.contentWidths.indices.contains(index) {
            let sum = context.contentWidths.reduce(0, +)
            var proportion: CGFloat = 0
            for (contentIndex, item) in context.contentWidths.enumerated() {
                if contentIndex >= index {
                    break
                }
                proportion += item / sum
            }
            view.frame.origin.x = (context.contentSize.width * proportion) * context.orientation.scale
        } else {
            let diff = context.visibleWidth - context.contentSize.width
            view.frame.origin.x = (CGFloat(index) * context.contentSize.width / CGFloat(context.numberOfActions) + diff) * context.orientation.scale
        }
//        switch self.style {
//        case .dismiss:
//            if context.contentWidths.indices.contains(index) {
//                let sum = context.contentWidths.reduce(0, +)
//                var proportion: CGFloat = 0
//                for (contentIndex, item) in context.contentWidths.enumerated() {
//                    if contentIndex >= index {
//                        break
//                    }
//                    proportion += item / sum
//                }
//                view.frame.origin.x = (context.contentSize.width * proportion) * context.orientation.scale
//            } else {
//                let diff = context.visibleWidth - context.contentSize.width
//                view.frame.origin.x = (CGFloat(index) * context.contentSize.width / CGFloat(context.numberOfActions) + diff) * context.orientation.scale
//            }
//        case .revert:
//            if context.contentWidths.indices.contains(index) {
//                let sum = context.contentWidths.reduce(0, +)
//                var proportion: CGFloat = 0
//                for (contentIndex, item) in context.contentWidths.enumerated() {
//                    if contentIndex >= index {
//                        break
//                    }
//                    proportion += item / sum
//                }
//                view.frame.origin.x = (context.contentSize.width * proportion) * context.orientation.scale
//            } else {
//                let diff = context.visibleWidth - context.contentSize.width
//                view.frame.origin.x = (CGFloat(index) * context.contentSize.width / CGFloat(context.numberOfActions) + diff) * context.orientation.scale
//            }
//        }

    }

    func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat] {

        // visible widths are all the same regardless of the action view position
        return context.contentWidths
    }
}
