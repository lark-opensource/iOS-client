//
//  DetailViewController+NaviAction.swift
//  Todo
//
//  Created by wangwanxin on 2021/12/27.
//

import CTFoundation
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignActionPanel
import LarkSnsShare
import EENavigator
import UniverseDesignDialog
import LarkMessageBase
import TodoInterface
import RustPB
import LarkAlertController
import LarkSetting
import UniverseDesignToast
import UIKit
import LarkSensitivityControl
import LarkEMM

/// Detail - Navi

extension DetailViewController {

    // MARK: - Setup Navi Item

    func setupNaviItem() {
        // left navi item
        if let controllers = navigationController?.viewControllers,
           controllers.contains(self) && (controllers.count > 1) {
            addBackItem()
        } else {
            // add close item
            let barItem = LKBarButtonItem(image: nil, title: I18N.Todo_Common_Cancel, fontStyle: .regular)
            barItem.button.titleLabel?.textColor = UIColor.ud.textTitle
            barItem.button.addTarget(self, action: #selector(closeBtnTapped), for: .touchUpInside)
            navigationItem.leftBarButtonItem = barItem
        }

        // right navi item
        typealias NaviItemContent = (title: String?, image: UIImage?, selector: Selector)
        let color = UIColor.ud.iconN1
        let rightNaviItemContents: [DetailViewModel.NaviItemType: NaviItemContent] = [
            .minimize: (
                title: nil,
                image: UDIcon.minimizeOutlined.ud.withTintColor(UIColor.ud.iconN2).withRenderingMode(.alwaysOriginal),
                selector: #selector(handleShrinkItemClick)
            ),
            .create: (
                title: context.scene.createBtnTitle,
                image: nil,
                selector: #selector(handleCreateItemClick)
            ),
            .more: (
                title: nil,
                image: UDIcon.moreOutlined.ud.withTintColor(color),
                selector: #selector(handleMoreItemClick)
            ),
            .subscribe: (
                title: nil,
                image: UDIcon.subscribeAddOutlined.ud.withTintColor(color),
                selector: #selector(handleSubscribeItemClick)
            ),
            .subscribed: (
                title: nil,
                image: UDIcon.resolveColorful,
                selector: #selector(handleSubscribeItemClick)
            ),
            .copyNum: (
                title: nil,
                image: UDIcon.copyOutlined,
                selector: #selector(numClick)
            ),
            .share: (
                title: nil,
                image: UDIcon.shareOutlined.ud.withTintColor(color),
                selector: #selector(handleShareItemClick)
            )
        ]
        let makeNaviBarItem = { [weak self] (naviItem: DetailViewModel.NaviItem) -> UIBarButtonItem in
            guard let self = self, let content = rightNaviItemContents[naviItem.type] else {
                assertionFailure()
                return .init()
            }
            let barItem = LKBarButtonItem(image: content.image, title: content.title, fontStyle: .medium, buttonType: content.image == nil ? .system : .custom)
            barItem.button.addTarget(self, action: content.selector, for: .touchUpInside)
            let isEnabled = naviItem.isEnabled
            barItem.button.isUserInteractionEnabled = naviItem.isEnabled
            if content.title != nil {
                barItem.button.tintColor = isEnabled ? UIColor.ud.primaryContentDefault : UIColor.ud.textDisabled
            }
            return barItem
        }
        let makeEmptyNaviItem = { () -> UIBarButtonItem in
            return LKBarSpaceItem(width: 2)
        }
        viewModel.rxRightNaviItems.subscribe(onNext: { [weak self] naviItems in
            var naviBarItems = [UIBarButtonItem]()
            for (i, naviItem) in naviItems.enumerated() {
                if i > 0 {
                    naviBarItems.append(makeEmptyNaviItem())
                }
                naviBarItems.append(makeNaviBarItem(naviItem))
            }
            self?.navigationItem.setRightBarButtonItems(naviBarItems, animated: false)
        }).disposed(by: disposeBag)
    }

    func _copyTaskNum() {
        Detail.Track.clickCopyId(with: viewModel.store.state.todo?.guid ?? "")
        do {
            let config = PasteboardConfig(token: Token("LARK-PSDA-task-detail-navi-number"))
            try SCPasteboard.generalUnsafe(config).string = viewModel.taskNumberURL
            guard let window = view.window else {
                assertionFailure("can not find window")
                return
            }
            Utils.Toast.showSuccess(with: I18N.Todo_Task_CopySuccessful, on: window, bottomInset: commentInputHeight())
        } catch { }
    }

    /// 目前通过这种方式取评论输入框的高度
    private func commentInputHeight() -> CGFloat {
        if let first = children.first(where: { $0 is CommentInputViewController }), let comment = first as? CommentInputViewController {
            let height = comment.keyboardView.frame.height
            return Utils.Toast.standardBottomInset > height ? Utils.Toast.standardBottomInset : height + Utils.Toast.bottomSpace
        }
        return Utils.Toast.standardBottomInset
    }

    // MARK: - Navi Actions

    private func getActionSheet(
        title: String? = nil,
        titleColor: UIColor? = nil
    ) -> (UDActionSheet) {
        let source = UDActionSheetSource(
            sourceView: view,
            sourceRect: CGRect(x: view.frame.maxX - 45, y: view.frame.minY - 80, width: 0, height: 0),
            arrowDirection: .up
        )
        let config = UDActionSheetUIConfig(titleColor: titleColor, isShowTitle: title != nil, popSource: source)
        let actionSheet = UDActionSheet(config: config)
        if let title = title {
            actionSheet.setTitle(title)
        }
        return actionSheet
    }

    // MARK: Internal Navi Action - Create

    func _handleCreateItemClick() {
        Detail.logger.info("navi create clicked")
        let window = self.view.window
        let doCreate = { [weak self] in
            guard let self = self else { return }
            self.cancelEditing()
            self.viewModel.createTodo { [weak self] res in
                guard let window = window else { return }
                switch res {
                case .success(let todo):
                    self?.showOperationToast(todo: todo, on: window)
                    self?.exit(reason: .create)
                case .failure(let userErr):
                    Utils.Toast.showError(with: userErr.message, on: window)
                }
            }
        }
        doCreate()
    }

    private func showOperationToast(todo: Rust.Todo, on view: UIView) {
        // 来自会话的场景不需要弹【查看详情】
        if viewModel.input.isQiuckCreate, let createSource = viewModel.store.state.scene.createSource, !createSource.isFromChat {
            var operation = UDToastOperationConfig(
                text: I18N.Todo_ViewDetails_New,
                displayType: .auto
            )
            operation.textAlignment = .left
            let config = UDToastConfig(
                toastType: .success,
                text: I18N.Todo_common_CreatedSuccessfully,
                operation: operation
            )
            UDToast.showToast(with: config, on: view, delay: 7) { [self] _ in
                // 这里需要强持有下self, 不然会被释放掉
                if case let .quickExpand(_, _, _, _, _, _, callbacks) = self.viewModel.input {
                    callbacks.successToastHandler?(todo)
                }
            }
        } else {
            Utils.Toast.showSuccess(with: I18N.Todo_common_CreatedSuccessfully, on: view)
        }
    }

    // MARK: Internal Navi Action - Subscribe / Subscribed

    func _handleSubscribeItemClick() {
        if !viewModel.store.state.selfRole.contains(.follower) {
            Detail.Track.clickSubscribe(with: viewModel.store.state.todo?.guid ?? "")
        }
        guard let last = navigationItem.rightBarButtonItems?.last as? LKBarButtonItem, let view = last.button.superview else {
            return
        }
        if let alertContext = viewModel.alertBeforeToggling() {
            showTogglingAlert(with: alertContext, from: view)
        } else {
            viewModel.toggleFollowing(before: beforeLoading(_:), after: makeCallback())
        }
    }

    /// 翻转关注（关注 -> 未关注）前，弹 alert
    private func showTogglingAlert(with ctx: DetailViewModel.AlertContext, from sourceView: UIView) {
        Detail.logger.info("show toggling alert for unfollowing")
        let source = UDActionSheetSource(
            sourceView: sourceView,
            sourceRect: sourceView.bounds,
            arrowDirection: .unknown
        )
        let config = UDActionSheetUIConfig(titleColor: UIColor.ud.textPlaceholder, isShowTitle: true, popSource: source)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(ctx.title)
        actionSheet.addItem(
            UDActionSheetItem(
                title: ctx.item,
                titleColor: UIColor.ud.textTitle,
                action: { [weak self] in
                    Detail.logger.info("click \(ctx.item) item")
                    guard let self = self else { return }
                    ctx.confirm(self.beforeLoading(_:), self.makeCallback())
                }
            )
        )
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel) {
            Detail.logger.info("click cancel item")
        }
        present(actionSheet, animated: true)
    }

