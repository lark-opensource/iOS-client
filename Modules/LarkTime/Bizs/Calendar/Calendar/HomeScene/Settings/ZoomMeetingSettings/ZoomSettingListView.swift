//
//  ZoomSettingListView.swift
//  Calendar
//
//  Created by pluto on 2022/10/28.
//

import UIKit
import Foundation
import UniverseDesignNotice
import UniverseDesignToast

protocol ZoomSettingListViewDataType {
    var zoomSetting: Server.ZoomSetting { get }
}

protocol ZoomSettingListViewDelegate: AnyObject {
    // 会议号
    func didSelectAutoMeetingNo()
    func didSelectSoloMeetingNo()
    // 安全
    func didClickPassCodeCell()
    func didClickWaitingRoom(isOn: Bool)
    func didClickVerifyCell()
    // 视频
    func didClickHostTick(isOn: Bool)
    func didClickParticipantTick(isOn: Bool)
    // 音频
    func didClickPhoneTick()
    func didClickComputerTick()
    func didClickPhoneComputerTick()
    // 高级
    func didClickAllowAnyTimeEnter(isOn: Bool)
    func didClickTimeLimitCell()

    func didClickAllowEnterRoomMute(isOn: Bool)

    func didClickAutoRecord(isOn: Bool)
    func didClickAutoRecordToLocal()
    func didClickAutoRecordInCloud()

    func didClickAlternativeHostCell()
}

final class ZoomSettingListView: UIView, ViewDataConvertible {

    private let stackView = UIStackView()
    private let scrollView = UIScrollView()
    private let defaultSwitchLockedMsg = I18n.Calendar_Zoom_LockedByAdmin
    weak var delegate: ZoomSettingListViewDelegate?
    var lockedMsgToastCallBack: (() -> Void)?

    var viewData: ZoomSettingListViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            let zoomSetting = viewData.zoomSetting
            // 会议号
            autoMeetingNoCell.update(checkBoxIsSelected: zoomSetting.isAutoMeetingNoSelected)
            autoMeetingNoCell.updateSubTitle(text: zoomSetting.autoMeetingNo)
            soloNumberCell.update(checkBoxIsSelected: zoomSetting.isPersonMeetingNoSelected)
            soloNumberCell.updateSubTitle(text: zoomSetting.soloMeetingNo == "0" ? "" : zoomSetting.soloMeetingNo)
            updateSoloMeetingNoticeView(needShow: zoomSetting.isPersonMeetingNoSelected)
            // 安全
            passCodeCell.update(tailingTitle: zoomSetting.isPassCodeOptionOpen ? I18n.Calendar_Zoom_TurnedOn : I18n.Calendar_Zoom_TurnedOff)
            passCodeCell.updateSubTitle(text: zoomSetting.autogenMeetingNoPassword.passwordInfo.embedLink ? I18n.Calendar_Zoom_OnlyWithCodeLinkJoin : I18n.Calendar_Zoom_OnlyWithCodeJoin)
            waitingRoomCell.update(switchIsOn: zoomSetting.waitingRoom.selected)
            waitingRoomCell.isLocked = !zoomSetting.waitingRoom.editable
            onlyWithVerifyCell.update(tailingTitle: zoomSetting.isAuthenticationOptionOpen ? I18n.Calendar_Zoom_TurnedOn : I18n.Calendar_Zoom_TurnedOff)
            // 视频
            hostTickCell.update(switchIsOn: zoomSetting.host.selected)
            hostTickCell.isLocked = !zoomSetting.host.editable

            participantTickCell.update(switchIsOn: zoomSetting.participant.selected)
            participantTickCell.isLocked = !zoomSetting.participant.editable
            // 音频
            audioDailInInfo = zoomSetting.audio.dialInInfo
            audioType = zoomSetting.audio.audioType
            // 高级
            allowAnyTimeEnterCell.update(switchIsOn: zoomSetting.joinBeforeHost.optionButton.selected)
            allowAnyTimeEnterCell.isLocked = !zoomSetting.joinBeforeHost.optionButton.editable
            allowAnyTimeEnterCell.update(titleText: zoomSetting.isAllowAnyTimeJoin ? I18n.Calendar_Zoom_AllowJoinAnyTime : I18n.Calendar_Zoom_AllowJoinAtTime)
            limitTimeCell.isHidden = zoomSetting.isAllowAnyTimeJoin || !(zoomSetting.joinBeforeHost.optionButton.selected)
            if !zoomSetting.isAllowAnyTimeJoin {

                limitTimeCell.update(tailingTitle: zoomSetting.joinBeforeHost.jbhTime == 0 ? I18n.Calendar_Zoom_Anytime : I18n.Calendar_Zoom_NumMinInAdvance(number: "\(zoomSetting.joinBeforeHost.jbhTime)"))
            }

