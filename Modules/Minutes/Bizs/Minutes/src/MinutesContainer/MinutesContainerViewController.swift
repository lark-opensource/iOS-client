//
//  MinutesDetailViewControllert.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import EENavigator
import LarkAlertController
import UniverseDesignToast
import AppReciableSDK
import UIKit
import MinutesInterface
import LarkContainer
import LarkUIKit
import LarkSetting
import LarkGuide

public final class MinutesContainerViewController: UIViewController, UserResolverWrapper {

    static var isFirtLoad = true

    enum Layout {
        static let margin: CGFloat = 8
        static let navigationHeight: CGFloat = 60
        static let cornerRadius: CGFloat = Display.pad ? 8 : 0
    }

    private var minutesLoadingVC: MinutesLoadingViewController?
    private var minutesErrorStatusVC: MinutesErrorStatusViewController?
    private(set) var leftMinutesDetail: MinutesDetailViewController?
    private(set) var rightMinutesDetail: MinutesDetailViewController?
    private var minutesAudioPreviewVC: MinutesAudioPreviewController?
    private var minutesAudioRecordVC: MinutesAudioRecordingController?
    private var minutesClipVC: MinutesClipViewController?

    lazy var subtitlesViewController: MinutesSubtitlesViewController = {
        let subtitles = MinutesSubtitlesViewController(resolver: userResolver, minutes: viewModel.minutes)
        subtitles.source = source
        subtitles.destination = destination
        subtitles.title = MinutesPageType.text.title
        subtitles.player = isText ? nil : videoPlayer
        return subtitles
    }()

    lazy var infoViewController: MinutesInfoViewController = {
        let infos = MinutesInfoViewController(resolver: userResolver, minutes: viewModel.minutes)
        infos.title = MinutesPageType.info.title
        infos.onClickItem = { [weak self] in
            self?.videoPlayer.pause()
        }
        return infos
    }()

    lazy var speakerController: MinutesSpeakersViewController = {
        let viewController = MinutesSpeakersViewController(resolver: userResolver, minutes: viewModel.minutes, player: videoPlayer)
        viewController.title = MinutesPageType.speaker.title
        return viewController
    }()

    lazy var chapterController: MinutesChapterViewController = {
        let viewController = MinutesChapterViewController(resolver: userResolver, minutes: viewModel.minutes, player: videoPlayer)
        viewController.title = MinutesPageType.chapter.title
        return viewController
    }()

    lazy var summaryViewController: MinutesSummaryViewController = {
        let summaryViewController = MinutesSummaryViewController(resolver: userResolver, minutes: viewModel.minutes)
        summaryViewController.title = MinutesPageType.summary.title
        summaryViewController.videoPlayer = videoPlayer
        return summaryViewController
    }()

    // 纯转录
    lazy var transcriptProgressBar: MinutesTranscriptProgressBar = {
        let view = MinutesTranscriptProgressBar(resolver: userResolver)
        view.videoDuration = viewModel.minutes.basicInfo?.duration ?? 0
        view.sliderValueDidChanged = { [weak self] progress, time in
            if time != 0 {
                self?.subtitlesViewController.isDragged = false
            }
        }
        let lastTime = (self.subtitlesViewController.viewModel.lastTextTime ?? 0.0) * 1000
        view.updateSliderOffset(Int(lastTime))
        return view
    }()

    var leftPages: [MinutesDetailPage] = []
    var rightPages: [MinutesDetailPage] = []

    let viewModel: MinutesContainerViewModel

    var videoPlayer: MinutesVideoPlayer { session.player }

    var source: MinutesSource? { session.source }
    var destination: MinutesDestination? { session.destination }

    var tracker: MinutesTracker { session.tracker }
    var isTrackedDev: Bool = false
    
    public var userResolver: UserResolver { session.userResolver }

    let session: MinutesSession

    var contentGuide: UILayoutGuide = UILayoutGuide()

