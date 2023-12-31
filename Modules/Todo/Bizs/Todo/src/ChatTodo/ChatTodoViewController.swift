//
//  ChatTodoViewController.swift
//  Todo
//
//  Created by 白言韬 on 2021/3/25.
//

import Foundation
import LarkContainer
import TodoInterface
import EENavigator
import LarkUIKit
import ESPullToRefresh
import RxSwift
import LarkTab
import UniverseDesignDialog
import UniverseDesignEmpty
import UniverseDesignFont

final class ChatTodoViewController: BaseViewController, UserResolverWrapper,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {
    typealias ViewModel = ChatTodoViewModel

    var userResolver: LarkContainer.UserResolver

    private let viewModel: ViewModel

    private lazy var collectionView: UICollectionView = setupCollectionView()

    // + 号大按钮
    private lazy var bigAddButton: BigAddButton = BigAddButton()

    @ScopedInjectedLazy private var routeDependency: RouteDependency?
    private let disposeBag = DisposeBag()

    // StateViews
    private var loadingView: LoadingPlaceholderView?
    private var failedView: UDEmptyView?
    private var emptyView: UDEmptyView?

    init(resolver: UserResolver, viewModel: ViewModel) {
        self.userResolver = resolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        title = I18N.Todo_Task_Tasks
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()

        bindViewState()
        bindLoadMoreState()

        viewModel.listUpdateResponder = { [weak self] in
            self?.collectionView.reloadData()
        }
        viewModel.setup()
        ChatTodo.Track.viewList(with: viewModel.chatId)
    }

    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: 12, left: 0, bottom: 0, right: 0)
            )
        }

        bigAddButton.rx.controlEvent(.touchUpInside)
            .bind { [weak self] _ in self?.handleBigAdd() }
            .disposed(by: disposeBag)
        view.addSubview(bigAddButton)
        bigAddButton.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }

        if viewModel.hasTodoTab() {
            let naviItem = LKBarButtonItem(image: nil, title: I18N.Todo_TaskCenter_ViewMore, fontStyle: .medium)
            naviItem.button.tintColor = UIColor.ud.textTitle
            naviItem.button.addTarget(self, action: #selector(jumpToTaskCenter), for: .touchUpInside)
            navigationItem.rightBarButtonItem = naviItem
        }
    }

    @objc
    private func jumpToTaskCenter() {
        userResolver.navigator.switchTab(Tab.todo.url, from: self, animated: false, completion: nil)
        ChatTodo.Track.clickJumpToCenter()
    }

    private func handleBigAdd() {
        #if InTodoDemo
        createTodo(chatName: "")
        return
        #endif
        viewModel.messengerDependency?.fetchChatName(
            by: viewModel.chatId,
            onSuccess: { [weak self] chatName in
                self?.createTodo(chatName: chatName)
            },
            onError: { error in
                ChatTodo.logger.error("fetchChatName failed. error: \(error)")
            }
        )
    }

    private func createTodo(chatName: String) {
        ChatTodo.Track.addTodo(with: viewModel.chatId)
        let chatContext = TodoCreateBody.ChatSourceContext(
            chatId: viewModel.chatId,
            chatName: chatName,
            messageId: nil,
            threadId: nil,
            fromContent: .chatSetting,
            isThread: viewModel.isFromThread
        )
        let source = TodoCreateSource.chat(context: chatContext)
        let callbacks = TodoCreateCallbacks(createHandler: { [weak self] response in
            self?.viewModel.handleCreatedTodo(response.todo) { [weak self] res in
                guard case .failure(let userErr) = res, let window = self?.view.window else { return }
                Utils.Toast.showError(with: userErr.message, on: window)
            }
        })
        let detailVC = DetailViewController(resolver: userResolver, input: .create(source: source, callbacks: callbacks))
        userResolver.navigator.present(
            detailVC,
            wrap: LkNavigationController.self,
            from: self,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    private func setupCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionHeadersPinToVisibleBounds = true
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        collectionView.backgroundColor = UIColor.ud.bgBase
        collectionView.ctf.register(cellType: ChatTodoCell.self)
        collectionView.ctf.register(headerViewType: V3ListSectionHeaderView.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.lu.addCorner(
            corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
            cornerSize: CGSize(width: 10, height: 10)
        )
        collectionView.clipsToBounds = true
        return collectionView
    }

    // MARK: UICollectionView

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.sectionCount()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let header = collectionView.ctf.dequeueReusableHeaderView(V3ListSectionHeaderView.self, for: indexPath) else {
            return UICollectionReusableView()
        }
        let headerData = viewModel.headerData(in: indexPath.section)
        header.viewData = headerData
        header.tapSectionHandler = { [weak self] in
            guard let self = self  else { return }
            self.viewModel.toggleFold(sectionKey: headerData?.titleInfo?.text ?? "")
            collectionView.reloadData()
        }
        // 如果折叠或者分组数据中没有数据
        if let headerData = headerData, headerData.isFold {
            header.containerView.lu.addCorner(
                corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner],
                cornerSize: CGSize(width: 10, height: 10)
            )
            header.containerView.clipsToBounds = true
        } else {
            header.containerView.lu.addCorner(
                corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner],
                cornerSize: CGSize(width: 10, height: 10)
            )
            header.containerView.clipsToBounds = true
        }
        return header
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.itemCount(in: section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.ctf.dequeueReusableCell(ChatTodoCell.self, for: indexPath) else {
            return UICollectionViewCell()
        }
        cell.viewData = viewModel.itemData(at: indexPath)
        cell.actionDelegate = self
        cell.showSeparateLine = true
        let numberOfRows = collectionView.numberOfItems(inSection: indexPath.section)
        switch indexPath.row {
        case 0:
            var corners: CACornerMask = []
            if numberOfRows - 1 == 0 {
                corners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                cell.showSeparateLine = false
            }
            if viewModel.headerData(in: indexPath.section) == nil {
                corners.insert(.layerMinXMinYCorner)
                corners.insert(.layerMaxXMinYCorner)
            }
            cell.lu.addCorner(
                corners: corners,
                cornerSize: corners.isEmpty ? .zero : CGSize(width: 10, height: 10)
            )
        case numberOfRows - 1:
            cell.lu.addCorner(
                corners: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner],
                cornerSize: CGSize(width: 10, height: 10)
            )
            cell.showSeparateLine = false
        default:
            cell.lu.addCorner(
                corners: [],
                cornerSize: .zero
            )
        }
        cell.clipsToBounds = true
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let cellData = viewModel.itemData(at: indexPath) else {
            return .zero
        }
        let maxWidth = collectionView.bounds.width - ListConfig.Cell.leftPadding - ListConfig.Cell.rightPadding
        return CGSize(width: maxWidth, height: cellData.preferredHeight(maxWidth: maxWidth))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard let headerData = viewModel.headerData(in: section) else { return .zero }
        return CGSize(width: collectionView.frame.width, height: headerData.preferredHeight)
    }

}

