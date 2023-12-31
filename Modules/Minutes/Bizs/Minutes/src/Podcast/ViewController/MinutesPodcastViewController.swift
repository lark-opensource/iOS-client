//
//  MinutesPodcastViewController.swift
//  Minutes
//
//  Created by yangyao on 2021/4/1.
//

import UIKit
import SnapKit
import MinutesFoundation
import MinutesNetwork
import LarkLocalizations
import YYText
import EENavigator
import UniverseDesignToast
import Lottie
import LarkUIKit
import AppReciableSDK
import LarkContainer

class MinutesPodcastViewController: UIViewController {
    class GradientView: UIView {
        enum GradientType {
            case top
            case bottom
        }
        var type: GradientType = .top
        lazy var gradientLayer: CAGradientLayer = {
            let gradientLayer = CAGradientLayer()
            if type == .top {
                gradientLayer.startPoint = CGPoint(x: 0, y: 0)
                gradientLayer.endPoint = CGPoint(x: 0, y: 0.1)
                gradientLayer.colors = [
                    UIColor.clear.withAlphaComponent(0).cgColor,
                    UIColor.clear.withAlphaComponent(1.0).cgColor
                ]
            } else {
                gradientLayer.startPoint = CGPoint(x: 0, y: 0.9)
                gradientLayer.endPoint = CGPoint(x: 0, y: 1.0)
                gradientLayer.colors = [
                    UIColor.clear.withAlphaComponent(1.0).cgColor,
                    UIColor.clear.withAlphaComponent(0).cgColor
                ]
            }
            return gradientLayer
        }()

        init(type: GradientType) {
            self.type = type
            super.init(frame: .zero)

            layer.mask = gradientLayer
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            gradientLayer.frame = bounds
        }
    }

    let session: MinutesSession

    var userResolver: UserResolver { session.userResolver }
    var viewModel: MinutesPodcastViewModel {
        didSet {
            guard oldValue.minutes !== viewModel.minutes else { return }
            addMinuteStatusObserver()
        }
    }

    var matchedVM: MinutesPodcastLyricViewModel?
    var lastAutoScrollOffset: CGFloat = -CGFloat.greatestFiniteMagnitude

    var navigationBarIsHidden: Bool?
    var currentToken: String?

    var minutesInfo: MinutesInfo?

    var autoScrollTimer: Timer?
    var isDragged: Bool = false {
        didSet {
            if isDragged && lyricTimeView.lyricTimeLabel.text?.isEmpty == false {
                lyricTimeView.isHidden = false
            } else {
                lyricTimeView.isHidden = true
            }
            if isDragged == false {
                viewModel.resetHighlightedLyric()
            }
        }
    }

    var highlightedLyricVM: MinutesPodcastLyricViewModel?
    var didClickedSameLyric: Bool = false
    var previousClickedTimer: Timer?
    var previousClickedIndex: NSInteger = -1

    // 显示歌词时间的高亮距离顶部的间距
    var highlightedLyricTimeTop: CGFloat = 200
    var lyricTimeViewHeight: CGFloat = 20
    // 播放时候当前的高亮间距
    var currentHighlightedLyricTop: CGFloat = 100
    var videoControlViewHeight: CGFloat = ScreenUtils.hasTopNotch ? 220 : 220 - 34
    var navigationBarHeight: CGFloat = 44
    var highlightedLyricTimeOffsetY: CGFloat {
        tableView.contentOffset.y + highlightedLyricTimeTop + lyricTimeViewHeight / 2.0
    }
    var headerViewHeight: CGFloat {
        return highlightedLyricTimeTop
    }
    var footerViewHeight: CGFloat {
        return view.bounds.height - navigationBarHeight - (UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0.0) - videoControlViewHeight
    }

    var isScrollingToRect: Bool = false

    var onClickBackButton: (() -> Void)?
    let serialQueue = DispatchQueue(label: "minutes.podcast.process.data.queue")

    var tracker: MinutesTracker { session.tracker }

