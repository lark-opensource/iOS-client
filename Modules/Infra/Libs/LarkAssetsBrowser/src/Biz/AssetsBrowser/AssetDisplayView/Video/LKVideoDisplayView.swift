//
//  LKVideoDisplayView.swift
//  LarkAssetsBrowser
//
//  Created by kangsiwan on 2021/9/16.
//

import LarkUIKit
import LKCommonsLogging
import RxSwift
import LarkKAFeatureSwitch
import RustPB
import EENavigator
import Foundation
import UIKit
import ByteWebImage
import UniverseDesignToast
import UniverseDesignDialog

protocol LKVideoDisplayViewDelegate: AnyObject {
    var targetVC: UIViewController? { get }
    func assetButtonDidClicked()
}

// 使用状态机控制视频的各个状态 https://bytedance.feishu.cn/docs/doccnOflw6r5cIHS0r2y4WXevJf#7y5281
enum VideoState: String, CustomStringConvertible {
    // 结束状态，finish和stop都会到此
    case idle
    // 等待状态，0.5s内判断各个值的变化，符合条件流转到playing，不符合条件流转到loading
    case waiting
    // 正在播放状态
    case playing
    // loading状态
    case loading
    // 暂停状态，点击屏幕后会到此
    case pause

    var description: String {
        return self.rawValue
    }
}

// 结束视频报错的错误类型
enum ErrorState {
    case inValid
    case fetchFail
}

final class LKVideoDisplayView: UIView {
    private static let logger = Logger.log(LKVideoDisplayView.self, category: "LarkAssetsBrowser.LKVideoDisplayView")
    private weak var delegete: LKVideoDisplayViewDelegate?
    private var videoState: VideoState = .idle
    // 当前视频暂停是否是由于程序挂起引起的
    private var isPauseByApplicationWillResign: Bool = false
    // 当前视频暂停是否是由于进入图库引起的
    private var isPauseByClickLookupButton: Bool = false

    private let beginPlayBtn = UIButton(type: .custom)
    private let headView = LKVideoDisplayHeaderView()
    private let footerView: LKVideoDisplayFooterView
    private let videoCoverView = LKVideoCoverView()
    private let loadingView = UIImageView(image: Resources.asset_video_loading)
    // 是否正在展示下载中的HUD
    private var isShowProgressView: Bool = false
    // 视频长度
    private var videoDurationByEngine: TimeInterval?

    private lazy var progressView: LarkProgressHUD = {
        let view = LarkProgressHUD(view: self)
        view.isUserInteractionEnabled = false
        return view
    }()
    private var playbackState: LKVideoPlaybackState = .stopped {
        didSet {
            guard oldValue != playbackState else { return }
            LKVideoDisplayView.logger.info("\(currentAssetKey) playbackState \(playbackState)")
            // 参数改变，让需要关心的状态，主动检查
            checkGoLoading()
        }
    }
    private var loadState: LKVideoLoadState = .stalled {
        didSet {
            guard oldValue != loadState else { return }
            LKVideoDisplayView.logger.info("\(currentAssetKey) loadState \(loadState)")
            // 参数改变，让需要关心的状态，主动检查
            checkGoLoading()
        }
    }

