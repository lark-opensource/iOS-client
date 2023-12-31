//
//  V3ListViewController.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/25.
//

import Foundation
import RxSwift
import RxCocoa
import EENavigator
import UniverseDesignIcon
import TodoInterface
import LarkContainer
import LarkAlertController
import LarkUIKit
import UniverseDesignDialog
import EditTextView
import UIKit
import UniverseDesignActionPanel
import UniverseDesignNotice
import UniverseDesignFont

// MARK: Home - List

final class V3ListViewController: V3HomeModuleController {

    let viewModel: V3ListViewModel

    private lazy var noticeView: UDNotice = {
        var config = UDNoticeUIConfig(
            type: .info,
            attributedText: AttrText(string: "")
        )
        let notice = UDNotice(config: config)
        notice.delegate = self
        return notice
    }()
    private lazy var listView = V3ListView()
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var shareService: ShareService?
    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    required init(resolver: UserResolver, context: V3HomeModuleContext) {
        self.viewModel = V3ListViewModel(resolver: resolver, context: context)
        super.init(resolver: resolver, context: context)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
        bindViewState()
        bindStoreAction()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let container = context.store.state.container {
            V3Home.Track.viewList(with: container)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        listView.collectionView.collectionViewLayout.invalidateLayout()
        listView.collectionView.layoutIfNeeded()
        listView.collectionView.reloadData()
    }
}

// MARK: - Notice
extension V3ListViewController: UDNoticeDelegate {

    func handleLeadingButtonEvent(_ button: UIButton) {
        guard let window = view.window, let launchScreen = viewModel.launchScreen(), let url = launchScreen.buttonUrl else { return }
        userResolver.navigator.open(url, from: WindowTopMostFrom(window: window))
    }

    func handleTrailingButtonEvent(_ button: UIButton) {
        viewModel.closeNotice()
    }

    func handleTextButtonEvent(URL: URL, characterRange: NSRange) {
        // nothing
    }

    private func upadteNotice(_ launchScreen: Rust.ListLaunchScreen?) {
        if let launchScreen = launchScreen, launchScreen.shouldDisplay {
            var config = UDNoticeUIConfig(type: .info, attributedText: AttrText(string: launchScreen.text ?? ""))
            if launchScreen.enableExit {
                config.trailingButtonIcon = UDIcon.closeOutlined
            }
            if launchScreen.enableButton {
                config.leadingButtonText = launchScreen.buttonoText
            }
            noticeView.updateConfigAndRefreshUI(config)
            let size = noticeView.sizeThatFits(view.bounds.size)
            view.addSubview(noticeView)
            noticeView.snp.makeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(size.height)
            }
            listView.snp.remakeConstraints { make in
                make.top.equalTo(noticeView.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            noticeView.removeFromSuperview()
            listView.snp.remakeConstraints({ $0.edges.equalToSuperview() })
        }
    }
}

// MARK: - Set Up

extension V3ListViewController {

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(listView)
        listView.snp.makeConstraints({ $0.edges.equalToSuperview() })
        listView.actionDelegate = self
    }

    private func bindViewData() {
        viewModel.onListUpdate = { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .reload(let viewData):
                self.updateListView(by: viewData)
            case .resetOffset:
                // 切换筛选排序等重置offset，体验更好
                self.listView.collectionView.contentOffset = .zero
            case .showToast(let text):
                if let view = self.view.window {
                    Utils.Toast.showWarning(with: text, on: view)
                }
            }
        }
    }

    private func bindStoreAction() {
        context.bus.subscribe { [weak self] event in
            guard let self = self else { return }
            switch event {
            case .deselectTodo:
                self.listView.deselectedItem()
            case .showFilterDrawer, .willCreateTodo:
                self.viewModel.tryCleanMarkedTodo()
            case .didCreatedTodo(let res):
                // 需要取消选中，不然在Ipad会有选中和新建高亮两个色块
                self.viewModel.updateSelected("")
                self.viewModel.didCreatedTodo(res)
            default:
                break
            }
        }.disposed(by: disposeBag)
    }

