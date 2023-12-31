//
//  V3HomeViewController+Action.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/25.
//

import Foundation
import LarkUIKit
import LarkNavigation
import EENavigator
import LarkSplitViewController
import TodoInterface
import UniverseDesignActionPanel
import UniverseDesignDialog
import UniverseDesignCheckBox
import UniverseDesignFont

// MARK: - Home -Action

extension V3HomeViewController {

    // MARK: - Crate

    func handleBigAdd(_ task: Rust.Todo = Rust.Todo().fixedForCreating()) {
        V3Home.logger.info("big add button clicked")
        V3Home.Track.clickListWholeAddTask(with: context.store.state.container)
        var newTask = task
        if let taskList = listModule.viewModel.curTaskList {
            newTask.relatedTaskListGuids = [taskList.guid]
        }
        createTodo(.list(container: listModule.viewModel.curContainerSection, task: newTask))
    }

    func createTodo(_ source: TodoCreateSource) {
        context.bus.post(.willCreateTodo)
        let callbacks = TodoCreateCallbacks(
            createHandler: { [weak self] res in
                self?.context.bus.post(.didCreatedTodo(res: res))
            },
            successToastHandler: { [weak self] todo in
                self?.context.bus.post(.showDetail(guid: todo.guid, needLoading: false, callbacks: .init()))
            }
        )
        userResolver.navigator.present(
            DetailViewController(resolver: userResolver, input: .create(source: source, callbacks: callbacks)),
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet },
            animated: true
        )
    }

    // MARK: - Detail

    func showDetail(with guid: String, needLoading: Bool, callbacks: TodoEditCallbacks) {
        let source = TodoEditSource.list(needLoading: needLoading)
        let detailVC = DetailViewController(resolver: userResolver, input: .edit(guid: guid, source: source, callbacks: callbacks))
        detailVC.closeCallback = { [weak self] in
            self?.context.bus.post(.deselectTodo)
        }
        if case .onePage = context.scene {
            userResolver.navigator.push(detailVC, from: self)
        } else {
            userResolver.navigator.showDetailOrPush(detailVC, wrap: LkNavigationController.self, from: self)
        }
    }

    func closeDetail(for guid: String) {
        guard let splitVC = larkSplitViewController,
              let naviVC = splitVC.secondaryViewController as? UINavigationController,
              let detailVC = naviVC.topViewController as? DetailViewController else {
            V3Home.logger.info("vc not match.")
            return
        }
        guard detailVC.guid == guid else {
            V3Home.logger.info("not match guid. detailVC.guid: \(detailVC.guid), target.guid: \(guid)")
            return
        }
        closeDetail()
    }

    /// ipad 上需要关闭详情页
    func closeDetail() {
        V3Home.logger.info("close detail")
        guard let splitVC = larkSplitViewController else { return }
        splitVC.showDetailViewController(SplitViewController.makeDefaultDetailVC(), sender: nil)
    }

    // MARK: - Drawer

    func shwoFilterDrawer(sourceView: UIView?) {
        if rootSizeClassIsRegular {
            guard let sourceView = sourceView else {
                assertionFailure()
                return
            }
            let vc = fg.boolValue(for: .organizableTaskList) ? sidebarModule : drawerModule
            vc.modalPresentationStyle = .popover
            vc.popoverPresentationController?.sourceView = sourceView
            vc.preferredContentSize = CGSize(width: 375, height: 450)
            let sourceRect = CGRect(
                x: sourceView.frame.width / 2,
                y: sourceView.frame.height, width: 0, height: 0
            )
            vc.popoverPresentationController?.sourceRect = sourceRect
            vc.popoverPresentationController?.permittedArrowDirections = .up
            // crash defence:
            // NSException Application tried to present modally a view controller
            // <Todo.FilterDrawerViewController> that is already being presented
            // by <LarkNavigation.RootNavigationController>.
            if vc.presentingViewController == nil {
                present(vc, animated: true)
            } else {
                assertionFailure()
            }
        } else {
            currentSideBarMenu?.showDrawer(.click(V3Home.drawerTag), completion: {})
        }
    }

    // MARK: - Share

    func shareTaskList(with container: Rust.TaskContainer?, sourceView: UIView? = nil, sourceVC: UIViewController? = nil) {
        guard let container = container, let applink = Utils.Applink.taskListApplink(with: container.guid) else { return }
        let fromVC = sourceVC ?? self
        let handleShare = { [weak self] in
            guard let self = self else { return }
            var shareBody = SelectSharingItemBody(summary: applink)
            shareBody.showIcon = false
            shareBody.ignoreBot = true
            shareBody.onCancel = { V3Home.logger.info("sharing task list canceled") }
            shareBody.onConfirm = { [weak self] (items, message) in
                guard let self = self else { return }
                self.viewModel.shareMember(
                    containerID: container.guid,
                    note: message,
                    items: items) { result in
                        guard let window = self.view.window else { return }
                        switch result {
                        case .succeed(let toast):
                            guard let toast = toast else { return }
                            Utils.Toast.showSuccess(with: toast, on: window)
                        case .failed(let toast):
                            guard let toast = toast else { return }
                            Utils.Toast.showError(with: toast, on: window)
                        }
                }
            }
            var routeParams = RouteParams(from: fromVC)
            routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
            routeParams.openType = .present
            routeParams.wrap = LkNavigationController.self
            self.routeDependency?.selectSharingItem(with: shareBody, params: routeParams)
        }

        sharePanel = V3ListSharePanel(
            resolver: userResolver,
            container: container,
            sourceVC: fromVC,
            applink: applink,
            handleShare: handleShare,
            shareBtn: sourceView
        )
        guard let sharePanel = sharePanel else { return }
        sharePanel.showSharePanel()
    }

    func switchContainer(by key: ContainerKey) {
        context.bus.post(.changeContainerByKey(key))
    }

    /// 接收新创建的Todo
    func receiveNewCreatedTodo(todo: Rust.Todo) {
        var res = Rust.CreateTodoRes()
        res.todo = todo
        context.bus.post(.didCreatedTodo(res: res))
    }
}

