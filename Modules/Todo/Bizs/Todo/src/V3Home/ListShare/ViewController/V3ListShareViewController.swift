//
//  V3ListShareViewController.swift
//  Todo
//
//  Created by GCW on 2022/11/30.
//

import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignIcon
import EENavigator
import TodoInterface
import UniverseDesignActionPanel
import UniverseDesignDialog
import UniverseDesignCheckBox
import UniverseDesignButton
import UniverseDesignInput
import LarkContainer
import UniverseDesignFont
import LarkFoundation

enum ListShareScene {
    case share
    case manage
}

final class V3ListShareViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    let viewModel: V3ListShareViewModel
    let scene: ListShareScene
    var handleCloseSharePanel: (() -> Void)?

    private let disposeBag = DisposeBag()
    private var willShowObserver: NSObjectProtocol?
    private var willHideObserver: NSObjectProtocol?

    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    // 协作者的tableView
    private lazy var assistantTableView: UITableView = {
        let assistantTableView = UITableView(frame: .zero)
        assistantTableView.delegate = self
        assistantTableView.dataSource = self
        assistantTableView.showsVerticalScrollIndicator = false
        assistantTableView.backgroundColor = UIColor.clear
        assistantTableView.separatorStyle = .none
        assistantTableView.keyboardDismissMode = .onDrag
        assistantTableView.register(V3ListShareCell.self, forCellReuseIdentifier: V3ListShareCell.lu.reuseIdentifier)
        return assistantTableView
    }()

    // loading view
    private lazy var stateView: ListStateView = {
        return ListStateView(
            with: view,
            targetView: view,
            backgroundColor: UIColor.ud.bgBody
        )
    }()

    private lazy var bottomView: V3ListShareBottomView = {
        let bottomView = V3ListShareBottomView()
        bottomView.delegate = self
        return bottomView
    }()

    init(resolver: UserResolver, viewModel: V3ListShareViewModel, scene: ListShareScene) {
        self.userResolver = resolver
        self.viewModel = viewModel
        self.scene = scene
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        if let willShowObserver = willShowObserver, let willHideObserver = willHideObserver {
            NotificationCenter.default.removeObserver(willShowObserver)
            NotificationCenter.default.removeObserver(willHideObserver)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNav()
        setupView()
        switch scene {
        case .manage:
            bindViewData()
            bindViewState()
            bindLoadMoreState()
        case .share:
            bindShareViewData()
            addObserver()
        }
    }

    func setupNav() {
        if scene == .manage {
            let addAssistant = LKBarButtonItem(image: UDIcon.getIconByKey(.memberAddOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1),
                                               title: nil)
            addAssistant.button.addTarget(self, action: #selector(addAssistantTap), for: .touchUpInside)
            self.navigationItem.rightBarButtonItem = addAssistant
        }
        // 添加取消按钮
        addCancelItem()
        self.title = scene == .manage ? I18N.Todo_ListCard_Collaborators_Text : I18N.Todo_ShareList_InviteCollaborators_Title
    }

    func setupView() {
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(assistantTableView)
        switch scene {
        case .manage:
            assistantTableView.snp.makeConstraints { $0.edges.equalToSuperview() }
        case .share:
            view.addSubview(bottomView)
            assistantTableView.snp.makeConstraints { (make) in
                make.top.left.right.equalToSuperview()
                make.bottom.equalTo(bottomView.snp.top)
            }
            bottomView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            }
        }
    }

    private func bindViewData() {
        viewModel.reloadNoti
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] viewData in
                switch viewData.state {
                case .refresh:
                    self?.assistantTableView.reloadData()
                    // 目前不显示协作者的数量
                    // self?.title = viewData.title
                case .dismiss:
                    self?.dismiss(animated: true, completion: self?.handleCloseSharePanel)
                }
            })
            .disposed(by: disposeBag)
    }

    private func bindShareViewData() {
        viewModel.inviteNoti
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] viewData in
                switch viewData.state {
                case .refresh:
                    self?.assistantTableView.reloadData()
                    // 目前不显示协作者的数量
                    // self?.title = viewData.title
                case .dismiss:
                    self?.dismiss(animated: true, completion: nil)
                }
            })
    }

    @objc
    func addAssistantTap() {
        showInvitorPicker()
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = assistantTableView.dequeueReusableCell(withIdentifier: V3ListShareCell.lu.reuseIdentifier, for: indexPath) as? V3ListShareCell
        tableViewCell?.delegate = self
        tableViewCell?.cellData = viewModel.cellData(at: indexPath)
        return tableViewCell ?? V3ListShareCell()
    }
}

// MARK: - LoadMore
extension V3ListShareViewController {
    private func setupFooterIfNeeded() {
        if assistantTableView.footer != nil { return }
        assistantTableView.es.addInfiniteScrolling(animator: LoadMoreAnimationView()) { [weak self] in
            guard let self = self else { return }
            let state = self.viewModel.rxLoadMoreState.value
            guard state == .hasMore else {
                self.doUpdateLoadMoreState(state)
                return
            }
            self.viewModel.doLoadMoreTaskLists()
        }
    }