    private lazy var navigationBar: MinutesPodcastNavigationBar = {
        let view = MinutesPodcastNavigationBar()
        view.backButton.addTarget(self, action: #selector(onBtnBack), for: .touchUpInside)
        view.speedButton.addTarget(self, action: #selector(speedbuttonAction), for: .touchUpInside)
        view.updateSpeedButton(with: getFormatedSpeedString())
        return view
    }()

    private lazy var lyricTimeView: MinutesLyricTimeView = {
        let view = MinutesLyricTimeView()
        view.isHidden = true
        return view
    }()
    var lyricTimeViewWidth: CGFloat = 45 {
        didSet {
            guard lyricTimeViewWidth != oldValue else { return }

            lyricTimeView.snp.updateConstraints { (maker) in
                maker.width.equalTo(lyricTimeViewWidth)
            }
        }
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MinutesPodcastLyricCell.self, forCellReuseIdentifier: MinutesPodcastLyricCell.description())
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.description())
        tableView.separatorStyle = .none
        // reload之后offset会变
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()

    var videoPlayer: MinutesVideoPlayer? {
        didSet {
            guard oldValue !== videoPlayer else { return }
            addPlayerCallback()
            if let player = videoPlayer {
                videoControlView = MinutesPodcastControlPannel(player)
                player.updatePodcastStatus()
            } else {
                videoControlView = nil
            }
        }
    }

    var videoControlView: MinutesPodcastControlPannel? {
        didSet {
            oldValue?.removeFromSuperview()
            addControllPannelView()
        }
    }

    lazy var backgroundImageIndex: Int = Int(CACurrentMediaTime())

    lazy var bgImageView: UIView = {
        if false {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            return imageView
        } else {
            let background = MinutesPodcastBackgroundView(background: UIImage())
            MinutesPodcast.shared.loadBackgoundImage(index: backgroundImageIndex) { image in
                background.image = image
            }
            return background
        }
    }()

    lazy var emptyTips: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Minutes.MMWeb_G_NoTranscript
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = .systemFont(ofSize: 17)
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    lazy var invalidTips: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Minutes.MMWeb_G_CouldNotPlayAudio
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = .systemFont(ofSize: 17)
        label.isHidden = true
        return label
    }()