    lazy var loadingContentView: UIView = {
        let v = UIView()
        v.backgroundColor = .ud.bgBody
        v.layer.cornerRadius = Layout.cornerRadius
        v.layer.shadowColor = UIColor(red: 0.122, green: 0.137, blue: 0.161, alpha: 0.08).cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    lazy var leftContentView: UIView = {
        let v = UIView()
        v.backgroundColor = .ud.bgBody
        v.layer.cornerRadius = Layout.cornerRadius
        v.layer.shadowColor = UIColor(red: 0.122, green: 0.137, blue: 0.161, alpha: 0.08).cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    lazy var rightContentView: UIView = {
        let v = UIView()
        v.backgroundColor = .ud.bgBody
        v.layer.cornerRadius = Layout.cornerRadius
        v.layer.shadowColor = UIColor(red: 0.122, green: 0.137, blue: 0.161, alpha: 0.08).cgColor
        v.layer.shadowOpacity = 1
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }()

    lazy var navigationBar: MinutesDetailPadNavigationBar = {
        let bar = MinutesDetailPadNavigationBar()
        bar.backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        bar.moreButton.addTarget(self, action: #selector(moreAction), for: .touchUpInside)
        bar.doneButton.addTarget(self, action: #selector(finishEditSpeaker), for: .touchUpInside)
        bar.closeButton.addTarget(self, action: #selector(closeSceneAction), for: .touchUpInside)
        bar.clipLinkBlock = { [weak self] in
            self?.minutesClipVC?.goToOriginalMinutes()
        }
        return bar
    }()

    lazy var videoView: MinutesVideoView = {
        let view = MinutesVideoView(resolver: userResolver, player: videoPlayer, isInCCMfg: viewModel.minutes.basicInfo?.isInCCMfg == true)
        view.miniControllBar.backCallback = { [weak self] in
            guard let `self` = self else {
                return
            }
            if self.videoView.isFullscreen {
                self.fullplayVC?.dismiss(animated: false, completion: {
                    self.videoView.isFullscreen = false
                    self.leftMinutesDetail?.recoverVideoView()
                })
            } else {
                self.backAction()
            }

        }
        view.miniControllBar.moreCallback = { [weak self] in
            guard let `self` = self else {
                return
            }
            self.didClickMore()
        }
        view.miniControllBar.fullscreenBlock = { [weak self, weak view] in
            guard let self = self else { return }

            self.videoView.isFullscreen = true
            let vc = MinutesFullscreenPlayViewController(resolver: self.userResolver, videoView: self.videoView, player: self.videoPlayer)
            self.fullplayVC = vc
            vc.detailVC = self.leftMinutesDetail
            vc.modalPresentationStyle = .fullScreen
//            vc.transitioningDelegate = vc
            self.present(vc, animated: false)
            view?.updateUIStyle(true)
        }
        return view
    }()


    weak var fullplayVC: MinutesFullscreenPlayViewController?

    /// 判断是否左右分屏
    var isRegular: Bool {
        Display.pad && ScreenUtils.sceneScreenSize.width > ScreenUtils.sceneScreenSize.height && layoutWidth > 800
    }

    /// 判断present方式
    var isSceneRegular: Bool { Display.pad && traitCollection.horizontalSizeClass == .regular }

    @ScopedProvider var featureGatingService: FeatureGatingService?
    @ScopedProvider var guideService: NewGuideService?

    private var isSummaryViewControllerEnable: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .aiSummaryVisible) == true && viewModel.minutes.basicInfo?.isAiAnalystSummary == true && viewModel.minutes.basicInfo?.summaryStatus != .notSupport
    }

    private var isChapterViewControllerEnable: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .aiChaptersVisible) == true && isSummaryViewControllerEnable && viewModel.minutes.basicInfo?.agendaStatus != .notSupport
    }

    var isText: Bool {
        return viewModel.minutes.basicInfo?.mediaType == .text
    }


    private var isMinutesReady: Bool = false
    private var lastBounds: CGRect = .zero
    private var leftWidth: CGFloat = 0
    private var rightWidth: CGFloat = 0
    private var subtitleLayoutWidth: CGFloat { isRegular ? rightWidth : leftWidth }
    private var isCommonMinutes: Bool = false

    private var layoutWidth: CGFloat = 0

    let limitLength = 80 //重命名最大字数

    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }

    var currentTranslationChosenLanguage: Language = .default {
        didSet {
            leftMinutesDetail?.currentTranslationChosenLanguage = currentTranslationChosenLanguage
            rightMinutesDetail?.currentTranslationChosenLanguage = currentTranslationChosenLanguage
        }
    }