// MARK: - ChatTodoCellActionDelegate

extension ChatTodoViewController: ChatTodoCellActionDelegate {

    func didTapDetail(from sender: ChatTodoCell) {
        guard let indexPath = collectionView.indexPath(for: sender),
              let chatTodo = viewModel.chatTodo(at: indexPath) else {
            ChatTodo.assertionFailure()
            return
        }

        let guid = chatTodo.todo.guid
        let source = TodoEditSource.chatTodo(chatId: viewModel.chatId, messageId: chatTodo.messageID)
        let callbacks = TodoEditCallbacks(
            updateHandler: { [weak self] todo in
                self?.viewModel.handleUpdatedItem(at: indexPath, item: todo)
            },
            deleteHandler: { [weak self] _ in
                self?.viewModel.handleDeletedItem(at: indexPath)
            }
        )
        ChatTodo.Track.clickCell(with: guid, chatId: viewModel.chatId)
        let detailVC = DetailViewController(resolver: userResolver, input: .edit(guid: guid, source: source, callbacks: callbacks))
        userResolver.navigator.push(detailVC, from: self)
    }

    func didTapSender(from sender: ChatTodoCell) {
        guard let indexPath = collectionView.indexPath(for: sender),
              let chatTodo = viewModel.chatTodo(at: indexPath) else {
            ChatTodo.assertionFailure()
            return
        }
        ChatTodo.Track.clickJumpToChat(with: chatTodo.todo.guid, chatId: viewModel.chatId)
        var routeParams = RouteParams(from: self)
        routeParams.openType = .push
        if viewModel.isFromThread {
            routeDependency?.showThread(with: chatTodo.messageID, position: chatTodo.messagePosition, params: routeParams)
        } else {
            routeDependency?.showChat(with: viewModel.chatId, position: chatTodo.messagePosition, params: routeParams)
        }
    }

    func disabledAction(for checkbox: Checkbox, from sender: ChatTodoCell) -> CheckboxDisabledAction {
        ChatTodo.logger.info("disabled checkbox clicked")
        return { }
    }

    func enabledAction(for checkbox: Checkbox, from sender: ChatTodoCell) -> CheckboxEnabledAction {
        ChatTodo.logger.info("checkbox clicked, will toggle checking status")
        guard
            let indexPath = collectionView.indexPath(for: sender),
            let cellData = sender.viewData as? ChatTodoCellData
        else {
            return .immediate { }
        }

        /// 自定义完成
        if let customComplete = viewModel.getCustomComplete(at: indexPath) {
            return .needsAsk(
                ask: { [weak self] (_, onNo) in
                    guard let self = self else { return }
                    customComplete.doAction(on: self)
                    onNo()
                },
                completion: {}
            )
        }

        if let doubleCheck = viewModel.doubleCheckBeforeToggleCompleteState(at: indexPath) {
            return .needsAsk(
                ask: { [weak self] (onYes, onNo) in
                    let dialog = UDDialog()
                    dialog.setTitle(text: doubleCheck.title)
                    dialog.setContent(text: doubleCheck.content)
                    dialog.addCancelButton(dismissCompletion: onNo)
                    dialog.addPrimaryButton(text: doubleCheck.confirm, dismissCompletion: onYes)
                    self?.present(dialog, animated: true)
                },
                completion: { [weak self] in
                    self?.viewModel.toggleCompleteState(forId: cellData.chatTodo.todo.guid)
                }
            )
        } else {
            return .immediate { [weak self] in
                self?.viewModel.toggleCompleteState(forId: cellData.chatTodo.todo.guid)
            }
        }
    }

}

