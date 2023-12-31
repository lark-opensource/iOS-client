//
//  MinutesAudioRecordingController.swift
//  Minutes
//
//  Created by lvdaqian on 2021/3/11.
//

import MinutesFoundation
import UniverseDesignColor
import EENavigator
import LarkAlertController
import YYText
import UniverseDesignToast
import MinutesNavigator
import LarkUIKit
import CoreTelephony
import LarkContainer
import LarkFeatureGating
import UniverseDesignIcon
import LarkMedia
import LarkContainer
import MinutesNetwork

public extension Notification {
    static let minutesAudioRecordingVCDismiss = Notification.Name("minutes.audio.recording.vc.dismiss")

    struct Key {
        public static let minutesAudioRecordIsStop = "minutes.audio.record.is.stop"
    }
}

public enum MinutesAudioRecordingSource: String {
    case createIcon = "create_icon"
    case listPage = "list_page"
    case floatingWindow = "floating_window"
    case others = "others"
}

class MinutesAudioRecordingController: UIViewController {
    var userResolver: UserResolver { session.userResolver }

    let limitLength = 80 //重命名最大字数
    
    var onClickBackButton: (() -> Void)?

    public var fromSource: MinutesAudioRecordingSource? { session.recordingSource }

    private var minutes: Minutes { session.minutes }
    private var viewModel: MinutesAudioContentViewModel

    weak var originalTextView: MinutesOriginalTextView?
    
    var dependency: MinutesDependency? {
        return try? userResolver.resolve(assert: MinutesDependency.self)
    }
    
    var currentTranslationChosenLanguage: Language = .default {
        didSet {
            InnoPerfMonitor.shared.update(extra: ["isInTranslationMode": isInTranslationMode])
        }
    }

    var weakNetworkHUDDate: Date?

    var isInTranslationMode: Bool {
        return minutes.translateData != nil
    }

    lazy var tracker: MinutesTracker = {
        return MinutesTracker(minutes: viewModel.minutes)
    }()

    var huds: [MinutesRecordHUD] = []
    var recordTimer: Timer?
    var stoped: Bool = false

