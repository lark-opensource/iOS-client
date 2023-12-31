//
//  SwitchAnimatedView.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/15.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkLocalizations
import UniverseDesignColor
import UniverseDesignStyle

final class SwitchAnimatedView: UIControl, CardBindable, CAAnimationDelegate {
    static let switchAnimationDuration = 0.4

    private var qrCodeCard: QRCodeCard?
    private var inviteLinkCard: InviteLinkCard?
    private let scenes: UnifiedNoDirectionalScenes
    private let leftClickHandler: (CardSwitchState) -> Void
    private let rightClickHandler: (CardSwitchState) -> Void
    private let disposeBag = DisposeBag()

    var shareSourceView: UIView {
        return rightOpButton
    }

    var switchState: CardSwitchState {
        willSet {
            if let qrcodeCard = qrCodeCard {
                qrcodeCard.isHidden = newValue != .qrCode
            }
            if let linkCard = inviteLinkCard {
                linkCard.isHidden = newValue == .qrCode
            }
        }
    }

    init(qrCodeCard: QRCodeCard?,
         inviteLinkCard: InviteLinkCard?,
         scenes: UnifiedNoDirectionalScenes,
         switchState: CardSwitchState,
         switchHandler: @escaping (CardSwitchState) -> Void,
         leftClickHandler: @escaping (CardSwitchState) -> Void,
         rightClickHandler: @escaping (CardSwitchState) -> Void) {
        self.qrCodeCard = qrCodeCard
        self.inviteLinkCard = inviteLinkCard
        self.scenes = scenes
        self.switchState = switchState
        self.leftClickHandler = leftClickHandler
        self.rightClickHandler = rightClickHandler

        super.init(frame: .zero)

        layoutPageSubviews()

        /// 3d rotate animation
        let switchCardHandler = { [weak self] in
            guard let `self` = self else { return }
            let duration = SwitchAnimatedView.switchAnimationDuration
            let animationProxy = WeakLayerAnimationDelegateProxy(delegate: self)
            self.start3DRotateAnimation(duration: duration, delegate: animationProxy)
            DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2, execute: {
                self.switchState = (self.switchState == .qrCode) ? .inviteLink : .qrCode
                // 90° 时更新文字
                self.updateOperationPanel(self.switchState)
                switchHandler(self.switchState)
            })
        }
        qrCodeCard?.switchToLinkHandler = { switchCardHandler() }
        inviteLinkCard?.switchToQRCodeHandler = { switchCardHandler() }
    }

    func animationDidStart(_ anim: CAAnimation) {
        isEnabled = false
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        isEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        qrCodeCard?.bindWithModel(cardInfo: cardInfo)
        inviteLinkCard?.bindWithModel(cardInfo: cardInfo)
    }

    func updateOperationPanel(_ state: CardSwitchState) {
        let shareButtonTitle = BundleI18n.LarkContact.Lark_Legacy_QrCodeShare
        let otherButtonTitle = state == .qrCode ?
            BundleI18n.LarkContact.Lark_Legacy_QrCodeSave : BundleI18n.LarkContact.Lark_Legacy_Copy
        leftOpButton.setTitle(otherButtonTitle, for: .normal)
        rightOpButton.setTitle(shareButtonTitle, for: .normal)
    }

    private func layoutPageSubviews() {
        qrCodeCard.flatMap { addSubview($0) }
        inviteLinkCard.flatMap { addSubview($0) }
        qrCodeCard?.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(scenes == .parent ? 392 : 480)
        }
        inviteLinkCard?.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(scenes == .parent ? 392 : 480)
        }

        addSubview(operationPanel)
        operationPanel.addSubview(leftOpButton)
        operationPanel.addSubview(rightOpButton)

        operationPanel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(70)
        }
        leftOpButton.snp.makeConstraints({ (make) in
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(36)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().multipliedBy(0.5).offset(-4)
        })
        rightOpButton.snp.makeConstraints({ (make) in
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(36)
            make.trailing.equalToSuperview().offset(-12)
            make.leading.equalTo(leftOpButton.snp.trailing).offset(8)
        })
    }

    private lazy var operationPanel: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    private lazy var leftOpButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.bgFloat), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.N200), for: .highlighted)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.rx.controlEvent(.touchUpInside)
        .asDriver()
        .drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.leftClickHandler(self.switchState)
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var rightOpButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.primaryContentDefault), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.B600), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            guard let `self` = self else { return }
            self.rightClickHandler(self.switchState)
        }).disposed(by: disposeBag)
        return button
    }()
}
