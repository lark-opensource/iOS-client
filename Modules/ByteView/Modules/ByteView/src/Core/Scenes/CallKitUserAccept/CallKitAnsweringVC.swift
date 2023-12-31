//
//  CallKitAnsweringVC.swift
//  ByteView
//
//  Created by 刘建龙 on 2019/10/30.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Action
import AVFoundation
import ByteViewCommon
import LarkMedia
import ByteViewUI
import UniverseDesignIcon

private class CommonButton: UIButton {

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        return CGRect(x: 0, y: 27, width: contentRect.size.width, height: 14)
    }

    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let widthHeight: CGFloat = 22.0
        let x = (contentRect.size.width - widthHeight) / 2.0
        return CGRect(x: x, y: 3, width: widthHeight, height: widthHeight)
    }
}

class CallKitAnsweringVC: VMViewController<CallKitAnsweringVM> {
    lazy var avatarImageView = AvatarView()
    lazy var blurImageView = AvatarView(style: .square)
    lazy var micBtn: UIButton = createBtn(icon: .micFilled, text: I18n.View_G_MicAbbreviated)
    lazy var camBtn: UIButton = createBtn(icon: .videoOffFilled, text: I18n.View_VM_Camera)
    lazy var camAlertImgView = UIImageView(image: BundleResources.ByteView.Call.deviceWarningIcon)
    lazy var switchButton: UIButton = createBtn(icon: .speakerFilled, text: I18n.View_VM_Speaker)
    lazy var shareBtn: UIButton = createBtn(icon: .shareScreenFilled, text: I18n.View_M_Share)
    lazy var participantBtn: UIButton = createBtn(icon: .personAddFilled, text: I18n.View_M_Participants)
    lazy var bottomStackView: UIStackView = createBottomStackView()
    lazy var floatingBtn: UIButton = createFloatingBtnButton()
    lazy var hangUpBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(BundleResources.ByteView.Call.CallDecline.vc.resized(to: CGSize(width: 28, height: 28)), for: .normal)
        return btn
    }()
    lazy var connectingLabel: UILabel = createConnectingLabel()
    lazy var bottomView: UIView = createBottomView()


    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.N900
        let visualEffect = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView(effect: visualEffect)

        let maskView = UIView()
        maskView.alpha = 0.8
        maskView.backgroundColor = UIColor.ud.N00
        blurEffectView.contentView.addSubview(maskView)
        maskView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let arrowIcon = UIImageView()
        arrowIcon.image = UDIcon.getIconByKey(.vcToolbarUpFilled, iconColor: .ud.iconDisabled, size: CGSize(width: 24, height: 24))

        camBtn.addSubview(camAlertImgView)
        bottomView.addSubview(bottomStackView)
        bottomView.addSubview(arrowIcon)
        view.addSubview(blurImageView)
        view.addSubview(blurEffectView)
        view.addSubview(avatarImageView)
        view.addSubview(connectingLabel)
        view.addSubview(bottomView)
        view.addSubview(floatingBtn)
        view.addSubview(hangUpBtn)

        camAlertImgView.snp.makeConstraints { (make) in
            make.width.height.equalTo(15)
            make.centerY.equalToSuperview().offset(-3)
            make.centerX.equalToSuperview().offset(9)
        }

        blurImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        avatarImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.size.equalTo(CGSize(width: 92.0, height: 92.0))
        }

        connectingLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(avatarImageView.snp.bottom).offset(20.0)
            make.height.equalTo(20)
        }

        let safeAreaBottomHeight: CGFloat = VCScene.safeAreaInsets.bottom
        bottomView.snp.makeConstraints { make in
            make.centerX.width.equalToSuperview()
            make.height.equalTo(72 + safeAreaBottomHeight)
            make.bottom.equalToSuperview()
        }

        bottomStackView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14.5)
            make.right.equalToSuperview().offset(-14.5)
            make.top.equalToSuperview().offset(28)
            make.height.equalTo(44)
        }
        arrowIcon.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(24)
        }

        micBtn.snp.makeConstraints { (make) in
            make.width.equalTo(66)
            make.height.equalTo(44)
        }
        camBtn.snp.makeConstraints { (make) in
            make.size.equalTo(micBtn)
        }
        switchButton.snp.makeConstraints { (make) in
            make.size.equalTo(micBtn)
        }
        shareBtn.snp.makeConstraints { (make) in
            make.size.equalTo(micBtn)
        }
        participantBtn.snp.makeConstraints { (make) in
            make.size.equalTo(micBtn)
        }

        let insets = VCScene.safeAreaInsets
        floatingBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12.0)
            make.top.equalToSuperview().offset(insets.top + 10.0)
            make.height.width.equalTo(24)
        }

        hangUpBtn.snp.makeConstraints { (make) in
            make.centerY.equalTo(floatingBtn)
            make.right.equalToSuperview().offset(-12)
            make.width.height.equalTo(28)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let path = UIBezierPath(roundedRect: bottomView.bounds,
                                byRoundingCorners: [.topLeft, .topRight],
                                cornerRadii: CGSize(width: 12, height: 12))
        let layer = CAShapeLayer()
        layer.frame = bottomView.bounds
        layer.path = path.cgPath
        bottomView.layer.mask = layer
    }

    override func bindViewModel() {
        self.hangUpBtn.addTarget(viewModel, action: #selector(CallKitAnsweringVM.decline), for: .touchUpInside)

        let handleAvatar: (AvatarInfo) -> Void = { [weak self] info in
            self?.avatarImageView.setAvatarInfo(info)
            self?.blurImageView.setAvatarInfo(info, size: .large)
        }

        viewModel.avatarInfo
            .drive(onNext: handleAvatar)
            .disposed(by: rx.disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .withLatestFrom(viewModel.avatarInfo)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: handleAvatar)
            .disposed(by: rx.disposeBag)

        Privacy.cameraAccess
            .map { $0.isAuthorized }
            .asDriver(onErrorJustReturn: true)
            .drive(camAlertImgView.rx.isHidden)
            .disposed(by: rx.disposeBag)

        self.didChangeAudioOutput(LarkAudioSession.shared.currentOutput)
        LarkAudioSession.rx.audioOutputObservable.subscribe(onNext: { [weak self] in
            self?.didChangeAudioOutput($0)
        }).disposed(by: rx.disposeBag)
    }

    func didChangeAudioOutput(_  output: AudioOutput) {
        Util.runInMainThread { [weak self] in
            guard let `self` = self else { return }
            self.switchButton.setTitle(output.i18nText, for: .normal)
            self.switchButton.setImage(output.image(color: UIColor.ud.iconDisabled), for: .normal)
        }
    }
}