    lazy var recordPanel: MinutesAudioRecordingControlPanel = {
        let panel = MinutesAudioRecordingControlPanel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 0))
        panel.isPausing = MinutesAudioRecorder.shared.status == .paused
        panel.selectLanguageBlock = { [weak self] point in
            guard let self = self else { return }

            self.tracker.tracker(name: .recordingPage, params: ["action_name": "recording_language_change"])
            self.tracker.tracker(name: .recordingClick, params: ["click": "recording_language_change", "target": "none"])
            self.presentChooseLanVC(point)
        }
        panel.pausingContinueRecordBlock = { [weak self, weak panel] in
            guard let self = self, let weakPanel = panel else { return }
            if !weakPanel.isPausing {
                MinutesLogger.recordBasic.info("pause record")
                MinutesAudioRecorder.shared.pause()

                self.tracker.tracker(name: .recordingPage, params: ["action_name": "pause_recording"])
                self.tracker.tracker(name: .recordingClick, params: ["click": "pause_recording", "target": "none"])
            } else {
                MinutesLogger.recordBasic.info("resume record")
                let isOnPhoneCall = Device.IsOnPhoneCall()
                if isOnPhoneCall {
                    MinutesLogger.record.info("current isOnPhoneCall")
                    UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_CanNotRecordInCall, on: self.view)
                    return
                }
                MinutesAudioRecorder.shared.resume()

                self.tracker.tracker(name: .recordingPage, params: ["action_name": "continue_recording"])
                self.tracker.tracker(name: .recordingClick, params: ["click": "continue_recording", "target": "none"])
            }
        }
        panel.stopRecordBlock = { [weak self] in
            MinutesLogger.recordBasic.info("stop record")

            guard let self = self else { return }
            NotificationCenter.default.post(name: Notification.minutesAudioRecordingVCDismiss,
                                            object: nil,
                                            userInfo: [Notification.Key.minutesAudioRecordIsStop: true])
            MinutesAudioRecorder.shared.stop()

            self.tracker.tracker(name: .recordingPage, params: ["action_name": "stop_recording"])

            let targetView = self.userResolver.navigator.mainSceneWindow
            MinutesToast.showTips(with: BundleI18n.Minutes.MMWeb_G_RecordingSaved, targetView: targetView)

            if let backSelector = self.onClickBackButton {
                backSelector()
            } else {
                self.dismiss(animated: true, completion: nil)
            }

            self.stoped = true
        }
        if let dependency = dependency, dependency.isShareEnabled(){
            panel.shareButton.isHidden = false
            panel.shareBlock = { [weak self] in
                self?.showSharePanelWhenClickShareButton()
            }
        } else {
            panel.shareButton.isHidden = false
        }
        panel.translationBlock = { [weak self] in
            self?.showTranslationPanel()
        }
        return panel
    }()

    private lazy var navigationBar: MinutesRecordNavigationBar = {
        let view = MinutesRecordNavigationBar()
        view.backButton.addTarget(self, action: #selector(onBtnBack), for: .touchUpInside)
        view.titleEditButton.addTarget(self, action: #selector(onBtnEditTitle), for: .touchUpInside)
        return view
    }()

    lazy var contentContainer: MinutesAudioContentView = {
        let view = MinutesAudioContentView(resolver: userResolver, frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 0), minutes: minutes, isInAudioPreview: false)
        view.delegate = self
        view.prepareForAudioListening()
        return view
    }()

    var isShowNavBar: Bool = true
    let session: MinutesSession

    init(session: MinutesSession) {
        self.session = session
        viewModel = MinutesAudioContentViewModel(minutes: session.minutes)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        MinutesLogger.record.info("audio vc deinit")
        invalidateTimer()
        session.willLeaveMinutes()
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    public override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBase

        if isShowNavBar {
            view.addSubview(navigationBar)
            navigationBar.snp.makeConstraints { (maker) in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(view.safeAreaLayoutGuide)
            }
        }

        view.addSubview(contentContainer)
        view.addSubview(recordPanel)
        contentContainer.snp.makeConstraints { (maker) in
            maker.top.equalTo(isShowNavBar ? navigationBar.snp.bottom : view.safeAreaLayoutGuide)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(recordPanel.snp.top)
        }
        recordPanel.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
        }

        addMinuteStatusObserver()
        addMinuteUploadStatusObserver()
        addAudioHandler()
        addAudioRecordTimer()

        AudioSuspendable.removeRecordSuspendable()

        tracker.tracker(name: .recordingPage, params: ["action_name": "display"])
        tracker.tracker(name: .recordingView, params: [:])

        checkIsInterrupt()
        addInterruptHandler()
        setTitle()
        setLanguage(MinutesAudioRecorder.shared.language)

        if fromSource == .createIcon {
            MinutesRecorderReciableTracker.shared.endEnterRecorder()
        }

        recordPanel.updateTranslationButton(isTranslation: isInTranslationMode)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)

        loadWave()
    }

    func checkIsInterrupt() {
        if let interruptionType = MinutesAudioRecorder.shared.interruptionType, interruptionType == .began {
            enablePauseContinueButton(false)
            showHUD(BundleI18n.Minutes.MMWeb_G_RecordingStoppedWhenCalling, type: .interrupt)
        }
    }

    func addInterruptHandler() {
        MinutesAudioRecorder.shared.didInterruption = { [weak self] type in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if type == .began {
                    self.enablePauseContinueButton(false)
                    self.showHUD(BundleI18n.Minutes.MMWeb_G_RecordingStoppedWhenCalling, type: .interrupt)
                } else if type == .ended {
                    self.enablePauseContinueButton(true)
                    self.closeHUD(type: .interrupt)
                }
            }
        }
    }

    func enablePauseContinueButton(_ enabled: Bool) {
        recordPanel.pauseContinueButton.isUserInteractionEnabled = enabled
        recordPanel.pauseContinueButton.alpha = enabled ? 1.0 : 0.25
    }

    private func addMinuteStatusObserver() {
        checkMinutesReady()
        viewModel.minutes.data.listeners.addListener(self)
        viewModel.minutes.info.listeners.addListener(self)
    }

    private func addMinuteUploadStatusObserver() {
        MinutesAudioDataUploadCenter.shared.listeners.addListener(self)
    }

    private func onMinutesAudioDataUpdate(_ data: MinutesAudioDataUploadCenterWorkLoad) {

        DispatchQueue.main.async {
            switch data {
            case .heavy:
                if let date = self.weakNetworkHUDDate {
                    if Date().timeIntervalSince(date) / 60 > 2 {
                        self.showHUD(BundleI18n.Minutes.MMWeb_G_RecordingNoInternetConnectionInfo, type: .network)
                        self.weakNetworkHUDDate = Date()
                    }
                } else {
                    self.weakNetworkHUDDate = Date()
                    self.showHUD(BundleI18n.Minutes.MMWeb_G_RecordingNoInternetConnectionInfo, type: .network)
                }
            default:
                self.weakNetworkHUDDate = nil
                self.closeHUD(type: .network)
            }
        }
    }

    private func checkMinutesReady() {
        setTitle()

        var timeStr = ""
        if let startTime = viewModel.minutes.basicInfo?.startTime {
            let time = TimeInterval(startTime) / 1000.0
            timeStr = time.localeDate()
        }
        navigationBar.timeLabel.text = timeStr

        let data = viewModel.minutes.data
        let translateData = viewModel.minutes.translateData
        if isInTranslationMode, let translateData = translateData {
            if translateData.status == .ready {
                onMinutesDataReady(translateData, didCompleted: nil)
            }
        } else {
            if data.status == .ready {
                onMinutesDataReady(data, didCompleted: nil)
            }
        }
    }

    @objc func closeHUD(_ sender: UIButton) {
        if let superview = sender.superview, let type = MinutesRecordHUD.HUDType(rawValue: superview.tag) {
            closeHUD(type: type)
        } else {
            sender.superview?.removeFromSuperview()
        }
    }

    func closeHUD(type: MinutesRecordHUD.HUDType) {
        let hud = huds.first(where: { $0.tag == type.rawValue })
        hud?.removeFromSuperview()
        huds.removeAll(where: { $0.tag == type.rawValue })
    }

    func showHUD(_ text: String, type: MinutesRecordHUD.HUDType) {
        var statusHUD: MinutesRecordHUD?
        for hud in huds where hud.tag == type.rawValue {
            statusHUD = hud
        }
        let networkStyle = type == .network
        let hideCloseButton = type == .network || type == .interrupt
        var block: ((MinutesRecordHUD) -> Void) = { hud in
            hud.tag = type.rawValue
            hud.closeButton.addTarget(self, action: #selector(self.closeHUD(_:)), for: .touchUpInside)
            hud.textLabel.text = text
            hud.backgroundColor = !networkStyle ? UIColor.ud.primaryFillSolid02 : UIColor.ud.functionWarningFillSolid02
            hud.closeButton.isHidden = hideCloseButton
            hud.imageView.tintColor = !networkStyle ? UIColor.ud.functionInfoContentDefault : UIColor.ud.colorfulOrange
            hud.imageView.image = networkStyle ? UDIcon.warningColorful: UDIcon.infoColorful
        }
        if let hud = statusHUD {
            block(hud)
        } else {
            let hud = MinutesRecordHUD()
            block(hud)
            view.addSubview(hud)
            hud.snp.makeConstraints { (maker) in
                maker.top.equalTo(navigationBar.snp.bottom)
                maker.left.right.equalToSuperview()
            }
            huds.append(hud)
        }

        if networkStyle {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.closeHUD(type: .network)
            }
        }
    }

    func addAudioRecordTimer() {
        recordTimer = Timer(timeInterval: 1.0, repeats: true, block: { [weak self] (_) in
            guard let self = self else { return }
            let recordingTime = MinutesAudioRecorder.shared.recordingTime
            let timeInterval = recordingTime
            let timeStr = timeInterval.autoFormat(fullFormat: true) ?? ""
            self.recordPanel.recordTimeLabel.text = timeStr

            if recordingTime >= MinutesAudioRecorder.maxRecordTime {
                MinutesAudioRecorder.shared.stop()
            } else if recordingTime >= MinutesAudioRecorder.showTipsTime && !MinutesAudioRecorder.shared.hasShownHud {
                self.showHUD(BundleI18n.Minutes.MMWeb_G_RecordingMaximumLengthInfo(4), type: .tips)
                MinutesAudioRecorder.shared.hasShownHud = true
            }
        })
        if let timer = recordTimer {
            RunLoop.current.add(timer, forMode: .common)
            timer.fire()
        }
    }

    func loadWave() {
        recordPanel.loadWave()
    }

    func invalidateTimer() {
        recordTimer?.invalidate()
    }

    func addAudioHandler() {
        MinutesAudioRecorder.shared.listeners.addListener(self)
    }

    public func onMinutesStatusReady(_ info: MinutesInfo) {
        MinutesLogger.record.info("onMinutesStatusReady")
    }

    public func onMinutesDataReady(_ data: MinutesData, scrollToBottom: Bool = true, didCompleted: (() -> Void)?) {
        MinutesLogger.record.info("onMinutesDataReady, language name:  \(MinutesAudioRecorder.shared.language.name), spoken lanuages: \(viewModel.minutes.spokenLanguages)")
        setLanguage(MinutesAudioRecorder.shared.language)

        contentContainer.setParagraphs(data.subtitles,
                                       lastSentenceFinal: data.lastSentenceFinal,
                                       commentsInfo: data.paragraphComments,
                                       isInTranslationMode: isInTranslationMode,
                                       didCompleted: didCompleted)
        var extra: [String: Any] = [:]
        extra["objectToken"] = viewModel.minutes.objectToken
        extra["hasVideo"] = viewModel.minutes.basicInfo?.mediaType == .video
        extra["contentSize"] = viewModel.minutes.data.subtitlesContentSize
        extra["mediaDuration"] = viewModel.minutes.basicInfo?.duration
        InnoPerfMonitor.shared.update(extra: extra)
    }

    @objc func onBtnBack() {
        MinutesLogger.record.info("audio recording page back")
        let audioFloatingView = AudioFloatingView(resolver: userResolver)
        let minutes = self.minutes

        audioFloatingView.onTapViewBlock = { resolver in
            DispatchQueue.main.async {
                let params = MinutesShowParams(minutes: minutes, userResolver: resolver, recordingSource: .floatingWindow)
                let vc = MinutesManager.shared.startMinutes(with: .record, params: params)

                MinutesLogger.record.info("to audio recording page")

                guard let from = resolver.navigator.mainSceneTopMost else { return }
                
                resolver.navigator.present(vc,
                                         from: from,
                                         prepare: { $0.modalPresentationStyle = .fullScreen },
                                         animated: true,
                                         completion: {
                                            AudioSuspendable.removeRecordSuspendable()
                                         })
            }
        }

        AudioSuspendable.addRecordSuspendable(customView: audioFloatingView, size: AudioFloatingView.viewSize)

        NotificationCenter.default.post(name: Notification.minutesAudioRecordingVCDismiss,
                                        object: nil,
                                        userInfo: [Notification.Key.minutesAudioRecordIsStop: false])
        if let backSelector = self.onClickBackButton {
            backSelector()
        } else {
            self.dismiss(animated: true, completion: nil)
        }

        tracker.tracker(name: .recordingMiniView, params: [:])
    }

    @objc func onBtnEditTitle() {
        let alertVC = UIAlertController(title: BundleI18n.Minutes.MMWeb_G_Rename, message: nil, preferredStyle: .alert)
        alertVC.addTextField { [weak self] (textField) in
            textField.text = self?.viewModel.minutes.basicInfo?.topic
            textField.delegate = self
        }
        alertVC.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_Cancel, style: .default, handler: nil))
        alertVC.addAction(UIAlertAction(title: BundleI18n.Minutes.MMWeb_G_ConfirmButton, style: .default, handler: { [weak self] (_) in
            if let text = (alertVC.textFields?.first)?.text, text.isEmpty == false {
                self?.handleConfirm(text: text)
            }
        }))
        present(alertVC, animated: true, completion: nil)
    }
    
    func handleConfirm(text: String) {
        let info = minutes.info
        info.updateTitle(catchError: true, topic: text, completionHandler: { [weak self] result in
            DispatchQueue.main.async {
                self?.handleConfirmResult(result: result, text: text)
            }
        })
    }
    
    func handleConfirmResult(result: Result<Void, Error>, text: String) {
        switch result {
        case .success:
            if self.navigationBar.titleLabel.text == text {
                self.tracker.tracker(name: .recordingClick, params: ["click": "header_title_edit", "target": "none", "is_change": "false"])
            } else {
                self.navigationBar.titleLabel.text = text
                MinutesAudioRecorder.shared.minutes?.setTopic(text)
                self.tracker.tracker(name: .recordingClick, params: ["click": "header_title_edit", "target": "none", "is_change": "true"])
            }
        case .failure:
            self.tracker.tracker(name: .recordingClick, params: ["click": "header_title_edit", "target": "none", "is_change": "false"])
        }
    }

    func setLanguage(_ lang: Language) {
        recordPanel.languageButton.middleLabel.text = lang.name
    }

    func setTitle() {
        navigationBar.titleLabel.text = viewModel.minutes.topic
    }

    // 录制或翻译
    func presentChooseLanVC(_ point: CGPoint? = nil) {
        if point == nil && viewModel.minutes.data.subtitles.isEmpty {
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_NoTranscript, on: view)
            return
        }

        var items: [MinutesTranslationLanguageModel] = []

        if let point = point {
            for language in viewModel.minutes.spokenLanguages {
                let item = MinutesTranslationLanguageModel(language: language.name,
                                                           code: language.code,
                                                           isHighlighted: language == MinutesAudioRecorder.shared.language)
                items.append(item)
            }

            // 录制语言选择
            let menuVC = MinutesRecordLanguageChooseController(items: items)
            menuVC.controlPositionInWindow = point

            let previousLang = MinutesAudioRecorder.shared.language
            menuVC.selectBlock = { [weak self] lang in
                guard let self = self else { return }
                MinutesAudioRecorder.shared.language = lang
                self.setLanguage(lang)
                self.recordPanel.rotateArrow()

                self.viewModel.minutes.record?.changeSpokenLaunguage(catchError: false, lang) { [weak self] in
                    self?.tracker.tracker(name: .recordingClick, params: ["click": "subtitle_language_change", "target": "none", "from_language": previousLang.trackerLanguage(), "action_language": lang.trackerLanguage()])
                }
            }
            menuVC.dismissBlock = { [weak self] in
                self?.recordPanel.rotateArrow()
            }
            present(menuVC, animated: false, completion: nil)

            recordPanel.rotateArrow()
        } else {
            for language in viewModel.minutes.subtitleLanguages where language != .default {
                let item = MinutesTranslationLanguageModel(language: language.name,
                                                           code: language.code,
                                                           isHighlighted: language == currentTranslationChosenLanguage)
                items.append(item)
            }

            // 翻译语言选择
            let center = SelectTargetLanguageTranslateCenter(items: items)
            center.selectBlock = { [weak self] vm in
                guard let self = self else {
                    return
                }
                let lang = Language(name: vm.language, code: vm.code)
                self.translateAction(lang)
            }
            center.showSelectDrawer(from: self, resolver: userResolver)
        }
    }

    func exitOriginalTextViewIfNeeded() {
        contentContainer.originalTextView?.removeFromSuperview()
    }

    func translateAction(_ lang: Language) {
        exitOriginalTextViewIfNeeded()

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
        hud.frame = view.bounds
        view.addSubview(hud)

        viewModel.minutes.translateAudio(catchError: false, language: lang) { [weak self] result in
            guard let self = self, isTranslateCancel == false else { return }

            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    hud.removeFromSuperview()
                    self.currentTranslationChosenLanguage = previousLang

                    self.showTranslateFailHud(isTranslating)
                case .success(let data):
                    hud.removeFromSuperview()
                    self.onMinutesDataReady(data, scrollToBottom: false, didCompleted: nil)
                    self.recordPanel.updateTranslationButton(isTranslation: true)
                    self.showTranslateSuccessHud(isTranslating)
                }
            }
        }
    }
    
    func showTranslateSuccessHud(_ isTranslating: Bool) {
        if isTranslating {
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_Translated, on: self.view, delay: 2.0)
        }
    }
    
    func showTranslateFailHud(_ isTranslating: Bool) {
        if !MinutesCommonErrorToastManger.individualInternetCheck() { return }
        UDToast.showTips(with: isTranslating ? BundleI18n.Minutes.MMWeb_G_FailedToTranslateTryAgainLater : BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: self.view, delay: 2.0)
    }

    func exitTranlation() {
        exitOriginalTextViewIfNeeded()

        var isTranslateCancel: Bool = false

        // 存储当前选择的语言
        let previousLang = currentTranslationChosenLanguage
        currentTranslationChosenLanguage = .default

        let isTranslating = true
        let hud = MinutesTranslationHUD(isTranslating: isTranslating)
        hud.closeBlock = { [weak self, weak hud] in
            isTranslateCancel = true
            // 暂时还没有cancel接口
            self?.currentTranslationChosenLanguage = previousLang
            hud?.removeFromSuperview()
        }
        hud.frame = view.bounds
        view.addSubview(hud)

        exitTranslateRequest(previousLang: previousLang, isTranslating: isTranslating, isTranslateCancel: isTranslateCancel, hud: hud)
    }
    
    func exitTranslateRequest(previousLang: Language, isTranslating: Bool, isTranslateCancel: Bool, hud: MinutesTranslationHUD) {
        viewModel.minutes.exitTranslateAudio(catchError: false) { [weak self] result in
            guard let self = self, isTranslateCancel == false else { return }

            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    hud.removeFromSuperview()
                    self.currentTranslationChosenLanguage = previousLang

                    if !MinutesCommonErrorToastManger.individualInternetCheck() { break }
                    UDToast.showTips(with: isTranslating ? BundleI18n.Minutes.MMWeb_G_FailedToTranslateTryAgainLater : BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: self.view, delay: 2.0)
                case .success(let data):
                    hud.removeFromSuperview()
                    self.onMinutesDataReady(data, scrollToBottom: false, didCompleted: nil)
                    self.recordPanel.updateTranslationButton(isTranslation: false)
                }
            }
        }
    }

    func showTranslationPanel() {
        self.tracker.tracker(name: .clickButton, params: ["action_name": "subtitle_language_change"])
        if self.isInTranslationMode {
            self.exitTranlation()
        } else {
            self.presentChooseLanVC()
        }
    }
}

