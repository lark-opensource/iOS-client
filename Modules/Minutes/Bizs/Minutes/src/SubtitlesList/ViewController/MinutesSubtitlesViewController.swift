//
//  MinutesSubtitlesViewController.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/12.
//  Copyright © 2021年 wangcong. All rights reserved.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork
import LarkLocalizations
import YYText
import UniverseDesignToast
import UniverseDesignIcon
import EENavigator
import RoundedHUD
import MinutesInterface
import LarkContainer
import LarkAccountInterface
import LarkStorage
import LarkSetting

protocol MinutesSubtitlesViewDelegate: AnyObject {
    func doKeyWordSearch(text: String)
    func didBeginSearchKeywords()
    func translatePullRefreshSuccess()
    func doAddComments()
    func showComments()
    func showNoticeViewForSubtitlesVC()
    func hideNoticeViewForSubtitlesVC()
    func enterSpeakerEdit(finish: @escaping() -> Void)
    func finishSpeakerEdit()

    func showOriginalTextViewBy(subtitle: UIViewController, attributedString: NSAttributedString)

    func showToast(text: String)
    func showRefreshViewBy(subtitle: UIViewController)
    func hideHeaderBy(subtitle: UIViewController)

    func didTappedText(_ startTime: String)
    func didFinishedEdit()
    var selectedType: MinutesPageType { get set }

}

protocol MinutesSubtitlesViewDataProvider: AnyObject {
    func subtitlesViewVisbleHeight() -> CGFloat
    func titleViewVisbleHeight() -> CGFloat
    func videoControlViewHeight() -> CGFloat
    func translationChosenLanguage() -> String
    func isDetailInLandscape() -> Bool
    func isDetailInVideo() -> Bool
    func isDetailInTranslationMode() -> Bool
    func isDetailInSearching() -> Bool
    func currentTranslateLanguage() -> String
    func switchToDetailTab()
}

