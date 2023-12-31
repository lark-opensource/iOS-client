//
//  DetailSubTaskModule.swift
//  Todo
//
//  Created by baiyantao on 2022/7/25.
//

import Foundation
import RxSwift
import RxCocoa
import EENavigator
import LarkUIKit
import TodoInterface
import LarkContainer
import UniverseDesignActionPanel
import UIKit
import LarkSwipeCellKit

// nolint: magic number
final class DetailSubTaskModule: DetailBaseModule, HasViewModel {

    let viewModel: DetailSubTaskViewModel
    @ScopedInjectedLazy private var routeDependency: RouteDependency?
    private let disposeBag = DisposeBag()

    private lazy var rootView = getRootView()
    private var contentView: DetailSubTaskContentView { rootView.contentView }
    private var emptyView: DetailEmptyView { rootView.emptyView }
    private var skeletonView: DetailSubTaskSkeletonView { rootView.skeletonView }
    private var tableView: UITableView { rootView.contentView.tableView }
    private var headerView: DetailSubTaskHeaderView { rootView.contentView.headerView }
    private var footerView: DetailSubTaskFooterView { rootView.contentView.footerView }

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = DetailSubTaskViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        viewModel.setup()
        bindViewData()
        bindViewAction()
        bindBusEvent()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func bindBusEvent() {
        context.bus.subscribe { [weak self] action in
            switch action {
            case .batchAddSubtasks(let ids):
                guard let self = self else { return }
                if !Display.pad || !self.viewModel.store.state.scene.isForSubTaskCreating {
                    self.viewModel.doBatchAddOwner(with: ids)
                }
            default:
                break
            }
        }.disposed(by: disposeBag)
    }

    private func getRootView() -> DetailSubTaskView {
        let view = DetailSubTaskView()
        view.contentView.tableView.delegate = self
        view.contentView.tableView.dataSource = self
        // ipad 上暂时不支持子任务里面在创建子任务
        view.isHidden = Display.pad && context.store.state.scene.isForSubTaskCreating
        return view
    }

