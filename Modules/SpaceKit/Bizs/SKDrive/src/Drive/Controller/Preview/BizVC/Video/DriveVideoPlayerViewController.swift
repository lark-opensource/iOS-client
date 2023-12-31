//  swiftlint:disable file_length type_body_length

import UIKit
import SKFoundation
import TTVideoEngine
import LarkUIKit
import MediaPlayer
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignLoading
import RxSwift
import RxCocoa
import UniverseDesignToast
import UniverseDesignDialog
import ByteWebImage

class DriveVideoPlayerViewController: BaseViewController, UIGestureRecognizerDelegate {
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        if isInFullScreenMode {
            return UIRectEdge.top
        }
        return []
    }
    /// 是否允许横版视频进入全屏模式
    var landscapeModeEnable: Bool = true
    /// 是否允许竖版视频进入全屏模式
    var portraitFullScreenModeEnable: Bool = true

    var viewModel: DriveVideoPlayerViewModel

    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    weak var bizVCDelegate: DriveBizViewControllerDelegate?

    private let footerHeight: CGFloat = 68.0
    private let landscapeAnimateTime = 0.3
    private let downloadCoverEnable = UserScopeNoChangeFG.ZYP.downloadVideoCover

    private let netWorkFlowHelper = NetworkFlowHelper()

    private let headerView = DriveVideoDisplayHeaderView()
    private let footerView = DriveVideoDisplayFooterView()
    private let footerSafeAreaPlaceholderView = GradientView()
    private let coverImageView = ByteImageView()

    // Docx 卡片模式相关 UI
    private let cardModePlayBtn: DriveVideoTapButton = {
        let btn = DriveVideoTapButton(type: .custom)
        btn.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.4).nonDynamic
        btn.layer.cornerRadius = 24
        btn.setImage(UDIcon.playFilled.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        if #available(iOS 13.4, *) {
            btn.isPointerInteractionEnabled = true
            btn.pointerStyleProvider = { button, proposedEffect, proposedShape in
                var rect = button.bounds.insetBy(dx: -12, dy: -10)
                rect = button.convert(rect, to: proposedEffect.preview.target.container)
                return UIPointerStyle(effect: proposedEffect, shape: .roundedRect(rect))
            }
        }
        return btn
    }()

    // 卡片模式，初始状态显示视频时长
    private lazy var duarationLabel: DriveMarginLabel = {
        let label = DriveMarginLabel(frame: .zero)
        label.text = "00:00"
        label.textColor = UDColor.primaryOnPrimaryFill
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.backgroundColor = UDColor.bgMask.nonDynamic
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.margin = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        label.isHidden = true
        return label
    }()

    private var loadingIndicatorView: UDSpin = {
        let view = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 20, color: UDColor.N400), textLabelConfig: nil))
        view.isHidden = true
        return view
    }()

    var playerView: UIView {
        self.viewModel.engine.playerView
    }

    // 是否正在拖动进度条
    private var isSeekingSlider: Bool = false
    // 播放器是否已经准备好，准备好后才可以获得视频宽高
    private var videoPlayerDidPrepared: Bool = false

    private var supportedOrientations: UIInterfaceOrientationMask = [.portrait]

    private let tapHandler = DriveTapEnterFullModeHandler()

    private lazy var immersionTask: SKImmersionTask = {
        return SKImmersionTask(taskInterval: 5, event: {[weak self] in
            self?.enterImmersion()
        })
    }()

    /// 是否全屏
    private var isInFullScreenMode: Bool = false {
        didSet {
            if isInFullScreenMode {
                immersionTask.resume()
            } else {
                exitImmersion()
            }
        }
    }
    private let _panGesture = UIPanGestureRecognizer()
    private let disposeBag = DisposeBag()

    init(viewModel: DriveVideoPlayerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        viewModel.onVCDeinit()
        DocsLogger.driveInfo("DriveVideoPlayerViewController deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupVideoEngine()
        setupHeaderView()
        setupFooterView()
        setupVideoCover()
        setupCardModeBtn()
        setNavigationBarHidden(true, animated: false)
        view.accessibilityIdentifier = "drive.viewModel.videoInfo.view"
        configUI(displayMode: viewModel.displayMode)
        view.addGestureRecognizer(_panGesture)
        _panGesture.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.onViewWillAppear()
        if !viewModel.isFromCardMode {
            DocsLogger.driveInfo("gesture intercept: footerView intercept pop gesture")
            footerView.startInterceptPopGesture(gesture: self.navigationController?.interactivePopGestureRecognizer)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.onViewWillDisappear()
        if !(parent is CommonGestureDelegateRepeaterProtocol) && !viewModel.isFromCardMode {
            DocsLogger.driveInfo("gesture intercept: footerView stop pop gesture")
            footerView.stopInterceptPopGesture()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.footerView.slider.updateTrackProgress()
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return supportedOrientations
    }

    private func setupVideoEngine() {
        UIView.performWithoutAnimation {
            view.addSubview(viewModel.engine.playerView)
            viewModel.engine.playerView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            view.addSubview(loadingIndicatorView)
            loadingIndicatorView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
            view.layoutIfNeeded()
        }
        if viewModel.displayMode == .card && downloadCoverEnable {
            viewModel.setupVideoEngineV2(appState: UIApplication.shared.applicationState)
        } else {
            viewModel.setupVideoEngine(appState: UIApplication.shared.applicationState)
        }
    }

    private func setupViewModel() {
        viewModel.playerStatus
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] status in
                self?.handlerPlayerStatus(status)
        }).disposed(by: disposeBag)

        viewModel.playerLoadStateChanged
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] loadState in
                self?.handleVideoLoadState(loadState)
        }).disposed(by: disposeBag)

        viewModel.playbackState
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] playbackstate in
                self?.handlePlaybackState(playbackstate)
        }).disposed(by: disposeBag)

        viewModel.currentPlaybackTime
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] time in
                guard let self = self else { return }
                // 如果正在拖动进度条，无需更新当前播放进度
                guard self.isSeekingSlider == false else { return }
                self.set(currentPlaybackTime: time, duration: self.viewModel.engine.duration)
        }).disposed(by: disposeBag)

        viewModel.bindAction = { [weak self] action in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.handleViewModelAction(action)
            }
        }
    }

    private func handlerPlayerStatus(_ status: DriveVideoPlayerViewModel.VideoPlayerStatus) {
        switch status {
        case .prepared:
            videoPlayerDidPrepared = true
            DocsLogger.driveInfo("videoPlayerDidPrepared, openType: \(openType.rawValue)")
            bizVCDelegate?.openSuccess(type: openType)
            configFullScreenMode()
            headerView.isHidden = false
            coverImageView.isHidden = true
            if viewModel.displayMode == .normal { // 卡片模式，优先展示播放按钮、隐藏底部控制栏
                showFooterView(true, animate: false)
            }
            footerView.endTimeLabel.text = viewModel.engine.duration.timeIntervalToString
            duarationLabel.text = viewModel.engine.duration.timeIntervalToString
            immersionTask.resume()
        case .finished:
            DocsLogger.driveInfo("videoPlayerDidFinished")
            footerView.slider.setProgress(1, animated: false)
            footerView.startTimeLabel.text = footerView.endTimeLabel.text

            let params: [String: Any] = ["display": viewModel.displayMode.statisticValue,
                          "play_time": viewModel.engine.currentPlaybackTime * 1000]
            bizVCDelegate?.clickEvent(DocsTracker.EventType.driveFileOpenClick,
                                      clickEventType: DriveStatistic.DriveFileOpenClickEventType.mediaTime,
                                      params: params)

            if viewModel.displayMode == .card {
                resetCardMode()
            } else {
                exitImmersion()
            }
            setupPauseUI()
        case .failed(let extraInfo):
            bizVCDelegate?.previewFailed(self, needRetry: false, type: openType, extraInfo: extraInfo)
        case .unknow:
            break
        }
    }

    private func handleVideoLoadState(_ loadState: DriveVideoLoadState) {
        switch loadState {
        case .playable:
            self.dismissLoadingView()
        case .stalled, .unknown:
            self.showLoadingView()
        default:
            break
        }
    }

    private func handlePlaybackState(_ playbackState: DriveVideoPlaybackState) {
        var params: [String: Any] = ["display": viewModel.displayMode.statisticValue]
        DocsLogger.driveInfo("handlePlaybackState \(playbackState)")
        switch playbackState {
        case .playing:
            setupPlayingUI()
            bizVCDelegate?.statistic(action: .play, source: .videoPlay)
            bizVCDelegate?.clickEvent(DocsTracker.EventType.driveFileOpenClick,
                                      clickEventType: DriveStatistic.DriveFileOpenClickEventType.mediaPlay,
                                      params: params)
            let name = PowerConsumptionStatisticEventName.driveMeidaPlayStart
            let params = [PowerConsumptionStatisticParamKey.mediaType: viewModel.engine.mediaType.rawValue]
            PowerConsumptionExtendedStatistic.addEvent(name: name, params: params)
        case .paused:
            setupPauseUI()
            bizVCDelegate?.statistic(action: .pause, source: .videoPlay)
            bizVCDelegate?.clickEvent(DocsTracker.EventType.driveFileOpenClick,
                                      clickEventType: DriveStatistic.DriveFileOpenClickEventType.pause,
                                      params: params)
            params["play_time"] = viewModel.engine.currentPlaybackTime
            bizVCDelegate?.clickEvent(DocsTracker.EventType.driveFileOpenClick,
                                      clickEventType: DriveStatistic.DriveFileOpenClickEventType.mediaTime,
                                      params: params)
            let name = PowerConsumptionStatisticEventName.driveMeidaPlayStop
            let params = [PowerConsumptionStatisticParamKey.mediaType: viewModel.engine.mediaType.rawValue]
            PowerConsumptionExtendedStatistic.addEvent(name: name, params: params)
        case .stopped:
            let name = PowerConsumptionStatisticEventName.driveMeidaPlayStop
            let params = [PowerConsumptionStatisticParamKey.mediaType: viewModel.engine.mediaType.rawValue]
            PowerConsumptionExtendedStatistic.addEvent(name: name, params: params)
            // 目前之后切换分辨率会调用stop，为了避免切换后按钮突然变成播放按钮这里不做任何事情
        default:
            self.footerView.playButton.isSelected = false
        }
    }

    private func handleViewModelAction(_ action: DriveVideoPlayerViewModel.Action) {
        switch action {
        case .playDirectUrl(let url):
            playDirectUrl(url: url)
        case let .showInterruption(msg):
            showInterruptionDialog(msg: msg)
        case .showCover(let image):
            // 展示视频封面应该在播放器Prepare之前
            guard !videoPlayerDidPrepared else { return }
            coverImageView.image = image
            coverImageView.isHidden = false
            DocsLogger.driveInfo("loading video cover succeeded")
            bizVCDelegate?.openSuccess(type: .videoCover)
        }
    }

    private func showInterruptionDialog(msg: String) {
        let dialog = UDDialog()
        dialog.setContent(text: msg)
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Drive_Drive_OK)
        present(dialog, animated: true, completion: nil)
    }

    // MARK: - UI Handler
    @objc
    private func muteButtonClicked(_ sender: Any) {
        if viewModel.displayMode == .card {
            // iPad pointer卡片模式下，点击mute按钮会导致进入沉浸态,
            // 如果是卡片模式点击mute后退出沉浸态
            exitImmersion()
        }
        viewModel.engine.muted = !viewModel.engine.muted
        footerView.inMutedMode = viewModel.engine.muted
        immersionTask.resume()
        let isMute = viewModel.engine.muted ? "True" : "False"
        let params = ["preview": self.viewModel.displayMode.statisticValue,
                      "is_mute": isMute]
        self.bizVCDelegate?.clickEvent(DocsTracker.EventType.driveFileOpenClick, clickEventType: DriveStatistic.DriveFileOpenClickEventType.mediaVolume, params: params)
    }

    @objc
    private func cardModePlayBtnClick(_ sender: Any) {
        viewModel.play()
    }

    @objc
    private func magnifyButtonClick(_ sender: Any) {
        bizVCDelegate?.invokeDriveBizAction(.enterNormalMode)
        let params = ["preview": self.viewModel.displayMode.statisticValue,
                      "is_fullscreen": "True"]
        self.bizVCDelegate?.clickEvent(DocsTracker.EventType.driveFileOpenClick, clickEventType: DriveStatistic.DriveFileOpenClickEventType.mediaFullScreen, params: params)
    }

    @objc
    private func rotateButtonClicked(_ sender: Any) {
        bizVCDelegate?.invokeDriveBizAction(.dismissCommentVC)
        let isLandscape = LKDeviceOrientation.isLandscape()
        if autoRoateEnable {
            DocsLogger.driveInfo("uiState: rotateButtonClicked autoRotate fullScreen")
            // 系统控制自动旋转的情况
            let orientation: UIDeviceOrientation = isLandscape ? .portrait : .landscapeLeft
            LKDeviceOrientation.setOritation(orientation)
        } else {
            // 强制旋转情况
            DocsLogger.driveInfo("uiState: rotateButtonClicked force fullScreen")
            if isLandscape {
                supportedOrientations = [.portrait]
                LKDeviceOrientation.setOritation(UIDeviceOrientation.portrait)
            } else {
                supportedOrientations = [.landscape]
                if !UIApplication.shared.statusBarOrientation.isLandscape {
                    LKDeviceOrientation.setOritation(UIDeviceOrientation.landscapeLeft)
                }
            }
            let orien = isLandscape ? "portrait" : "landscape"
            let params = ["preview": self.viewModel.displayMode.statisticValue,
                          "media_display": orien]
            self.bizVCDelegate?.clickEvent(DocsTracker.EventType.driveFileOpenClick,
                                           clickEventType: DriveStatistic.DriveFileOpenClickEventType.mediaRotate,
                                           params: params)
        }
        footerView.slider.updateTrackProgress()
        setNeedsUpdateOfScreenEdgesDeferringSystemGestures()
    }

    @objc
    private func playButtonClicked(_ sender: Any) {
        if viewModel.engine.playbackState == .playing {
            DocsLogger.driveInfo("playBtn Clicked, set to pause, current state: playing")
            viewModel.pause()
            immersionTask.invalidate()
        } else {
            DocsLogger.driveInfo("playBtn Clicked, set to playing, current state: \(viewModel.engine.playbackState)")
            viewModel.play()
            immersionTask.resume()
        }
    }

    @objc
    private func moreButtonClicked(_ sender: Any) {
        immersionTask.resume()
        // 弹分辨率弹框
        var sheetStyle: DriveVideoActionSheet.Style = LKDeviceOrientation.isLandscape() ? .landscape : .protrait
        if SKDisplay.pad {
            sheetStyle = .protrait
        }
        let actionSheet = DriveVideoActionSheet(style: sheetStyle)
        viewModel.resolutionHandler.handleResolutionDatas { (isSelected, resolution) in
            let view = DriveResolutionView()
            view.isSelected = isSelected
            view.resolutionName = resolution
            actionSheet.addItemView(view) { [weak self] in
                guard let self = self else { return }
                self.immersionTask.resume()
                self.footerView.resolution = resolution
                self.viewModel.resolutionHandler.currentResolution = resolution
                let params = ["preview": self.viewModel.displayMode.statisticValue,
                              "quality": resolution]
                self.bizVCDelegate?.clickEvent(DocsTracker.EventType.driveFileOpenClick, clickEventType: DriveStatistic.DriveFileOpenClickEventType.mediaQuanlity, params: params)
                if let url = self.viewModel.resolutionHandler.currentUrl {
                    self.viewModel.engine.resume(url, taskKey: self.viewModel.resolutionHandler.taskKey)
                    // https://meego.feishu.cn/larksuite/issue/detail/14823372
                    self.viewModel.play()
                } else {
                    spaceAssertionFailure("切换码率必须有对应码率url")
                }
            }
        }
        if SKDisplay.pad && self.isMyWindowRegularSize() {
            actionSheet.preferredContentSize = CGSize(width: 320, height: viewModel.videoInfo.resolutionDatas.count * 56 + 20)
            actionSheet.modalPresentationStyle = .popover
            actionSheet.popoverPresentationController?.sourceView = footerView.moreButton
            actionSheet.popoverPresentationController?.sourceRect = footerView.moreButton.bounds
            actionSheet.popoverPresentationController?.permittedArrowDirections = .down
            actionSheet.popoverPresentationController?.backgroundColor = UDColor.bgFloat
        } else {
            actionSheet.addCancelItem()
        }
        present(actionSheet, animated: true, completion: nil)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        !isInFullScreenMode
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    var shouldHandleDismissGesture: Bool {
        !isInFullScreenMode
    }

    // 是否支持自动旋转
    var autoRoateEnable: Bool {
        parent?.supportedInterfaceOrientations == .allButUpsideDown
    }
}

