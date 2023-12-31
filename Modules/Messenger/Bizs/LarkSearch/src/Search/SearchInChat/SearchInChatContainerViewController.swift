//
//  SearchInChatContainerViewController.swift
//  LarkSearch
//
//  Created by zc09v on 2018/8/17.
//

import Foundation
import UIKit
import LarkUIKit
import LarkSDKInterface
import LarkSegmentedView
import RxSwift
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkSearchCore
import LarkSplitViewController
import LarkFeatureGating
import LarkModel
import UniverseDesignTabs
import LarkSearchFilter
import LarkContainer

// 搜索的类型
enum SearchInChatType: String {
    case message, file, doc, wiki, image, url, docWiki, video
}

extension SearchInChatType {
    var trackRepresentation: String {
        switch self {
        case .file, .image, .video: return rawValue
        case .message: return "messages"
        case .docWiki, .doc, .wiki: return "docs"
        case .url: return "link"
        }
    }
}

public protocol TrackInfoRepresentable {
    var currentFilters: [SearchFilter] { get }
    var lastestSearchCapture: SearchSession.Captured { get }
    var currentQuery: String { get }
}

public extension TrackInfoRepresentable {
    var currentFilters: [SearchFilter] { return [] }
    var lastestSearchCapture: SearchSession.Captured { return SearchSession.Captured.mock() }
    var currentQuery: String { return "" }
}

final class SearchInChatContainerViewController: BaseUIViewController, UDTabsListContainerViewDataSource, UDTabsViewDelegate {
    private let chatId: String
    private let chatType: Chat.TypeEnum?
    private let isThreadGroup: Bool? // 会话类型是否为话题群
    private let isMeetingChat: Bool
    private let searchCache: SearchCache
    private let searchAPI: SearchAPI
    private let messageAPI: MessageAPI
    private let chatAPI: ChatAPI
    private let router: SearchInChatRouter
    let userResolver: UserResolver
    private let enableMindnote: Bool
    private let enableBitable: Bool
    private let searchItemTypes: [SearchInChatType]
    private let searchSession = SearchSession()
    private let segmentedView: UDTabsTitleView = {
        let tabs = UDTabsTitleView()
        let config = tabs.getConfig()
        config.isItemSpacingAverageEnabled = false
        config.isTitleColorGradientEnabled = false
        config.titleNormalFont = UIFont.systemFont(ofSize: 14)
        config.titleNormalColor = UIColor.ud.textCaption
        config.titleSelectedFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        config.titleSelectedColor = UIColor.ud.primaryContentDefault
        config.itemSpacing = 12
        config.itemWidthIncrement = 2

        tabs.setConfig(config: config)
        /// 配置指示器
        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        indicator.indicatorCornerRadius = 0
        indicator.indicatorColor = .ud.primaryContentDefault
        tabs.indicators = [indicator]
        return tabs
    }()
    private lazy var listContainerView = UDTabsListContainerView(dataSource: self)

    private lazy var searchMessageViewController = self.generateSearchInChatViewController(searchType: .message)
    private lazy var searchDocWikiViewController = self.generateSearchInChatViewController(searchType: .docWiki)
    private lazy var searchDocViewController = self.generateSearchInChatViewController(searchType: .doc)
    private lazy var searchWikiViewController = self.generateSearchInChatViewController(searchType: .wiki)
    private lazy var searchFileViewController = self.generateSearchInChatViewController(searchType: .file)
    private lazy var searchImageViewController = SearchImageInChatViewController(userResolver: userResolver,
                                                                                 chatId: chatId,
                                                                                 isMeetingChat: isMeetingChat,
                                                                                 messageAPI: messageAPI,
                                                                                 chatAPI: chatAPI,
                                                                                 router: router,
                                                                                 searchSession: searchSession,
                                                                                 searchAPI: searchAPI,
                                                                                 chatType: chatType,
                                                                                 isThreadGroup: isThreadGroup)
    private lazy var searchUrlViewController = self.generateSearchInChatViewController(searchType: .url)

