//
//  ReadRecordCell.swift
//  SKCommon
//
//  Created by CJ on 2021/9/25.
//

import Kingfisher
import SKResource
import SKUIKit
import UniverseDesignColor
import SKFoundation

class ReadRecordCell: UITableViewCell {
    static let reuseIdentifier = "ReadRecordCell"
    
    struct Layout {
        static let imageViewWidth: CGFloat = 40
    }

    var tapProfileHandler: ((ReadRecordUserInfoModel) -> Void)?
    var userInfoModel: ReadRecordUserInfoModel?

    private lazy var displayImage: UIImageView = {
        let imageView = SKAvatar(configuration: .init(backgroundColor: .clear,
                                               style: .circle,
                                               contentMode: .scaleAspectFill))
        imageView.layer.cornerRadius = Layout.imageViewWidth / 2.0
        imageView.layer.masksToBounds = true
        imageView.image = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(sender:)))
        tapGesture.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UDColor.textTitle
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textAlignment = .left
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.N500
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textAlignment = .left
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    private lazy var externalLabel: SKNavigationBarTitle.ExternalLabel = {
        let label = SKNavigationBarTitle.ExternalLabel()
        label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return label
    }()

    private lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textAlignment = .right
        label.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return label
    }()

    private lazy var seperatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineBorderCard
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentView.addSubview(displayImage)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(externalLabel)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(seperatorLine)
    }

    private func setupConstraints() {
        displayImage.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(17)
            make.width.height.equalTo(Layout.imageViewWidth)
            make.centerY.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(displayImage.snp.trailing).offset(16)
            make.trailing.lessThanOrEqualTo(timestampLabel.snp.leading).offset(-10)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(24)
        }

        externalLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(nameLabel)
            make.leading.equalTo(nameLabel.snp.trailing).offset(3)
            make.height.equalTo(16)
            make.trailing.lessThanOrEqualTo(timestampLabel.snp.leading).offset(-10)
            make.width.greaterThanOrEqualTo(40)
        }
        
        //设置优先显示名字，标签进行压缩，但标签最小宽度是40
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        externalLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        descriptionLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualTo(timestampLabel.snp.leading).offset(-10)
            make.top.equalTo(nameLabel.snp.bottom)
            make.bottom.equalToSuperview().offset(-9)
            make.height.equalTo(22)
        }

        timestampLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
            make.height.equalTo(25)
        }

        seperatorLine.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview()
            make.leading.equalTo(nameLabel)
            make.height.equalTo(0.5)
        }
    }

    func updateNameLabelConstraints() {
        if let model = userInfoModel {
            if model.descText.isEmpty {
                nameLabel.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(18)
                }
                descriptionLabel.snp.updateConstraints { make in
                    make.height.equalTo(0)
                    make.bottom.equalToSuperview().offset(-18)
                }
            } else {
                nameLabel.snp.updateConstraints { make in
                    make.top.equalToSuperview().offset(10)
                }
                descriptionLabel.snp.updateConstraints { make in
                    make.height.equalTo(22)
                    make.bottom.equalToSuperview().offset(-9)
                }
            }
        }
    }

    @objc
    func handleTapGesture(sender: UITapGestureRecognizer) {
        if let model = userInfoModel {
            tapProfileHandler?(model)
        }
    }
}

extension ReadRecordCell {
    
    func setUserInfoModel(_ model: ReadRecordUserInfoModel) {
        userInfoModel = model
        if let url = URL(string: model.avatarURL) {
            displayImage.kf.setImage(with: url, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        }

        self.nameLabel.text = model.localizedName
        self.descriptionLabel.text = model.descText

        self.timestampLabel.text = model.time
        
        if UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            if EnvConfig.CanShowExternalTag.value, let tagValue = model.displayTag?.tagValue, !tagValue.isEmpty {
                    self.externalLabel.isHidden = false
                    self.externalLabel.text = tagValue
                } else {
                    self.externalLabel.isHidden = true
                    self.externalLabel.text = ""
                }
        } else {
            if EnvConfig.CanShowExternalTag.value,
               model.isShowExternal {
                self.externalLabel.isHidden = false
                self.externalLabel.text = BundleI18n.SKResource.Doc_Widget_External
            } else {
                self.externalLabel.isHidden = true
                self.externalLabel.text = ""
            }
        }
        updateNameLabelConstraints()
    }
    
    func updateSeperator(isShow: Bool = true) {
        seperatorLine.isHidden = !isShow
    }
}
