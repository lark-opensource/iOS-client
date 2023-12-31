//
//  SearchOnPadRootViewController.swift
//  LarkSearch
//
//  Created by chenyanjie on 2023/11/10.
//

import Foundation
import LarkContainer
import LarkSDKInterface
import LarkSearchCore
import LarkMessengerInterface
import LarkUIKit
import RxCocoa
import LarkTab
import SuiteAppConfig
import LarkSplitViewController

public protocol SearchOnPadRootViewControllerDelegate: AnyObject {
    func searchOnPadRootVCWillDisapper()
    func searchOnPadRootVCDidDisapper(query: String?)
    func searchOnPadRootVCWillAppear()
    func searchOnPadRootVCCancel()
}

public protocol SearchRootViewControllerCircleDelegate: AnyObject {
    func didTapCancelBtn()
    func searchQueryWhenWillDisappear(query: String?)
}

class SearchOnPadRootViewController: UIViewController {
    let userResolver: UserResolver
    weak var delegate: SearchOnPadRootViewControllerDelegate?
    var sourceOfSearch: SourceOfSearch
    var searchEnterModel: SearchEnterModel
    let minLeftRightSpacing: CGFloat = 20
    var searchRootView: UIView?
    var searchRootViewController: SearchRootViewControllerProtocol?
    var query: String?
    var searchTopBGView: UIView?

    var isNeedShowCapsule: Bool

    var containerView = UIView()

    var splitVC: SplitViewController?

    var isEnterCacheSearchVC = false  //跳转到缓存的搜索页面

    init(userResolver: UserResolver, delegate: SearchOnPadRootViewControllerDelegate, sourceOfSearch: SourceOfSearch, searchEnterModel: SearchEnterModel) {
        self.userResolver = userResolver
        self.delegate = delegate
        self.sourceOfSearch = sourceOfSearch
        self.searchEnterModel = searchEnterModel
        isNeedShowCapsule = SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn
        super.init(nibName: nil, bundle: nil)
        setupView()
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func removeSplitVC() {
        if let splitVC = self.splitVC {
            splitVC.removeFromParent()
            splitVC.view.removeFromSuperview()
            self.splitVC = nil
            self.searchRootViewController = nil
            self.searchRootView = nil
        }
    }

    public func enterCacheSearchVC() {
        self.isEnterCacheSearchVC = true
    }

//viewWillTransitionToSize:横竖屏切换。台前调度会走，分屏待确认会不会走，，下面的方法会重新渲染
    // MARK: vc live cycle
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        guard Display.pad else { return }
        guard let searchRootView = searchRootView else { return }
        if self.traitCollection.horizontalSizeClass != .compact {
            //R视图---非分屏样式
            let idealLeftRightSpacing = (self.view.frame.size.width - 750) / 2
            if self.larkSplitViewController?.splitMode != .sideOnly {
                //分栏样式
                searchRootView.snp.updateConstraints { make in
                    make.left.equalToSuperview().offset(12)
                    make.right.equalToSuperview().offset(-12)
                }
            } else if idealLeftRightSpacing > minLeftRightSpacing {
                searchRootView.snp.updateConstraints { make in
                    make.left.equalToSuperview().offset(idealLeftRightSpacing)
                    make.right.equalToSuperview().offset(-idealLeftRightSpacing)
                }
            } else {
                searchRootView.snp.updateConstraints { make in
                    make.left.equalToSuperview().offset(minLeftRightSpacing)
                    make.right.equalToSuperview().offset(-minLeftRightSpacing)
                }
            }
        } else {
            //C视图-分屏样式 ｜ 侧拉样式
            searchRootView.snp.updateConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
            }
        }

