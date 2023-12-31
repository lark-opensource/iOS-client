//
//  InMeetFullScreenMicrophoneComponent.swift
//  ByteView
//
//  Created by liujianlong on 2021/10/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ByteViewUDColor
import SnapKit
import UniverseDesignShadow
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTheme
import RxSwift
import ByteViewCommon
import ByteViewSetting
import ByteViewNetwork
import ByteViewRtcBridge

class PadFullScreenMicrophoneBar: UIViewController {

    let contentView = UIView()
    let expandBtn = UIButton(type: .custom)
    let micBtn = UIButton(type: .custom)
    let micIconView = MicIconView(iconSize: 24)
    let unreadCountLabel = PaddingLabel()
    let micAlertImageView = UIImageView(image: CommonResources.iconDeviceDisabled)
    let meeting: InMeetMeeting

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSubviews()
    }

    private func setupSubviews() {
        self.contentView.clipsToBounds = true
        self.contentView.layer.cornerRadius = 8.0

        self.view.layer.cornerRadius = 8.0
        self.view.layer.borderWidth = 1.0
        self.view.layer.ud.setBorderColor(UIColor.ud.lineDividerDefault)
        self.view.layer.ud.setShadow(type: .s4Down)

        let leftImg = UDIcon.getIconByKey(.vcToolbarDownFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16.0, height: 16.0))
        expandBtn.setImage(leftImg, for: .normal)

        micIconView.setMicState(.on())

        expandBtn.addInteraction(type: .hover)
        micBtn.addInteraction(type: .hover)

        expandBtn.vc.setBackgroundColor(UIColor.ud.bgBody, for: .normal)
        expandBtn.vc.setBackgroundColor(UIColor.ud.N200, for: .focused)
        expandBtn.vc.setBackgroundColor(UIColor.ud.N300, for: .highlighted)

        micBtn.vc.setBackgroundColor(UIColor.ud.bgBodyOverlay, for: .normal)
        micBtn.vc.setBackgroundColor(UIColor.ud.N200, for: .focused)
        micBtn.vc.setBackgroundColor(UIColor.ud.N300, for: .highlighted)

        unreadCountLabel.backgroundColor = UIColor.ud.functionDangerContentDefault
        unreadCountLabel.layer.cornerRadius = 8.0
        unreadCountLabel.clipsToBounds = true
        unreadCountLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        unreadCountLabel.font = .systemFont(ofSize: 10.0)
        unreadCountLabel.textInsets = UIEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 4.0)
        unreadCountLabel.textAlignment = .center

        self.view.addSubview(contentView)
        self.contentView.addSubview(expandBtn)
        self.contentView.addSubview(micBtn)
        self.contentView.addSubview(unreadCountLabel)
        micBtn.addSubview(micIconView)

        micBtn.addSubview(micAlertImageView)
        micAlertImageView.isHidden = true

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        expandBtn.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: 40.0, height: 48.0))
        }

        micBtn.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: 48, height: 48))
            make.left.equalTo(expandBtn.snp.right)
        }

        micIconView.snp.makeConstraints { make in
            make.center .equalToSuperview()
            make.height.width.equalTo(24)
        }

        micAlertImageView.snp.makeConstraints { make in
            make.size.equalTo(14)
            make.bottom.equalTo(-9)
            make.right.equalTo(-6)

        }
        unreadCountLabel.snp.makeConstraints { make in
            make.top.right.equalTo(self.expandBtn).inset(4.0)
            make.height.equalTo(16.0)
            make.width.greaterThanOrEqualTo(16.0)
        }
    }

    // nolint: duplicated_code
    func updateMicBtn(by state: MicViewState, isMicComponentHidden: Bool) {
        micIconView.isHidden = isMicComponentHidden
        self.loadViewIfNeeded()
        micAlertImageView.isHidden = state.isHiddenMicAlertIcon
        switch state {
        case .on, .off:
            let isOn = state == .on
            micBtn.tintColor = isOn ? UIColor.ud.N700 : UIColor.ud.functionDangerContentDefault
            micIconView.setMicState(isOn ? .on() : .off())
        case .denied:
            micBtn.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(.denied)
        case .sysCalling:
            micBtn.tintColor = .ud.iconDisabled
            micIconView.setMicState(.disabled())
        case .forbidden:
            micBtn.vc.setBackgroundColor(UIColor.ud.bgBodyOverlay, for: .highlighted)
            micBtn.tintColor = UIColor.ud.iconDisabled
            micAlertImageView.isHidden = true
            micIconView.setMicState(.disabled())
        case .callMe(let callMeState, false):
            switch callMeState {
            case .denied:
                micBtn.tintColor = UIColor.ud.iconDisabled
                micIconView.setMicState(.denied)
            case .on, .off:
                micBtn.tintColor = callMeState == .on ? UIColor.ud.N700 : UIColor.ud.functionDangerContentDefault
                micIconView.setMicState(callMeState.toMicIconState)
            }
        case .disconnect:
            micBtn.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(.disconnectedToolbar)
        case .room(let bindState):
            micBtn.tintColor = bindState.roomTintColor
            micIconView.setMicState(bindState.roomState)
        case .callMe(let callMeState, true):
            micBtn.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(callMeState.toMicIconState)
        }
        self.view.alpha = 1.0
    }

    func handlePadMicSpeakerDisabled(_ isDisabled: Bool) {
        if isDisabled {
            micBtn.vc.setBackgroundColor(UIColor.ud.bgBodyOverlay, for: .highlighted)
            micBtn.tintColor = UIColor.ud.iconDisabled
            micAlertImageView.isHidden = true
            micIconView.setMicState(.disabled())
        } else {
            micBtn.vc.setBackgroundColor(UIColor.ud.N300, for: .highlighted)
            let isDenied = Privacy.audioDenied
            micAlertImageView.isHidden = !isDenied
            if isDenied {
                micBtn.tintColor = UIColor.ud.iconDisabled
                micIconView.setMicState(.denied)
            } else {
                micBtn.tintColor = UIColor.ud.functionDangerContentDefault
                micIconView.setMicState(.off())
            }
        }
    }
}