    private func doUpdateLoadMoreState(_ loadMoreState: ListLoadMoreState) {
        switch loadMoreState {
        case .none:
            assistantTableView.es.removeRefreshFooter()
        case .noMore:
            assistantTableView.es.stopLoadingMore()
            assistantTableView.es.noticeNoMoreData()
        case .loading:
            setupFooterIfNeeded()
            assistantTableView.footer?.startRefreshing()
        case .hasMore:
            setupFooterIfNeeded()
            assistantTableView.es.resetNoMoreData()
            assistantTableView.es.stopLoadingMore()
        }
    }

    private func bindViewState() {
        viewModel.rxViewState.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] viewState in
                guard let self = self else { return }
                self.stateView.updateViewState(state: viewState)
            })
            .disposed(by: disposeBag)
    }

    private func bindLoadMoreState() {
        viewModel.rxLoadMoreState.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] loadMoreState in
                self?.doUpdateLoadMoreState(loadMoreState)
            })
            .disposed(by: disposeBag)
    }

    private func updateMemberPermission(updateMemberRole: Rust.MemberRole, memberId: String, memberType: Rust.TaskMemberType) {
        self.viewModel.updateMemberPermission(updateMemberRole: updateMemberRole,
                                              memberId: memberId,
                                              entityType: memberType ) { [weak self] result in
            guard let self = self, let window = self.view.window else { return }
            switch result {
            case .succeed(let toast):
                guard let toast = toast else { return }
                Utils.Toast.showSuccess(with: toast, on: window)
                // 操作自己的时候，需要退出。不然会有一些状态不能及时刷新，这里参考的是文档那边的交互
                if memberId == self.viewModel.currentUserId {
                    self.dismiss(animated: true)
                }
            case .failed(let toast):
                guard let toast = toast else { return }
                Utils.Toast.showError(with: toast, on: window)
            }
        }
    }

    private func updateInvitorPermission(updateMemberRole: Rust.MemberRole, memberId: String) {
        switch updateMemberRole {
        case .reader, .writer:
            self.viewModel.updateInvitorPermission(memberId: memberId, memberRole: updateMemberRole)
        case .none:
            self.viewModel.removeInvitor(memberId: memberId)
        @unknown default:
            break
        }
    }

    private func addObserver() {
        willShowObserver = handelKeyboard(name: UIResponder.keyboardWillShowNotification, action: { [weak self] (keyboardRect, duration) in
            guard let self = self else { return }
            let animation = { [weak self] in
                guard let self = self else { return }
                self.bottomView.snp.remakeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.bottom.equalToSuperview().offset(-keyboardRect.height)
                }
            }
            UIView.animate(withDuration: duration,
                           delay: 0,
                           animations: {
                animation()
                self.view.layoutIfNeeded()
            },
            completion: nil)
        })
        willHideObserver = handelKeyboard(name: UIResponder.keyboardWillHideNotification, action: { [weak self] (_, duration) in
            guard let self = self else { return }
            let animation = { [weak self] in
                guard let self = self else { return }
                self.bottomView.snp.remakeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
                }
            }
            UIView.animate(withDuration: duration,
                           delay: 0,
                           animations: {
                animation()
                self.view.layoutIfNeeded()
            },
            completion: nil)
        })
    }

    private func handelKeyboard(name: NSNotification.Name, action: @escaping (CGRect, TimeInterval) -> Void) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { (notification) in
            guard let userinfo = notification.userInfo else {
                assertionFailure()
                return
            }
            let duration = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
            guard let toFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                assertionFailure()
                return
            }
            action(toFrame, duration ?? 0)
        }
    }

    private func getSelectedIds() -> [String] {
        let members = self.viewModel.reloadNoti.value
        let selectedIds = members.cellItem.map {
            return $0.identifier
        }
        return selectedIds
    }

    func showInvitorPicker() {
        var routeParams = RouteParams(from: self)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showSharePicker(
            title: I18N.Todo_ShareList_InviteCollaborators_Title,
            selectedChatterIds: getSelectedIds(),
            selectedCallback: { [weak self] (fromVC, userInfos, groupInfos) in
                guard let self = self else { return }
                var users = userInfos.map {
                    return MemberData(
                        userId: $0.identifier,
                        name: $0.name,
                        avatar: AvatarSeed(avatarId: $0.identifier, avatarKey: $0.avatarKey),
                        memberDepart: "",
                        memberType: .user
                    )
                }
                let groups = groupInfos.map {
                    return MemberData(
                        userId: $0.identifier,
                        name: $0.name,
                        avatar: AvatarSeed(avatarId: $0.identifier, avatarKey: $0.avatarKey),
                        memberDepart: "",
                        memberType: .group
                    )
                }
                users.append(contentsOf: groups)
                self.showShareManage(memberDatas: users, fromVC: fromVC)
            },
            params: routeParams
        )
    }

    func showShareManage(memberDatas: [MemberData], fromVC: UIViewController?) {
        guard let fromVC = fromVC else { return }
        let invitor = V3ListShareViewModel.transformInviteData(
            container: viewModel.taskListInput,
            memberDatas: memberDatas,
            currentRole: viewModel.currentRole
        )
        let vm = V3ListShareViewModel(resolver: userResolver, taskListInput: viewModel.taskListInput, scene: .share, invitorData: invitor, currentRole: viewModel.currentRole)
        let vc = V3ListShareViewController(resolver: userResolver, viewModel: vm, scene: .share)
        vc.handleCloseSharePanel = handleCloseSharePanel
        let newVC = LkNavigationController(rootViewController: vc)
        fromVC.present(newVC, animated: true, completion: nil)
    }
}

