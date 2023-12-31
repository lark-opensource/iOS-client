//
//  NaviRecommandViewController.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/11/03.
//

import Foundation
import LarkUIKit
import SnapKit
import LKCommonsTracker
import LKCommonsLogging
import Homeric
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignEmpty
import LarkTab
import LarkInteraction
import EENavigator
import LarkContainer
import RustPB
import RxSwift
import LarkQuickLaunchInterface

final class NaviRecommandViewController: BaseUIViewController, UserResolverWrapper, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let userResolver: UserResolver

    private weak var tabBarVC: AnimatedTabBarController?

    static let logger = Logger.log(NaviRecommandViewController.self, category: "Module.AnimatedTabBar")

    @ScopedInjectedLazy private var quickLaunchService: QuickLaunchService?

    private let disposeBag = DisposeBag()

    private lazy var emptyDataView: UDEmptyView = {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.AnimatedTabBar.Lark_Legacy_PullEmptyResult)
        let emptyDataView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noApplication))
        emptyDataView.useCenterConstraints = true
        emptyDataView.isHidden = true
        return emptyDataView
    }()
    
    // 回调
    typealias RecommandCallback = () -> Void

    // 数据模型
    var items: [RustPB.Basic_V1_NavigationAppInfo] = []

    // 取消点击事件
    private let cancelCallback: RecommandCallback?
    // 添加应用事件
    private let addRecommandCallback: RecommandCallback?
    // 容器
    lazy var container = NaviRecommandContainer()

    private lazy var viewModel: NaviRecommandViewModel = {
        let viewModel = NaviRecommandViewModel(userResolver: userResolver, quickLaunchService: self.quickLaunchService)
        return viewModel
    }()

    required init(userResolver: UserResolver,
                  tabBarVC: AnimatedTabBarController?,
                  cancelCallback: RecommandCallback? = nil,
                  addRecommandCallback: RecommandCallback? = nil) {
        self.userResolver = userResolver
        self.tabBarVC = tabBarVC
        self.cancelCallback = cancelCallback
        self.addRecommandCallback = addRecommandCallback
        super.init(nibName: nil, bundle: nil)
        NotificationCenter.default.post(name: .lkQuickLaunchWindowAddRecommandDidShow, object: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 隐藏导航栏
        self.isNavigationBarHidden = true
        setup()
        layout()
        bindActions()
        bindVMAction()
        self.loadData()
        Tracker.post(TeaEvent(Homeric.NAVIGATION_ADD_APP_LIST_VIEW))
    }

    private func setup() {
        view.addSubview(container)
        view.addSubview(emptyDataView)
    }

    private func layout() {
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        emptyDataView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalTo(container)
            make.top.equalTo(container.navigationBar.snp.bottom)
        }
        loadingPlaceholderView.snp.remakeConstraints { (make) in
            make.edges.equalTo(container.collectionView)
        }
    }

    private func bindActions() {
        container.collectionView.delegate = self
        container.collectionView.dataSource = self

        container.cancelButton.addTarget(self, action: #selector(cancelBtnTapped), for: .touchUpInside)
    }

    @objc
    func cancelBtnTapped() {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_MORE_EDIT_CANCEL))
        cancelCallback?()
        self.dismiss(animated: true, completion: nil)
    }

    deinit {
        print("NaviRecommandViewController deinit")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.container.collectionView.frame.size.width != self.view.frame.size.width {
            //解决C/R模式切换显示
            self.container.collectionView.reloadData()
        }
    }

    private func loadData() {
        self.viewModel.loadRecommandData()
    }

    private func bindVMAction() {
        viewModel.status.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (status) in
            guard let self = self else { return }
            switch status {
            case .loading:
                self.loadingPlaceholderView.isHidden = false
            case .reload, .loadComplete:
                self.loadingPlaceholderView.isHidden = true
                self.container.collectionView.reloadData()
                self.addDataEmptyViewIfNeed()
            case .empty:
                self.loadingPlaceholderView.isHidden = true
                self.addDataEmptyViewIfNeed()
            case .retry:
                self.loadingPlaceholderView.isHidden = true
                self.addDataEmptyViewIfNeed()
            case .fail(let error):
                self.loadingPlaceholderView.isHidden = true
                self.addDataEmptyViewIfNeed()
            }
        }).disposed(by: disposeBag)

        self.viewModel
            .recommandObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (items) in
                guard let self = self else { return }
                self.items = items
            }).disposed(by: disposeBag)
    }

    // MARK: - CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item >= 0, indexPath.item < items.count else { return }
        collectionView.deselectItem(at: indexPath, animated: false)

        let item = items[indexPath.item]
        openApp(by: item)
    }

    // MARK: - CollectionView DataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.item >= 0, indexPath.item < items.count else { return UICollectionViewCell() }
        let recommandCell = collectionView.lu.dequeueReusableCell(withClass: NaviRecommandCell.self, for: indexPath)
        let item = items[indexPath.item]
        let isInNavigation: Bool
        if let tabBarVC = self.tabBarVC {
            isInNavigation = tabBarVC.findInNavigation(uniqueId: item.uniqueID)
        } else {
            isInNavigation = false
        }
        recommandCell.config(userResolver: self.userResolver, item: item, isInNavigation: isInNavigation) { [weak self] _ in
            guard let self = self else { return }
            if isInNavigation {
                self.openApp(by: item)
            } else {
                self.pinItemInRecommandList(item: item)
            }
        }
        return recommandCell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard (UICollectionView.elementKindSectionFooter == kind || UICollectionView.elementKindSectionHeader == kind) else { return UICollectionReusableView() }

        if UICollectionView.elementKindSectionHeader == kind {
            let titleHeaderView = collectionView.lu.dequeueReusableSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                withClass: RecommandHeaderTitleView.self,
                for: indexPath)
            return titleHeaderView
        }
        return UICollectionReusableView()
    }

    // MARK: - CollectionView FlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return Layout.sectionInset
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 60)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        // 标题
        return CGSize(width: collectionView.bounds.width, height: 44)
    }
}