    let proxy: LKVideoDisplayViewProxy
    var connection: LKVideoConnection = .none
    var displayIndex: Int = Int.max
    var getExistedImageBlock: GetExistedImageBlock?
    var setImageBlock: SetImageBlock?
    var handleLoadCompletion: ((AssetLoadCompletionInfo) -> Void)?
    var prepareAssetInfo: PrepareAssetInfo?
    var setSVGBlock: SetSVGBlock?
    var dismissCallback: (() -> Void)?
    var longPressCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)?
    var moreButtonClickedCallback: ((UIImage?, LKDisplayAsset, UIView?) -> Void)?
    // 配置图片加载额外的ImageRequestOptions，与内部策略归并
    public var additonImageRequestOptions: ImageRequestOptions?

    var displayAsset: LKDisplayAsset? {
        didSet {
            if let displayAsset = self.displayAsset {
                if displayAsset.isLocalVideoUrl {
                    self.proxy.setLocalURL(displayAsset.videoUrl)
                } else {
                    self.proxy.setDirectPlayURL(displayAsset.videoUrl)
                }
                if videoDurationByEngine == nil {
                    LKVideoDisplayView.logger.info("\(currentAssetKey)  didSet displayAsset, set endTime ")
                    let time: TimeInterval = TimeInterval(displayAsset.duration) / 1_000
                    self.footerView.setEndTimeLabel(time: stringFromTimeInterval(time))
                    videoDurationByEngine = time
                }
            }
        }
    }

    // 单击（暂停）
    public fileprivate(set) var singleTap = UITapGestureRecognizer()
    // 长按（展示菜单）
    public fileprivate(set) var longGesture = UILongPressGestureRecognizer()

    init(proxy: LKVideoDisplayViewProxy, showMoreButton: Bool, showAssetButton: Bool = false, delegate: LKVideoDisplayViewDelegate) {
        self.proxy = proxy
        self.delegete = delegate
        self.footerView = LKVideoDisplayFooterView(showMoreButton: showMoreButton, showAssetButton: showAssetButton)
        super.init(frame: CGRect.zero)

        self.footerView.delegate = self
        self.proxy.delegate = self
        videoCoverView.delegate = self
        setupView()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupView() {
        self.addSubview(proxy.playerView)
        proxy.playerView.isHidden = true
        self.addSubview(videoCoverView)
        self.videoCoverView.contentMode = .scaleAspectFit
        self.addSubview(beginPlayBtn)
        beginPlayBtn.setImage(Resources.asset_video_begin_play, for: .normal)
        beginPlayBtn.addTarget(self, action: #selector(beginPlayButtonClicked), for: .touchUpInside)
        self.addSubview(self.headView)
        self.headView.closeButton.addTarget(self, action: #selector(closeButtonClicked), for: .touchUpInside)
        self.addSubview(self.footerView)
        self.addSubview(loadingView)
        // 先隐藏loading
        loadingView.isHidden = true
        remakeConstraints(isFirstLayout: true)
        singleTap.addTarget(self, action: #selector(handleSingleTap))
        self.addGestureRecognizer(singleTap)
        longGesture.addTarget(self, action: #selector(handleLongPress(ges:)))
        self.addGestureRecognizer(longGesture)

        goIdle()

        self.footerView.slider.seekingToProgress = { [unowned self] progress, finish in
            if finish {
                LKVideoDisplayView.logger.info("\(currentAssetKey)  seekFinish progress \(progress)")
                goWaitingWithoutPlay()
                self.proxy.seekVideoProcess(progress) { _ in
                    if abs(progress - 1) > Float.leastNormalMagnitude {
                        LKVideoDisplayView.logger.info("\(currentAssetKey)  seekVideoProcess Completion")
                        // 能调用到这里说明已经变更到.playable
                        proxyPlay()
                    }
                }
            } else {
                if videoState == .idle {
                    goWaitingWithoutPlay()
                }
                goPause()
                if let videoDurationByEngine = videoDurationByEngine {
                    footerView.setStartTimeLabel(time: stringFromTimeInterval(Double(progress) * videoDurationByEngine))
                }
            }
        }
    }

    func layoutCoverView() {
        guard let size = self.videoCoverView.image?.size else {
            return
        }
        if (size.width / size.height) < (self.frame.width / self.frame.height) { // 竖直长图
            self.videoCoverView.snp.remakeConstraints { (make) in
                make.center.height.equalToSuperview()
                let width = self.frame.height * size.width / size.height
                make.width.equalTo(width)
            }
        } else {
            self.videoCoverView.snp.remakeConstraints { (make) in
                make.center.width.equalToSuperview()
                let height = self.frame.width * size.height / size.width
                make.height.equalTo(height)
            }
        }
    }

    func remakeConstraints(isFirstLayout: Bool) {
        self.headView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(safeAreaInsets.left)
            make.right.equalToSuperview().offset(-safeAreaInsets.right)
            make.height.equalTo(60 + safeAreaInsets.top)
        }
        self.footerView.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(safeAreaInsets.left)
            make.right.equalToSuperview().offset(-safeAreaInsets.right)
            make.height.equalTo(44 + safeAreaInsets.bottom)
        }
        self.proxy.playerView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(safeAreaInsets.left)
            make.right.equalToSuperview().offset(-safeAreaInsets.right)
        }
        self.headView.remakeConstraintsBy(safeAreaInsets: safeAreaInsets)
        self.footerView.remakeConstraintsBy(safeAreaInsets: safeAreaInsets)
        guard isFirstLayout else {
            return
        }
        layoutCoverView()
        beginPlayBtn.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        self.loadingView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    @objc
    func applicationWillResignActive() {
        // 挂起app
        LKVideoDisplayView.logger.info("\(currentAssetKey)  applicationWillResignActive")
        guard videoState == .playing || videoState == .loading || videoState == .waiting else {
            return
        }
        // 当前视频暂停是由于程序挂起
        isPauseByApplicationWillResign = true
        goPause()
    }

    @objc
    func applicationDidBecomeActive() {
        // 重新进入程序
        LKVideoDisplayView.logger.info("\(currentAssetKey)  applicationDidBecomeActive")
        // 当前视频暂停，并且暂停的原因是由于之前程序挂起。那么尝试播放
        if videoState == .pause, isPauseByApplicationWillResign {
            goWaitingWithPlay()
        }
        isPauseByApplicationWillResign = false
    }

    @objc
    func beginPlayButtonClicked() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) beginPlayButtonClicked")
        // 点击开始按钮
        if videoState != .idle || (videoState == .idle && judgeSuiteVideoDownloadFG()) {
            goWaitingWithPlay()
        }
    }

    @objc
    func closeButtonClicked() {
        if dismissCallback == nil {
            Self.logger.info("handleSingleTap, dismissCallback is nil")
        } else {
            Self.logger.info("handleSingleTap, dismissCallback")
        }
        // 关闭按钮
        self.proxy.stop()
        self.dismissCallback?()
    }

    @objc
    func handleSingleTap() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) handleSingleTap")
        // 点击屏幕
        // 主要用来接受外部的信息传递

        switch videoState {
        case .idle:
            // 应PM需要，在idle状态下，点击屏幕，视频可以开始播放
            if judgeSuiteVideoDownloadFG() {
                goWaitingWithPlay()
            }
        case .waiting, .playing, .loading:
            goPause()
        case .pause:
            goWaitingWithPlay()
        }
    }

    @objc
    private func handleLongPress(ges: UITapGestureRecognizer) {
        LKVideoDisplayView.logger.info("\(currentAssetKey) handleLongPress")
        // 长按响应事件
        if ges.state == .began {
            self.showMoreAction(nil)
        }
    }

    @objc
    func showMoreAction(_ sourceView: UIView?) {
        if let asset = self.displayAsset {
            self.moreButtonClickedCallback?(nil, asset, sourceView)
        }
    }

    @objc
    func timerHandler() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) timerHandler")
        // 定时任务后执行的任务
        headView.isHidden = true
        footerView.isHidden = true
    }

    @objc
    func checkGoLoading() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) checkGoLoading videoState: \(videoState)")
        // 只有在waiting，playing，loading情况下才会监控loadState和playback的值的变化
        guard videoState == .waiting || videoState == .playing || videoState == .loading else {
            return
        }
        LKVideoDisplayView.logger.info("\(currentAssetKey) checkGoLoading loadState \(loadState) playback \(playbackState)")
        inMainQueue(complete: { [weak self] in
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self?.checkGoLoading), object: nil)
        })
        // 只有在loadState是playable，playback是playing才不显示loading
        if loadState == .playable, playbackState == .playing {
            goPlaying()
        } else {
            goLoading()
        }
    }

    fileprivate func proxyPlay() {
        // 统一播放接口
        LKVideoDisplayView.logger.info("\(currentAssetKey) proxyPlay() ")
        self.proxy.play(self.displayAsset?.isVideoMuted ?? false)
    }

    fileprivate func proxyPause() {
        // 统一暂停接口
        LKVideoDisplayView.logger.info("\(currentAssetKey) proxyPause()")
        self.proxy.pause()
    }

    func scheduledTimer() {
        // 开启计时
        inMainQueue(complete: { [weak self] in
            self?.perform(#selector(self?.timerHandler), with: nil, afterDelay: 5)
        })
    }

    func invalidateTimer() {
        // 结束计时
        inMainQueue(complete: { [weak self] in
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self?.timerHandler), object: nil)
        })
    }

    // firstToPlay 首播
    // 在点击视频后，初始化当前scroll页面的时候调用
    func initialPlay() {
        LKVideoDisplayView.logger.info("\(self.displayAsset?.key) initialPlay()")

        // 新版本播放器对齐安卓和微信的策略，不再判断当前网络

        // FG判断
        if judgeSuiteVideoDownloadFG() {
            goWaitingWithPlay()
        }
    }

    // 因为点击lookup按钮进入下一个页面，返回后需要再自动播放
    func continueToPlayIfNeeded() {
        if isPauseByClickLookupButton {
            goWaitingWithPlay()
        }
        isPauseByClickLookupButton = false
    }

    func showLoadingView() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) showLoadingView")
        guard self.loadingView.isHidden == true else { return }
        self.loadingView.isHidden = false
        self.loadingView.lu.addRotateAnimation()
    }

    func dismissLoadingView() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) dismissLoadingView")
        guard self.loadingView.isHidden == false else { return }
        self.loadingView.isHidden = true
        self.loadingView.lu.removeRotateAnimation()
    }

    func showHeadAndFooterView() {
        headView.isHidden = false
        footerView.isHidden = false
    }

    func dismissHeadAndFooterView() {
        headView.isHidden = true
        footerView.isHidden = true
    }

    func setupFooterViewSlider() {
        footerView.slider.setProgress(0, animated: false)
        footerView.slider.setCacheProgress(0, animated: false)
        footerView.setStartTimeLabel(time: stringFromTimeInterval(0))
    }

    // 转换时间
    private func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let interval = Int(round(interval))
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let hours = (interval / 60 / 60)
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func inMainQueue(complete: @escaping () -> Void) {
        if Thread.isMainThread {
            complete()
        } else {
            DispatchQueue.main.async {
                complete()
            }
        }
    }

    static func getViewController(view: UIView) -> UIViewController? {
        if let next = view.next as? UIViewController {
            return next
        } else if let next = view.next as? UIView {
            return getViewController(view: next)
        }
        return nil
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        remakeConstraints(isFirstLayout: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutCoverView()
    }

    // 判断是否能下载视频
    func judgeSuiteVideoDownloadFG() -> Bool {
        if !FeatureSwitch.share.bool(for: .suiteVideoDownload) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let window = self.window else { return }
                if let vc = LKVideoDisplayView.getViewController(view: self), let transitionCoordinator = vc.transitionCoordinator {
                    transitionCoordinator.animate(alongsideTransition: nil) { [weak window] (_) in
                        guard let window = window else { return }
                        // 因安全策略限制无法播放，请切换到桌面云环境后重试
                        UDToast.showTips(
                            with: BundleI18n.LarkAssetsBrowser.Lark_Chat_CantPlayVideosDueToAdminSecuritySettings,
                            on: window
                        )
                    }
                } else {
                    UDToast.showTips(
                        with: BundleI18n.LarkAssetsBrowser.Lark_Chat_CantPlayVideosDueToAdminSecuritySettings,
                        on: window
                    )
                }
            }
            return false
        }
        return true
    }

    func goLoadingIfNeeded() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) goLoadingIfNeeded")
        // 0.5s后主动check
        inMainQueue(complete: { [weak self] in
            self?.perform(#selector(self?.checkGoLoading), with: nil, afterDelay: 0.5)
        })
    }

    func goIdle(errorState: ErrorState? = nil) {
        guard videoState != .idle else { return }
        LKVideoDisplayView.logger.info("\(currentAssetKey) goIdle \(errorState)")
        // 到达idle的状态
        videoState = .idle

        // UI
        dismissLoadingView()
        // 如果有错误需要显示，就不能显示beginBtn
        beginPlayBtn.isHidden = (errorState != nil) ? true : false
        showHeadAndFooterView()
        self.invalidateTimer()
        videoCoverView.isHidden = false
        proxy.playerView.isHidden = true
        setupFooterViewSlider()

        // 是否是正常结束
        if let errorState = errorState {
            switch errorState {
            case .fetchFail:
                videoCoverView.setVideoFetchFail()
            case .inValid:
                videoCoverView.setVideo(isValid: false)
            }
        } else {
            videoCoverView.setVideo(isValid: true)
        }

        // 状态设置
        // https://bytedance.feishu.cn/docs/doccnOflw6r5cIHS0r2y4WXevJf#gvd9ex
        proxy.stop()
    }

    func goWaitingWithPlay() {
        guard videoState != .waiting else { return }
        LKVideoDisplayView.logger.info("\(currentAssetKey) goWaitingWithPlay")
        self.proxyPlay()
        goWaitingWithoutPlay()
    }

    func goWaitingWithoutPlay() {
        guard videoState != .waiting else { return }
        LKVideoDisplayView.logger.info("\(currentAssetKey) goWaitingWithoutPlay")
        if videoState == .idle || videoState == .pause {
            videoState = .waiting
            goLoadingIfNeeded()
            // UI
            dismissLoadingView()
            beginPlayBtn.isHidden = true
            showHeadAndFooterView()
            videoCoverView.setVideo(isValid: true)
            self.scheduledTimer()
        } else {
            assertionFailure("状态错误")
        }
    }

    func goPlaying() {
        guard videoState != .playing else { return }
        LKVideoDisplayView.logger.info("\(currentAssetKey) goPlaying")
        // 到达playing的状态，调用的方法
        if videoState == .waiting || videoState == .loading {
            videoState = .playing

            // UI
            dismissLoadingView()
            beginPlayBtn.isHidden = true
            showHeadAndFooterView()
            videoCoverView.setVideo(isValid: true)
            self.scheduledTimer()
        } else {
            assertionFailure("状态错误")
        }
    }

    func goLoading() {
        guard videoState != .loading else { return }
        LKVideoDisplayView.logger.info("\(currentAssetKey) goLoading")
        // 到达loading的状态，调用的方法
        if videoState == .playing || videoState == .waiting {
            videoState = .loading

            // UI
            showLoadingView()
            beginPlayBtn.isHidden = true
            dismissHeadAndFooterView()
            videoCoverView.setVideo(isValid: true)
            self.invalidateTimer()
        } else {
            assertionFailure("状态错误")
        }
    }

    func goPause() {
        guard videoState != .pause else { return }
        LKVideoDisplayView.logger.info("\(currentAssetKey) goPause")
        // 到达pause的状态，调用的方法
        if videoState == .playing || videoState == .loading || videoState == .waiting {
            videoState = .pause
            proxyPause()

            // UI
            dismissLoadingView()
            self.invalidateTimer()
            beginPlayBtn.isHidden = false
            showHeadAndFooterView()
            videoCoverView.setVideo(isValid: true)
        } else {
            assertionFailure("状态错误")
        }
    }
}

