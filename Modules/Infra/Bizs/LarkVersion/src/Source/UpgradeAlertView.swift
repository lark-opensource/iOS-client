//
//  UpgradeAlertView.swift
//  LarkVersion
//
//  Created by K3 on 2018/7/16.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LKCommonsLogging
import UniverseDesignColor
import FigmaKit

typealias UpgradeEventHandler = () -> Void

internal final class UpgradeAlertView: UIView {
    static private var logger = Logger.log(UpgradeAlertView.self, category: "LarkVersion")

    private let gradientView: LinearGradientView = LinearGradientView()
    private let titleLabel: UILabel = UILabel()
    private let noteTextView: FlexibleTextView = FlexibleTextView()

    private var hasMaskView: Bool = false
    lazy var textMaskView: LinearGradientView = {
        let view = LinearGradientView()
        view.colors = [UIColor.ud.bgFloat.withAlphaComponent(0), UIColor.ud.bgFloat]
        view.locations = [0.0, 0.4, 1]
        view.direction = .topToBottom
        view.type = .linear
        view.isUserInteractionEnabled = false
        return view
    }()

    private let buttonContentView: UIStackView = UIStackView()
    private lazy var laterButton: UIButton = {
        UIButton()
    }()
    private let upgradButton: UIButton = UIButton()

    var buttonBottomOffset: CGFloat = UpgradeAlertView.Cons.buttonNoSafeAreaBottomOffset

    var laterTitle: String = BundleI18n.LarkVersion.Lark_Legacy_UpgradeLater {
        didSet {
            self.laterButton.setTitle(laterTitle, for: .normal)
        }
    }

    var upgradeTitle: String = BundleI18n.LarkVersion.Lark_Legacy_immediate {
        didSet {
            self.upgradButton.setTitle(upgradeTitle, for: .normal)
        }
    }

    public var laterHandler: UpgradeEventHandler?
    public var upgradHandler: UpgradeEventHandler?

    private(set) var showLater: Bool

    init(showLater: Bool) {
        self.showLater = showLater
        super.init(frame: .zero)
        self.accessibilityIdentifier = "upgrade_alert_view"

        backgroundColor = UIColor.ud.bgFloat
        layer.cornerRadius = Self.Cons.containerRadius
        layer.masksToBounds = true

        gradientView.colors = [UIColor.ud.B100, UIColor.ud.bgFloat]
        gradientView.locations = [0.0, 0.4, 1]
        gradientView.type = .linear
        gradientView.direction = .topToBottom
        addSubview(gradientView)
        gradientView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.left.equalToSuperview()
            make.height.equalTo(Self.Cons.gradientHeight)
        }