class MinutesSubtitlesViewController: UIViewController, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    @ScopedProvider var passportUserService: PassportUserService?
    @ScopedProvider var featureGatingService: FeatureGatingService?

    let store = KVStores.udkv(
        space: .global,
        domain: Domain.biz.minutes
    )

    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }

    let serialQueue = DispatchQueue(label: "minutes.subtitle.process.data.queue")

    let serialRangeQueue = DispatchQueue(label: "minutes.subtitle.process.range.queue")

    var isClip: Bool {
        return viewModel.minutes.isClip
    }

    var commentDependency: MinutesCommentDependency?
    var minutesComments: [MinutesCCMComment]? {
        didSet {
            viewModel.ccmComments = minutesComments
            for pVM in viewModel.data {
                pVM.ccmComments = minutesComments
            }
        }
    }
    var commentIndexPath: IndexPath?
    
    var searchWaitingTimer: Timer?
    var viewModel: MinutesSubtitlesViewModel

    var source: MinutesSource?
    var destination: MinutesDestination?

    var searchViewModel: MinutesSearchViewModel?
    var commentsViewModel: MinutesCommentsViewModel?
    weak var dataProvider: MinutesSubtitlesViewDataProvider?

    @RwAtomic
    var viewData: [MinutesParagraphViewModel] = []
    
    var currentPVM: MinutesParagraphViewModel?
    
    weak var delegate: MinutesSubtitlesViewDelegate?
    weak var player: MinutesVideoPlayer?

    var scrollDirectionBlock: ((Bool) -> Void)?
    var lastOffset: CGFloat = 0.0

    var lastAutoScrollOffset: CGFloat = -CGFloat.greatestFiniteMagnitude
    var lastAutoScrollIndexPath: IndexPath = IndexPath(row: NSInteger.min, section: 0)
    var playingIndexPath: IndexPath = IndexPath(row: 0, section: 0)

    var isFirstAllDataReady: Bool = false
    var isFirstAllDataReadyDidReached: Bool = false

    var currentCellIndex: Int?
    var totalIndex: NSInteger = 0
    var searchIndex: NSInteger = -1
    var isDragged: Bool = false
    var isInSearchPage: Bool = false {
        didSet {
            isDragged = false
            if isInSearchPage {
                hideNoticeButton()
            }
        }
    }
    var isInCommentPage: Bool = false {
        didSet {
            isDragged = isInCommentPage
        }
    }
    var isScrollingToRect: Bool = false
    var currentLongPressTextView: YYTextView?

    lazy var searchButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.searchOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16)), for: .normal)
        button.addTarget(self, action: #selector(doSearchButtonClick), for: .touchUpInside)
        return button
    }()

    private lazy var expandButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.downOutlined, iconColor: UIColor.ud.N800, size: CGSize(width: 16, height: 16)), for: .normal)
        button.addTarget(self, action: #selector(expandButtonClick), for: .touchUpInside)
        return button
    }()

    @objc func doSearchButtonClick() {
        delegate?.didBeginSearchKeywords()
    }

    @objc func expandButtonClick() {
        if keywordsView.viewModel.viewStatus == .expand {
            keywordsView.tapShrinkButton()
        } else if keywordsView.viewModel.viewStatus == .shrink {
            keywordsView.tapExpandButton()
        }
    }

    var shouldShownNotice: Bool {
        if !isClip {
            if viewModel.minutes.info.reviewStatus != .normal || (viewModel.minutes.basicInfo?.mediaType != .text && viewModel.minutes.info.noPlayURL) {
                return true
            } else {
                return false
            }
        }
        else {
            return false
        }
    }

    var isEditingSpeaker: Bool = false {
        didSet {
            reloadData()
        }
    }

    var isText: Bool {
        return viewModel.minutes.basicInfo?.mediaType == .text
    }

    var editSession: MinutesEditSession?

    var otherSectionHeight: CGFloat {
        return !shouldShownNotice ? keywordsView.viewHeight : noticeView.viewHeight
    }

    var isFirstLocate: Bool = true

    // Refresh
    let header = MinutesRefreshHeaderAnimator(frame: .zero)

    var isSpeakerRemoveBatchOn: Bool = true
    var localComments: [CommentContext] = []
    var ccmInitMonitorTimer: Timer?
    var ccmMetaDataMonitorTimer: Timer?
    var isCCMInitSuccess: Bool = false
    var isSetMetadataSuccess: Bool = false
    
    lazy var tracker: MinutesTracker = {
        return MinutesTracker(minutes: viewModel.minutes)
    }()

    lazy var searchBar: MinutesSearchBar = {
        let bar = MinutesSearchBar(frame: CGRect(x: 0, y: 0, width: 0, height: 60))
        bar.searchHandler = { [weak self] in
            self?.doSearchButtonClick()
        }
        return bar
    }()

    private lazy var noticeView: MinutesNoticeView = {
        let view = MinutesNoticeView(frame: CGRect(x: 0, y: 0, width: layoutWidth, height: 0), minutes: viewModel.minutes, resolver: userResolver)
        view.delegate = self
        return view
    }()

    lazy var keywordsView: MinutesKeyWordsView = {
        let view = MinutesKeyWordsView(frame: CGRect(x: 0, y: 0, width: layoutWidth - 16 - 88, height: 0), minutes: viewModel.minutes)
        view.viewDelegate = self
        view.viewModel.keywordsViewWidth = layoutWidth - 16 - 88
        return view
    }()

    var tableView: MinutesTableView?

    lazy var upFloatView: MinutesFloatBackView = {
        let fv = MinutesFloatBackView()
        fv.addTarget(self, action: #selector(upToPlayPosition), for: .touchUpInside)
        return fv
    }()

    lazy var downFloatView: MinutesFloatBackView = {
        let fv = MinutesFloatBackView()
        fv.addTarget(self, action: #selector(downToPlayPosition), for: .touchUpInside)
        fv.bottomInset = view.safeAreaInsets.bottom + 24
        return fv
    }()

    var layoutWidth: CGFloat = 0 {
        didSet {
            if abs(layoutWidth - oldValue) > 0.1 && oldValue > 0.01{
                reloadSubtitleLayout()
            }
        }
    }
    
    var isInCCMfg: Bool {
        viewModel.minutes.info.basicInfo?.isInCCMfg == true
    }

    private var isLingoFGEnabled: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .lingoEnabled) == true
    }

    init(resolver: UserResolver, minutes: Minutes) {
        self.userResolver = resolver
        self.viewModel = MinutesSubtitlesViewModel(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeRefreshHeader()
        invaliateSearchWaitingTimer()
        invaliateCCMInitMonitorTimer()
        invaliateCCMMetaDataMonitorTimer()
        MinutesLogger.subtitle.info("subtitle vc deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
   
        if isInCCMfg {
            initCCMModule()
        }
        view.backgroundColor = UIColor.ud.bgBody
        
        tableView = MinutesTableView()
        tableView?.backgroundColor = UIColor.ud.bgBody
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.register(MinutesSubtitleCell.self, forCellReuseIdentifier: MinutesSubtitleCell.description())
        tableView?.register(MinutesSubtitleEmptyCell.self, forCellReuseIdentifier: MinutesSubtitleEmptyCell.description())
        tableView?.register(MinutesSubtitleTransformingCell.self, forCellReuseIdentifier: MinutesSubtitleTransformingCell.description())
        tableView?.register(MinutesSubtitleSkeletonCell.self, forCellReuseIdentifier: MinutesSubtitleSkeletonCell.description())
        tableView?.separatorStyle = .none
        // reload之后offset会变
        tableView?.estimatedRowHeight = 0
        tableView?.estimatedSectionHeaderHeight = 0
        tableView?.estimatedSectionFooterHeight = 0

        if #available(iOS 11.0, *) {
            tableView?.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        tableView?.showsVerticalScrollIndicator = false
        tableView?.showsHorizontalScrollIndicator = false
        if #available(iOS 13.0, *) {
            tableView?.automaticallyAdjustsScrollIndicatorInsets = false
        }
        tableView?.keyboardDismissMode = .onDrag
        tableView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        if let tableView = tableView {
            view.addSubview(tableView)
            tableView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }

        addPlayerCallback()
        addMinutesCallback()
        
        observeEditMenu()

        let pageName = viewModel.minutes.info.isInProcessing ? "pre_detail_page" : "detail_page"
        let isRisk: Bool = viewModel.minutes.info.basicInfo?.isRisk == true
        tracker.tracker(name: .detailView, params: ["page_name": pageName, "is_risky": isRisk])
        
        tracker.tracker(name: .minutesDetailViewDev, params: ["action_name": "finished", "is_error": 0, "token": viewModel.minutes.data.objectToken])
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadSubtitleLayout), name: Notification.ReloadDetail, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadComments(_:)), name: Notification.ReloadComments, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 快速进来又pop出去，新的vc的didload可能在deinit之前调用，导致读取的userdefualts是老的，因此放在这
        savePlayInfo()
    }

    func updateKeywordsData(_ data: MinutesData) {
        if isClip == false {
            keywordsView.viewModel.keywordsViewWidth = layoutWidth - 16 - 88
            keywordsView.configureDataAndUpdate(data)
        }
    }

    func updateSubtitleViewer() {
        self.reloadData()
    }

    func observeEditMenu() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleLongPressRects), name: NSNotification.Name(rawValue: YYTextViewIsInLongPressSelectionRects), object: nil)
    }

    @objc func handleLongPressRects(_ notification: Notification) {
        if let object = notification.object as? [Any], let textView = object.last as? YYTextView {
            if let cur = currentLongPressTextView, textView.tag != cur.tag {
                if let cell = tableView?.cellForRow(at: subtitleIndexPath(cur.tag)) as? MinutesSubtitleCell {
                    cell.hideSelectionDot()
                }
                currentLongPressTextView = textView
            } else {
                currentLongPressTextView = textView
            }
        }
    }

    // 在评论成功的callback之前回来
    private func onCommentsUpdate(_ data: ([String], Bool)) {
        // 翻译状态下不自动更新
        if self.viewModel.isInTranslationMode {
            return
        }

        // 评论更新和highlight更新
        self.setParagraphs(self.viewModel.minutes.data.subtitles,
                           commentsInfo: self.viewModel.minutes.data.paragraphComments,
                           isInTranslationMode: self.viewModel.isInTranslationMode,
                           scrollToFirstWord: false,
                           forceDictRefresh: true,
                           didCompleted: nil)
    }
    
    private func onCommentsUpdateV2(_ data: ([String], Bool)) {
        // 翻译状态下不自动更新
        if self.viewModel.isInTranslationMode {
            return
        }
        
        // 评论更新和highlight更新
        self.setParagraphs(self.viewModel.minutes.data.subtitles,
                           commentsInfo: self.viewModel.minutes.data.paragraphComments,
                           isInTranslationMode: self.viewModel.isInTranslationMode,
                           scrollToFirstWord: false,
                           didCompleted: nil,
                           didCCMCommentCompleted: { [weak self] in
            // 远端更新，由于ccm回调和妙记数据是异步的，需要重新设置一次
            self?.setMetadata()
        })
    }
    
    func addMinutesCallback() {
        viewModel.minutes.data.listeners.addListener(self)
        viewModel.minutes.info.listeners.addListener(self)
    }

    func onRefreshAll(_ objectStatusOldNew: (ObjectStatus, ObjectStatus)) {
        if objectStatusOldNew.0 != .complete, objectStatusOldNew.1 == .complete {
            if viewModel.minutes.info.isInProcessing {
                self.delegate?.showRefreshViewBy(subtitle: self)
                if viewModel.minutes.isClip {
                    topLoadRefresh()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.delegate?.showToast(text: BundleI18n.Minutes.MMWeb_MV_VideoDone)
                    }
                }
            } else if viewData.isEmpty {
                topLoadRefresh()
            } else {
                onRefreshState(true)
            }
        }
    }

    var isInBottom: Bool {
        if let tableView = tableView {
            return ceil(tableView.contentOffset.y) >= ceil(tableView.contentSize.height - tableView.frame.size.height)
        } else {
            return false
        }
    }

    func addPlayerCallback() {
        player?.listeners.addListener(self)
        player?.delegate = self
    }

    func configureHeader() {
        if let tableView = tableView {
            if tableView.header == nil {
                configHeaderRefresh()
            }
        }
    }

    func updateSearchOffset() {
        isDragged = false

        // 子线程
        serialQueue.async {
            let searchIndex = self.searchIndex
            guard let searchViewModel = self.searchViewModel else {
                return
            }
            guard searchViewModel.searchResults.indices.contains(searchIndex) && searchViewModel.timelines.indices.contains(searchIndex) else {
                return
            }

            let info = searchViewModel.searchResults[searchIndex]
            self.viewModel.searchAndMarkSpecifiedRange(with: info)

            let time = searchViewModel.timelines[searchIndex]

            DispatchQueue.main.async {
                // 主线程替换数据
                self.viewData = self.viewModel.data

                // 不依赖player回调
                self.updateSubtitleOffset(time.startTime, index: info.0, isSearch: true, manualTrigger: true, didCompleted: nil)
                self.syncTimeToPlayer(time.startTime, manualOffset: 1)
            }
        }
    }
    
    func setMetadata(_ completion: (() -> Void)? = nil) {
        guard isInCCMfg else { return }
        var filterCCMIds: [String] = []
        if isInCCMfg {
            let localCommentIds = localComments.map({$0.localCommentID})
            
            for pVM in viewModel.data {
                let ids = pVM.commentIDAndRanges.keys
                // 筛选出妙记中包含的评论
                let ccmComments: [MinutesCCMComment] = pVM.ccmComments?.filter({ ids.contains($0.commentID) }) ?? []
                pVM.ccmComments = ccmComments
                
                let ccmCommentIds = ccmComments.map { $0.commentID }
                
                var cids: [(String, NSRange)] = []
                for kv in pVM.commentIDAndRanges {
                    let commentId: String = kv.key
                    let range: NSRange = kv.value
                    if ccmCommentIds.contains(kv.key) == true {
                        cids.append((commentId, range))
                    }
                }
                cids = cids.sorted(by: {$0.1.location < $1.1.location})
                let filterIds: [String] = cids.flatMap({$0.0})
                filterCCMIds.append(contentsOf: filterIds)
            }

            // 存在发送中的id，添加回去
            if let isSendingIDs = viewModel.ccmComments?.filter( { localCommentIds.contains($0.commentUUID) }) {
                let ids: [String] = isSendingIDs.flatMap({$0.commentUUID})
                filterCCMIds.append(contentsOf: ids)
            }
            if filterCCMIds.count > 0 {
                self.isSetMetadataSuccess = true
                self.commentDependency?.setCommentMetadata(commentIds: filterCCMIds)
                MinutesLogger.subtitle.info("[comment sdk] minutes set metadata succeed: \(filterCCMIds.count)")
            } else {
                MinutesLogger.subtitle.error("[comment sdk] minutes filterID is empty, no need to set metadata")
            }
            completion?()
        }
    }
    
    // 刷新评论高亮等一系列元素
    func reloadCCMComment(isFirstRequest: Bool = false, scrollToFirstWord: Bool = false, didCompleted: (() -> Void)? = nil, didCCMCommentCompleted: (() -> Void)? = nil) {
        let paragraphs = viewModel.paragraphs
        let isInTranslationMode = viewModel.isInTranslationMode
        let width = self.layoutWidth

        self.serialQueue.async {
            self.viewModel.calculate(containerWidth: width,
                                 paragraphs: paragraphs,
                                 commentsInfo: self.commentsViewModel?.commentsInfo,
                                 highlightedCommentId: self.commentsViewModel?.highligtedCommentId,
                                     isInTranslationMode: isInTranslationMode, ccmComments: self.minutesComments) {
                [weak self] data, pidAndSentenceDict, sentenceContentLenDict, pidAndIdxDict in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.viewModel.data = data
                    self.viewModel.paragraphs = paragraphs
                    self.viewModel.pidAndSentenceDict = pidAndSentenceDict
                    self.viewModel.sentenceContentLenDict = sentenceContentLenDict
                    self.viewModel.pidAndIdxDict = pidAndIdxDict
                    self.viewModel.isInTranslationMode = isInTranslationMode
                    
                    // 主线程替换数据
                    self.viewData = self.viewModel.data

                    let lastTime = self.player?.lastPlayTime ?? 0.0
                    let ms = Int((lastTime * 1000))
                    if ms != 0 {
                        self.updateSubtitleOffset("\(ms)",
                                                  animated: false,
                                                  isFirstRequest: isFirstRequest,
                                                  didCompleted: didCompleted)
                    } else {
                        if scrollToFirstWord {
                            // 定位到首次说话的位置
                            if let firstVM = self.viewData.first {
                                let firstTime = firstVM.getFirstTime()?[0]
                                self.updateSubtitleOffset(firstTime,

                                                          needScroll: false,
                                                          animated: true,
                                                          isFirstRequest: isFirstRequest,
                                                          didCompleted: didCompleted)
                            }
                        }
                    }
                    
                    self.serialQueue.async {
                        for (idx, pVM) in self.viewData.enumerated() where pVM.commentIDAndRanges.isEmpty == false {
                            
                            let lineCommentsWrapper = MinutesSubtileUtils.rangeCountIn(pVM, ccms: pVM.ccmComments ?? [])
                            pVM.lineCommentsCount = lineCommentsWrapper.0
                            pVM.lineCommentsId = lineCommentsWrapper.1
                            pVM.commentIdLine = lineCommentsWrapper.2
                            pVM.lineHeight = lineCommentsWrapper.3
                        }
                        DispatchQueue.main.async {
                            self.tableView?.reloadData()
                            didCCMCommentCompleted?()
                        }
                    }
                }
            }
        }
    }
    
    
    // isFirstRequest，首个请求，包括分段请求和完整请求，为true，刷新为false
    func setParagraphs(_ paragraphs: [Paragraph],
                       commentsInfo: [String: ParagraphCommentsInfo],
                       isInTranslationMode: Bool,
                       scrollToFirstWord: Bool = true,
                       isFirstRequest: Bool = false,
                       isTranslation: Bool = false,
                       forceDictRefresh: Bool = false,
                       didCompleted: (() -> Void)?,
                       didCCMCommentCompleted: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            if paragraphs.isEmpty {
                self.removeRefreshHeader()
                didCompleted?()
                return
            } else {
                self.configureHeader()
            }

            let width = self.layoutWidth
            // 子线程处理数据，主线程消费数据
            self.serialQueue.async {
                self.commentsViewModel = MinutesCommentsViewModel(minutes: self.viewModel.minutes,
                                                                  commentsInfo: commentsInfo,
                                                                  highligtedCommentId: self.commentsViewModel?.highligtedCommentId,
                                                                  isInTranslationMode: isInTranslationMode)

                self.viewModel.calculate(containerWidth: width,
                                     paragraphs: paragraphs,
                                     commentsInfo: self.commentsViewModel?.commentsInfo,
                                     highlightedCommentId: self.commentsViewModel?.highligtedCommentId,
                                         isInTranslationMode: isInTranslationMode, ccmComments: self.minutesComments) {
                    [weak self] data, pidAndSentenceDict, sentenceContentLenDict, pidAndIdxDict in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.viewModel.data = data
                        self.viewModel.paragraphs = paragraphs
                        self.viewModel.pidAndSentenceDict = pidAndSentenceDict
                        self.viewModel.sentenceContentLenDict = sentenceContentLenDict
                        self.viewModel.pidAndIdxDict = pidAndIdxDict
                        self.viewModel.isInTranslationMode = isInTranslationMode

                        MinutesDetailReciableTracker.shared.finishDataProcess()
                        // 主线程替换数据
                        self.viewData = self.viewModel.data

                        // 首次需要延迟reload，防止计算耗时导致闪动
                        // 非首次，点击先刷新，看到文字标记在滚动
                        if !isFirstRequest {
                            // 刷新UI
                            self.reloadData()
                        }
                        
                        if self.isInCCMfg {
                            self.reloadCCMComment(isFirstRequest: isFirstRequest, scrollToFirstWord: scrollToFirstWord, didCompleted: didCompleted, didCCMCommentCompleted: didCCMCommentCompleted)
                        } else {
                            var lastTime = self.player?.lastPlayTime ?? 0.0
                            if self.isText {
                                lastTime = self.viewModel.lastTextTime ?? 0.0
                            }
                            let ms = Int((lastTime * 1000))
                            MinutesLogger.subtitle.info("first locate: \(ms), \(paragraphs.count), \(self.viewData.count)")
                            if ms != 0 {
                                self.updateSubtitleOffset("\(ms)",
                                                          animated: false,
                                                          isFirstRequest: isFirstRequest,
                                                          isTranslation: isTranslation,
                                                          forceDictRefresh: forceDictRefresh,
                                                          didCompleted: didCompleted)
                            } else {
                                if scrollToFirstWord {
                                    // 定位到首次说话的位置
                                    if let firstVM = self.viewData.first {
                                        let firstTime = firstVM.getFirstTime()?[0]
                                        self.updateSubtitleOffset(firstTime,

                                                                  needScroll: false,
                                                                  animated: true,
                                                                  isFirstRequest: isFirstRequest,
                                                                  didCompleted: didCompleted)
                                    }
                                }
                            }
                        }

                        if case .detailComment(let commentId, let contentId) = self.destination, commentsInfo.keys.count != 0 {
                            self.dataProvider?.switchToDetailTab()
                            self.showCommentsCardVC(highligtedCommentId: commentId, contentId: contentId, needScrollToBottom: true)
                            self.destination = .detail
                        }
                    }
                }
            }
        }
    }
    
    func queryVisibleCellDict() {
        guard isLingoFGEnabled && viewModel.minutes.isLingoOpen else { return }

        guard let visibleIndexPath = tableView?.indexPathsForVisibleRows else { return }
        let playIndexPath = visibleIndexPath.filter({$0.section == playingIndexPath.section})

        let rows = playIndexPath.map({$0.row})

        viewModel.queryDict(rows: rows, completion: { [weak self] in
            self?.reloadData()
        })
    }

    @objc func reloadSubtitleLayout() {
        let paragraphs = (viewModel.isInTranslationMode ? viewModel.minutes.translateData?.subtitles : viewModel.minutes.data.subtitles) ?? []
        self.setParagraphs(paragraphs,
                           commentsInfo: self.viewModel.minutes.data.paragraphComments,
                           isInTranslationMode: self.viewModel.isInTranslationMode,
                           scrollToFirstWord: false,
                           didCompleted: nil)
        self.updateKeywordsData(self.viewModel.minutes.data)
        if viewModel.minutes.data.subtitles.isEmpty { // 解决无文字内容时不展示举报notice
            DispatchQueue.main.async {[weak self] in
                guard let `self` = self else {
                    return
                }
                self.tableView?.reloadData()
            }
        }
    }
    
    @objc func reloadComments(_ notification: Notification) {
        if !viewModel.minutes.data.subtitles.isEmpty {
            guard let subtitles = self.viewModel.isInTranslationMode ? self.viewModel.minutes.translateData?.subtitles : self.viewModel.minutes.data.subtitles else { return }
            guard let commentInfo = notification.object as? [String : ParagraphCommentsInfo] else { return }
            self.setParagraphs(subtitles,
                               commentsInfo: commentInfo,
                               isInTranslationMode: self.viewModel.isInTranslationMode,
                               scrollToFirstWord: false,
                               forceDictRefresh: true,
                               didCompleted: nil)
        }
    }
    
    func reloadData(layoutIfNeeded: Bool = false, ignoreApplicationState: Bool = false) {
//        if !ignoreApplicationState {
//            guard UIApplication.shared.applicationState == .active else { return }
//        }

        if viewModel.minutes.data.keywords.isEmpty {
            if isText {
                tableView?.tableHeaderView = nil
            } else {
                tableView?.tableHeaderView = viewData.isEmpty ? nil : searchBar
            }
         } else {
            tableView?.tableHeaderView = nil
        }
        if isClip {
            tableView?.tableHeaderView = nil
        }

        tableView?.reloadData()
        if layoutIfNeeded {
            // layout right away，不可频繁调用，对流畅性造成影响
            tableView?.layoutIfNeeded()
        }
    }
}