    var isVisible: Bool {
        isViewLoaded && view.window != nil
    }

    init(session: MinutesSession) {
        self.session = session
        self.viewModel = session.resolver.resolve()!
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        session.willLeaveMinutes()
        MinutesLogger.detail.info("container vc deinit")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if #available(iOS 16.0, *) {
            let shouldShowVideoView = !(videoPlayer.isAudioOnly)
            if shouldShowVideoView {
                return .allButUpsideDown
            } else {
                return .portrait
            }
        } else {
            return .allButUpsideDown
        }
    }

    public override var shouldAutorotate: Bool {
        if #available(iOS 16.0, *) {
            return false
        } else {
            if let firstViewController = self.children.first {
                return firstViewController.shouldAutorotate
            }
            return false
        }
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if videoPlayer.isAudioOnly || leftMinutesDetail?.isEditingSpeaker == true || Display.pad {
            return .default
        } else {
            return .lightContent
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        subtitlesViewController.savePlayInfo(false)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .ud.bgContentBase
        view.addLayoutGuide(contentGuide)
        updateContentLayoutGuide()

        addNavigationBarIfNeeded()
        addContentView()

        showMinutesLoadingVC()
        addMinuteStatusObserver()
        
        tracker.tracker(name: .minutesDetailViewDev, params: ["action_name": "entry_page", "is_error": 0, "token": viewModel.minutes.data.objectToken])
        tracker.tracker(name: .detailView, params: ["if_ai_minutes": isSummaryViewControllerEnable])

        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentLayout(width: view.bounds.width)
        updateNavigationLayoutIfNeeded()
    }

    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if Self.isFirtLoad { /// 冷启首次打开size的值不对
            Self.isFirtLoad = false
            return
        }
        let oldBounds = view.bounds
        coordinator.animate { [weak self] _ in
            guard let self = self else { return }
            let newBounds = self.view.bounds
            let layoutWidth = oldBounds == newBounds ? size.width : newBounds.width
            self.updateContentLayout(width: layoutWidth)
            self.createRightDetailIfNeeded()
            self.updatePages()
        }
        if Display.pad, isVisible, presentedViewController != nil, !(presentedViewController is MinutesFullscreenPlayViewController) {
            dismiss(animated: false)
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // YYLabel在不重新渲染的情况下，在系统中手动设置dark和light模式时候，无法自动变化
        if #available(iOS 13.0, *), Display.pad {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                navigationBar.config(with: viewModel.minutes)
            }
        }

        self.dependency?.messenger?.dismissEnterpriseTopic()
    }
}

extension MinutesContainerViewController {