extension MinutesAudioRecordingController: MinutesDataChangedListener {
    public func onMinutesDataStatusUpdate(_ data: MinutesData) {
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

extension MinutesAudioRecordingController: MinutesInfoChangedListener {
    public func onMinutesInfoStatusUpdate(_ info: MinutesInfo) {
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

extension MinutesAudioRecordingController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else {
            return true
        }
        let newLength = text.count + string.count - range.length
        return newLength <= limitLength
    }
}

extension MinutesAudioRecordingController: MinutesAudioDataUploadListener {
    func audioDataUploadChanged(status: MinutesAudioDataUploadCenterWorkLoad) {
        onMinutesAudioDataUpdate(status)
    }
    func audioDataUploadComplete(data: String) {
        
    }
}

extension MinutesAudioRecordingController {
    
    private func trackShare() {
        tracker.tracker(name: .recordingPage, params: ["action_name": "header_share"])
        
        var trackParams: [AnyHashable: Any] = [:]
        trackParams.append(.headerShareActionName)
        tracker.tracker(name: .clickButton, params: trackParams)
        tracker.tracker(name: .recordingClick, params: ["click": "header_share", "target": "none"])
    }
    
    private func showSharePanelWhenClickShareButton() {
        trackShare()

        guard let info = viewModel.minutes.basicInfo else { return }
        let shareType: Int = 28
        dependency?.docs?.openDocShareViewController(token: info.objectToken,
                                        type: shareType,
                                        isOwner: info.isOwner ?? false,
                                        ownerID: info.ownerID,
                                        ownerName: info.ownerInfo?.userName ?? "",
                                        url: viewModel.minutes.baseURL.absoluteString,
                                        title: info.topic,
                                        tenantID: "",
                                        needPopover: false,
                                        padPopDirection: .up,
                                        popoverSourceFrame: nil,
                                        sourceView: nil,
                                        isInVideoConference: false,
                                        hostViewController: self)
    }
}

extension MinutesAudioRecordingController: MinutesAudioRecordingViewDelegate {
    func containerViewController() -> UIViewController {
        return self
    }
}

extension MinutesAudioRecordingController: MinutesAudioRecorderListener {
    func audioRecorderDidChangeStatus(status: MinutesAudioRecorderStatus) {
        self.recordPanel.isPausing = status == .paused || status == .idle
        if status == .paused {
            self.invalidateTimer()
        } else if status == .recording {
            self.addAudioRecordTimer()
        }

        if status == .paused || status == .idle {
            self.invalidateTimer()
        } else if status == .recording {
            self.addAudioRecordTimer()
        }

        if status == .idle {

            if let backSelector = self.onClickBackButton {
                backSelector()
            } else {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func audioRecorderOpenRecordingSucceed(isForced: Bool) {
        
    }
    
    func audioRecorderTryMideaLockfailed(error: LarkMedia.MediaMutexError, isResume: Bool) {
        if case let MediaMutexError.occupiedByOther(context) = error {
            if let msg = context.1 {
                UDToast.showFailure(with: msg, on: self.view, delay: 2)
            }
        } else {
            UDToast.showFailure(with: BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: self.view, delay: 2)
        }
    }
    
    func audioRecorderTimeUpdate(time: TimeInterval) {
        
    }
}