    private func makeCallback() -> DetailViewModel.ToggleCallback {
        return { [weak self] res in
            guard let self = self, let window = self.view.window else { return }
            switch res {
            case let .success((toast, needsExit)):
                Utils.Toast.showSuccess(with: toast, on: window)
                if needsExit {
                    self.exit(reason: .unfollow)
                }
            case let .failure(userErr):
                Utils.Toast.showError(with: userErr.message, on: window)
            }
        }
    }

    private func beforeLoading(_ text: String) {
        guard let window = view.window else {
            return
        }
        Utils.Toast.showLoading(
            with: text,
            on: window,
            disableUserInteraction: true
        )
    }

    // MARK: Internal Navi Action - Share

    func _handleShareItemClick() {
        Detail.logger.info("navi share clicked")
        let summaryText = viewModel.summaryForSharing()
        var shareBody = SelectSharingItemBody(summary: summaryText)
        shareBody.onCancel = {
            Detail.logger.info("sharing canceled")
        }
        shareBody.onConfirm = { [weak self] (items, message) in
            Detail.logger.info("select sharing items: \(items.count), msg: \(message?.count ?? 0)")
            guard let self = self else { return }
            let removable = Utils.Toast.showLoading(with: I18N.Todo_Task_Sharing, on: self.view)
            self.viewModel.shareToLark(with: items, message: message) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(_, let blockAlert):
                    if let blockAlert = blockAlert {
                        if blockAlert.preferToast {
                            Utils.Toast.showError(with: blockAlert.message, on: self.view)
                        } else {
                            removable()
                            let alertVC = LarkAlertController()
                            alertVC.setTitle(text: I18N.Todo_Common_FailToSend)
                            alertVC.setContent(text: blockAlert.message)
                            alertVC.addPrimaryButton(text: I18N.Todo_Task_Confirm)
                            self.present(alertVC, animated: true)
                        }
                    } else {
                        Utils.Toast.showSuccess(with: I18N.Todo_Task_ShareSucTip, on: self.view)
                    }
                case .failure(let message):
                    Utils.Toast.showError(with: message, on: self.view)
                }
            }
        }
        var routeParams = RouteParams(from: self)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.openType = .present
        routeParams.wrap = LkNavigationController.self
        routeDependency?.selectSharingItem(with: shareBody, params: routeParams)
        Detail.tracker(.todo_task_share, params: ["source": "task details"])
        Detail.Track.clickShare(with: context.scene.todoId ?? "")
    }

    // MARK: Internal Navi Action - More

    func _handleMoreItemClick() {
        Detail.logger.info("navi more clicked")
        Detail.Track.clickMore(with: context.scene.todoId ?? "")
        let isMilestone = viewModel.store.state.isMilestone

        typealias MoreItemContent = (text: String, textColor: UIColor, action: () -> Void)
        let moreNaviItemContents: [ViewModel.NaviMoreItemType: MoreItemContent] = [
            .preDependent: (
                text: I18N.Todo_GanttView_BlockedBy_MenuItem,
                textColor: UIColor.ud.textTitle,
                action: { [weak self] in self?.showDependentPicker(.prev) }
            ),
            .nextDepedent: (
                text: I18N.Todo_GanttView_Blocking_MenuItem,
                textColor: UIColor.ud.textTitle,
                action: { [weak self] in self?.showDependentPicker(.next) }
            ),
            .milestone: (
                text: isMilestone ? I18N.Todo_GanttView_UnmarkMilestone_Button : I18N.Todo_GanttView_MarkMilestone_Button,
                textColor: UIColor.ud.textTitle,
                action: { [weak self] in self?.handleMilestoneItem() }
            ),
            .editRecord: (
                text: I18N.Todo_Task_ViewChangelogButton,
                textColor: UIColor.ud.textTitle,
                action: { [weak self] in self?.handleEditRecordItemClick() }
            ),
            .report: (
                text: I18N.Todo_Report_Report,
                textColor: UIColor.ud.textTitle,
                action: { [weak self] in self?.handleReportItemClick() }
            ),
            .delete: (
                text: I18N.Todo_Task_DeleteTaskButton,
                textColor: UIColor.ud.textTitle,
                action: { [weak self] in self?.handleDeleteItemClick() }
            ),
            .quit: (
                text: I18N.Todo_LeaveTask_Button,
                textColor: UIColor.ud.functionDangerContentDefault,
                action: { [weak self] in self?.handleQuitItemClick() }
            ),
            .copyTaskGuid: (
                text: "Copy Task Guid",
                textColor: UIColor.ud.textTitle,
                action: { [weak self] in self?.handleDebugGuidItemClick() }
            ),
            .copyTaskInfo: (
                text: "Copy Task Info",
                textColor: UIColor.ud.textTitle,
                action: { [weak self] in self?.handleDebugInfoItemClick() }
            )
        ]

        let vc = getActionSheet()
        viewModel.naviMoreItems()
            .compactMap { moreNaviItemContents[$0] }
            .forEach {
                let item = UDActionSheetItem(title: $0.text, titleColor: $0.textColor, action: $0.action)
                vc.addItem(item)
            }
        vc.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(vc, animated: true)
    }
    
    // MARK: Navi Action - Dependent

    private func showDependentPicker(_ type: Rust.TaskDependent.TypeEnum) {
        let guid = viewModel.store.state.todo?.guid ?? ""
        Detail.Track.clickNaviMoreDep(with: guid, type: type, isAddFinal: false)
        var filterTaskGuids: [String]?
        if let keys = viewModel.store.state.dependentsMap?.keys {
            filterTaskGuids = Array(keys)
            if !guid.isEmpty {
                filterTaskGuids?.append(guid)
            }
        }
        let viewModel = DetailDependentPickerViewModel(
            resolver: userResolver,
            filterTaskGuids: filterTaskGuids,
            type: type
        )
        let vc = DetailDependentPickerViewController(
            viewModel: viewModel) { [weak self] todos in
                Detail.Track.clickNaviMoreDep(with: guid, type: type, isAddFinal: true)
                self?.viewModel.handlePickerDependents(todos, type)
            }
        userResolver.navigator.present(vc, from: self)
    }

    // MARK: Navi Action - Milestone

    private func handleMilestoneItem() {
        let oldValue = viewModel.store.state.isMilestone
        Detail.logger.info("update mile stone. old value: \(oldValue)")
        Detail.Track.clickMileStone(with: viewModel.store.state.todo?.guid ?? "", isMark: !oldValue)
        viewModel.store.dispatch(.updateMilestone(!oldValue))
    }

    // MARK: Navi Action - EditRecord

    // 跳转到 change log
    private func handleEditRecordItemClick() {
        Detail.logger.info("navi edit record clicked")
        guard let todo = viewModel.store.state.todo else {
            assertionFailure()
            return
        }
        Detail.tracker(.todo_task_history_click, params: ["task_id": todo.guid])
        Detail.Track.clickViewHistory(with: todo.guid)
        Detail.Track.viewHistory(with: todo.guid, chatId: context.scene.chatId)
        let viewModel = ListActivityRecordsViewModel(resolver: userResolver, scene: .task, guid: todo.guid)
        let vc = ListActivityRecordsViewController(resolver: userResolver, viewModel: viewModel)
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    // MARK: Internal Navi Action - Report

    func handleReportItemClick() {
        Detail.logger.info("navi report clicked")
        let domainSettings = DomainSettingManager.shared.currentSetting
        guard let reportHost = domainSettings[.suiteReport]?.first,
              !reportHost.isEmpty else {
            Detail.assertionFailure("reportHost is missing")
            return
        }
        guard let guid = context.scene.todoId else {
            Detail.assertionFailure()
            return
        }
        let paramsStr = "{\"guid\": \"\(guid)\"}"
        guard let encodedParamsStr = paramsStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            Detail.assertionFailure("encoded failed")
            return
        }
        let urlStr = "https://\(reportHost)/report/?type=todo&params=\(encodedParamsStr)"
        guard let url = URL(string: urlStr) else {
            Detail.assertionFailure("transform url failed")
            return
        }
        userResolver.navigator.present(
            url,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
        Detail.logger.info("try to report guid: \(guid)")
    }

    // MARK: Internal Navi Action - Delete

    func handleDeleteItemClick() {
        Detail.logger.info("navi delete clicked")
        let guid = context.scene.todoId ?? ""
        Detail.tracker(.todo_task_delete, params: ["task_id": guid])
        let title = viewModel.hideDeleteActionTitle() ? nil : I18N.Todo_Task_DeleteTaskDialogContent
        let vc = getActionSheet(
            title: title,
            titleColor: UIColor.ud.textPlaceholder
        )
        let (text, textColor) = (I18N.Todo_Task_DeleteTaskButton, UIColor.ud.functionDangerContentDefault)
        vc.addItem(UDActionSheetItem(title: text, titleColor: textColor, action: { [weak self] in
            guard let self = self else { return }
            Detail.Track.clickLeave(with: guid)
            Detail.tracker(.todo_task_delete_confirm, params: ["task_id": guid])
            let window = self.view.window
            self.viewModel.deleteTodo { [weak self] res in
                switch res {
                case .success:
                    self?.exit(reason: .delete)
                    if let window = window {
                        Utils.Toast.showSuccess(with: I18N.Todo_common_DeletedSuccessfully, on: window)
                    }
                case .failure(let userErr):
                    if let window = window {
                        Utils.Toast.showError(with: userErr.message, on: window)
                    }
                }
            }
        }))
        vc.setCancelItem(text: I18N.Todo_Common_Cancel) {
            Detail.tracker(.todo_task_delete_cancel, params: ["task_id": guid])
        }
        present(vc, animated: true, completion: nil)
    }

    // MARK: Navi Action - Quit

    private func handleQuitItemClick() {
        Detail.logger.info("navi quit clicked")
        let vc = getActionSheet(
            title: I18N.Todo_New_LeaveTaskMobile_Title,
            titleColor: UIColor.ud.textPlaceholder
        )
        let text = I18N.Todo_LeaveTask_Button
        let (title, titleColor) = (text, UIColor.ud.functionDangerContentDefault)
        vc.addItem(UDActionSheetItem(title: title, titleColor: titleColor, action: { [weak self] in
            guard let self = self else { return }
            Detail.Track.clickLeave(with: self.context.scene.todoId ?? "")
            let window = self.view.window
            self.viewModel.quitTodo { [weak self] res in
                switch res {
                case .success:
                    self?.exit(reason: .quit)
                    if let window = window {
                        let toast = I18N.Todo_LeaveTask_Left_Toast
                        Utils.Toast.showSuccess(with: toast, on: window)
                    }
                case .failure(let userErr):
                    guard let window = window else { return }
                    Utils.Toast.showError(with: userErr.message, on: window)
                }
            }
        }))
        vc.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(vc, animated: true, completion: nil)
    }

    // MARK: Navi Action - Debug

    private func handleDebugGuidItemClick() {
        let guid = viewModel.store.state.todo?.guid ?? ""
        do {
            let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
            try SCPasteboard.generalUnsafe(config).string = guid
            guard let window = view.window else { return }
            Utils.Toast.showSuccess(with: "Copy Success: \(guid)", on: window)
        } catch { }
    }

    private func handleDebugInfoItemClick() {
        #if DEBUG || ALPHA
        let info = try? viewModel.store.state.todo?.jsonString() ?? ""
        #else
        let info = ""
        #endif
        do {
            let config = PasteboardConfig(token: Token("psda_token_avoid_intercept"))
            try SCPasteboard.generalUnsafe(config).string = info
            guard let window = view.window else { return }
            Utils.Toast.showSuccess(with: "Copy Success: \(info ?? "")", on: window)
        } catch { }
    }

}
