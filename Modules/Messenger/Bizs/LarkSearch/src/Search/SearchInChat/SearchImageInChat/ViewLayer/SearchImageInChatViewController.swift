//
//  SearchImageInChatViewController.swift
//  LarkSearch
//
//  Created by zc09v on 2018/9/10.
//

import UIKit
import Foundation
import LarkUIKit
import RxCocoa
import RxSwift
import UniverseDesignToast
import UniverseDesignTabs
import LarkStorage
import LarkSDKInterface
import LarkSegmentedView
import LarkFeatureGating
import LarkSearchCore
import LarkModel
import MapKit
import LKCommonsLogging
import EENavigator
import LarkCore
import LarkContainer

final class SearchImageInChatViewController: BaseUIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout, TrackInfoRepresentable, UserResolverWrapper {
    private static let logger = Logger.log(SearchImageInChatViewController.self, category: "SearchImageInChatViewController")
    private let loadingFooterIdentifier = "LoadingFooterView"
    private let oneYearNoMoreFooterIdentifier = "OneYearNoMoreFooterView"
    private let overYearNoeMoreFooterIdentifier = "OverYearNoMoreFooterView"
    private let emptyResuableIdentifier = "emptyResuableView"
    private let interitemSpacing: CGFloat = 5
    private let lineSpacing: CGFloat = 5
    private let disposeBag = DisposeBag()
    private let collectionViewMargin: CGFloat = 16
    private let numberImagePerLine: CGFloat = 4
    private let router: SearchInChatRouter
    private let chatId: String
    private var lastQuery: String = ""
    private let chatType: Chat.TypeEnum?
    private let isThreadGroup: Bool?
    private let isMeetingChat: Bool
    private var toastOff: Bool

    private let searchSession: SearchSession
    private(set) var lastestSearchCapture: SearchSession.Captured
    private lazy var searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField {
        return searchWrapper.searchUITextField
    }

    var currentQuery: String { return searchTextField.text ?? "" }

