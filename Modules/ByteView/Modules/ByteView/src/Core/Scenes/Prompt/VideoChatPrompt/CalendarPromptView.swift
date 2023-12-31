//
//  CalendarPromptView.swift
//  ByteView
//
//  Created by wangpeiran on 2022/10/18.
//

import UIKit
import ByteViewCommon
import Lottie
import UniverseDesignShadow
import UniverseDesignTheme
import UniverseDesignIcon
import ByteViewMeeting
import ByteViewNetwork
import ByteViewUI

protocol CalendarPromptViewDelegate: AnyObject {
    func didConfirmPrompt(_ prompt: VideoChatPrompt, from: UIView, dependency: MeetingDependency)
    func didCancelPrompt(_ prompt: VideoChatPrompt, from: UIView, dependency: MeetingDependency)
}

class CalendarPromptView: UIView {
    private struct Layout {
        static let commonSpace: CGFloat = 16
        static let buttonHeight: CGFloat = 36
        static let iconSize: CGFloat = 24
        static let tipsIconSize: CGFloat = 16
        static let viewRadius: CGFloat = 12
        static let buttonRadius: CGFloat = 6
        static let baseTopicHeight: CGFloat = 24
    }

    private lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.spacing = Layout.commonSpace
        stackView.axis = .vertical

        stackView.addArrangedSubview(topStackView)
        stackView.addArrangedSubview(topicStackView)
        stackView.addArrangedSubview(buttonStackView)

