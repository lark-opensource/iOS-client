//
//  MinutesDetailViewController.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import EENavigator
import YYText
import UniverseDesignToast
import UniverseDesignIcon
import UniverseDesignTabs
import RoundedHUD
import LarkFeatureGating
import LarkContainer
import UIKit
import MinutesInterface
import LarkContainer
import LarkGuide
import LarkSetting
import LarkUIKit
import FigmaKit

extension PagingListContainerView: UDTabsViewListContainer {
}

public extension Notification {
    public static let minutesSummaryContentUpdated = Notification.Name("Minutes.Summary.Content.Updated")

    struct MinutesSummary {
        public static let objectToken = "minutes.summary.object.token"
    }
}

enum MinutesDetailType {
    case phone
    case padLeft
    case padRight
}

protocol MinutesDetailViewControllerDelegate: AnyObject {
    func didClickMore()
    func didClickChooseLanguage()
    func translationDidExit()
    var containerView: UIView { get }
}

public final class MinutesDetailViewController: UIViewController, UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver
    @ScopedProvider var guideService: NewGuideService?
    @ScopedProvider var featureGatingService: FeatureGatingService?

    private var isSummaryViewControllerEnable: Bool {
        return viewModel.minutes.basicInfo?.isAiAnalystSummary == true && featureGatingService?.staticFeatureGatingValue(with: .aiSummaryVisible) == true
    }

    var lastTab: MinutesPageType?
    var lastTabStartTime: Date?

    var source: MinutesSource?
    var destination: MinutesDestination?

    var onClickBackButton: (() -> Void)?

    var auroraView: AuroraView?
    
    lazy var pagingView: MinutesPagingView = {
        let view = MinutesPagingView(delegate: self)
        addChild(view.listContainerView.containerVC)
        return view
    }()