    lazy var errorTips: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Minutes.MMWeb_G_NoInternetConnectionTryAgainLater
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.font = .systemFont(ofSize: 14)
        label.isHidden = true
        return label
    }()

    lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.layer.cornerRadius = 4
        button.backgroundColor = UIColor.ud.rgb(0x0085FF)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_Reload, for: .normal)
        button.addTarget(self, action: #selector(onBtnRetry), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    lazy var animateLoadingView: LOTAnimationView = {
        let view: LOTAnimationView
        if let jsonPath = BundleConfig.MinutesBundle.path(
            forResource: "minutes_podcast_loading",
            ofType: "json",
            inDirectory: "lottie") {
            view = LOTAnimationView(filePath: jsonPath)
        } else {
            view = LOTAnimationView()
        }
        view.loopAnimation = true
        view.play()
        view.isHidden = true
        return view
    }()

    lazy var loadingTips: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Minutes.MMWeb_G_Loading
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.isHidden = true
        return label
    }()

    lazy var exitButton: UIButton = {
        let button = UIButton()
        button.setImage(BundleResources.Minutes.minutes_podcast_exit, for: .normal)
        button.setTitle(" \(BundleI18n.Minutes.MMWeb_G_ExitPodcastMode)", for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.85), for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.35), for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 13
        button.layer.borderWidth = 1.0
        button.layer.ud.setBorderColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.35))
        button.addTarget(self, action: #selector(onExit), for: .touchUpInside)
        return button
    }()

    init(session: MinutesSession) {
        // 进入设置为音频模式
        self.session = session
        session.player.videoEngine.radioMode = true
        self.viewModel = MinutesPodcastViewModel(minutes: session.minutes)
        self.videoPlayer = session.player
        self.currentToken = session.minutes.objectToken
        super.init(nibName: nil, bundle: nil)

        self.videoPlayer?.updatePodcastStatus()
        self.videoPlayer?.pageType = .podcast

        MinutesPodcast.shared.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        session.willLeaveMinutes()
        UIApplication.shared.isIdleTimerDisabled = false
        // 退出恢复
        videoPlayer?.videoEngine.radioMode = false

        autoScrollTimer?.invalidate()
        autoScrollTimer = nil

        previousClickedTimer?.invalidate()
        previousClickedTimer = nil
        MinutesPodcast.shared.delegate = nil
        MinutesLogger.podcast.info("podcast vc deinit")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationBarIsHidden = navigationController?.navigationBar.isHidden
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationBarIsHidden = navigationBarIsHidden {
            navigationController?.navigationBar.isHidden = navigationBarIsHidden
        }
    }

    lazy var gradientViewTop: GradientView = {
        let view = GradientView(type: .top)
        return view
    }()

    lazy var gradientViewBottom: GradientView = {
        let view = GradientView(type: .bottom)
        return view
    }()

    lazy var tableViewContainer: UIView = {
        return UIView()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        MinutesPodcastSuspendable.removePodcastSuspendable()

        UIApplication.shared.isIdleTimerDisabled = true

        let gradientview = LarkUIKit.GradientView()
        gradientview.colors = [
            UIColor.ud.rgb("095651").withAlphaComponent(0.7),
            UIColor.ud.rgb("0B3D6E").withAlphaComponent(0.35),
            UIColor.ud.rgb("0D4981").withAlphaComponent(0)
        ]

        view.addSubview(gradientview)
        gradientview.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        view.addSubview(bgImageView)
        view.addSubview(gradientViewTop)
        gradientViewTop.addSubview(gradientViewBottom)
        gradientViewBottom.addSubview(tableViewContainer)
        tableViewContainer.addSubview(tableView)

        view.addSubview(navigationBar)
        view.addSubview(lyricTimeView)
        view.addSubview(exitButton)

        bgImageView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        gradientViewTop.snp.makeConstraints { (maker) in
            maker.top.equalTo(navigationBar.snp.bottom)
            maker.left.right.equalToSuperview()
            maker.bottom.lessThanOrEqualToSuperview()
        }
        gradientViewBottom.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        tableViewContainer.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        tableView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        navigationBar.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
        }
        lyricTimeView.snp.makeConstraints { (maker) in
            maker.top.equalTo(tableViewContainer).offset(200)
            maker.right.equalToSuperview()
            maker.width.equalTo(lyricTimeViewWidth)
        }
        exitButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.height.equalTo(26)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        if let player = self.videoPlayer, videoControlView == nil {
            videoControlView = MinutesPodcastControlPannel(player)
        }
        addControllPannelView()
        addLoadingView()
        addErrorViewView()
        addEmptyView()
        addInvalideView()

        addMinuteStatusObserver()
        addPlayerCallback()

        tracker.tracker(name: .podcastView, params: [:])
        
        tracker.tracker(name: .minutesPodcastViewDev, params: ["action_name": "entry_page", "is_error": 0])
    }

    func showErrorView() {
        hideLoadingView()
        hideEmptyView()
        hideInvalideView()
        errorTips.isHidden = false
        retryButton.isHidden = false
    }

    func hideErrorView() {
        errorTips.isHidden = true
        retryButton.isHidden = true
    }

    func showLoadingView() {
        setParagraphs([])
        hideErrorView()
        hideEmptyView()
        hideInvalideView()
        animateLoadingView.isHidden = false
        loadingTips.isHidden = false
        exitButton.isHidden = false
        bgImageView.isHidden = true
    }

    func hideLoadingView() {
        animateLoadingView.isHidden = true
        loadingTips.isHidden = true
    }

    func showEmptyView() {
        hideLoadingView()
        hideErrorView()
        hideInvalideView()
        emptyTips.isHidden = false
        if viewModel.isSupportASR {
            // longMeetingNoContentTips: 超16小时没有文字生成
            emptyTips.text = viewModel.minutes.basicInfo?.longMeetingNoContentTips == true ? BundleI18n.Minutes.MMWeb_G_VideoLengthOverNoText : BundleI18n.Minutes.MMWeb_G_NoTranscript
        } else {
            emptyTips.text = BundleI18n.Minutes.MMWeb_G_ThisLanguageNoTranscriptionNow
        }
    }

    func hideEmptyView() {
        emptyTips.isHidden = true
    }

    func showInvalidView() {
        setParagraphs([])
        hideLoadingView()
        hideErrorView()
        hideEmptyView()
        invalidTips.isHidden = false
    }

    func hideInvalideView() {
        invalidTips.isHidden = true
    }

    @objc func onBtnRetry() {
        loadPodcastData()
    }

    func updateMinutes(_ minutes: Minutes?) {
        if let minutes = minutes {
            self.currentToken = minutes.objectToken
            self.viewModel = MinutesPodcastViewModel(minutes: minutes)
            if self.videoPlayer?.minutes !== minutes {
                let speed = self.videoPlayer?.playbackSpeed ?? 1.0
                let player = MinutesVideoPlayer(resolver: userResolver, minutes: minutes)
                player.playbackSpeed = speed
                self.videoPlayer = player
                // 切换下一首之后，update
                MinutesPodcast.shared.player = player
            }
            backgroundImageIndex = minutes.objectToken.hashValue
            MinutesPodcast.shared.loadBackgoundImage(index: backgroundImageIndex) { [weak self] image in
                if let imageView = self?.bgImageView as? UIImageView {
                    imageView.image = image
                } else if let background = self?.bgImageView as? MinutesPodcastBackgroundView {
                    background.image = image
                }
            }
        } else if MinutesPodcast.shared.isInPodcast {
            self.videoPlayer = nil
            self.currentToken = nil
            showInvalidView()
        } else if self.navigationController != nil {
            exitToMinutes()
        }
    }

    func loadPodcastData() {
        showLoadingView()
        let taskToken = currentToken
        viewModel.minutes.data.loadPodcast { [weak self] (result) in
            guard taskToken == self?.currentToken else { return }

            MinutesPodcastReciableTracker.shared.finishNetworkReqeust()

            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    self?.tracker.tracker(name: .minutesPodcastViewDev, params: ["action_name": "finished", "is_error": 0])
                    
                    MinutesLogger.podcast.info("load podcast success")
                    self?.setParagraphs(items)
                    MinutesPodcastReciableTracker.shared.finishDataProcess()
                    self?.hideLoadingView()
                    self?.exitButton.isHidden = true
                    self?.videoControlView?.isHidden = false
                    self?.bgImageView.isHidden = false
                case .failure(let error):
                    if let error = error as? ResponseError, error == .invalidJSONObject {
                        self?.setParagraphs([])
                        self?.hideLoadingView()
                        self?.exitButton.isHidden = true
                        self?.videoControlView?.isHidden = false
                        self?.bgImageView.isHidden = false
                        break
                    }
                    let extra = Extra(isNeedNet: true, category: ["object_token": taskToken])
                    MinutesReciableTracker.shared.error(scene: .MinutesPodcast,
                                                        event: .minutes_load_podcast_error,
                                                        error: error,
                                                        extra: extra)

                    MinutesLogger.podcast.warn("load podcast error: \(error)")
                    self?.showErrorView()
                    
                    var params: [String: Any] = ["action_name": "finished", "is_error": 1]
                    params["server_error_code"] = "\(error.minutes.code)"
                    self?.tracker.tracker(name: .minutesPodcastViewDev, params: params)
                }
                MinutesPodcastReciableTracker.shared.endEnterPodcast()
            }
        }
    }

    func addInvalideView() {
        view.addSubview(invalidTips)
        invalidTips.snp.remakeConstraints { maker in
            maker.center.equalToSuperview()
        }
    }

    func addEmptyView() {
        view.addSubview(emptyTips)
        emptyTips.snp.remakeConstraints { maker in
            //maker.height.equalTo(22)
            maker.centerX.equalTo(tableViewContainer)
            maker.centerY.equalTo(tableViewContainer)
            maker.left.greaterThanOrEqualToSuperview().offset(10)
            maker.right.lessThanOrEqualToSuperview().offset(-10)
        }
    }

    func addControllPannelView() {
        guard let pannel = videoControlView else { return }
        view.insertSubview(pannel, belowSubview: exitButton)
        pannel.snp.makeConstraints { maker in
            maker.left.right.bottom.equalToSuperview()
            maker.height.equalTo(videoControlViewHeight)
            maker.top.equalTo(tableViewContainer.snp.bottom)
        }
    }

    func addLoadingView() {
        view.addSubview(animateLoadingView)
        view.addSubview(loadingTips)
        animateLoadingView.snp.remakeConstraints { maker in
            maker.centerX.equalTo(tableViewContainer)
            maker.centerY.equalTo(tableViewContainer)
            maker.size.equalTo(72)
        }
        loadingTips.snp.remakeConstraints { maker in
            maker.centerX.equalTo(animateLoadingView)
            maker.top.equalTo(animateLoadingView.snp.bottom).offset(-10)
        }
    }

    func addErrorViewView() {
        view.addSubview(errorTips)
        view.addSubview(retryButton)
        errorTips.snp.remakeConstraints { maker in
            maker.height.equalTo(22)
            maker.centerX.equalTo(tableViewContainer)
            maker.centerY.equalTo(tableViewContainer)
            maker.left.greaterThanOrEqualToSuperview().offset(10)
            maker.right.lessThanOrEqualToSuperview().offset(-10)
        }
        retryButton.snp.remakeConstraints { maker in
            maker.width.equalTo(88)
            maker.height.equalTo(36)
            maker.centerX.equalTo(errorTips)
            maker.top.equalTo(errorTips.snp.bottom).offset(10)
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil, let player = videoPlayer, player.currentPlayerStatus != .paused, player.currentPlayerStatus != .stopped,
           MinutesPodcast.shared.isInPodcast {
            // 会议小窗下开启播客模式，返回时候结束播客播放
            
            let dependency = try? userResolver.resolve(assert: MinutesDependency.self)
            let isInMeeting = dependency?.meeting?.isInMeeting ?? false
            if isInMeeting {
                MinutesLogger.podcast.info("current isInMeeting, stop podcast")
                MinutesPodcast.shared.stopPodcast()
                return
            }

            MinutesPodcast.shared.player = player
            let podcastFloatingView = MinutesPodcastFloatingView(videoPlayer: player, resolver: userResolver)
            let minutes = self.viewModel.minutes
            podcastFloatingView.onTapViewBlock = { [weak self] resolver in
                DispatchQueue.main.async {
                    let body = MinutesPodcastBody(minutes: minutes, player: player)
                    guard let from = resolver.navigator.mainSceneTopMost else { return }
                    resolver.navigator.push(body: body, from: from, animated: true, completion: { (_, response) in
                        if response.error != nil { return }
                        MinutesPodcastSuspendable.removePodcastSuspendable()
                    })
                }
            }

            MinutesPodcastSuspendable.addPodcastSuspendable(customView: podcastFloatingView, size: MinutesPodcastFloatingView.viewSize)
        }
    }

    @objc func onBtnBack() {
        if Display.pad {
            onExit()
            return
        }
        tracker.tracker(name: .podcastPage, params: ["action_name": "back"])
        tracker.tracker(name: .podcastClick, params: ["click": "back", "target": "none"])

        if let player = videoPlayer, player.currentPlayerStatus != .paused, player.currentPlayerStatus != .stopped {
            popSelf()
        } else {
            popSelf(animated: true, dismissPresented: true) {
                MinutesPodcast.shared.stopPodcast()
            }
        }
    }

    @objc func onExit() {
        self.tracker.tracker(name: .podcastPage, params: ["action_name": "podcast_exit"])
        MinutesPodcast.shared.stopPodcast()
    }

    func exitToMinutes() {
        if let player = videoPlayer {
            // 退出播客设置详情的MPRemoteCommandCenter
            player.configRemoteCommandCenter()
            var controllers = self.navigationController?.viewControllers ?? []
            if controllers.last == self {
                let params = MinutesShowParams(minutes: viewModel.minutes, userResolver: userResolver, source: .podcast, destination: .detail)
                let detailVC = MinutesManager.shared.startMinutes(with: .detail, params: params)
                controllers.insert(detailVC, at: controllers.count - 1)
                controllers.removeLast()
                self.navigationController?.setViewControllers(controllers, animated: false)
            }
        } else {
            popSelf()
        }
    }

    private func addMinuteStatusObserver() {
        if viewModel.minutes.info.status == .ready {
            navigationBar.titleLabel.text = viewModel.minutes.basicInfo?.topic
            loadPodcastData()
        } else {
            showLoadingView()
            viewModel.minutes.info.listeners.addListener(self)
        }
    }

    func addPlayerCallback() {
        videoPlayer?.listeners.addListener(self)
    }

    func setParagraphs(_ subtitleData: [OverlaySubtitleItem]) {
        if subtitleData.isEmpty || viewModel.isSupportASR == false {
            showEmptyView()
            reloadData()
            return
        }
        hideLoadingView()
        exitButton.isHidden = true
        videoControlView?.isHidden = false
        viewModel.configure(containerWidth: self.view.bounds.width, subtitleItems: subtitleData)
        reloadData()

        DispatchQueue.main.async {
            var targetRowIndexPath = self.subtitleIndexPath(0)
            if self.tableView.indexPathExists(indexPath: targetRowIndexPath) {
                self.tableView.scrollToRow(at: targetRowIndexPath, at: .top, animated: false)
            }
        }
    }

    private func reloadData() {
        guard UIApplication.shared.applicationState == .active else { return }
        tableView.reloadData()
    }

    func getFormatedSpeedString() -> String {
        guard let speed = videoPlayer?.playbackSpeed else { return "1.0x" }
        let value = Double(speed)
        let titleString: String
        if value == 1.0 || value == 2.0 || value == 3.0 {
            titleString = String(format: "%.1fx", value)
        } else {
            titleString = String(format: "%gx", value)
        }
        return titleString
    }

    @objc func speedbuttonAction() {
        guard let player = videoPlayer else { return }
        player.tracker.tracker(name: .podcastPage, params: ["action_name": "adjust_button"])

        let vc = MinutesVideoPlayerSpeedViewController(.podcast)
        vc.player = player
        vc.onSelecteValueChanged = { [weak self] value in
            self?.navigationBar.updateSpeedButton(with: self?.getFormatedSpeedString() ?? "1.0x")
        }
        vc.onSkipSwitchValueChanged = { [weak self] value in
            player.shouldSkipSilence = value
        }
        userResolver.navigator.present(vc, from: self)
        player.tracker.tracker(name: .podcastSettingView, params: [:])
        player.tracker.tracker(name: .podcastClick, params: ["click": "setting", "target": "vc_minutes_podcast_setting_view"])
    }
}

