//
//  SearchOuterServiceImpl.swift
//  LarkSearch
//
//  Created by chenyanjie on 2023/11/10.
//

import Foundation
import LarkMessengerInterface
import LarkContainer
import LarkSDKInterface
import LarkSearchCore
import LarkSplitViewController
import LarkUIKit
import UniverseDesignIcon
import SuiteAppConfig

class SearchOuterServiceImpl: SearchOuterService, SearchOnPadRootViewControllerDelegate {
    let userResolver: UserResolver
    weak var currentRootViewController: SearchRootViewControllerProtocol?
    var searchOnPadRootViewController: SearchOnPadRootViewController?
    var searchEntrenceOnPadView: SearchEntrenceOnPadView?
    var searchSaveTimer: Timer?
    var fromTabURL: URL?
    let edgeBarMinWidth: CGFloat = 76  //iPad 导航栏窄栏宽度
    let edgeSlideMargin: CGFloat = 20  //iPad 非分屏/侧栏状态，搜索页的左右边距最小距离
    let padMaxWidth: CGFloat = 750     //iPad 搜索页最大宽度
    var query: String?
    var searchEnterModel: SearchEnterModel?
    var isCached: Bool?
    var currentChatId: String?  // 消息分栏--展示「x」按钮的消息详情页 chat_id，埋点用
    var isCloseBySelectedEntranceCloseIcon: Bool = false   //是否是位于搜索tab时，点击导航栏输入框的「x」号导致的页面disappear
    lazy var splitVC: SearchSplitViewController = {
        let vc = SearchSplitViewController(supportSingleColumnSetting: true)
        vc.supportSideOnly = true
        vc.supportSecondaryPanGesture = true
        return vc
    }()

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // MARK: SearchOuterService
    func getCurrentSearchPadVC(searchEnterModel: SearchEnterModel) -> UIViewController? {
        guard enableUseNewSearchEntranceOnPad() else { return .init() }
        self.fromTabURL = searchEnterModel.fromTabURL
        guard let sourceOfSearchStr = searchEnterModel.sourceOfSearchStr, let sourceOfSearch = SourceOfSearch(rawValue: sourceOfSearchStr) else { return nil }
        if let searchOnPadRootViewController = searchOnPadRootViewController {
            if sourceOfSearch == .im {
                searchOnPadRootViewController.enterCacheSearchVC()
                self.isCached = true
                self.searchEnterModel = searchEnterModel
                self.fromTabURL = searchEnterModel.fromTabURL
                return splitVC
            }
        }

        clearSplitVC()
        self.searchEnterModel = searchEnterModel
        self.fromTabURL = searchEnterModel.fromTabURL
        self.isCached = false
        searchOnPadRootViewController = SearchOnPadRootViewController(userResolver: self.userResolver,
                                                                      delegate: self,
                                                                      sourceOfSearch: sourceOfSearch,
                                                                      searchEnterModel: searchEnterModel)
        if let searchOnPadRootViewController = searchOnPadRootViewController {
            searchOnPadRootViewController.isLkShowTabBar = false
            let navi: LkNavigationController = LkNavigationController(rootViewController: searchOnPadRootViewController)
            splitVC.setViewController(navi, for: .primary)
            splitVC.setViewController(navi, for: .compact)
            splitVC.updateSplitMode(.sideOnly, animated: false)
            splitVC.defaultVCProvider = { () -> DefaultVCResult in
                return DefaultVCResult(defaultVC: LarkSplitViewController.SplitViewController.DefaultDetailController(), wrap: LkNavigationController.self)
            }
            splitVC.searchSplitVCDelegate = self
        }

        searchOnPadRootViewController?.sourceOfSearch = sourceOfSearch
        self.searchEntrenceOnPadView?.cancelSaveState()
        return splitVC
    }

    func setCurrentSearchRootVC(viewController: UIViewController) {
        guard !SearchFeatureGatingKey.disableInterceptRepeatedVC.isUserEnabled(userResolver: userResolver) else { return }
        if let vc = viewController as? SearchRootViewControllerProtocol {
            currentRootViewController = vc
        }
    }

