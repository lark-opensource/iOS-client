//
//  DetailOtherMeetingView.swift
//  Calendar
//
//  Created by tuwenbo on 2022/11/21.
//

import UniverseDesignIcon
import CalendarFoundation
import RustPB
import RxSwift
import LarkFoundation
import UIKit

protocol DetailOtherMeetingCellContent {
    // 显示标题
    var summary: String { get }
    // 描述（会议链接）
    var linkDesc: String { get }
    // link 是否可以跳转
    var isLinkAvailable: Bool { get }
    // copy 按钮是否显示
    var isCopyAvailable: Bool { get }
    // 视频会议展示类型
    var iconType: Rust.VideoMeetingIconType { get }
    // 拨入电话
    var phoneNumber: String { get }
    // 更多电话
    var isMoreNumberAvailable: Bool { get }
    // 会议信息是否是合理的，用于控制隐藏view
    var isMeetingInvalid: Bool { get }
}

final class DetailOtherMeetingView: UIView {
    private let meetingStatusIconView = UIImageView()

    private lazy var defaultIcon = UDIcon.getIconByKeyNoLimitSize(.videoOutlined).renderColor(with: .n3)

    private let verticalStackView = UIStackView()
    private let videoMeetingStatusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2(.fixed)
        label.textColor = UIColor.ud.functionSuccessContentPressed
        label.isUserInteractionEnabled = false
        return label
    }()

    private lazy var linkLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.ud.body2(.fixed)
        return label
    }()

    private lazy var linkLabelCell: UIView = {
        let uiview = UIView()
        uiview.addSubview(linkLabel)
        linkLabel.snp.makeConstraints { make in
            make.height.equalTo(22)
            make.left.equalToSuperview().inset(48)
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview()
        }
        let longCopyGesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(handleLongPress)
        )
        addGestureRecognizer(longCopyGesture)
        return uiview
    }()

    private let copyButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.copyOutlined).scaleInfoSize().renderColor(with: .n2).withRenderingMode(.alwaysOriginal), for: .normal)
        button.increaseClickableArea(top: -16, left: -16, bottom: -16, right: -16)
        button.addTarget(self, action: #selector(didCopyButtonClick), for: .touchUpInside)
        return button
    }()

    private lazy var videoMeetingCell = initVideoMeetingCell()

    private lazy var phoneNumCell = initPhoneNumCell()

    private var disposeBag: DisposeBag?

    private lazy var phoneNumBtn: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.ud.body2(.fixed)
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
            $0.height.equalTo(22)
            $0.top.bottom.equalToSuperview()
        }
        return wrapper
    }()

    private lazy var morePhoneView: EventBasicCellLikeView = {
        let morePhoneNumView = EventBasicCellLikeView()
        morePhoneNumView.backgroundColors = (UIColor.clear, UIColor.ud.fillHover)

        let title = UILabel()
        title.text = BundleI18n.Calendar.Calendar_Edit_DialIn
        title.textColor = UIColor.ud.textTitle
        title.textAlignment = .left
        title.font = UIFont.ud.body0(.fixed)

        let more = UILabel()
        more.text = BundleI18n.Calendar.View_MV_MoreCountryRegion
        more.font = UIFont.ud.body2(.fixed)
        more.textAlignment = .right
        more.textColor = UIColor.ud.textPlaceholder

        let customWrapper = UIView()
        customWrapper.addSubview(title)
        title.snp.makeConstraints {
            $0.top.bottom.left.height.equalToSuperview()
            $0.height.equalTo(22)
        }
        customWrapper.addSubview(more)
        more.snp.makeConstraints {
            $0.top.bottom.right.height.equalToSuperview()
            $0.left.greaterThanOrEqualTo(title.snp.right)
            $0.centerY.equalTo(title)
        }

        morePhoneNumView.content = .customView(customWrapper)
        morePhoneNumView.accessory = .type(.next())
        morePhoneNumView.icon = .empty

        morePhoneNumView.onClick = { [weak self] in
            guard let self = self else { return }
            self.morePhoneNumAction?()
        }

        return morePhoneNumView
    }()

    private var content: DetailOtherMeetingCellContent?

    // 视频会议按钮被点击
    var videoMeetingAction: (() -> Void)?
    // copy button 被点击
    var linkCopyAction: (() -> Void)?

    var morePhoneNumAction: (() -> Void)?

    var dailInAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .fill
        verticalStackView.spacing = 4
        addSubview(verticalStackView)
        verticalStackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.bottom.equalToSuperview().inset(12)
            $0.left.right.equalToSuperview()
        }
        verticalStackView.setCustomSpacing(12, after: linkLabelCell)
        verticalStackView.addArrangedSubview(videoMeetingCell)
        verticalStackView.addArrangedSubview(linkLabelCell)
        verticalStackView.addArrangedSubview(phoneNumCell)

        videoMeetingCell.snp.makeConstraints {
            $0.height.equalTo(36)
        }
        linkLabelCell.snp.makeConstraints {
            $0.height.equalTo(22)
        }
        phoneNumCell.snp.makeConstraints {
            $0.height.equalTo(46)
        }
    }

    func initPhoneNumCell() -> UIView {
        let phoneNumCell = UIStackView()
        phoneNumCell.axis = .vertical
        phoneNumCell.alignment = .fill
        phoneNumCell.spacing = 2

        phoneNumCell.backgroundColor = UIColor.ud.bgBody

        phoneNumCell.addArrangedSubview(morePhoneView)
        phoneNumCell.addArrangedSubview(phoneNumberWrapper)

        return phoneNumCell
    }

    func initVideoMeetingCell() -> UIView {
        let videoMeetingCell = UIView()

        meetingStatusIconView.image = defaultIcon
        videoMeetingCell.addSubview(meetingStatusIconView)
        meetingStatusIconView.snp.makeConstraints {
            $0.left.equalToSuperview().inset(16)
            $0.width.height.equalTo(16)
            $0.top.equalToSuperview().inset(10)
        }

        videoMeetingCell.addSubview(copyButton)
        copyButton.snp.makeConstraints {
            $0.width.height.equalTo(16)
            $0.centerY.equalTo(meetingStatusIconView)
            $0.right.equalToSuperview().offset(-16)
        }

        videoMeetingStatusBGView.addSubview(videoMeetingStatusLabel)
        videoMeetingStatusBGView.sendSubviewToBack(videoMeetingStatusLabel)
        videoMeetingStatusLabel.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        videoMeetingCell.addSubview(videoMeetingStatusBGView)
        videoMeetingStatusBGView.snp.makeConstraints {
            $0.centerY.equalTo(meetingStatusIconView)
            $0.height.equalTo(36)
            $0.top.equalToSuperview()
            $0.left.equalTo(meetingStatusIconView.snp.right).offset(16)
            $0.right.lessThanOrEqualTo(copyButton.snp.left).offset(-16)
        }

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
            var rect = linkLabel.bounds
            rect.origin.y += 6
            menu.setTargetRect(rect, in: linkLabel)
            menu.setMenuVisible(true, animated: false)
        }
    }

    func updateContent(_ content: DetailOtherMeetingCellContent) {
        self.content = content
        meetingStatusIconView.image = content.iconType.iconNormal
        videoMeetingStatusLabel.text = content.summary

        if content.isLinkAvailable {
            videoMeetingStatusLabel.textColor = UIColor.ud.primaryContentDefault
            videoMeetingStatusBGView.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        } else {
            videoMeetingStatusLabel.textColor = UIColor.ud.textTitle
            videoMeetingStatusBGView.layer.ud.setBorderColor(UIColor.ud.textTitle)
        }

        linkLabel.text = content.linkDesc
        linkLabelCell.isHidden = content.linkDesc.isEmpty

        copyButton.isHidden = !content.isCopyAvailable

        phoneNumBtn.setTitle(content.phoneNumber, for: .normal)
        morePhoneView.isHidden = !content.isMoreNumberAvailable
        phoneNumberWrapper.isHidden = content.phoneNumber.isEmpty

        phoneNumCell.isHidden = morePhoneView.isHidden && phoneNumberWrapper.isHidden
    }

}