extension V3ListShareViewController: V3ListShareBottomDelegate {
    func tapInviteBtn(isSendNote: Bool, note: String?) {
        self.viewModel.inviteMembers(isSendNote: isSendNote, note: note) { [weak self] result in
            guard let self = self, let window = self.view.window else { return }
            switch result {
            case .succeed(let toast):
                guard let toast = toast else { return }
                Utils.Toast.showSuccess(with: toast, on: window)
                self.handleCloseSharePanel?()
            case .failed(let toast):
                guard let toast = toast else { return }
                Utils.Toast.showError(with: toast, on: window)
                self.handleCloseSharePanel?()
            }
        }
    }
}

extension V3ListShareViewController: ListPermissionDelegate {
    func operatePermission(_ memberId: String, sourceView: UILabel?) {
        let alertVC = V3ListSharePermissionViewController()
        let alertActions = viewModel.getAlertViewData(memberId: memberId, scene: scene)
        if scene == .manage {
            guard let cellData = self.viewModel.reloadNoti.value.cellItem.first(where: { $0.identifier == memberId }) else { return }
            alertActions.forEach { alertAction in
                alertAction.handler = { [weak self] in
                    guard let self = self else { return }
                    // 当点击不为当前选项时，进行后续操作，下面同理
                    let isSelected = alertAction.isSelected ?? false
                    if !isSelected {
                        if alertAction.style.selectPermission == .owner {
                            let dialog = UDDialog()
                            dialog.setTitle(text: I18N.Todo_List_TransferOwnership_Title(cellData.name))
                            dialog.setContent(text: I18N.Todo_List_TransferOwnership_Desc(cellData.name))
                            dialog.addCancelButton()
                            dialog.addDestructiveButton(text: I18N.Todo_List_TransferOwnershipTransfer_Button, dismissCompletion: {
                                self.updateMemberPermission(updateMemberRole: alertAction.style.selectPermission,
                                                            memberId: memberId,
                                                            memberType: cellData.memberType)
                            })
                            self.present(dialog, animated: true)
                        } else {
                            self.updateMemberPermission(updateMemberRole: alertAction.style.selectPermission,
                                                        memberId: memberId,
                                                        memberType: cellData.memberType)
                        }
                    }
                }
                alertVC.add(alertAction)
            }
            alertVC.setMember(avatar: cellData.leadingIcon, name: cellData.name)
        } else if scene == .share {
            // 当为分享面板时，可能需要收起键盘
            bottomView.closeKeyBoard()
            guard let cellData = self.viewModel.inviteNoti.value.cellItem.first(where: { $0.identifier == memberId }) else { return }
            alertActions.forEach { alertAction in
                alertAction.handler = { [weak self] in
                    guard let self = self else { return }
                    let isSelected = alertAction.isSelected ?? false
                    if !isSelected {
                        self.updateInvitorPermission(updateMemberRole: alertAction.style.selectPermission, memberId: memberId)
                    }
                }
                alertVC.add(alertAction)
            }
            alertVC.setMember(avatar: cellData.leadingIcon, name: cellData.name)
        }
        if Display.pad {
            guard let sourceView = sourceView else { return }
            alertVC.modalPresentationStyle = .popover
            alertVC.popoverPresentationController?.sourceView = sourceView
            alertVC.preferredContentSize = CGSize(width: 375, height: alertVC.heightForAlertView())
            alertVC.popoverPresentationController?.permittedArrowDirections = [.right, .down, .up]
            present(alertVC, animated: true)
        } else {
            let config = UDActionPanelUIConfig(
                originY: UIScreen.main.bounds.height - alertVC.heightForAlertView() - self.view.safeAreaInsets.bottom,
                canBeDragged: false)
            let source = UDActionPanel(customViewController: alertVC, config: config)
            present(source, animated: true, completion: nil)
        }
    }

    func clickProfile(_ userId: String, _ sender: V3ListShareCell) {
        guard assistantTableView.indexPath(for: sender) != nil else {
            return
        }
        var routeParams = RouteParams(from: self)
        routeParams.openType = .push
        routeDependency?.showProfile(with: userId, params: routeParams)
    }

    func clickContent(_ url: String, _ sender: V3ListShareCell) {
        guard assistantTableView.indexPath(for: sender) != nil else {
            return
        }
        do {
            let url = try URL.forceCreateURL(string: url)
            guard let httpUrl = url.lf.toHttpUrl() else {
                Detail.logger.error("share url is not valid.")
                return
            }
            userResolver.navigator.push(httpUrl, context: ["from": "todo_share"], from: self)
        } catch {
            Detail.logger.error("forceCreateURL failed. err: \(error)")
        }
    }

}