extension MinutesPodcastViewController: MinutesInfoChangedListener{
    public func onMinutesInfoStatusUpdate(_ info: MinutesInfo) {
        if let error = info.lastError {
            let extra = Extra(isNeedNet: true, category: ["object_token": info.objectToken])

            MinutesReciableTracker.shared.error(scene: .MinutesPodcast,
                                                event: .minutes_load_podcast_error,
                                                userAction: info.lastAction,
                                                error: error,
                                                extra: extra)
        }

        DispatchQueue.main.async {
            switch info.status {
            case .ready:
                if self.minutesInfo?.status != .ready {
                    self.showLoadingView()
                }
                self.navigationBar.titleLabel.text = info.basicInfo?.topic
                self.loadPodcastData()

                self.minutesInfo = info
            default:
                break
            }
        }
    }
}

extension MinutesPodcastViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? viewModel.data.count : 1
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return headerViewHeight
        } else if indexPath.section == 1 {
            if indexPath.row >= 0 && indexPath.row < viewModel.data.count {
                return viewModel.data[indexPath.row].cellHeight
            } else {
                return 0
            }
        } else {
            return footerViewHeight
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return indexPath.section == 1 ? createSubtitleCell(tableView, indexPath: indexPath) : createDefaultCell(tableView, indexPath: indexPath)
    }

    func createSubtitleCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesPodcastLyricCell.description(), for: indexPath) as? MinutesPodcastLyricCell else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none
        let pVM: MinutesPodcastLyricViewModel = viewModel.data[indexPath.row]
        cell.configure(pVM, tag: indexPath.row)
        cell.didTextTappedBlock = { [weak self] in
            guard let self = self else { return }

            self.tracker.tracker(name: .podcastPage, params: ["action_name": "click_subtitles"])
            self.tracker.tracker(name: .podcastClick, params: ["click": "click_subtitles", "target": "none"])

            if indexPath.row == self.previousClickedIndex {
                // 1s内忽略播放器的回调
                self.didClickedSameLyric = true
                self.previousClickedTimer?.invalidate()
                self.previousClickedTimer = Timer(timeInterval: 1.0, repeats: false, block: { [weak self] (_) in
                    self?.didClickedSameLyric = false
                })
                if let timer = self.previousClickedTimer {
                    RunLoop.current.add(timer, forMode: .common)
                }
            } else {
                self.didClickedSameLyric = false
            }
            self.previousClickedIndex = indexPath.row

            self.syncTimeToPlayer(pVM.subtitleItem.startTime, didTappedRow: indexPath.row)
        }
        return cell
    }

    func createDefaultCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description(), for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        return cell
    }
}

