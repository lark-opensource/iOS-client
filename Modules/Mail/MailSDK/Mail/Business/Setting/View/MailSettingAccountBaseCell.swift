//
//  MailSettingAccountBaseCell.swift
//  MailSDK
//
//  Created by Raozhongtao on 2023/11/17.
//

import Foundation
import LarkUIKit
import RxSwift
import EENavigator
import LarkTag
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignTag


struct SettingAccountBaseCellParams {
    var hasAvatarView: Bool = true
    var style: UITableViewCell.CellStyle
    var reuseIdentifier: String?
}

// MARK: - MailSettingAccountBaseCell
class MailSettingAccountBaseCell: UITableViewCell {
    let titleLabel: UILabel = UILabel()
    let titleContainer: UIView = UIView()
    let subTitleLabel: UILabel = UILabel()
    let avatarView: MailAvatarImageView = MailAvatarImageView()
    let grayBg: UIView = UIView()
    var hasAvatarView: Bool
    var showArrow: Bool = false {
        didSet {
            arrowIcon.isHidden = !showArrow
        }
    }
    var item: MailSettingItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    lazy var arrowIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.hideToolbarOutlined.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = UIColor.ud.iconN3
        return imageView
    }()

    lazy var warningIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.mail_setting_icon_warn
        return imageView
    }()

    lazy var tagsContainer: UIStackView = {
        let tagsContainer = UIStackView()
        tagsContainer.axis = .horizontal
        tagsContainer.spacing = 4
        tagsContainer.alignment = .leading
        return tagsContainer
    }()

    let disposeBag = DisposeBag()


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    init(params: SettingAccountBaseCellParams) {
        self.hasAvatarView = params.hasAvatarView
        super.init(style: params.style, reuseIdentifier: params.reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.hasAvatarView = true
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }



    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        titleLabel.font = UDFont.title4
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail

        subTitleLabel.font = UIFont.systemFont(ofSize: 14)
        subTitleLabel.textColor = UIColor.ud.textPlaceholder
        subTitleLabel.numberOfLines = 1
        subTitleLabel.lineBreakMode = .byTruncatingTail
        titleContainer.addSubview(titleLabel)
        titleContainer.addSubview(subTitleLabel)
        titleContainer.addSubview(tagsContainer)

        contentView.addSubview(titleContainer)
        contentView.addSubview(warningIcon)
        contentView.addSubview(arrowIcon)
        contentView.addSubview(avatarView)
        if hasAvatarView {
            avatarView.clipsToBounds = true
            avatarView.layer.cornerRadius = 48 / 2.0
            avatarView.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 48, height: 48))
                make.top.leading.equalTo(13)
                make.bottom.equalTo(-13)
            }
        }
        warningIcon.isHidden = true
        warningIcon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.bottom.trailing.equalTo(avatarView)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(13)
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(tagsContainer.snp.leading)
            make.height.equalTo(24)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-13)
            make.height.equalTo(24)
        }
        titleContainer.snp.makeConstraints { (make) in
            var leadingOffset: CGFloat = 0
            if hasAvatarView {
                leadingOffset = 12
            } else {
                leadingOffset = 16
            }
            make.leading.equalTo(avatarView.snp.trailing).offset(leadingOffset)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.trailing.equalTo(arrowIcon.snp.leading).offset(-12)
            make.centerY.top.bottom.equalToSuperview()
        }
        tagsContainer.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8).priority(.high)
            make.trailing.lessThanOrEqualToSuperview()
            make.height.equalTo(18)
            make.centerY.equalTo(titleLabel)
        }
        arrowIcon.isHidden = true
        arrowIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 12, height: 12))
            make.trailing.equalTo(-16)
        }

        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickCell)))
    }

    func setupTags(with tags: [UDTag]) {
        guard !tags.isEmpty else { return }
        for tag in tags {
            tagsContainer.addArrangedSubview(tag)
            let textWidth = tag.text?.getTextWidth(font: UIFont.systemFont(ofSize: 12), height: 44) ?? 0
            let widthGap: CGFloat = 10
            tag.snp.makeConstraints { (make) in
                make.width.equalTo(textWidth + 10)
                make.height.equalTo(18)
                make.centerY.equalToSuperview()
            }
        }
    }

    func setCellInfo() {
        assertionFailure("must Override")
    }

    @objc
    func didClickCell() {
        assertionFailure("must Override")
    }
}