//    lazy var searchButton: UIButton = {
//        let button = UIButton(type: .custom)
//        button.setImage(UDIcon.getIconByKey(.searchOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 18, height: 18)), for: .normal)
//        button.addTarget(self, action: #selector(doSearchButtonClick), for: .touchUpInside)
//        return button
//    }()

    lazy var segmentedView: UDTabsTitleView = {
        let tabsView = UDTabsTitleView()
        let config = tabsView.getConfig()
        config.itemSpacing = 24
        config.contentEdgeInsetLeft = 18
        config.contentEdgeInsetRight = 18
        config.isItemSpacingAverageEnabled = false

        let indicator = UDTabsIndicatorLineView()
        indicator.indicatorHeight = 2
        tabsView.indicators = [indicator]
        tabsView.setConfig(config: config)
        tabsView.backgroundColor = UIColor.ud.bgBody
        tabsView.delegate = self

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        tabsView.addSubview(line)
        line.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

//        tabsView.addSubview(searchButton)
//        searchButton.snp.makeConstraints { make in
//            make.right.equalToSuperview().offset(-10)
//            make.width.height.equalTo(30)
//            make.centerY.equalToSuperview()
//        }

        return tabsView
    }()

    var titleViewHeight: CGFloat = 96
    var segmentHeight: Int {
        detailType == .phone ? 40 : 48
    }

    var videoHeight: CGFloat = 211

    let videoPlayer: MinutesVideoPlayer

    var isInLandScape = false {
        didSet {
            InnoPerfMonitor.shared.update(extra: ["isInLandScape": isInLandScape])
        }
    }


    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }

    var scrollDirection: Bool?

    var titles: [String] = []

    /// 分组讨论 - 智能纪要 - 文字记录 - 基本信息
    var types: [MinutesPageType] = []
    var subViewControllers: [UIViewController] = []
    var pages: [MinutesDetailPage] = []
    var selectedType: MinutesPageType = .summary
    var detailType: MinutesDetailType = .phone

    var currentTranslationChosenLanguage: Language = .default {
        didSet {
            InnoPerfMonitor.shared.update(extra: ["isInTranslationMode": isInTranslationMode])
        }
    }

    var isInTranslationMode: Bool {
        return currentTranslationChosenLanguage != .default
    }

    weak var originalTextView: MinutesOriginalTextView?

    var isEditingSpeaker: Bool = false {
        didSet {
            if isEditingSpeaker {
                self.selectItem(with: .text)
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+0.35, execute: {
                self.subtitlesViewController?.isEditingSpeaker = self.isEditingSpeaker
                self.navigationBar.isEditing = self.isEditingSpeaker
                if self.isEditingSpeaker {
                    self.subtitlesViewController?.editSession = self.viewModel.editSession
                    self.navigationBar.isHidden = false
                } else {
                    self.viewModel.editSession = nil
                    self.subtitlesViewController?.editSession = nil
                    self.navigationBar.isHidden = self.isVideo
                }
                if self.detailType != .padRight {
                    self.videoView?.miniControllBar.isEditSpeaker = self.isEditingSpeaker
                }
                self.adjustHeaderIfNeeded()
                self.parent?.setNeedsStatusBarAppearanceUpdate()
            })
        }
    }

    private lazy var titleView: MinutesDetailTitleView = {
        let v = MinutesDetailTitleView()
        v.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: titleViewHeight)
        return v
    }()

    lazy var videoViewBackground: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: videoViewHeight))
        view.backgroundColor = .black
        return view
    }()

    var videoView: MinutesVideoView?

    var refreshNotice: MinutesRefreshNoticeView?

    // 音频
    lazy var videoControlView: MinutesVideoControlPannel = {
        let view = MinutesVideoControlPannel(resolver: userResolver, player: videoPlayer, isInCCMfg:  viewModel.minutes.basicInfo?.isInCCMfg == true)
        view.clickMoreHandler = { [weak self] in
            self?.delegate?.didClickMore()
        }
        return view
    }()

    // 纯转录
    var transcriptProgressBar: MinutesTranscriptProgressBar?

    lazy var searchView: MinutesSearchView = {
        let view = MinutesSearchView(frame: .zero, minutes: viewModel.minutes)
        view.delegate = self
        view.dataProvider = subtitlesViewController
        view.isVideo = isVideo
        view.isHidden = true
        view.detailBottomInset = detailBottomInset
        return view
    }()

    lazy var transcriptView: MinutesTranscriptView = {
        let v = MinutesTranscriptView()
        if let bar = transcriptProgressBar {
            v.setProgressBar(bar)
        }
        return v
    }()

    var subtitlesViewController: MinutesSubtitlesViewController?

    var infoViewController: MinutesInfoViewController?

    var speakerController: MinutesSpeakersViewController?

    var chapterController: MinutesChapterViewController?

    var summaryViewController: MinutesSummaryViewController?

    lazy var navigationBar: MinutesDetailViewNavigationBar = {
        let bar = MinutesDetailViewNavigationBar(frame: .zero)
        bar.delegate = self
        return bar
    }()

    private lazy var noticeButton: MinutesNoticeVisualButton = {
        let view = MinutesNoticeVisualButton(frame: .zero)
        return view
    }()

    lazy var exitTranslateView: MinutesExitTranslationView = {
        let exitTranslateView = MinutesExitTranslationView()
        exitTranslateView.setLanguage(currentTranslationChosenLanguage.name)
        exitTranslateView.selectLanguageBlock = { [weak self] in
            self?.delegate?.didClickChooseLanguage()
        }
        exitTranslateView.exitTranslateBlock = { [weak self] in
            self?.exitTranlation()
        }
        exitTranslateView.isHidden = true
        return exitTranslateView
    }()

    var viewModel: MinutesDetailViewModel
    let tracker: MinutesTracker

    var isSearching: Bool {
        return searchView.superview != nil
    }

    var isVideo: Bool {
        return !(videoPlayer.isAudioOnly)
    }

    var isText: Bool {
        return viewModel.minutes.basicInfo?.mediaType == .text
    }

    var videoViewHeight: CGFloat {
        switch detailType {
            case .phone:
                return videoHeight + view.safeAreaInsets.top
            case .padLeft:
                return videoHeight
            case .padRight:
                return 0
        }
    }

    var videoOriginY: CGFloat {
        switch detailType {
            case .phone:
                return view.safeAreaInsets.top
            case .padLeft, .padRight:
                return 0
        }
    }

    private var videoBottomOffset: CGFloat {
        return 0
    }

    var videoDuration: Int = 0 {
        didSet {
            if oldValue != videoDuration {
                setupReactionInfo()
            }
        }
    }

    var shouldShowCommentTip: Bool = true {
        didSet {
            updateReactionInfo(reactionsInfo)
        }
    }

    var reactionsInfo: [ReactionInfo] = []

    var isFirstLoad = true

    let limitLength = 80 //重命名最大字数

    let minutes: Minutes

    var detailBottomInset: CGFloat = 0

    weak var delegate: MinutesDetailViewControllerDelegate?

    var noticeTask: DispatchWorkItem? //有更新通知
    
    init(resolver: UserResolver, minutes: Minutes, player: MinutesVideoPlayer? = nil, type: MinutesDetailType = .phone) {
        self.userResolver = resolver
        self.minutes = minutes
        self.viewModel = MinutesDetailViewModel(minutes: minutes)
        self.videoPlayer = player ?? MinutesVideoPlayer(resolver: resolver, minutes: minutes)
        self.tracker = MinutesTracker(minutes: minutes)
        self.detailType = type

        super.init(nibName: nil, bundle: nil)

        if self.isText {
            self.selectedType = .text
        }

        if let player = player {
            player.listeners.addListener(self)
            player.updatePodcastStatus()
            if minutes.basicInfo?.mediaType == .video {
                player.videoEngine.radioMode = false
            } else {
                player.videoEngine.radioMode = true
            }
            player.pageType = .detail
        }
        InnoPerfMonitor.shared.entry(scene: .minutesDetail)

        var extra: [String: Any] = [:]
        extra["objectToken"] = minutes.objectToken
        extra["hasVideo"] = minutes.basicInfo?.mediaType == .video
        extra["contentSize"] = minutes.data.subtitlesContentSize
        extra["mediaDuration"] = minutes.basicInfo?.duration
        InnoPerfMonitor.shared.update(extra: extra)

        InnoPerfMonitor.shared.update(extra: ["isInTranslationMode": isInTranslationMode,
                                              "isInLandScape": isInLandScape,
                                              "isSmallVideoViewShown": false])

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        tracker.pageActive()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showGuideIfNeeded()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tracker.pageDeactive()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // YYLabel在不重新渲染的情况下，在系统中手动设置dark和light模式时候，无法自动变化
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                titleView.reloadData()
            }
        }
   }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        UIApplication.shared.isIdleTimerDisabled = true

        if !Display.pad {
            let auroraView = getAuroraViewView(auroraColors: (UIColor.ud.B600.withAlphaComponent(0.2), UIColor.ud.B500.withAlphaComponent(0.2), UIColor.ud.T350.withAlphaComponent(0.1)),
                                               auroraOpacity: 0.3)

            auroraView.layer.cornerRadius = 10
            auroraView.layer.masksToBounds = true
            self.auroraView = auroraView
            view.addSubview(auroraView)

            auroraView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        let verticalWidth = self.view.bounds.height > self.view.bounds.width ? self.view.bounds.width : self.view.bounds.height
        videoHeight = verticalWidth * 9.0 / 16.0

        segmentedView.titles = self.titles
        segmentedView.listContainer = pagingView.listContainerView
        self.view.addSubview(pagingView)

        view.addSubview(exitTranslateView)

        switch detailType {
            case .phone:
                if isVideo {
                    setupVideoView()
                    navigationBar.isHidden = true
                    navigationBar.backgroundColor = UIColor.ud.bgBody
                    titleView.backgroundColor = UIColor.ud.bgBody
                } else if isText {
                    navigationBar.moreButton.isHidden = false
                    navigationBar.backgroundColor = .clear
                    titleView.backgroundColor = .clear
                    if let bar = transcriptProgressBar {
                        view.addSubview(bar)
                        bar.snp.makeConstraints { maker in
                            maker.left.right.bottom.equalToSuperview()
                            maker.height.equalTo(86)
                        }
                    }
                } else {
                    navigationBar.moreButton.isHidden = true
                    navigationBar.backgroundColor = .clear
                    titleView.backgroundColor = .clear
                    view.addSubview(videoControlView)
                    videoControlView.snp.makeConstraints { maker in
                        maker.left.right.bottom.equalToSuperview()
                        maker.height.equalTo(144)
                    }
                    videoControlView.updateUIStyle()
                }
                view.addSubview(navigationBar)
            case .padLeft:
                navigationBar.isHidden = true
                if isVideo {
                    setupVideoView()
                    videoView?.mediaType = .video
                } else if isText {
                    setupTranscritpView()
                } else {
                    setupVideoView()
                    videoView?.mediaType = .audio
                }
            case .padRight:
                break
        }
        if !isText, detailType != .padRight {
            videoPlayer.loadPlayTime()
        }

        addMinuteStatusObserver()

        observeEditMenu()
        observeSummaryContentUpdated()

        let pageName = viewModel.minutes.info.isInProcessing ? "pre_detail_page" : "detail_page"
        tracker.tracker(name: .pageView, params: ["from_source": source?.rawValue ?? "", "page_name": pageName])
        NotificationCenter.default.addObserver(self, selector: #selector(quitEditSpeaker), name: NSNotification.Name.EditSpeaker.quitEditSpeaker, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }


    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if Display.phone { return }
        let verticalWidth = self.view.bounds.height > self.view.bounds.width ? self.view.bounds.width : self.view.bounds.height
        videoHeight = verticalWidth * 9.0 / 16.0
        updateLayout()
        DispatchQueue.main.async {
            self.updateMiniControlBarIfNeeded()
        }
    }

    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateLayout()
    }

    func observeEditMenu() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleLongPressRects), name: NSNotification.Name(rawValue: YYTextViewIsInLongPressSelectionRects), object: nil)
    }

    @objc func handleLongPressRects(_ notification: Notification) {
        if let object = notification.object as? [Any], let rectCount = object.first as? Int {
            let isInLongPressSelectionRects = rectCount > 0
            pagingView.mainScrollView.canCancelContentTouches = !isInLongPressSelectionRects
            pagingView.mainScrollView.delaysContentTouches = !isInLongPressSelectionRects

            pagingView.listContainerView.scrollView?.canCancelContentTouches = !isInLongPressSelectionRects
            pagingView.listContainerView.scrollView?.delaysContentTouches = !isInLongPressSelectionRects

            infoViewController?.tableView.canCancelContentTouches = !isInLongPressSelectionRects
            infoViewController?.tableView.delaysContentTouches = !isInLongPressSelectionRects

            summaryViewController?.tableView.canCancelContentTouches = !isInLongPressSelectionRects
            summaryViewController?.tableView.delaysContentTouches = !isInLongPressSelectionRects

            subtitlesViewController?.tableView?.canCancelContentTouches = !isInLongPressSelectionRects
            subtitlesViewController?.tableView?.delaysContentTouches = !isInLongPressSelectionRects
        }
    }

    func observeSummaryContentUpdated() {
        NotificationCenter.default.addObserver(self,
                selector: #selector(onReceiveMinutesSummaryContentUpdatedNotification(_:)),
                name: Notification.minutesSummaryContentUpdated,
                object: nil)
    }

    @objc
    private func onReceiveMinutesSummaryContentUpdatedNotification(_ notification: Notification) {
        if !isSummaryViewControllerEnable {
            return
        }
        DispatchQueue.main.async {
            if self.isSearching {
                return
            }
            if let userInfo = notification.userInfo as? [String: String],
               let objectToken = userInfo[Notification.MinutesSummary.objectToken],
               objectToken == self.viewModel.minutes.objectToken {
                self.showNoticeButton()
            }
        }
    }

    @objc
    private func quitEditSpeaker() {
        isEditingSpeaker = false
    }

    deinit {
        MinutesLogger.detail.info("detail vc deinit")

        UIApplication.shared.isIdleTimerDisabled = false

        NotificationCenter.default.removeObserver(self)
        InnoPerfMonitor.shared.leave(scene: .minutesDetail)
    }

    func updateLayout(forceReload: Bool = true) {
        navigationBar.frame = CGRect(x: 0, y: 0, width: view.safeAreaLayoutGuide.layoutFrame.width, height: view.safeAreaInsets.top + 44)
        var containerScrViewHeight: CGFloat = 0
        switch detailType {
            case .phone:
                if isVideo {
                    let vy: CGFloat = isEditingSpeaker ? 44 : 0
                    videoViewBackground.frame = CGRect(x: 0, y: vy, width: self.view.bounds.width, height: videoViewHeight)
                    containerScrViewHeight = view.bounds.height - videoViewHeight - vy
                    let y = videoViewHeight + vy
                    pagingView.frame = CGRect(x: 0, y: y, width: view.safeAreaLayoutGuide.layoutFrame.width, height: containerScrViewHeight)
                    videoView?.frame = CGRect(x: 0, y: videoOriginY, width: self.view.bounds.width, height: self.videoHeight)
                } else if isText {
                    if transcriptProgressBar?.isHidden == true {
                        containerScrViewHeight = view.bounds.height - navigationBar.frame.height
                    } else {
                        containerScrViewHeight = view.bounds.height - navigationBar.frame.height - 86
                    }

                    let y = view.safeAreaInsets.top + 44
                    pagingView.frame = CGRect(x: 0, y: y, width: view.safeAreaLayoutGuide.layoutFrame.width, height: containerScrViewHeight)
                } else {
                    containerScrViewHeight = view.bounds.height - navigationBar.frame.height - 144
                    let y = view.safeAreaInsets.top + 44
                    pagingView.frame = CGRect(x: 0, y: y, width: view.safeAreaLayoutGuide.layoutFrame.width, height: containerScrViewHeight)
                }
            case .padLeft:
                if isText {
                    transcriptView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: videoViewHeight)
                } else {
                    videoViewBackground.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: videoViewHeight)
                    videoView?.frame = CGRect(x: 0, y: videoOriginY, width: self.view.bounds.width, height: videoHeight)
                }
                containerScrViewHeight = view.bounds.height - videoViewHeight
                let y = videoViewHeight
                pagingView.frame = CGRect(x: 0, y: y, width: view.safeAreaLayoutGuide.layoutFrame.width, height: containerScrViewHeight)
            case .padRight:
                containerScrViewHeight = view.bounds.height
                pagingView.frame = CGRect(x: 0, y: 0, width: view.safeAreaLayoutGuide.layoutFrame.width, height: containerScrViewHeight)
        }
        if forceReload {
            pagingView.updateLayout()
        }
    }

    func setupTranscritpView() {
        guard detailType == .padLeft else { return }
        view.addSubview(transcriptView)
        transcriptView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: videoViewHeight)
    }

    func setupVideoView() {
        if detailType == .padRight { return }
        self.isInLandScape = false
        let shouldShowVideoView = detailType == .padLeft || !(videoPlayer.isAudioOnly)
        if shouldShowVideoView, let videoView = self.videoView {
            videoView.frame = CGRect(x: 0, y: videoOriginY, width: self.view.bounds.width, height: self.videoHeight)
            self.videoViewBackground.addSubview(videoView)
            videoView.updateUIStyle(false)
            videoViewBackground.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: videoViewHeight)
            view.addSubview(videoViewBackground)
        }
        videoView?.miniControllBar.hasSubtitle = !viewModel.minutes.data.subtitles.isEmpty
    }

    func updateVideoView(size: CGSize) {
        if detailType == .padRight { return }
        let shouldShowVideoView = !(videoPlayer.isAudioOnly)
        let isLandscape = size.width > size.height
        if isLandscape && shouldShowVideoView {
            switchVideoViewToLandscape(size: size)
        } else {
            switchVideoViewToPortrait(size: size)
        }
    }

    func switchVideoViewToLandscape(size: CGSize) {
        if !Display.pad, let videoView = self.videoView {
            self.isInLandScape = true
            self.pagingView.isHidden = true
            videoView.removeFromSuperview()
            videoView.frame = CGRect(origin: .zero, size: size)
            self.view.addSubview(videoView)
            videoView.updateUIStyle(true)
        }
    }

    func switchVideoViewToPortrait(size: CGSize) {
        guard Display.phone, let videoView = self.videoView else { return }
        self.isInLandScape = false
        self.pagingView.isHidden = false
        videoView.removeFromSuperview()
        videoView.frame = CGRect(x: 0, y: videoOriginY, width: size.width, height: self.videoHeight)
        videoViewBackground.addSubview(videoView)
        videoView.updateUIStyle(false)
    }

    func hideSearchButton() {

    }

    func refreshTopBar() {
        self.navigationBar.titleLabel.text = self.viewModel.minutes.basicInfo?.topic
        if self.viewModel.minutes.basicInfo?.objectStatus != .complete {
            hideSearchButton()
        }
    }

    func refreshVideoControlPannel(_ info: MinutesInfo) {
        if isVideo || detailType != .phone {
            return
        }
        let originHeight: CGFloat = 144
        let height = info.noPlayURL ? 0 : originHeight
        videoControlView.snp.updateConstraints { maker in
            maker.height.equalTo(height)
        }

//        videoControlView.showPodcastButton = !info.isInProcessing
    }

    func refreshHeaderView(with info: MinutesInfo) {
        guard detailType == .phone else { return }
        titleView.config(with: info)
        navigationBar.config(with: info)
        titleViewHeight = isEditingSpeaker ? 0 : titleView.headerHeight
        pagingView.updateLayout()
        DispatchQueue.main.async {
            if self.isVideo {
                self.pagingView.showHeader(animated: false)
            } else {
                if self.navigationBar.isTitleShow {
                    self.pagingView.hideHeader(animated: false)
                } else {
                    self.pagingView.showHeader(animated: false)
                }
            }
        }
    }

    private func setHeaderView(isHidden: Bool) {
        guard detailType == .phone else { return }
        titleViewHeight = isHidden ? 0 : titleView.headerHeight
        titleView.isHidden = isHidden
        pagingView.updateLayout()
        if pagingView.isHeaderVisible() {
            pagingView.hideHeader(animated: false)
        } else {
            pagingView.showHeader(animated: false)
        }
    }

    private func adjustHeaderIfNeeded() {
        if isVideo {
            updateLayout()
        }
        setHeaderView(isHidden: isEditingSpeaker)
    }

    func switchToPodcast() {
        // 直播小窗下开启播客模式，退出直播
        let isInLive: Bool = dependency?.larkLive?.isInLiving ?? false

        if isInLive {
            MinutesLogger.detail.info("current isInLiving, stop living")
            dependency?.larkLive?.stopLiving()
        }

        // 录音时开启播客模式
        if MinutesAudioRecorder.shared.isRecording {
            MinutesLogger.detail.info("current isInRecording")
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_PodcastDisabledWhileRecording, on: self.view)
            return
        }

        let body = MinutesPodcastBody(minutes: viewModel.minutes, player: self.videoPlayer)
        guard let from = userResolver.navigator.mainSceneTopMost else {
            return
        }
        userResolver.navigator.push(body: body, from: from, animated: false) { (_, response) in
            if let vc = response.resource as? UIViewController {
                var controllers = vc.navigationController?.viewControllers ?? []
                if controllers.count > 2,
                   controllers[controllers.count - 2] is MinutesContainerViewController {
                    controllers.remove(at: controllers.count - 2)
                }
                vc.navigationController?.setViewControllers(controllers, animated: false)
            }
        }

        self.tracker.tracker(name: .clickButton, params: ["action_name": "podcast_enter"])

        self.tracker.tracker(name: .detailClick, params: ["click": "podcast_enter", "target": "vc_minutes_podcast_view"])
    }

    @objc private func didEnterBackground() {
        if detailType != .padRight {
            videoPlayer.videoEngine.radioMode = true
        }
    }

    @objc private func willEnterForeground() {
        if detailType != .padRight, viewModel.minutes.basicInfo?.mediaType == .video {
            videoPlayer.videoEngine.radioMode = false
        }
        titleView.reloadData()
    }

    func reloadSegmentedData() {
        segmentedView.titles = titles
        segmentedView.reloadData()
    }

    func updatePages(_ pages: [MinutesDetailPage]) {
        resetPages()
        self.pages = pages
        configPages()
        loadPageControllers()
        reloadSegmentedData()
        pagingView.reloadData()
        selectItem(with: selectedType)
        DispatchQueue.main.async {
            self.pagingView.reloadData()
            self.summaryViewController?.tableView.reloadData()
            self.showExitTranslateViewIfNeeded()
            self.exitOriginalTextViewIfNeeded()
        }
    }

    func resetPages() {
        subtitlesViewController = nil
        summaryViewController = nil
        infoViewController = nil
        speakerController = nil
        chapterController = nil
    }

    func configPages() {
        for page in pages {
            switch page.pageType {
                case .summary:
                    if let controller = page.pageController as? MinutesSummaryViewController {
                        configSummaryController(controller)
                        summaryViewController = controller
                    }
                case .text:
                    if let controller = page.pageController as? MinutesSubtitlesViewController {
                        configSubtitlesController(controller)
                        subtitlesViewController = controller
                    }
                case .speaker:
                    if let controller = page.pageController as? MinutesSpeakersViewController {
                        configSpeakerController(controller)
                        speakerController = controller
                    }
                case .info:
                    if let controller = page.pageController as? MinutesInfoViewController {
                        infoViewController = controller
                    }
                case .chapter:
                    if let controller = page.pageController as? MinutesChapterViewController {
                        configChapterController(controller)
                        chapterController = controller
                    }
            }
        }
    }

    // disable-lint: duplicated_code
    private func configSubtitlesController(_ controller: MinutesSubtitlesViewController) {
        controller.delegate = self
        controller.dataProvider = self
        controller.scrollDirectionBlock = { [weak self] isUp in
            guard let self = self, self.isInTranslationMode else {
                return
            }

            if let direction = self.scrollDirection, direction == isUp {
                return
            }

            self.exitTranslateView.isHidden = false
            self.exitTranslateView.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview()
                if self.isVideo || self.isText || Display.pad {
                    maker.height.equalTo(44 + self.view.safeAreaInsets.bottom)
                    if isUp {
                        maker.top.equalTo(self.view.snp.bottom)
                    } else {
                        maker.bottom.equalTo(self.view.snp.bottom)
                    }
                } else {
                    maker.height.equalTo(44)
                    if isUp {
                        maker.top.equalTo(self.videoControlView.snp.top).offset(10) // 阴影会超出
                    } else {
                        maker.bottom.equalTo(self.videoControlView.snp.top)
                    }
                }
            }

            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            self.scrollDirection = isUp
        }
    }
    // enable-lint: duplicated_code

    // disable-lint: duplicated_code
    private func configSummaryController(_ controller: MinutesSummaryViewController) {
        controller.delegate = self
        controller.scrollDirectionBlock = { [weak self] isUp in
            guard let self = self, self.isInTranslationMode else {
                return
            }

            if let direction = self.scrollDirection, direction == isUp {
                return
            }

            self.exitTranslateView.isHidden = false
            self.exitTranslateView.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview()
                if self.isVideo || self.isText || Display.pad {
                    maker.height.equalTo(44 + self.view.safeAreaInsets.bottom)
                    if isUp {
                        maker.top.equalTo(self.view.snp.bottom)
                    } else {
                        maker.bottom.equalTo(self.view.snp.bottom)
                    }
                } else {
                    if isUp {
                        maker.top.equalTo(self.videoControlView.snp.top).offset(10) // 阴影会超出
                    } else {
                        maker.bottom.equalTo(self.videoControlView.snp.top)
                    }
                }
            }

            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            self.scrollDirection = isUp
        }
        controller.dataProvider = self
    }
    // enable-lint: duplicated_code

    // disable-lint: duplicated_code
    private func configSpeakerController(_ controller: MinutesSpeakersViewController) {
        controller.delegate = self
        controller.scrollDirectionBlock = { [weak self] isUp in
            guard let self = self, self.isInTranslationMode else {
                return
            }

            if let direction = self.scrollDirection, direction == isUp {
                return
            }

            self.exitTranslateView.isHidden = false
            self.exitTranslateView.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview()
                if self.isVideo || self.isText || Display.pad {
                    maker.height.equalTo(44 + self.view.safeAreaInsets.bottom)
                    if isUp {
                        maker.top.equalTo(self.view.snp.bottom)
                    } else {
                        maker.bottom.equalTo(self.view.snp.bottom)
                    }
                } else {
                    if isUp {
                        maker.top.equalTo(self.videoControlView.snp.top).offset(10) // 阴影会超出
                    } else {
                        maker.bottom.equalTo(self.videoControlView.snp.top)
                    }
                }
            }

            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            self.scrollDirection = isUp
        }
    }
    // enable-lint: duplicated_code

    // disable-lint: duplicated_code
    private func configChapterController(_ controller: MinutesChapterViewController) {
        controller.delegate = self
        controller.scrollDirectionBlock = { [weak self] isUp in
            guard let self = self, self.isInTranslationMode else {
                return
            }

            if let direction = self.scrollDirection, direction == isUp {
                return
            }

            self.exitTranslateView.isHidden = false
            self.exitTranslateView.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview()
                if self.isVideo || self.isText || Display.pad {
                    maker.height.equalTo(44 + self.view.safeAreaInsets.bottom)
                    if isUp {
                        maker.top.equalTo(self.view.snp.bottom)
                    } else {
                        maker.bottom.equalTo(self.view.snp.bottom)
                    }
                } else {
                    if isUp {
                        maker.top.equalTo(self.videoControlView.snp.top).offset(10) // 阴影会超出
                    } else {
                        maker.bottom.equalTo(self.videoControlView.snp.top)
                    }
                }
            }

            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            self.scrollDirection = isUp
        }
    }
    // enable-lint: duplicated_code

    // 根据type的顺序来load
    func loadPageControllers() {
        subViewControllers = pages.map { $0.pageController }
        types = pages.map { $0.pageType }
        titles = pages.map { $0.pageType.title }
    }

    func selectItem(with type: MinutesPageType) {
        if let idx = self.types.firstIndex(of: type) {
            self.segmentedView.selectItemAt(index: idx)
        }
    }

    private func getAuroraViewView(auroraColors: (UIColor, UIColor, UIColor), auroraOpacity: CGFloat) -> AuroraView {
        let auroraView = AuroraView(config: .init(
            mainBlob: .init(color: auroraColors.0, frame: CGRect(x: -44, y: -26, width: 168, height: 104), opacity: 1),
            subBlob: .init(color: auroraColors.1, frame: CGRect(x: -32, y: -131, width: 284, height: 217), opacity: 1),
            reflectionBlob: .init(color: auroraColors.2, frame: CGRect(x: 122, y: -71, width: 248, height: 149), opacity: 1)
        ))
        auroraView.blobsOpacity = auroraOpacity
        return auroraView
    }
}