extension PadFullScreenMicrophoneBar: ChatMessageViewModelDelegate {
    func numberOfUnreadMessagesDidChange(count: Int) {
        // swiftlint:disable empty_count
        let maxUnreadCount: Int = 999
        unreadCountLabel.isHidden = count <= 0
        unreadCountLabel.text = count > maxUnreadCount ? "···" : String(count)
        // swiftlint:enable empty_count
    }
}

extension PadFullScreenMicrophoneBar: IMChatViewModelDelegate {
    func messageUnreadNumberDidUpdate(num: Int) {
        numberOfUnreadMessagesDidChange(count: num)
    }
}

class PhoneMicBar: UIViewController {
    let micButton = UIButton(type: .system)
    let micIconView = MicIconView(iconSize: 24)
    let micAlertImageView = UIImageView(image: CommonResources.iconDeviceDisabled)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    private static func makeBackgroundImage(isDarkMode: Bool) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 40, height: 40)
        let render = UIGraphicsImageRenderer(bounds: rect)
        let image = render.image { _ in
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 20)
            path.addClip()
            path.lineWidth = 1
            if isDarkMode {
                UIColor.ud.bgFloat.alwaysDark.withAlphaComponent(0.9).setFill()
            } else {
                UIColor.ud.bgFloat.alwaysLight.withAlphaComponent(0.9).setFill()
            }
            path.fill()
            if isDarkMode {
                UIColor.ud.lineBorderCard.alwaysDark.setStroke()
            } else {
                UIColor.ud.lineBorderCard.alwaysLight.setStroke()
            }
            path.stroke()
        }
        return image
    }

    private static var bgDarkImg = makeBackgroundImage(isDarkMode: true)
    private static var bgLightImg = makeBackgroundImage(isDarkMode: false)

    private static let micImg = UDIcon.getIconByKey(.micFilled, iconColor: UIColor.ud.N700, size: CGSize(width: 24, height: 24))

    private func setupSubviews() {
        if #available(iOS 13.0, *) {
            let correctStyle = UDThemeManager.userInterfaceStyle
            let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
            UITraitCollection.current = correctTraitCollection
        }
        let micBgImg = UIImage.dynamic(light: Self.bgLightImg, dark: Self.bgDarkImg)
        _ = Self.micImg
        micButton.setBackgroundImage(micBgImg, for: .normal)
        micButton.tintColor = UIColor.ud.N700
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 40, height: 40), cornerRadius: 20)
        micButton.layer.shadowPath = path.cgPath
        micButton.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
        micButton.layer.shadowOpacity = 1
        micButton.layer.shadowRadius = 8
        micButton.layer.shadowOffset = CGSize(width: 0, height: 4)

        micAlertImageView.isHidden = true

        self.view.addSubview(micButton)
        micButton.addSubview(micIconView)
        micButton.addSubview(micAlertImageView)

        micButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        micIconView.snp.makeConstraints { make in
            make.center .equalToSuperview()
            make.height.width.equalTo(24)
        }
        micAlertImageView.snp.makeConstraints { make in
            make.size.equalTo(14)
            make.bottom.equalTo(-9)
            make.right.equalTo(-6)
        }
    }

    // nolint: duplicated_code
    func updateMicBtn(by state: MicViewState, isMicComponentHidden: Bool) {
        micButton.isHidden = isMicComponentHidden
        self.loadViewIfNeeded()

        micAlertImageView.isHidden = state.isHiddenMicAlertIcon
        switch state {
        case .on, .off:
            let isOn = state == .on
            micButton.tintColor = isOn ? UIColor.ud.N700 : UIColor.ud.functionDangerContentDefault
            micIconView.setMicState(isOn ? .on() : .off())
        case .denied:
            micButton.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(.denied)
        case .sysCalling, .forbidden:
            micButton.tintColor = .ud.iconDisabled
            micIconView.setMicState(.disabled())
        case .callMe(let callMeState, false):
            switch callMeState {
            case .denied:
                micButton.tintColor = UIColor.ud.iconDisabled
                micIconView.setMicState(.denied)
            case .on, .off:
                micButton.tintColor = callMeState == .on ? UIColor.ud.N700 : UIColor.ud.functionDangerContentDefault
                micIconView.setMicState(callMeState.toMicIconState)
            }
        case .disconnect:
            micButton.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(.disconnectedToolbar)
        case .room(let bindState):
            micButton.tintColor = bindState.roomTintColor
            micIconView.setMicState(bindState.roomState)
        case .callMe(let callMeState, true):
            micButton.tintColor = UIColor.ud.iconDisabled
            micIconView.setMicState(callMeState.toMicIconState)
        }
        micButton.alpha = 1.0
    }
}