    private var lastVCWidth: CGFloat = 0
    var searchQueryText: String = ""
    private var defaultType: SearchInChatType?

    typealias Child = UDTabsListContainerViewDelegate & TrackInfoRepresentable

    init(userResolver: UserResolver,
         chatId: String,
         chatType: Chat.TypeEnum?,
         isMeetingChat: Bool,
         searchCache: SearchCache,
         searchAPI: SearchAPI,
         messageAPI: MessageAPI,
         chatAPI: ChatAPI,
         router: SearchInChatRouter,
         enableMindnote: Bool,
         enableBitable: Bool,
         searchTypes: [SearchInChatType],
         defaultType: SearchInChatType? = nil,
         isThreadGroup: Bool? = nil) {
        self.userResolver = userResolver
        self.chatId = chatId
        self.chatType = chatType
        self.searchAPI = searchAPI
        self.messageAPI = messageAPI
        self.chatAPI = chatAPI
        self.router = router
        self.isMeetingChat = isMeetingChat
        self.defaultType = defaultType
        self.searchCache = searchCache
        self.enableMindnote = enableMindnote
        self.enableBitable = enableBitable
        self.isThreadGroup = isThreadGroup
        var searchItemTypes = searchTypes
        Feature.on(.searchFilter).apply(on: {}, off: {
            searchItemTypes = searchItemTypes.filter({ (type) -> Bool in
                switch type {
                case .wiki:
                    return false
                default:
                    return true
                }
            })
        })
        self.searchItemTypes = searchItemTypes
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard SearchTrackUtil.enablePostTrack() != false else { return }
        SearchTrackUtil.trackForStableWatcher(domain: "asl_chat_search",
                                              message: "asl_search_enter",
                                              metricParams: [:],
                                              categoryParams: [:])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.title = BundleI18n.LarkSearch.Lark_Legacy_SearchHint
        self.view.backgroundColor = .ud.bgBody

        // Event Tracking
        SearchTrackUtil.trackSearchView(session: searchSession,
                                        searchLocation: (defaultType ?? .message).trackRepresentation,
                                        sceneType: "chat",
                                        chatId: chatId,
                                        chatType: chatType,
                                        isThreadGroup: isThreadGroup,
                                        shouldReportSearchBar: false)

        segmentedView.titles = searchItemTypes.map { title(with: $0) }
        segmentedView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(segmentedView)
        segmentedView.snp.makeConstraints { (make) in
            make.top.right.equalToSuperview()
            make.left.equalToSuperview().inset(8)
            make.height.equalTo(40)
        }
        segmentedView.delegate = self

        let dividerView = UIView()
        dividerView.backgroundColor = .ud.lineDividerDefault
        view.addSubview(dividerView)
        dividerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalTo(segmentedView.snp.bottom)
        }