extension CallKitAnsweringVC {
    private func createBtn(icon: UDIconType, text: String?) -> UIButton {
        let btn = CommonButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(icon, iconColor: .ud.iconDisabled, size: CGSize(width: 22, height: 22)), for: .disabled)
        btn.setTitle(text, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        btn.setTitleColor(UIColor.ud.textDisabled, for: .normal)
        btn.titleLabel?.textAlignment = .center
        btn.isEnabled = false
        return btn
    }

    private func createBottomStackView() -> UIStackView {
        let subviews = [micBtn, camBtn, switchButton, shareBtn, participantBtn]
        let bottomStackView = UIStackView(arrangedSubviews: subviews)
        bottomStackView.axis = .horizontal
        bottomStackView.alignment = .center
        bottomStackView.distribution = .equalSpacing
        bottomStackView.spacing = 4
        return bottomStackView
    }

    private func createFloatingBtnButton() -> UIButton {
        let floatingBtn = UIButton(type: .custom)
        floatingBtn.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconDisabled, size: CGSize(width: 24, height: 24)), for: .normal)
        return floatingBtn
    }

    private func createConnectingLabel() -> UILabel {
        let connectingLabel = UILabel()
        connectingLabel.text = I18n.View_G_Connecting
        connectingLabel.font = .systemFont(ofSize: 14.0)
        connectingLabel.textColor = UIColor.ud.textCaption
        return connectingLabel
    }

    private func createBottomView() -> UIView {
        let bottomView = UIView()
        bottomView.backgroundColor = UIColor.ud.N00
        return bottomView
    }
}
