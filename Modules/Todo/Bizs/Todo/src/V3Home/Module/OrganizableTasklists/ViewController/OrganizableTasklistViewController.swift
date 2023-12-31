//
//  OrganizableTasklistViewController.swift
//  Todo
//
//  Created by wangwanxin on 2023/10/23.
//

import CTFoundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkUIKit

final class OrganizableTasklistViewController:
    BaseViewController, UserResolverWrapper,
    UICollectionViewDelegateFlowLayout,
    UICollectionViewDataSource,
    UICollectionViewDelegate {

    let viewModel: OrganizableTasklistViewModel
    let userResolver: LarkContainer.UserResolver

    private lazy var stateView: ListStateView = {
        return ListStateView(
            with: view,
            targetView: view,
            bottomInset: navigationController?.navigationBar.frame.height ?? 0,
            backgroundColor: UIColor.ud.bgBase
        )
    }()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.showsVerticalScrollIndicator = false
        view.alwaysBounceVertical = true
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = UIColor.ud.bgBase
        view.clipsToBounds = true
        view.lu.addCorner(
            corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner],
            cornerSize: CGSize(
                width: OrganizableTasklistItemData.Config.cornerRadius,
                height: OrganizableTasklistItemData.Config.cornerRadius
            )
        )
        view.ctf.register(cellType: OrganizableTasklistCell.self)
        return view
    }()
    private lazy var bigAddButton = BigAddButton()
    private let disposeBag = DisposeBag()

    init(resolver: LarkContainer.UserResolver, viewModel: OrganizableTasklistViewModel) {
        self.userResolver = resolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubview()
        bindViewState()
        setupViewModel()
        OrganizableTasklist.Track.view()
    }

    private func setupSubview() {
        view.backgroundColor = UIColor.ud.bgBase
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            let padding = OrganizableTasklistItemData.Config.collectionViewPadding
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: padding, left: padding, bottom: 0, right: padding)
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
        stateView.retryHandler = { [weak self] in self?.viewModel.retryFetch() }
    }

    private func bindViewState() {
        viewModel.rxListUpdate
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self]  in
                    self?.reloadData()
                })
            .disposed(by: disposeBag)
        viewModel.rxLoadMoreState.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(
                onNext: { [weak self] state in
                    guard let self = self else { return }
                    self.updateLoadMore(state: state)
                })
            .disposed(by: disposeBag)
        viewModel.rxViewState.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                if case .empty = state {
                    self.stateView.cleanEmptyView()
                }
                self.stateView.bottomInset = self.collectionView.adjustedContentInset.bottom
                self.stateView.updateViewState(
                    state: state,
                    emptyType: .noContent,
                    emptyDescription: self.viewModel.currentRequest.emptyText
                )
                self.view.bringSubviewToFront(self.bigAddButton)
            })
            .disposed(by: disposeBag)
    }

    private func setupViewModel() {
        contentViewWidth()
        viewModel.setup()
    }

    private func contentViewWidth() {
        let width = navigationController?.view.bounds.size.width ?? view.bounds.size.width
        let padding = OrganizableTasklistItemData.Config.collectionViewPadding
        viewModel.contentViewWidth = width - padding * 2
    }

    private func reloadData() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        collectionView.reloadData()
    }

    // collection view
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 80)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.ctf.dequeueReusableCell(OrganizableTasklistCell.self, for: indexPath),
                let itemData = viewModel.itemData(at: indexPath) else {
            return UICollectionViewCell()
        }
        cell.viewData = itemData
        let numberOfRows = collectionView.numberOfItems(inSection: indexPath.section)
        let radius = OrganizableTasklistItemData.Config.cornerRadius
        switch indexPath.row {
        case 0:
            var corners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            // 有且只有一个cell的时候需要处理左下、右下.
            if numberOfRows - 1 == 0 {
                corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            }
            cell.lu.addCorner(
                corners: corners,
                cornerSize: corners.isEmpty ? .zero : CGSize(width: radius, height: radius)
            )
        case numberOfRows - 1:
            let corners: CACornerMask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            cell.lu.addCorner(
                corners: corners,
                cornerSize: corners.isEmpty ? .zero : CGSize(width: radius, height: radius)
            )
        default:
            cell.lu.addCorner(
                corners: [],
                cornerSize: .zero
            )
        }
        cell.clipsToBounds = true
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView.cellForItem(at: indexPath) != nil else { return }
        guard let item = viewModel.itemData(at: indexPath) else { return }
        viewModel.logger.info("did tap tasklist \(item.identifier)")
        OrganizableTasklist.Track.clickItem(guid: item.identifier, tab: viewModel.currentRequest.tab, isArchived: viewModel.currentRequest.isArchived)
        let vc = V3HomeViewController(resolver: userResolver, scene: .onePage(guid: item.identifier))
        userResolver.navigator.push(vc, from: self)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard viewModel.needPreload(at: indexPath) else { return }
        viewModel.loadMore(silent: true)
    }

    @objc
    private func handleBigAdd() {
        OrganizableTasklist.Track.clickCreateButton()
        viewModel.context.bus.post(.createTasklist(section: nil, from: nil, callback: nil, completion: { container in
            OrganizableTasklist.Track.clickFinalCreate(guid: container.guid)
        }))
    }

}

// MARK: - Load More State

extension OrganizableTasklistViewController {

    func updateLoadMore(state: ListLoadMoreState) {
        viewModel.logger.info("updateLoadMoreState: \(state)")
        switch state {
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

    private func setupFooterIfNeeded() {
        if collectionView.footer != nil { return }
        collectionView.es.addInfiniteScrolling(animator: LoadMoreAnimationView()) { [weak self] in
            self?.viewModel.loadMore()
        }
    }
}
