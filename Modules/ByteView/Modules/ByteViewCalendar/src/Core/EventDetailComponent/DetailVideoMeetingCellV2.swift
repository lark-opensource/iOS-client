//
//  DetailVideoMeetingCellV2.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/10.
//

import UniverseDesignIcon
import CalendarFoundation
import RustPB
import RxSwift
import LarkFoundation
import UIKit

public enum DetailVideoMeetingParticipantType {
    /// 未知
    case unknown
    /// 参会人
    case participant
    /// 组织者
    case organizer
    /// 观众
    case attendee
}

protocol DetailVideoMeetingCellContent {
    // 会议是否正在进行中
    var isLiving: Bool { get }
    // 显示标题
    var summary: String { get }
    // 描述（会议链接）
    var linkDesc: String { get }
    // link 是否可以跳转
    var isLinkAvailable: Bool { get }
    // copy 按钮是否显示
    var isCopyAvailable: Bool { get }
    // VC 设置按钮是否显示
    var settingPermission: PermissionOption { get }
    // 视频会议展示类型
    var iconType: Rust.VideoMeetingIconType { get }
    // 视频会议持续时间
    var durationTime: Int { get }
    // 是否webinar
    var isWebinar: Bool { get }
    /// webinar 角色
    var webinarRole: DetailVideoMeetingParticipantType { get }
    /// webinar 会议彩排中
    var isWebinarRehearsal: Bool { get }
    // 已在其他设备加入会议的tip
    var deviceJoinedText: String? { get }
}

protocol DetailVideoMeetingCellPstnNumContent {
    // 拨入电话
    var phoneNumber: String { get }
    // 更多电话
    var isMoreNumberAvailable: Bool { get }
}

final class DetailVideoMeetingCellV2: UIView {
    private let meetingStatusIconView = UIImageView()

    private lazy var defaultIcon = UDIcon.getIconByKeyNoLimitSize(.videoOutlined).renderColor(with: .n3)

