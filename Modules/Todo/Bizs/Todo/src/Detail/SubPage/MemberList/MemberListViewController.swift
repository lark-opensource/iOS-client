//
//  MemberListViewController.swift
//  Todo
//
//  Created by 张威 on 2021/9/12.
//

import LarkUIKit
import EENavigator
import RxSwift
import LarkContainer
import TodoInterface
import CTFoundation
import UniverseDesignActionPanel
import UniverseDesignIcon

/// MemberList - ViewController

class MemberListViewController: BaseViewController, HasViewModel, UserResolverWrapper, UITableViewDataSource, UITableViewDelegate {
    var userResolver: LarkContainer.UserResolver
    /// 需要退出页面
    var onNeedsExit: (() -> Void)?

    let viewModel: MemberListViewModel

    private lazy var headerView = DetailAssingeeHeaderView()
    private lazy var tableView = setupTableView()
    private lazy var separateLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()
    private lazy var footerView = SettingSubTitleCell()
    private let disposeBag = DisposeBag()
    @ScopedInjectedLazy private var routeDependency: RouteDependency?

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
        viewModel.onListUpdate = { [weak self] in
            self?.tableView.reloadData()
            self?.updateHeaderTitle()
            self?.updateFooterTitle()
        }
        viewModel.setup()
    }

    private func setupView() {
        let fg = FeatureGating(resolver: userResolver).boolValue(for: .multiAssignee)

        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(tableView)

        if fg {
            view.addSubview(headerView)

            headerView.snp.makeConstraints { make in
                make.left.top.right.equalToSuperview()
            }

            if case .enable = viewModel.naviAddState {
                headerView.enableClickBtn = true
            }
            headerView.onAddHandler = { [weak self] in
                guard let self = self else {
                    return
                }
                self.showChatterPicker()
            }

            if viewModel.isAssigneeScene, viewModel.modeEditable {
                view.addSubview(separateLine)
                view.addSubview(footerView)
                tableView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(headerView.snp.bottom)
                }
                let lintHeight = CGFloat(1.0 / UIScreen.main.scale)
                separateLine.snp.makeConstraints { make in
                    make.height.equalTo(lintHeight)
                    make.bottom.equalTo(tableView.snp.bottom)
                    make.left.right.equalToSuperview()
                }

                footerView.snp.makeConstraints { make in
                    make.top.equalTo(tableView.snp.bottom).offset(8)
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
                tableView.snp.makeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(headerView.snp.bottom)
                    make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
                }
            }
        } else {
            tableView.snp.makeConstraints { $0.edges.equalToSuperview() }
            setupNaviBar()
        }
        addCloseItem()
    }

    private func setupTableView() -> UITableView {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.tableHeaderView = UIView(frame: .zero)
        tableView.tableFooterView = UIView()
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.separatorInset = .init(top: 0, left: 68, bottom: 0, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.ctf.register(cellType: MemberListCell.self)
        return tableView
    }

    private func setupNaviBar() {
        // title
        title = viewModel.title
        // right
        switch viewModel.naviAddState {
        case .hidden:
            return
        case .disable(let message):
            let barItem = LKBarButtonItem(image: nil, title: I18N.Todo_common_Add, fontStyle: .medium)
            barItem.button.tintColor = UIColor.ud.textLinkDisabled
            barItem.button.rx.tap.asDriver()
                .drive(onNext: { [weak self] in
                    guard let self = self else { return }
                    Utils.Toast.showWarning(with: message, on: self.view)
                })
                .disposed(by: disposeBag)
            navigationItem.setRightBarButton(barItem, animated: false)
        case .enable:
            let barItem = LKBarButtonItem(image: nil, title: I18N.Todo_common_Add, fontStyle: .medium)
            barItem.button.tintColor = UIColor.ud.primaryContentDefault
            barItem.button.rx.tap.asDriver()
                .drive(onNext: { [weak self] in
                    self?.showChatterPicker()
                })
                .disposed(by: disposeBag)
            navigationItem.setRightBarButton(barItem, animated: false)
        }
    }

    @objc
    private func showChatterPicker() {
        var routeParams = RouteParams(from: self)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        let title: String
        let isAssignee: Bool
        switch viewModel.input.scene {
        case .creating_assignee, .editing_assignee, .creating_subTask_assignee:
            title = I18N.Todo_AddCollaborator_Tooltip
            isAssignee = true
        case .creating_follower, .editing_follower:
            title = I18N.Todo_Task_AddFollower
            isAssignee = false
        case .custom_fields(_, let titleText):
            title = titleText
            isAssignee = false
        }
        routeDependency?.showChatterPicker(
            title: title,
            chatId: viewModel.input.chatId,
            isAssignee: isAssignee,
            selectedChatterIds: viewModel.allChatterIds(),
            selectedCallback: { [weak self] controller, chatterIds in
                Detail.logger.info("pick chatters, count:\(chatterIds.count)")
                controller?.dismiss(animated: true, completion: nil)
                guard let self = self else { return }
                self.viewModel.appendItems(by: chatterIds, callback: self.makeAppendCallback())
            },
            params: routeParams
        )
    }

    private func makeAppendCallback() -> ViewModel.AppendCallback {
        return { [weak self] res in
            guard let self = self else { return }
            if case .failure(let userErr) = res {
                Utils.Toast.showError(with: userErr.message, on: self.view)
            }
        }
    }

    private func makeDeleteCallback() -> ViewModel.DeleteCallback {
        return { [weak self] res in
            guard let self = self else { return }
            switch res {
            case let .success((toast, needsExit)):
                if let toast = toast {
                    Utils.Toast.showSuccess(with: toast, on: self.view)
                }
                if needsExit {
                    self.onNeedsExit?()
                }
            case .failure(let userErr):
                Utils.Toast.showError(with: userErr.message, on: self.view)
            }
        }
    }

    private func handleDelete(at indexPath: IndexPath) {
        guard let confirmCtx = viewModel.confirmContextForDeleting(at: indexPath) else {
            // 直接删除
            viewModel.deleteItem(at: indexPath, callback: makeDeleteCallback())
            return
        }

        // 二次确认
        guard let cell = tableView.cellForRow(at: indexPath) else {
            Detail.assertionFailure("find cell failed. indexPath: \(indexPath)")
            return
        }

        let source = UDActionSheetSource(
            sourceView: cell.contentView,
            sourceRect: CGRect(x: cell.frame.width - 32, y: cell.frame.height / 2 - 8, width: 16, height: 16),
            arrowDirection: .unknown
        )
        let config = UDActionSheetUIConfig(titleColor: UIColor.ud.textPlaceholder, isShowTitle: confirmCtx.tip != nil, popSource: source)
        let actionSheet = UDActionSheet(config: config)
        if let title = confirmCtx.tip {
            actionSheet.setTitle(title)
        }
        actionSheet.addItem(
            UDActionSheetItem(
                title: confirmCtx.text,
                titleColor: UIColor.ud.textTitle,
                action: { [weak self] in
                    guard let self = self else { return }
                    confirmCtx.action(self.makeDeleteCallback())
                }
            )
        )
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true)
    }

    // MARK: UITableViewDataSource & UITableViewDelegate

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
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
            let cellData = viewModel.cellData(at: indexPath),
            let cell = tableView.ctf.dequeueReusableCell(MemberListCell.self, for: indexPath)
        else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        cell.viewData = cellData
        cell.onDelete = { [weak self] in self?.handleDelete(at: indexPath) }
        cell.onDeleteDisableAlert = { [weak self] toast in
            guard let self = self else { return }
            Utils.Toast.showWarning(with: toast, on: self.view)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        guard let chatterId = viewModel.chatterId(at: indexPath) else { return }

        Detail.logger.info("will jump to profile. chatterId: \(chatterId)")

        var routeParams = RouteParams(from: self)
        if Display.pad {
            routeParams.openType = .present
            routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
            routeParams.wrap = LkNavigationController.self
        } else {
            routeParams.openType = .push
        }
        routeDependency?.showProfile(with: chatterId, params: routeParams)
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
                guard let self = self else { return }
                self.viewModel.changeTaskMode(.taskComplete)
                if !self.viewModel.isAssigneeCreateScene {
                    self.closeBtnTapped()
                }
        }))
        actionSheet.addItem(UDActionSheetItem(
            title: Rust.TaskMode.userComplete.pickerTitle,
            titleColor: color(.userComplete),
            action: { [weak self] in
                guard let self = self else { return }
                self.viewModel.changeTaskMode(.userComplete)
                if !self.viewModel.isAssigneeCreateScene {
                    self.closeBtnTapped()
                }
        }))
        actionSheet.setCancelItem(text: I18N.Todo_Common_Cancel)
        present(actionSheet, animated: true)
    }

    private func updateHeaderTitle() {
        let totalCount = viewModel.numberOfRows(in: 0)
        if totalCount > 0 {
            headerView.title = "\(viewModel.title)(\(totalCount))"
        } else {
            headerView.title = viewModel.title
        }
    }

    private func updateFooterTitle() {
        footerView.updateTitle(title: viewModel.mode.pickerTitle)
    }

}
