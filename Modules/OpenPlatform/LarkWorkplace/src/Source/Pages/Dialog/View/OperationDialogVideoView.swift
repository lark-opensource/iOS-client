//
//  OperationDialogVideoView.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/24.
//

import UIKit
import TTVideoEngine
import UniverseDesignLoading
import UniverseDesignIcon
import ByteWebImage
import UniverseDesignEmpty
import LKCommonsLogging

private enum State {
    case initial
    case onReady
    case loading
    case playing
    case onPause
    case failure
}

final class OperationDialogVideoView: UIView {
    static let logger = Logger.log(OperationDialogVideoView.self)

    private enum Const {
        enum Style {
            static let cornerRadius: CGFloat = 12.0
            static let centerBtnRadius: CGFloat = 30
        }
    }

    private lazy var player: TTVideoEngine = {
        // swiftlint:disable empty_enum_arguments
        if !TTVideoEngine.ls_isStarted() {
            // swiftlint:enable empty_enum_arguments
            // 开启 Media Data Loader
            Self.logger.info("[dialog] player enable MDL start!")
            TTVideoEngine.ls_localServerConfigure().maxCacheSize = 300 * 1024 * 1024
            TTVideoEngine.ls_localServerConfigure().cachDirectory = WPCacheTool.videoCachePath
            TTVideoEngine.ls_start()
            Self.logger.info("[dialog] player enable MDL, cache path: \(WPCacheTool.videoCachePath)")
        }
        let ins = TTVideoEngine(ownPlayer: true)
        ins.delegate = self
        ins.addPeriodicTimeObserver(forInterval: 1.0 / 60, queue: DispatchQueue.main) { [weak self] in
            self?.updateVideoProgress()
        }
        ins.setOptions([
            // 解决 seek 问题，参考：https://bytedance.feishu.cn/wiki/wikcnh3rzpY5KOtuGs2ChGZjUOg
            VEKKey.VEKKEYPlayerKeepFormatAlive_BOOL.rawValue as VEKKeyType: true,
            VEKKey.VEKKeyPlayerSeekEndEnabled_BOOL.rawValue as VEKKeyType: true,

            // 开启本地视频缓存（MDL）
            VEKKey.VEKKeyMedialoaderEnable_BOOL.rawValue as VEKKeyType: true,

            // 播放器 Tag 设置
            VEKKey.VEKKeyLogTag_NSString.rawValue as VEKKeyType: "workplace",
            VEKKey.VEKKeyLogSubTag_NSString.rawValue as VEKKeyType: "dialog"
        ])
        return ins
    }()

    private var coverView: ByteImageView = {
        let vi = ByteImageView()
        vi.contentMode = .scaleAspectFit
        return vi
    }()

    private let imageFetcher: ImageManager
    private let session: String

    private var controlView: OperationDialogVideoControlView = {
        OperationDialogVideoControlView()
    }()

    private var playBtn: UIButton = {
        let vi = UIButton(type: .custom)
        vi.layer.masksToBounds = true
        vi.backgroundColor = UIColor.ud.bgMask
        vi.addTarget(self, action: #selector(onPlayBtnClick(_:)), for: .touchUpInside)
        var image = UDIcon.playFilled
        image = image.bd_imageByResize(to: CGSize(width: 30.0, height: 30.0)) ?? image
        vi.setImage(image.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill), for: .normal)
        return vi
    }()

    private let emptyView: UDEmpty = {
        let str = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_FailRefreshMsg
        let desc = UDEmptyConfig.Description(descriptionText: str)
        let config = UDEmptyConfig(description: desc, type: .loadingFailure)
        let vi = UDEmpty(config: config)
        vi.isUserInteractionEnabled = false
        return vi
    }()

