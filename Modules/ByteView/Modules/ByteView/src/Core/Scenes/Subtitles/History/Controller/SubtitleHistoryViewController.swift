//
//  SubtitleHistoryViewController.swift
//  ByteView
//
//  Created by kiri on 2020/6/9.
//

import UIKit
import RxSwift
import Action
import RichLabel
import SnapKit
import ByteViewUI
import ByteViewTracker
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewSetting

class SubtitleHistoryViewController: VMViewController<SubtitlesViewModel> {
    var subtitle: InMeetSubtitleViewModel?

    private var isBackBtnClicked = false

    private var viewForGuide = UIView()
    var filterBlock: ((SubtitlesFilterViewController) -> Void)?

    var closeHistoryBlock: (() -> Void)?
    var closeSubtitleBlock: (() -> Void)?

    private weak var guideView: GuideView?
    private var menuFixer: MenuFixer?

    private lazy var historyView: SubtitleHistoryView = {
        let view = SubtitleHistoryView(viewModel: self.viewModel)
        view.tableView.keyboardDismissMode = .onDrag
        view.filterBlock = { [weak self] filterVC in
            self?.filterBlock?(filterVC)
        }
        view.openDocBlock = { [weak self] url in
            self?.viewModel.larkRouter.gotoDocs(urlString: url, context: ["from": "subtitles"], from: self)
        }
        return view
    }()

    private lazy var closeButton: UIBarButtonItem = {
        let imgKey: UniverseDesignIcon.UDIconType = isSubtitleScene ? .closeOutlined : .leftOutlined
        let color = preferredNavigationBarStyle.displayParams.buttonTintColor
        let highlighedColor = preferredNavigationBarStyle.displayParams.buttonHighlightTintColor
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(imgKey, iconColor: color, size: CGSize(width: 20, height: 20)), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(imgKey, iconColor: highlighedColor, size: CGSize(width: 20, height: 20)), for: .highlighted)
        actionButton.addTarget(self, action: #selector(closeSubtitle), for: .touchUpInside)
        return UIBarButtonItem(customView: actionButton)
    }()

