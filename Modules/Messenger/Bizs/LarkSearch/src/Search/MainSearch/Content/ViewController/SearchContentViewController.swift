//
//  SearchContentViewController.swift
//  LarkSearch
//
//  Created by Patrick on 2022/5/19.
//

import UIKit
import Foundation
import UniverseDesignTabs
import LarkKeyCommandKit
import RxSwift
import EENavigator
import LarkMessengerInterface
import LarkUIKit
import LarkSearchCore
import LarkContainer
import LarkSearchFilter

public protocol SearchContentContainer: UIViewController, UDTabsListContainerViewDelegate {
    func queryChange(text: String)
    func filtersChange(filters: [SearchFilter])
}

public extension SearchContentContainer {
    func filtersChange(filters: [SearchFilter]) {}
}

final class SearchContentViewController: NiblessViewController, SearchContentContainer, UserResolverWrapper {
    let viewModel: SearchContentViewModel

    private lazy var searchResultController: SearchResultViewController = {
        let viewController = SearchResultViewController(userResolver: userResolver, viewModel: viewModel.searchResultViewModel)
        viewController.container = self
        viewController.view.isHidden = false
        return viewController
    }()

    private lazy var filterViewController: SearchFilterViewController? = {
        guard let filterViewModel = viewModel.searchFilterViewModel else { return nil }
        let viewController = SearchFilterViewController(userResolver: userResolver, viewModel: filterViewModel)
        viewController.container = self
        viewController.view.isHidden = !SearchFeatureGatingKey.noQueryFilterEnable.isEnabled
        return viewController
    }()

    private lazy var universalRecommendViewController: UniversalRecommendViewController? = {
        guard let recommendViewModel = viewModel.universalRecommendViewModel else { return nil }
        let viewController = UniversalRecommendViewController(userResolver: userResolver, viewModel: recommendViewModel)
        viewController.view.isHidden = true
        return viewController
    }()

    private lazy var noNetworkPage: SearchNoNetworkPage = {
        let view = SearchNoNetworkPage()
        view.retryAction = { [weak self] in
            self?.viewModel.retrySearch()
        }
        view.isHidden = true
        return view
    }()

    private var containerScrollView: SearchScrollView?
    private var lastScrollContentOffset: CGFloat = 0
    private var isShowingVC: Bool = true

    let userResolver: UserResolver
    init(userResolver: UserResolver, viewModel: SearchContentViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init()
    }

