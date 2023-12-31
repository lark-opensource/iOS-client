//
//  InviteContainerView.swift
//  LarkContact
//
//  Created by Nix Wang on 2023/1/3.
//

import Foundation
import UIKit
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTheme
import SnapKit
import LarkExtensions
import UniverseDesignDialog
import EENavigator

class InviteContainerView: UIView {

    private lazy var topGradientMainCircle = GradientCircleView()
    private lazy var topGradientSubCircle = GradientCircleView()
    private lazy var topGradientRefCircle = GradientCircleView()
    private lazy var blurEffectView = UIVisualEffectView()

    lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .ud.textCaption
        label.font = .ud.body2
        return label
    }()

    lazy var infoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.infoOutlined, iconColor: .ud.textCaption), for: .normal)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.addTarget(self, action: #selector(onTapTip), for: .touchUpInside)
        return button
    }()

    lazy var tenantLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textTitle
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(24)
        }
        return label
    }()

    lazy var expireLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textPlaceholder
        label.textAlignment = .left
        label.font = .ud.caption0
        label.numberOfLines = 0
        return label
    }()

    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .custom)
        button.addTarget(self, action: #selector(onReset), for: .touchUpInside)
        return button
    }()

    private lazy var resetIcon: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.getIconByKey(.refreshOutlined, iconColor: .ud.primaryContentDefault)
        return view
    }()

    private lazy var resetTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.primaryContentDefault
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 1
        label.text = BundleI18n.LarkContact.Lark_Invitation_AddMembers_SharedInvitationInfo_ResetButton
        return label
    }()
    private let mainStack = UIStackView()

    var tipText: String?
    weak var hostViewController: UIViewController?
    var onResetBlock: (() -> Void)?
    let navigator: Navigatable
    init(hostViewController: UIViewController?, navigator: Navigatable) {
        self.hostViewController = hostViewController
        self.navigator = navigator
        super.init(frame: .zero)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .ud.bgFloat
        layer.cornerRadius = IGLayer.commonPopPanelRadius
        layer.masksToBounds = true
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        layer.borderWidth = 1

        addSubview(topGradientMainCircle)
        addSubview(topGradientSubCircle)
        addSubview(topGradientRefCircle)
        topGradientMainCircle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(106.0)
            make.top.equalToSuperview().offset(-46.0)
            make.width.equalToSuperview().multipliedBy(144.0 / 336)
            make.height.equalToSuperview().multipliedBy(116.0 / 380)
        }
        topGradientSubCircle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(-70.0)
            make.top.equalToSuperview().offset(-136.0)
            make.width.equalToSuperview().multipliedBy(244.0 / 336)
            make.height.equalToSuperview().multipliedBy(202.0 / 380)
        }
        topGradientRefCircle.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(174)
            make.top.equalToSuperview().offset(-89)
            make.width.equalToSuperview().multipliedBy(212.0 / 336)
            make.height.equalToSuperview().multipliedBy(151.0 / 380)
        }

        addSubview(blurEffectView)
        blurEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        mainStack.axis = .vertical
        mainStack.alignment = .center
        addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 50, left: 20, bottom: 35, right: 20))
        }

        tipText = BundleI18n.LarkContact.Lark_AdminUpdate_Toast_MobileOrgQRCodeContactAdmin
        infoButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 16, height: 16))
        }
        let tipStack = UIStackView(arrangedSubviews: [tipLabel, infoButton])
        tipStack.axis = .horizontal
        tipStack.spacing = 8
        tipStack.alignment = .center
        mainStack.addArrangedSubview(tipStack)
        mainStack.setCustomSpacing(8, after: tipStack)
        tipStack.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }

        mainStack.addArrangedSubview(tenantLabel)

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        mainStack.addArrangedSubview(spacer)

        resetIcon.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 10, height: 10))
        }
        let resetButtonStack = UIStackView(arrangedSubviews: [resetIcon, resetTitleLabel])
        resetButtonStack.axis = .horizontal
        resetButtonStack.spacing = 3.0
        resetButtonStack.alignment = .center
        resetButtonStack.isUserInteractionEnabled = false
        resetButton.addSubview(resetButtonStack)
        resetButtonStack.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        resetButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        expireLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let resetStack = UIStackView(arrangedSubviews: [expireLabel, resetButton])
        resetStack.axis = .horizontal
        resetStack.spacing = 12.0
        resetStack.alignment = .center
        mainStack.addArrangedSubview(resetStack)
        expireLabel.textAlignment = .right
        resetButtonStack.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
        }
        resetButton.snp.makeConstraints { make in
            make.width.equalToSuperview().dividedBy(4)
        }
        resetStack.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }

    private func setText(text: String, label: UILabel, lineHeight: CGFloat) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = lineHeight

        label.attributedText = NSAttributedString(
            string: text,
            attributes: [.paragraphStyle: paragraphStyle,
                         .font: label.font,
                         .foregroundColor: label.textColor]
        )
    }

    func setAuroraEffect(isDarkModeTheme: Bool) {
        if isDarkModeTheme {
            topGradientMainCircle.setColors(color: UIColor.ud.rgb("#75A4FF"), opacity: 0.2)
            topGradientSubCircle.setColors(color: UIColor.ud.rgb("#4C88FF"), opacity: 0.25)
            topGradientRefCircle.setColors(color: UIColor.ud.rgb("#135A78"), opacity: 0.2)
            blurEffectView.effect = UIBlurEffect(style: .dark)
        } else {
            topGradientMainCircle.setColors(color: UIColor.ud.rgb("#1456F0"), opacity: 0.2)
            topGradientSubCircle.setColors(color: UIColor.ud.rgb("#336DF4"), opacity: 0.25)
            topGradientRefCircle.setColors(color: UIColor.ud.rgb("#3EC3F7"), opacity: 0.2)
            blurEffectView.effect = UIBlurEffect(style: .light)
        }
    }

    @objc
    private func onTapTip() {
        guard let hostViewController = hostViewController else { return }

        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkContact.Lark_AdminUpdate_PH_MobileNotice)
        dialog.setContent(text: tipText ?? "")
        dialog.addPrimaryButton(text: BundleI18n.LarkContact.Lark_AdminUpdate_Button_MobileGotIt)

        navigator.present(dialog, from: hostViewController)
    }

    @objc
    private func onReset() {
        onResetBlock?()
    }

    func setRefreshing(_ toRefresh: Bool) {
        resetButton.isEnabled = !toRefresh
        resetTitleLabel.textColor = toRefresh ? UIColor.ud.B200 : UIColor.ud.colorfulBlue
        if toRefresh {
            UIView.animate(withDuration: 0.5, animations: {
                self.resetIcon.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
            }) { (_) in
                UIView.animate(withDuration: 0.5, animations: {
                    self.resetIcon.transform = CGAffineTransform(rotationAngle: 2 * CGFloat.pi)
                })
            }
        }
    }
}