extension MinutesSubtitlesViewController: MinutesDataChangedListener {
    public func onMinutesCommentsUpdate(_ data: ([String], Bool)?) {
        if let data = data {
            onCommentsUpdate(data)
        }
    }
    
    public func onMinutesCommentsUpdateCCM(_ data: ([String], Bool)?) {
        if let data = data {
            onCommentsUpdateV2(data)
        }
    }
}

extension MinutesSubtitlesViewController: MinutesInfoChangedListener {
    
    public func onMinutesInfoObjectStatusUpdate(newStatus: ObjectStatus, oldStatus: ObjectStatus) {
        onRefreshAll((oldStatus, newStatus))
    }
    
    public func onMinutesInfoVersionUpdate(newVersion: Int, oldVersion: Int) {
        if(newVersion != oldVersion) {
            onRefreshState(true)
        }
    }
}

extension MinutesSubtitlesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        if !shouldShownNotice {
            return 2
        } else {
            return 3
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !shouldShownNotice {
            if section == 0 {
                return 1
            } else {
                if !viewModel.isSupportASR {
                    return 1
                }
                if viewData.isEmpty {
                    return 1
                } else {
                    return viewData.count
                }
            }
        } else {
            if section == 0 || section == 1 {
                return 1
            } else {
                if !viewModel.isSupportASR {
                    return 1
                }
                if viewData.isEmpty {
                    return 1
                } else {
                    return viewData.count
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if !shouldShownNotice {
            if indexPath.section == 0 {
                return keywordsView.viewHeight
            } else {
                let emptyHeight = tableView.frame.height - 80
                if !viewModel.isSupportASR {
                    return max(0, emptyHeight)
                }
                if viewData.isEmpty {
                    return max(0, emptyHeight)
                } else {
                    let pVM: MinutesParagraphViewModel = viewData[indexPath.row]
                    if pVM.isSkeletonType {
                        return MinutesSubtitleSkeletonCell.height
                    } else {
                        return viewData[indexPath.row].cellHeight
                    }
                }
            }
        } else {
            if indexPath.section == 0 {
                return noticeView.viewHeight
            } else if indexPath.section == 1 {
                return keywordsView.viewHeight
            } else {
                let emptyHeight = tableView.frame.height - 80
                if !viewModel.isSupportASR {
                    return max(0, emptyHeight)
                }
                if viewData.isEmpty {
                    return max(0, emptyHeight)
                } else {
                    let pVM: MinutesParagraphViewModel = viewData[indexPath.row]
                    if pVM.isSkeletonType {
                        return MinutesSubtitleSkeletonCell.height
                    } else {
                        return viewData[indexPath.row].cellHeight
                    }
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if !shouldShownNotice {
            if indexPath.section == 0 {
                return createKeyWordsCell(tableView, indexPath: indexPath)
            } else {
                if !viewModel.isSupportASR {
                    return createEmtpyCell(tableView, indexPath: indexPath, supportASR: false)
                }
                if viewData.isEmpty {
                    if let objectStatus = viewModel.minutes.info.statusInfo?.objectStatus, objectStatus.minutesIsNeedBashStatus() {
                        return createTransformingCell(tableView, indexPath: indexPath)
                    } else {
                        return createEmtpyCell(tableView, indexPath: indexPath)
                    }
                } else {
                    let pVM: MinutesParagraphViewModel = viewData[indexPath.row]
                    
                    if pVM.isSkeletonType {
                        return createSkeletonCell(tableView, indexPath: indexPath)
                    } else {
                        return createSubtitleCell(tableView, indexPath: indexPath)
                    }
                }
            }
        } else {
            if indexPath.section == 0 {
                return createNoticeCell(tableView, indexPath: indexPath)
           } else if indexPath.section == 1 {
                return createKeyWordsCell(tableView, indexPath: indexPath)
            } else {
                if !viewModel.isSupportASR {
                    return createEmtpyCell(tableView, indexPath: indexPath, supportASR: false)
                }
                if viewData.isEmpty {
                    if let objectStatus = viewModel.minutes.info.statusInfo?.objectStatus, objectStatus.minutesIsNeedBashStatus() {
                        return createTransformingCell(tableView, indexPath: indexPath)
                    } else {
                        return createEmtpyCell(tableView, indexPath: indexPath)
                    }
                } else {
                    let pVM: MinutesParagraphViewModel = viewData[indexPath.row]
                    
                    if pVM.isSkeletonType {
                        return createSkeletonCell(tableView, indexPath: indexPath)
                    } else {
                        return createSubtitleCell(tableView, indexPath: indexPath)
                    }
                }
            }
        }
    }

    func createKeyWordsCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let keywordsCellID = "keywordsCellID"

        var cell = tableView.dequeueReusableCell(withIdentifier: keywordsCellID)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: keywordsCellID)
            cell?.contentView.backgroundColor = UIColor.ud.bgBody
            cell?.selectionStyle = .none
            cell?.contentView.addSubview(keywordsView)

            keywordsView.snp.makeConstraints { (maker) in
                maker.top.equalToSuperview().offset(20)
                maker.bottom.equalToSuperview().offset(-12)
                maker.left.equalToSuperview().offset(16)
                maker.right.equalToSuperview().offset(-88)
    
            }
            
            cell?.contentView.addSubview(searchButton)
            searchButton.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(-16)
                make.top.equalToSuperview().offset(20)
                make.width.equalTo(20)
                make.height.equalTo(20)
            }
            
            cell?.contentView.addSubview(expandButton)
            expandButton.snp.makeConstraints { make in
                make.right.equalTo(searchButton.snp.left).offset(-16)
                make.centerY.equalTo(searchButton)
                make.width.equalTo(20)
                make.height.equalTo(20)
            }
        }
        if keywordsView.viewModel.viewStatus != .hiden {
            searchButton.isHidden = false
            if keywordsView.viewModel.viewStatus == .plain {
                expandButton.isHidden = true
            } else if keywordsView.viewModel.viewStatus == .shrink {
                expandButton.isHidden = false
                expandButton.setImage(UDIcon.getIconByKey(.upOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16)), for: .normal)
            } else {
                expandButton.isHidden = false
                expandButton.setImage(UDIcon.getIconByKey(.downOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16)), for: .normal)
            }
        } else {
            searchButton.isHidden = true
            expandButton.isHidden = true
        }
        return cell!
    }

    func createNoticeCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let noticeCellID = "NoticeCellID"

        var cell = tableView.dequeueReusableCell(withIdentifier: noticeCellID)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: noticeCellID)
            cell?.selectionStyle = .none
            cell?.contentView.backgroundColor = UIColor.ud.bgBody
            cell?.contentView.addSubview(noticeView)
            noticeView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        if let _ = cell {
            if viewModel.minutes.info.noPlayURL {
                let attributedText = NSAttributedString(string: BundleI18n.Minutes.MMWeb_G_ProcessingAudioNothingToPlay,
                                                        attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                                                     NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle])
                noticeView.update(isAlert: true, attributedText: attributedText)
            } else {
                noticeView.updateReviewStatus()
            }
        }
        return cell!
    }

    func createSkeletonCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesSubtitleSkeletonCell.description(), for: indexPath) as? MinutesSubtitleSkeletonCell else {
            return UITableViewCell()
        }
        return cell
    }
    
    // disable-lint: long_function
    func createSubtitleCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesSubtitleCell.description(), for: indexPath) as? MinutesSubtitleCell else {
            return UITableViewCell()
        }
        cell.selectionStyle = .none
        let pVM: MinutesParagraphViewModel = viewData[indexPath.row]
        var showName = true
        if viewModel.minutes.info.isInProcessing && viewModel.minutes.isClip == false {
            showName = false
        }
        cell.configure(pVM, tag: indexPath.row, showName: showName, isClip: isClip)
        cell.isSpeakerEditing = isEditingSpeaker
        cell.didTextTappedBlock = { [weak self] result in
            guard let self = self else { return }
            if self.isText {
                if let startTime = result?.0 { // 毫秒
                    self.updateSubtitleOffset(startTime,
                                              index: indexPath.row,
                                              manualTrigger: false, didCompleted: nil)
                    self.delegate?.didTappedText(startTime)
                    self.handleDict(result: result)
                }

                return
            }
            // 点击之后根据回调来高亮
            if let startTime = result?.0 { // 毫秒
                self.syncTimeToPlayer(startTime, didTappedRow: indexPath.row)
                self.delegate?.didTappedText(startTime)
            }
            self.handleDict(result: result)

            self.upFloatView.hide()
            self.downFloatView.hide()
            self.tracker.tracker(name: .clickButton, params: ["action_name": "progress_bar_change", "from_source": "click_subtitle"])
            self.tracker.tracker(name: .detailClick, params: ["click": "subtitle", "target": "none"])
        }
        cell.menuCommentsBlock = { [weak self] copiedString, selectedRange in
            guard let self = self else { return }
            guard indexPath.row < self.viewData.count else { return }

            self.commentIndexPath = indexPath
            
            if self.isInCCMfg {
                let offsetAndSize = pVM.findOffsetAndSizeInSentence(selectedRange: selectedRange)
                let context = CommentContext(pid: pVM.pid, indexPath: indexPath, quote: copiedString, localCommentID: "", offsetAndSize: offsetAndSize, range: selectedRange)
                self.showAddCommentPanel(context: context)
             
                // 取最新的，数据可能被远端更新
                let pVM = self.viewData[indexPath.row]
                // 同步高亮
                pVM.selectedRange = selectedRange
                self.tableView?.reloadRows(at: [indexPath], with: .none)
                if !self.isInBottom {
                    // 定位到相关位置
                    let offsetY = MinutesSubtileUtils.rangeOffsetIn(self.viewData, row: indexPath.row, range: selectedRange)
                    self.scrollTo(offset: offsetY + self.otherSectionHeight, indexPath: indexPath, didCompleted: nil)
                }
                
            } else {
                // 弹出评论页面
                let offsetAndSize = pVM.findOffsetAndSizeInSentence(selectedRange: selectedRange)
                let info: [String: Any] = [AddCommentsVCParams.isNewComment: true,
                                           AddCommentsVCParams.pid: pVM.pid,
                                           AddCommentsVCParams.quote: copiedString,
                                           AddCommentsVCParams.offsetAndSize: offsetAndSize,
                                           AddCommentsVCParams.selectedRange: selectedRange]
    
                let commentsVC = MinutesAddCommentsViewController(commentsViewModel: self.commentsViewModel, info: info)
                commentsVC.commentSuccessBlock = { [weak self, weak commentsVC] response in
                    guard let self = self else { return }
    
                    self.tracker.tracker(name: .detailClick, params: ["click": "create_comment", "target": "none", "location": "transcript"])
    
                    guard let commentsVC = commentsVC else { return }
    
                    commentsVC.dismissSelf()
    
                    // 子线程处理数据
                    // 本地更新评论数据和highlight信息
                    // 同时paragraphCommentsUpdate也会推送更新，包括评论数据和highlight
                    // 先comment update成功通知，再callback
                    let width = self.view.bounds.width
                    self.serialQueue.async {
                        self.updateCommentAndHighlightInfo(response, indexPath: indexPath, containerWidth: width)
    
                        DispatchQueue.main.async {
                            // 主线程替换数据
                            self.viewData = self.viewModel.data
                            self.showCommentsCardVC(indexPath, response: response, needScrollToBottom: true)
                        }
                    }
                }
                commentsVC.dismissSelfBlock = { [weak self] text in
                    guard let self = self else { return }
                    // 子线程处理数据
                    self.serialQueue.async {
                        self.clearCommentHighlight(indexPath)
                        DispatchQueue.main.async {
                            // 主线程替换数据
                            self.viewData = self.viewModel.data
                            self.tableView?.reloadRows(at: [indexPath], with: .none)
                        }
                    }
                }
                self.present(commentsVC, animated: false, completion: {[weak self]  in
                    self?.delegate?.doAddComments()
                })
    
                self.tracker.tracker(name: .clickButton, params: ["action_name": "create_comment", "route": "transcript"])
            }
        }
        cell.showCommentsBlock = { [weak self] canComment in
            self?.tracker.tracker(name: .clickButton, params: ["action_name": "view_comment", "location": "subtitle"])
            self?.showCommentsCardVC(indexPath, canComment: canComment)
        }
        cell.didTappedComment = { [weak self] (canComment, cid) in
            self?.tracker.tracker(name: .clickButton, params: ["action_name": "view_comment", "location": "subtitle"])
            self?.showNewCommentsCardVC(indexPath, canComment: canComment, cid: cid)
        }
        cell.copySuccessBlock = { [weak self] in
            guard let self = self else { return }
    
            let targetView = self.userResolver.navigator.mainSceneWindow?.fromViewController?.view
            MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_G_CopiedSuccessfully, targetView: targetView)
        }
        cell.menuOriginalBlock = { [weak self] row in
            guard let self = self else { return }
            self.showOriginalTextView(row)
        }

        cell.openProfileBlock = { [weak self] pVM in
            guard let self = self else { return }
            if let pVM = pVM {
                self.editSubtitleProfile(paragraph: pVM.paragraph)
            }
        }
        cell.editSpeakerBlock = { [weak self] paragraph in
            guard let `self` = self else { return }
            self.showEditSpeakerAlert(with: paragraph)
        }
        return cell
    }
    // enable-lint: long_function

    func handleDict(result: (String?, String?, CGPoint?, CGRect?, Phrase?)?) {
        if let phrase = result?.4, let dictId = phrase.dictId {
            MinutesLogger.detail.info("phrase subtitle: \(phrase)")
            self.dependency?.messenger?.showEnterpriseTopic(abbrId: dictId, query: phrase.name)
            self.tracker.tracker(name: .detailClick, params: ["click": "lingo"])
        }
    }

    func createEmtpyCell(_ tableView: UITableView, indexPath: IndexPath, supportASR: Bool = true) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: MinutesSubtitleEmptyCell.description(), for: indexPath)
            as? MinutesSubtitleEmptyCell {
            cell.update(supportASR: supportASR, longMeetingNoContentTips: viewModel.minutes.basicInfo?.longMeetingNoContentTips == true)
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func createTransformingCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: MinutesSubtitleTransformingCell.description(), for: indexPath)
            as? MinutesSubtitleTransformingCell {
            return cell
        } else {
            return UITableViewCell()
        }
    }

    func showOriginalTextView(_ row: NSInteger) {
        let subtitles: [Paragraph] = viewModel.minutes.data.subtitles
        if subtitles.indices.contains(row) {
            let paragraph = subtitles[row]

            var paragraphContent: String = ""
            for sentence in paragraph.sentences {
                for word in sentence.contents {
                    paragraphContent.append(word.content)
                }
            }
            let attributedText = NSMutableAttributedString(string: paragraphContent, attributes: [.foregroundColor: UIColor.ud.textTitle])
            attributedText.yy_font = MinutesSubtitleCell.LayoutContext.yyTextFont
            attributedText.yy_minimumLineHeight = MinutesSubtitleCell.LayoutContext.yyTextLineHeight

            self.delegate?.showOriginalTextViewBy(subtitle: self, attributedString: attributedText)
        }
    }
}