extension MinutesPodcastViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isDragged = true
        autoScrollTimer?.invalidate()

        tracker.tracker(name: .podcastPage, params: ["action_name": "slide_subtitles"])
        tracker.tracker(name: .podcastClick, params: ["click": "slide_subtitles", "target": "none"])
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidStopped(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidStopped(scrollView)
    }

    func scrollViewDidStopped(_ scrollView: UIScrollView) {
        autoScrollTimer?.invalidate()
        autoScrollTimer = Timer(timeInterval: 3, repeats: false, block: { [weak self] (_) in
            self?.isDragged = false
        })
        if let timer = autoScrollTimer {
            RunLoop.current.add(timer, forMode: .common)
        }

        if isDragged, let vm = highlightedLyricVM {
            let totalHeight: CGFloat = viewModel.getCenterHeight(vm, headerViewHeight)
            if totalHeight != highlightedLyricTimeOffsetY {
                let currentOffsetY = scrollView.contentOffset.y

                var newOffsetY: CGFloat = currentOffsetY + totalHeight - highlightedLyricTimeOffsetY
                scrollView.setContentOffset(CGPoint(x: 0, y: newOffsetY), animated: true)
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isDragged {
            if let vm = viewModel.findHighlightedLyric(highlightedLyricTimeOffsetY, headerViewHeight) {
                highlightedLyricVM = vm
                lyricTimeView.lyricTimeLabel.text = vm.lyricStartTime
                lyricTimeViewWidth = vm.lyricStartTimeInterval > 3600 ? 58 : 45

                reloadData()
            }
        }
    }
}

extension MinutesPodcastViewController {
    func updateSubtitleOffset(_ timeInt: NSInteger?, index: NSInteger? = nil, manualTrigger: Bool? = false) {
        guard !isDragged else { return }
        // 保证给的时间必须大于数据的开始时间
        // 保证当前的时间不在此刻高亮的范围内
        guard let time = timeInt,
              let firstStartTime = viewModel.firstVMStartTime,
              time >= firstStartTime,
              matchedVM?.checkInInCurrentLyricRange(time) != true else {
            return
        }

        viewModel.clearTasks()
        serialQueue.async {
            var matchedVM: MinutesPodcastLyricViewModel? = self.viewModel.checkIsCurrentLyric(time, index: index)
            guard matchedVM != nil else {
                return
            }
            DispatchQueue.main.async {
                self.matchedVM = matchedVM

                if manualTrigger == true {
                    // 更新last offset
                    self.lastAutoScrollOffset = self.tableView.contentOffset.y
                }

                self.reloadData()
                // 等待reload完成
                DispatchQueue.main.async {
                    if !self.isDragged {
                        self.doScrollIfNeeded(podcastViewModel: matchedVM, manualTrigger: manualTrigger)
                    }
                }
            }
        }
    }
    // disable-lint: magic number
    func syncTimeToPlayer(_ startTime: Int, manualOffset: NSInteger = 0, didTappedRow: NSInteger? = nil) {
        let msSeconds = Double(startTime)
        let playbackTime = msSeconds * 0.001
        videoPlayer?.seekVideoPlaybackTime(playbackTime, manualOffset: manualOffset, didTappedRow: didTappedRow)
    }
    // enable-lint: magic number
    func subtitleIndexPath(_ row: NSInteger) -> IndexPath {
        return IndexPath(row: row, section: 1)
    }

    func doScrollIfNeeded(podcastViewModel: MinutesPodcastLyricViewModel?, isSearch: Bool = false, manualTrigger: Bool? = false) {
        guard let podcastViewModel = podcastViewModel else {
            return
        }
        let indexPath = subtitleIndexPath(podcastViewModel.pIndex)
        let totalHeight: CGFloat = viewModel.getHeight(podcastViewModel, headerViewHeight)
        scrollTo(offset: totalHeight - currentHighlightedLyricTop, manualTrigger: manualTrigger)
    }

    func scrollTo(offset: CGFloat, manualTrigger: Bool? = false) {
//        if manualTrigger == false, offset < lastAutoScrollOffset {
//            return
//        }

        guard offset > 0 else { return }
        guard tableView.contentOffset.y != offset else { return }
        guard isScrollingToRect == false else { return }
        DispatchQueue.main.async {
            self.isScrollingToRect = true
            self.tableView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self.isScrollingToRect = false
                self.lastAutoScrollOffset = self.tableView.contentOffset.y
            }
        }
    }
}

