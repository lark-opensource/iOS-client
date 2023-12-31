//
//  GroupedAssigneeViewController.swift
//  Todo
//
//  Created by 张威 on 2021/8/16.
//

import LarkUIKit
import EENavigator
import RxSwift
import LarkContainer
import TodoInterface
import SnapKit
import UniverseDesignEmpty
import UniverseDesignActionPanel
import UniverseDesignFont
import UniverseDesignDialog

/// 分组的执行人列表页

class GroupedAssigneeViewController: BaseViewController, HasViewModel, UserResolverWrapper, UITableViewDataSource, UITableViewDelegate {

    /// 退出原因
    enum ExitReason {
        case removeSelf
        case complete
        case close
    }

    /// 需要退出
    var onNeedsExit: ((ExitReason) -> Void)?
    var userResolver: LarkContainer.UserResolver
    let viewModel: GroupedAssigneeViewModel

    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    private lazy var headerView = DetailAssingeeHeaderView()
    private lazy var segmentView = initSegmentView()
    private lazy var listViews = (uncompleted: initListView(), completed: initListView())
    private lazy var emptyViews = (uncompleted: initEmptyView(false), completed: initEmptyView(true))
    private lazy var footerView = SettingSubTitleCell()
    private lazy var separateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    init(resolver: UserResolver, viewModel: ViewModel) {
        self.userResolver = resolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        updateSegmentTitle()
        viewModel.onListDataUpdate = { [weak self] type in
            self?.reloadListData(for: type)
            self?.updateHeaderTitle()
            self?.updateSegmentTitle()
            self?.updateFooterTitle()
        }
        viewModel.onNeedsCompleteExit = { [weak self] in
            self?.onNeedsExit?(.complete)
        }
        viewModel.setup()
    }

    override func backItemTapped() {
        viewModel.trackGoBack()
        super.backItemTapped()
    }

    private func initSegmentView() -> SegmentView {
        let segment = StandardSegment()
        segment.backgroundColor = UIColor.ud.bgBody
        segment.height = 40
        segment.lineStyle = .adjust
        segment.titleFont = UDFont.systemFont(ofSize: 14)
        segment.titleNormalColor = UIColor.ud.N600
        return SegmentView(segment: segment)
    }

