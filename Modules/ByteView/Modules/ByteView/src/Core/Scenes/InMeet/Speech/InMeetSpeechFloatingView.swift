//
//  InMeetSpeechFloatingView.swift
//  ByteView
//
//  Created by ZhangJi on 2022/9/4.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import RxSwift
import RxRelay
import ByteViewSetting
import ByteViewRtcBridge

class InMeetSpeechFloatingView: UIView {

    private enum Layout {
        static let arrowButtonSize = CGSize(width: 28, height: 28)
    }

    var bag = DisposeBag()

    enum SpeechFloatingViewType {
        case up
        case down

        var nextValue: SpeechFloatingViewType {
            switch self {
            case .up:
                return .down
            case .down:
                return .up
            }
        }
    }

    let speechViewIsUp = BehaviorRelay<Bool>(value: false)

    weak var delegate: InMeetSpeechFloatingVCDelegate?

    var subviewDisposeBag = DisposeBag()

    private(set) var viewType: SpeechFloatingViewType = .down {
        didSet {
            guard viewType != oldValue else { return }
            updateView(with: viewType, forcedHidden: forcedHidden)
            speechViewIsUp.accept(speechViewShouldBeUp)
        }
    }

    // 强制收起floatingView，并不允许展开
    private(set) var forcedHidden: Bool = false {
        didSet {
            guard forcedHidden != oldValue else { return }
            updateView(with: viewType, forcedHidden: forcedHidden)
            speechViewIsUp.accept(speechViewShouldBeUp)
        }
    }

    var speechViewShouldBeUp: Bool {
        viewType == .up || forcedHidden
    }

    private lazy var speakingView: SpeakingView = {
        let speakingView = SpeakingView()
        speakingView.isHidden = true
        return speakingView
    }()

    private func updateArrowButton(isUp: Bool) {
        if isUp {
            arrowButton.setImage(UDIcon.getIconByKey(.upBoldOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16)), for: .normal)
            arrowButton.layer.cornerRadius = 6.0
            arrowButton.alpha = 0.8
            arrowButton.vc.setBackgroundColor(UDColor.bgFloat, for: .normal)
            arrowButton.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)