extension MinutesDetailViewController: MinutesPagingViewDelegate {

    func headerViewHeight(in pagingView: MinutesPagingView) -> CGFloat {
        return detailType == .phone ? titleViewHeight : 0
    }

    func headerView(in pagingView: MinutesPagingView) -> UIView {
        return titleView
    }

    func canHeaderViewScroll(in pagingView: MinutesPagingView) -> Bool {
        return true
    }

    func heightForPinSectionHeader(in pagingView: MinutesPagingView) -> CGFloat {
        return CGFloat(segmentHeight)
    }

    func viewForPinSectionHeader(in pagingView: MinutesPagingView) -> UIView {
        return segmentedView
    }

    func numberOfLists(in pagingView: MinutesPagingView) -> Int {
        return subViewControllers.count
    }

    func pagingView(_ pagingView: MinutesPagingView, initListAtIndex index: Int) -> PagingViewListViewDelegate {
        return subViewControllers[index] as! PagingViewListViewDelegate
    }

    func mainScrollViewDidScroll(_ scrollView: UIScrollView) {
        guard detailType == .phone else { return }
        if scrollView.contentOffset.y > titleViewHeight - 10 {
//            navigationBar.showTitle()
        } else {
            navigationBar.hideTitle()
        }
    }

    func pagingView(_ pagingView: MinutesPagingView, mainScrollViewWillBeginDragging scrollView: UIScrollView) {
        subtitlesViewController?.hideMenu()
    }
}