    private func bindViewState() {
        viewModel.rxViewState.distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] state in
                    guard let self = self else { return }
                    self.listView.updateViewState(state: state, emptyText: I18N.Todo_NoTasks_EmptyStateText)
                })
            .disposed(by: disposeBag)
        viewModel.rxNotice.distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] launchScreen in
                    self?.upadteNotice(launchScreen)
                })
            .disposed(by: disposeBag)
    }

    private func updateListView(by viewData: V3ListViewData) {
        switch viewData.transition {
        case .reload:
            listView.reloadList(viewData.data, animated: false)
        case .animated:
            listView.reloadList(viewData.data, animated: true)
        }

        switch viewData.afterTransition {
        case .selectItem(let indexPath):
            listView.selectItem(at: indexPath)
        case .scrollToItem(let indexPath):
            listView.scrollToItem(at: indexPath)
        default: break
        }
    }
}

// MARK: - List View Delegate

extension V3ListViewController: V3ListViewActionDelegate {

    func getSwipeDescriptor(at indexPath: IndexPath, guid: String) -> [V3SwipeActionDescriptor]? {
        return viewModel.getSwipeDescriptor(at: indexPath, with: guid)
    }

    func canDrag(at indexPath: IndexPath) -> Bool {
        let (canDrag, toast) = viewModel.checkCanDrag()
        if let toast = toast, let window = view.window {
            Utils.Toast.showWarning(with: toast, on: window)
        }
        return canDrag
    }

    func enabledAction(at indexPath: IndexPath, guid: String, isFromSlide: Bool) -> CheckboxEnabledAction {
        V3Home.logger.info("begin change completed status, guid: \(guid)")
        guard let todo = viewModel.cellData(at: indexPath, with: guid)?.todo else {
            V3Home.logger.info("complete status failed because cannot find todo")
            return .immediate { }
        }
        // ipad 情况下需求关闭详情页
        context.bus.post(.closeDetail(guid: todo.guid))
        let completion = { [weak self] in
            guard let self = self else { return }
            // 只要选中就取消高亮显示
            self.viewModel.tryCleanMarkedTodo()
        }
        /// 自定义完成
        if let customComplete = viewModel.getCustomComplete(from: todo) {
            return .needsAsk(
                ask: { [weak self] (_, onNo) in
                    guard let self = self else { return }
                    customComplete.doAction(on: self)
                    onNo()
                },
                completion: completion
            )
        }
        if let doubleCheck = viewModel.doubleCheckBeforeToggleCompleteState(from: todo) {
            return .needsAsk(
                ask: { [weak self] (onYes, onNo) in
                    guard let self = self else { return }
                    let dialog = UDDialog()
                    dialog.setTitle(text: doubleCheck.title)
                    dialog.setContent(text: doubleCheck.content)
                    dialog.addCancelButton(dismissCompletion: onNo)
                    dialog.addPrimaryButton(text: doubleCheck.confirm, dismissCompletion: onYes)
                    self.present(dialog, animated: true)
                },
                completion: { [weak self] in
                    guard let self = self else { return }
                    guard let indexPath = self.viewModel.indexPath(from: todo.guid) else {
                        V3Home.logger.info("user confirm to change completed, but todo is missing, id: \(todo.guid)")
                        return
                    }
                    guard
                        let cell = self.listView.collectionView.cellForItem(at: indexPath) as? V3ListCell,
                        case .content = cell.viewData?.contentType
                    else {
                        assertionFailure()
                        V3Home.assertionFailure("something is wrong")
                        return
                    }
                    self.handleActionResult(self.viewModel.toggleCompleteStatus(at: indexPath, with: guid, isFromSlide: isFromSlide))
                    completion()
                }
            )
        } else {
            return .immediate { [weak self] in
                guard let self = self else { return }
                self.handleActionResult(self.viewModel.toggleCompleteStatus(at: indexPath, with: guid, isFromSlide: isFromSlide))
                completion()
            }
        }
    }