    private let verticalStackView = UIStackView()
    private let videoMeetingStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.functionSuccessContentPressed
        label.isUserInteractionEnabled = false
        return label
    }()

    private lazy var meetingPromptView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    private let deviceJoinedLabel = UILabel()

    private let linkLabel = UILabel()

    private let copyButton = UIButton()

    private lazy var videoMeetingCell = initVideoMeetCell()

    private lazy var videoSettingCell = initVideoSettingCell()

    private lazy var phoneNumCell = initPhoneNumCell()

    private lazy var durationTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var durationTimeView = initDurationTimeView()

    private var durationTime: Int = 0
    private var originalTime: Int = -1
    private var disposeBag: DisposeBag?

    private lazy var phoneNumBtn: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.cd.regularFont(ofSize: 14)
        button.contentHorizontalAlignment = .left
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.addTarget(self, action: #selector(didDialInButtonClick), for: .touchUpInside)
        return button
    }()

    private lazy var videoMeetingStatusBGView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 6
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(didVideoMeetingStatusClick))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    private lazy var phoneNumberWrapper: UIView = {
        let wrapper = UIView()
        wrapper.addSubview(phoneNumBtn)
        phoneNumBtn.snp.makeConstraints {
            $0.left.equalToSuperview().offset(48)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(20)
            $0.top.bottom.equalToSuperview()
        }
        return wrapper
    }()

    private lazy var morePhoneView: EventBasicCellLikeView = {
        let morePhoneNumView = EventBasicCellLikeView()
        morePhoneNumView.backgroundColors = (UIColor.clear, UIColor.clear)

        let title = UILabel()
        title.text = I18n.Calendar_Edit_DialIn
        title.textColor = UIColor.ud.textTitle
        title.textAlignment = .left
        title.font = UIFont.cd.regularFont(ofSize: 16)

        let more = UILabel()
        more.text = I18n.View_MV_MoreCountryRegion
        more.font = UIFont.cd.regularFont(ofSize: 14)
        more.textAlignment = .right
        more.textColor = UIColor.ud.textPlaceholder

        let customWrapper = UIView()
        customWrapper.addSubview(title)
        title.snp.makeConstraints {
            $0.top.bottom.left.height.equalToSuperview()
        }
        customWrapper.addSubview(more)
        more.snp.makeConstraints {
            $0.top.bottom.right.height.equalToSuperview()
            $0.left.greaterThanOrEqualTo(title.snp.right)
        }

        morePhoneNumView.content = .customView(customWrapper)
        morePhoneNumView.accessory = .type(.next)
        morePhoneNumView.icon = .empty

        morePhoneNumView.onClick = { [weak self] in
            guard let self = self else { return }
            self.morePhoneNumAction?()
        }

        morePhoneNumView.snp.makeConstraints {
            $0.height.equalTo(24)
        }

        return morePhoneNumView
    }()

    private var content: DetailVideoMeetingCellContent?
    private var pstnNumContent: DetailVideoMeetingCellPstnNumContent?

    // 视频会议按钮被点击
    var videoMeetingAction: (() -> Void)?
    // copy button 被点击
    var linkCopyAction: (() -> Void)?
    // setting item 被点击
    var settingItemAction: (() -> Void)?

    var morePhoneNumAction: (() -> Void)?

    var folderChangeAction: (() -> Void)?

    var dailInAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.spacing = 12
        addSubview(verticalStackView)
        verticalStackView.snp.makeConstraints {
            $0.top.equalTo(10)
            $0.bottom.equalTo(-10)
            $0.left.right.equalToSuperview()
        }
        verticalStackView.addArrangedSubview(videoMeetingCell)
        verticalStackView.addArrangedSubview(phoneNumCell)
        verticalStackView.addArrangedSubview(videoSettingCell)
    }

    func initPhoneNumCell() -> UIView {
        let phoneNumCell = UIStackView()
        phoneNumCell.axis = .vertical
        phoneNumCell.alignment = .fill
        phoneNumCell.spacing = 2

        phoneNumCell.addArrangedSubview(morePhoneView)
        phoneNumCell.addArrangedSubview(phoneNumberWrapper)

        return phoneNumCell
    }

    func initVideoSettingCell() -> EventBasicCellLikeView {
        let settingCell = EventBasicCellLikeView()
        settingCell.backgroundColors = (UIColor.clear, UIColor.clear)
        settingCell.content = .title(.init(text: I18n.Calendar_Edit_JoinSettings,
                                            color: UIColor.ud.textTitle,
                                            font: UIFont.cd.regularFont(ofSize: 16)))
        settingCell.icon = .empty
        settingCell.accessory = .type(.next)

        settingCell.snp.makeConstraints {
            $0.height.equalTo(24)
        }

        settingCell.onClick = { [weak self] in
            guard let self = self else { return }
            self.settingItemAction?()
        }
        return settingCell
    }

    func initVideoMeetCell() -> UIView {
        let videoMeetingCell = UIView()

        videoMeetingCell.addSubview(meetingStatusIconView)
        meetingStatusIconView.image = defaultIcon

        meetingStatusIconView.snp.makeConstraints {
            $0.width.height.left.equalTo(16)
            $0.top.equalTo(10)
        }

        copyButton.setImage(UDIcon.getIconByKeyNoLimitSize(.copyOutlined).scaleInfoSize().renderColor(with: .n2).withRenderingMode(.alwaysOriginal), for: .normal)
        copyButton.increaseClickableArea(top: -16, left: -16, bottom: -16, right: -16)
        copyButton.addTarget(self, action: #selector(didCopyButtonClick), for: .touchUpInside)
        videoMeetingCell.addSubview(copyButton)
        copyButton.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.centerY.equalTo(meetingStatusIconView)
            $0.right.equalToSuperview().offset(-16)
        }

        let topStackView = UIStackView()

        topStackView.axis = .horizontal
        topStackView.alignment = .center

        videoMeetingStatusBGView.addSubview(videoMeetingStatusLabel)
        videoMeetingStatusBGView.sendSubviewToBack(videoMeetingStatusLabel)
        videoMeetingStatusLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        topStackView.addArrangedSubview(videoMeetingStatusBGView)
        topStackView.addArrangedSubview(durationTimeView)

        videoMeetingStatusBGView.snp.makeConstraints {
            $0.height.equalToSuperview()
        }

        durationTimeView.isHidden = true
        videoMeetingCell.addSubview(topStackView)

        topStackView.snp.makeConstraints {
            $0.centerY.equalTo(meetingStatusIconView)
            $0.height.equalTo(36)
            $0.top.equalToSuperview()
            $0.left.equalTo(meetingStatusIconView.snp.right).offset(16)
            $0.right.lessThanOrEqualTo(copyButton.snp.left).offset(-16)
        }

        videoMeetingCell.addSubview(meetingPromptView)
        meetingPromptView.snp.makeConstraints {
            $0.top.equalTo(topStackView.snp.bottom).offset(6)
            $0.left.equalTo(topStackView)
            $0.right.equalTo(copyButton.snp.left).offset(-16)
            $0.bottom.equalToSuperview()
        }

        linkLabel.textColor = UIColor.ud.textPlaceholder
        linkLabel.font = UIFont.systemFont(ofSize: 14)

        deviceJoinedLabel.textColor = UIColor.ud.textPlaceholder
        deviceJoinedLabel.font = UIFont.systemFont(ofSize: 14)

        meetingPromptView.addArrangedSubview(linkLabel)
        meetingPromptView.addArrangedSubview(deviceJoinedLabel)

        deviceJoinedLabel.isHidden = true

        let longCopyGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        addGestureRecognizer(longCopyGesture)

        return videoMeetingCell
    }

    func initDurationTimeView() -> UIView {
        let view = UIView()

        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault

        view.addSubview(lineView)
        lineView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(12)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(16)
            $0.width.equalTo(1)
        }

        view.addSubview(durationTimeLabel)
        durationTimeLabel.snp.makeConstraints {
            $0.left.equalTo(lineView).offset(12)
            $0.right.equalToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
        }

        return view
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        resignFirstResponder()
    }

    override public var canBecomeFirstResponder: Bool {
        return true
    }

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return action == #selector(didCopyButtonClick)
    }

    @objc
    func didDialInButtonClick() {
        dailInAction?()
    }

    @objc
    private func didVideoMeetingStatusClick() {
        videoMeetingAction?()
    }

    @objc
    private func didCopyButtonClick() {
        linkCopyAction?()
        if UIMenuController.shared.isMenuVisible {
            UIMenuController.shared.setMenuVisible(false, animated: true)
        }
    }

    @objc
    private func handleLongPress() {
        guard let content = content, content.isCopyAvailable else { return }
        becomeFirstResponder()
        let menu = UIMenuController.shared
        menu.menuItems = [UIMenuItem(
            title: I18n.Calendar_Common_Copy,
            action: #selector(didCopyButtonClick)
        )]
        if !menu.isMenuVisible {
            var rect = linkLabel.bounds
            rect.origin.y += 6
            menu.setTargetRect(rect, in: linkLabel)
            menu.setMenuVisible(true, animated: false)
        }
    }

    func updateContent(_ content: DetailVideoMeetingCellContent) {
        self.content = content
        if content.isLiving {
            meetingStatusIconView.image = content.iconType.iconGreen
            if content.isWebinar {
                // 对于日程中的组织者/嘉宾，研讨会为「已开始」状态，文案为：加入彩排
                // 对于日程中的观众，研讨会为「未开始」状态，文案依旧为：加入研讨会；（不希望观众感知到彩排）
                let notAttendee = content.webinarRole == .organizer || content.webinarRole == .participant
                var text: String
                if notAttendee {
                    text = content.isWebinarRehearsal ? I18n.View_G_JoinRehearsal_Button : I18n.Calendar_G_JoinWebinar
                } else {
                    text = I18n.Calendar_G_JoinWebinar
                }
                videoMeetingStatusLabel.text = text
            } else {
                videoMeetingStatusLabel.text = I18n.Calendar_VideoMeeting_JoinVideoMeeting
            }
            startTimerIfNeeded(startTime: content.durationTime)

            videoMeetingStatusLabel.textColor = UIColor.ud.functionSuccessContentPressed
            videoMeetingStatusBGView.layer.ud.setBorderColor(UIColor.ud.functionSuccessContentPressed)
        } else {
            meetingStatusIconView.image = content.iconType.iconNormal
            videoMeetingStatusLabel.text = content.summary
            stopTimer()

            if content.isLinkAvailable {
                videoMeetingStatusLabel.textColor = UIColor.ud.primaryContentDefault
                videoMeetingStatusBGView.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
            } else {
                videoMeetingStatusLabel.textColor = UIColor.ud.textTitle
                videoMeetingStatusBGView.layer.ud.setBorderColor(UIColor.ud.textTitle)
            }
        }

        linkLabel.text = content.linkDesc

        if let joinedText = content.deviceJoinedText, !joinedText.isEmpty {
            deviceJoinedLabel.text = joinedText
            deviceJoinedLabel.isHidden = false
        } else {
            deviceJoinedLabel.isHidden = true
        }

        copyButton.isHidden = !content.isCopyAvailable

        switch content.settingPermission {
        case .none:
            videoSettingCell.isHidden = true
        case .readable:
            videoSettingCell.content = .title(.init(text: I18n.Calendar_Edit_JoinSettings,
                                                    color: UIColor.ud.textDisable,
                                                    font: UIFont.cd.regularFont(ofSize: 16)))
            videoSettingCell.isHidden = false
        case .writable:
            videoSettingCell.content = .title(.init(text: I18n.Calendar_Edit_JoinSettings,
                                                    color: UIColor.ud.textTitle,
                                                    font: UIFont.cd.regularFont(ofSize: 16)))
            videoSettingCell.isHidden = false
        default:
            break
        }

        if content.isWebinar {
            videoSettingCell.isHidden = true
        }

        copyButton.snp.remakeConstraints {
            $0.width.height.equalTo(16)
            $0.centerY.equalTo(meetingStatusIconView)
            $0.right.equalToSuperview().offset(-16)
        }

        durationTimeView.isHidden = !content.isLiving
    }

    func updatePstnData(_ content: DetailVideoMeetingCellPstnNumContent) {
        self.pstnNumContent = content
        morePhoneView.isHidden = !content.isMoreNumberAvailable
        phoneNumBtn.setTitle(content.phoneNumber, for: .normal)
        phoneNumberWrapper.isHidden = content.phoneNumber.isEmpty
        phoneNumCell.isHidden = morePhoneView.isHidden && phoneNumberWrapper.isHidden
    }

    private func stopTimer() {
        durationTime = 0
        originalTime = -1
        disposeBag = nil
        durationTimeView.isHidden = true
    }

    private func startTimerIfNeeded(startTime: Int) {
        guard startTime != originalTime else { return }
        originalTime = startTime
        durationTime = originalTime

        durationTimeView.isHidden = false
        durationTimeLabel.text = formatTime(durationTime: durationTime)
        let disposeBag = DisposeBag()
        Observable<Int>.timer(.seconds(1), period: .seconds(1), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .bind { [weak self] (_) in
                guard let self = self else { return }
                self.durationTime += 1
                self.durationTimeLabel.text = self.formatTime(durationTime: self.durationTime)
            }.disposed(by: disposeBag)
        self.disposeBag = disposeBag
    }

    func formatTime(durationTime: Int) -> String {
        let hour = durationTime / 3600
        let minute = (durationTime % 3600) / 60
        let second = durationTime % 60
        return hour > 0 ? String(format: "%02d:%02d:%02d", hour, minute, second) : String(format: "%02d:%02d", minute, second)
    }

}