// MARK: - Error Status Handler

extension MinutesDetailViewController: MinutesVideoPlayerListener {
    public func videoEngineDidLoad() {
    }

    public func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        self.onVideoPlayerStatusUpdate(status)
    }

    public func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
    }
}

extension MinutesDetailViewController: MinutesDataChangedListener {
    public func onMinutesReactionInfosUpdate(_ data:  [ReactionInfo]?) {
        if let data = data {
            updateReactionInfo(data)
        }
    }
}

extension MinutesDetailViewController {
    private func addMinuteStatusObserver() {
        if detailType != .padRight {
            videoPlayer.listeners.addListener(self)
            viewModel.minutes.data.listeners.addListener(self)
        }
    }

    func checkMinutesReady(isFirstRequest: Bool) {
        let info = viewModel.minutes.info
        let data = viewModel.minutes.data
        let translateData = viewModel.minutes.translateData
        if isInTranslationMode, let translateData = translateData {
            if info.status == .ready && translateData.status == .ready {
                onMinutesDataReady(translateData, isFirstRequest: isFirstRequest, didCompleted: nil)
                onMinutesStatusReady(info, isFirstRequest: isFirstRequest)
            }
        } else {
            if info.status == .ready && data.status == .ready {
                onMinutesDataReady(data, isFirstRequest: isFirstRequest, didCompleted: nil)
                onMinutesStatusReady(info, isFirstRequest: isFirstRequest)
            }
        }
    }

