//
//  MinutesClipViewController.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/6.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import EENavigator
import YYText
import UniverseDesignToast
import UniverseDesignTabs
import RoundedHUD
import LarkFeatureGating
import LarkContainer
import LarkSnsShare
import UniverseDesignIcon
import UIKit
import MinutesInterface
import LarkContainer
import LarkUIKit
import FigmaKit

public final class MinutesClipViewController: UIViewController {
    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }
    var selectedType: MinutesPageType = .text
    var source: MinutesSource?
    var destination: MinutesDestination?

    var onClickBackButton: (() -> Void)?

    let userResolver: UserResolver
    
    lazy var pagingView: MinutesPagingView = {
        let view = MinutesPagingView(delegate: self)
        addChild(view.listContainerView.containerVC)
        return view
    }()

    lazy var segmentedView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    var titleViewHeight: CGFloat = 96
    let segmentHeight: CGFloat = 0.5

    private var videoHeight: CGFloat = 211

    private var videoOriginY: CGFloat {
        Display.pad ? 0 : view.safeAreaInsets.top
    }

    var isText: Bool {
        return viewModel.minutes.basicInfo?.mediaType == .text
    }

    let videoPlayer: MinutesVideoPlayer

    var isInLandScape = false {
        didSet {
            InnoPerfMonitor.shared.update(extra: ["isInLandScape": isInLandScape])
        }
    }

    var scrollDirection: Bool?
    
    var curTranslateChosenLanguage: Language = .default {
        didSet {
            InnoPerfMonitor.shared.update(extra: ["isInTranslationMode": isInTranslationMode])
        }
    }

    var isInTranslationMode: Bool {
        return curTranslateChosenLanguage != .default
    }

    weak var originalTextView: MinutesOriginalTextView?

    private lazy var titleView: MinutesClipTitleView = {
        let v = MinutesClipTitleView()
        v.delegate = self
        v.backgroundColor = .clear
        v.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: titleViewHeight)
        return v
    }()

    lazy var videoViewBackground: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: videoViewHeight))
        view.backgroundColor = .black
        return view
    }()

    lazy var videoView: MinutesVideoView = {
        let view = MinutesVideoView(resolver: userResolver, player: videoPlayer, isInCCMfg:  viewModel.minutes.basicInfo?.isInCCMfg == true)
        view.miniControllBar.backCallback = { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.videoView.isFullscreen {
                self.fullplayVC?.dismiss(animated: false, completion: {
                    self.videoView.isFullscreen = false
                    self.recoverVideoView()
                })
            } else {
                self.navigationBack(self.navigationBar)
            }

        }
        view.miniControllBar.moreCallback = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.presentMoreViewController()
        }
        view.miniControllBar.fullscreenBlock = { [weak self, weak view] in
            guard let self = self else { return }

            self.videoView.isFullscreen = true
            let vc = MinutesFullscreenPlayViewController(resolver: self.userResolver, videoView: self.videoView, player: self.videoPlayer)
            self.fullplayVC = vc
            vc.detailVC = self
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: false)
            view?.updateUIStyle(true)
        }
        return view
    }()

    weak var fullplayVC: MinutesFullscreenPlayViewController?

    lazy var videoControlView: MinutesVideoControlPannel = {
        let view = MinutesVideoControlPannel(resolver: userResolver, player: videoPlayer, isInCCMfg: viewModel.minutes.basicInfo?.isInCCMfg == true)
        view.delegate = self
        view.clickMoreHandler = { [weak self] in
            self?.presentMoreViewController()
        }
//        view.showShareButton = true
//        view.shareCallback = { [weak self] in
//            guard let self = self else { return }
//            self.showShareSnsPanel()
//        }
        return view
    }()

    lazy var subtitlesViewController: MinutesSubtitlesViewController = {
        let subtitles = MinutesSubtitlesViewController(resolver: userResolver, minutes: viewModel.minutes)
        subtitles.source = source
        subtitles.destination = destination
        subtitles.title = BundleI18n.Minutes.MMWeb_G_Transcription
        subtitles.player = videoPlayer
        subtitles.delegate = self
        subtitles.dataProvider = self
        subtitles.scrollDirectionBlock = { [weak self] isUp in
            guard let self = self, self.isInTranslationMode else { return }

            if let direction = self.scrollDirection, direction == isUp {
                return
            }

            self.exitTranslatePanel.isHidden = false
            self.exitTranslatePanel.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview()
                if self.isVideo || self.isText {
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
        return subtitles
    }()

    lazy var navigationBar: MinutesClipNavigationBar = {
        let bar = MinutesClipNavigationBar(frame: .zero)
        bar.delegate = self
        bar.backgroundColor = .clear
        return bar
    }()

//    private lazy var noticeButton: MinutesNoticeVisualButton = {
//        let view = MinutesNoticeVisualButton(frame: .zero)
//        return view
//    }()
    
    lazy var subViewControllers: [UIViewController] = {
        return [subtitlesViewController]
    }()

    lazy var exitTranslatePanel: MinutesExitTranslationView = {
        let exitTranslatePanel = MinutesExitTranslationView()
        exitTranslatePanel.setLanguage(curTranslateChosenLanguage.name)
        exitTranslatePanel.selectLanguageBlock = { [weak self] in
            guard let self = self else { return }
            if self.viewModel.minutes.data.subtitles.isEmpty {
                UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_NoTranscript, on: self.view)
                return
            }

            if self.viewModel.minutes.basicInfo?.supportAsr == false {
                UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_ThisLanguageNoTranscriptionNow, on: self.view)
                return
            }
            self.presentChooseTranlationLanVC(items: self.createTransItems())
        }
        exitTranslatePanel.exitTranslateBlock = { [weak self] in
            self?.exitTranlation()
        }
        exitTranslatePanel.isHidden = true
        return exitTranslatePanel
    }()

    var viewModel: MinutesClipViewModel
    let tracker: MinutesTracker

    var isVideo: Bool {
        return !(videoPlayer.isAudioOnly)
    }

    private var videoViewHeight: CGFloat {
        if Display.pad {
            return videoHeight
        } else {
            return videoHeight + view.safeAreaInsets.top
        }
    }

    private var videoBottomOffset: CGFloat {
        return 0
    }

    var videoDuration: Int = 0

    var isFirstLoad = true

    var moreSourceView: UIView?

    lazy var sharePanel: LarkSharePanel = {
        let url = viewModel.minutes.baseURL
        /// 分享内容
        let webUrlPrepare = WebUrlPrepare(title: self.navigationBar.titleLabel.text ?? "", webpageURL: url.absoluteString)
        let contentContext = ShareContentContext.webUrl(webUrlPrepare)
        let sourceView = moreSourceView ?? videoControlView.moreButton
        let pop = PopoverMaterial(sourceView: sourceView, sourceRect: sourceView.bounds, direction: moreSourceView == nil ? .down : .up)
        let sharePanel = LarkSharePanel(userResolver: userResolver,
                                        by: "lark.minutes.shareclip.link",
                                        shareContent: contentContext,
                                        on: self,
                                        popoverMaterial: pop,
                                        productLevel: "VC",
                                        scene: "Minutes_Shareclip",
                                        pasteConfig: .scPasteImmunity)
        sharePanel.delegate = self
        sharePanel.isRotatable = false
        sharePanel.downgradeTipPanel = DowngradeTipPanelMaterial.text(panelTitle: self.navigationBar.titleLabel.text ?? "", content: url.absoluteString ?? "")
        let itemContext = CustomShareItemContext(title: BundleI18n.Minutes.MMWeb_G_ShareToChat, icon: UDIcon.forwardOutlined.ud.withTintColor(UIColor.ud.iconN1))
        let shareContent: CustomShareContent = .text("", ["": ""])
        sharePanel.customShareContextMapping = ["inapp": CustomShareContext(identifier: "inapp",
                                                                            itemContext: itemContext,
                                                                            content: shareContent) { [weak self] _,_,_ in
            self?.showShareToChat()
        }]
        return sharePanel
    }()

    //var noticeTask: DispatchWorkItem? //有更新通知 clip 不更新通知

    init(resolver: UserResolver, minutes: Minutes, player: MinutesVideoPlayer? = nil) {
        self.userResolver = resolver
        self.viewModel = MinutesClipViewModel(minutes: minutes)
        self.videoPlayer = player ?? MinutesVideoPlayer(resolver: resolver, minutes: minutes)
        self.tracker = MinutesTracker(minutes: minutes)
        super.init(nibName: nil, bundle: nil)
        setupPlayer(minutes: minutes, player: player)
        performMonitor(minutes: minutes)
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
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tracker.pageDeactive()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody

        setupViews()
        addObservers()
    
        let pageName = viewModel.minutes.info.isInProcessing ? "pre_detail_page" : "detail_page"
        tracker.tracker(name: .pageView, params: ["from_source": source?.rawValue ?? "", "page_name": pageName])

        if isText == false {
            navigationBar.moreButton.isHidden = true
            if let info = viewModel.minutes.basicInfo, info.videoURL == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showToast(text: BundleI18n.Minutes.MMWeb_MV_VideoGenerating)

                }
            }
        } else {
            navigationBar.moreButton.isHidden = false
        }
    }
    
    func setupViews() {
        if !Display.pad {
            let auroraView = getAuroraViewView(auroraColors: (UIColor.ud.B600.withAlphaComponent(0.2), UIColor.ud.B500.withAlphaComponent(0.2), UIColor.ud.T350.withAlphaComponent(0.1)),
                                               auroraOpacity: 0.3)

            auroraView.layer.cornerRadius = 10
            auroraView.layer.masksToBounds = true
            view.addSubview(auroraView)

            auroraView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }


        let verticalWidth = self.view.bounds.height > self.view.bounds.width ? self.view.bounds.width : self.view.bounds.height
        videoHeight = verticalWidth * 9.0 / 16.0
        subtitlesViewController.layoutWidth = view.bounds.width
   
        view.addSubview(pagingView)
        view.addSubview(exitTranslatePanel)

        if isVideo {
            setupVideoView()
            navigationBar.isHidden = true
        } else if isText {
            // do nothing
        } else {
            view.addSubview(videoControlView)
            videoControlView.snp.makeConstraints { maker in
                maker.left.right.bottom.equalToSuperview()
                maker.height.equalTo(144)
            }
            videoControlView.updateUIStyle()
        }
        if Display.phone {
            view.addSubview(navigationBar)
        }
    }

    private func setupPlayer(minutes: Minutes, player: MinutesVideoPlayer?) {
        if let player = player {
            player.listeners.addListener(self)
            player.updatePodcastStatus()
            if minutes.basicInfo?.mediaType == .video {
                player.videoEngine.radioMode = false
            } else {
                player.videoEngine.radioMode = true
            }
            player.pageType = .clip
        }
    }
    
    private func performMonitor(minutes: Minutes) {
        InnoPerfMonitor.shared.entry(scene: .minutesClip)
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
    
    private func getAuroraViewView(auroraColors: (UIColor, UIColor, UIColor), auroraOpacity: CGFloat) -> AuroraView {
        let auroraView = AuroraView(config: .init(
            mainBlob: .init(color: auroraColors.0, frame: CGRect(x: -44, y: -26, width: 168, height: 104), opacity: 1),
            subBlob: .init(color: auroraColors.1, frame: CGRect(x: -32, y: -131, width: 284, height: 217), opacity: 1),
            reflectionBlob: .init(color: auroraColors.2, frame: CGRect(x: 122, y: -71, width: 248, height: 149), opacity: 1)
        ))
        auroraView.blobsOpacity = auroraOpacity
        return auroraView
    }

    func addObservers() {
        addMinuteStatusObserver()
        observeEditMenu()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if Display.phone { return }
        let verticalWidth = self.view.bounds.height > self.view.bounds.width ? self.view.bounds.width : self.view.bounds.height
        videoHeight = verticalWidth * 9.0 / 16.0
        if !(videoPlayer.isAudioOnly), !isInLandScape {
            videoViewBackground.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: videoViewHeight)
            videoView.frame = CGRect(x: 0, y: videoOriginY, width: self.view.bounds.width, height: videoHeight)
        }
        subtitlesViewController.layoutWidth = view.bounds.width
        refreshHeaderView(with: viewModel.minutes.info)
        updateLayout()
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

            subtitlesViewController.tableView?.canCancelContentTouches = !isInLongPressSelectionRects
            subtitlesViewController.tableView?.delaysContentTouches = !isInLongPressSelectionRects
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        InnoPerfMonitor.shared.leave(scene: .minutesDetail)
    }

    func updateLayout() {
        navigationBar.frame = CGRect(x: 0, y: 0, width: view.safeAreaLayoutGuide.layoutFrame.width, height: view.safeAreaInsets.top + 44)
        var containerScrViewHeight: CGFloat = 0
        if isVideo {
            let vy: CGFloat = 0
            videoViewBackground.frame = CGRect(x: 0, y: vy, width: self.view.bounds.width, height: videoViewHeight)
            containerScrViewHeight = view.bounds.height - videoViewHeight - vy
            let y = videoViewHeight + vy
            pagingView.frame = CGRect(x: 0, y: y, width: view.safeAreaLayoutGuide.layoutFrame.width, height: containerScrViewHeight)
        }  else if isText {
            containerScrViewHeight = view.bounds.height - (Display.pad ? 0 : navigationBar.frame.height)
            let y = Display.pad ? 0 : view.safeAreaInsets.top + 44
            pagingView.frame = CGRect(x: 0, y: y, width: view.safeAreaLayoutGuide.layoutFrame.width, height: containerScrViewHeight)
        } else {
            containerScrViewHeight = view.bounds.height - (Display.pad ? 0 : navigationBar.frame.height) - 144
            let y = Display.pad ? 0 : view.safeAreaInsets.top + 44
            pagingView.frame = CGRect(x: 0, y: y, width: view.safeAreaLayoutGuide.layoutFrame.width, height: containerScrViewHeight)
        }
        pagingView.updateLayout()
    }

    func setupVideoView() {
        self.isInLandScape = false
        let shouldShowVideoView = !(videoPlayer.isAudioOnly)
        if shouldShowVideoView {
            self.videoView.frame = CGRect(x: 0, y: videoOriginY, width: self.view.bounds.width, height: self.videoHeight)
            self.videoViewBackground.addSubview(self.videoView)
            self.videoView.updateUIStyle(false)
            videoViewBackground.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: videoViewHeight)
            view.addSubview(videoViewBackground)
        }
        videoView.miniControllBar.hasSubtitle = !viewModel.minutes.data.subtitles.isEmpty
    }

    func updateVideoView(size: CGSize) {
        let shouldShowVideoView = !(videoPlayer.isAudioOnly)
        let isLandscape = size.width > size.height
        if isLandscape && shouldShowVideoView {
            switchVideoViewToLandscape(size: size)
        } else {
            switchVideoViewToPortrait(size: size)
        }
    }

    func switchVideoViewToLandscape(size: CGSize) {
        if Display.pad { return }
        self.isInLandScape = true
        self.pagingView.isHidden = true
        self.videoView.removeFromSuperview()
        self.videoView.frame = view.bounds
        self.view.addSubview(self.videoView)
        self.videoView.updateUIStyle(true)
    }

    func switchVideoViewToPortrait(size: CGSize) {
        if Display.pad { return }
        self.isInLandScape = false
        self.pagingView.isHidden = false
        self.videoView.removeFromSuperview()
        self.videoView.frame = CGRect(x: 0, y: videoOriginY, width: size.width, height: self.videoHeight)
        self.videoViewBackground.addSubview(self.videoView)
        self.videoView.updateUIStyle(false)
    }

    func refreshTopBar() {
        self.navigationBar.titleLabel.text = self.viewModel.minutes.basicInfo?.topic
    }

    func refreshVideoControlPannel(_ info: MinutesInfo) {
    }

    func refreshHeaderView(with info: MinutesInfo) {
        titleView.config(with: info.basicInfo)
        titleViewHeight = titleView.headerHeight
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

    private func setHeaderView() {
        titleViewHeight = titleView.headerHeight
        titleView.isHidden = false
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
        setHeaderView()
    }

    @objc private func didEnterBackground() {
        videoPlayer.videoEngine.radioMode = true
    }

    @objc private func willEnterForeground() {
        if viewModel.minutes.basicInfo?.mediaType == .video {
            videoPlayer.videoEngine.radioMode = false
        }
    }
}