        if let searchTopBGView = searchTopBGView, let searchRootViewController = searchRootViewController {
            DispatchQueue.main.async {
                searchTopBGView.snp.updateConstraints { make in
                    make.top.left.right.equalToSuperview()
                    make.height.equalTo(searchRootViewController.getContentContainerY())
                }
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.searchOnPadRootVCDidDisapper(query: self.query)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.searchOnPadRootVCWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.isEnterCacheSearchVC {
            self.isEnterCacheSearchVC = false
            self.searchRootViewController?.enterCacheSearchVC()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.searchOnPadRootVCWillDisapper()
    }

    // MARK: private
    private func setupView() {
        let searchTopBGView = UIView()
        searchTopBGView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(searchTopBGView)
        searchTopBGView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(isNeedShowCapsule ? 116 : 108)
        }
        self.searchTopBGView = searchTopBGView

        addSearchRootVC()
    }

    public func addSearchRootVC() {
        guard let searchRootViewController = makeSearchRootViewController() else { return }
        self.searchRootViewController = searchRootViewController

        guard let searchRootView = searchRootViewController.view else { return }
        self.searchRootView = searchRootView
        view.addSubview(searchRootView)

        addChild(searchRootViewController)
        searchRootView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(minLeftRightSpacing)
            make.right.equalToSuperview().offset(-minLeftRightSpacing)
        }
    }

    public func removeSearchRootVC() {
        if let searchRootVC = self.searchRootViewController as UIViewController? {
            searchRootVC.removeFromParent()
            searchRootVC.view.removeFromSuperview()
            self.searchRootViewController = nil
        }
    }

    private func makeSearchRootViewController() -> SearchRootViewControllerProtocol? {
        let searchSession = SearchSession()
        guard let searchDependency = try?userResolver.resolve(assert: SearchDependency.self) else { return nil }
        let searchRouter: SearchRouter = SearchRouter(userResolver: userResolver, dependency: searchDependency)
        guard let searchAPI = try?userResolver.resolve(assert: SearchAPI.self) else { return nil}
        searchSession.sourceOfSearch = sourceOfSearch
        let searchRootVC: SearchRootViewControllerProtocol
        if isNeedShowCapsule {
            let searchRootContainer = SearchNewRootDependencyContainer(userResolver: userResolver,
                                                                       sourceOfSearch: sourceOfSearch,
                                                                       searchSession: searchSession,
                                                                       router: searchRouter,
                                                                       historyStore: SearchQueryHistoryStore(searchAPI: searchAPI),
                                                                       resolver: userResolver,
                                                                       initQuery: self.searchEnterModel.initQuery,
                                                                       jumpTab: makeSearchTab())
            searchRootVC = searchRootContainer.makeSearchRootViewController()
        } else {
            let searchNavBar = SearchNaviBar(style: .search)
            let searchRootContainer = SearchRootDependencyContainer(userResolver: userResolver,
                                                                    sourceOfSearch: sourceOfSearch,
                                                                    searchSession: searchSession,
                                                                    searchNavBar: searchNavBar,
                                                                    router: searchRouter,
                                                                    historyStore: SearchQueryHistoryStore(searchAPI: searchAPI),
                                                                    initQuery: self.searchEnterModel.initQuery,
                                                                    applinkSource: self.searchEnterModel.appLinkSource ?? "",
                                                                    jumpTab: makeSearchTab())
            searchRootVC = searchRootContainer.makeSearchRootViewController()
        }
        searchRootVC.circleDelegate = self
        return searchRootVC
    }

    private func makeSearchTab() -> SearchTab? {
        guard let jumpTabStr = self.searchEnterModel.jumpTab else {
            switch self.sourceOfSearch {
            case .docs, .wiki: return .doc
            default: return nil
            }
        }
        let jumpTabAction = SearchSectionAction(rawValue: jumpTabStr)
        switch jumpTabAction {
        case .main: return .main
        case .message: return .message
        case .doc, .wiki: return .doc
        case .app: return .app
        case .contacts: return .chatter
        case .group: return .chat
        case .calendar: return .calendar
        case .oncall: return .oncall
        case .slashCommand, .openSearch:
            if let appId = self.searchEnterModel.appId,
               let tabName = self.searchEnterModel.searchTabName {
                return .open(SearchTab.OpenSearch(id: appId, label: tabName, icon: nil, resultType: .customization, filters: []))
            }
            return .main
        default: return .main
        }
    }
}

extension SearchOnPadRootViewController: SearchRootViewControllerCircleDelegate {
    func didTapCancelBtn() {
        self.delegate?.searchOnPadRootVCCancel()
    }

    func searchQueryWhenWillDisappear(query: String?) {
        self.query = query
    }

}

extension SearchOnPadRootViewController: LarkNaviBarProtocol {
    public var titleText: BehaviorRelay<String> { return BehaviorRelay(value: "") }

    public var isNaviBarEnabled: Bool { false }

    public var isDrawerEnabled: Bool { true }
}