    func getCurrentSearchRootVCOnWindow() -> UIViewController? {
        guard !SearchFeatureGatingKey.disableInterceptRepeatedVC.isUserEnabled(userResolver: userResolver) else { return nil }
        if let currentRootVC = currentRootViewController,
           currentRootVC.isViewLoaded,
           currentRootVC.view.window != nil {
            return currentRootVC
        }
        return nil
    }

    func getSearchOnPadEntranceView() -> UIView {
        guard enableUseNewSearchEntranceOnPad() else { return .init() }
        if let searchEntrenceOnPadView = searchEntrenceOnPadView {
            //C/R 视图切换时可能会反复调接口添加view，需要保存缓存结果
            return searchEntrenceOnPadView
        }
        searchEntrenceOnPadView = SearchEntrenceOnPadView(userResolver: self.userResolver)
        searchEntrenceOnPadView?.setupView()
        searchEntrenceOnPadView?.delegate = self
        return searchEntrenceOnPadView ?? .init()
    }

    func isCompactStatus() -> Bool {
        guard enableUseNewSearchEntranceOnPad() else { return false }
        return splitVC.isCollapsed
    }

    func isNeedChangeCellLayout() -> Bool {
        guard enableUseNewSearchEntranceOnPad() else { return false }
        //true--分屏 false--全屏
        let isCompactStatus = isCompactStatus()
        let isShowCapsule = SearchFeatureGatingKey.enableIntensionCapsule.isUserEnabled(userResolver: self.userResolver) && !AppConfigManager.shared.leanModeIsOn
        return !isCompactStatus && isShowCapsule
    }

    func changeSelectedState(isSelect: Bool) {
        guard enableUseNewSearchEntranceOnPad() else { return }
        guard let searchEntrenceOnPadView = searchEntrenceOnPadView else { return }
        searchEntrenceOnPadView.changeSelectedState(isSelect: isSelect)
    }

    func closeDetailButton(chatID: String) -> UIButton {
        guard enableUseNewSearchEntranceOnPad() else { return .init() }
        self.currentChatId = chatID
        let closeDetailButton = UIButton()
        closeDetailButton.addTarget(self, action: #selector(closeDetailButtonClicked(sender:)), for: .touchUpInside)
        closeDetailButton.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: -10)
        let image = UDIcon.getIconByKey(.closeOutlined)
        closeDetailButton.setImage(image, for: .normal)
        return closeDetailButton
    }

    func enableUseNewSearchEntranceOnPad() -> Bool {
        guard SearchFeatureGatingKey.enableSearchiPadRedesign.isUserEnabled(userResolver: userResolver) else { return false }
        guard Display.pad else { return false }
        return true
    }

    func enableSearchiPadSpliteMode() -> Bool {
        guard enableUseNewSearchEntranceOnPad() else { return false }
        guard SearchFeatureGatingKey.enableSearchiPadSpliteMode.isUserEnabled(userResolver: userResolver) else { return false }
        return true
    }

    func requestWidthOnPad() -> CGFloat {
        guard enableUseNewSearchEntranceOnPad() else { return 0 }
        ///宽屏/窄屏，最大是750。两遍边距最小20
        let maxScreenSize = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
        let maxSplitVCSize = maxScreenSize - edgeBarMinWidth
        let suitSize = (maxSplitVCSize - edgeSlideMargin * 2) > padMaxWidth ? padMaxWidth : (maxSplitVCSize - edgeSlideMargin * 2)
        return suitSize
    }

    func currentEntryAction() -> SearchEntryAction? {
        guard enableUseNewSearchEntranceOnPad() else { return nil }
        return self.searchEnterModel?.entryAction
    }

    func currentIsCacheVC() -> Bool? {
        guard enableUseNewSearchEntranceOnPad() else { return nil }
        return self.isCached
    }