        segmentedView.listContainer = listContainerView
        view.addSubview(listContainerView)
        listContainerView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.top.equalTo(segmentedView.snp.bottom)
        }
        if let defaultType = defaultType, let index = searchItemTypes.firstIndex(of: defaultType) {
            segmentedView.defaultSelectedIndex = index
            lastIndex = index
        }

        _ = searchItemTypes.map { viewController(with: $0) }

        lastVCWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let viewWidth = self.navigationController?.view.bounds.size.width ?? self.view.bounds.size.width
        if lastVCWidth != viewWidth {
            lastVCWidth = viewWidth
            segmentedView.reloadData()
        }
    }

    func title(with type: SearchInChatType) -> String {
        switch type {
        case .message:
            return BundleI18n.LarkSearch.Lark_Legacy_MessageFragmentTitle
        case .doc, .docWiki:
            return BundleI18n.LarkSearch.Lark_Legacy_DocFragmentTitle
        case .wiki:
            return BundleI18n.LarkSearch.Lark_Search_Wiki
        case .file:
            return BundleI18n.LarkSearch.Lark_Legacy_FileFragmentTitle
        case .image, .video:
            return BundleI18n.LarkSearch.Lark_Search_Media
        case .url:
            return BundleI18n.LarkSearch.Lark_Search_Link
        }
    }

    func viewController(with type: SearchInChatType) -> Child {
        switch type {
        case .message: return searchMessageViewController
        case .docWiki: return searchDocWikiViewController
        case .doc:     return searchDocViewController
        case .wiki:    return searchWikiViewController
        case .file:    return searchFileViewController
        case .image, .video:
            searchImageViewController.containerViewController = self
            return searchImageViewController
        case .url:     return searchUrlViewController
        }
    }

    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return searchItemTypes.count
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView, initListAt index: Int) -> UDTabsListContainerViewDelegate {
        let type = searchItemTypes[index]
        return viewController(with: type)
    }

    var lastIndex: Int?
    public func tabsView(_ segmentedView: UDTabsView, didSelectedItemAt index: Int) {
        let type = searchItemTypes[index]
        let child = viewController(with: type)
        if SearchTrackUtil.enablePostTrack() != false, lastIndex == nil {
            lastIndex = 0
        }
        defer {
            lastIndex = index
        }
        if let last = lastIndex, last < searchItemTypes.count, index < searchItemTypes.count, index != last {
            let lastChild = viewController(with: searchItemTypes[last])
            SearchTrackUtil.trackTabClick(
                searchLocation: searchItemTypes[last].trackRepresentation,
                tabName: searchItemTypes[index].trackRepresentation,
                query: child.currentQuery,
                sceneType: "chat",
                tabTrackInfo: lastChild,
                slashIds: [],
                chatId: chatId,
                chatType: chatType,
                isThreadGroup: isThreadGroup
            )
            if SearchTrackUtil.enablePostTrack() != false {
                SearchTrackUtil.trackForStableWatcher(domain: "asl_chat_search",
                                                      message: "asl_search_enter_tab",
                                                      metricParams: [:],
                                                      categoryParams: ["tab_name": searchItemTypes[index].trackRepresentation])
            }
        }
    }

    func scrollViewClass(in listContainerView: JXSegmentedListContainerView) -> AnyClass? {
        return SearchInChatScrollView.self
    }
}

extension SearchInChatContainerViewController {
    func generateSearchInChatViewController(searchType: SearchInChatType) -> SearchInChatViewController {
        guard let vcConfig = searchType.getVCConfig(userResolver: userResolver) else { fatalError("Should never go here") }
        let tabVC = SearchInChatViewController(userResolver: userResolver,
                                               config: vcConfig,
                                               chatId: chatId,
                                               chatType: chatType,
                                               searchSession: searchSession,
                                               searchCache: searchCache,
                                               isMeetingChat: isMeetingChat,
                                               searchAPI: searchAPI,
                                               chatAPI: chatAPI,
                                               router: router,
                                               enableMindnote: enableMindnote,
                                               enableBitable: enableBitable,
                                               isThreadGroup: isThreadGroup)

        tabVC.containerViewController = self
        return tabVC
    }
}

final class SearchInChatScrollView: UIScrollView {
    // If a UIScrollView has a UITextField as its subview and when the UITextfield becomes first responder,
    // it will scroll automatically. To prevent this, override the method below.
    // For more discussion, see https://stackoverflow.com/questions/4585718/disable-uiscrollview-scrolling-when-uitextfield-becomes-first-responder
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) { }
}

