//
//  CalendarLiveInterceptionViewController.swift
//  ByteView
//
//  Created by liurundong.henry on 2020/12/17.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import ByteViewSetting
import LarkContainer
import ByteViewUI
import UniverseDesignIcon

class CalendarLiveInterceptionViewController: UIViewController {

    private enum Layout {
        static let upgradeDisableImageSize: CGFloat = 125.0
        static let upgradeEnableImageSize: CGFloat = 245.0
        static let infoLabelTopSpacing: CGFloat = 16.0
        static let infoLabelHorizontalEdge: CGFloat = 16.0
        static let upgradeButtonTitleLabelVerticalEdge: CGFloat = 8.0
        static let upgradeButtonTitleLabelHorizontalEdge: CGFloat = 16.0
        static let upgradeButtonHeight: CGFloat = 36.0
        static let upgradeButtonTopSpecing: CGFloat = 24.0
        static let upgradeButtonCornerRadius: CGFloat = 4.0
    }

    private lazy var upgradeEnabledImage: UIImage = BundleResources.ByteViewCalendar.Calendar.CalendarLiveInterceptionUpgradeEnabled
    private lazy var upgradeDisabledImage: UIImage = BundleResources.ByteViewCalendar.Calendar.CalendarLiveInterceptionUpgradeDisabled

    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.leftBoldOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.leftBoldOutlined, iconColor: .ud.N900, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.addTarget(self, action: #selector(popVC), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    private lazy var infoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = showUpgrade ? upgradeEnabledImage : upgradeDisabledImage
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: showUpgrade ? I18n.View_G_MobileUpdateApp : I18n.View_G_MobileUseDesktop, config: .bodyAssist)
        label.textColor = UIColor.ud.textCaption
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var upgradeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.contentEdgeInsets = UIEdgeInsets(top: Layout.upgradeButtonTitleLabelVerticalEdge,
                                                left: Layout.upgradeButtonTitleLabelHorizontalEdge,
                                                bottom: Layout.upgradeButtonTitleLabelVerticalEdge,
                                                right: Layout.upgradeButtonTitleLabelHorizontalEdge)
        button.setTitle(I18n.View_G_GoUpdate, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(UIColor.ud.N00, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.layer.cornerRadius = Layout.upgradeButtonCornerRadius
        button.layer.masksToBounds = true
        button.isHidden = !showUpgrade
        button.addTarget(self, action: #selector(goToUpgradeAction), for: .touchUpInside)
        return button
    }()

    private let showUpgrade: Bool
    private let onUpgrade: ((UIViewController) -> Void)?
    init(showUpgrade: Bool, onUpgrade: ((UIViewController) -> Void)?) {
        self.showUpgrade = showUpgrade
        self.onUpgrade = onUpgrade
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.N00
        setupViews()
        autoLayoutViews()
    }

    private func setupViews() {
        view.addSubview(backButton)
        view.addSubview(contentStackView)
        contentStackView.addArrangedSubview(infoImageView)
        contentStackView.addArrangedSubview(infoLabel)
        contentStackView.addArrangedSubview(upgradeButton)
        contentStackView.setCustomSpacing(Layout.infoLabelTopSpacing, after: infoImageView)
        contentStackView.setCustomSpacing(Layout.upgradeButtonTopSpecing, after: infoLabel)
    }

    private func autoLayoutViews() {
        backButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16.0)
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12.0)
            maker.size.equalTo(24.0)
        }
        contentStackView.snp.makeConstraints { (maker) in
            maker.left.right.centerY.equalToSuperview()
        }
        infoImageView.snp.makeConstraints { (maker) in
            maker.size.equalTo(showUpgrade ? Layout.upgradeEnableImageSize : Layout.upgradeDisableImageSize)
        }
        infoLabel.snp.makeConstraints { (maker) in
            maker.left.greaterThanOrEqualToSuperview().offset(Layout.infoLabelHorizontalEdge)
            maker.right.lessThanOrEqualToSuperview().offset(-Layout.infoLabelHorizontalEdge)
        }
        upgradeButton.snp.makeConstraints { (maker) in
            maker.height.equalTo(Layout.upgradeButtonHeight)
        }
    }

    @objc
    private func goToUpgradeAction() {
        self.onUpgrade?(self)
    }

    @objc
    private func popVC() {
        if let nav = navigationController {
            let vcs = nav.viewControllers.filter { $0 !== self }
            if !vcs.isEmpty {
                nav.setViewControllers(vcs, animated: true)
            }
        }
    }
}