    deinit {
        trackShow()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        setupSubscribe()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        viewModel.searchWidthGetter = { [weak self] in
            if let service = try? self?.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
                return service.requestWidthOnPad()
            }
            return self?.view.frame.size.width ?? 0
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var supportPadStyle = false
        if let service = try? userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
            supportPadStyle = UIDevice.btd_isPadDevice() && !service.isCompactStatus()
        }
        searchResultController.view.snp.updateConstraints { make in
            if let filterViewController = filterViewController {
                make.top.equalTo(filterViewController.view.snp.bottom)
            } else {
                make.top.equalToSuperview().offset(supportPadStyle ? 0 : 8)
            }
        }
    }

    // MARK: - setups
    private func setupViews() {
        func makeScrollView() -> SearchScrollView {
            let view = SearchScrollView()
            view.scrollsToTop = false
            view.bounces = false
            view.delegate = self
            view.showsVerticalScrollIndicator = false
            view.showsHorizontalScrollIndicator = false
            view.backgroundColor = .ud.bgBase
            return view
        }
        /// 当FG为false，或者应用Tab下会添加推荐页面
        /// 当FG为true并且为综合Tab就不会进入这段逻辑
        if let universalRecommendViewController = universalRecommendViewController, (!SearchFeatureGatingKey.noQueryFilterEnable.isEnabled || !(viewModel.config is SearchMainTopResultsTabConfig)) {
            add(universalRecommendViewController) { view in
                self.view.addSubview(view)
                view.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
            }
        }
        /// 综合Tab
        if viewModel.autoHideFilterEnabled {
            let containerScrollView = makeScrollView()
            self.containerScrollView = containerScrollView
            view.addSubview(containerScrollView)
            containerScrollView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            containerScrollView.contentSize.width = view.frame.width
            containerScrollView.contentSize.height = view.frame.height + 60 // filterHeight

            if let filterViewController = filterViewController {
                add(filterViewController) { view in
                    containerScrollView.addSubview(view)
                    view.snp.makeConstraints { make in
                        make.leading.trailing.top.equalToSuperview()
                        make.height.equalTo(60)
                    }
                }
            }
            /// FG内并且综合Tab下添加推荐页面
            if let universalRecommendViewController = universalRecommendViewController, SearchFeatureGatingKey.noQueryFilterEnable.isEnabled,
                viewModel.config is SearchMainTopResultsTabConfig {
                add(universalRecommendViewController) { view in
                    containerScrollView.addSubview(view)
                    view.snp.makeConstraints { make in
                        if let filterViewController = filterViewController {
                            make.top.equalTo(filterViewController.view.snp.bottom)
                        } else {
                            make.top.equalToSuperview()
                        }
                        make.leading.trailing.bottom.width.equalToSuperview()
                        make.height.equalToSuperview()
                    }
                }
            }
            add(searchResultController) { view in
                containerScrollView.addSubview(view)
                view.snp.makeConstraints { make in
                    if let filterViewController = filterViewController {
                        make.top.equalTo(filterViewController.view.snp.bottom)
                    } else {
                        make.top.equalToSuperview().offset(8)
                    }
                    make.leading.trailing.bottom.width.equalToSuperview()
                    make.height.equalToSuperview()
                }
            }
        } else {
            /// 垂搜tab
            if let filterViewController = filterViewController {
                add(filterViewController) { view in
                    self.view.addSubview(view)
                    view.snp.makeConstraints { make in
                        make.leading.trailing.top.equalToSuperview()
                        make.height.equalTo(60)
                    }
                }
            }

            add(searchResultController) { view in
                self.view.addSubview(view)
                view.snp.makeConstraints { make in
                    if let filterViewController = filterViewController {
                        make.top.equalTo(filterViewController.view.snp.bottom)
                    } else {
                        make.top.equalToSuperview()
                    }
                    make.leading.trailing.bottom.equalToSuperview()
                }
            }
        }

        view.addSubview(noNetworkPage)
        noNetworkPage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private let disposeBag = DisposeBag()
    private func setupSubscribe() {
        viewModel.shouldShowRecommend
            .drive(onNext: { [weak self] shouldShowRecommend in
                guard let self = self else { return }
                if let originIsHidden = self.universalRecommendViewController?.view.isHidden, !originIsHidden, !shouldShowRecommend {
                    self.universalRecommendViewController?.trackShow()
                }
                if !self.searchResultController.view.isHidden, shouldShowRecommend {
                    self.viewModel.searchResultViewModel.trackSearchShow()
                }
                self.universalRecommendViewController?.view.isHidden = !shouldShowRecommend
                self.searchResultController.view.isHidden = shouldShowRecommend
                /// 全量后isHidden属性恒为false， 可以删除
                self.containerScrollView?.isHidden = shouldShowRecommend && !SearchFeatureGatingKey.noQueryFilterEnable.isEnabled
                self.filterViewController?.view.isHidden = shouldShowRecommend && !SearchFeatureGatingKey.noQueryFilterEnable.isEnabled
            })
            .disposed(by: disposeBag)
        viewModel.shouldShowNoNetworkPage
            .drive(onNext: { [weak self] shouldShowNoNetworkPage in
                guard let self = self else { return }
                switch shouldShowNoNetworkPage {
                case .hide:
                    self.noNetworkPage.isHidden = true
                case .show(let error):
                    self.view.bringSubviewToFront(self.noNetworkPage)
                    self.noNetworkPage.isHidden = false
                    self.noNetworkPage.setup(withError: error, backgroundColor: self.viewModel.resultViewBackgroundColor)
                }
            })
            .disposed(by: disposeBag)
        if viewModel.autoHideFilterEnabled {
            viewModel.goToScrollViewContentOffset
                .drive(onNext: { [weak self] offSetInfo in
                    guard let self = self, let (offset, animated) = offSetInfo else { return }
                    self.containerScrollView?.setContentOffset(offset, animated: animated)
                })
                .disposed(by: disposeBag)
        }
        viewModel.shouldOpenProfile
            .subscribe(onNext: { [weak self] userId in
                guard let self = self else { return }
                self.viewModel.viewModelContext.router.gotoPersonCardWith(chatterID: userId, fromVC: self)
            })
            .disposed(by: disposeBag)
        if viewModel.autoHideFilterEnabled {
            viewModel.shouldChangeFilterStyle
                .drive(onNext: { [weak self] style in
                    self?.filterViewController?.style = style
                })
                .disposed(by: disposeBag)
            viewModel.shouldEnableContainerScroll
                .drive(onNext: { [weak self] shouldEnableContainerScroll in
                    self?.containerScrollView?.isScrollEnabled = shouldEnableContainerScroll
                })
                .disposed(by: disposeBag)
        }
    }

    private func add(_ viewController: UIViewController, layout: (UIView) -> Void) {
        addChild(viewController)
        layout(viewController.view)
        viewController.didMove(toParent: self)
    }

    // MARK: - Route
    func routeTo(withSearchInput input: SearcherInput, isCapsuleStyle: Bool) {
        viewModel.routeTo(withSearchInput: input, isCapsuleStyle: isCapsuleStyle)
    }

    func trackShow() {
        if isShowingVC {
            if let isHidden = universalRecommendViewController?.view.isHidden, !isHidden {
                universalRecommendViewController?.trackShow()
            } else {
                viewModel.searchResultViewModel.trackSearchShow()
            }
        }
    }

    // MARK: - Search
    func queryChange(text: String) {
        searchResultController.resetKBFocus()
        viewModel.queryChange(text: text)
    }

    func filtersChange(filters: [SearchFilter]) {
        viewModel.filtersChange(filters: filters)
    }

    // MARK: - JXSegmentedListContainerViewListDelegate
    func listWillDisappear() {
        trackShow()
        isShowingVC = false
    }

    func listDidAppear() {
        isShowingVC = true
    }

    // MARK: - KeyBinding
    override func keyCommandContainers() -> [KeyCommandContainer] {
        if let present = self.presentedViewController {
            return present.keyCommandContainers()
        }
        return [self] + (searchResultController.keyCommandContainers() )
    }
}

extension SearchContentViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView { view }
}

extension SearchContentViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let headerStickyHeight: CGFloat = 60
        let offset = scrollView.contentOffset.y
        if scrollView == containerScrollView {
            if offset >= headerStickyHeight {
                scrollView.contentOffset.y = headerStickyHeight
            }
        }
    }
}