// MARK: - LoadMore State

extension ChatTodoViewController {

    private func setupFooterIfNeeded() {
        if collectionView.footer != nil { return }
        collectionView.es.addInfiniteScrolling(animator: LoadMoreAnimationView()) { [weak self] in
            guard let self = self else { return }
            let state = self.viewModel.rxLoadMoreState.value
            guard state == .hasMore else {
                self.doUpdateLoadMoreState(state)
                return
            }
            ChatTodo.logger.info("loadMore action triggerred")
            self.viewModel.loadMore()
        }
    }

    private func doUpdateLoadMoreState(_ loadMoreState: ListLoadMoreState) {
        ChatTodo.logger.info("doUpdateLoadMoreState: \(loadMoreState)")
        switch loadMoreState {
        case .none:
            collectionView.es.removeRefreshFooter()
        case .noMore:
            collectionView.es.stopLoadingMore()
            collectionView.es.noticeNoMoreData()
        case .loading:
            setupFooterIfNeeded()
            collectionView.footer?.startRefreshing()
        case .hasMore:
            setupFooterIfNeeded()
            collectionView.es.resetNoMoreData()
            collectionView.es.stopLoadingMore()
        }
    }

    private func bindLoadMoreState() {
        viewModel.rxLoadMoreState.distinctUntilChanged()
            .subscribe(onNext: { [weak self] loadMoreState in
                self?.doUpdateLoadMoreState(loadMoreState)
            })
            .disposed(by: disposeBag)
    }

}

// MARK: - View State

extension ChatTodoViewController {
    private func bindViewState() {
        viewModel.rxViewState.distinctUntilChanged()
            .subscribe(onNext: { [weak self] viewState in
                self?.doUpdateViewState(viewState)
            })
            .disposed(by: disposeBag)
    }

    private func doUpdateViewState(_ viewState: ListViewState) {
        var hiddens = (empty: true, loading: true, failed: true)
        switch viewState {
        case .loading:
            setupLoadingView()
            hiddens.loading = false
            view.bringSubviewToFront(loadingView ?? UIView())
        case .data:
            view.bringSubviewToFront(collectionView)
            view.bringSubviewToFront(bigAddButton)
        case .failed:
            setupFailedView()
            hiddens.failed = false
            view.bringSubviewToFront(failedView ?? UIView())
        case .empty:
            setupEmptyView()
            hiddens.empty = false
            view.bringSubviewToFront(emptyView ?? UIView())
            view.bringSubviewToFront(bigAddButton)
        case .idle:
            break
        }
        emptyView?.isHidden = hiddens.empty
        failedView?.isHidden = hiddens.failed
        loadingView?.isHidden = hiddens.loading
    }

    private func setupLoadingView() {
        guard loadingView == nil else { return }
        let loadingView = LoadingPlaceholderView()
        loadingView.isHidden = true
        loadingView.backgroundColor = UIColor.ud.bgBase
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.loadingView = loadingView
    }

    private func setupFailedView() {
        guard failedView == nil else { return }
        let description = UDEmptyConfig.Description(
            descriptionText: NSAttributedString(
                string: I18N.Lark_Legacy_LoadFailedRetryTip,
                attributes: [
                    .font: UDFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.ud.textCaption
                ])
        )
        let failedView = UDEmptyView(config: UDEmptyConfig(
            description: description,
            type: .loadingFailure
        ))
        failedView.backgroundColor = UIColor.ud.bgBase
        failedView.clickHandler = { [weak self] in self?.viewModel.setup() }
        failedView.useCenterConstraints = true
        failedView.isHidden = true
        view.addSubview(failedView)
        failedView.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.failedView = failedView
    }

    private func setupEmptyView() {
        guard emptyView == nil else { return }
        let description = UDEmptyConfig.Description(
            descriptionText: NSAttributedString(
                string: I18N.Todo_Chat_TasksListEmptyState,
                attributes: [
                    .font: UDFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.ud.textCaption
                ])
        )
        let emptyView = UDEmptyView(config: UDEmptyConfig(
            description: description,
            type: .done
        ))
        emptyView.useCenterConstraints = true
        emptyView.backgroundColor = UIColor.ud.bgBase
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        self.emptyView = emptyView
    }
}
