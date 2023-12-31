//
//  DetailTaskListModule.swift
//  Todo
//
//  Created by wangwanxin on 2022/12/23.
//

import Foundation
import CTFoundation
import EENavigator
import RxSwift
import RxCocoa
import LarkSwipeCellKit
import UniverseDesignActionPanel
import LarkContainer
import LarkUIKit

// nolint: magic number
final class DetailTaskListModule: DetailBaseModule, HasViewModel {
    let viewModel: DetailTaskListModel

    private lazy var rootView = getRootView()

    private let disposeBag = DisposeBag()

    override init(resolver: UserResolver, context: DetailModuleContext) {
        self.viewModel = ViewModel(resolver: resolver, store: context.store)
        super.init(resolver: resolver, context: context)
    }

    override func setup() {
        viewModel.setup()
        viewModel.onUpdate = { [weak self] type in
            guard let self = self else { return }
            switch type {
            case .reload(let isHiddenAdd):
                self.rootView.spaceView.frame.size.height = DetailTaskListView.headerHeight
                self.rootView.addView.frame.size.height = isHiddenAdd ? .zero : DetailTaskListView.footerHeight
                self.rootView.tableView.tableFooterView = isHiddenAdd ? UIView() : self.rootView.addView
                self.rootView.content = .customView(self.rootView.tableView)
                self.rootView.iconAlignment = .topByOffset(16)
                self.rootView.contentHeight = self.viewModel.getContentHeight(by: type)
                self.rootView.tableView.reloadData()
            case .failed, .idle:
                self.rootView.iconAlignment = .centerVertically
                self.rootView.contentHeight = self.viewModel.getContentHeight(by: type)
                self.rootView.content = .customView(self.rootView.emptyView)
            case .hidden:
                self.rootView.isHidden = true
            }
        }
        bindViewAction()
    }

    override func loadView() -> UIView {
        return rootView
    }

    private func getRootView() -> DetailTaskListView {
        let view = DetailTaskListView()
        view.tableView.delegate = self
        view.tableView.dataSource = self
        return view
    }

    private func bindViewAction() {
        rootView.addView.onTapAddHandler = { [weak self] in
            self?.showPicker(with: nil)
        }
        rootView.emptyView.onTapHandler = { [weak self] in
            guard let self = self else { return }
            if !self.viewModel.isEditable {
                self.showNoEditToast(I18N.Todo_Task_NoEditAccess)
                return
            }
            self.showPicker(with: nil)
        }
    }

    private func showNoEditToast(_ toast: String) {
        if let window = view.window {
            Utils.Toast.showWarning(with: toast, on: window)
        }
    }

}

// MARK: - Action

extension DetailTaskListModule {

    private func showPicker(with taskListGuid: String?) {
        guard let from = context.viewController else { return }
        // 强制收起键盘
        from.view.endEditing(true)
        var scene: DetailTaskListPickerViewModel.TaskListPickerScene = .taskList(context.store.state.relatedTaskLists)
        if let taskListGuid = taskListGuid,
           let taskList = viewModel.taskList(by: taskListGuid),
           let sectionRef = viewModel.sectionRef(by: taskListGuid) {
            if taskList.canEdit {
                scene = .sectionRefs([taskList], [taskListGuid: sectionRef])
            } else {
                showNoEditToast(I18N.Todo_TaskList_TaskCardNoPermissionToEdit_Hover)
                return
            }
        }
        let viewModel = DetailTaskListPickerViewModel(resolver: userResolver, scene: scene)
        let vc = DetailTaskListPickerViewController(with: viewModel)
        vc.didSelectedHandler = { [weak self] pickerResult in
            guard let self = self else { return }
            self.viewModel.handlePickerResult(pickerResult)
        }
        vc.addTaskListHandler = { [weak self] res in
            guard let self = self else { return }
            self.viewModel.handleCreateRes(res)
        }
        from.present(vc, animated: true)
    }

    private func showTaskList(with taskListGuid: String) {
        guard let from = context.viewController else { return }
        Detail.logger.info("did tap taskList, guid: \(taskListGuid)")
        Detail.Track.clickTaskListDetail(with: context.store.state.todo?.guid)
        let vc = V3HomeViewController(resolver: userResolver, scene: .onePage(guid: taskListGuid))
        userResolver.navigator.push(vc, from: from)
    }

}
// MARK: - TableVeiw

extension DetailTaskListModule: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.ctf.dequeueReusableCell(DetailTaskListContentCell.self, for: indexPath),
              let cellData = viewModel.cellData(indexPath: indexPath) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        cell.viewData = cellData
        cell.delegate = self
        cell.onTapLeftHandler = { [weak self] in
            self?.showTaskList(with: cellData.taskListGuid)
        }
        cell.onTapRightHandler = { [weak self] in
            self?.showPicker(with: cellData.taskListGuid)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return DetailTaskListContentCell.sectionFooterHeight
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.ctf.dequeueReusableFooterView(DetailTaskListContentFooterView.self) else {
            return DetailTaskListContentFooterView()
        }
        return footer
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DetailTaskListContentCell.cellHeight
    }
}

// MARK: - Swipe Cell

extension DetailTaskListModule: SwipeTableViewCellDelegate {

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        guard let action = viewModel.getSwipeAction(indexPath) else { return nil }
        return action.map { makeAction(with: $0) }
    }

    func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
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
        return options

    }

    /// 删除
    private func makeDeleteAction() -> SwipeAction {
        let action = SwipeAction(
            style: .destructive,
            title: nil
        ) { [weak self] (_, indexPath, _) in
            self?.viewModel.deleteTaskList(by: indexPath)
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