        topStackView.snp.makeConstraints { (maker) in
            maker.width.equalToSuperview()
        }
        topicStackView.snp.makeConstraints { (maker) in
            maker.width.equalToSuperview()
        }
        buttonStackView.snp.makeConstraints { (maker) in
            maker.width.equalToSuperview()
        }
        return stackView
    }()

    //图片+xxx开始了会议
    private lazy var topStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(inviteStackView)
        iconView.snp.makeConstraints { (maker) in
            maker.size.equalTo(24)
        }
        return stackView
    }()

    private lazy var inviteStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.addArrangedSubview(inviterLabel)
        stackView.addArrangedSubview(invitationLabel)
        return stackView
    }()

    private lazy var inviterLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        label.textColor = UIColor.ud.textCaption
        label.text = nil
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .horizontal)
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 749), for: .horizontal)
        return label
    }()

    private lazy var invitationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: UIFont.Weight.regular)
        label.textColor = UIColor.ud.textCaption
        label.text = I18n.View_M_StartedMeetingNameBraces("")
        label.textAlignment = .natural
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .horizontal)
        label.setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .vertical)
        return label
    }()

    private lazy var iconView: UIView = {
        let icon = UIView()
        icon.backgroundColor = UIColor.ud.functionSuccessFillDefault
        icon.layer.cornerRadius = 12
        icon.layer.masksToBounds = true
        icon.addSubview(meetingOnGoingView)
        meetingOnGoingView.snp.makeConstraints { (maker) in
            maker.size.equalTo(12)
            maker.center.equalToSuperview()
        }
        return icon
    }()

    private lazy var topicStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 4
        stackView.addArrangedSubview(topicLabel)
        stackView.addArrangedSubview(roleLabel)
        return stackView
    }()

    private lazy var topicLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: UIFont.Weight.medium)
        label.textColor = UIColor.ud.textTitle
        label.text = nil
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 2
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    private lazy var roleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        label.isHidden = true
        return label
    }()

    lazy var meetingOnGoingView: LOTAnimationView = {
        var fileSuffix: String = ""
        var onGoing: String = "prompt_"
        if #available(iOS 13.0, *) {
            fileSuffix = UDThemeManager.getRealUserInterfaceStyle() == .dark ? "DM" : "LM"
        }
        let onGoingView = LOTAnimationView(name: onGoing + fileSuffix, bundle: .localResources)
        onGoingView.loopAnimation = true
        return onGoingView
    }()

    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.spacing = Layout.commonSpace
        stackView.addArrangedSubview(cancelButton)
        stackView.addArrangedSubview(confirmButton)
        cancelButton.snp.makeConstraints { (maker) in
            maker.height.equalTo(Layout.buttonHeight)
        }
        confirmButton.snp.makeConstraints { (maker) in
            maker.height.equalTo(Layout.buttonHeight)
        }
        return stackView
    }()

    // 忽略按钮
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isExclusiveTouch = true
        button.setTitle(I18n.View_G_DismissButton, for: .normal)
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.vc.setBackgroundColor(.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.cornerRadius = Layout.buttonRadius
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didClickCancel(_:)), for: .touchUpInside)
        return button
    }()

    // 加入按钮
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.isExclusiveTouch = true
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        button.setTitle(I18n.View_T_JoinMeeting, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillPressed, for: .highlighted)
        button.layer.cornerRadius = Layout.buttonRadius
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(didClickConfirm(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var iconWarningImageView: UIImageView = {
        let image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: Layout.tipsIconSize, height: Layout.tipsIconSize))
        let imageView = UIImageView(image: image)
        return imageView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .left
        return label
    }()

    private lazy var tipsInfo: UIView = { //warningView的内部封装
        let v = UIView()
        v.addSubview(iconWarningImageView)
        v.addSubview(descriptionLabel)
        iconWarningImageView.snp.makeConstraints { (maker) in
            maker.size.equalTo(Layout.tipsIconSize)
            maker.left.equalToSuperview()
            maker.top.equalToSuperview().offset(2)
        }
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.top.bottom.equalToSuperview()
            maker.left.equalTo(iconWarningImageView.snp.right).offset(8)
            maker.right.lessThanOrEqualToSuperview()
        }
        return v
    }()

    private lazy var warningView: UIView = { // 最下面的黄色视图部分
        let v = UIView()
        v.backgroundColor = UIColor.ud.functionWarningFillSolid02
        v.addSubview(tipsInfo)
        tipsInfo.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.bottom.equalToSuperview().inset(12)
            maker.left.greaterThanOrEqualToSuperview().offset(16)
            maker.right.lessThanOrEqualToSuperview().offset(-16)
        }
        return v
    }()

    weak var delegate: CalendarPromptViewDelegate?
    private var prompt: VideoChatPrompt?
    private var cardKey: String
    private let dependency: MeetingDependency
    var httpClient: HttpClient { dependency.httpClient }

    init(frame: CGRect, dependency: MeetingDependency, cardKey: String) {
        self.dependency = dependency
        self.cardKey = cardKey
        super.init(frame: frame)
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func playMeetingOnGoing() {
        meetingOnGoingView.play()
    }

    private func initialize() {
        containerView.addSubview(contentStackView)
        addSubview(containerView)
        addSubview(warningView)

        containerView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
        }
        contentStackView.snp.makeConstraints { (maker) in
            maker.top.left.bottom.right.equalToSuperview().inset(Layout.commonSpace)
        }

        layoutWarningViews()
        MeetingManager.shared.addListener(self)
        MeetingManager.shared.currentSession?.addListener(self)
    }

    private func setTopic(_ topic: String) {
        topicLabel.attributedText = NSAttributedString(string: topic, config: .h3, lineBreakMode: .byTruncatingTail)
    }

    @objc private func didClickConfirm(_ sender: UIButton) {
        if let prompt = self.prompt {
            delegate?.didConfirmPrompt(prompt, from: self, dependency: self.dependency)
        }
    }

    @objc private func didClickCancel(_ sender: UIButton) {
        if let prompt = self.prompt {
            delegate?.didCancelPrompt(prompt, from: self, dependency: self.dependency)
        }
    }

    private func updateMeetingSessionState() {
        var description: String?
        Logger.Prompt.info("updateClientMutexModule")
        let tempStr = descriptionLabel.text
        if let session = MeetingManager.shared.currentSession, session.isActive {
            if session.sessionType == .vc {
                let isShareScreenMeeting = session.setting?.meetingSubType == .screenShare
                description = isShareScreenMeeting ? I18n.View_G_SharingWillEndIfJoinMeeting : I18n.View_M_IfJoinCurrentCallEnds
                description = I18n.View_M_IfJoinCurrentCallEnds // 原有的
                if isShareScreenMeeting {
                    description = I18n.View_G_SharingWillEndIfJoinMeeting
                } else if session.meetType == .call {
                    description = I18n.View_MV_JoinLeaveCallNow
                } else if session.meetType == .meet {
                    description = I18n.View_MV_IfAcceptCurrentMeetingEnds
                }
                self.confirmButton.isEnabled = true
            } else {
                description = I18n.View_M_EncryptedCallCantJoin
                self.confirmButton.isEnabled = false
            }
            self.descriptionLabel.attributedText = NSAttributedString(string: description ?? "", config: .bodyAssist,
                                                                      alignment: .left, lineBreakMode: .byTruncatingTail)
        } else {
            description = ""
            self.descriptionLabel.text = description
            self.confirmButton.isEnabled = true
        }
        layoutWarningViews()
        if tempStr != description {
            PushCardCenter.shared.update(with: self.cardKey)
        }
    }

    func layoutWarningViews() {
        if let description = descriptionLabel.text, !description.isEmpty {
            warningView.isHidden = false
            warningView.snp.remakeConstraints { (maker) in
                maker.top.equalTo(containerView.snp.bottom)
                maker.left.right.equalToSuperview()
                maker.bottom.equalToSuperview()
                maker.height.greaterThanOrEqualTo(44)
            }
        } else {
            warningView.isHidden = true
            warningView.snp.remakeConstraints { (maker) in
                maker.top.equalTo(containerView.snp.bottom)
                maker.left.right.equalToSuperview()
                maker.bottom.equalToSuperview()
                maker.height.equalTo(0)
            }
        }
    }

    func setCalendarStartPrompt(_ prompt: VideoChatPrompt) {
        guard let calendarPrompt = prompt.calendarStartPrompt else { return }
        self.prompt = prompt
        let meetingId = calendarPrompt.meetingID
        self.inviterLabel.text = ""
        httpClient.participantService.participantInfo(pid: calendarPrompt.startUser, meetingId: meetingId) { [weak self] ap in
            if let self = self,
               self.prompt?.calendarStartPrompt?.meetingID == meetingId {
                self.inviterLabel.text = ap.name
            }
        }
        invitationLabel.text = calendarPrompt.subtype == .webinar ? I18n.View_G_NoNameStartedWebinar : I18n.View_M_StartedMeetingNameBraces("")
        setTopic(calendarPrompt.displayedTitle)
        let userId = dependency.account.userId
        let isHost = calendarPrompt.backupHostUids.contains(userId)
        let isInterpreter = calendarPrompt.interpreterUids.contains(userId)
        if isHost, isInterpreter {
            roleLabel.text = I18n.View_G_YouAreHostInterpreter
        } else if isHost {
            roleLabel.text = I18n.View_G_YouAreHost
        } else if isInterpreter {
            roleLabel.text = I18n.View_G_YouAreInterpreter
        } else {
            roleLabel.text = nil
        }
        roleLabel.isHidden = roleLabel.text == nil
        updateMeetingSessionState()
    }
}

extension CalendarPromptView: MeetingManagerListener, MeetingSessionListener {
    func didCreateMeetingSession(_ session: MeetingSession) {
        session.addListener(self)
    }

    func didLeaveMeetingSession(_ session: MeetingSession, event: MeetingEvent) {
    }

    func didLeavePending(session: MeetingSession) {
        Util.runInMainThread { [weak self] in
            if let self = self, self.prompt != nil {
                self.updateMeetingSessionState()
            }
        }
    }

    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        if session.isPending { return }
        Util.runInMainThread { [weak self] in
            if let self = self, self.prompt != nil {
                self.updateMeetingSessionState()
            }
        }
    }
}