// MARK: LKAssetPageView
extension LKVideoDisplayView: LKAssetPageView {
    var dismissFrame: CGRect {
        return self.convert(self.videoCoverView.frame, to: self.window)
    }

    var dismissImage: UIImage? {
        return self.videoCoverView.image
    }

    func handleSwipeDown() {
        self.headView.isHidden = true
        self.footerView.isHidden = true
    }

    func prepareDisplayAsset(completion: @escaping () -> Void) {
        guard let displayAsset = self.displayAsset else { return }
        let completionHandler: CompletionHandler = { [weak self] (image, _, _) in
            guard let `self` = self, let image = image else { return }
            self.videoCoverView.image = image
            self.layoutCoverView()
            completion()
        }
        if let oldSet = self.setImageBlock {
            oldSet(displayAsset, self.videoCoverView, nil, completionHandler)
        } else if let prepareAssetInfo = self.prepareAssetInfo {
            let (dataProvider, passThrough, trackInfo) = prepareAssetInfo(displayAsset)
            self.videoCoverView.bt.setLarkImage(
                with: dataProvider.getImageKeyResource(),
                placeholder: displayAsset.placeHolder,
                passThrough: passThrough,
                options: self.additonImageRequestOptions ?? [],
                trackStart: { return trackInfo },
                completion: { result in
                    switch result {
                    case .success(let imageResult):
                        completionHandler(imageResult.image, nil, nil)
                    case .failure(let error):
                        completionHandler(nil, nil, error)
                    }
                }
            )
        }
    }