    // entry: 5
    public func onMinutesStatusReady(_ info: MinutesInfo, isFirstRequest: Bool) {
        refreshTopBar()
        refreshVideoControlPannel(info)
        infoViewController?.requestNewInfoData()
        if isText {
//            updateVideoView(size: self.view.bounds.size)
        } else {
            updateVideoView(size: self.view.bounds.size)
        }

        refreshHeaderView(with: info)
    }

    // entry: 6
    public func onMinutesDataReady(_ data: MinutesData, scrollToFirstWord: Bool = true, isFirstRequest: Bool, isTranslation: Bool = false, didCompleted: (() -> Void)?) {
        MinutesDetailReciableTracker.shared.finishNetworkReqeust()

        if data.subtitles.isEmpty {
            self.hideSearchButton()
        }
        self.subtitlesViewController?.updateKeywordsData(data)
        self.subtitlesViewController?.setParagraphs(data.subtitles, commentsInfo: data.paragraphComments, isInTranslationMode: self.isInTranslationMode, scrollToFirstWord: scrollToFirstWord, isFirstRequest: isFirstRequest, isTranslation: isTranslation) { [weak self] in
            didCompleted?()
        }

        DispatchQueue.main.async {
            self.updateRefreshViewLayoutIfNeeded()
        }
    }

