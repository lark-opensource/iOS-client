//
//  UniversalRecommendViewModel.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/24.
//

import UIKit
import Foundation
import RustPB
import ServerPB
import LarkSDKInterface
import RxSwift
import LarkSearchCore
import UniverseDesignToast
import EENavigator
import LarkAppLinkSDK
import LarkAlertController
import LarkUIKit
import LKCommonsLogging
import RxCocoa
import LarkSearchFilter
import LarkContainer
import LarkAccountInterface
import LarkTab
import LarkMessengerInterface

protocol UniversalRecommendDelegate: AnyObject {
    func didSelect(history: UniversalRecommendSearchHistory)
    func didSelect(hotword: UniversalRecommendHotword)
    /// callback true to mark success clear
    func clearHistory(callback: @escaping (Bool) -> Void)
}

protocol UniversalRecommendTrackingDelegate: AnyObject {
    func getCaptureId() -> SearchSession.Captured?
}

final class UniversalRecommendViewModel: UniversalRecommendPresentable, UserResolverWrapper {
    static var requestTimeInterval: TimeInterval { return 10 }
    struct Context {
        let session: SearchSession
        let searchContext: SearchViewModelContext
        let tab: SearchTab
    }
    enum Status: Equatable {
        case initial
        case empty
        case result
    }
    private let repo: UniversalRecommendRepo
    private let context: Context
    private let searchVMFactory: SearchSceneConfig
    private let router: SearchRouter