// MARK: - Task List

extension V3HomeViewController {
    enum MoreActionScene: Int {
        case drawer
        case listDetail
    }

    struct MoreActionData {
        var container: Rust.TaskContainer
        var ref: Rust.TaskListSectionRef?
    }

    func showTasklistMoreAction(
        data: MoreActionData,
        sourceView: UIView,
        sourceVC: UIViewController?,
        scene: MoreActionScene
    ) {
        let vc = sourceVC ?? self
        let actionSheet = getActionSheet(with: sourceView)
        let container = data.container
        actionSheet.addDefaultItem(text: I18N.Todo_List_Share_MenuItem) { [weak self, weak sourceView, weak sourceVC] in
            switch scene {
            case .listDetail:
                V3Home.Track.clickShareListInMore(with: container)
            case .drawer:
                HomeSidebar.Track.shareTasklist(with: container)
            }
            if Display.pad {
                self?.shareTaskList(with: container, sourceView: sourceView, sourceVC: sourceVC)
            } else {
                sourceVC?.dismiss(animated: true)
                self?.shareTaskList(with: container)
            }
        }

        actionSheet.addDefaultItem(text: I18N.Todo_Updates_Title) { [weak self] in
            guard let self = self else { return }
            V3Home.Track.clickActivity(with: container)
            sourceVC?.dismiss(animated: true)
            let viewModel = ListActivityRecordsViewModel(resolver: self.userResolver, scene: .taskList, guid: container.guid)
            let recordVC = ListActivityRecordsViewController(resolver: self.userResolver, viewModel: viewModel)
            if case .onePage = self.context.scene {
                self.userResolver.navigator.push(recordVC, from: self)
            } else {
                self.userResolver.navigator.showDetailOrPush(recordVC, wrap: LkNavigationController.self, from: self)
            }
        }

        if container.canEdit {
            actionSheet.addDefaultItem(text: I18N.Todo_List_Rename_MenuItem) { [weak self, weak vc] in
                guard let self = self, let vc = vc else { return }
                switch scene {
                case .listDetail:
                    V3Home.Track.clickRenameListInMore(with: container)
                case .drawer:
                    HomeSidebar.Track.renameTaskList(with: container)
                }
                let editVM = ListEditViewModel(scene: .edit(content: container.name))
                let editVC = ListEditViewController(viewModel: editVM)
                editVC.saveHandler = { [weak self, weak vc] title in
                    self?.viewModel.doUpdateTasklistTitle(title, container) { [weak vc] res in
                        guard let window = vc?.view.window else { return }
                        switch res {
                        case .success:
                            Utils.Toast.showSuccess(with: I18N.Todo_TaskListRenameSaved_Toast, on: window)
                        case .failure(let err):
                            Utils.Toast.showWarning(with: err.message, on: window)
                        }
                    }
                }
                self.userResolver.navigator.present(
                    editVC,
                    wrap: LkNavigationController.self,
                    from: vc,
                    prepare: { $0.modalPresentationStyle = .formSheet }
                )
            }
            let currentIsArchived = container.isArchived
            actionSheet.addDefaultItem(
                text: currentIsArchived ? I18N.Todo_TaskList_Restore_Button : I18N.Todo_TaskList_Archive_Button
            ) { [weak self, weak vc] in
                guard let vc = vc else { return }
                switch scene {
                case .listDetail:
                    V3Home.Track.clickArchiveListInMore(with: container)
                case .drawer:
                    HomeSidebar.Track.archiveTasklist(with: container)
                }
                if currentIsArchived {
                    self?.doUnarchiveTasklist(container: container, sourceVC: vc)
                } else {
                    self?.showArchiveConfirmDialog(container, vc)
                }
            }
        }
        if let ref = data.ref, !ref.isDeleted, fg.boolValue(for: .organizableTaskList) {
            actionSheet.addDefaultItem(text: I18N.Todo_TaskListSection_RemoveFromSection_DropDown_Button) { [weak self] in
                self?.viewModel.deleteTaskListSectionRef(in: container.guid, ref, userResponse: { [weak self] res in
                    HomeSidebar.Track.removeFromSection(with: container)
                    self?.handleUserRes(res)
                })
            }
        }

        if container.canDelete {
            actionSheet.addDefaultItem(text: I18N.Todo_List_Delete_MenuItem) { [weak self, weak vc] in
                guard let vc = vc else { return }
                self?.showDeleteConfirmDialog(container, vc, scene)
            }
        }

        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        vc.present(actionSheet, animated: true, completion: nil)
    }