// MARK: - private method
extension DriveVideoPlayerViewController {
    private func playDirectUrl(url: String) {
        let skipCheck = (viewModel.displayMode == .card) // 卡片模式不弹出流量提醒
        netWorkFlowHelper.process(viewModel.videoInfo.size,
                                  skipCheck: skipCheck,
                                  requestTask: { [weak self] in
            guard let self = self else { return }
            let autoPlay = self.viewModel.shouldAutoPlayForSetup(appState: UIApplication.shared.applicationState)
            let taskKey = self.viewModel.resolutionHandler.taskKey
            self.viewModel.setup(directUrl: url, taskKey: taskKey, autoPlay: autoPlay)
        }, judgeToast: {[weak self] in
            guard let self = self else { return }
            self.netWorkFlowHelper.presentToast(view: self.view, fileSize: self.viewModel.videoInfo.size)
        })
    }

    private func set(currentPlaybackTime: TimeInterval, duration: TimeInterval) {
        let currentTime = currentPlaybackTime > 0 ? currentPlaybackTime : 0
        footerView.startTimeLabel.text = currentTime.timeIntervalToString

        if duration > 0 {
            footerView.endTimeLabel.text = duration.timeIntervalToString
        }

        var playPercent = Float(currentPlaybackTime / duration)
        playPercent = min(max(0, playPercent), 1)
        footerView.slider.setProgress(playPercent, animated: false)
    }
}