extension MinutesClipViewController: MinutesPagingViewDelegate {

    func headerViewHeight(in pagingView: MinutesPagingView) -> CGFloat {
        return Display.pad ? 16 : titleViewHeight
    }

    func headerView(in pagingView: MinutesPagingView) -> UIView {
        return Display.pad ? UIView() : titleView
    }

    func canHeaderViewScroll(in pagingView: MinutesPagingView) -> Bool {
        if isVideo {
            return false
        } else {
            return true
        }
    }
    
    func heightForPinSectionHeader(in pagingView: MinutesPagingView) -> CGFloat {
        return Display.pad ? 0 : CGFloat(segmentHeight)
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
        if scrollView.contentOffset.y > titleViewHeight - 10 {
//            navigationBar.showTitle()
        } else {
            navigationBar.hideTitle()
        }
    }

    func pagingView(_ pagingView: MinutesPagingView, mainScrollViewWillBeginDragging scrollView: UIScrollView) {
        subtitlesViewController.hideMenu()
    }
}

// MARK: - Error Status Handler

extension MinutesClipViewController:MinutesVideoPlayerListener {
    public func videoEngineDidLoad() {
    }

    public func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        self.onVideoPlayerStatusUpdate(status)
    }

    public func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
    }
}

extension MinutesClipViewController {
    private func addMinuteStatusObserver() {
        
        viewModel.minutes.data.listeners.addListener(self)
        viewModel.minutes.info.listeners.addListener(self)

        videoPlayer.listeners.addListener(self)
    }