    private func updateContentLayoutGuide() {
        if Display.pad {
            contentGuide.snp.remakeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.navigationHeight + Layout.margin)
                make.left.right.bottom.equalTo(view.safeAreaLayoutGuide).inset(Layout.margin)
            }
        } else {
            contentGuide.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    private func addNavigationBarIfNeeded() {
        if Display.pad {
            view.addSubview(navigationBar)
            if couldCloseScene {
                if navigationController?.viewControllers.first == self {
                    navigationBar.backButton.isHidden = true
                    navigationBar.closeButton.isHidden = false
                } else {
                    navigationBar.backButton.isHidden = false
                    navigationBar.closeButton.isHidden = true
                }
            } else {
                navigationBar.backButton.isHidden = false
                navigationBar.closeButton.isHidden = true
            }
        }
    }


    private func updateNavigationLayoutIfNeeded() {
        if Display.pad {
            navigationBar.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: Layout.navigationHeight + view.safeAreaInsets.top)
        }
    }

    private func updateNavigationBarIfNeeded() {
        if Display.pad {
            navigationBar.config(with: viewModel.minutes)
        }
    }

    private func addContentView() {
        view.addSubview(leftContentView)
        view.addSubview(rightContentView)
        updateContentLayout(width: view.safeAreaLayoutGuide.layoutFrame.width)
        view.addSubview(loadingContentView)
        loadingContentView.snp.makeConstraints { make in
            make.edges.equalTo(contentGuide)
        }
    }

    private func updateContentLayout(width: CGFloat) {
        layoutWidth = width
        let contentWidth = width - Layout.margin * 3
        let leftWidth = isRegular ? contentWidth * 4 / 7 : (Display.pad ? width - Layout.margin * 2 : width)
        let rightWidth = isRegular ? contentWidth * 3 / 7 : 0
        if Display.pad {
            leftContentView.snp.remakeConstraints { make in
                make.top.left.bottom.equalTo(contentGuide)
                make.width.equalTo(leftWidth)
            }
            rightContentView.snp.remakeConstraints { make in
                make.top.right.bottom.equalTo(contentGuide)
                make.width.equalTo(rightWidth)
            }
        } else {
            leftContentView.snp.remakeConstraints { make in
                make.edges.equalTo(contentGuide)
            }
        }
        rightContentView.isHidden = !isRegular
        self.leftWidth = leftWidth
        self.rightWidth = rightWidth
    }

    private func updatePages() {
        if isRegular {
            if isText == false {
                leftPages = [speakerController, infoViewController]
            } else {
                leftPages = [infoViewController]
            }
            rightPages = []
            if isSummaryViewControllerEnable {
                summaryViewController.layoutWidth = subtitleLayoutWidth
                rightPages.append(summaryViewController)
            }
            if isChapterViewControllerEnable {
                chapterController.layoutWidth = subtitleLayoutWidth
                rightPages.append(chapterController)
            }

            rightPages.append(subtitlesViewController)
            if let type = leftMinutesDetail?.selectedType, type.isRightPageType {
                rightMinutesDetail?.selectedType = type
            }
        } else {
            leftPages = []
            if isSummaryViewControllerEnable {
                summaryViewController.layoutWidth = subtitleLayoutWidth
                leftPages.append(summaryViewController)
            }
            if isChapterViewControllerEnable {
                chapterController.layoutWidth = subtitleLayoutWidth
                leftPages.append(chapterController)
            }
            if isText == false {
                leftPages.append(contentsOf: [subtitlesViewController, speakerController, infoViewController])
            } else {
                leftPages.append(contentsOf: [subtitlesViewController, infoViewController])
            }
            rightPages = []
        }
        leftMinutesDetail?.updatePages(leftPages)
        rightMinutesDetail?.updatePages(rightPages)
        subtitlesViewController.layoutWidth = subtitleLayoutWidth
    }
}

extension MinutesContainerViewController {

    @objc private func backAction() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            navigationController?.popViewController(animated: true)
        } else if isInSplitDetail {
            larkSplitViewController?.cleanSecondaryViewController()
        } else {
            navigationController?.dismiss(animated: true)
        }
    }

    @objc private func moreAction() {
        didClickMore()
    }

    @objc private func finishEditSpeaker() {
        if isRegular {
            rightMinutesDetail?.isEditingSpeaker = false
        } else {
            leftMinutesDetail?.isEditingSpeaker = false
        }
        navigationBar.isEditSpeaker = false
    }

    @objc private func closeSceneAction() {
        exitScene()
    }

    @objc private func willEnterForeground() {
        updateNavigationBarIfNeeded()
    }
}

// MARK: - Error Status Handler