    private var listViewModels: [IndexPath: SearchCellViewModel] = [:]

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         repo: UniversalRecommendRepo,
         context: Context,
         searchVMFactory: SearchSceneConfig,
         router: SearchRouter) {
        self.userResolver = userResolver
        self.repo = repo
        self.context = context
        self.searchVMFactory = searchVMFactory
        self.router = router
    }

    deinit {
        guard let user = (try? userResolver.resolve(assert: PassportUserService.self))?.user else { return }
        RecommendCacheManager.shared.saveSections(sections: self.sections, cacheKey: RecommendCacheKey(tab: self.context.tab, userId: user.userID, tenantId: user.tenant.tenantID))
    }

    private lazy var _requestCapturedSession = context.session.capture()
    private var sections: [UniversalRecommendSection] = [] {
        didSet {
            shouldEnableContainerScrollSubject.onNext(true)
            resultShowTrackManager.captured = captured
            _requestCapturedSession = context.session.capture()
            resultShowTrackManager.searchTimestamp = Int64(Date().timeIntervalSince1970 * 1000)
            if sections.isEmpty {
                _status.accept(.empty)
                goToScrollViewContentOffsetSubject.onNext((.zero, false))
                shouldEnableContainerScrollSubject.onNext(false)
            } else {
                _status.accept(.result)
                reloadData()
            }
        }
    }
    static let logger = Logger.log(UniversalRecommendViewModel.self, category: "LarkSearch.UniversalRecommendViewModel")

    private var _lastRequestTime: TimeInterval?
    private var _status = BehaviorRelay<Status>(value: .initial)
    var status: Driver<Status> {
        return _status.asDriver(onErrorJustReturn: .empty)
    }
    func requestIfNeeded() {
        let currentRequestTime = Date().timeIntervalSince1970
        defer { _lastRequestTime = currentRequestTime }
        if let lastRequestTime = _lastRequestTime, currentRequestTime - lastRequestTime < Self.requestTimeInterval {
            return
        }
        goToScrollViewContentOffsetSubject.onNext((.zero, false))
        var contentWidth = if let currentWidth = currentWidth?() {
            currentWidth
        } else {
            UIDevice.btd_screenWidth()
        }
        repo.getRecommendSection(contentWidth: contentWidth)
            .distinctUntilChanged()
            .drive(onNext: { [weak self] sections in
                self?.sections = sections
            })
            .disposed(by: bag)
    }

    private let bag = DisposeBag()

    // Output
    private let _shouldReloadData = PublishSubject<Void>()
    var shouldReloadData: Observable<Void> {
        return _shouldReloadData.asObservable()
    }

    private let _shouldInsertRows = PublishSubject<(Int, [IndexPath])>()
    var shouldInsertRows: Observable<(Int, [IndexPath])> {
        return _shouldInsertRows.asObservable()
    }

    private let _shouldDeleteRows = PublishSubject<(Int, [IndexPath])>()
    var shouldDeleteRows: Observable<(Int, [IndexPath])> {
        return _shouldDeleteRows.asObservable()
    }

    private let goToScrollViewContentOffsetSubject = PublishSubject<(CGPoint, Bool)?>()
    var goToScrollViewContentOffset: Observable<(CGPoint, Bool)?> {
        return goToScrollViewContentOffsetSubject.asObservable()
    }

    private let shouldChangeFilterStyleSubject = PublishSubject<FilterBarStyle>()
    var shouldChangeFilterStyle: Observable<FilterBarStyle> {
        return shouldChangeFilterStyleSubject.asObservable()
    }

    private let shouldEnableContainerScrollSubject = PublishSubject<Bool>()
    var shouldEnableContainerScroll: Observable<Bool> {
        return shouldEnableContainerScrollSubject.asObservable()
    }

    weak var delegate: UniversalRecommendDelegate?
    weak var trackingDelegate: UniversalRecommendTrackingDelegate?

    var currentWidth: (() -> CGFloat?)?

    var currentVC: (() -> UIViewController?)?

    // 埋点
    private let resultShowTrackManager: SearchResultShowTrackMananger = {
        let manager = SearchResultShowTrackMananger()
        manager.isRecommend = true
        return manager
    }()

    private lazy var captured = context.session.capture()
    func willDisplay(atIndexPath indexPath: IndexPath) {
        guard let currentSection = sections[safe: indexPath.section] else { return }
        switch currentSection {
        case .chip: return
        case .card(let v):
            guard let items = v.itemsByRow[safe: indexPath.row] else { return }
            for item in items {
                resultShowTrackManager.willDisplay(result: item, tags: [v.sectionTag])
            }
        case .list(let v):
            guard let item = v.items[safe: indexPath.row] else { return }
            resultShowTrackManager.willDisplay(result: item, tags: [v.sectionTag])
        }
    }
    func trackShow() {
        var isCache: Bool?
        if let searchOutService = try? self.userResolver.resolve(assert: SearchOuterService.self), searchOutService.enableUseNewSearchEntranceOnPad() {
            isCache = searchOutService.currentIsCacheVC()
        }
        resultShowTrackManager.track(searchLocation: self.context.searchContext.clickInfo?().searchLocation ?? "",
                                     query: "",
                                     sceneType: "main",
                                     session: self.context.session,
                                     filterStatus: .none,
                                     offset: 1,
                                     isCache: isCache)
    }

    // MARK: - Filter Related
    func changeFilterStyle(_ style: FilterBarStyle) {
        shouldChangeFilterStyleSubject.onNext(style)
    }

    private func renewSession() {
        context.session.renewSession()
        captured = context.session.capture()
        resultShowTrackManager.captured = captured
    }

    var numberOfSections: Int {
        return sections.count
    }

    func heightForCell(forIndexPath indexPath: IndexPath) -> CGFloat {
        guard let section = sections[safe: indexPath.section] else { return 0 }
        switch section {
        case .card:
            return UniversalRecommendCardCell.cellHeight
        case .chip: return UniversalRecommendChipCell.cellHeight
        case .list: return UITableView.automaticDimension
        }
    }

    var registeredCellTypes = Set<String>()

    var headerTypes: [UniversalRecommendHeaderProtocol.Type] {
        return [UniversalRecommendChipHeader.self, UniversalRecommendCardHeader.self, UniversalRecommendListHeader.self]
    }

    var footerTypes: [UniversalRecommendFooterProtocol.Type] {
        return [UniversalRecommendChipFooter.self, UniversalRecommendCardFooter.self]
    }

    func headerType(forSection section: Int) -> UniversalRecommendHeaderProtocol.Type? {
        guard let currentSection = sections[safe: section] else { return nil }
        switch currentSection {
        case .chip: return UniversalRecommendChipHeader.self
        case .card: return UniversalRecommendCardHeader.self
        case .list: return UniversalRecommendListHeader.self
        }
    }

    func headerHeight(forSection section: Int) -> CGFloat {
        guard let currentSection = sections[safe: section] else { return 0 }
        switch currentSection {
        case .chip: return 48
        case .card, .list: return 38 + 8 // 38是header中展示内容的高度 8 是section之间的间距
        }
    }

    func footerType(forSection section: Int) -> UniversalRecommendFooterProtocol.Type? {
        guard let currentSection = sections[safe: section] else { return nil }
        switch currentSection {
        case .chip: return UniversalRecommendChipFooter.self
        case .card: return UniversalRecommendCardFooter.self
        case .list: return nil
        }
    }

    func footerHeight(forSection section: Int) -> CGFloat {
        guard let currentSection = sections[safe: section] else { return 0 }
        switch currentSection {
        case .chip: return 6
        case .card: return 10
        case .list: return 0
        }
    }

    func cellType(forIndexPath indexPath: IndexPath) -> SearchCellProtocol.Type? {
        guard let currentSection = sections[safe: indexPath.section] else { return nil }
        switch currentSection {
        case .chip: return UniversalRecommendChipCell.self
        case .card: return UniversalRecommendCardCell.self
        case .list(let v):
            let result = Search.UniversalRecommendResult(base: v.items[indexPath.row], contextID: nil)
            let vm = searchVMFactory.createViewModel(searchResult: result, context: context.searchContext)
            return searchVMFactory.cellType(for: vm)
        }
    }

    func headerViewModel(forSection section: Int) -> UniversalRecommendHeaderPresentable? {
        guard let currentSection = sections[safe: section] else { return nil }
        var isCache: Bool?
        if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        switch currentSection {
        case .list(let v):
            return UniversalRecommendListHeaderViewModel(title: v.title)
        case .card(let v):
            v.didClickFoldButton = { [weak self] in
                guard let `self` = self else { return }
                v.fold()
                var rows = [IndexPath]()
                for i in 1 ..< v.itemsByRow.count {
                    rows.append(IndexPath(row: i, section: section))
                }
                let foldStatus: SearchTrackUtil.RecommendCardFoldStatus = v.isFold ? .fold : .unfold
                SearchTrackUtil.trackRecommendClick(sessionId: self.captured.session,
                                                    searchLocation: self.context.searchContext.clickInfo?().searchLocation ?? "",
                                                    resultType: foldStatus.trackingDescription,
                                                    query: "",
                                                    entityId: nil,
                                                    tag: v.sectionTag,
                                                    position: nil,
                                                    sceneType: "main",
                                                    imprId: self.captured.imprID,
                                                    isCache: isCache)
                if v.isFold {
                    self._shouldDeleteRows.onNext((section, rows))
                } else {
                    self._shouldInsertRows.onNext((section, rows))
                }
            }
            return v.headerViewModel()
        case .chip(let v):
            let header = UniversalRecommendChipHeaderViewModel(title: v.title) { [weak self] in
                self?.delegate?.clearHistory(callback: { [weak self] success in
                    guard let self = self, success else { return }
                    SearchTrackUtil.trackQuickSearchClick(sessionId: self.captured.session,
                                                          imprId: self.captured.imprID,
                                                          searchLocation: self.context.searchContext.clickInfo?().searchLocation ?? "",
                                                          clickType: .delete,
                                                          sceneType: "main",
                                                          isCache: isCache)
                    self.sections.remove(at: section)
                    self.reloadData()
                })
            }
            header.shouldHideClickButton = v.shouldHideClickButton
            return header
        }
    }

    func reloadData() {
        listViewModels = [:]
        _shouldReloadData.onNext(())
    }

    func selectItem(atIndexPath indexPath: IndexPath, from vc: UIViewController) {
        guard let currentSection = sections[safe: indexPath.section] else { return }
        switch currentSection {
        case .list(let v):
            let item = v.items[indexPath.row]
            let viewModel = listViewModel(for: indexPath, item: item)
            var isCache: Bool?
            if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
                isCache = service.currentIsCacheVC()
            }
            SearchTrackUtil.trackRecommendClick(sessionId: _requestCapturedSession.session,
                                                searchLocation: self.context.searchContext.clickInfo?().searchLocation ?? "",
                                                resultType: viewModel.resultTypeInfo,
                                                query: "",
                                                entityId: item.id,
                                                tag: v.sectionTag,
                                                position: indexPath.row + 1,
                                                sceneType: "main",
                                                imprId: self.captured.imprID,
                                                isCache: isCache)
            guard let feedAPI = try? userResolver.resolve(assert: FeedAPI.self) else { return }
            viewModel.peakFeedCard(feedAPI, disposeBag: bag)
            Self.logger.info("[LarkSearch] click recommend result", additionalData: [
                "result type": "\(viewModel.searchResult.type.rawValue)",
                "id": SearchTrackUtil.encrypt(id: viewModel.searchResult.id)])
            _ = viewModel.didSelectCell(from: vc)
            trackShow()
            renewSession()
        default: break
        }
    }

    private func listViewModel(for indexPath: IndexPath, item: UniversalRecommendResult) -> SearchCellViewModel {
        if let viewModel = listViewModels[indexPath] {
            return viewModel
        } else {
            let result = Search.UniversalRecommendResult(base: item, contextID: nil)
            let viewModel = searchVMFactory.createViewModel(searchResult: result, context: context.searchContext)
            listViewModels[indexPath] = viewModel
            return viewModel
        }
    }

    func cellViewModel(forIndexPath indexPath: IndexPath) -> SearchCellPresentable? {
        guard let currentSection = sections[safe: indexPath.section] else { return nil }
        var isCache: Bool?
        if let service = try? self.userResolver.resolve(assert: SearchOuterService.self), service.enableUseNewSearchEntranceOnPad() {
            isCache = service.currentIsCacheVC()
        }
        switch currentSection {
        case .list(let v):
            return listViewModel(for: indexPath, item: v.items[indexPath.row])
        case .card(let v):
            let viewModel = v.cellViewModel(forRow: indexPath.row)
            viewModel.didSelectItem = { [weak self, weak v] index in
                guard let `self` = self, let v = v, let item = v.item(forRow: indexPath.row, index: index) else { return }
                SearchTrackUtil.trackRecommendClick(sessionId: self._requestCapturedSession.session,
                                                    searchLocation: self.context.searchContext.clickInfo?().searchLocation ?? "",
                                                    resultType: item.resultType,
                                                    query: "",
                                                    entityId: item.id,
                                                    tag: v.sectionTag,
                                                    position: indexPath.row * v.itemPerRow + index + 1,
                                                    sceneType: "main",
                                                    imprId: self._requestCapturedSession.imprID,
                                                    isCache: isCache)
                self.selectCardItem(item)
                self.trackShow()
                self.renewSession()
            }
            return viewModel
        case .chip(let v):
            let viewModel = v.cellViewModel(forRow: indexPath.row)
            viewModel.sectionWidth = { [weak v] in
                return v?.lastWidth
            }
            viewModel.didSelectFold = { [weak self, weak v] currentIsFold in
                v?.isFold = !currentIsFold
                self?._shouldReloadData.onNext(())
            }
            viewModel.didSelectItem = { [weak self, weak v] index in
                guard let `self` = self, let item = v?.item(forRow: indexPath.row, index: index) else { return }
                switch item.content {
                case .history(let history):
                    SearchTrackUtil.trackQuickSearchClick(sessionId: self.captured.session,
                                                          imprId: self.captured.imprID,
                                                          searchLocation: self.context.searchContext.clickInfo?().searchLocation ?? "",
                                                          clickType: .history(history.query),
                                                          sceneType: "main",
                                                          isCache: isCache)
                    self.delegate?.didSelect(history: history)
                case .hotword(let hotword): self.delegate?.didSelect(hotword: hotword)
                }
            }
            return viewModel
        }
    }

    func numberOfRows(forSection section: Int) -> Int {
        guard let currentSection = sections[safe: section] else {
            assertionFailure("Search recommand section out of bounds")
            return 0
        }
        switch currentSection {
        case .list(let v):
            return v.numberOfRows
        case .card(let v):
            guard let currentWidth = currentWidth?() else {
                assertionFailure("currentWidth block not implemented")
                return  1
            }
            return v.numberOfRows(withWidth: currentWidth)
        case .chip(let v):
            guard let currentWidth = currentWidth?() else {
                assertionFailure("currentWidth block not implemented")
                return  1
            }
            return v.numberOfRows(withWidth: currentWidth)
        }
    }

    // 跳转
    func selectCardItem(_ item: UniversalRecommendResult) {
        guard let vc = currentVC?() else { return }
        guard let feedAPI = try? userResolver.resolve(assert: FeedAPI.self) else { return }
        item.peakFeedCard(feedAPI, disposeBag: bag)
        switch item.type {
        case .app:
            let appInfo = item.resultMeta.appMeta
            if !appInfo.isAvailable, case let appStoreURL = appInfo.appStoreURL, !appStoreURL.isEmpty {
                self.goToURL(appStoreURL, from: vc)
                return
            }
            var microAppURL: String?
            var h5URL: String?
            var botID: String?
            var localComponentURL: String?
            appInfo.appAbility.forEach { (ability) in
                switch ability {
                case .small:
                    microAppURL = appInfo.appURL
                case .h5:
                    h5URL = appInfo.appURL
                case .bot:
                    botID = appInfo.botID
                case .localComponent:
                    localComponentURL = appInfo.appURL
                @unknown default:
                    assertionFailure("Unknown app ability")
                }
            }
            if let localComponentURL = localComponentURL, !localComponentURL.isEmpty {
                // Then check if can open as a localComponent
                self.goToURL(localComponentURL, from: vc)
            } else if let microAppURL = microAppURL, !microAppURL.isEmpty {
                // First check if can open as a microApp
                self.goToURL(microAppURL, from: vc)
            } else if let h5URL = h5URL, !h5URL.isEmpty {
                // Then check if can open as a H5
                self.goToURL(h5URL, from: vc)
            } else if let botID = botID, !botID.isEmpty {
                // Then check if can open as a bot
                goToBotChat(botID: botID, from: vc)
            } else {
                // Finally, show open in other platforms
                UDToast.showTipsOnScreenCenter(with: BundleI18n.LarkSearch.Lark_Search_AppUnavailableInMobile, on: vc.view)
            }
        case .user:
            let chatterMeta = item.resultMeta.userMeta
            if let searchOuterService = try? self.userResolver.resolve(assert: SearchOuterService.self), searchOuterService.enableUseNewSearchEntranceOnPad() {
                userResolver.navigator.switchTab(Tab.feed.url, from: vc, animated: true) { [weak self] _ in
                    guard let self = self else { return }
                    guard let topVC = self.userResolver.navigator.mainSceneTopMost else { return }
                    if chatterMeta.type == .bot {
                        // 机器人跳转回话
                        goToBotChatWith(chatterMeta: chatterMeta, fromVC: topVC)
                    } else if chatterMeta.type == .ai {
                        router.gotoMyAI(fromVC: topVC)
                    } else if chatterMeta.type == .user {
                        // 普通人跳转会话
                        goToChatWith(chatterMeta: chatterMeta, chatId: chatterMeta.p2PChatID, fromVC: topVC)
                    }
                }
            } else {
                if chatterMeta.type == .bot {
                    // 机器人跳转回话
                    goToBotChatWith(chatterMeta: chatterMeta, fromVC: vc)
                } else if chatterMeta.type == .ai {
                    router.gotoMyAI(fromVC: vc)
                } else if chatterMeta.type == .user {
                    // 普通人跳转会话
                    goToChatWith(chatterMeta: chatterMeta, chatId: chatterMeta.p2PChatID, fromVC: vc)
                }
            }
        default: break
        }
    }

    // App
    private func goToURL(_ url: String, from: UIViewController) {
        if let url = URL(string: url) {
            navigator.pushOrShowDetail(url, context: [FromSceneKey.key: FromScene.global_search.rawValue], from: from)
        } else {
            UDToast.showTipsOnScreenCenter(with: BundleI18n.LarkSearch.Lark_Search_AppUnavailableInMobile, on: from.view)
            AppSearchViewModel.logger.error("[LarkSearch] 无效 url")
        }
    }

    private func goToBotChat(botID: String, from: UIViewController) {
        guard let chatService = try? userResolver.resolve(assert: ChatService.self) else { return }
        UDToast.showLoading(with: "", on: from.view)
        chatService.createP2PChat(userId: botID, isCrypto: false, chatSource: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak from] (chatModel) in
                guard let `self` = self, let from = from else { return }
                self.router.gotoChat(withChat: chatModel, fromVC: from)
                self.renewSession()
                UDToast.removeToast(on: from.view)
            }, onError: { [weak self, weak from] (error) in
                guard self != nil, let from = from else { return }
                AppSearchViewModel.logger.error("[LarkSearch] 点击机器人，创建会话失败", additionalData: ["Bot": botID], error: error)
                UDToast.removeToast(on: from.view)
                UDToast.showFailure(
                    with: BundleI18n.LarkSearch.Lark_Legacy_ProfileDetailCreateSingleChatFailed,
                    on: from.view,
                    error: error
                )

            }, onDisposed: {[weak self, weak from] in
                guard self != nil, let from = from else { return }
                UDToast.removeToast(on: from.view)
            })
            .disposed(by: bag)
    }

    // Chatter
    private func goToChatWith(chatterMeta: ServerPB_Usearch_UserMeta, chatId: String, fromVC: UIViewController) {
        if !chatId.isEmpty {
            router.gotoChat(chatterID: chatterMeta.id, chatId: chatId, fromVC: fromVC, onError: { err in
                if let routerError = err as? RouterError,
                    let apiError = routerError.stack.first(where: { $0.underlyingError is APIError })?.underlyingError as? APIError,
                    case .forbidPutP2PChat(let message) = apiError.type {
                    let alertController = LarkAlertController()
                    alertController.setContent(text: message)
                    alertController.addPrimaryButton(text: BundleI18n.LarkSearch.Lark_Legacy_ApplicationPhoneCallTimeButtonKnow)
                    self.navigator.present(alertController, from: fromVC)
                    self.renewSession()
                }
            }, onCompleted: nil)
        } else {
            guard let chatAPI = try? userResolver.resolve(assert: ChatAPI.self) else { return }
            chatAPI.createP2pChats(uids: [chatterMeta.id])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self, weak fromVC] (chats) in
                    guard let self = self, let chat = chats.first, let fromVC = fromVC else {
                        return
                    }
                    self.router.gotoChat(withChat: chat, fromVC: fromVC)
                    self.renewSession()
                }, onError: { [weak self, weak fromVC] (error) in
                    guard self != nil, let fromVC = fromVC else { return }
                    UDToast.removeToast(on: fromVC.view)
                    UDToast.showFailure(
                        with: BundleI18n.LarkSearch.Lark_Legacy_ProfileDetailCreateSingleChatFailed,
                        on: fromVC.view,
                        error: error
                    )
                })
                .disposed(by: bag)
        }
    }

    private func goToBotChatWith(chatterMeta: ServerPB_Usearch_UserMeta, fromVC: UIViewController) {
        guard chatterMeta.type == .bot else { return }
        guard let chatService = try? userResolver.resolve(assert: ChatService.self) else { return }
        UDToast.showLoading(with: "", on: fromVC.view)
        chatService.createP2PChat(userId: chatterMeta.id, isCrypto: false, chatSource: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak fromVC] (chatModel) in
                guard let `self` = self, let fromVC = fromVC else { return }
                self.router.gotoChat(withChat: chatModel, fromVC: fromVC)
                self.renewSession()
                UDToast.removeToast(on: fromVC.view)
            }, onError: { [weak self, weak fromVC] (error) in
                guard self != nil, let fromVC = fromVC else { return }
                ChatterSearchViewModel.logger.error("点击机器人，创建会话失败", additionalData: ["Bot": chatterMeta.id], error: error)
                UDToast.removeToast(on: fromVC.view)
                UDToast.showFailure(
                    with: BundleI18n.LarkSearch.Lark_Legacy_ProfileDetailCreateSingleChatFailed,
                    on: fromVC.view,
                    error: error
                )
            }, onDisposed: {[weak self, weak fromVC] in
                guard self != nil, let fromVC = fromVC else { return }
                UDToast.removeToast(on: fromVC.view)
            })
            .disposed(by: bag)
    }

    // KeyBinding
    func firstFocusPosition() -> UniversalRecommendViewController.FocusInfo? {
        assert(Thread.isMainThread, "should occur on main thread!")
        for (i, v) in sections.enumerated() {
            if case .recommend = v.contentType {
                return IndexPath(row: 0, section: i)
            }
        }
        return nil
    }

    func canFocus(info: IndexPath) -> Bool {
        if info.section >= 0 && info.section < sections.count {
            switch self.sections[info.section].contentType {
            case .recommend: return true
            default: break
            }
        }
        return false
    }

}