extension SearchInChatType {
    func getVCConfig(userResolver: UserResolver) -> SearchInChatVCConifg? {
        switch self {
        case .message:
            return SearchInChatVCConifg(type: .message,
                                        searchWhenEmpty: false,
                                        defaultDataSearchScene: nil,
                                        placeHolderType: .noMessageLog,
                                        placeHolderText: BundleI18n.LarkSearch.Lark_Legacy_SearchMarkTips,
                                        searchScene: .searchMessages,
                                        supportedFilters: [.chatter(mode: .unlimited, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false),
                                                           .date(date: nil, source: .message)],
                                        cellType: SearchMessageInChatTableViewCell.self)
        case .docWiki:
            var supportedFilters: [SearchFilter]
            if SearchFeatureGatingKey.inChatCompleteFilter.isEnabled {
                supportedFilters = [.chatter(mode: .unlimited, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false),
                                    .docFormat([], .inChat)]
            } else {
                supportedFilters = [.docCreator([], userResolver.userID), .docFormat([], .inChat)]
            }
            return SearchInChatVCConifg(type: .docWiki,
                                        searchWhenEmpty: true,
                                        defaultDataSearchScene: .pullDocsWikiInChatScene,
                                        placeHolderType: .noCloudFile,
                                        placeHolderText: BundleI18n.LarkSearch.Lark_Legacy_PullEmptyResult,
                                        searchScene: .searchDocsWikiInChatScene,
                                        supportedFilters: supportedFilters,
                                        cellType: SearchDocInChatTableViewCell.self)
        case .doc:
            var supportedFilters: [SearchFilter]
            if SearchFeatureGatingKey.inChatCompleteFilter.isEnabled {
                supportedFilters = [.chatter(mode: .unlimited, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false),
                                    .docFormat([], .inChat)]
            } else {
                supportedFilters = [.docCreator([], userResolver.userID), .docFormat([], .inChat)]
            }
            return SearchInChatVCConifg(type: .doc,
                                        searchWhenEmpty: true,
                                        defaultDataSearchScene: .getDocsInChatScene,
                                        placeHolderType: .noCloudFile,
                                        placeHolderText: BundleI18n.LarkSearch.Lark_Legacy_PullEmptyResult,
                                        searchScene: .searchDocsInChatScene,
                                        supportedFilters: supportedFilters,
                                        cellType: SearchDocInChatTableViewCell.self)
        case .file:
            var supportedFilters: [SearchFilter]
            if SearchFeatureGatingKey.inChatCompleteFilter.isEnabled {
                supportedFilters = [.chatter(mode: .unlimited, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false),
                                    .date(date: nil, source: .message)]
            } else {
                supportedFilters = []
            }
            return SearchInChatVCConifg(type: .file,
                                        searchWhenEmpty: true,
                                        defaultDataSearchScene: .searchFileScene,
                                        placeHolderType: .noFile,
                                        placeHolderText: BundleI18n.LarkSearch.Lark_Legacy_PullEmptyResult,
                                        searchScene: .searchFileScene,
                                        supportedFilters: supportedFilters,
                                        cellType: SearchFileInChatTableViewCell.self)
        case .image, .video:
            break
        case .url:
            var supportedFilters: [SearchFilter]
            if SearchFeatureGatingKey.inChatCompleteFilter.isEnabled {
                supportedFilters = [.chatter(mode: .unlimited, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false),
                                    .date(date: nil, source: .message)]
            } else {
                supportedFilters = []
            }
            return SearchInChatVCConifg(type: .url,
                                        searchWhenEmpty: true,
                                        defaultDataSearchScene: .searchLinkScene,
                                        placeHolderType: .noURL,
                                        placeHolderText: BundleI18n.LarkSearch.Lark_Legacy_PullEmptyResult,
                                        searchScene: .searchLinkScene,
                                        supportedFilters: supportedFilters,
                                        cellType: SearchURLInChatTableViewCell.self)
        case .wiki:
            var supportedFilters: [SearchFilter]
            if SearchFeatureGatingKey.inChatCompleteFilter.isEnabled {
                supportedFilters = [.chatter(mode: .unlimited, picker: [], recommends: [], fromType: .user, isRecommendResultSelected: false)]
            } else {
                supportedFilters = [.wikiCreator([])]
            }
            return SearchInChatVCConifg(type: .wiki,
                                        searchWhenEmpty: true,
                                        defaultDataSearchScene: .searchWikiInChatScene,
                                        placeHolderType: .noWiki,
                                        placeHolderText: BundleI18n.LarkSearch.Lark_Legacy_PullEmptyResult,
                                        searchScene: .searchWikiInChatScene,
                                        supportedFilters: supportedFilters,
                                        cellType: SearchWikiInChatTableViewCell.self)
        }
        return nil
    }
}
