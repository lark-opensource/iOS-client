//
//  AssistantViews.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/1/12.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa

enum NoDirectionalEntrance {
    case teamCode
    case qrcode
}

final class NoDirectionalBottomView: UIView {
    private let disposeBag = DisposeBag()
    let entrances: [NoDirectionalEntrance] = [.qrcode, .teamCode]
    let didClickEntranceHandler: (NoDirectionalEntrance) -> Void

    init(didClickEntranceHandler: @escaping (NoDirectionalEntrance) -> Void) {
        self.didClickEntranceHandler = didClickEntranceHandler
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.ud.bgBase
        layoutPageSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutPageSubviews() {
        addSubview(leftGradientSepLine)
        addSubview(tipLabel)
        addSubview(rightGradientSepLine)
        addSubview(inviteQRCodeButton)
        addSubview(teamCodeButton)

        leftGradientSepLine.snp.makeConstraints { (make) in
            make.centerY.equalTo(tipLabel)
            make.height.equalTo(1)
            make.left.equalToSuperview().offset(34.5)
            make.right.equalTo(tipLabel.snp.left).offset(-10)
        }
        tipLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-91)
            make.centerX.equalToSuperview()
        }
        rightGradientSepLine.snp.makeConstraints { (make) in
            make.centerY.equalTo(tipLabel)
            make.height.equalTo(1)
            make.right.equalToSuperview().offset(-34.5)
            make.left.equalTo(tipLabel.snp.right).offset(10)
        }
        inviteQRCodeButton.snp.makeConstraints { (make) in
            make.right.equalTo(self.snp.centerX).offset(-24)
            make.top.equalTo(tipLabel.snp.bottom).offset(15)
            make.bottom.equalToSuperview().inset(10)
            make.width.equalTo(100)
        }
        teamCodeButton.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.centerX).offset(24)
            make.top.equalTo(tipLabel.snp.bottom).offset(15)
            make.bottom.equalToSuperview().inset(10)
            make.width.equalTo(100)
        }
    }

    private lazy var teamCodeButton: EntranceControl = {
        let button = EntranceControl(icon: Resources.entrance_teamcode,
                                     title: BundleI18n.LarkContact.Lark_Invitation_AddMembersTeamCodeEntry)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            self?.didClickEntranceHandler(.teamCode)
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var inviteQRCodeButton: EntranceControl = {
        let button = EntranceControl(icon: Resources.entrance_qrcode,
                                     title: BundleI18n.LarkContact.Lark_Invitation_AddMembersShowQRCode)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            self?.didClickEntranceHandler(.qrcode)
        }).disposed(by: disposeBag)
        return button
    }()

    private lazy var leftGradientSepLine: GradientLine = {
        let line = GradientLine(mode: .clearToTint)
        return line
    }()

    private lazy var rightGradientSepLine: GradientLine = {
        let line = GradientLine(mode: .tintToClear)
        return line
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 1
        label.text = BundleI18n.LarkContact.Lark_Invitation_AddMembersTitleOtherWay
        return label
    }()
}

private final class GradientLine: UIView {
    enum TintMode {
        case tintToClear
        case clearToTint
    }

    static override var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    private static let gradientTintColor = UIColor.ud.color(216, 216, 216)
    private static let gradientClearColor = UIColor.ud.color(238, 238, 238, 0)
    private let mode: TintMode

    init(mode: TintMode) {
        self.mode = mode
        super.init(frame: .zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let gradientLayer: CAGradientLayer? = layer as? CAGradientLayer
        if let layer = gradientLayer {
            layer.locations = [0, 1]
            layer.startPoint = CGPoint(x: 0, y: 0)
            layer.endPoint = CGPoint(x: 1, y: 0)
            switch mode {
            case .tintToClear:
                layer.colors = [GradientLine.gradientTintColor.cgColor, GradientLine.gradientClearColor.cgColor]
            case .clearToTint:
                layer.colors = [GradientLine.gradientClearColor.cgColor, GradientLine.gradientTintColor.cgColor]
            }
        }
    }
}

private final class EntranceControl: UIControl {
    init(icon: UIImage, title: String) {
        super.init(frame: .zero)
        backgroundColor = .clear
        layoutPageSubviews()
        iconView.image = icon
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutPageSubviews() {
        addSubview(iconView)
        addSubview(titleLabel)
        iconView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(6)
            make.width.height.equalTo(24)
            make.centerX.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconView.snp.bottom).offset(6)
            make.left.right.equalToSuperview()
        }
    }

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N600
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.numberOfLines = 2
        return label
    }()
}

final class InviteOperationView: UIView {
    var importFromContactsTapHandler: (() -> Void)?
    var inviteButtonTapHandler: (() -> Void)?
    var buttonEnableBinder: Binder<Bool> {
        return inviteButton.rx.isEnabled
    }
    private let disposeBag = DisposeBag()

    lazy var inviteButton: InviteLoadingButton = {
        let button = InviteLoadingButton(frame: .zero)
        button.addTarget(self, action: #selector(clickButton), for: .touchUpInside)
        return button
    }()

    private lazy var importContactButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.bgBase), for: .normal)
        button.setBackgroundImage(UIImage.lu.fromColor(UIColor.ud.N100), for: .highlighted)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.layer.cornerRadius = IGLayer.commonButtonRadius
        button.layer.masksToBounds = true
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.borderWidth = 1
        button.setTitle(BundleI18n.LarkContact.Lark_Invitation_AddMembersImportContactsNew, for: .normal)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            if let handler = self?.importFromContactsTapHandler {
                handler()
            }
        }).disposed(by: self.disposeBag)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clickButton() {
        inviteButton.setLoading(true)
        inviteButtonTapHandler?()
    }

    private func layoutPageSubviews() {
        addSubview(inviteButton)
        addSubview(importContactButton)
        inviteButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        importContactButton.snp.makeConstraints { (make) in
            make.top.equalTo(inviteButton.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
    }
}
