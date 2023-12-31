//
//  AppPermissionTableViewCell.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/12/12.
//

import UIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignButton
import UniverseDesignIcon

class AppPermissionTableViewCell: UITableViewCell {

    var logoView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 8.0
        imageView.layer.masksToBounds = true
        return imageView
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14.0)
        label.textColor = .ud.textTitle
        return label
    }()

    var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .ud.caption0
        label.textColor = .ud.textTitle
        return label
    }()

    var switchButton: UIButton = {
        let button = UDButton.secondaryBlue
        return button
    }()

    var userID: String?
    var switchBlock: ((_ userID: String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        initViews()
    }

    private func initViews() {
        contentView.backgroundColor = .ud.bgContentBase
        
        logoView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4.0
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        switchButton.setContentHuggingPriority(.required, for: .horizontal)
        switchButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        switchButton.snp.makeConstraints { make in
            make.height.equalTo(32)
        }
        switchButton.addTarget(self, action: #selector(onSwitch), for: .touchUpInside)

        let mainStack = UIStackView(arrangedSubviews: [logoView, textStack, switchButton])
        mainStack.axis = .horizontal
        mainStack.spacing = 12.0
        mainStack.alignment = .center

        contentView.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: 16))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup(userItem: V4UserItem, switchBlock: ((_ userID: String) -> Void)?) {
        self.switchBlock = switchBlock
        self.userID = userItem.user.id

        if let url = URL(string: userItem.user.tenant.iconURL) {
            logoView.kf.setImage(with: url,
                                 placeholder: Resource.V3.default_avatar)
        }
        titleLabel.text = userItem.user.tenant.name
        subtitleLabel.text = userItem.user.name
        if let title = userItem.button?.text {
            switchButton.setTitle(title, for: .normal)
        }
    }

    @objc
    private func onSwitch() {
        if let userID = self.userID {
            switchBlock?(userID)
        }
    }
}

class AddAccountView: UIView {
    let iconView = UIImageView(image: UDIcon.mailCollaboratorOutlined)
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .ud.textTitle
        return label
    }()
    let disclosureIndicator: UIImageView = {
        let imageView = UIImageView()
        let image = BundleResources.UDIconResources.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        imageView.image = image
        imageView.frame.size = image.size
        return imageView
    }()

    var actionBlock: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .ud.bgContentBase
        layer.cornerRadius = 8.0

        let iconBackground = UIView()
        iconBackground.backgroundColor = .ud.bgBody
        iconBackground.layer.cornerRadius = 8.0
        iconBackground.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 40, height: 40))
        }
        iconBackground.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 19, height: 19))
            make.center.equalToSuperview()
        }

        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.text = I18N.Lark_Passport_AccountAccessControl_NoAccess_UseOtherAccounts

        let stackView = UIStackView(arrangedSubviews: [iconBackground, titleLabel, disclosureIndicator])
        stackView.axis = .horizontal
        stackView.spacing = 12.0
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(edges: 16.0))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tap)
    }

    @objc
    func onTap() {
        actionBlock?()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 72)
    }
}