    private func onVideoPlayerStatusUpdate(_ status: PlayerStatusWrapper) {
        MinutesLogger.detail.info("onVideoPlayerStatusUpdate: \(status)")
        switch status.videoPlayerStatus {
        case .error:
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_FailedToLoad, on: self.view, delay: 2)
        default:
            break
        }
        videoDuration = Int(videoPlayer.duration)
    }
}

extension MinutesDetailViewController: MinutesDetailViewNavigationBarDelegate {
    func navigationBack(_ view: MinutesDetailViewNavigationBar) {
        tracker.tracker(name: .feelgoodPop, params: [:])

        videoPlayer.removeCommandCenterTarget()
        if let backSelector = self.onClickBackButton {
            backSelector()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func navigationMore(_ view: MinutesDetailViewNavigationBar) {
        delegate?.didClickMore()
    }

    func navigationDone() {
        isEditingSpeaker = false
    }

}

extension MinutesDetailViewController {

    @objc func doSearchButtonClick() {
        self.didBeginSearchKeywords()
    }

    func showSearchBar() {
        setSearchFrame()
        if isVideo {
            searchView.isHidden = false
        }
        self.view.addSubview(searchView)
        self.selectItem(with: .text)
        self.searchView.viewWillShow()
        self.searchView.isKeywordSearch = false
        self.videoPlayer.pause()
        subtitlesViewController?.enterSearch()
        subtitlesViewController?.updateDownFloat(isInTranslationMode: true)
    }

    func showSearchBarWithKeyWord(text: String) {
        if !isSearching {
            setSearchFrame()
            searchView.isHidden = false
            self.view.addSubview(searchView)
            if detailType != .padRight {
                self.videoPlayer.pause()
            }
            subtitlesViewController?.clearSearch()
            subtitlesViewController?.enterSearch()
        }
        // 选择文字
        self.selectItem(with: .text)
        self.searchView.keyWordSearch(text: text)
        self.searchView.isKeywordSearch = true
        subtitlesViewController?.updateDownFloat(isInTranslationMode: true)
    }

    func hideSearchBar() {
        self.searchView.removeFromSuperview()
        searchView.isHidden = true
        subtitlesViewController?.updateDownFloat(isInTranslationMode: false)
    }

    func setSearchFrame() {
        let bottom = Display.pad ? 0 : view.safeAreaInsets.bottom
        var y = view.bounds.height - 40 - bottom
        var h = 40 + bottom
        if isText, Display.phone {
            y = view.bounds.height - 40 - videoControlView.bounds.height - 86
            h = 40
        } else if !isVideo, Display.phone {
            y = view.bounds.height - 40 - videoControlView.bounds.height
            h = 40
        }
        let fm = CGRect(x: 0, y: y, width: view.bounds.width, height: h)
        searchView.frame = fm
        searchView.originFrame = fm
    }
}

extension MinutesDetailViewController: MinutesSearchViewDelegate {

    func searchViewExitKeywordSearching(_ view: MinutesSearchView) {
        self.subtitlesViewController?.unselectKeywordsView()
    }

    func searchViewClearSearching(_ view: MinutesSearchView) {
        self.subtitlesViewController?.clearSearch()
        self.searchView.refreshSearchView()
        self.updateLayout()
    }

    func searchViewFinishSearching(_ view: MinutesSearchView) {
        self.hideSearchBar()
        self.subtitlesViewController?.exitSearch()
        self.infoViewController?.exitSearch()
        self.summaryViewController?.exitSearch()
        self.updateLayout()
        tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_search_location_change", "action_type": "done"])
        tracker.tracker(name: .detailClick, params: ["click": "subtitle_search_location_change", "action_type": "done", "target": "none"])
    }

    func searchView(_ view: MinutesSearchView, shouldSearch text: String, type: Int, callback: (() -> Void)?) {
        subtitlesViewController?.goSearch(text, type: type, callback: {
            callback?()
        })
    }

    func searchViewPreSearching(_ view: MinutesSearchView) {
        subtitlesViewController?.goSearchPre()

        tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_search_location_change", "action_type": "up"])
        tracker.tracker(name: .detailClick, params: ["click": "subtitle_search_location_change", "action_type": "up", "target": "none"])
    }

    func searchViewNextSearching(_ view: MinutesSearchView) {
        subtitlesViewController?.goSearchNext()

        tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_search_location_change", "action_type": "down"])
        tracker.tracker(name: .detailClick, params: ["click": "subtitle_search_location_change", "action_type": "down", "target": "none"])
    }
}

extension MinutesDetailViewController {
    func exitTranlation() {
        // 清空翻译数据
        viewModel.minutes.translateData = nil
        // 重置选择语言
        currentTranslationChosenLanguage = .default
        // 隐藏退出翻译视图
        exitTranslateView.isHidden = true
        // 取出默认数据并刷新
        onMinutesDataReady(viewModel.minutes.data, scrollToFirstWord: false, isFirstRequest: false, isTranslation: true, didCompleted: nil)

        summaryViewController?.requestNewData(language: .default)
        chapterController?.fetchSummaries(language: .default)
        speakerController?.onSpeakerDataUpdate(language: .default)
        subtitlesViewController?.updateDownFloat(isInTranslationMode: false)
        delegate?.translationDidExit()
    }

    func presentChooseTranlationLanVC() {
        if viewModel.minutes.data.subtitles.isEmpty {
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_NoTranscript, on: view)
            return
        }

        if viewModel.minutes.basicInfo?.supportAsr == false {
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_ThisLanguageNoTranscriptionNow, on: view)
            return
        }

        var items: [MinutesTranslationLanguageModel] = []

        for language in viewModel.minutes.subtitleLanguages where language != .default {
            let item = MinutesTranslationLanguageModel(language: language.name,
                    code: language.code,
                    isHighlighted: language == currentTranslationChosenLanguage)
            items.append(item)
        }
        let center = SelectTargetLanguageTranslateCenter(items: items)
        center.selectBlock = { [weak self] vm in
            guard let self = self else {
                return
            }
            let lang = Language(name: vm.language, code: vm.code)
            self.startTranslate(with: lang)
        }
        center.showSelectDrawer(from: self, resolver: userResolver)
    }

