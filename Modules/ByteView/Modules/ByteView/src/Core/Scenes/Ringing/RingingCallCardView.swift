//
//  RingingCallCardView.swift
//  ByteView
//
//  Created by wangpeiran on 2022/9/16.
//

import Foundation
import ByteViewCommon
import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift
import ByteViewMeeting
import ByteViewUI

private struct Layout {
    static let bannerCommonLongMargin: CGFloat = 16.0
    static let bannerCommonShortMargin: CGFloat = 8.0
    static let bannerButtonSize: CGFloat = 44.0
    static let buttonImageBannerSize: CGSize = CGSize(width: 22, height: 22)
}

enum CallInViewStyle {
    case banner       // 通知横幅
    case fullScreen   // 全屏
}

class RingingCallCardView: UIView {
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

    let avatarImageView = AvatarView()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .left
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    lazy var declineButton: UIButton = {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.functionDangerFillDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerFillPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.functionDangerFillDefault, for: .disabled)
        let image = UDIcon.getIconByKey(.callEndFilled, iconColor: .ud.primaryOnPrimaryFill, size: Layout.buttonImageBannerSize)
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        button.setImage(image, for: .disabled)
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(decline), for: .touchUpInside)
        return button
    }()

    lazy var acceptButton: UIButton = {
        let button = UIButton()
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.functionSuccessFillLoading, for: .disabled)
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(accept), for: .touchUpInside)
        return button
    }()

    private lazy var loadingView: LoadingView = {
        let view = LoadingView(style: .white)
        view.isHidden = true
        return view
    }()

    private lazy var warningView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.O100

        let containerView = UIView()
        containerView.addSubview(warningIcon)
        containerView.addSubview(attentionLabel)
        view.addSubview(containerView)

        warningIcon.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(14)
            maker.size.equalTo(16)
            maker.left.greaterThanOrEqualToSuperview()
        }
        attentionLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(warningIcon.snp.right).offset(8)
            maker.right.lessThanOrEqualToSuperview()
            maker.top.equalToSuperview().offset(12)
            maker.bottom.equalToSuperview().offset(-12)
        }
        containerView.snp.makeConstraints { (maker) in
            maker.left.greaterThanOrEqualToSuperview().offset(16)
            maker.right.lessThanOrEqualToSuperview().offset(-16)
            maker.centerX.top.bottom.equalToSuperview()
        }
        return view
    }()

    private lazy var attentionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 2
        var title = I18n.View_G_IfAcceptCurrentCallEnds // 原有的
        if let setting = MeetingManager.shared.currentSession?.setting {
            if setting.meetingSubType == .screenShare {
                title = I18n.View_MV_IfAcceptEndScreenShare
            } else if setting.meetingType == .call {
                title = I18n.View_MV_IfAcceptCurrentCallEnds
            } else if setting.meetingType == .meet {
                title = I18n.View_MV_NewCallLeaveMeetingNow
            }
        }
        label.attributedText = NSAttributedString(string: title, config: .bodyAssist)
        return label
    }()

    private lazy var warningIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.warningColorful, size: CGSize(width: 16, height: 16))
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    var pressBlock: (() -> Void)?
    let viewModel: CallInViewModel

    var isPhoneCall: Bool { viewModel.callInType.isPhoneCall && Display.phone }

    private var acceptButtonImage: UIImage?

    init(viewModel: CallInViewModel) {
        self.viewModel = viewModel

        super.init(frame: .zero)
        setupSubviews()
        bindViewModel()

        Logger.ring.info("RingingCallCardView init")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Logger.ring.info("RingingCallCardView deinit")
    }

    private func setupSubviews() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(acceptButton)
        contentView.addSubview(declineButton)

        acceptButton.addSubview(loadingView)

        addSubview(contentView)
        addSubview(warningView)

        self.layer.cornerRadius = 16
        self.clipsToBounds = true
        self.layer.masksToBounds = true

        avatarImageView.isHidden = Display.phone && viewModel.callInType == .ipPhone("")
        warningView.isHidden = !viewModel.isBusyRinging

        let icon: UDIconType = viewModel.isVoiceCall ? .callFilled : .videoFilled
        let image = UDIcon.getIconByKey(icon, iconColor: .ud.primaryOnPrimaryFill, size: Layout.buttonImageBannerSize)
        acceptButton.setImage(image, for: .normal)
        acceptButton.setImage(image, for: .highlighted)
        acceptButton.setImage(UIImage(), for: .disabled)

        nameLabel.font = .systemFont(ofSize: 17)
        nameLabel.textAlignment = .left

        if isPhoneCall {
            declineButton.layer.cornerRadius = 22
            acceptButton.layer.cornerRadius = 22
        } else {
            declineButton.layer.ux.setSmoothCorner(radius: 12, corners: .allCorners, smoothness: .max)
            acceptButton.layer.ux.setSmoothCorner(radius: 12, corners: .allCorners, smoothness: .max)
        }
        layoutViewsBanner()
    }

    private func bindViewModel() {
        bindAvatar()
        bindName()
        bindDescription()
        bindAcceptEnabled()
    }

    // MARK: - UI elements update
    func updateAvatar(avatarInfo: AvatarInfo) {
        avatarImageView.setAvatarInfo(avatarInfo)
    }

    func updateName(name: String) {
        nameLabel.vc.justReplaceText(to: name)
    }

    func updateAcceptEnabled(enabled: Bool) {
        acceptButton.isEnabled = enabled  //在点击接听后，为防止重复点击，acceptButton会被置为disable状态
        showLoading(!enabled)
    }

    func updateDescription(description: String) {
        descriptionLabel.text = description
    }

    private func bindAvatar() {
        let handleAvatar: (AvatarInfo) -> Void = { [weak self] avatarInfo in
            guard let self = self else { return }
            self.updateAvatar(avatarInfo: avatarInfo)
        }
        viewModel.avatarInfo.drive(onNext: handleAvatar).disposed(by: rx.disposeBag)
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .withLatestFrom(viewModel.avatarInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: handleAvatar)
            .disposed(by: rx.disposeBag)
    }

    private func bindName() {
        viewModel.name.drive(onNext: { [weak self] name in
            guard let self = self else { return }
            self.updateName(name: name)
        }).disposed(by: rx.disposeBag)
    }

    private func bindDescription() {
        viewModel.callInDescription.drive(onNext: { [weak self] description in
            guard let self = self else { return }
            self.updateDescription(description: description)
        }).disposed(by: rx.disposeBag)
    }

    private func bindAcceptEnabled() {
        viewModel.isButtonEnabled
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (enable) in
                guard let self = self else { return }
                self.updateAcceptEnabled(enabled: enable)
            }).disposed(by: rx.disposeBag)
    }

    @objc func decline() {
        viewModel.decline()
    }

    @objc func accept() {
        viewModel.accept()
        if #unavailable(iOS 16.0) {
            UIDevice.updateDeviceOrientationForViewScene(self, to: .portrait, animated: true)
        }
    }

    private func showLoading(_ loading: Bool) {
        if loading {
            loadingView.play()
            loadingView.isHidden = false
        } else {
            loadingView.stop()
            loadingView.isHidden = true
        }
    }

    // disable-lint: duplicated code
    private func layoutViewsBanner() {
        if isPhoneCall {
            if viewModel.callInType == .ipPhoneBindLark {
                avatarImageView.snp.remakeConstraints { (make) in
                    make.left.equalToSuperview().offset(Layout.bannerCommonLongMargin)
                    make.centerY.equalToSuperview()
                    make.size.equalTo(44.0)
                }
                nameLabel.snp.remakeConstraints { (make) in
                    make.left.equalTo(avatarImageView.snp.right).offset(Layout.bannerCommonShortMargin)
                    make.right.equalTo(declineButton.snp.left).offset(-Layout.bannerCommonShortMargin)
                    make.height.equalTo(24)
                    make.top.equalToSuperview().offset(18)
                }
            } else {
                nameLabel.snp.remakeConstraints { (make) in
                    make.left.equalToSuperview().offset(Layout.bannerCommonLongMargin)
                    make.right.equalTo(declineButton.snp.left).offset(-Layout.bannerCommonShortMargin)
                    make.height.equalTo(24)
                    make.top.equalToSuperview().offset(18)
                }
            }
        } else {
            avatarImageView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(Layout.bannerCommonLongMargin)
                make.centerY.equalToSuperview()
                make.size.equalTo(44.0)
            }
            nameLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarImageView.snp.right).offset(Layout.bannerCommonShortMargin)
                make.right.equalTo(declineButton.snp.left).offset(-Layout.bannerCommonShortMargin)
                make.height.equalTo(24)
                make.top.equalToSuperview().offset(18)
            }
        }

        contentView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(80)
        }

        descriptionLabel.snp.remakeConstraints { (make) in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.height.equalTo(18)
        }

        acceptButton.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(Layout.bannerButtonSize)
            make.right.equalToSuperview().offset(-Layout.bannerCommonLongMargin)
        }

        loadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(22)
        }

        declineButton.snp.remakeConstraints { (make) in
            make.size.equalTo(Layout.bannerButtonSize)
            make.centerY.equalTo(acceptButton)
            make.right.equalTo(acceptButton.snp.left).offset(-Layout.bannerCommonLongMargin)
        }

        warningView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(contentView.snp.bottom)
            if viewModel.isBusyRinging {
                make.height.greaterThanOrEqualTo(44)
            } else {
                make.height.equalTo(0)
            }
        }
    }
    // enable-lint: duplicated code
}