            buttonContentView.layer.borderWidth = 1.0
            buttonContentView.layer.cornerRadius = 6.0
            buttonContentView.layer.ud.setBorderColor(UDColor.lineBorderComponent)
            buttonContentView.layer.ud.setShadow(type: .s4Down)
        } else {
            arrowButton.setImage(UDIcon.getIconByKey(.downBoldOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 16, height: 16)), for: .normal)
            arrowButton.vc.setBackgroundColor(.clear, for: .normal)
            buttonContentView.layer.borderWidth = 0.0
            buttonContentView.layer.shadowOpacity = 0.0
        }
    }

    private lazy var arrowButton: VisualButton = {
        let arrowButton = VisualButton()
        arrowButton.layer.masksToBounds = true
        arrowButton.addTarget(self, action: #selector(didTapArrowButton), for: .touchUpInside)
        return arrowButton
    }()

    private lazy var buttonContentView = UIView()

    lazy var participantView: InMeetingParticipantView = {
        let view = InMeetingParticipantView()
        view.moreSelectionButton.removeFromSuperview()
        view.styleConfig = .speechFloating
        view.styleConfig.userInfoViewStyle = .speechFloatingLarge
        view.styleConfig.systemCallingStatusInfoSyle = Display.phone ? .systemCallingSmallPhone : .systemCallingSmallPad
        return view
    }()

    private lazy var activeSpeakerBorder: InMeetingParticipantActiveSpeakerView = {
        let view = InMeetingParticipantActiveSpeakerView()
        view.fillColor = .ud.bgBase
        view.isHidden = true
        return view
    }()

    lazy var shareContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.layer.cornerRadius = 8.0
        view.layer.masksToBounds = true
        return view
    }()

    var shareDisplayText: String {
        get {
            self.userInfoView.userInfoStatus.name
        }
        set {
            var userInfo = self.userInfoView.userInfoStatus
            userInfo.name = newValue
            self.userInfoView.userInfoStatus = userInfo
        }
    }

    let userInfoView = InMeetUserInfoView()

    var isTalking = false {
        didSet {
            updateActiveSpeakerBorderVisibility()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.vcTokenMeetingBgFloat

        addSubview(speakingView)
        addSubview(activeSpeakerBorder)
        addSubview(participantView)
        addSubview(buttonContentView)
        updateArrowButton(isUp: true)
        buttonContentView.addSubview(arrowButton)

        speakingView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().inset(12)
            make.right.equalTo(arrowButton.snp.left).offset(4)
            make.height.equalTo(40)
        }

        arrowButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        buttonContentView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(5)
            make.right.equalToSuperview().inset(5)
            make.size.equalTo(Layout.arrowButtonSize)
        }

        participantView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        activeSpeakerBorder.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(-2.0)
        }

        setupShareContentView()
    }

    private func setupShareContentView() {
        var params = InMeetUserInfoView.UserInfoDisplayStyle.floatingLarge
        params.components = .nameAndMic
        userInfoView.displayParams = params
        userInfoView.userInfoStatus = ParticipantUserInfoStatus(hasRoleTag: false,
                                                                meetingRole: .participant,
                                                                isSharing: false,
                                                                isFocusing: false,
                                                                isMute: false,
                                                                isLarkGuest: false,
                                                                name: "",
                                                                isRinging: false,
                                                                isMe: false,
//                                                                showNameAndMicOnly: true,
                                                                rtcNetworkStatus: nil,
                                                                audioMode: .unknown,
                                                                is1v1: false,
                                                                meetingSource: nil,
                                                                isRoomConnected: false,
                                                                isLocalRecord: false)
        insertSubview(shareContentView, belowSubview: buttonContentView)
        shareContentView.addSubview(userInfoView)

        shareContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        userInfoView.snp.makeConstraints { make in
            make.bottom.left.equalToSuperview().inset(2)
            make.right.lessThanOrEqualToSuperview().inset(2)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTapArrowButton() {
        self.viewType = self.viewType.nextValue
        self.delegate?.speechFloatingDidShrunk(isShrunken: self.speechViewIsUp.value)
    }

    func setViewType(_ type: SpeechFloatingViewType) {
        self.viewType = type
    }

    private func updateView(with type: SpeechFloatingViewType, forcedHidden: Bool) {
        if speechViewShouldBeUp {
            updateArrowButton(isUp: false)
            speakingView.isHidden = false
            self.hiddenShareContent(true)
            self.hiddenVideoView(true)
        } else {
            updateArrowButton(isUp: true)
            speakingView.isHidden = true
        }
        arrowButton.isHidden = self.forcedHidden
        updateActiveSpeakerBorderVisibility()
    }

    func hiddenShareContent(_ hidden: Bool, isScreen: Bool = false) {
        shareContentView.isHidden = hidden
        if hidden && shareContentView.superview != nil {
            shareContentView.removeFromSuperview()
        } else if !hidden && shareContentView.superview == nil {
            insertSubview(shareContentView, belowSubview: buttonContentView)
            shareContentView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    func hiddenVideoView(_ hidden: Bool) {
        participantView.isHidden = hidden
        participantView.streamRenderView.isCellVisible = !isHidden
        updateActiveSpeakerBorderVisibility()
    }

    func insertShareContent(layer: CALayer) {
        shareContentView.layer.insertSublayer(layer, below: userInfoView.layer)
    }

    func insertShareContent(_ view: UIView, updateSize: Bool = false) {
        shareContentView.insertSubview(view, belowSubview: userInfoView)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setSpeakerUserName(_ name: String) {
        speakingView.speakingTitleLabel.text = I18n.View_VM_SpeakingColonName("")
        speakingView.speakingLabel.text = name
    }

    func setFocusingUserName(_ name: String) {
        speakingView.speakingTitleLabel.text = I18n.View_MV_FocusVideoName_Icon("")
        speakingView.speakingLabel.text = name
    }

    func setForcedHidden(_ isHidden: Bool) {
        self.forcedHidden = isHidden
    }

    func updateActiveSpeakerBorderVisibility() {
        activeSpeakerBorder.isHidden = !isTalking || speechViewShouldBeUp || participantView.isHidden
    }
}

extension InMeetSpeechFloatingView {
    func bind(viewModel: InMeetGridCellViewModel) {
        bag = DisposeBag()
        viewModel.isActiveSpeaker
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isActiveSpeaker in
                self?.isTalking = isActiveSpeaker
            }).disposed(by: bag)

        let cfgs = viewModel.meeting.setting.multiResolutionConfig
        let normalCfg: ByteViewSetting.MultiResSubscribeResolution
        let sipCfg: ByteViewSetting.MultiResSubscribeResolution
        if Display.pad {
            let cfg = cfgs.pad.subscribe
            normalCfg = cfg.gridFloat
            sipCfg = cfg.gridFloatSip
        } else {
            let cfg = cfgs.phone.subscribe
            normalCfg = cfg.gridFloat
            sipCfg = cfg.gridFloatSip
        }
        self.participantView.streamRenderView.multiResSubscribeConfig = MultiResSubscribeConfig(
            normal: normalCfg.toRtc(), priority: .low, sipOrRoom: sipCfg.toRtc())
        self.participantView.bind(viewModel: viewModel, layoutType: "speech_float")
    }
}