    func checkMinutesReady() {
        let info = viewModel.minutes.info
        let data = viewModel.minutes.data
        let translateData = viewModel.minutes.translateData
        if isInTranslationMode, let translateData = translateData {
            if info.status == .ready && translateData.status == .ready {
                onMinutesDataReady(translateData, isTranslation: true, didCompleted: nil)
                onMinutesStatusReady(info)
            }
        } else {
            if info.status == .ready && data.status == .ready {
                onMinutesDataReady(data, didCompleted: nil)
                onMinutesStatusReady(info)
            }
        }
    }

    public func onMinutesStatusReady(_ info: MinutesInfo) {
        refreshTopBar()
        refreshVideoControlPannel(info)
        updateVideoView(size: self.view.bounds.size)
        refreshHeaderView(with: info)
    }

    public func onMinutesDataReady(_ data: MinutesData, scrollToFirstWord: Bool = true, isTranslation: Bool = false, didCompleted: (() -> Void)?) {
        MinutesDetailReciableTracker.shared.finishNetworkReqeust()

        self.subtitlesViewController.setParagraphs(data.subtitles,
                                                   commentsInfo: data.paragraphComments,
                                                   isInTranslationMode: self.isInTranslationMode,
                                                   scrollToFirstWord: scrollToFirstWord,
                                                   isTranslation: isTranslation,
                                                   didCompleted: didCompleted)
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

extension MinutesClipViewController: MinutesDataChangedListener {
    public func onMinutesDataStatusUpdate(_ data: MinutesData) {
        MinutesLogger.detail.info("onMinutesDataStatusUpdate: \(data.status)")
        DispatchQueue.main.async {
            switch data.status {
            case .ready:
                self.checkMinutesReady()
            default:
                break
            }
        }
    }
}

extension MinutesClipViewController: MinutesInfoChangedListener {
    public func onMinutesInfoStatusUpdate(_ info: MinutesInfo) {
        MinutesLogger.detail.info("onMinutesInfoStatusUpdate: \(info.status)")
        DispatchQueue.main.async {
            switch info.status {
            case .ready:
                self.checkMinutesReady()
            default:
                break
            }
        }
    }
}

extension MinutesClipViewController: MinutesClipNavigationBarDelegate {
    func navigationBack(_ view: MinutesClipNavigationBar) {
        if let backSelector = self.onClickBackButton {
            backSelector()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func navigationMore(_ view: MinutesClipNavigationBar) {
        presentMoreViewController()
    }

    func navigationBackToMinutes() {
        goToOriginalMinutes()
    }
}

extension MinutesClipViewController {
    func exitTranlation() {
        // 重置选择语言
        curTranslateChosenLanguage = .default
        // 清空翻译数据
        viewModel.minutes.translateData = nil
        // 取出默认数据并刷新
        onMinutesDataReady(viewModel.minutes.data, scrollToFirstWord: false, didCompleted: nil)
        // 隐藏退出翻译视图
        exitTranslatePanel.isHidden = true
        
        subtitlesViewController.updateDownFloat(isInTranslationMode: false)
        subtitlesViewController.updateSubtitleViewer()
    }

    // disable-lint: duplicated_code
    func presentChooseTranlationLanVC(items: [MinutesTranslationLanguageModel]) {
        let center = SelectTargetLanguageTranslateCenter(items: items)
        center.selectBlock = { [weak self] vm in
            guard let self = self else {
                return
            }
            let lang = Language(name: vm.language, code: vm.code)
            self.translateRequest(lang)
        }
        center.showSelectDrawer(from: self, resolver: userResolver, isRegular: traitCollection.horizontalSizeClass == .regular)
    }
    // enable-lint: duplicated_code
    
    func createTransItems() -> [MinutesTranslationLanguageModel] {
        var items: [MinutesTranslationLanguageModel] = []

        for language in self.viewModel.minutes.subtitleLanguages where language != .default {
            let item = MinutesTranslationLanguageModel(language: language.name,
                                                       code: language.code,
                                                       isHighlighted: language == self.curTranslateChosenLanguage)
            items.append(item)
        }
        return items
    }
    
    func translateRequest(_ lang: Language) {
        self.exitOriginalTextViewIfNeeded()

        var isTranslateCancel: Bool = false
        
        // 存储当前选择的语言
        let previousLang = curTranslateChosenLanguage
        curTranslateChosenLanguage = lang
        
        tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_language_change", "from_language": previousLang.trackerLanguage(), "action_language": lang.trackerLanguage()])
        
        let isTranslating = true
        let hud = MinutesTranslationHUD(isTranslating: isTranslating)
        hud.closeBlock = { [weak self, weak hud] in
            isTranslateCancel = true
            // 暂时还没有cancel接口
            self?.curTranslateChosenLanguage = previousLang
            hud?.removeFromSuperview()
        }
        hud.frame = view.bounds
        view.addSubview(hud)
        
        translatRequest(lang, previousLang: previousLang, isTranslating: isTranslating, isTranslateCancel: isTranslateCancel, hud: hud)
    }
    
    func translatRequest(_ lang: Language, previousLang: Language, isTranslating: Bool, isTranslateCancel: Bool, hud: MinutesTranslationHUD) {
        viewModel.minutes.translate(language: lang) { [weak self] result in
            guard let self = self, isTranslateCancel == false else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    hud.removeFromSuperview()
                    // 一次失败就返回，不会多次返回
                    self.curTranslateChosenLanguage = previousLang
                    
                    if !MinutesCommonErrorToastManger.individualInternetCheck() { break }
                    UDToast.showTips(with: isTranslating ? BundleI18n.Minutes.MMWeb_G_FailedToTranslateTryAgainLater : BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: self.view, delay: 2.0)
                case .success(let data):
                    hud.removeFromSuperview()
                    self.onMinutesDataReady(data, scrollToFirstWord: false, isTranslation: true, didCompleted: nil)
                    self.showExitTranslatePanel()
                    
                    if isTranslating {
                        UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_Translated, on: self.view, delay: 2.0)
                    }
                    self.tracker.tracker(name: .detailClick, params: ["click": "subtitle_language_change", "from_language": previousLang.trackerLanguage(), "action_language": lang.trackerLanguage(), "target": "none"])
                }
            }
        }
    }

    private func showExitTranslatePanel() {
        exitTranslatePanel.isHidden = false
        exitTranslatePanel.setLanguage(curTranslateChosenLanguage.name)
        exitTranslatePanel.snp.remakeConstraints { maker in
            maker.left.right.equalToSuperview()
            if isVideo || isText {
                maker.bottom.equalTo(0)
                maker.height.equalTo(44 + view.safeAreaInsets.bottom)
            } else {
                maker.bottom.equalTo(videoControlView.snp.top)
                maker.height.equalTo(44)
            }
        }
        subtitlesViewController.updateDownFloat(isInTranslationMode: true)
    }
}

//extension MinutesClipViewController {
//    func showNoticeButton() {
//        noticeTask?.cancel()
//        let workItem = DispatchWorkItem(block: { [weak self] in
//            self?.hideNoticeButton()
//        })
//        noticeTask = workItem
//
//        let width = self.view.bounds.width
//        let buttonWith = MinutesNoticeVisualButton.viewWidth
//        let buttonHeight = MinutesNoticeVisualButton.viewHeight
//        
//        let frame = CGRect(x: (width - buttonWith) / 2, y: 48, width: buttonWith, height: buttonHeight)
//        noticeButton.frame = frame
//        noticeButton.addTarget(self, action: #selector(noticeButtonClicked(_:)), for: .touchUpInside)
//        self.pagingView.addSubview(noticeButton)
//        self.pagingView.bringSubviewToFront(noticeButton)
//            
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10), execute: workItem)
//    }
//
//    func hideNoticeButton() {
//        noticeButton.removeFromSuperview()
//    }
//
//    @objc
//    private func noticeButtonClicked(_ sender: UIButton) {
//        if subViewControllers.contains(subtitlesViewController) {
//            subtitlesViewController.noticeButtonClicked()
//        }
//    }
//}

