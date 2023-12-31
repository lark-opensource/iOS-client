//
//  MinutesAudioPreviewController.swift
//  Minutes
//
//  Created by panzaofeng on 2021/3/11.
//

import UIKit
import MinutesFoundation
import UniverseDesignToast
import MinutesNavigator
import EENavigator
import LarkContainer
import LarkAccountInterface
import MinutesNetwork
import UniverseDesignIcon

class MinutesAudioPreviewController: UIViewController, UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver { session.userResolver }
    @ScopedProvider var passportUserService: PassportUserService?
    

    var onClickBackButton: (() -> Void)?

    private var minutes: Minutes { session.minutes }
    private var viewModel: MinutesAudioContentViewModel


    var navigationBarIsHidden: Bool?

    weak var originalTextView: MinutesOriginalTextView?

    lazy var tracker: MinutesTracker = {
        return MinutesTracker(minutes: viewModel.minutes)
    }()

    var topic: String?

    var finished: Bool = false

    var currentTranslationChosenLanguage: Language = .default {
        didSet {
            InnoPerfMonitor.shared.update(extra: ["isInTranslationMode": isInTranslationMode])
        }
    }

    var isInTranslationMode: Bool {
        return currentTranslationChosenLanguage != .default
    }

    private lazy var navigationBar: MinutesAudioPreviewNavigationBar = {
        let view = MinutesAudioPreviewNavigationBar()
        view.backButton.addTarget(self, action: #selector(onBackButtonItem), for: .touchUpInside)
        return view
    }()

    private lazy var contentContainer: MinutesAudioContentView = {
        let view = MinutesAudioContentView(resolver: userResolver, frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 0), minutes: minutes, isInAudioPreview: true)
        view.delegate = self
        view.prepareForAudioListening()
        return view
    }()

    private lazy var translateButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.translateOutlined, iconColor: UIColor.ud.N500, size: CGSize(width: 36, height: 36)), for: .normal)

        button.addTarget(self, action: #selector(onBtnTranslate), for: .touchUpInside)

        button.addSubview(translateLabel)
        translateLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(button.snp.centerX)
            maker.bottom.equalTo(button.snp.centerY)
            maker.width.equalTo(24)
            maker.height.equalTo(18)
        }
        return button
    }()

    private lazy var translateLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill.nonDynamic
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 9)
        label.backgroundColor = UIColor.ud.colorfulOrange
        label.layer.borderWidth = 1.0
        label.layer.ud.setBorderColor(UIColor.ud.N00.nonDynamic)
        label.layer.cornerRadius = 9.0
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    private lazy var bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        let translateContainer = UIView()
        translateContainer.backgroundColor = UIColor.ud.bgBody
        translateContainer.addSubview(translateButton)

        view.addSubview(line)
        view.addSubview(translateContainer)

        line.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.height.equalTo(0.5)
        }
        translateContainer.snp.makeConstraints { (maker) in
            maker.left.top.bottom.right.equalToSuperview()
        }
        translateButton.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(18)
            maker.width.height.equalTo(24)
        }
        return view
    }()

    var isShowNavBar: Bool = true
    let session: MinutesSession

    init(session: MinutesSession) {
        self.session = session
        self.topic = session.topic
        viewModel = MinutesAudioContentViewModel(minutes: session.minutes)
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen

        InnoPerfMonitor.shared.entry(scene: .minutesDetail)
    }

    deinit {
        session.willLeaveMinutes()
        InnoPerfMonitor.shared.leave(scene: .minutesDetail)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        view.addSubview(bottomBar)

        contentContainer.snp.makeConstraints { (maker) in
            maker.top.equalTo(isShowNavBar ? navigationBar.snp.bottom : view.safeAreaLayoutGuide)
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(bottomBar.snp.top)
        }

        bottomBar.snp.makeConstraints { (maker) in
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-60)
            maker.left.right.equalToSuperview()
            maker.bottom.equalToSuperview()
        }

        addMinuteStatusObserver()
        checkMinutesDataReady()
        setTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationBarIsHidden = navigationController?.navigationBar.isHidden
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let navigationBarIsHidden = navigationBarIsHidden {
            navigationController?.navigationBar.isHidden = navigationBarIsHidden
        }
    }

    func setTitle() {
        navigationBar.titleLabel.text = topic
    }

    private func addMinuteStatusObserver() {
        viewModel.minutes.data.listeners.addListener(self)
        viewModel.minutes.info.listeners.addListener(self)
    }

    private func checkMinutesDataReady() {
        if let newTopic = viewModel.minutes.info.basicInfo?.topic {
            topic = newTopic
            setTitle()
        }
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

    public func onMinutesDataReady(_ data: MinutesData,
                                   scrollToBottom: Bool = true,
                                   didCompleted: (() -> Void)?) {
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

    @objc
    private func onBackButtonItem(_ sender: UIButton) {
        onBack()
    }

    @objc func onBtnTranslate() {
        presentChooseLanVC()
    }

    private func onBack() {
        if let backSelector = self.onClickBackButton {
            backSelector()
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

}

extension MinutesAudioPreviewController: MinutesDataChangedListener {
    public func onMinutesDataStatusUpdate(_ data: MinutesData) {
        DispatchQueue.main.async {
            switch data.status {
            case .ready:
                self.checkMinutesDataReady()
            default:
                break
            }
        }
    }
}

extension MinutesAudioPreviewController: MinutesInfoChangedListener {
    public func onMinutesInfoStatusUpdate(_ info: MinutesInfo) {
        MinutesLogger.record.info("MinutesAudioPreviewController status: \(info.status)")
        if finished {
            return
        }

        guard let statusInfo = info.statusInfo else {
            return
        }

        DispatchQueue.main.async {
            if statusInfo.objectStatus != .audioRecording && statusInfo.objectStatus != .audioRecordPause {
                var toastString: String?
                if info.basicInfo?.ownerInfo?.userId == self.passportUserService?.user.userID {
                    toastString = BundleI18n.Minutes.MMWeb_G_RecordingSaved
                } else {
                    toastString = BundleI18n.Minutes.MMWeb_G_RecordingSavedShared
                }
                if let toastString = toastString {
                    let targetView = self.userResolver.navigator.mainSceneWindow
                    MinutesToast.showTips(with: toastString, targetView: targetView)
                }
                self.finished = true
                self.onBack()
            }
        }
    }
}

extension MinutesAudioPreviewController: MinutesAudioRecordingViewDelegate {
    func containerViewController() -> UIViewController {
        return self
    }
}

extension MinutesAudioPreviewController {

    func exitTranlation() {
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

        viewModel.minutes.exitTranslateAudio(catchError: false) { [weak self] result in
            guard let self = self, isTranslateCancel == false else { return }

            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    // 一次失败就返回，不会多次返回
                    self.currentTranslationChosenLanguage = previousLang

                    hud.removeFromSuperview()
                    if !MinutesCommonErrorToastManger.individualInternetCheck() { break }
                    UDToast.showTips(with: isTranslating ? BundleI18n.Minutes.MMWeb_G_FailedToTranslateTryAgainLater : BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: self.view, delay: 2.0)
                case .success(let data):
                    self.onMinutesDataReady(data, scrollToBottom: false, didCompleted: nil)
                    self.translateButton.setImage(UIImage.dynamicIcon(.iconTranslateOutlined, dimension: 36, color: UIColor.ud.N500), for: .normal)
                    self.translateLabel.isHidden = true
                    hud.removeFromSuperview()
                }
            }
        }
    }

    func presentChooseLanVC() {
        if viewModel.minutes.data.subtitles.isEmpty {
            UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_NoTranscript, on: view)
            return
        }

        let items = createTranslationLanguageItems()
        presentTranlationLanVC(items: items)
    }
    
    func createTranslationLanguageItems() -> [MinutesTranslationLanguageModel] {
        var items: [MinutesTranslationLanguageModel] = []
        for language in viewModel.minutes.subtitleLanguages {
            let item = MinutesTranslationLanguageModel(language: language.name,
                                                       code: language.code,
                                                       isHighlighted: language == currentTranslationChosenLanguage)
            items.append(item)
        }
        return items
    }
    
    func presentTranlationLanVC(items: [MinutesTranslationLanguageModel]) {
        let center = SelectTargetLanguageTranslateCenter(items: items)
        center.selectBlock = { [weak self] vm in
            guard let self = self else {
                return
            }
            let lang = Language(name: vm.language, code: vm.code)
            
            if lang == .default {
                self.exitTranlation()
            } else {
                self.translateRequest(lang)
            }
        }
        center.showSelectDrawer(from: self, resolver: userResolver)
    }

    func translateRequest(_ lang: Language) {
        var isTranslateCancel: Bool = false

        // 存储当前选择的语言
        let previousLang = currentTranslationChosenLanguage
        currentTranslationChosenLanguage = lang

        tracker.tracker(name: .recordingClick, params: ["action_name": "subtitle_language_change", "from_language": previousLang.trackerLanguage(), "action_language": lang.trackerLanguage()])

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
                    
                    if !MinutesCommonErrorToastManger.individualInternetCheck() { break }
                    UDToast.showTips(with: isTranslating ? BundleI18n.Minutes.MMWeb_G_FailedToTranslateTryAgainLater : BundleI18n.Minutes.MMWeb_G_SomethingWentWrong, on: self.view, delay: 2.0)
                case .success(let data):
                    hud.removeFromSuperview()
                    self.onMinutesDataReady(data, scrollToBottom: false, didCompleted: nil)

                    if isTranslating {
                        UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_Translated, on: self.view, delay: 2.0)    
                        self.translateButton.setImage(UDIcon.getIconByKey(.translateOutlined, iconColor: UIColor.ud.colorfulBlue, size: CGSize(width: 36, height: 36)), for: .normal)

                        self.translateLabel.isHidden = false

                        self.translateLabel.text = self.currentTranslationChosenLanguage.code[0..<2].uppercased()
                    }
                }
            }
        }
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
         return String(self[start...])
    }
}