extension MinutesPodcastViewController: MinutesPodcastDelegate {
    func podcastMinutesChanged(data: Minutes?) {
        self.updateMinutes(data)
    }
}

extension MinutesPodcastViewController: MinutesVideoPlayerListener {
    func videoEngineDidLoad() {
    }

    func videoEngineDidChangedStatus(status: PlayerStatusWrapper) {
        if status.videoPlayerStatus == .playing {
            DispatchQueue.main.async {
                self.isDragged = false
            }
        }

        if status.videoPlayerStatus == .error, let objectToken = self.videoPlayer?.minutes.objectToken {
            let error = self.videoPlayer?.lastError ?? NSError(domain: "Load error", code: -1)
            let extra = Extra(isNeedNet: true, category: ["object_token": objectToken])

            MinutesReciableTracker.shared.error(scene: .MinutesPodcast,
                                                event: .minutes_media_play_error,
                                                page: "podcast",
                                                error: error,
                                                extra: extra)
            self.videoPlayer?.lastError = nil
        }
    }

    func videoEngineDidChangedPlaybackTime(time: PlaybackTime) {
        // 手动更新offset
        let manualOffset = time.payload[.manualOffset]
        guard manualOffset == 0 else {
            return
        }

        let row = time.payload[.didTappedRow]
        let manualTrigger: Bool = handle(time: time)

        // 避免快速点击相同歌词时候播放器同时播放给的回调导致的抖动
        if self.didClickedSameLyric == true {
            return
        }

        if time.time >= 0 {
            self.updateSubtitleOffset(time.millisecond,
                                      index: row,
                                      manualTrigger: manualTrigger)
        }
    }
    
    private func handle(time: PlaybackTime) -> Bool {
        // 点击了快进/快退/拖动进度条/点击进度条
        let resetDragging = time.payload[.resetDragging]
        let row = time.payload[.didTappedRow]
        if row == nil, let resetDragging = resetDragging, resetDragging != 0 {
            DispatchQueue.main.async {
                self.isDragged = false
            }
        }
        // 主动触发的
        let manualTrigger: Bool = (resetDragging != 0)
        return manualTrigger
    }
}