            // 会议室静音
            allowEnterRoomMuteCell.update(switchIsOn: zoomSetting.mute.selected)
            allowEnterRoomMuteCell.isLocked = !zoomSetting.mute.editable
            // 自动录制
            autoRecordCell.update(switchIsOn: zoomSetting.isAutoDisplaySelected)
            autoRecordCell.isLocked = !zoomSetting.autoRecording.autoRecordButton.editable
            autoRecordType = zoomSetting.autoRecording.displayType
            if autoRecordType == .autoRecord {
                updateRecordOptions(isShow: zoomSetting.isAutoDisplaySelected)
            }
            autoRecordInCloudCell.update(checkBoxIsSelected: zoomSetting.isClouldRecordSelected)
            autoRecordToLocalCell.update(checkBoxIsSelected: zoomSetting.isLocalRecordSelected)
            // 备选主持人
            alternativeHostsCell.isHidden = !zoomSetting.paidUser
            alternativeHostsCell.updateSubTitle(text: zoomSetting.alternativeHosts.joined(separator: "、"))
        }
    }

    private var autoRecordType: Server.ZoomSetting.AutoRecording.DisplayType = .autoRecord {
        didSet {
            switch autoRecordType {
            case .autoRecord:
                autoRecordCell.update(titleText: I18n.Calendar_Zoom_AutoRecord)
                autoRecordToLocalCell.isHidden = false
                autoRecordInCloudCell.isHidden = false
            case .cloudRecord:
                autoRecordCell.update(titleText: I18n.Calendar_Zoom_AutoRecordToCloud)
                autoRecordToLocalCell.isHidden = true
                autoRecordInCloudCell.isHidden = true
            case .localRecord:
                autoRecordCell.update(titleText: I18n.Calendar_Zoom_AutoRecordToDevice)
                autoRecordToLocalCell.isHidden = true
                autoRecordInCloudCell.isHidden = true
            @unknown default: break
            }
        }
    }

    private var audioDailInInfo: String = ""
    private var audioType: Server.ZoomSetting.AudioOption.AudioType = .telephone {
        didSet {
            updateAudioOptions(audioType: audioType)
            switch audioType {
            case .telephone:
                phoneTickCell.updateSubTitle(text: audioDailInInfo.isEmpty ? audioDailInInfo : audioDailInInfo + "(\(I18n.Calendar_Zoom_EditGoToSetPage))")
                phoneComputerTickCell.updateSubTitle(text: "")
            case .voip:
                phoneTickCell.updateSubTitle(text: "")
                phoneComputerTickCell.updateSubTitle(text: "")
            case .both:
                phoneComputerTickCell.updateSubTitle(text: audioDailInInfo.isEmpty ? audioDailInInfo : audioDailInInfo + "(\(I18n.Calendar_Zoom_EditGoToSetPage))")
                phoneTickCell.updateSubTitle(text: "")
            @unknown default: break
            }
        }
    }

    // MARK: - View
    // 会议号
    private lazy var meetingNoNoticeView: UDNotice = {
        var infoConfig = UDNoticeUIConfig(type: .info,
                             attributedText: NSAttributedString(string: I18n.Calendar_Zoom_ResetExplain))
        let notice = UDNotice(config: infoConfig)
        notice.isHidden = true
        return notice
    }()

    private lazy var autoMeetingNoCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapAutoMeetingNo), target: self, title: I18n.Calendar_Zoom_AutoGenerateSubTitle, subTitle: "", isSelected: true)
        return view
    }()

    private lazy var soloNumberCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapSoloMeetingNo), target: self, title: I18n.Calendar_Zoom_SoloNumberSubTitle, subTitle: "", isSelected: false)
        return view
    }()

    // 安全
    private lazy var passCodeCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapPassCodeCell),
                               target: self,
                               title: I18n.Calendar_Zoom_CodeRequired,
                               subTitle: I18n.Calendar_Zoom_OnlyWithCodeLinkJoin,
                               tailingTitle: I18n.Calendar_Zoom_TurnedOff)
        return view
    }()

    private lazy var waitingRoomCell: SettingView = {
        let view = SettingView(switchSelector: #selector(tapWaitingRoom), target: self, title: I18n.Calendar_Zoom_EnableWaitRoom, subTitle: I18n.Calendar_Zoom_OnlyWithHostJoin, lockedMsgToastCallBack: lockedMsgToastCallBack)
        return view
    }()

    private lazy var onlyWithVerifyCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapOnlyWithVerifyCell), target: self, title: I18n.Calendar_Zoom_OnlyWithVerifyJoin, tailingTitle: I18n.Calendar_Zoom_TurnedOff)
        return view
    }()

    // 视频
    private lazy var hostTickCell: SettingView = {
        let view = SettingView(switchSelector: #selector(tapHostTick), target: self, title: I18n.Calendar_Zoom_HostVideoOn, lockedMsgToastCallBack: lockedMsgToastCallBack)
        return view
    }()

    private lazy var participantTickCell: SettingView = {
        let view = SettingView(switchSelector: #selector(tapParticipantTick), target: self, title: I18n.Calendar_Zoom_ParticipantVideoOn, lockedMsgToastCallBack: lockedMsgToastCallBack)
        return view
    }()

    // 音频
    private lazy var phoneTickCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapPhoneTick), target: self, title: I18n.Calendar_Zoom_PhoneOnly, subTitle: "", enableNoLimitMultiLine: true, isSelected: true)
        return view
    }()

    private lazy var computerTickCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapComputerTick), target: self, title: I18n.Calendar_Zoom_AudioDeviceOnly, subTitle: "", isSelected: false)
        return view
    }()

    private lazy var phoneComputerTickCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapPhoneComputerTick), target: self, title: I18n.Calendar_Zoom_PhoneAudioDevice, subTitle: "", enableNoLimitMultiLine: true, isSelected: false)
        return view
    }()

    // 高级
    private lazy var allowAnyTimeEnterCell: SettingView = {
        let view = SettingView(switchSelector: #selector(tapAllowAnyTimeEnter), target: self, title: I18n.Calendar_Zoom_AllowJoinAnyTime, lockedMsgToastCallBack: lockedMsgToastCallBack)
        return view
    }()

    private lazy var limitTimeCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapLimitTime), target: self, title: I18n.Calendar_Zoom_SpecifiedTime, tailingTitle: I18n.Calendar_Zoom_NumMinInAdvance(number: ""))
        return view
    }()

    private lazy var allowEnterRoomMuteCell: SettingView = {
        let view = SettingView(switchSelector: #selector(tapAllowEnterRoomMute), target: self, title: I18n.Calendar_Zoom_MuteOnEntry, lockedMsgToastCallBack: lockedMsgToastCallBack)
        return view
    }()

    private lazy var autoRecordCell: SettingView = {
        let view = SettingView(switchSelector: #selector(tapAutoRecord), target: self, title: I18n.Calendar_Zoom_AutoRecord, lockedMsgToastCallBack: lockedMsgToastCallBack)
        return view
    }()

    private lazy var autoRecordToLocalCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapAutoRecordToLocal), target: self, title: I18n.Calendar_Zoom_ToLocalDevice, isSelected: true)
        return view
    }()

    private lazy var autoRecordInCloudCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapAutoRecordInCloud), target: self, title: I18n.Calendar_Zoom_InCloud, isSelected: false)
        return view
    }()

    private lazy var alternativeHostsCell: SettingView = {
        let view = SettingView(cellSelector: #selector(tapAlternativeHosts), target: self, title: I18n.Calendar_Zoom_AlternativeHosts, subTitle: "")
        return view
    }()

    private lazy var meetingNoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var securityStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var videoStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var audioStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var autoRecordStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var enterMeetingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var securityNoticeView: ZoomCommonErrorTipsView = {
        let view = ZoomCommonErrorTipsView()
        view.backgroundColor = .clear
        view.configSingleError(title: I18n.Calendar_Zoom_ChooseOneSafe)
        view.errorType = .single
        view.isHidden = true
        return view
    }()

    private lazy var hostErrorNoticeView: ZoomCommonErrorTipsView = {
        let view = ZoomCommonErrorTipsView()
        view.backgroundColor = .clear
        view.isHidden = true
        view.errorType = .single
        return view
    }()

    init() {
        super.init(frame: UIScreen.main.bounds)
        configLockCallback()
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        addSubview(meetingNoNoticeView)
        meetingNoNoticeView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        stackView.axis = .vertical
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(14)
            make.bottom.lessThanOrEqualToSuperview()
        }
        // 会议号
        addSectionHeader(with: I18n.Calendar_Zoom_MeetIDMobile)

        let accountManagerStackBG = UIView()
        accountManagerStackBG.addSubview(meetingNoStack)
        meetingNoStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.addArrangedSubview(accountManagerStackBG)
        meetingNoStack.addArrangedSubview(autoMeetingNoCell)
        meetingNoStack.addArrangedSubview(soloNumberCell)

        // 安全
        addDivideLine()
        addSectionHeader(with: I18n.Calendar_Zoom_SecurityMobile)
        let securityStackBG = UIView()
        securityStackBG.addSubview(securityStack)
        securityStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(securityStackBG)
        securityStack.addArrangedSubview(passCodeCell)
        securityStack.addArrangedSubview(waitingRoomCell)
        securityStack.addArrangedSubview(onlyWithVerifyCell)

        // 安全提示
        stackView.addArrangedSubview(securityNoticeView)
        securityNoticeView.snp.makeConstraints { make in
            make.height.equalTo(20)
        }

        // 视频
        addDivideLine()
        addSectionHeader(with: I18n.Calendar_Zoom_VideoMobile)
        let videoStackBG = UIView()
        videoStackBG.addSubview(videoStack)
        videoStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(videoStackBG)
        videoStack.addArrangedSubview(hostTickCell)
        videoStack.addArrangedSubview(participantTickCell)

        // 音频
        addDivideLine()
        addSectionHeader(with: I18n.Calendar_Zoom_AudioMobile)
        let audioStackBG = UIView()
        audioStackBG.addSubview(audioStack)
        audioStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(audioStackBG)
        audioStack.addArrangedSubview(phoneTickCell)
        audioStack.addArrangedSubview(computerTickCell)
        audioStack.addArrangedSubview(phoneComputerTickCell)

        // --
        addDivideLine()
        let enterMeetingStackBG = UIView()
        enterMeetingStackBG.addSubview(enterMeetingStack)
        enterMeetingStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(enterMeetingStackBG)
        enterMeetingStack.addArrangedSubview(allowAnyTimeEnterCell)
        enterMeetingStack.addArrangedSubview(limitTimeCell)

        stackView.addArrangedSubview(allowEnterRoomMuteCell)

        let autoRecordStackBG = UIView()
        autoRecordStackBG.addSubview(autoRecordStack)
        autoRecordStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(autoRecordStackBG)
        autoRecordStack.addArrangedSubview(autoRecordCell)
        autoRecordStack.addArrangedSubview(autoRecordToLocalCell)
        autoRecordStack.addArrangedSubview(autoRecordInCloudCell)

        stackView.addArrangedSubview(alternativeHostsCell)

        // 备选主持人提示
        stackView.addArrangedSubview(hostErrorNoticeView)
        hostErrorNoticeView.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
    }

    private func addSectionHeader(with title: String) {
        let seprator = UIView()
        seprator.snp.makeConstraints { (make) in
            make.height.equalTo(20)
        }
        stackView.addArrangedSubview(seprator)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        seprator.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
    }

    private func addDivideLine() {
        let divideView = EventBasicDivideView()
        self.stackView.addArrangedSubview(divideView)
    }

    // MARK: - Page Tips Action
    func updateErrorNoticeTips(errorState: Server.UpdateZoomSettingsResponse.State, passTips: [String], hostTip: String) {
        resetErrorStatus()
        switch errorState {
        case .passwordIllegal:
            passCodeCell.update(errorTitles: passTips)
        case .alternativeHostsIllegal:
            hostErrorNoticeView.configSingleError(title: hostTip)
            hostErrorNoticeView.isHidden = false
        @unknown default: break
        }
    }

    func hideErrorTips(type: Server.UpdateZoomSettingsResponse.State) {
        switch type {
        case .passwordIllegal:
            passCodeCell.update(errorTitles: [])
        case .alternativeHostsIllegal:
            hostErrorNoticeView.isHidden = true
        @unknown default: break
        }
    }

    func updateSecurityNoticeTips(needShow: Bool) {
        securityNoticeView.isHidden = !needShow
    }

    private func resetErrorStatus() {
        passCodeCell.update(errorTitles: [])
        hostErrorNoticeView.isHidden = true
    }

    private func updateSoloMeetingNoticeView(needShow: Bool) {
        meetingNoNoticeView.isHidden = !needShow
        scrollView.snp.remakeConstraints { (make) in
            if needShow {
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(meetingNoNoticeView.snp.bottom)
            } else {
                make.edges.equalToSuperview()
            }
        }
    }

    private func updateRecordOptions(isShow: Bool) {
        autoRecordToLocalCell.isHidden = !isShow
        autoRecordInCloudCell.isHidden = !isShow
    }

    private func updateAudioOptions(audioType: Server.ZoomSetting.AudioOption.AudioType) {
        phoneTickCell.update(checkBoxIsSelected: audioType == .telephone)
        computerTickCell.update(checkBoxIsSelected: audioType == .voip)
        phoneComputerTickCell.update(checkBoxIsSelected: audioType == .both)
    }

    private func configLockCallback() {
        lockedMsgToastCallBack = { [weak self]  in
            guard let self = self else { return }
            UDToast.showTips(with: self.defaultSwitchLockedMsg, on: self)
        }
    }

    // MARK: - Cell Tap Actions
    @objc
    private func tapAutoMeetingNo() {
        self.delegate?.didSelectAutoMeetingNo()
    }

    @objc
    private func tapSoloMeetingNo() {
        self.delegate?.didSelectSoloMeetingNo()
    }

    @objc
    private func tapPassCodeCell() {
        self.delegate?.didClickPassCodeCell()
    }

    @objc
    private func tapWaitingRoom(sender: UISwitch) {
        self.delegate?.didClickWaitingRoom(isOn: sender.isOn)
    }

    @objc
    private func tapOnlyWithVerifyCell() {
        self.delegate?.didClickVerifyCell()
    }

    @objc
    private func tapHostTick(sender: UISwitch) {
        self.delegate?.didClickHostTick(isOn: sender.isOn)
    }

    @objc
    private func tapParticipantTick(sender: UISwitch) {
        self.delegate?.didClickParticipantTick(isOn: sender.isOn)
    }

    @objc
    private func tapPhoneTick() {
        self.delegate?.didClickPhoneTick()
    }

    @objc
    private func tapComputerTick() {
        self.delegate?.didClickComputerTick()
    }

    @objc
    private func tapPhoneComputerTick() {
        self.delegate?.didClickPhoneComputerTick()
    }

    @objc
    private func tapAllowAnyTimeEnter(sender: UISwitch) {
        self.delegate?.didClickAllowAnyTimeEnter(isOn: sender.isOn)
    }

    @objc
    private func tapLimitTime() {
        self.delegate?.didClickTimeLimitCell()
    }

    @objc
    private func tapAllowEnterRoomMute(sender: UISwitch) {
        self.delegate?.didClickAllowEnterRoomMute(isOn: sender.isOn)
    }

    @objc
    private func tapAutoRecord(sender: UISwitch) {
        self.delegate?.didClickAutoRecord(isOn: sender.isOn)
    }

    @objc
    private func tapAutoRecordToLocal() {
        self.delegate?.didClickAutoRecordToLocal()
    }

    @objc
    private func tapAutoRecordInCloud() {
        self.delegate?.didClickAutoRecordInCloud()
    }

    @objc
    private func tapAlternativeHosts() {
        self.delegate?.didClickAlternativeHostCell()
    }
}