    @objc private func closeDetailButtonClicked(sender: UIButton) {
        splitVC.removeViewController(for: .secondary)
        splitVC.updateSplitMode(.sideOnly, animated: false)
        let trackInfo: [String: Any] = [
            "chat_id": self.currentChatId ?? "",
            "click": "close"
        ]
        SearchTrackUtil.track("im_chat_component_ipad_click", params: trackInfo)
    }

    // MARK: private
    private func sourceOfSearch(entranceKey: String?) -> SourceOfSearch? {
        guard let key = entranceKey else { return nil }
        switch key {
        case "main": return .workplace//导航栏
        case "conversation": return .workplace//C视图下的消息
        case "appCenter": return .workplace //工作台
        case "todo": return .todo //任务
        case "wiki": return .wiki //知识库
        case "moments": return .moments //字节圈
        case "space": return .docs //云文档
        case "bitable": return .docs //多维表格
        case "contact": return .contact //通讯录
        case "videochat": return .videoChat //视频会议

        default: return nil
        }
    }

    private func clearSplitVC() {
        splitVC.removeViewController(for: .primary)
        splitVC.removeViewController(for: .secondary)
        splitVC.removeViewController(for: .compact)

        self.searchOnPadRootViewController = nil
        self.fromTabURL = nil
        self.searchEnterModel = nil
        self.isCached = nil
    }

    private func clearTimer() {
        searchSaveTimer?.invalidate()
        searchSaveTimer = nil
    }

    // MARK: SearchOnPadRootViewControllerDelegate
    func searchOnPadRootVCDidDisapper(query: String?) {
        self.query = query
    }

    func searchOnPadRootVCWillAppear() {

    }

    func searchOnPadRootVCCancel() {
        guard let fromTabURL = self.fromTabURL else { return }
        userResolver.navigator.switchTab(fromTabURL, from: splitVC)
        SearchTrackUtil.trackSearchCancelClick(click: "function", actionType: "cancel_search", isCache: self.isCached)
    }

    func searchOnPadRootVCWillDisapper() {
        guard let searchEntrenceOnPadView = searchEntrenceOnPadView else { return }
        searchEntrenceOnPadView.changeSelectedState(isSelect: false)
    }
}

extension SearchOuterServiceImpl: SearchEntrenceOnPadViewDelegate {
    func cancelSaveState(isSelected: Bool? = false) {
        if isSelected == true, let fromTabURL = self.fromTabURL {
            isCloseBySelectedEntranceCloseIcon = true
            self.userResolver.navigator.switchTab(fromTabURL, from: splitVC)
        }
        clearSplitVC()
        clearTimer()
    }
}

extension SearchOuterServiceImpl: SearchSplitViewControllerDelegate {
    func searchSplitVCDidDisapper() {
        if isCloseBySelectedEntranceCloseIcon {
            //位于搜索tab下，直接点击导航栏入口的「x」号不用缓存，直接清除
            self.isCloseBySelectedEntranceCloseIcon = false
            return
        }

        clearTimer()

        if query == nil || query.isEmpty {
            //离开搜索页面，空query时，需要关闭打开的消息分栏
            splitVC.removeViewController(for: .secondary)
            splitVC.updateSplitMode(.sideOnly, animated: false)
        }

        let searchSaveTimer = Timer(timeInterval: 60, repeats: false) { [weak self] timer in
            timer.invalidate()
            guard let self = self else { return }
            self.searchSaveTimer = nil
            clearSplitVC()
            self.searchEntrenceOnPadView?.cancelSaveState()
        }
        self.searchSaveTimer = searchSaveTimer
        RunLoop.main.add(searchSaveTimer, forMode: .common)
        self.searchEntrenceOnPadView?.queryTextChange(query: self.query)
    }

    func searchSplitVCWillAppear() {
        clearTimer()
        guard let searchEntrenceOnPadView = searchEntrenceOnPadView else { return }
        searchEntrenceOnPadView.changeSelectedState(isSelect: true)
    }
}