extension MinutesSubtitlesViewController {
    func currentSubtitleCell(withIndex index: Int?) -> MinutesSubtitleCell? {
        guard let row = index else { return nil }
        let section = shouldShownNotice ? 2 : 1
        return tableView?.cellForRow(at: IndexPath(row: row, section: section)) as? MinutesSubtitleCell
    }
    
    func updatePlayingOffset(indexPath: IndexPath) {
        if let commentDependency = commentDependency, commentDependency.isVisiable == false {
            playingIndexPath = indexPath
        } else {
            playingIndexPath = indexPath
        }
    }
    
    func updateLastOffset(indexPath: IndexPath, offset: CGFloat) {
        if let commentDependency = commentDependency, commentDependency.isVisiable == false {
            lastAutoScrollIndexPath = indexPath
            lastAutoScrollOffset = offset
        } else {
            lastAutoScrollIndexPath = indexPath
            lastAutoScrollOffset = offset
        }
    }

    func resetLastOffset() {
        lastAutoScrollOffset = -CGFloat.greatestFiniteMagnitude
        lastAutoScrollIndexPath = IndexPath(row: NSInteger.min, section: 0)
    }

    // disable-lint: long_function
    func updateSubtitleOffset(_ time: String?,        // 播放器的时间，毫秒
                              index: NSInteger? = nil, // 点击和搜索下才不为空
                              isSearch: Bool = false, // 是否是搜索
                              needScroll: Bool = true, // 是否需要滚动
                              manualTrigger: Bool? = false, // 是否是手动触发
                              animated: Bool = true,
                              isFirstRequest: Bool = false, // 是否是首次进来的第一个请求
                              isTranslation: Bool = false,
                              forceDictRefresh: Bool = false,
                              didCompleted: (() -> Void)?) {
        guard let tableView = tableView else {
            return
        }
        // 子线程处理数据
        serialRangeQueue.async {
            guard let time = time else {
                MinutesSubtileUtils.runOnMain {
                    self.reloadData()
                    didCompleted?()
                }
                return
            }

            var result: (MinutesParagraphViewModel?, [[String]]) = MinutesSubtileUtils.findWordRanges(self.viewData, time: time, index: index)

            var matchedVM = result.0
            let allWordsTimes = result.1

            // 如果没有匹配到，则定位到stop time最近的那个点
            if matchedVM == nil {
                let tmp = (TimeInterval(time) ?? 0.0) / 1000
                let tmpShow = tmp.autoFormat()

                let matchedTimes = MinutesSubtileUtils.findLatestWordRanges(with: allWordsTimes, startTime: time)
                let newTime = matchedTimes.first?[0]

                matchedVM = MinutesSubtileUtils.findWordRanges(self.viewData, time: newTime, index: index).0
            } else {
                let tmp = (TimeInterval(time) ?? 0.0) / 1000
                let tmpShow = tmp.autoFormat()
            }
            matchedVM?.playTime = Double(time)
            self.currentPVM = matchedVM

            if self.currentPVM == nil {
                if let firstVM = self.viewData.first,
                    let firstTime = firstVM.getFirstTime()?[0],
                    let firstTimeDouble = Double(firstTime),
                    let timeDouble = Double(time) {

                    // 拖动的位置超过了说话开始的位置，将第一个vm赋给currentVM
                    if firstTimeDouble > timeDouble {
                        var result: (MinutesParagraphViewModel?, [[String]]) = MinutesSubtileUtils.findWordRanges(self.viewData, time: firstTime, index: index)
                        var firstMatchedVM = result.0
                        firstMatchedVM?.playTime = timeDouble
                        self.currentPVM = firstMatchedVM
                        if firstMatchedVM == nil {
                            assertionFailure("fatal error: firstMatchedVM is nil")
                        }
                    }
                } else {
                    // 即使超过了区域，保证完整请求下来的时候可以正确定位
                    if let timeDouble = Double(time) {
                        // 转成秒
                        self.player?.updateLastPlayTime(timeDouble / 1000)
                    }
                    
                    // 首次请求，reload依赖scroll/offset的设置
                    MinutesSubtileUtils.runOnMain {
                        self.reloadData()
                        didCompleted?()
                    }
                    // 重置
                    if manualTrigger == true {
                        self.resetLastOffset()
                    }
                    return
                }
            }
            // 完整请求和拖动请求的顺序不保证，保证每次updateOffset的时候能够拿到最新的进度
            if let playTime = self.currentPVM?.playTime {
                // 转成秒
                self.player?.updateLastPlayTime(playTime / 1000)
            }

            // 主线程刷新
            MinutesSubtileUtils.runOnMain {
                DispatchQueue.main.asyncAfter(deadline: .now()+0.75, execute: {
                    if forceDictRefresh {
                        self.viewModel.clearDictCache()
                    }
                    self.queryVisibleCellDict()
                })

                let pIndex = self.currentPVM?.pIndex
                
                // 是否是首次进来的全量请求
                let isFirstAllDataReady = self.viewModel.minutes.data.isAllDataReady
                self.isFirstAllDataReady = isFirstAllDataReady
                // 首次，全量加载，保持offset不变
                var isFirstSegRequest = isFirstRequest && !isFirstAllDataReady
                var isFirstFullRequest = isFirstRequest && isFirstAllDataReady

                if isFirstFullRequest && self.isFirstAllDataReadyDidReached == false {
                    // 当前第一个cell距离顶部的距离
                    let firstParagraphMinY = self.viewModel.firstLocateHeight()
                    // 当前offset
                    let curOffset = tableView.contentOffset
                    // 距离屏幕顶部距离
                    let offsetToScreen = firstParagraphMinY - curOffset.y
                    // 新的高度
                    let newRectY: CGFloat? = self.viewModel.newLocateHeight()

                    self.reloadData(layoutIfNeeded: true, ignoreApplicationState: true)
                    // 保证offset不变
                    if let newRectY = newRectY {
                        let newOffset = newRectY - offsetToScreen
                        tableView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: false)
                    }

                    self.isFirstAllDataReadyDidReached = true
                    
                    didCompleted?()
                } else {
                    if isFirstSegRequest {
                        // 首次请求的第一个分段请求，处理较耗时，保证定位不跳动，将reload延后
                    } else if !isFirstRequest {
                        // 非首次请求，刷新或者播放过程的跳动
                        if isTranslation {
                            self.reloadData()
                            self.currentCellIndex = pIndex
                            didCompleted?()
                        } else {
                            if let row = self.currentCellIndex, row == pIndex, let cell = self.currentSubtitleCell(withIndex: row) {
                                let pv = self.viewData[row]
                                // 减少频繁reload带来的消耗
                                cell.configure(pv, tag: row, isClip: self.isClip)
                            } else {
                                self.reloadData()
                            }
                            self.currentCellIndex = pIndex
                            didCompleted?()
                        }
                    }
                }
                
                self.updatePlayingOffset(indexPath: self.subtitleIndexPath(self.currentPVM?.pIndex ?? NSInteger.min))
                if manualTrigger == true {
                    // 更新last offset
                    self.updateLastOffset(indexPath: self.subtitleIndexPath(self.currentPVM?.pIndex ?? NSInteger.min), offset: tableView.contentOffset.y)
                }

                guard needScroll == true else {
                    if isFirstRequest {
                        self.reloadData()
                    }
                    didCompleted?()
                    return
                }
                // 播放过程中滚动了（包括下拉刷新），不自动滚动
                guard self.isDragged == false else {
                    if isFirstRequest {
                        self.reloadData()
                    }
                    didCompleted?()
                    return
                }
                self.doScrollIfNeeded(paragraphViewModel: self.currentPVM,
                                      isSearch: isSearch,
                                      manualTrigger: manualTrigger,
                                      animated: animated,
                                      isFirstSegRequest: isFirstSegRequest,
                                      didCompleted: didCompleted)
            }
        }
    }
    // enable-lint: long_function


    func subtitleSection() -> NSInteger {
        if viewData.isEmpty {
            return -1
        }
        return shouldShownNotice ? 2 : 1
    }

    func subtitleIndexPath(_ row: NSInteger) -> IndexPath {
        return IndexPath(row: row, section: subtitleSection())
    }

    func doScrollIfNeeded(paragraphViewModel: MinutesParagraphViewModel?,
                          isSearch: Bool = false,
                          manualTrigger: Bool? = false,
                          animated: Bool = true,
                          isFirstSegRequest: Bool = false,
                          didCompleted: (() -> Void)?) {
        guard let tableView = tableView else {
            return
        }
        guard let paragraphViewModel = paragraphViewModel, let dataProvider = dataProvider else {
            didCompleted?()
            return
        }

        let minOffset: CGFloat = 150
        let tableViewVisibleHeight: CGFloat = dataProvider.subtitlesViewVisbleHeight()
        let indexPath = subtitleIndexPath(paragraphViewModel.pIndex)
        // 高亮位置顶部距离tableview头部的高度,不包含other section
        let totalHeight: CGFloat = MinutesSubtileUtils.highlightedOffsetIn(viewData, pVM: paragraphViewModel, isSearch: isSearch)
        
        var highlightedCellTopOffset: CGFloat = MinutesSubtileUtils.highlightedRowHeaderOffsetIn(viewData, pVM: paragraphViewModel, isSearch: isSearch) + otherSectionHeight
        // 总offset减去别的section的高度，才是真正文字区域的offset
        let sectionContentOffset = tableView.contentOffset.y - otherSectionHeight
       
        if totalHeight < sectionContentOffset {
            // 进度条往前拖，高亮点在屏幕上面
            scrollTo(offset: totalHeight + otherSectionHeight - MinutesSubtitleCell.LayoutContext.specifiedTop,
                     indexPath: indexPath,
                     manualTrigger: manualTrigger,
                     animated: animated,
                     isFirstSegRequest: isFirstSegRequest,
                     didCompleted: didCompleted)
        } else {
            // 高亮位置距离屏幕可见位置顶部的距离：totalHeight - sectionContentOffset
            // 高亮位置距离屏幕底部的距离：屏幕可见位置 - 高亮位置距离屏幕可见位置顶部的距离
            let bottomOffset = tableViewVisibleHeight - (totalHeight - sectionContentOffset)
            // 高亮位置距离底部小于预设值，需要滚动
            if bottomOffset < minOffset {
                // 超长段落，段落本身大于可见区域
                // 1. 滚动到下一行的头部
                // 2. 滚动到高亮区域附近，高亮区域距离顶部的距离为specifiedTop
                if paragraphViewModel.cellHeight > tableViewVisibleHeight {
                    // 获取cell的位置
                    let positionOfCell = tableView.rectForRow(at: indexPath).origin
                    if tableViewVisibleHeight - (totalHeight - positionOfCell.y) > minOffset {
                        // 滚动到下一行的头部
                        scrollTo(indexPath: indexPath, manualTrigger: manualTrigger, animated: animated, isFirstSegRequest: isFirstSegRequest, didCompleted: didCompleted)
                    } else {
                        // 滚动到高亮区域附近，高亮区域距离顶部的距离为specifiedTop
                        var offset = totalHeight + otherSectionHeight - MinutesSubtitleCell.LayoutContext.specifiedTop
                        if offset >= tableView.contentSize.height - tableView.frame.size.height {
                            scrollTo(indexPath: indexPath, manualTrigger: manualTrigger, animated: animated, isFirstSegRequest: isFirstSegRequest, didCompleted: didCompleted)
                        } else {
                            scrollTo(offset: offset, indexPath: indexPath, manualTrigger: manualTrigger, animated: animated, isFirstSegRequest: isFirstSegRequest, didCompleted: didCompleted)
                        }
                    }
                } else {
                    // 会有动画，offset or index？index保证到最后的时候不跳
                    scrollTo(indexPath: indexPath, manualTrigger: manualTrigger, animated: animated, isFirstSegRequest: isFirstSegRequest, didCompleted: didCompleted)
                }
            } else {
                // 高亮位置距离底部大于预设值，无需滚动
                if isFirstSegRequest {
                    MinutesSubtileUtils.runOnMain {
                        self.reloadData()
                    }
                }
                didCompleted?()
            }
        }
    }

    func scrollTo(offset: CGFloat,
                  indexPath: IndexPath,
                  manualTrigger: Bool? = false,
                  forceScroll: Bool = false,
                  animated: Bool = true,
                  isFirstSegRequest: Bool = false,
                  didCompleted: (() -> Void)?) {
        guard let tableView = tableView else {
            return
        }
        MinutesSubtileUtils.runOnMain {
            if isFirstSegRequest {
                self.reloadData(layoutIfNeeded: true)
            }
            
            if forceScroll {
                self.isScrollingToRect = true
                tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.isScrollingToRect = false

                    self.updateLastOffset(indexPath: indexPath, offset: tableView.contentOffset.y)
                    self.updatePlayingOffset(indexPath: indexPath)
                    
                    if isFirstSegRequest {
                        didCompleted?()
                    }
                }
                return
            }

            // manualTrigger true表示是手动触发的，false是播放器自动播放，这个时候要保证始终往下滑动
            if manualTrigger == false, offset < self.lastAutoScrollOffset {
                return
            }
            guard self.isScrollingToRect == false else { return }

            self.isScrollingToRect = true
            if animated == false {
                tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
                self.isScrollingToRect = false
                self.updateLastOffset(indexPath: indexPath, offset: tableView.contentOffset.y)
                self.updatePlayingOffset(indexPath: indexPath)
            
                if isFirstSegRequest {
                    didCompleted?()
                }
            } else {
                tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    self.isScrollingToRect = false

                    self.updateLastOffset(indexPath: indexPath, offset: tableView.contentOffset.y)
                    self.updatePlayingOffset(indexPath: indexPath)
                    
                    if isFirstSegRequest {
                        didCompleted?()
                    }
                }
            }
        }
    }

    func scrollTo(indexPath: IndexPath,
                  manualTrigger: Bool? = false,
                  animated: Bool = true,
                  isFirstSegRequest: Bool = false,
                  didCompleted: (() -> Void)?) {
        guard let tableView = tableView else {
            return
        }
        MinutesSubtileUtils.runOnMain {
            if isFirstSegRequest {
                self.reloadData(layoutIfNeeded: true)
            }
            
            if manualTrigger == false, indexPath.row < self.lastAutoScrollIndexPath.row {
                return
            }
            guard self.isScrollingToRect == false else { return }

            self.isScrollingToRect = true
            if animated == false {
                if tableView.indexPathExists(indexPath: indexPath) {
                    tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                    self.isScrollingToRect = false

                    self.updateLastOffset(indexPath: indexPath, offset: tableView.contentOffset.y)
                    self.updatePlayingOffset(indexPath: indexPath)
                    
                    if isFirstSegRequest {
                        didCompleted?()
                    }
                } else {
                    self.isScrollingToRect = false
                }
            } else {
                if tableView.indexPathExists(indexPath: indexPath) {
                    tableView.scrollToRow(at: indexPath, at: .top, animated: animated)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        self.isScrollingToRect = false

                        self.updateLastOffset(indexPath: indexPath, offset: tableView.contentOffset.y)
                        self.updatePlayingOffset(indexPath: indexPath)
                           
                        if isFirstSegRequest {
                            didCompleted?()
                        }
                    }
                } else {
                    self.isScrollingToRect = false
                }
            }
        }
    }
}

extension MinutesSubtitlesViewController: MinutesNoticeViewDelegate {
    func handleReviewAppealFinished() {
        self.reloadData()
    }
}