    func doAction(by type: V3ListView.ActionType) {
        V3Home.logger.info("do action :\(type.logInfo)")
        switch type {
        case .prefetch:
            viewModel.loadMore()
        case .retryFetch:
            viewModel.retryFetch()
        case .headerMore(let indexPath, let sectionId, let sourceView):
            showCustomSection(in: indexPath.section, with: sectionId, from: sourceView)
        case .headerSelected(let indexPath, let sectionId):
            viewModel.foldSection(section: indexPath.section, sectionId: sectionId)
        case .footerSelected(let indexPath, let sectionId):
            viewModel.createTodo(in: indexPath.section, with: sectionId)
            V3Home.Track.clickListListAddTask(with: context.store.state.container)
        case .didSelectItem(let indexPath, let guid):
            didSelectedItem(at: indexPath, with: guid)
            V3Home.Track.clickListClickTask(with: context.store.state.container, guid: guid)
        case .swipeItem, .didSwipe:
            viewModel.tryCleanMarkedTodo()
        case .didSelectSwipeItem(let descriptor, let indexPath, let guid):
            switch descriptor {
            case .delete, .quit:
                handleActionResult(viewModel.doRightAction(at: indexPath, with: guid, action: descriptor))
                V3Home.Track.clickListLeaveTask(with: context.store.state.container, guid: guid)
            case .share:
                shareItem(at: indexPath, with: guid)
                V3Home.Track.clickListShare(with: context.store.state.container, guid: guid)
            case .complete, .uncomplete:
                switch enabledAction(at: indexPath, guid: guid, isFromSlide: true) {
                case .immediate(let completion): completion()
                case .needsAsk(let ask, let completion):
                    ask({
                            completion()
                        }, {
                            // nothing
                        }
                    )
                }
            case .dueTime:
                jumpToTimePicker(at: indexPath, with: guid)
                V3Home.Track.clickListSlideToEditDue(with: context.store.state.container, guid: guid)
            }
        case .moveItem(let from, let to, let preGuid, let todo, let nextGuid):
            viewModel.moveItem(from: from, to: to, preGuid: preGuid, todo: todo, nextGuid: nextGuid)
        }
    }

}

// MARK: - Action

extension V3ListViewController {