final class FullScreenMicophoneComponent: InMeetViewComponent, InMeetViewChangeListener {
    let meeting: InMeetMeeting
    let resolver: InMeetViewModelResolver
    var currentLayoutType: LayoutType
    weak var container: InMeetViewContainer?

    lazy var phoneMicBar = PhoneMicBar()
    lazy var padMicBar = PadFullScreenMicrophoneBar(meeting: meeting)
    var padCenterXCst: NSLayoutConstraint!
    private var isFullScreenMicHidden = false
    private let disposeBag = DisposeBag()

    func containerDidChangeLayoutStyle(container: InMeetViewContainer, prevStyle: MeetingLayoutStyle?) {
        updateVisibility(container: container)
    }

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        guard let container = container else { return }
        self.currentLayoutType = newContext.layoutType
        updateVisibility(container: container)
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        guard let container = self.container else {
            return
        }
        switch change {
        case .contentScene, .singleVideo:
            updateVisibility(container: container)
        case .containerDidLayout:
            fixPadBoundary()
        default:
            break
        }
    }

    private func updateVisibility(container: InMeetViewContainer) {
        let isHidden: Bool
        if container.context.isSingleVideoVisible {
            isHidden = true
        } else if !meeting.setting.showsMicrophone {
            isHidden = true
        } else if meeting.audioModeManager.bizMode.canShowMic {
            isHidden = container.meetingLayoutStyle != .fullscreen
            || (container.context.meetingScene == .thumbnailRow && container.context.meetingContent == .follow && Display.phone)
            || currentLayoutType.isPhoneLandscape
        } else {
            isHidden = true
        }
        container.context.isFullScreenMicHidden = isHidden
        self.isFullScreenMicHidden = isHidden
        if let state = meeting.audioModeManager.currentMicState {
            let isHidden = isFullScreenMicHidden
            if Display.phone {
                phoneMicBar.updateMicBtn(by: state, isMicComponentHidden: isHidden)
            } else {
                padMicBar.updateMicBtn(by: state, isMicComponentHidden: isHidden)
            }
        }
    }

    @objc
    func toggleButtonTapped(_ sender: UIControl) {
        if let container = container,
           container.meetingLayoutStyle == .fullscreen {
            let isSharing = container.context.meetingContent.isShareContent
            let shareType: String
            if container.context.meetingContent == .follow {
                shareType = "follow"
            } else if container.context.meetingContent == .shareScreen {
                shareType = "screen"
            } else if container.context.meetingContent == .whiteboard {
                shareType = "whiteboard"
            } else {
                shareType = "none"
            }
            InMeetFullScreenTracks.trackPadFullScreenUnfoldToolbar(isSharing: isSharing, shareType: shareType)
        }
        if let container = container,
           let singleVideo = container.component(by: .singleVideo) as? InMeetSingleVideoComponent,
           singleVideo.singleVideoViewController != nil {
            singleVideo.hideSingleVideo(animated: true)
        }
        self.container?.fullScreenDetector.postInterruptEvent()
    }

    @objc
    func micButtonTapped(_ sender: UIControl) {
        guard let container = container, !meeting.audioModeManager.shouldHandleMicClickEvent() else { return }

        let mute = meeting.microphone.isMuted
        meeting.microphone.muteMyself(!mute, source: .floating_button, completion: nil)

        let isSharing = container.context.meetingContent.isShareContent
        let shareType: String
        if container.context.meetingContent == .follow {
            shareType = "follow"
        } else if container.context.meetingContent == .shareScreen {
            shareType = "screen"
        } else if container.context.meetingContent == .whiteboard {
            shareType = "whiteboard"
        } else {
            shareType = "none"
        }
        InMeetFullScreenTracks.trackFullScreenClickMic(option: !mute, isSharing: isSharing, shareType: shareType)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    var componentIdentifier: InMeetViewComponentIdentifier = .fullScreenMicrophone

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) {
        self.meeting = viewModel.meeting
        self.container = container
        self.resolver = viewModel.resolver
        self.currentLayoutType = layoutContext.layoutType
        meeting.setting.addListener(self, for: .showsMicrophone)
        meeting.syncChecker.registerMicrophone(self)

        if Display.phone {
            self.phoneMicBar.micButton.addTarget(self, action: #selector(micButtonTapped(_:)), for: .touchUpInside)
            container.addContent(self.phoneMicBar, level: .fullScreenMicroPhone)
            self.phoneMicBar.view.snp.makeConstraints { make in
                make.edges.equalTo(container.fullScreenMicGuide)
            }
        } else {
            let panGest = UIPanGestureRecognizer(target: self, action: #selector(handlePadPan(_:)))
            let chatVM = resolver.resolve(ChatMessageViewModel.self)!
            let imChatVM = resolver.resolve(IMChatViewModel.self)!
            self.padMicBar.micBtn.addTarget(self, action: #selector(micButtonTapped(_:)), for: .touchUpInside)
            self.padMicBar.expandBtn.addTarget(self, action: #selector(toggleButtonTapped(_:)), for: .touchUpInside)
            container.addContent(self.padMicBar, level: .fullScreenMicroPhone)
            self.padMicBar.view.addGestureRecognizer(panGest)
            self.padMicBar.view.snp.makeConstraints { make in
                make.centerY.equalTo(container.fullScreenMicGuide)
            }
            self.padCenterXCst = self.padMicBar.view.centerXAnchor.constraint(equalTo: container.fullScreenMicGuide.centerXAnchor)
            self.padCenterXCst.isActive = true
            let unreadCount = meeting.setting.isUseImChat ? imChatVM.unreadCount : chatVM.messagesStore.unreadMessageCount
            self.padMicBar.numberOfUnreadMessagesDidChange(count: unreadCount)
            chatVM.addListener(self.padMicBar)
            imChatVM.addListener(self.padMicBar)
        }
        viewModel.viewContext.addListener(self, for: [.contentScene, .containerDidLayout, .singleVideo])
        meeting.volumeManager.addListener(self)
        meeting.audioModeManager.addListener(self)
    }

    deinit {
        meeting.syncChecker.unregisterMicrophone(self)
    }

    private func fixPadBoundary() {
        guard Display.pad,
              let container = self.container else {
            return
        }
        let halfWidth: CGFloat = 44
        let centerX = container.view.bounds.width * 0.5 + self.padCenterXCst.constant
        let left = centerX - halfWidth
        let right = centerX + halfWidth
        let sideInset: CGFloat = 20
        if left < sideInset {
            self.padCenterXCst.constant += sideInset - left
        } else if right > container.view.bounds.width - sideInset {
            self.padCenterXCst.constant -= right + sideInset - container.view.bounds.width
        }
    }

    @objc func handlePadPan(_ gest: UIPanGestureRecognizer) {
        let translation = gest.translation(in: nil)
        gest.setTranslation(.zero, in: nil)
        self.padCenterXCst?.constant += translation.x
        switch gest.state {
        case .ended, .failed:
            fixPadBoundary()
        default:
            break
        }
    }
}

extension FullScreenMicophoneComponent: VolumeManagerDelegate {
    func volumeDidChange(to volume: Int, rtcUid: RtcUID) {
        if rtcUid == meeting.myself.bindRtcUid {
            if Display.phone {
                phoneMicBar.micIconView.micOnView.updateVolume(volume)
            } else {
                padMicBar.micIconView.micOnView.updateVolume(volume)
            }
        }
    }
}

extension FullScreenMicophoneComponent: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        DispatchQueue.main.async {
            if let container = self.container {
                self.updateVisibility(container: container)
            }
        }
    }
}

extension FullScreenMicophoneComponent: InMeetAudioModeListener {
    func didChangeMicState(_ state: MicViewState) {
        if let container = self.container {
            updateVisibility(container: container)
        }
    }
}

extension FullScreenMicophoneComponent: MicrophoneStateRepresentable {
    var isMicMuted: Bool? {
        let view = Display.phone ? phoneMicBar.micIconView : padMicBar.micIconView
        guard !view.isHidden else { return nil }
        return view.currentState.isMuted
    }

    var micIdentifier: String {
        "FullScreenMic"
    }
}