    private var loadingView: UIView = {
        let vi = UIView()
        vi.backgroundColor = UIColor.ud.bgMask
        vi.layer.masksToBounds = true
        let spin = SpinLoadingView()
        vi.addSubview(spin)
        spin.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(36)
        }
        spin.stokeColor = UIColor.ud.primaryOnPrimaryFill
        spin.animating = true
        return vi
    }()

    private var state: State = .onReady {
        didSet {
            playBtn.alpha = (state == .onReady || state == .onPause ? 1.0 : 0.0)
            coverView.alpha = (state == .onReady ? 1.0 : 0.0)
            loadingView.alpha = ((state == .loading || state == .initial) ? 1.0 : 0.0)
            emptyView.alpha = (state == .failure ? 1.0 : 0.0)
            if state == .playing || state == .onPause {
                // 只有播放或暂停时允许 seek，否则播放器 seek 有 bug
                controlView.disableSeek(false)
            } else {
                controlView.disableSeek(true)
            }
        }
    }

    private var hover: Bool = false {
        didSet {
            controlView.alpha = hover ? 1.0 : 0.0

            hoverTimer?.invalidate()
            hoverTimer = nil

            if hover {
                let timer = Timer(timeInterval: 5.0, repeats: false, block: { [weak self] _ in
                    self?.hover = false
                })
                RunLoop.main.add(timer, forMode: .common)
                hoverTimer = timer
            }
        }
    }

    private var hoverTimer: Timer?

    private var seeking = false {
        didSet {
            controlView.disableSeek(seeking)
        }
    }

    private var loadingInfo: (vURL: URL?, cURL: URL?)?

    // MARK: - life cycle

    init(imageFetcher: ImageManager, session: String) {
        self.imageFetcher = imageFetcher
        self.session = session
        super.init(frame: .zero)

        setupSubviews()
        setupPlayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        hoverTimer?.invalidate()

        player.removeTimeObserver()
        player.stop()
        player.closeAysnc()
        player.playerView.removeFromSuperview()
    }

    // MARK: - public

    func loadVideo(_ videoUrl: URL?, coverURL: URL? = nil) {
        loadingInfo = (videoUrl, coverURL)
        guard let vURL = videoUrl else {
            Self.logger.error("[dialog] nil video url: \(String(describing: videoUrl))")
            self.state = .failure
            return
        }
        if let cURL = coverURL {
            imageFetcher.requestImage(cURL, completion: { [weak self] result in
                guard let `self` = self else {
                    return
                }
                switch result {
                case .success(let ret):
                    self.coverView.image = ret.image
                case .failure(let err):
                    Self.logger.error("[dialog] cover image load err: \(err)")
                }
            })
        }

        player.ls_setDirectURL(vURL.absoluteString, key: vURL.absoluteString.md5())
        player.prepareToPlay()
    }

    // MARK: - private

    private func play() {
        guard state == .onPause || state == .onReady else {
            return
        }
        state = .playing
        controlView.updatePlayingStatus(true)
        player.play()
    }

    private func pause() {
        guard state == .playing else {
            return
        }
        state = .onPause
        self.controlView.updatePlayingStatus(false)
        player.pause(true)
    }

    private func seekTo(_ progress: Float) {
        if seeking {
            return
        }
        Self.logger.info("[dialog] player seek start!")
        seeking = true
        let time = self.player.duration * TimeInterval(progress)
        self.player.setCurrentPlaybackTime(time) { [weak self] _ in
            Self.logger.info("[dialog] player seek finish!")
            self?.seeking = false
        }
    }

    @objc
    private func onPlayBtnClick(_ sender: UIButton?) {
        play()
    }

    private func updateVideoProgress() {
        if state != .onReady && state != .playing {
            return
        }
        if seeking {
            return
        }
        let current = player.currentPlaybackTime
        let buffer = player.playableDuration
        let total = player.duration
        controlView.updateProgress(current: current, buffer: buffer, total: total)
    }

    private func setupSubviews() {
        layer.cornerRadius = Const.Style.cornerRadius
        layer.masksToBounds = true
        backgroundColor = UIColor.ud.staticBlack

        addSubview(player.playerView)
        player.playerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(coverView)
        coverView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(controlView)
        controlView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        addSubview(playBtn)
        playBtn.layer.cornerRadius = Const.Style.centerBtnRadius
        playBtn.snp.makeConstraints { make in
            make.width.height.equalTo(Const.Style.centerBtnRadius * 2)
            make.center.equalToSuperview()
        }

        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        addSubview(loadingView)
        loadingView.layer.cornerRadius = Const.Style.centerBtnRadius
        loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(Const.Style.centerBtnRadius * 2)
            make.center.equalToSuperview()
        }

        controlView.actionHandler = { [weak self] (_, action) in
            guard let self = self else {
                return
            }
            switch action {
            case .play(let value):
                if value {
                    self.play()
                } else {
                    self.pause()
                }
            case .mute(let value):
                self.player.muted = value
                self.controlView.updateMuteStatus(value)
            case .seek(let progress):
                self.hover = true
                self.seekTo(progress)
            }
        }

        let tap1 = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        addGestureRecognizer(tap1)

        let tap2 = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
        controlView.addGestureRecognizer(tap2)

        state = .initial
        hover = false
    }

    private func setupPlayer() {
        // zhysan todo: 是否需要 header 鉴权需要配置
        setupWorkplaceHeader()
    }

    func setupWorkplaceHeader() {
        player.setCustomHeaderValue("session=\(session)", forKey: "Cookie")
    }

    @objc
    private func onTap(_ sender: UITapGestureRecognizer) {
        if sender.view == self {
            if state == .failure {
                state = .loading
                loadVideo(loadingInfo?.vURL, coverURL: loadingInfo?.cURL)
                return
            }
            hover = true
        } else if sender.view == controlView {
            hover = false
        }
    }
}

extension OperationDialogVideoView: TTVideoEngineDelegate {
    func videoEngineUserStopped(_ videoEngine: TTVideoEngine) {}
    func videoEngineCloseAysncFinish(_ videoEngine: TTVideoEngine) {}

    func videoEngineDidFinish(_ videoEngine: TTVideoEngine, error: Error?) {
        Self.logger.info("[dialog] finish play, \(String(describing: error))")
        if state == .playing {
            state = .onReady
        } else if state == .loading || state == .initial {
            // swiftlint:disable unused_optional_binding
            if let _ = error {
                state = .failure
            }
            // swiftlint:enable unused_optional_binding
        }
    }

    func videoEngine(_ videoEngine: TTVideoEngine, loadStateDidChanged loadState: TTVideoEngineLoadState) {
        Self.logger.info("[dialog] loadState change: \(loadState)")
        switch loadState {
        case .playable:
            if state == .loading {
                state = .playing
            }
        case .stalled:
            if state == .playing {
                state = .loading
            }
        default:
            break
        }
    }

    func videoEngineReady(toDisPlay videoEngine: TTVideoEngine) {
        Self.logger.info("[dialog] ready to display")
        if state == .initial {
            state = .onReady
            updateVideoProgress()
        }
    }

    func videoEnginePrepared(_ videoEngine: TTVideoEngine) {
        Self.logger.info("[dialog] prepare finish")
    }

    func videoEngineReady(toPlay videoEngine: TTVideoEngine) {
        Self.logger.info("[dialog] ready to play")
    }

    func videoEngineDidFinish(_ videoEngine: TTVideoEngine, videoStatusException status: Int) {
        Self.logger.warn("[dialog] status exception: \(status)")
    }

    func videoEngine(_ videoEngine: TTVideoEngine, retryForError error: Error) {
        Self.logger.warn("[dialog] retry for error: \(error)")
    }
}