    func doUnarchiveTasklist(container: Rust.TaskContainer, sourceVC: UIViewController?) {
        viewModel.doUnarchiveTasklist(container) { [weak self, weak sourceVC] res in
            let vc = sourceVC ?? self
            guard let window = vc?.view.window else { return }
            switch res {
            case .success:
                Utils.Toast.showSuccess(with: I18N.Todo_TaskList_Restored_Toast, on: window)
            case .failure(let err):
                Utils.Toast.showWarning(with: err.message, on: window)
            }
        }
    }

    private func showArchiveConfirmDialog(_ container: Rust.TaskContainer, _ sourceVC: UIViewController) {
        let dialog = UDDialog()
        dialog.setTitle(text: I18N.Todo_TaskList_ArchiveList_Title(container.name))
        dialog.setContent(text: I18N.Todo_TaskList_ArchiveList_Desc)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: I18N.Todo_TaskList_ArchiveList_Archive_Button, dismissCompletion: { [weak self, weak sourceVC] in
            self?.viewModel.doArchiveTasklist(container) { [weak sourceVC] res in
                guard let window = sourceVC?.view.window else { return }
                switch res {
                case .success:
                    Utils.Toast.showSuccess(with: I18N.Todo_TaskList_Archived_Toast, on: window)
                case .failure(let err):
                    Utils.Toast.showWarning(with: err.message, on: window)
                }
            }
        })
        sourceVC.present(dialog, animated: true)
    }

    private func showDeleteConfirmDialog(_ container: Rust.TaskContainer, _ sourceVC: UIViewController, _ scene: MoreActionScene) {
        let dialog = UDDialog()
        dialog.setTitle(text: I18N.Todo_List_DeleteList_Title(container.name))
        let customView = DialogCustomView()
        dialog.setContent(view: customView)
        dialog.addCancelButton()
        dialog.addDestructiveButton(
            text: I18N.Todo_List_DeleteListDelete_Button,
            dismissCompletion: { [weak self, weak customView, weak sourceVC] in
                let isRemoveNoOwnerTasks = customView?.isSelected ?? false
                switch scene {
                case .listDetail:
                    V3Home.Track.clickDeleteListInMore(with: container, isRemoveNoOwnerTasks)
                case .drawer:
                    HomeSidebar.Track.deleteTasklist(with: container, isRemoveNoOwnerTasks)
                }
                self?.viewModel.doDeleteTaskList(
                    container,
                    isRemoveNoOwnerTasks: isRemoveNoOwnerTasks,
                    completion: { [weak sourceVC] res in
                        guard let window = sourceVC?.view.window else { return }
                        switch res {
                        case .success(let toast):
                            if let toast = toast {
                                Utils.Toast.showSuccess(with: toast, on: window)
                            }
                        case .failure(let err):
                            Utils.Toast.showWarning(with: err.message, on: window)
                        }
                    })
            }
        )
        sourceVC.present(dialog, animated: true)
    }
}