    private func initListView() -> UITableView {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = .init(top: 0, left: 68, bottom: 0, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.ctf.register(cellType: GroupedAssigneeListCell.self)
        return tableView
    }

    private func initEmptyView(_ isCompleted: Bool) -> UIView {
        let title = isCompleted
            ? I18N.Todo_AssigneePage_NoAssigneesCompletedTask_EmptyState
            : I18N.Todo_AssigneePage_AllAssigneesHaveComleted_EmptyState
        let description = UDEmptyConfig.Description(
            descriptionText: NSAttributedString(
                string: title,
                attributes: [
                    .font: UDFont.body2,
                    .foregroundColor: UIColor.ud.textCaption
                ])
        )
        let empty = UDEmptyView(config: UDEmptyConfig(
            description: description,
            type: .defaultPage
        ))
        empty.useCenterConstraints = true
        return empty
    }

    private func setupView() {
        let fg = FeatureGating(resolver: userResolver).boolValue(for: .multiAssignee)
        view.backgroundColor = UIColor.ud.bgBody

        let segmentItemViews = (uncompleted: UIView(), completed: UIView())

        segmentItemViews.uncompleted.addSubview(listViews.uncompleted)
        listViews.uncompleted.snp.makeConstraints { $0.edges.equalToSuperview() }

        segmentItemViews.uncompleted.addSubview(emptyViews.uncompleted)
        emptyViews.uncompleted.snp.makeConstraints { $0.edges.equalToSuperview() }

        segmentItemViews.completed.addSubview(listViews.completed)
        listViews.completed.snp.makeConstraints { $0.edges.equalToSuperview() }

        segmentItemViews.completed.addSubview(emptyViews.completed)
        emptyViews.completed.snp.makeConstraints { $0.edges.equalToSuperview() }

        segmentView.set(
            views: [
                (I18N.Todo_CollabTask_IncompleteTitleNum(0), segmentItemViews.uncompleted),
                (I18N.Todo_CollabTask_CompletedTitleNum(0), segmentItemViews.completed)
            ]
        )
        view.addSubview(segmentView)

        if fg {
            view.addSubview(headerView)

            headerView.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
            }
            headerView.enableClickBtn = viewModel.enableAddAssignee
            headerView.onAddHandler = { [weak self] in
                guard let self = self else {
                    return
                }
                self.jumpToAddAssignee()
            }

            if viewModel.modeEditable {
                view.addSubview(separateLine)
                view.addSubview(footerView)
                segmentView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(headerView.snp.bottom)
                }
                let lintHeight = CGFloat(1.0 / UIScreen.main.scale)
                separateLine.snp.makeConstraints { make in
                    make.height.equalTo(lintHeight)
                    make.bottom.equalTo(segmentView.snp.bottom)
                    make.left.right.equalToSuperview()
                }
                footerView.snp.makeConstraints { make in
                    make.top.equalTo(segmentView.snp.bottom).offset(8)
                    make.left.equalToSuperview()
                    make.right.equalToSuperview()
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
                }

                footerView.setup(
                    title: viewModel.mode.pickerTitle,
                    description: nil,
                    subTitle: "") { [weak self] in
                        self?.showTaskMode()
                }
            } else {
                segmentView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(headerView.snp.bottom)
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                }
            }
        } else {
            setupNaviItem()
            segmentView.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
        }

        addCloseItem()
    }


    override func closeBtnTapped() {
        dismiss(animated: true, completion: nil)
        onNeedsExit?(.close)
    }

    private func setupNaviItem() {
        title = I18N.Todo_New_Owner_Text

        guard viewModel.enableAddAssignee else { return }
        let barItem = LKBarButtonItem(image: nil, title: I18N.Todo_common_Add, fontStyle: .medium)
        barItem.button.tintColor = UIColor.ud.primaryContentDefault
        barItem.button.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self ] _ in self?.jumpToAddAssignee() })
            .disposed(by: disposeBag)
        navigationItem.setRightBarButton(barItem, animated: false)
    }

    private func showTaskMode() {
        let source = UDActionSheetSource(
            sourceView: footerView,
            sourceRect: CGRect(
                x: footerView.frame.width / 2,
                y: footerView.frame.height / 2,
                width: 0,
                height: 0
            ),
            preferredContentWidth: Utils.Pop.preferredContentWidth,
            arrowDirection: .unknown
        )
        let color = { [weak self] (mode: Rust.TaskMode) -> UIColor in
            if self?.viewModel.mode == mode {
                return UIColor.ud.primaryContentDefault
            }
            return UIColor.ud.textTitle
        }
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source))
        actionSheet.addItem(UDActionSheetItem(
            title: Rust.TaskMode.taskComplete.pickerTitle,
            titleColor: color(.taskComplete),
            action: { [weak self] in
                self?.showChangeModeConfirm(.taskComplete)
        }))
        actionSheet.addItem(UDActionSheetItem(
            title: Rust.TaskMode.userComplete.pickerTitle,
            titleColor: color(.userComplete),
            action: { [weak self] in
                self?.showChangeModeConfirm(.userComplete)
        }))
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true)
    }

    private func showChangeModeConfirm(_ newMode: Rust.TaskMode) {
        // 选中上次选中的，直接退出
        guard viewModel.mode != newMode else {
            closeBtnTapped()
            return
        }

        let action = { [weak self] in
            self?.viewModel.changeTaskMode(newMode)
            self?.closeBtnTapped()
        }
        let completedCount = viewModel.numberOfRows(in: 0, for: .completed)
        let uncompletedCount = viewModel.numberOfRows(in: 0, for: .uncompleted)
        if newMode == .taskComplete, uncompletedCount > 0, completedCount > 0 {
            let dialog = UDDialog()
            dialog.setTitle(text: I18N.Todo_MultiOwners_SwithToRequireAnyonePopover_Title)
            dialog.addCancelButton()
            dialog.addPrimaryButton(text: I18N.Todo_MultiOwners_SwithToRequireAnyonePopover_Save_Button, dismissCompletion: action)
            present(dialog, animated: true)
        } else {
            action()
        }
    }

    @objc
    private func jumpToAddAssignee() {
        var routeParams = RouteParams(from: self)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        let context = viewModel.pickChattersContext()
        routeDependency?.showChatterPicker(
            title: I18N.Todo_AddCollaborator_Tooltip,
            chatId: context.chatId,
            isAssignee: true,
            selectedChatterIds: context.selectedChatterIds,
            selectedCallback: { [weak self] controller, chatterIds in
                Detail.logger.info("add  do get todoUsers count:\(chatterIds.count)")
                controller?.dismiss(animated: true)
                guard let self = self else { return }
                self.viewModel.trackPickChatters(chatterIds)
                self.viewModel.addAssignees(by: chatterIds, completion: self.makeActionCompletion())
            },
            params: routeParams
        )
    }

    private func reloadListData(for type: ViewModel.ListType) {
        switch type {
        case .completed:
            listViews.completed.reloadData()
            let hasCompletedData = viewModel.numberOfRows(in: 0, for: .completed) > 0
            emptyViews.completed.isHidden = hasCompletedData
            listViews.completed.isHidden = !hasCompletedData
        case .uncompleted:
            listViews.uncompleted.reloadData()
            let hasUncompletedData = viewModel.numberOfRows(in: 0, for: .uncompleted) > 0
            emptyViews.uncompleted.isHidden = hasUncompletedData
            listViews.uncompleted.isHidden = !hasUncompletedData
        }
    }

    private func updateSegmentTitle() {
        let title0 = I18N.Todo_CollabTask_IncompleteTitleNum(viewModel.numberOfRows(in: 0, for: .uncompleted))
        let title1 = I18N.Todo_CollabTask_CompletedTitleNum(viewModel.numberOfRows(in: 0, for: .completed))
        segmentView.segment.updateItem(title: title0, index: 0)
        segmentView.segment.updateItem(title: title1, index: 1)
    }

    private func updateFooterTitle() {
        footerView.updateTitle(title: viewModel.mode.pickerTitle)
    }

    private func updateHeaderTitle() {
        let uncompletedCount = viewModel.numberOfRows(in: 0, for: .uncompleted)
        let completedCount = viewModel.numberOfRows(in: 0, for: .completed)
        let totalCount = uncompletedCount + completedCount
        if totalCount > 0 {
            headerView.title = "\(I18N.Todo_New_Owner_Text)(\(totalCount))"
        } else {
            headerView.title = I18N.Todo_New_Owner_Text
        }
    }

    private func listType(for tableView: UITableView) -> ViewModel.ListType {
        return tableView == listViews.completed ? .completed : .uncompleted
    }

    // MARK: Cell Action

    private func makeActionCompletion(onSuccess: (() -> Void)? = nil) -> ViewModel.UserActionCompletion {
        return { [weak self] res in
            switch res {
            case .success:
                onSuccess?()
            case .failure(let userErr):
                if let self = self {
                    Utils.Toast.showError(with: userErr.message, on: self.view)
                }
            }
        }
    }

    private func handleMoreClick(at indexPath: IndexPath, in tableView: UITableView) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let source = UDActionSheetSource(
            sourceView: cell.contentView,
            sourceRect: CGRect(
                x: cell.contentView.frame.width - 48,
                y: cell.contentView.frame.height / 2,
                width: 0,
                height: 0
            ),
            arrowDirection: .unknown
        )
        let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source))
        let listType = listType(for: tableView)
        for item in viewModel.moreActionItems(at: indexPath, for: listType) {
            actionSheet.addItem(UDActionSheetItem(title: item.action.title, action: { [weak self] in
                guard let self = self else { return }
                switch item.action {
                case .markAsCompleted, .markAsInProgress:
                    if let customComplete = self.viewModel.customComplete(at: indexPath, for: listType) {
                        customComplete.doAction(on: self)
                    } else {
                        self.viewModel.toggleCompleteState(at: indexPath, for: listType)
                    }
                case .removeAssignee:
                    if self.viewModel.needsAlertBeforeRemoveAssignee(at: indexPath, for: listType) {
                        self.showRemoveAssigneeAlert(sender: cell) { [weak self] in
                            guard let self = self else { return }
                            let completion = self.makeActionCompletion { [weak self] in
                                self?.onNeedsExit?(.removeSelf)
                            }
                            self.viewModel.removeItem(at: indexPath, for: listType, completion: completion)
                        }
                    } else {
                        self.viewModel.removeItem(at: indexPath, for: listType, completion: self.makeActionCompletion())
                    }
                }
            }))
        }
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true)
    }

    private func showRemoveAssigneeAlert(sender: UITableViewCell, confirm: @escaping () -> Void) {
        let source = UDActionSheetSource(
            sourceView: sender.contentView,
            sourceRect: CGRect(
                x: sender.contentView.frame.width - 48,
                y: sender.contentView.frame.height / 2,
                width: 0,
                height: 0
            ),
            arrowDirection: .unknown
        )
        let config = UDActionSheetUIConfig(titleColor: UIColor.ud.textPlaceholder, isShowTitle: true, popSource: source)
        let actionSheet = UDActionSheet(config: config)
        actionSheet.setTitle(I18N.Todo_Task_RemoveOneselfFromAssigneesDialogContent)
        actionSheet.addItem(
            UDActionSheetItem(
                title: I18N.Todo_Task_RemoveOneselfFromAssigneesRemoveButton,
                titleColor: UIColor.ud.textTitle,
                action: confirm
            )
        )
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true)
    }

    // MARK: TableView

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections(for: listType(for: tableView))
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section, for: listType(for: tableView))
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cellData = viewModel.cellData(at: indexPath, for: listType(for: tableView)),
            let cell = tableView.ctf.dequeueReusableCell(GroupedAssigneeListCell.self, for: indexPath)
        else {
            return .init()
        }
        cell.viewData = cellData
        cell.onMoreClick = { [weak self, weak tableView] in
            guard let self = self, let tableView = tableView else { return }
            self.handleMoreClick(at: indexPath, in: tableView)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(66)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: false)
        guard
            let assignee = viewModel.assignee(at: indexPath, for: listType(for: tableView)),
            case .user(let user) = assignee.asMember()
        else {
            return
        }

        var routeParams = RouteParams(from: self)
        if Display.pad {
            routeParams.openType = .present
            routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
            routeParams.wrap = LkNavigationController.self
        } else {
            routeParams.openType = .push
        }
        routeDependency?.showProfile(with: user.chatterId, params: routeParams)

        Detail.logger.info("will jump to profile. chatterId: \(user.chatterId)")
    }

}