    private func jumpToTimePicker(indexPath: IndexPath, components: TimeComponents?) {
        guard let containerVC = context.viewController else { return }
        let vm = TimePickerViewModel(resolver: userResolver, tuple: components)
        let vc = TimePickerViewController(resolver: userResolver, viewModel: vm)
        vc.saveHandler = { [weak self] comps in
            self?.viewModel.doUpdateTime(indexPath: indexPath, components: comps)
        }
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: containerVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    private func jumpToChatterPicker(indexPath: IndexPath) {
        guard let containerVC = context.viewController else { return }
        var routeParams = RouteParams(from: containerVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showOwnerPicker(
            title: I18N.Todo_TaskDetails_AddAnOwner_Button,
            chatId: viewModel.getChatId(),
            selectedChatterIds: [],
            supportbatchAdd: !FeatureGating(resolver: userResolver).boolValue(for: .multiAssignee),
            disableBatchAdd: false,
            batchHandler: { [weak self] fromVC in
                guard let self = self else { return }
                OwnerPicker.Track.multiSelectClick(with: self.viewModel.ancestorGuid ?? "", isEdit: self.viewModel.isEdit, isSubTask: true)
                self.showBatchOwnerPicker(fromVC, indexPath: indexPath, createSubTask: true)
            },
            selectedCallback: { [weak self] controller, chatterIds in
                controller?.dismiss(animated: true, completion: nil)
                guard let self = self, let chatterId = chatterIds.first else { return }
                self.viewModel.doAddOwners(indexPath: indexPath, with: [chatterId])
            },
            params: routeParams
        )
    }

    private func showBatchOwnerPicker(_ fromVC: UIViewController, indexPath: IndexPath, createSubTask: Bool) {
        guard let containerVC = context.viewController else { return }
        var routeParams = RouteParams(from: fromVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        let title = createSubTask ? I18N.Todo_MultiselectMembersToAssignTasks_Title : I18N.Todo_TaskDetails_AddAnOwner_Button
        routeDependency?.showChatterPicker(
            title: title,
            chatId: viewModel.getChatId(),
            isAssignee: true,
            selectedChatterIds: [],
            selectedCallback: { [weak self] controller, chatterIds in
                guard let self = self else { return }
                if createSubTask {
                    OwnerPicker.Track.confirmClick(with: self.viewModel.ancestorGuid ?? "", isEdit: self.viewModel.isEdit, isSubTask: true)
                    // 注意这里需要用最外层的控制去dismiss
                    containerVC.dismiss(animated: true)
                    self.viewModel.doBatchAddOwner(indexPath: indexPath, with: chatterIds)
                } else {
                    OwnerPicker.Track.finalAddClick(with: self.viewModel.ancestorGuid ?? "", isEdit: self.viewModel.isEdit, isSubTask: true)
                    controller?.dismiss(animated: true, completion: nil)
                    self.viewModel.doAddOwners(indexPath: indexPath, with: chatterIds)
                }
            },
            params: routeParams
        )
        OwnerPicker.Track.view(with: "", isSubTask: true, isEdit: viewModel.isEdit)
    }

    private func emptySummaryCheck(_ cell: DetailSubTaskContentCell) -> Bool {
        if cell.summaryView.textView.attributedText.string.isEmpty {
            if let view = context.tableView?.window {
                Utils.Toast.showWarning(with: I18N.Todo_PleaseEnterTaskTitle_Toast, on: view)
            }
            return false
        }
        return true
    }

    private func appendNewCellCheck() -> Bool {
        if let lastCell = tableView.cellForRow(at: .init(row: viewModel.numberOfItems() - 1, section: 0)),
           let cell = lastCell as? DetailSubTaskContentCell,
           cell.summaryView.textView.attributedText.string.isEmpty {
            cell.summaryView.textView.becomeFirstResponder()
            return false
        }
        return true
    }
}

// MARK: - View Data

extension DetailSubTaskModule {
    private func bindViewData() {
        viewModel.rxViewState.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                self.rootView.isHidden = false
                switch state {
                case .content, .failed:
                    self.rootView.iconAlignment = .topByOffset(16)
                    self.rootView.content = .customView(self.contentView)
                    // 新建页首次进入 contentview 需要弹起键盘
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if self.context.scene.isForCreating,
                           let cell = self.tableView.visibleCells.first as? DetailSubTaskContentCell,
                           cell.summaryView.textView.attributedText.string.isEmpty {
                            cell.summaryView.textView.becomeFirstResponder()
                        }
                    }
                case .idle:
                    self.rootView.iconAlignment = .centerVertically
                    self.emptyView.text = I18N.Todo_AddASubTask_Placeholder
                    self.rootView.content = .customView(self.emptyView)
                case .empty(let isAtMaxLeafLayer):
                    self.rootView.iconAlignment = .centerVertically
                    self.emptyView.text = isAtMaxLeafLayer ? I18N.Todo_Add5LevelsOfSubTasksAtMost_Text : I18N.Todo_AddASubTask_Placeholder
                    self.rootView.content = .customView(self.emptyView)
                case .loading:
                    self.rootView.iconAlignment = .topByOffset(16)
                    self.rootView.content = .customView(self.skeletonView)
                case .hidden:
                    self.rootView.isHidden = true
                }
            })
            .disposed(by: disposeBag)
        viewModel.reloadNoti
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            })
            .disposed(by: disposeBag)
        viewModel.rxHeaderData.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                self.headerView.viewData = data
                self.headerView.frame.size.height = data.headerHeight
                self.tableView.tableHeaderView = self.headerView
            })
            .disposed(by: disposeBag)
        viewModel.rxFooterData.skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] data in
                guard let self = self else { return }
                self.footerView.viewData = data
                self.footerView.frame.size.height = data.footerHeight
                self.tableView.tableFooterView = self.footerView
            })
            .disposed(by: disposeBag)
        viewModel.rxContentHeight
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] height in
                guard let self = self else { return }
                self.rootView.contentHeight = height
                self.rootView.invalidateIntrinsicContentSize()
            })
            .disposed(by: disposeBag)
        viewModel.insertRowHandler = { [weak self] index in
            guard let self = self else { return }

            guard self.viewModel.numberOfItems() == self.tableView.numberOfRows(inSection: 0) + 1 else {
                assertionFailure()
                return
            }
            // insert 时，先插入 cell，再转移键盘焦点
            UIView.setAnimationsEnabled(false)
            self.tableView.insertRows(at: [.init(row: index, section: 0)], with: .none)
            UIView.setAnimationsEnabled(true)
            self.rootView.contentHeight = self.viewModel.getContentHeight()
            self.rootView.invalidateIntrinsicContentSize()

            if let cell = self.tableView.cellForRow(at: .init(row: index, section: 0)),
               let contentCell = cell as? DetailSubTaskContentCell {
                contentCell.summaryView.textView.becomeFirstResponder()
            }
        }
    }
}