    private lazy var backButton: UIBarButtonItem = {
        let imgKey: UniverseDesignIcon.UDIconType = isSubtitleScene ? .liveSubtitlesOutlined : .leftOutlined
        let color = preferredNavigationBarStyle.displayParams.buttonTintColor
        let highlighedColor = preferredNavigationBarStyle.displayParams.buttonHighlightTintColor
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(imgKey, iconColor: color, size: CGSize(width: 20, height: 20)), for: .normal)
        actionButton.setImage(UDIcon.getIconByKey(imgKey, iconColor: highlighedColor, size: CGSize(width: 20, height: 20)), for: .highlighted)
        actionButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        return UIBarButtonItem(customView: actionButton)
    }()

    private lazy var settingButton: UIBarButtonItem = {
        let button = UIButton(type: .custom)
        let normalImage = UDIcon.getIconByKey(.settingOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20))
        let highlightedImage = UDIcon.getIconByKey(.settingOutlined, iconColor: .ud.iconN3, size: CGSize(width: 20, height: 20))
        button.setImage(normalImage, for: .normal)
        button.setImage(highlightedImage, for: .highlighted)
        button.addTarget(self, action: #selector(didClickSetting(_:)), for: .touchUpInside)
        viewForGuide.isUserInteractionEnabled = false
        button.addSubview(viewForGuide)
        viewForGuide.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return UIBarButtonItem(customView: button)
    }()

    var isSubtitleScene = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc func goBack() {
        let breakoutRoomId = self.viewModel.meeting.data.breakoutRoomId
        viewModel.httpClient.send(SetSubtitlesFilterRequest(users: [], breakoutRoomId: breakoutRoomId))
        closeSubtitleBlock = nil
        self.closeHistoryBlock?()
        isBackBtnClicked = true
        viewModel.router.setWindowFloating(false)
    }

    @objc func closeSubtitle() {
        self.closeSubtitleBlock?()
        self.closeSubtitleBlock = nil
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        menuFixer = MenuFixer(viewController: self)
        viewModel.router.addListener(self)
        viewModel.meeting.addListener(self)
        subtitle?.breakoutRoom.addObserver(self, fireImmediately: false)
    }

    override func setupViews() {
        setNavigationItemTitle(text: I18n.View_M_Subtitles, color: .ud.textTitle)
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(historyView)
        historyView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let spaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        spaceItem.width = 16
        navigationItem.rightBarButtonItems = Display.pad ? [settingButton, spaceItem, backButton] : [settingButton]
        navigationItem.leftBarButtonItem = Display.pad ? closeButton : backButton
        // 显示左侧返回按钮
        if !Display.pad {
            hidesBackButton = false
        }
    }

    var padRegularStyle: Bool {
        return traitCollection.userInterfaceIdiom == .pad && VCScene.rootTraitCollection?.horizontalSizeClass == .regular
    }

    @objc func didClickSetting(_ sender: UIButton) {
        guard let subtitle = subtitle else { return }
        SubtitleTracks.trackClickSettings()
        SubtitleTracksV2.trackClickSubtitleSetting()
        SubtitleTracks.trackSubtitleSettings(from: "history_setting_button")
        let viewController = viewModel.setting.ui.createSubtitleSettingViewController(context: SubtitleSettingContext(fromSource: .subtitleHistory))
        if Display.pad {
            viewModel.router.presentDynamicModal(viewController,
                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                              compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true),
                                              from: self)
        } else {
            viewModel.larkRouter.push(viewController, animated: true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isMovingToParent {
            VCTracker.post(name: .vc_meeting_subtitle_page, params: [.action_name: "display"])
            setupOnboarding()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let action = guideView?.sureAction {
            action(.plain(content: ""))
        }
    }

    private func setupOnboarding() {
        setupOldSubtitlesOnboarding()
    }

    /// 旧引导-打开历史字幕指引
    private func setupOldSubtitlesOnboarding() {
        //  判断是否展示onboarding, 打开历史字幕指引
        guard viewModel.service.shouldShowGuide(.subtitleSetting) else {
            return
        }
        let guideView = self.guideView ?? GuideView(frame: view.bounds)
        self.guideView = guideView
        if guideView.superview == nil {
            view.addSubview(guideView)
            guideView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        guideView.setStyle(.plain(content: I18n.View_G_ClickHereToChangeLanguages), on: .bottom,
                           of: viewForGuide, forcesSingleLine: true)
        guideView.sureAction = { [weak self] _ in
            self?.viewModel.service.didShowGuide(.subtitleSetting)
            self?.guideView?.removeFromSuperview()
            self?.guideView = nil
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.historyView.viewWillTransition()
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    deinit {
        closeSubtitleBlock?()
    }
}

extension SubtitleHistoryViewController: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        if VCScene.supportsMultipleScenes { return }
        if !isFloating {
            subtitle?.isSubtitleVisible = true
            let breakoutRoomId = self.viewModel.meeting.data.breakoutRoomId
            self.viewModel.httpClient.send(SetSubtitlesFilterRequest(users: [], breakoutRoomId: breakoutRoomId))
            self.navigationController?.dismiss(animated: true)
            if isBackBtnClicked {
                SubtitleTracksV2.trackClickBackButton()
            } else {
                SubtitleTracksV2.trackClickFloatWindow()
            }
        }
    }
}

extension SubtitleHistoryViewController: InMeetMeetingListener {
    func didReleaseInMeetMeeting(_ meeting: InMeetMeeting) {
        if VCScene.supportsMultipleScenes { return }
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.navigationController?.dismiss(animated: true)
        }
    }
}

extension SubtitleHistoryViewController: BreakoutRoomManagerObserver {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        Logger.meeting.info("SubtitleHistoryViewController breakoutRoomInfoChanged: id = \(info?.breakoutRoomId)")
        viewModel.router.setWindowFloating(false)
    }
}