extension MinutesContainerViewController: MinutesDataChangedListener {
    public func onMinutesDataStatusUpdate(_ data: MinutesData) {
        MinutesLogger.detail.info("onMinutesDataStatusUpdate: \(data.status)")
        
        if let error = data.lastError {
            let extra = Extra(isNeedNet: true, category: ["object_token": data.objectToken])

            MinutesReciableTracker.shared.error(scene: .MinutesDetail,
                                                event: .minutes_load_detail_error,
                                                userAction: data.lastAction,
                                                error: error,
                                                extra: extra)
            
            if !isTrackedDev {
                tracker.tracker(name: .minutesDetailViewDev, params: ["action_name": "finished", "is_error": 1, "token": viewModel.minutes.data.objectToken, "server_error_code": "\(error.minutes.code)"])
                isTrackedDev = true
            }
        }

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

extension MinutesContainerViewController: MinutesInfoChangedListener {
    public func onMinutesInfoStatusUpdate(_ info: MinutesInfo) {
        MinutesLogger.detail.info("onMinutesInfoStatusUpdate: \(info.status)")
        
        if let error = info.lastError {
            let extra = Extra(isNeedNet: true, category: ["object_token": info.objectToken])

            MinutesReciableTracker.shared.error(scene: .MinutesDetail,
                                                event: .minutes_load_detail_error,
                                                userAction: info.lastAction,
                                                error: error,
                                                extra: extra)
            if !isTrackedDev {
                tracker.tracker(name: .minutesDetailViewDev, params: ["action_name": "finished", "is_error": 1, "token": viewModel.minutes.data.objectToken, "server_error_code": "\(error.minutes.code)"])
                isTrackedDev = true
            }
        }

        DispatchQueue.main.async {
            switch info.status {
            case .unkown:
                self.showMinutesLoadingVC()
            case .authFailed, .noPermission, .pathNotFound,
                .resourceDeleted, .serverError, .transcoding, .otherError:
                self.showMinutesErrorStatusVC()
            case .audioRecording:
                self.checkMinutesReady()
            case .ready:
                self.checkMinutesReady()
            default:
                break
            }

            if info.status == .resourceDeleted {
                self.videoPlayer.stop()
            }
        }
    }
    public func onMinutesInfoObjectStatusUpdate(newStatus: ObjectStatus, oldStatus: ObjectStatus) {
        let needUpdate = self.minutesErrorStatusVC != nil
        let statusChanged = oldStatus != newStatus
        if  needUpdate && statusChanged {
            viewModel.minutes.refresh(catchError: false)
        }
    }
}

extension MinutesContainerViewController {

    private func addMinuteStatusObserver() {
        viewModel.minutes.data.listeners.addListener(self)
        viewModel.minutes.info.listeners.addListener(self)
        checkMinutesReady()
    }

    // entry: 3
    private func checkMinutesReady() {
        let info = viewModel.minutes.info
        let data = viewModel.minutes.data
        let translateData = viewModel.minutes.translateData
        if leftMinutesDetail?.isInTranslationMode == true, let translateData = translateData {
            if info.status == .ready && translateData.status == .ready {
                onMinutesReady(info: info, data: translateData, isFirstRequest: data.isFirstRequest)
            } else if info.status == .audioRecording, info.basicInfo != nil {
                onMinutesReady(info: info, data: translateData, isFirstRequest: translateData.isFirstRequest)
            }
        } else {
            // 两个都ready再进来，此后仅仅更新info，data是没有更新的
            if info.status == .ready && data.status == .ready {
                onMinutesReady(info: info, data: data, isFirstRequest: data.isFirstRequest)
            } else if info.status == .audioRecording, info.basicInfo != nil {
                onMinutesReady(info: info, data: data, isFirstRequest: data.isFirstRequest)
            }
        }
    }

    // entry: 4
    private func onMinutesReady(info: MinutesInfo, data: MinutesData, isFirstRequest: Bool) {
        isMinutesReady = true
        let didCompleted = { [weak self] in
            if info.status == .audioRecording {
                MinutesDetailReciableTracker.shared.cancelEnterDetail()
            } else {
                MinutesDetailReciableTracker.shared.endEnterDetail()
            }
        }
        updateNavigationBarIfNeeded()
        hideMinutesLoadingVC()
        hideMinutesErrorStatusVC()
        if info.status == .audioRecording {
            if viewModel.minutes.basicInfo?.isRecordingDevice == true {
                if showAudioRecordVC() {
                    minutesAudioRecordVC?.onMinutesStatusReady(info)
                    minutesAudioRecordVC?.onMinutesDataReady(data, didCompleted: didCompleted)
                }
            } else {
                if showAudioPreviewVC() {
                    minutesAudioPreviewVC?.onMinutesDataReady(data, didCompleted: didCompleted)
                }
            }
        }
        else {
            if viewModel.minutes.isClip == false {
                if showMinutesDetailVC() {
                    leftMinutesDetail?.onMinutesStatusReady(info, isFirstRequest: isFirstRequest)
                    leftMinutesDetail?.onMinutesDataReady(data, isFirstRequest: isFirstRequest, didCompleted: didCompleted)
                    rightMinutesDetail?.onMinutesStatusReady(info, isFirstRequest: isFirstRequest)
                    rightMinutesDetail?.onMinutesDataReady(data, isFirstRequest: isFirstRequest, didCompleted: didCompleted)
                    if #available(iOS 16.0, *) {
                        self.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                }
            } else {
                if showMinutesClipVC() {
                    minutesClipVC?.onMinutesStatusReady(info)
                    minutesClipVC?.onMinutesDataReady(data, didCompleted: didCompleted)
                    if #available(iOS 16.0, *) {
                        self.setNeedsUpdateOfSupportedInterfaceOrientations()
                    }
                }
            }
        }
    }

    private func showMinutesLoadingVC() {
        if minutesLoadingVC != nil { return }
        if minutesErrorStatusVC != nil { hideMinutesErrorStatusVC() }

        createLoadingVC()
    }

    private func hideMinutesLoadingVC() {
        if let someMinutesLoadingVC = minutesLoadingVC {
            someMinutesLoadingVC.view.removeFromSuperview()
            someMinutesLoadingVC.removeFromParent()
            minutesLoadingVC = nil
            loadingContentView.isHidden = true
        }
    }

    private func hideMinutesAudioRecordVC() {
        if let vc = minutesAudioRecordVC {
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            minutesAudioRecordVC = nil
        }
    }

    private func hideMinutesAudioPreviewVC() {
        if let vc = minutesAudioPreviewVC {
            vc.view.removeFromSuperview()
            vc.removeFromParent()
            minutesAudioPreviewVC = nil
        }
    }

    func showMinutesErrorStatusVC(status: MinutesInfoStatus? = nil) {
        if Display.pad {
            navigationBar.hideTitle()
        }
        if minutesErrorStatusVC != nil {
            minutesErrorStatusVC?.updateResourceDeletedViewIfNeeded()
            minutesErrorStatusVC?.updateServerErrorViewIfNeeded()
            if let status = status {
                minutesErrorStatusVC?.show(with: status)
            }
            return
        }
        if minutesLoadingVC != nil { hideMinutesLoadingVC() }
        createErrorStatusVC()
        loadingContentView.isHidden = false
        if let status = status {
            minutesErrorStatusVC?.show(with: status)
        }
    }

    private func hideMinutesErrorStatusVC() {
        if let someMinutesErrorStatusVC = minutesErrorStatusVC {
            someMinutesErrorStatusVC.view.removeFromSuperview()
            someMinutesErrorStatusVC.removeFromParent()
            minutesErrorStatusVC = nil
            loadingContentView.isHidden = true
        }
    }
    
    private func showMinutesDetailVC() -> Bool {
        setNeedsStatusBarAppearanceUpdate()

        if minutesErrorStatusVC != nil {
            hideMinutesErrorStatusVC()
        }

        if leftMinutesDetail != nil {
            return true
        }

        createDetailVC()
        return true
    }
    
    private func showAudioPreviewVC() -> Bool {
        if minutesErrorStatusVC != nil {
            return false
        }
        if minutesAudioPreviewVC != nil {
            return false
        }

        if minutesAudioRecordVC != nil {
            hideMinutesAudioRecordVC()
        }

        hideMinutesAudioPreviewVC()
        createAudioPreviewVC()
        loadingContentView.isHidden = false
        return true
    }

    private func showMinutesClipVC() -> Bool {
        setNeedsStatusBarAppearanceUpdate()

        if minutesErrorStatusVC != nil {
            hideMinutesErrorStatusVC()
        }

        if minutesClipVC != nil {
            return true
        }

        createClipVC()
        loadingContentView.isHidden = false
        return true
    }
    
    private func showAudioRecordVC() -> Bool {
        if minutesErrorStatusVC != nil {
            return false
        }
        if minutesAudioRecordVC != nil {
            return false
        }

        if minutesAudioPreviewVC != nil {
            hideMinutesAudioPreviewVC()
        }

        hideMinutesAudioRecordVC()
        createAudioRecordVC()
        loadingContentView.isHidden = false
        return true
    }
    
    private func createLoadingVC() {
        let vc = MinutesLoadingViewController()
        addChild(vc)
        loadingContentView.addSubview(vc.view)
        loadingContentView.bringSubviewToFront(vc.view)
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        vc.view.layer.cornerRadius = Layout.cornerRadius
        vc.view.clipsToBounds = true

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }

            wSelf.navigationController?.popViewController(animated: true)
        }
        minutesLoadingVC = vc
    }
    
    private func createErrorStatusVC() {
        let vc = MinutesErrorStatusViewController(resolver: userResolver, minutes: viewModel.minutes)
        vc.source = source
        addChild(vc)
        loadingContentView.addSubview(vc.view)
        loadingContentView.bringSubviewToFront(vc.view)
        vc.view.layer.cornerRadius = Layout.cornerRadius
        vc.view.clipsToBounds = true
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }

            wSelf.navigationController?.popViewController(animated: true)
        }
        minutesErrorStatusVC = vc
    }

    // disable-lint: duplicated_code
    private func createDetailVC() {
        isCommonMinutes = true
        let vc = MinutesDetailViewController(resolver: userResolver, minutes: viewModel.minutes, player: videoPlayer, type: Display.pad ? .padLeft : .phone)
        vc.videoView = videoView
        vc.source = source
        vc.destination = destination
        vc.detailBottomInset = view.safeAreaInsets.bottom + Layout.margin
        if vc.isText {
            vc.transcriptProgressBar = transcriptProgressBar
        }
        addChild(vc)
        leftContentView.addSubview(vc.view)
        vc.view.layer.cornerRadius = Layout.cornerRadius
        vc.view.clipsToBounds = true
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.backAction()
        }
        vc.delegate = self
        leftMinutesDetail = vc
        createRightDetailIfNeeded()
        updatePages()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: DispatchWorkItem(block: {
            Self.isFirtLoad = false
        }))
    }

    private func createRightDetailIfNeeded() {
        guard isRegular && isCommonMinutes && rightMinutesDetail == nil  else { return }
        let vc = MinutesDetailViewController(resolver: userResolver, minutes: viewModel.minutes, player: videoPlayer, type: .padRight)
        vc.videoView = videoView
        vc.source = source
        vc.destination = destination
        vc.detailBottomInset = view.safeAreaInsets.bottom + Layout.margin
        vc.currentTranslationChosenLanguage = currentTranslationChosenLanguage
        if vc.isText {
            vc.transcriptProgressBar = transcriptProgressBar
        }
        addChild(vc)
        rightContentView.addSubview(vc.view)
        vc.view.layer.cornerRadius = Layout.cornerRadius
        vc.view.clipsToBounds = true
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.backAction()
        }
        vc.delegate = self
        rightMinutesDetail = vc
    }
    // enable-lint: duplicated_code

    
    private func createAudioPreviewVC() {
        let vc = MinutesAudioPreviewController(session: session)
        vc.isShowNavBar = false
        addChild(vc)
        loadingContentView.addSubview(vc.view)
        vc.view.layer.cornerRadius = Layout.cornerRadius
        vc.view.clipsToBounds = true
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }

            wSelf.backAction()
        }
        minutesAudioPreviewVC = vc
    }
    
    private func createClipVC() {
        let vc = MinutesClipViewController(resolver: userResolver, minutes: viewModel.minutes, player: videoPlayer)
        vc.source = source
        vc.destination = destination
        if Display.pad, viewModel.minutes.basicInfo?.mediaType != .audio { vc.moreSourceView = navigationBar.moreButton }
        addChild(vc)
        loadingContentView.addSubview(vc.view)
        vc.view.layer.cornerRadius = Layout.cornerRadius
        vc.view.clipsToBounds = true
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.backAction()
        }
        minutesClipVC = vc
    }

    private func createAudioRecordVC() {
        let vc = MinutesAudioRecordingController(session: session)
        vc.isShowNavBar = false
        addChild(vc)
        loadingContentView.addSubview(vc.view)
        vc.view.layer.cornerRadius = Layout.cornerRadius
        vc.view.clipsToBounds = true
        vc.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        vc.onClickBackButton = { [weak self] in
            guard let wSelf = self else { return }
            wSelf.backAction()
        }
        minutesAudioRecordVC = vc
    }
}

extension MinutesContainerViewController: MinutesDetailViewControllerDelegate {
    func didClickMore() {
        if let clip = minutesClipVC, viewModel.minutes.isClip {
            clip.presentMoreViewController()
        } else {
            presentMoreViewController()
        }
    }

    func didClickChooseLanguage() {
        presentChooseTranlationLanVC()
    }

    func translationDidExit() {
        currentTranslationChosenLanguage = .default
    }

    var containerView: UIView {
        self.view
    }
}

/// scene
extension MinutesContainerViewController: MinutesMultiSceneController {
    var sceneID: String {
        "minutes_detail"
    }
}