// MARK: - View Action

extension DetailSubTaskModule {
    private func bindViewAction() {
        footerView.showMoreClickHandler = { [weak self] in
            self?.viewModel.fetchNextPageSubTasks()
        }
        footerView.addSubTaskClickHandler = { [weak self] in
            guard let self = self else { return }
            if self.context.scene.isForCreating {
                let canAppend = self.appendNewCellCheck()
                if canAppend {
                    self.viewModel.doAppendNewCell()
                }
            } else {
                self.createSubTask()
            }
        }
        footerView.retryClickHandler = { [weak self] in
            self?.viewModel.doRetry()
        }
        emptyView.onTapHandler = { [weak self] in
            guard let self = self else { return }
            if self.context.scene.isForCreating {
                self.viewModel.doAppendNewCell()
            } else {
                self.createSubTask()
            }
        }
    }
}

// MARK: - UITableView

extension DetailSubTaskModule: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(DetailSubTaskContentCell.self, for: indexPath),
              let info = viewModel.cellInfo(indexPath: indexPath) else {
            assertionFailure()
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        cell.actionDelegate = self
        cell.delegate = self
        var controller = cell.cellInputController
        if controller == nil {
            controller = .init(resolver: userResolver, context: context, summaryView: cell.summaryView)
        }
        cell.summaryView.inputController = controller?.inputController
        cell.viewData = info
        if cell.cellInputController == nil {
            cell.cellInputController = controller
            cell.cellInputController?.setup()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let info = viewModel.cellInfo(indexPath: indexPath) else {
            assertionFailure()
            return .zero
        }
        return info.cellHeight
    }
}

// MARK: - Swipe Cell

extension DetailSubTaskModule: SwipeTableViewCellDelegate {

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        guard let action = viewModel.getSwipeAction(indexPath: indexPath) else { return nil }
        return action.map { makeAction(with: $0) }
    }

    static var deleteSwipeOptions: SwipeOptions?
    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        if orientation == .right, let swipeOptions = Self.deleteSwipeOptions {
            return swipeOptions
        }

        var options = SwipeOptions()
        options.minimumButtonWidth = 92
        options.buttonHorizontalPadding = 20
        options.buttonStyle = .horizontal
        options.buttonSpacing = 4
        options.backgroundColor = UIColor.ud.R400

        // 优化左右/上下滑动触发机制, 调整角度使横向手势触发概率变小；目前参数定制为拖拽角度小于 35 度触发
        options.shouldBegin = { (originX, originY) in
            return abs(originY) * 1.4 < abs(originX)
        }

        if orientation == .right {
            Self.deleteSwipeOptions = options
        }
        return options

    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) {

    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?, for orientation: SwipeActionsOrientation) {

    }

    func visibleRect(for tableView: UITableView) -> CGRect? {
         tableView.bounds
     }

    /// 删除
    private func makeDeleteAction() -> SwipeAction {
        let action = SwipeAction(
            style: .destructive,
            title: nil
        ) { [weak self] (_, indexPath, _) in
            self?.viewModel.doSwipeDeleteCell(indexPath: indexPath) { [weak self] res in
                guard let self = self else { return }
                switch res {
                case .success:
                    if let view = self.context.tableView?.window {
                        Utils.Toast.showWarning(with: I18N.Todo_common_DeletedSuccessfully, on: view)
                    }
                case .failure(let userErr):
                    if let view = self.context.tableView?.window {
                        Utils.Toast.showWarning(with: userErr.message, on: view)
                    }
                }
            }
        }
        configure(action: action, with: .delete)
        return action
    }

    private func makeAction(with descriptor: V3SwipeActionDescriptor) -> SwipeAction {
        switch descriptor {
        case .delete: return makeDeleteAction()
        default: return SwipeAction(style: .default, title: nil, handler: nil)
        }
    }

    private func configure(action: SwipeAction, with descriptor: V3SwipeActionDescriptor) {
        action.title = descriptor.title
        action.image = descriptor.image.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        action.textColor = UIColor.ud.primaryOnPrimaryFill
        action.backgroundColor = descriptor.backgroundColor
        action.font = descriptor.font
        action.hidesWhenSelected = true
    }

}

