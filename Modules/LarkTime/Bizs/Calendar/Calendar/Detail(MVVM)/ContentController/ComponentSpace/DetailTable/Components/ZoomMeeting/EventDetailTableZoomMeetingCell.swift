//
//  EventDetailTableZoomMeetingCell.swift
//  Calendar
//
//  Created by pluto on 2022-10-20.
//

import UniverseDesignIcon
import CalendarFoundation
import RustPB
import RxSwift
import LarkFoundation
import UIKit

protocol DetailZoomMeetingCellContent {
    // 显示标题
    var summary: String { get }
    // 会议号
    var meetingNo: Int64 { get }
    // 会议密码
    var password: String { get }
    // copy 按钮是否显示
    var isCopyAvailable: Bool { get }
    // 会议设置按钮是否显示
    var settingPermission: PermissionOption { get }
    // 视频会议展示类型
    var iconType: Rust.VideoMeetingIconType { get }
    // 拨入电话
    var phoneNumber: String { get }
}

final class EventDetailTableZoomMeetingCell: UIView {

    private var disposeBag: DisposeBag?

    var videoMeetingAction: (() -> Void)?
    // copy button 被点击
    var linkCopyAction: (() -> Void)?
    var settingItemAction: (() -> Void)?
    var morePhoneNumAction: (() -> Void)?
    var folderChangeAction: (() -> Void)?
    var dailInAction: (() -> Void)?

    private lazy var defaultIcon = UDIcon.getIconByKeyNoLimitSize(.videoOutlined).renderColor(with: .n3)
    private lazy var videoMeetingCell = initVideoMeetingCell()
    private lazy var videoSettingCell = initVideoSettingCell()
    private lazy var phoneNumCell = initPhoneNumCell()

    private let verticalStackView = UIStackView()
    private let meetingStatusIconView = UIImageView()
    private let copyButton = UIButton()

    private let videoMeetingStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.functionSuccessContentPressed
        label.isUserInteractionEnabled = false
        return label
    }()

    private lazy var phoneNumBtn: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.contentHorizontalAlignment = .left
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.addTarget(self, action: #selector(didDialInButtonClick), for: .touchUpInside)
        return button
    }()

    private lazy var videoMeetingStatusBGView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 4
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

    private lazy var zoomMeetingDescView: ZoomAccountInfoView = {
        let view = ZoomAccountInfoView()
        return view
    }()

    private lazy var morePhoneView: EventBasicCellLikeView = {
        let morePhoneNumView = EventBasicCellLikeView()
        morePhoneNumView.backgroundColors = (UIColor.clear, UIColor.ud.fillHover)

        let title = UILabel()
        title.text = BundleI18n.Calendar.Calendar_Edit_DialIn
        title.textColor = UIColor.ud.textTitle
        title.textAlignment = .left
        title.font = UIFont.systemFont(ofSize: 16)

        let more = UILabel()
        more.text = BundleI18n.Calendar.View_MV_MoreCountryRegion
        more.font = UIFont.systemFont(ofSize: 14)
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
        morePhoneNumView.accessory = .type(.next())
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

    private var content: DetailZoomMeetingCellContent?

    override init(frame: CGRect) {
        super.init(frame: frame)
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.spacing = 12
        addSubview(verticalStackView)
        verticalStackView.snp.makeConstraints {
            $0.top.equalTo(16)
            $0.bottom.equalTo(-12)
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
        settingCell.content = .title(.init(text: BundleI18n.Calendar.Calendar_Edit_JoinSettings,
                                            color: UIColor.ud.textTitle,
                                            font: UIFont.cd.regularFont(ofSize: 16)))
        settingCell.icon = .empty
        settingCell.accessory = .type(.next())

        settingCell.snp.makeConstraints {
            $0.height.equalTo(24)
        }

        settingCell.onClick = { [weak self] in
            guard let self = self else { return }
            self.settingItemAction?()
        }
        return settingCell
    }

    func initVideoMeetingCell() -> UIView {
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

        videoMeetingStatusBGView.snp.makeConstraints {
            $0.height.equalToSuperview()
        }

        videoMeetingCell.addSubview(topStackView)

        topStackView.snp.makeConstraints {
            $0.centerY.equalTo(meetingStatusIconView)
            $0.height.equalTo(36)
            $0.top.equalToSuperview()
            $0.left.equalTo(meetingStatusIconView.snp.right).offset(16)
            $0.right.lessThanOrEqualTo(copyButton.snp.left).offset(-16)
        }

        videoMeetingCell.addSubview(zoomMeetingDescView)

        zoomMeetingDescView.snp.makeConstraints {
            $0.top.equalTo(topStackView.snp.bottom).offset(4)
            $0.left.equalTo(topStackView)
            $0.right.equalTo(copyButton.snp.left).offset(-16)
            $0.bottom.equalToSuperview()
        }
        let longCopyGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        addGestureRecognizer(longCopyGesture)

        return videoMeetingCell
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
            title: BundleI18n.Calendar.Calendar_Common_Copy,
            action: #selector(didCopyButtonClick)
        )]
        if !menu.isMenuVisible {
            var rect = zoomMeetingDescView.bounds
            rect.origin.y += 6
            menu.setTargetRect(rect, in: zoomMeetingDescView)
            menu.setMenuVisible(true, animated: false)
        }
    }

    func updateContent(_ content: DetailZoomMeetingCellContent) {
        self.content = content
        meetingStatusIconView.image = content.iconType.iconNormal
        videoMeetingStatusLabel.text = content.summary
        videoMeetingStatusLabel.textColor = UIColor.ud.primaryContentDefault
        videoMeetingStatusBGView.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        zoomMeetingDescView.status = content.password.isEmpty ? .normalOneLine : .normal
        zoomMeetingDescView.configMeetingDescInfo(meetingNo: content.meetingNo, password: content.password, fontSize: 14)
        copyButton.isHidden = false

        switch content.settingPermission {
        case .none:
            videoSettingCell.isHidden = true
        case .readable, .writable:
            videoSettingCell.content = .title(.init(text: BundleI18n.Calendar.Calendar_Edit_JoinSettings,
                                                    color: UIColor.ud.textTitle,
                                                    font: UIFont.cd.regularFont(ofSize: 16)))
            videoSettingCell.isHidden = false
        default:
            break
        }

        if !FG.shouldEnableZoom {
            videoSettingCell.isHidden = true
        }

        morePhoneView.isHidden = content.phoneNumber.isEmpty
        phoneNumBtn.setTitle(content.phoneNumber, for: .normal)
        phoneNumberWrapper.isHidden = content.phoneNumber.isEmpty
        copyButton.snp.remakeConstraints {
            $0.width.height.equalTo(16)
            $0.centerY.equalTo(meetingStatusIconView)
            $0.right.equalToSuperview().offset(-16)
        }
    }
}