    func startTranslate(with lang: Language) {
        self.exitOriginalTextViewIfNeeded()

        var isTranslateCancel: Bool = false

        // 存储当前选择的语言
        let previousLang = currentTranslationChosenLanguage
        currentTranslationChosenLanguage = lang

        self.tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_language_change", "from_language": previousLang.trackerLanguage(), "action_language": lang.trackerLanguage()])

        let isTranslating = true
        let hud = MinutesTranslationHUD(isTranslating: isTranslating)
        hud.closeBlock = { [weak self, weak hud] in
            isTranslateCancel = true
            // 暂时还没有cancel接口
            self?.currentTranslationChosenLanguage = previousLang
            hud?.removeFromSuperview()
        }
        let container: UIView = self.delegate?.containerView ?? self.view
        hud.frame = container.bounds
        container.addSubview(hud)

        summaryViewController?.requestNewData(language: lang)
        chapterController?.fetchSummaries(language: lang)

        speakerController?.onSpeakerDataUpdate(language: .default, reload: false)
        speakerController?.onSpeakerDataUpdate(language: lang)

        viewModel.minutes.translate(language: lang) { [weak self] result in
            guard let self = self, isTranslateCancel == false else {
                return
            }
            DispatchQueue.main.async {
                switch result {
                case .failure(_):
                    // 一次失败就返回，不会多次返回
                    self.handleTranslateFail(previousLang: previousLang, hud: hud, isTranslating: isTranslating)
                case .success(let data):
                    self.handleTranslateSucccess(data, hud: hud, isTranslating: isTranslating)
                    self.tracker.tracker(name: .detailClick, params: ["click": "subtitle_language_change", "from_language": previousLang.trackerLanguage(), "action_language": lang.trackerLanguage(), "target": "none"])
                }
            }
        }
    }