// MARK: - UI
extension DriveVideoPlayerViewController {
    private func setupHeaderView() {
        statusBar.alpha = 0
        headerView.isHidden = true
        headerView.rotateButton.addTarget(self, action: #selector(rotateButtonClicked(_:)), for: .touchUpInside)
        UIView.performWithoutAnimation {
            playerView.addSubview(headerView)
            headerView.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.left.equalTo(playerView.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(playerView.safeAreaLayoutGuide.snp.right)
                make.height.equalTo(50)
            }
            view.layoutIfNeeded()
        }
    }

    private func setupFooterView() {
        footerView.isHidden = true
        footerView.playButton.addTarget(self, action: #selector(playButtonClicked(_:)), for: .touchUpInside)
        footerView.moreButton.addTarget(self, action: #selector(moreButtonClicked(_:)), for: .touchUpInside)
        footerView.magnifyButton.addTarget(self, action: #selector(magnifyButtonClick(_:)), for: .touchUpInside)
        footerView.muteButton.addTarget(self, action: #selector(muteButtonClicked(_:)), for: .touchUpInside)

        footerView.resolution = viewModel.resolutionHandler.currentResolution ?? ""
        footerView.slider.seekingToProgress = { [weak self] progress, finished in
            guard let self = self else { return }
            if finished {
                self.viewModel.engine.seek(progress: progress) { (_) in
                    DocsLogger.driveDebug("engine seek progress finished")
                    self.isSeekingSlider = false
                    self.immersionTask.resume()
                }
            } else {
                // 拖动进度条时更新当前拖动的时间
                let duration = self.viewModel.engine.duration
                let time = Double(progress) * duration
                self.set(currentPlaybackTime: time, duration: duration)
                self.isSeekingSlider = true
                self.exitImmersion()
            }
        }
        UIView.performWithoutAnimation {
            footerSafeAreaPlaceholderView.backgroundColor = UIColor.clear
            footerSafeAreaPlaceholderView.colors = [UDColor.staticBlack.withAlphaComponent(0), UDColor.staticBlack.withAlphaComponent(1)]
            footerSafeAreaPlaceholderView.locations = [0.0, 1.0]
            footerSafeAreaPlaceholderView.direction = .vertical
            footerSafeAreaPlaceholderView.alpha = 0.5
            playerView.addSubview(footerSafeAreaPlaceholderView)
            playerView.addSubview(footerView)
            footerView.snp.makeConstraints { (make) in
                make.bottom.equalTo(playerView.safeAreaLayoutGuide.snp.bottom)
                make.left.equalTo(playerView.safeAreaLayoutGuide.snp.left)
                make.right.equalTo(playerView.safeAreaLayoutGuide.snp.right)
                make.height.equalTo(footerHeight)
            }
            footerSafeAreaPlaceholderView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(footerView.snp.top)
            }
            view.layoutIfNeeded()
        }

        // 播放本地文件，或者仅有一个分辨率选项，需要隐藏切换分辨率按钮
        if viewModel.videoInfo.info == nil || viewModel.videoInfo.resolutionDatas.count <= 1 {
            footerView.hideMoreButton()
        }
    }

    private func setupVideoCover() {
        guard viewModel.displayMode == .card, downloadCoverEnable else { return }
        view.backgroundColor = mainBackgroundColor
        coverImageView.contentMode = .scaleAspectFit
        view.addSubview(coverImageView)
        coverImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        coverImageView.isHidden = true
        duarationLabel.isHidden = true
        // 开始加载视频封面
        viewModel.loadVideoCover()
    }

    private func setupCardModeBtn() {
        cardModePlayBtn.addTarget(self, action: #selector(cardModePlayBtnClick(_:)), for: .touchUpInside)
        view.addSubview(cardModePlayBtn)
        cardModePlayBtn.snp.makeConstraints { make in
            make.width.height.equalTo(48)
            make.center.equalToSuperview()
        }

        view.addSubview(duarationLabel)
        duarationLabel.snp.makeConstraints { make in
            make.height.equalTo(16.0)
            make.bottom.equalToSuperview().offset(-8.0)
            make.left.equalToSuperview().offset(12.0)
        }

        hideCardButton()
    }

    private func enterImmersion() {
        showFooterView(false, animate: true)
        headerView.isHidden = true
        immersionTask.isImmersion = true
        // 卡片模式下需要隐藏标题栏
        if viewModel.displayMode == .card {
            bizVCDelegate?.invokeDriveBizAction(.showCardModeNavibar(isShow: false))
        }
        if changeScreenModeEnable() {
            self.screenModeDelegate?.changePreview(situation: .fullScreen)
        }
    }

    private func exitImmersion() {
        showFooterView(true, animate: true)
        headerView.isHidden = false
        immersionTask.isImmersion = false
        immersionTask.invalidate()
        if viewModel.displayMode == .card {
            bizVCDelegate?.invokeDriveBizAction(.showCardModeNavibar(isShow: true))
        }
        if viewModel.displayMode == .normal {
            screenModeDelegate?.changePreview(situation: .exitFullScreen)
        }
        if changeScreenModeEnable() {
            self.screenModeDelegate?.changePreview(situation: .exitFullScreen)
        }
    }

    private func showFooterView(_ show: Bool, animate: Bool) {
        if animate {
            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
            } completion: { _ in
                self.footerView.isHidden = !show
                self.footerSafeAreaPlaceholderView.isHidden = !show
            }
        } else {
            self.footerView.isHidden = !show
            self.footerSafeAreaPlaceholderView.isHidden = !show
        }
    }

    private func configFullScreenMode() {
        tapHandler.addTapGestureRecognizer(targetView: view) { [unowned self] in
            // 卡片态大播放按钮存在情况下，不响应点击沉浸态
            guard cardModePlayBtn.isHidden else { return }
            if self.immersionTask.isImmersion {
                self.exitImmersion()
                self.immersionTask.resume()
            } else {
                self.enterImmersion()
            }
        }
        configFullScreenBtn()
    }

    private func configFullScreenBtn() {
        if viewModel.engine.isLandscapeVideo {
            guard landscapeModeEnable else {
                DocsLogger.driveInfo("LandscapeVideo Disable landcapeMode")
                return
            }
            let shouldShow = shouldShowFullScreenBtnOnLandScapeVideo()
            headerView.rotateButton.isHidden = !shouldShow
        }
    }

    private func changeScreenModeEnable() -> Bool {
        guard viewModel.displayMode == .normal else { return false }
        if !viewModel.engine.isLandscapeVideo {
            return portraitFullScreenModeEnable
        }
        return true
    }

    private func showLoadingView() {
        loadingIndicatorView.isHidden = false
        loadingIndicatorView.reset()
    }

    private func dismissLoadingView() {
        loadingIndicatorView.isHidden = true
    }

    private func setupPlayingUI() {
        footerView.playButton.isSelected = true
        coverImageView.isHidden = true
        hideCardButton()
        showFooterView(true, animate: true)
        if viewModel.displayMode == .card {
            footerView.setupCardMode()
            bizVCDelegate?.invokeDriveBizAction(.showCardModeNavibar(isShow: true))
        }
        immersionTask.resume()
    }

    private func setupPauseUI() {
        footerView.playButton.isSelected = false
        if viewModel.displayMode == .card {
            return
        }
        exitImmersion()
    }
    
    private func shouldShowFullScreenBtnOnLandScapeVideo() -> Bool {
        if viewModel.displayMode == .card {
            return false
        } else {
            let bugOSVersions = DriveFeatureGate.orientationBugSystems
            DocsLogger.driveInfo("show force landscape buton, bugOSVersions: \(bugOSVersions)")
            let systemVersion = UIDevice.current.systemVersion
            let isBugOS = bugOSVersions.contains(systemVersion)
            if isBugOS && SKDisplay.phone {
                // 部分 iOS16 版本强制横屏旋转系统有Bug，这里隐藏旋转按钮
                return false
            }
            return true
        }
    }
}

// MARK: - AutoRotateAjustable
extension DriveVideoPlayerViewController: DriveAutoRotateAdjustable {
    func orientationDidChange(orientation: UIDeviceOrientation) {
        guard viewModel.displayMode == .normal else { return }
        if orientation == .portrait {
            screenModeDelegate?.changePreview(situation: .exitFullScreen)
        }
    }
}

// MARK: - 卡片模式
extension DriveVideoPlayerViewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        if viewModel.engine is DriveAVPlayer {
            return .avplayer_local
        } else { // 区分本地视频、转码后视频和源地址播放
            switch viewModel.videoInfo.type {
            case let .local(_):
                return .ttplayer_local
            case let .online(_):
                if viewModel.videoInfo.info != nil {
                    return .ttplayer_online
                } else {
                    return .ttplayer_sourceURL
                }
            }
        }
    }

    var customGestureView: UIView? {
        guard !footerView.isHidden else {
            return nil
        }
        return footerView.slider
    }

    var panGesture: UIPanGestureRecognizer? {
        return _panGesture
    }

    var mainBackgroundColor: UIColor {
        return UIColor.ud.N900.nonDynamic
    }

    func willUpdateDisplayMode(_ mode: DrivePreviewMode) {

    }

    func changingDisplayMode(_ mode: DrivePreviewMode) {
        DocsLogger.driveInfo("uiState: changingDisplayMode: \(mode)")
        self.viewModel.displayMode = mode
        self.configFullScreenBtn()
        self.footerView.isHidden = true
    }

    func updateDisplayMode(_ mode: DrivePreviewMode) {
        DocsLogger.driveInfo("uiState: updateDisplayMode: \(mode)")
        self.viewModel.displayMode = mode
        self.footerView.isHidden = false
        configUI(displayMode: mode)
        if mode == .card {
            immersionTask.resume()
        }
        // 横屏下从卡片切换到Normal隐藏导航栏
        if mode == .normal && SKDisplay.phone && LKDeviceOrientation.isLandscape() {
            enterImmersion()
        }
        // VCFollow 下且作为 Follwer 时，CardMode 和 NormalMode 切换时，暂停视频播放，目的是与 PC 端同步
        if viewModel.followAPIDelegate?.followRole == .follower {
            viewModel.pause()
        }
    }

    private func configUI(displayMode: DrivePreviewMode) {
        footerView.setupUI(displayMode: displayMode)
        switch displayMode {
        case .card:
            if viewModel.engine.playbackState != .playing {
                showCardButton()
                showFooterView(false, animate: false)
            } else {
                hideCardButton()
            }
        case .normal:
            let orientation = LKDeviceOrientation.convertMaskOrientationToDevice(UIApplication.shared.statusBarOrientation)
            if orientation.isLandscape && SKDisplay.phone {
                isInFullScreenMode = orientation.isLandscape
            }
            hideCardButton()
            showFooterView(true, animate: true)
        }
    }

    private func showCardButton() {
        cardModePlayBtn.isHidden = false
        duarationLabel.isHidden = downloadCoverEnable
    }

    private func hideCardButton() {
        cardModePlayBtn.isHidden = true
        duarationLabel.isHidden = true
    }

    private func resetCardMode() {
        showCardButton()
        footerView.resetCardMode()
        showFooterView(false, animate: false)
        bizVCDelegate?.invokeDriveBizAction(.showCardModeNavibar(isShow: false))
    }
}