// MARK: - Organizable Task List

extension V3HomeViewController {

    func showCreateTaskList(section: Rust.TaskListSection? = nil, from: UIViewController? = nil, callback: ((String) -> Void)? = nil, completion: ((Rust.TaskContainer) -> Void)?) {
        let vm = ListEditViewModel(scene: .create)
        let vc = ListEditViewController(viewModel: vm)
        vc.saveHandler = { [weak self] text in
            if let callback = callback {
                callback(text)
            } else {
                self?.viewModel.doCreateTaskList(with: text, tracker: completion, userResponse: { [weak self] res in
                    self?.handleUserRes(res)
                })
            }
        }
        let fromVC = from ?? self
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: fromVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    func showOrganizableActionSheet(sourceView: UIView) {
        guard case .custom(let cotegory) = context.store.state.sideBarItem, case .taskLists(let tab, let isArchived) = cotegory else {
            return
        }
        let actionSheet = getActionSheet(with: sourceView)
        actionSheet.addDefaultItem(text: I18N.Todo_CreateNewList_Title) { [weak self] in
            self?.showCreateTaskList(completion: { container in
                OrganizableTasklist.Track.clickFinalCreate(guid: container.guid)
             })
        }
        let text = isArchived ? I18N.Todo_TaskListPage_NotArchived_Option : I18N.Todo_TaskListPage_Archived_Option
        actionSheet.addDefaultItem(text: text) { [weak self] in
            if !isArchived {
                OrganizableTasklist.Track.clickArchived(tab: tab)
            }
            self?.context.store.dispatch(.changeContainer(.custom(.taskLists(tab: tab, isArchived: !isArchived))))
        }
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true, completion: nil)
    }

    private func getActionSheet(with sourceView: UIView) -> UDActionSheet {
        let source = UDActionSheetSource(
            sourceView: sourceView,
            sourceRect: CGRect(
                x: sourceView.frame.width / 2,
                y: sourceView.frame.height / 2 + 2,
                width: 0, height: 0
            ),
            arrowDirection: .unknown
        )
        let config = UDActionSheetUIConfig(popSource: source)
        return UDActionSheet(config: config)
    }

    private func handleUserRes(_ res: UserResponse<String?>) {
        switch res {
        case .success: break
        case .failure(let err):
            Utils.Toast.showWarning(with: err.message, on: self.view)
        }
    }
}

private class DialogCustomView: UIView {
    private(set) var isSelected: Bool = false {
        didSet {
            guard isSelected != oldValue else { return }
            checkBox.isSelected = isSelected
        }
    }

    private lazy var titleLabel = initTitleLabel()
    private lazy var containerView = UIView()
    private lazy var checkBox = initCheckBox()
    private lazy var checkBoxLabel = initCheckBoxLabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(containerView)
        containerView.addSubview(checkBox)
        containerView.addSubview(checkBoxLabel)

        checkBox.isUserInteractionEnabled = false
        titleLabel.isUserInteractionEnabled = false

        titleLabel.snp.makeConstraints {
            $0.top.left.right.equalToSuperview()
        }

        containerView.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.height.greaterThanOrEqualTo(20)
        }
        checkBox.snp.makeConstraints {
            $0.top.left.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        checkBoxLabel.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview()
            $0.left.equalTo(checkBox.snp.right).offset(12)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onSeleted))
        containerView.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = I18N.Todo_List_DeleteList_Desc
        label.numberOfLines = 0
        return label
    }

    private func initCheckBox() -> UDCheckBox {
        let config = UDCheckBoxUIConfig(style: .circle)
        let checkBox = UDCheckBox(boxType: .single, config: config)
        checkBox.isEnabled = true
        return checkBox
    }

    private func initCheckBoxLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        label.text = I18N.Todo_List_DeleteListUnassignedTasks_Checkbox
        label.numberOfLines = 0
        return label
    }

    @objc
    private func onSeleted() {
        isSelected = !isSelected
    }
}