    /// 记录查看更多的动画是不是开始加载了
    var startLoading = false
    /// 记录查看更多的动画所在的index
    var loadingFooterIndex: IndexPath?
    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let itemSize = (self.view.frame.width - 2 * collectionViewMargin - interitemSpacing * (numberImagePerLine - 1)) / numberImagePerLine
        layout.itemSize = CGSize(width: itemSize, height: itemSize)
        layout.minimumInteritemSpacing = interitemSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionHeadersPinToVisibleBounds = true
        layout.headerReferenceSize = CGSize(width: self.view.frame.size.width, height: 50)
        return layout
    }()

    private lazy var imageCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.keyboardDismissMode = .onDrag
        let hearderIndentifier = String(describing: SearchImageInChatCollectionHeader.self)
        collectionView.register(SearchImageInChatCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: hearderIndentifier)
        /// 注册三类footerView
        /// 点击查看更多之后的动画
        collectionView.register(LoadingMoreView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: loadingFooterIdentifier)
        /// 一年内没有更多消息的提示
        collectionView.register(ShowAllHotDataTipView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: oneYearNoMoreFooterIdentifier)
        /// 已经展示全部的提示
        collectionView.register(ShowAllColdDataTipView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: overYearNoeMoreFooterIdentifier)
        /// 注册兜底的空view
        collectionView.register(EmptyResuableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: emptyResuableIdentifier)
        let cellIndentifier = String(describing: SearchImageInChatCollectionCell.self)
        collectionView.register(SearchImageInChatCollectionCell.self, forCellWithReuseIdentifier: cellIndentifier)
        return collectionView
    }()
    private lazy var _initialEmptyDataView: SearhInChatEmptyDataView = SearhInChatEmptyDataView.searchImageStyle()

    private var initialEmptyDataView: SearhInChatEmptyDataView {
        self.view.bringSubviewToFront(_initialEmptyDataView)
        return _initialEmptyDataView
    }

    /// 展示搜索动画，以及一年内无结果页面
    private let _loadingResultView = SearchResultView(tableStyle: .plain)
    private var loadingResultView: SearchResultView {
        self.view.bringSubviewToFront(_loadingResultView)
        return _loadingResultView
    }

    private let viewModel: SearchImageInChatViewModel

    /// 是否还有更多数据
    private var hasMore: Bool?
    /// 指向container控制器，用于透传query
    weak var containerViewController: UIViewController?
    #if DEBUG || INHOUSE || ALPHA
    // debug悬浮按钮
    private let debugButton: ASLFloatingDebugButton
    #endif

    let userResolver: UserResolver
    init(userResolver: UserResolver,
         chatId: String,
         isMeetingChat: Bool,
         messageAPI: MessageAPI,
         chatAPI: ChatAPI,
         router: SearchInChatRouter,
         searchSession: SearchSession,
         searchAPI: SearchAPI,
         chatType: Chat.TypeEnum? = nil,
         isThreadGroup: Bool? = nil) {
        self.userResolver = userResolver
        self.chatId = chatId
        self.isMeetingChat = isMeetingChat
        let repo: SearchInChatResourcePresntable
        if SearchFeatureGatingKey.inChatImageV2.isEnabled {
            repo = SearchInChatResourceRepo(userResolver: userResolver, chatId: chatId, searchSession: searchSession, searchAPI: searchAPI, chatAPI: chatAPI, messageAPI: messageAPI)
        } else {
            repo = GetResourceInChatRepo(chatId: chatId, chatAPI: chatAPI, messageAPI: messageAPI)
        }
        self.viewModel = SearchImageInChatViewModel(repo: repo, chatId: chatId)
        self.router = router
        self.searchSession = searchSession
        self.lastestSearchCapture = searchSession.capture()
        self.chatType = chatType
        self.isThreadGroup = isThreadGroup
        self.toastOff = SearchFeatureGatingKey.searchToastOff.isUserEnabled(userResolver: userResolver)
        #if DEBUG || INHOUSE || ALPHA
        self.debugButton = ASLFloatingDebugButton()
        #endif
        super.init(nibName: nil, bundle: nil)
        viewModel.currentQuery = { [weak self] in
            return self?.searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        _loadingResultView.containerVC = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func listDidAppear() {
        if SearchFeatureGatingKey.inChatCompleteFilter.isEnabled {
            let lastSearchText = searchTextField.text
            searchTextField.text = (self.containerViewController as? SearchInChatContainerViewController)?.searchQueryText ?? ""
            if lastSearchText != searchTextField.text {
                searchTextChanged()
            }
        }
        self.updateItemSizeIfNeeded(size: self.view.bounds.size)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        self.observerViewModel()
        if SearchFeatureGatingKey.inChatCompleteFilter.isEnabled,
           let queryText = (self.containerViewController as? SearchInChatContainerViewController)?.searchQueryText {
            if queryText.isEmpty {
                self.viewModel.fetchInitData()
            } else {
                searchTextField.text = queryText
                searchTextChanged()
            }
        } else {
            self.viewModel.fetchInitData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastestSearchCapture = searchSession.capture()
    }

    func setupViews() {
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(_initialEmptyDataView)
        self.view.addSubview(_loadingResultView)
        if viewModel.enableSearchAbility {
            searchWrapper.searchUITextField.autocorrectionType = .no
            searchWrapper.searchUITextField.placeholder = BundleI18n.LarkSearch.Lark_ASL_SearchPics
            view.addSubview(searchWrapper)
            searchWrapper.snp.makeConstraints({ make in
                make.top.equalToSuperview().offset(8)
                make.left.right.equalToSuperview()
            })
        }
        self.view.addSubview(imageCollectionView)
        #if DEBUG || INHOUSE || ALPHA
        // 初始化时读取默认状态
        self.debugButton.isHidden = !KVStores.SearchDebug.globalStore[KVKeys.SearchDebug.contextIdShow]
        // 之后通过通知传值
        NotificationCenter
            .default
            .addObserver(self,
                         selector: #selector(swittchDebugButton(_:)),
                         name: NSNotification.Name(KVKeys.SearchDebug.contextIdShow.raw),
                         object: nil)
        self.view.addSubview(debugButton)
        viewModel
            .debugDataManager
            .getContextIDDriver()
            .drive(onNext: { [weak self] aslContextID in
                self?.debugButton.updateTitle(ContextID: aslContextID)
            }).disposed(by: disposeBag)
        #endif
        if viewModel.enableSearchAbility {
            imageCollectionView.snp.makeConstraints { (make) in
                make.top.equalTo(searchWrapper.snp.bottom)
                make.bottom.equalToSuperview()
                make.left.equalToSuperview().offset(collectionViewMargin)
                make.right.equalToSuperview().offset(-collectionViewMargin)
            }

            _initialEmptyDataView.snp.makeConstraints { (make) in
                make.top.equalTo(searchWrapper.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
            _loadingResultView.snp.makeConstraints { (make) in
                    make.top.equalTo(searchWrapper.snp.bottom)
                    make.left.right.bottom.equalToSuperview()
            }
            loadingPlaceholderView.snp.makeConstraints {(make) in
                make.top.equalTo(searchWrapper.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
            retryLoadingView.snp.remakeConstraints { (make) in
                make.top.equalTo(searchWrapper.snp.bottom)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            imageCollectionView.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(collectionViewMargin)
                make.right.equalToSuperview().offset(-collectionViewMargin)
                make.top.bottom.equalToSuperview()
            }
            _initialEmptyDataView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }

            _loadingResultView.snp.makeConstraints {(make) in
                make.edges.equalToSuperview()
            }
        }
        retryLoadingView.retryAction = { [weak self] in
            self?.viewModel.fetchInitData()
        }
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
    }

    #if DEBUG || INHOUSE || ALPHA
    @objc
    private func swittchDebugButton(_ notification: Notification) {
        if let isOn = notification.userInfo?["isOn"] as? Bool {
            self.debugButton.isHidden = !isOn
        }
    }
    #endif

    @objc
    private func searchTextChanged() {
        if searchTextField.markedTextRange == nil {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
            self.perform(#selector(search), with: nil, afterDelay: SearchRemoteSettings.shared.searchDebounce)
            /// 发起一次新的请求，开始loading动画
            viewModel.initialStatus.onNext(.initialLoading)
        }
    }

    @objc
    private func search() {
        (self.containerViewController as? SearchInChatContainerViewController)?.searchQueryText = searchTextField.text?.trimmingForSearch() ?? ""
        if let query = searchTextField.text?.trimmingForSearch(), query != lastQuery {
            let param = SearchParam(query: query)
            self.viewModel.search(param: param)
            lastQuery = query
        }
    }

    func observerViewModel() {
        self.viewModel
            .initialStatusDirver
            .drive(onNext: { [weak self] (initialStatus) in
                guard let `self` = self else { return }
                switch initialStatus {
                case .initialLoading:
                    self._loadingResultView.status = .loading
                    self.loadingResultView.isHidden = false
                case .initialFinish:
                    self.loadingResultView.isHidden = true
                    self.updateNoResultView()
                case .initialFailed:
                    self.loadingResultView.isHidden = true
                    self.retryLoadingView.isHidden = false
                }
            }).disposed(by: self.disposeBag)

        self.viewModel
            .tableRefreshDriver
            .drive(onNext: { [weak self] (type) in
                guard let `self` = self else { return }

                if let footerView = self.imageCollectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter,
                                                                               at: self.loadingFooterIndex ?? IndexPath(item: 0, section: 0)),
                    let loadingFooter = footerView as? LoadingMoreView {
                    // 通过 footerView 来访问 footer 视图的属性和方法
                    loadingFooter.stopLoading()
                }
                self.updateNoResultView()
                switch type {
                case .refresh(hasMore: let getHasMore):
                    self.hasMore = getHasMore
                    self.imageCollectionView.reloadData()
                    self.imageCollectionView.layoutIfNeeded()
                case .loadFailed(hasMore: let getHasMore):
                    self.hasMore = getHasMore
                    if !self.toastOff {
                        UDToast.showFailure(with: BundleI18n.LarkSearch.Lark_Legacy_NetworkOrServiceError, on: self.view)
                    }
                }
                if self.hasMore == true {
                    self.imageCollectionView.addBottomLoadMoreView { [weak self] in
                        self?.viewModel.loadMore()
                    }
                } else {
                    self.imageCollectionView.removeBottomLoadMore()
                }
            }).disposed(by: self.disposeBag)
    }

    private func updateNoResultView() {
        if self.viewModel.sectionsDataSource.isEmpty {
            if case .noResultForYear = self.viewModel.coldAndHotTipType {
                self._loadingResultView.status = .noResultForAYear(searchTextField.text ?? "")
                self.loadingResultView.isHidden = false
                self.initialEmptyDataView.isHidden = true
            } else {
                self.loadingResultView.isHidden = true
                self.initialEmptyDataView.isHidden = false
            }
        } else {
            self.initialEmptyDataView.isHidden = true
            self.loadingResultView.isHidden = true
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            self.updateItemSizeIfNeeded(size: size)
        })
    }

    private func updateItemSizeIfNeeded(size: CGSize) {
        let itemWidth = (size.width - 2 * self.collectionViewMargin
            - self.interitemSpacing * (self.numberImagePerLine - 1)) / self.numberImagePerLine
        // 如果宽度未变化 / 计算出的结果不符合预期, 不进行布局更新
        if self.layout.itemSize.width == itemWidth || itemWidth <= 0 { return }
        self.layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        self.layout.headerReferenceSize = CGSize(width: size.width, height: 50)
        self.layout.invalidateLayout()
        self.imageCollectionView.reloadData()
    }
    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.viewModel.sectionsDataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel.resources(section: section).count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        /// 需要出现提示的场景下添加footView， 只有特定场景下最后一个section出现
        if section == collectionView.numberOfSections - 1 {
            if case .oneYearHasNoMore = viewModel.coldAndHotTipType {
                return CGSize(width: collectionView.bounds.width, height: 44)
            } else if case .overYearHasNoMore = viewModel.coldAndHotTipType {
                return CGSize(width: collectionView.bounds.width, height: 44)
            }
        }
        return .zero
    }
    /// 点击展示更多数据时候加载动画
    var activityIndicatorView: UIActivityIndicatorView?
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let hearderIndentifier = String(describing: SearchImageInChatCollectionHeader.self)
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: hearderIndentifier, for: indexPath)
            let section = indexPath.section
            let title = self.viewModel.sectionsDataSource[section]
            (header as? SearchImageInChatCollectionHeader)?.set(text: title)
            return header
        } else if kind == UICollectionView.elementKindSectionFooter {
            /// 三类需要展示的footer
            if case .oneYearHasNoMore = viewModel.coldAndHotTipType {
                if startLoading {
                    startLoading = false
                    if #available(iOS 13.0, *) {
                        let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: loadingFooterIdentifier, for: indexPath)
                        loadingFooterIndex = indexPath
                        (footer as? LoadingMoreView)?.startLoading()
                        return footer
                    }

                } else {
                    let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: oneYearNoMoreFooterIdentifier, for: indexPath)
                    (footer as? ShowAllHotDataTipView)?.buttonTappedHandler = { [weak self] in
                        self?.viewModel.loadMore()
                        self?.startLoading = true
                        self?.imageCollectionView.reloadData()
                    }
                    return footer
                }
            } else if case .overYearHasNoMore = viewModel.coldAndHotTipType {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: overYearNoeMoreFooterIdentifier, for: indexPath)
                return footer
            }

        }
        let defaultView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: emptyResuableIdentifier, for: indexPath)
        return defaultView
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = indexPath.section
        let row = indexPath.row
        let cellIndentifier = String(describing: SearchImageInChatCollectionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIndentifier, for: indexPath)
        if let cell = cell as? SearchImageInChatCollectionCell,
           let resource = self.viewModel.resource(section: section, row: row) {
            cell.set(resource: resource.data, hasPreviewPremission: resource.hasPreviewPremission)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let localChat = self.viewModel.chatAPI.getLocalChat(by: self.chatId) else {
            //此处必须有chat模型，否则后续跳转无法明确是去thread还是会话，且该场景是会话内搜索，chat模型本地预期肯定会有的
            Self.logger.error("miss chat \(self.chatId)")
            return
        }
        let isThread = localChat.chatMode == .threadV2
        SearchTrackUtil.trackClickChatHistoryResults(
            type: .image,
            isThread: isThread,
            isSearchResult: false,
            action: .openImage
        )
        guard let resource = self.viewModel.resource(section: indexPath.section, row: indexPath.row) else { return }
        if resource.hasPreviewPremission == false {
            var alertController: UIViewController
            switch resource.data {
            case .image:
                alertController = SearchNoPermissionPreviewAlert.getAlertViewController(.image)
            case .video:
                alertController = SearchNoPermissionPreviewAlert.getAlertViewController(.video)
            }
            navigator.present(alertController, from: self)
            return
        }
        let cell = collectionView.cellForItem(at: indexPath) as? SearchImageInChatCollectionCell
        let assetInfo = self.viewModel.asset(resource: resource, thumbnail: cell?.imageView)
        let allAssets = self.viewModel.allAssets()

        /// 是否需要跳转文件页面查看 PC 原画视频
        var goToFileForOriginVideo = false
        var resultType: SearchInChatType?
        switch resource.data {
        case .image(let imageSet):
            resultType = .image
        case .video(let mediaContent):
            resultType = .video
            goToFileForOriginVideo = mediaContent.isOriginal
        }
        SearchTrackUtil.trackSearchResultClick(sessionId: lastestSearchCapture.session,
                                               searchLocation: "image",
                                               query: searchTextField.text ?? "",
                                               sceneType: "chat",
                                               filterStatus: .none,
                                               imprID: lastestSearchCapture.imprID,
                                               at: absolutePosInCollection(in: collectionView, at: indexPath),
                                               chatId: chatId,
                                               chatType: chatType,
                                               resultType: resultType,
                                               messageID: resource.messageId,
                                               isThreadGroup: isThreadGroup)
        if goToFileForOriginVideo {
            router.goToFileBrowserForOriginVideo(messageId: resource.messageId, fromVC: self)
        } else if localChat.chatMode == .threadV2 {
            router.assetBrowserViewControllerForThread(
                assets: allAssets,
                currentAsset: assetInfo.asset,
                chat: localChat,
                messageId: resource.messageId,
                threadID: resource.threadID,
                position: resource.messagePosition,
                fromVC: self
            )
        } else {
            router.assetBrowserViewController(assets: allAssets,
                                              currentAsset: assetInfo.asset,
                                              chat: localChat,
                                              messageId: resource.messageId,
                                              position: resource.messagePosition,
                                              fromVC: self)
        }
    }

    public func absolutePosInCollection(in collectionView: UICollectionView, at indexPath: IndexPath) -> Int {
        var pos = 1
        for i in 0..<indexPath.section {
            pos += collectionView.numberOfItems(inSection: i)
        }
        return pos + indexPath.row
    }
}
extension SearchImageInChatViewController: UDTabsListContainerViewDelegate {
    public func listView() -> UIView {
        return view
    }
}
extension SearchImageInChatViewController: SearchFromColdDataDelegate {
    func requestColdData() {
        /// 无结果页面上点击查看更多
        viewModel.loadMore()
        viewModel.initialStatus.onNext(.initialLoading)
    }
}