extension NaviRecommandViewController {
    var navigationWrapper: UINavigationController {
        let navigation = UINavigationController(rootViewController: self)
        navigation.modalPresentationStyle = .formSheet
        return navigation
    }
}

extension NaviRecommandViewController {

    /// 把推荐的应用Pin到主导航
    func pinItemInRecommandList(item: RustPB.Basic_V1_NavigationAppInfo) {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_ADD_APP_LIST_CLICK, params: getAddAppListClickParams(by: "add", item: item)))
        let candidate = item.transferToTabContainable()
        self.quickLaunchService?.pinToQuickLaunchWindow(tab: candidate)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            self.addRecommandCallback?()
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: self.disposeBag)
    }

    /// 打开应用
    func openApp(by item: RustPB.Basic_V1_NavigationAppInfo) {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_ADD_APP_LIST_CLICK, params: getAddAppListClickParams(by: "application", item: item)))
        let candidate = item.transferToTabContainable()
        if let url = URL(string: candidate.url) {
            userResolver.animatedNavigator.push(url, context: item.extra, from: self)
        }
    }

    func getAddAppListClickParams(by click: String, item: RustPB.Basic_V1_NavigationAppInfo) -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        params["click"] = click
        let appId = item.extra[RecentRecordExtraKey.appid] ?? ""
        params["biz_type"] = item.extra[RecentRecordExtraKey.bizType] ?? ""
        params["op_app_id"] = appId
        params["doc_token"] = appId
        params["list_type"] = "recommend_list"
        return params
    }
}

extension NaviRecommandViewController {
    private func addDataEmptyViewIfNeed() {
        if self.items.isEmpty {
            emptyDataView.isHidden = false
            self.container.collectionView.isHidden = true
        } else {
            emptyDataView.isHidden = true
            self.container.collectionView.isHidden = false
        }
    }
}

extension NaviRecommandViewController {
    enum Layout {
        static let sectionInset: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
}