    func prepareForReuse() {
        displayAsset = nil
        displayIndex = Int.max
        proxy.stop()
    }

    func recoverToInitialState() {
        proxy.stop()
        goIdle()
    }

    func resetInitStatus() {
        goIdle()
    }

    func handleCurrentDisplayAsset() {}

    func handleTranslateProcess(baseView: UIView,
                                cancelHandler: @escaping () -> Void,
                                processHandler: @escaping (@escaping () -> Void, @escaping (Bool, LKDisplayAsset?) -> Void) -> Void,
                                dataSourceUpdater: @escaping (LKDisplayAsset) -> Void) {}
}

extension LKVideoDisplayView: LKVideoDisplayFooterViewDelegate {
    func menuButtonDidClicked(_ sender: UIView) {
        self.showMoreAction(sender)
    }

    // lookup按钮的响应事件
    func assetsButtonDidClicked() {
        // 会push出图库，如果视频不是在停止或暂停，那么就暂停
        if videoState == .loading || videoState == .playing || videoState == .waiting {
            isPauseByClickLookupButton = true
            goPause()
        }
        delegete?.assetButtonDidClicked()
    }
}

extension LKVideoDisplayView: LKVideoDisplayViewProxyDelegate {
    var currentAsset: LKDisplayAsset? {
        return self.displayAsset
    }