extension MinutesClipViewController: MinutesClipTitleViewDelegate {
    func goToOriginalMinutes() {
        self.tracker.tracker(name: .detailClick, params: ["click": "jump_to_full", "object_type": "7"])
        self.videoPlayer.pause()
        if let urlString: String = viewModel.minutes.basicInfo?.clipInfo?.parentURLStr, let url = URL(string: urlString) {
            if let minutes = Minutes(url) {
                let body = MinutesDetailBody(minutes: minutes, source: .clip, destination: .detail)

                if source == .clipList {
                    userResolver.navigator.push(body: body, from: self)
                } else {
                    var params = NaviParams()
                    params.forcePush = true
                    userResolver.navigator.push(body: body, naviParams: params, from: self){ _,_ in
                      if let currNavCtrl = self.navigationController, currNavCtrl.viewControllers.count >= 2, currNavCtrl.viewControllers[currNavCtrl.viewControllers.count - 2].children.count >= 1,
                        currNavCtrl.viewControllers[currNavCtrl.viewControllers.count - 2].children[0].isKind(of: MinutesClipViewController.self){
                        currNavCtrl.viewControllers.remove(at: currNavCtrl.viewControllers.count - 2)
                      }
                    }
                }
            }
        }
    }
}

extension MinutesClipViewController: MinutesVideoControlPannelDelegate {
    func showToast(text: String, by pannel: MinutesVideoControlPannel) {
        self.showToast(text: text)
    }
}