// MARK: - Cell Action

extension DetailSubTaskModule: DetailSubTaskContentCellDelegate {

    private func showMemeberList(_ indexPath: IndexPath) {
        guard let input = viewModel.memberListInput(indexPath: indexPath), let fromVC = context.viewController else { return }
        let vm = MemberListViewModel(resolver: userResolver, input: input, dependency: viewModel)
        let vc = MemberListViewController(resolver: userResolver, viewModel: vm)
        vc.onNeedsExit = { [weak vc] in
            let theVC = vc?.navigationController ?? vc
            theVC?.dismiss(animated: true)
        }
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: fromVC,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }


    func onCheckboxClick(_ cell: DetailSubTaskContentCell, _ cellData: DetailSubTaskContentCellData?) {
        guard tableView.indexPath(for: cell) != nil, let cellIndex = viewModel.indexPath(from: cellData) else {
            return
        }
        viewModel.doToggleComplete(indexPath: cellIndex) { [weak self] res in
            guard let self = self else { return }
            switch res {
            case .success(let toast):
                if let toast = toast, let view = self.context.tableView?.window {
                    Utils.Toast.showSuccess(with: toast, on: view)
                }
            case .failure(let userErr):
                if let view = self.context.tableView?.window {
                    Utils.Toast.showWarning(with: Rust.displayMessage(from: userErr), on: view)
                }
            }
        }
    }

    func onAddTimeBtnClick(_ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell) else {
            return
        }
        let canContinue = emptySummaryCheck(cell)
        guard canContinue else { return }