    func handleTranslateSucccess(_ data: MinutesData, hud: MinutesTranslationHUD, isTranslating: Bool) {
        onMinutesDataReady(data, scrollToFirstWord: false, isFirstRequest: false, isTranslation: true, didCompleted: nil)
        hud.removeFromSuperview()
        showExitTranslateView()
        if isTranslating {
            let container: UIView = self.delegate?.containerView ?? self.view
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_Translated, on: container, delay: 2.0)
        }
    }

    func handleTranslateFail(previousLang: Language, hud: MinutesTranslationHUD, isTranslating: Bool) {
        hud.removeFromSuperview()
        currentTranslationChosenLanguage = previousLang

        if !MinutesCommonErrorToastManger.individualInternetCheck() {
            return
        }
        UDToast.showTips(with: isTranslating ? BundleI18n.Minutes.MMWeb_G_FailedToTranslateTryAgainLater : BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: self.view, delay: 2.0)
    }

    private func showExitTranslateView() {
        exitTranslateView.isHidden = false
        exitTranslateView.setLanguage(currentTranslationChosenLanguage.name)
        exitTranslateView.snp.remakeConstraints { maker in
            maker.left.right.equalToSuperview()
            if isVideo || isText || Display.pad {
                maker.bottom.equalTo(0)
                maker.height.equalTo(44 + view.safeAreaInsets.bottom)
            } else {
                maker.bottom.equalTo(videoControlView.snp.top)
                maker.height.equalTo(44)
            }
        }
        subtitlesViewController?.updateDownFloat(isInTranslationMode: true)
    }

    private func showExitTranslateViewIfNeeded() {
        if isInTranslationMode, subtitlesViewController != nil {
            showExitTranslateView()
        } else {
            exitTranslateView.isHidden = true
        }
    }
}

extension MinutesDetailViewController {
    func showNoticeButton() {
        noticeTask?.cancel()
        let workItem = DispatchWorkItem(block: { [weak self] in
            self?.hideNoticeButton()
        })
        noticeTask = workItem

        let width = self.view.bounds.width
        let buttonWith = MinutesNoticeVisualButton.viewWidth
        let buttonHeight = MinutesNoticeVisualButton.viewHeight
        
        let frame = CGRect(x: (width - buttonWith) / 2, y: 110, width: buttonWith, height: buttonHeight)
        noticeButton.frame = frame
        noticeButton.addTarget(self, action: #selector(noticeButtonClicked(_:)), for: .touchUpInside)
        self.pagingView.addSubview(noticeButton)
        self.pagingView.bringSubviewToFront(noticeButton)
            
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: workItem)
    }

    func hideNoticeButton() {
        noticeButton.removeFromSuperview()
    }

    @objc
    private func noticeButtonClicked(_ sender: UIButton) {
        if types.contains(.text) {
            subtitlesViewController?.noticeButtonClicked()
        }

        if types.contains(.summary) {
            summaryViewController?.noticeButtonClicked()
        }
        
        if types.contains(.chapter) {
            chapterController?.noticeButtonClicked()
        }
    }
}

// MARK: - commnet tip
extension MinutesDetailViewController {
    func setupReactionInfo() {
        viewModel.minutes.data.setupTimeline(videoDuration) { [weak self] result in
            switch result {
            case .success(let value):
                self?.updateReactionInfo(value)
            case .failure(let error):
                MinutesLogger.detail.warn("load reaction info error: \(error)")
            }
        }
    }

    func updateReactionInfo(_ info: [ReactionInfo]) {
        if detailType == .padRight { return }
        var validInfo = info.filter {
                    $0.type == 2
                }
                .sorted {
                    Double($0.startTime ?? 0) < Double($1.startTime ?? 0)
                }
        reactionsInfo = validInfo
        if !shouldShowCommentTip {
            validInfo = []
        }
        DispatchQueue.main.async {
            if self.isVideo {
                self.videoView?.miniControllBar.updateReactionInfo(validInfo)
            } else {
                self.videoControlView.updateReactionInfo(validInfo)
            }
        }
    }

    func updateMiniControlBarIfNeeded() {
        if detailType == .padRight { return }
        self.videoView?.miniControllBar.updateReactionInfo(reactionsInfo)
        self.videoView?.miniControllBar.slider.updateProgress(animated: false)
        self.videoView?.miniControllBar.slider.configureChapter()
    }
}

extension Language {
    func trackerLanguage() -> String {
        switch code {
        case "en_us":
            return "en_us"
        case "zh_cn":
            return "zh_cn"
        case "ja_jp":
            return "ja_jp"
        default:
            return "default"
        }
    }
}