    func set(currentPlaybackTime: TimeInterval, duration: TimeInterval, playableDuration: TimeInterval) {
        // 设置进度
        // 如果状态是playing，才能设置
        guard videoState == .playing else { return }
        if currentPlaybackTime > 0 {
            footerView.setStartTimeLabel(time: stringFromTimeInterval(currentPlaybackTime))
        }

        if duration > 0 {
            footerView.setEndTimeLabel(time: stringFromTimeInterval(duration))
            videoDurationByEngine = duration
        }

        var playPercent = Float(currentPlaybackTime / duration)
        playPercent = min(max(0, playPercent), 1)
        footerView.slider.setProgress(playPercent, animated: false)

        var cachePercent = Float(playableDuration / duration)
        cachePercent = min(max(0, cachePercent), 1)
        footerView.slider.setCacheProgress(cachePercent, animated: false)
    }

    // 视频开始连续渲染的时候回调，必须调用play才会触发该回调
    func videoReadyToPlay() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) videoReadyToPlay")
        // 如果视频在idle状态，则进入waiting状态
        if videoState == .idle {
            goWaitingWithPlay()
        } else if videoState == .loading {
            // 如果在loading状态，再尝试判断一下，可以播放了吗
            checkGoLoading()
        }
        // 如果在playing，则不需要再做什么
        // 如果在pause，是外界触发进入的状态，也不需要做什么

        // 在playback变为.playing和loadState变为.playable后，会调用readyToPlay
        // 如果在.playing状态隐藏coverView，时机会偏早，可能会出现后面的playerView，导致闪一下的效果
        // 在readyToPlay隐藏coverView，时机会更好一些，不会出现闪一下的场景
        videoCoverView.isHidden = true
        proxy.playerView.isHidden = false
    }

    func videoPlaybackStateDidChanged(_ playbackState: LKVideoPlaybackState) {
        self.playbackState = playbackState
    }

    func videoLoadStateDidChanged(_ loadState: LKVideoLoadState) {
        self.loadState = loadState
    }

    func videoDidStop() {
        LKVideoDisplayView.logger.info("\(currentAssetKey)  videoDidStop")
        goIdle()
    }

    func videoPlayDidFinish(state: LKVideoState) {
        LKVideoDisplayView.logger.info("\(currentAssetKey)  videoPlayDidFinish state \(state)")
        // 进入idle状态 看是进入正常结束还是异常结束
        switch state {
        case .invalid:
            goIdle(errorState: .inValid)
        case .fetchFail(let error):
            handleLoadCompletion?(AssetLoadCompletionInfo(index: displayIndex,
                                                          data: .video,
                                                          error: error))
            goIdle(errorState: .fetchFail)
        case .error(let error):
            handleLoadCompletion?(AssetLoadCompletionInfo(index: displayIndex,
                                                          data: .video,
                                                          error: error))
            LKVideoDisplayView.logger.info("\(currentAssetKey)  videoPlayDidFinish error:\(error)")
            goIdle(errorState: .fetchFail)
        case .valid:
            goIdle()
        }
    }

    func retryPlay() {
        LKVideoDisplayView.logger.info("\(currentAssetKey) retryPlay")
        // 进入waiting状态，执行goWaiting()
        // FG判断
        if judgeSuiteVideoDownloadFG() {
            goWaitingWithPlay()
        }
    }

    func showAlert(with state: Media_V1_GetFileStateResponse.State) {
        guard state != .normal, let targetVC = delegete?.targetVC else { return }
        let alert = UDDialog()
        alert.setTitle(text: BundleI18n.LarkAssetsBrowser.Lark_ChatFileStorage_ChatFileNotFoundDialogTitle)
        switch state {
        case .freedUp:
            alert.setContent(text: BundleI18n.LarkAssetsBrowser.Lark_IM_ViewOrDownloadFile_FileDeleted_Text)
        case .deleted:
            alert.setContent(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_FileWithdrawTip)
        case .unrecoverable:
            alert.setContent(text: BundleI18n.LarkAssetsBrowser.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days)
        case .recoverable:
            alert.setContent(text: BundleI18n.LarkAssetsBrowser.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days)
        case .normal:
            assertionFailure()
        @unknown default:
            assertionFailure()
        }
        if state == .deleted {
            alert.setContent(text: BundleI18n.LarkAssetsBrowser.Lark_ChatFileStorage_ChatFileNotFoundDialogOver90Days)
        } else {
            alert.setContent(text: BundleI18n.LarkAssetsBrowser.Lark_ChatFileStorage_ChatFileNotFoundDialogWithin90Days)
        }
        alert.addPrimaryButton(text: BundleI18n.LarkAssetsBrowser.Lark_Legacy_IKnow)
        Navigator.shared.present(alert, from: targetVC)
    }
}

extension LKVideoDisplayView: LKVideoCoverViewDelegate {
    func retryFetchVideo() {
        goWaitingWithPlay()
    }
}

extension LKVideoDisplayView: LKVideoDisplayViewProtocol {
    func showProgressView() {
        self.isShowProgressView = true
        self.addSubview(self.progressView)
        self.progressView.show(animated: true)
    }

    func configProgressView(_ progress: Float) {}

    func hideProgressView() {
        self.progressView.hide(animated: true)
        self.progressView.removeFromSuperview()
        self.isShowProgressView = false
    }

    func play() {
        proxyPlay()
        goWaitingWithPlay()
    }

    func pause() {
        // 在idle状态下，不能pause
        guard videoState != .idle else { return }
        proxyPause()
        goPause()
    }
}

extension LKVideoDisplayView {

    private var currentAssetKey: String {
        displayAsset?.key ?? "[invalid key]"
    }
}