        jumpToTimePicker(indexPath: cellIndex, components: nil)
    }

    func onAddOwnerBtnClick(_ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell) else {
            return
        }
        let canContinue = emptySummaryCheck(cell)
        guard canContinue, let containerVC = context.viewController else { return }
        if FeatureGating(resolver: userResolver).boolValue(for: .multiAssignee) {
            showBatchOwnerPicker(containerVC, indexPath: cellIndex, createSubTask: false)
        } else {
            jumpToChatterPicker(indexPath: cellIndex)
        }
    }

    func onOwnerAvatarClick(_ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell),
              let containerVC = context.viewController else {
            return
        }
        let canContinue = emptySummaryCheck(cell)
        guard canContinue else { return }

        if FeatureGating(resolver: userResolver).boolValue(for: .multiAssignee) {
            showMemeberList(cellIndex)
        } else {
            let avatarView = cell.ownerAvatarView
            let source = UDActionSheetSource(
                sourceView: avatarView,
                sourceRect: CGRect(x: 0, y: avatarView.frame.height / 2, width: 0, height: 0),
                arrowDirection: .unknown
            )
            let actionSheet = UDActionSheet(config: UDActionSheetUIConfig(popSource: source))
            actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
            actionSheet.addItem(.init(
                title: I18N.Todo_ViewProfilePage_Button,
                titleColor: UIColor.ud.textTitle,
                action: { [weak self] in
                    guard let self = self,
                          let chatterId = cell.viewData?.assignees.first?.asUser()?.chatterId else {
                        return
                    }
                    var routeParams = RouteParams(from: containerVC)
                    routeParams.openType = .push
                    self.routeDependency?.showProfile(with: chatterId, params: routeParams)
                })
            )
            actionSheet.addItem(.init(
                title: I18N.Todo_SelectAnotherOwner_Button,
                titleColor: UIColor.ud.textTitle,
                action: { [weak self] in
                    guard let self = self else { return }
                    if FeatureGating(resolver: self.userResolver).boolValue(for: .multiAssignee),
                        let controller = self.context.viewController {
                        self.showBatchOwnerPicker(controller, indexPath: cellIndex, createSubTask: false)
                    } else {
                        self.jumpToChatterPicker(indexPath: cellIndex)
                    }
                })
            )
            actionSheet.addItem(.init(
                title: I18N.Todo_RemoveOwner_Button,
                titleColor: UIColor.ud.textTitle,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.viewModel.doClearOwner(indexPath: cellIndex)
                })
            )
            containerVC.present(actionSheet, animated: true)
        }
    }

    func onTimeClearBtnClick(_ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell) else {
            return
        }
        let canContinue = emptySummaryCheck(cell)
        guard canContinue else { return }

        viewModel.doClearTime(indexPath: cellIndex)
    }

    func onTimeDetailClick(_ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell),
              let timeComponents = cell.viewData?.timeComponents else {
            return
        }
        let canContinue = emptySummaryCheck(cell)
        guard canContinue else { return }

        jumpToTimePicker(indexPath: cellIndex, components: timeComponents)
    }

    func onDetailClick(_ cell: DetailSubTaskContentCell) {
        guard let guid = cell.viewData?.todo?.guid, !guid.isEmpty,
              let containerVC = context.viewController else {
            return
        }
        Detail.Track.clickSubTask(with: guid)
        let detailVC = DetailViewController(resolver: userResolver, input: .edit(guid: guid, source: .subTasks, callbacks: .init()))
        userResolver.navigator.push(detailVC, from: containerVC)
    }

    func onSummaryUpdate(content: Rust.RichContent, _ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell) else {
            return
        }
        viewModel.doUpdateSummary(indexPath: cellIndex, content: content)
    }

    func onReturnClick(_ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell) else {
            return
        }
        viewModel.doInsertNewCell(indexPath: cellIndex)
    }

    func onEmptyBackspaceClick(_ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell) else {
            return
        }
        // 直接转移键盘焦点即可，summary 为空的 cell 在失去键盘焦点时会被删除
        if let cell = self.tableView.cellForRow(at: .init(row: cellIndex.row, section: 0)),
           let contentCell = cell as? DetailSubTaskContentCell {
            contentCell.summaryView.textView.resignFirstResponder()
        }
        if let cell = self.tableView.cellForRow(at: .init(row: cellIndex.row - 1, section: 0)),
           let contentCell = cell as? DetailSubTaskContentCell {
            contentCell.summaryView.textView.becomeFirstResponder()
        }
    }

    func onBeginEditing(_ cell: DetailSubTaskContentCell) {
        if let globalFrame = context.tableView?.convert(cell.frame, from: tableView) {
            context.tableView?.scrollRectToVisible(globalFrame, animated: false)
        }
    }

    func onEmptyEndEditing(_ cell: DetailSubTaskContentCell) {
        guard let cellIndex = tableView.indexPath(for: cell) else {
            return
        }
        viewModel.doDeleteEmptyCell(indexPath: cellIndex)
        guard viewModel.numberOfItems() == tableView.numberOfRows(inSection: 0) - 1 else {
            assertionFailure()
            return
        }
        UIView.setAnimationsEnabled(false)
        tableView.deleteRows(at: [cellIndex], with: .none)
        UIView.setAnimationsEnabled(true)
        rootView.contentHeight = self.viewModel.getContentHeight()
        rootView.invalidateIntrinsicContentSize()
    }
}

// MARK: - Inline Create

extension DetailSubTaskModule {

    private func createSubTask() {
        guard !viewModel.isAtMaxLeafLayer else { return }
        guard viewModel.hasEditRight else {
            showNoEditToast()
            return
        }
        guard let ancestorGuid = viewModel.ancestorGuid, let from = context.viewController else {
            assertionFailure()
            return
        }
        // 强制关闭键盘
        from.view.endEditing(true)
        DetailSubTask.logger.info("will create subtask, ancestorId: \(ancestorGuid)")
        let source = TodoCreateSource.subTask(ancestorGuid: ancestorGuid, ancestorIsSubTask: viewModel.isSubTask, chatId: viewModel.chatId)
        let detailVC: UIViewController
        let presentationStyle: UIModalPresentationStyle
        let animated: Bool
        if Display.pad {
            detailVC = DetailViewController(resolver: userResolver, input: .create(source: source, callbacks: .init()))
            presentationStyle = .formSheet
            animated = true
        } else {
            detailVC = QuickCreateViewController(resolver: userResolver, source: source, callbacks: .init())
            if #available(iOS 13.0, *) {
                presentationStyle = .overCurrentContext
            } else {
                presentationStyle = .overFullScreen
            }
            animated = false
        }
        userResolver.navigator.present(
            detailVC,
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = presentationStyle },
            animated: animated
        )
    }

    private func showNoEditToast() {
        if let window = self.view.window {
            Utils.Toast.showWarning(with: I18N.Todo_Task_NoEditAccess, on: window)
        }
    }
}