        titleLabel.text = BundleI18n.LarkVersion.Lark_Feed_EnterprisePackageUpgradeTitle()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = Self.Cons.titleFont
        titleLabel.numberOfLines = Self.Cons.titleLimitLines
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Self.Cons.contentHPadding)
            make.right.equalToSuperview().offset(-Self.Cons.contentHPadding)
            make.top.equalToSuperview().offset(Self.Cons.titleTopPadding)
        }

        noteTextView.textColor = UIColor.ud.textTitle
        noteTextView.backgroundColor = UIColor.ud.bgFloat
        noteTextView.font = Self.Cons.contentFont
        noteTextView.textContainer.lineFragmentPadding = 0
        noteTextView.isEditable = false
        noteTextView.isScrollEnabled = false
        addSubview(noteTextView)
        noteTextView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Self.Cons.contentHPadding)
            make.right.equalToSuperview().offset(-Self.Cons.contentHPadding)
            make.top.equalTo(titleLabel.snp.bottom).offset(Self.Cons.contentVPadding)
            make.height.greaterThanOrEqualTo(Self.Cons.minContentHeight)
        }
        noteTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Self.Cons.contentVPadding, right: 0)
        noteTextView.maxHeight = Self.Cons.maxContentHeight

        addSubview(buttonContentView)
        buttonContentView.axis = .horizontal
        buttonContentView.spacing = 10
        buttonContentView.distribution = .fillEqually
        buttonContentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Self.Cons.buttonHPadding)
            make.right.equalToSuperview().offset(-Self.Cons.buttonHPadding)
            make.top.equalTo(noteTextView.snp.bottom)
            make.bottom.equalToSuperview().offset(-self.buttonBottomOffset)
            make.height.equalTo(Self.Cons.buttonHeight)
        }

        if showLater {
            custom(button: laterButton,
                   title: self.laterTitle,
                   titleColor: UIColor.ud.textTitle,
                   highlightColor: UIColor.ud.fillHover,
                   borderColor: UIColor.ud.lineBorderComponent,
                   selector: #selector(later))
            laterButton.lu.addRightBorder(color: UIColor.ud.lineBorderCard)
            laterButton.accessibilityIdentifier = "upgrade_later"
            buttonContentView.addArrangedSubview(laterButton)
        }
        custom(button: upgradButton,
               title: self.upgradeTitle,
               titleColor: UIColor.ud.primaryPri500,
               highlightColor: UIColor.ud.fillHover,
               borderColor: UIColor.ud.primaryFillHover,
               selector: #selector(upgrade))
        upgradButton.accessibilityIdentifier = "upgrade_now"
        buttonContentView.addArrangedSubview(upgradButton)
    }

    override func safeAreaInsetsDidChange() {
        if self.safeAreaInsets.bottom == 0 {
            buttonBottomOffset = Self.Cons.buttonNoSafeAreaBottomOffset
        } else {
            buttonBottomOffset = Self.Cons.buttonSafeAreaBottomOffset + self.safeAreaInsets.bottom
        }
        buttonContentView.snp.updateConstraints { (make) in
            make.bottom.equalTo(-buttonBottomOffset)
        }
    }

    private func custom(button: UIButton, title: String, titleColor: UIColor, highlightColor: UIColor, borderColor: UIColor, selector: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = Self.Cons.buttonTitleFont
        button.setTitleColor(titleColor, for: .normal)
        let highlightImage = UIImage.lu.fromColor(highlightColor)
        button.setBackgroundImage(highlightImage, for: .highlighted)
        button.layer.ud.setBorderColor(borderColor)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 6
        button.addTarget(self, action: selector, for: .touchUpInside)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        addMaskIfNeed()
    }

    func setup(note: String, customTitle: String? = nil) {
        noteTextView.text = note
        // 指定customTitle即可覆盖原弹窗标题
        if let title = customTitle {
            titleLabel.text = title
        }
    }

    func addMaskIfNeed() {
        guard noteTextView.isScrollEnabled else {
            buttonContentView.snp.updateConstraints { make in
                make.top.equalTo(noteTextView.snp.bottom).offset(Self.Cons.contentVPadding)
            }
            if (hasMaskView) {
                textMaskView.removeFromSuperview()
            }
            hasMaskView = false
            return
        }

        // 超出最大高度，内容可滚动，需要加个小遮罩
        if (!hasMaskView) {
            insertSubview(textMaskView, belowSubview: buttonContentView)
            textMaskView.snp.makeConstraints { (make) in
                make.left.equalTo(buttonContentView.snp.left)
                make.right.equalTo(buttonContentView.snp.right)
                make.bottom.equalTo(buttonContentView.snp.bottom).offset(-20)
                make.height.equalTo(Self.Cons.maskHeight)
            }
            buttonContentView.snp.updateConstraints { make in
                make.top.equalTo(noteTextView.snp.bottom)
            }
        }
        hasMaskView = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Self.logger.info("new version: alert view dealloc")
    }
}

private extension UpgradeAlertView {
    @objc
    func later() {
        laterHandler?()
    }

    @objc
    func upgrade() {
        upgradHandler?()
    }
}

extension UpgradeAlertView {
    enum Cons {
        static let gradientHeight: CGFloat = 120
        static let containerRadius: CGFloat = 12
        static let titleLimitLines: Int = 2
        static let titleFont: UIFont = UIFont.systemFont(ofSize: 22, weight: .semibold)
        static let titleTopPadding: CGFloat = 28
        static let contentFont: UIFont = UIFont.systemFont(ofSize: 16)
        static let contentHPadding: CGFloat = 24
        static let contentVPadding: CGFloat = 24
        static let buttonHeight: CGFloat = 48
        static let buttonHPadding: CGFloat = 20
        static let buttonNoSafeAreaBottomOffset = 17.0
        static let buttonSafeAreaBottomOffset = 4.0
        static let buttonTitleFont = UIFont.systemFont(ofSize: 17, weight: .regular)
        static let minContentHeight: CGFloat = 90
        static let maxContentHeight: CGFloat = 330
        static let maskHeight: CGFloat = 60
    }
}