    private func showCustomSection(in section: Int, with sectionId: String, from view: UIView) {
        guard let(items, delete) = viewModel.sectionMoreItems(section: section, sectionId: sectionId) else {
            return
        }
        let source = UDActionSheetSource(
            sourceView: view,
            sourceRect: CGRect(x: view.frame.width - ListConfig.Section.horizontalPadding - ListConfig.Section.trailingIconSize.width / 2, y: view.frame.height / 2 + 4, width: 0, height: 0),
            arrowDirection: .unknown
        )
        let config = UDActionSheetUIConfig(popSource: source)
        let actionSheet = UDActionSheet(config: config)
        if let title = title {
            actionSheet.setTitle(title)
        }
        items.forEach { (key, value) in
            actionSheet.addItem(
                UDActionSheetItem(
                    title: value,
                    titleColor: UIColor.ud.textTitle,
                    action: { [weak self] in
                        if key == .reorder {
                            self?.showReorder(in: section, with: sectionId)
                        } else {
                            self?.showDialog(in: section, with: sectionId, action: key)
                        }
                    }
                )
            )
        }
        if let delete = delete {
            actionSheet.addItem(
                UDActionSheetItem(
                    title: delete,
                    titleColor: UIColor.ud.textTitle,
                    action: { [weak self] in
                        guard let self = self else { return }
                        self.showDeleteSectionDialog(in: section, with: sectionId)
                    }
                )
            )
        }
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true, completion: nil)
    }

    private func showDeleteSectionDialog(in section: Int, with sectionId: String) {
        let dialog = UDDialog(config: UDDialogUIConfig())
        dialog.setTitle(text: I18N.Todo_New_Section_DeleteSection_Button)
        dialog.setContent(text: I18N.Todo_SectionDeletedTasksReturnedToNoSection_Title)
        dialog.addCancelButton()
        dialog.addDestructiveButton(text: I18N.Todo_common_Delete, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.handleActionResult(self.viewModel.deleteSection(in: section, with: sectionId))
        })
        present(dialog, animated: true)
    }

    private func showReorder(in section: Int, with sectionId: String) {
        let vc = ListSectionReorderViewController(sections: listView.sectionModels) { [weak self] sectionModels in
            self?.listView.reloadList(sectionModels, animated: false)
        } cancel: { [weak self] sectionModels in
            self?.listView.reloadList(sectionModels, animated: false)
        } confirm: { [weak self] (new, old) in
            self?.viewModel.reorderSections(new, old)
        }
        // 这里不能用view.safeArea，因为在首页TabBar会有自己的安全区
        let viewControllerHeight: CGFloat = vc.height(bottomInset: view.window?.safeAreaInsets.bottom ?? 0)
        let actionPanel = UDActionPanel(
            customViewController: vc,
            config: UDActionPanelUIConfig(originY: max(UIScreen.main.bounds.height - viewControllerHeight, view?.window?.safeAreaInsets.top ?? 0))
        )
        present(actionPanel, animated: true)
    }

    private func showDialog(in section: Int, with sectionId: String, action: V3ListViewModel.SectionMoreAction) {
        guard let (title, text, placeholder) = viewModel.dialogContent(in: section, with: sectionId, action: action) else {
            return
        }
        PaddingTextField.showTextField(
            with: .init(text: text, title: title, placeholder: placeholder),
            from: self) { [weak self] textFiledText in
                guard let self = self else { return }
                V3Home.Track.clickListEditSection(with: self.context.store.state.container, type: action)
                self.handleActionResult(self.viewModel.upsertSection(
                    in: section,
                    with: sectionId,
                    action: action,
                    name: textFiledText
                ))
            }
    }

    private func didSelectedItem(at indexPath: IndexPath, with guid: String) {
        guard let cd = viewModel.cellData(at: indexPath, with: guid) else {
            V3Home.logger.info("show detail failed, because can't find cell data")
            return
        }
        guard !cd.todo.guid.isEmpty else { return }
        // for ipad
        if Display.pad {
            viewModel.updateSelected(cd.todo.guid)
        } else {
            listView.collectionView.deselectItem(at: indexPath, animated: false)
            viewModel.updateSelected(nil)
        }
        viewModel.tryCleanMarkedTodo()
        // 已完成或者来自清单都需要
        let needLoading = cd.completeState.isCompleted || viewModel.isTaskList
        context.bus.post(.showDetail(guid: cd.todo.guid, needLoading: needLoading, callbacks: TodoEditCallbacks()))
    }

    /// share
    private func shareItem(at indexPath: IndexPath, with guid: String) {
        guard let todo = viewModel.cellData(at: indexPath, with: guid)?.todo else { return }
        var shareBody = SelectSharingItemBody(summary: Utils.RichText.makePlainText(from: todo.richSummary))
        shareBody.onCancel = { V3Home.logger.info("sharing canceled") }
        shareBody.onConfirm = { [weak self] (items, message) in
            V3Home.logger.info("select sharing items: \(items.count), msg: \(message?.count ?? 0)")
            // 这里需要用view，iOS12上找不到window
            guard let self = self, let window = self.view else { return }
            let removable = Utils.Toast.showLoading(with: I18N.Todo_Task_Sharing, on: window)
            self.shareService?.shareToLark(
                withTodoId: todo.guid,
                items: items,
                type: .share,
                message: message
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(_, let blockAlert):
                    if let blockAlert = blockAlert {
                        if blockAlert.preferToast {
                            Utils.Toast.showError(with: blockAlert.message, on: window)
                        } else {
                            removable()
                            let alertVC = LarkAlertController()
                            alertVC.setTitle(text: I18N.Todo_Common_FailToSend)
                            alertVC.setContent(text: blockAlert.message)
                            alertVC.addPrimaryButton(text: I18N.Todo_Task_Confirm)
                            self.present(alertVC, animated: true)
                        }
                    } else {
                        Utils.Toast.showSuccess(with: I18N.Todo_Task_ShareSucTip, on: window)
                    }
                case .failure(let message):
                    Utils.Toast.showError(with: message, on: window)
                }
            }
        }
        var routeParams = RouteParams(from: self)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.openType = .present
        routeParams.wrap = LkNavigationController.self
        routeDependency?.selectSharingItem(with: shareBody, params: routeParams)
    }

    private func jumpToTimePicker(at indexPath: IndexPath, with guid: String) {
        guard let todo = viewModel.cellData(at: indexPath, with: guid)?.todo else { return }
        let timeComponents = TimeComponents(from: todo)
        let vm = TimePickerViewModel(resolver: userResolver, tuple: timeComponents)
        let vc = TimePickerViewController(resolver: userResolver, viewModel: vm)
        vc.saveHandler = { [weak self] comps in
            self?.viewModel.doUpdateTime(at: indexPath, with: guid, and: comps)
        }
        userResolver.navigator.present(
            vc,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    private func handleActionResult(_ actionResult: Single<ListActionResult>) {
        actionResult
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] result in
                guard let self = self, let window = self.view.window else { return }
                switch result {
                case .succeed(let toast):
                    guard let toast = toast else { return }
                    Utils.Toast.showSuccess(with: toast, on: window)
                case .failed(let toast):
                    guard let toast = toast else { return }
                    Utils.Toast.showError(with: toast, on: window)
                }
            }).disposed(by: disposeBag)
    }
}
