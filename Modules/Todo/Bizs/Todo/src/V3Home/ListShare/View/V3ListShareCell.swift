//
//  V3ListShareCell.swift
//  Todo
//
//  Created by GCW on 2022/11/30.
//

import Foundation
import LarkBizAvatar
import UniverseDesignIcon
import UniverseDesignTag
import LarkTag
import EENavigator
import UniverseDesignFont

protocol ListPermissionDelegate: AnyObject {
    func operatePermission(_ identifier: String, sourceView: UILabel?)
    func clickProfile(_ userId: String, _ sender: V3ListShareCell)
    func clickContent(_ url: String, _ sender: V3ListShareCell)}

final class V3ListShareCell: UITableViewCell {
    weak var delegate: ListPermissionDelegate?

    var cellData: TaskMemberCellData? {
        didSet {
            updateUI()
        }
    }

    private let avatarView = BizAvatar()
    private let leadingImageView = UIImageView()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UDFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        return titleLabel
    }()

    private lazy var nameTag: UDTag = {
        let config = UDTagConfig.TextConfig(cornerRadius: 4,
                                            textColor: UIColor.ud.udtokenTagTextSBlue,
                                            backgroundColor: UIColor.ud.udtokenTagBgBlue)
        let tag = UDTag(text: I18N.Todo_ShareList_ManageCollaboratorsCanManage_Text, textConfig: config)
        tag.layer.masksToBounds = true
        return tag
    }()

    private lazy var powerLable: UILabel = {
        let powerLabel = UILabel()
        powerLabel.font = UDFont.systemFont(ofSize: 14)
        powerLabel.textColor = UIColor.ud.textTitle
        powerLabel.numberOfLines = 1
        powerLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickTap)))
        powerLabel.isUserInteractionEnabled = true
        return powerLabel
    }()

    private lazy var iconBtn: UIButton = {
        let iconBtn = UIButton()
        iconBtn.setImage(UDIcon.getIconByKey(.expandDownFilled, iconColor: UIColor.ud.iconN2, size: CGSize(width: 8, height: 8)), for: .normal)
        iconBtn.addTarget(self, action: #selector(clickTap), for: .touchUpInside)
        return iconBtn
    }()


    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpUI() {
        // 设置背景颜色
        self.backgroundColor = UIColor.ud.bgBody
        self.selectionStyle = .none

        // 添加头像框
        contentView.addSubview(leadingImageView)
        contentView.addSubview(avatarView)
        // 添加titleLabel（名称）
        contentView.addSubview(titleLabel)
        // 添加powerLabel（权限字样）
        contentView.addSubview(powerLable)
        // 添加iconBtn（下三角button），当不为所有者时存在
        contentView.addSubview(iconBtn)
        avatarView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ListShare.Config.leadingIconSize.width)
        }
        leadingImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(ListShare.Config.leadingIconSize.width)
        }

        iconBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        powerLable.snp.makeConstraints { (make) in
            make.right.equalTo(iconBtn.snp.left)
            make.top.equalToSuperview().offset(21)
            make.bottom.equalToSuperview().offset(-23)
        }
        // 设置powerLabel的抗压缩属性，防止填充时被压缩，只需要title进行压缩即可
        powerLable.setContentCompressionResistancePriority(.required, for: .horizontal)

        // 添加tag标签
        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        contentView.addSubview(nameTag)
        nameTag.isHidden = true

        let tapIcon = UITapGestureRecognizer(target: self, action: #selector(clickIcon))
        avatarView.addGestureRecognizer(tapIcon)

        titleLabel.isUserInteractionEnabled = true
        let tapContent = UITapGestureRecognizer(target: self, action: #selector(clickContent))
        titleLabel.addGestureRecognizer(tapContent)
    }

    fileprivate func updateUI() {
        guard let cellData = cellData else { return }

        switch cellData.leadingIcon {
        case .avatar(let seed):
            leadingImageView.isHidden = true
            avatarView.isHidden = false
            avatarView.setAvatarByIdentifier(seed.avatarId, avatarKey: seed.avatarKey)
        case .icon(let image):
            leadingImageView.isHidden = false
            avatarView.isHidden = true
            leadingImageView.image = image
        }
        titleLabel.text = cellData.name
        powerLable.text = cellData.roleActionText
        powerLable.isUserInteractionEnabled = cellData.canEditAction
        iconBtn.isHidden = !cellData.canEditAction

        let isOwner = cellData.role == .owner
        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(isOwner ? nameTag.snp.left : powerLable.snp.left).offset(-12)
        }
        if isOwner {
            nameTag.snp.remakeConstraints { (make) in
                make.centerY.equalTo(titleLabel)
                make.left.equalTo(titleLabel.snp.right).offset(6)
                if let width = nameTag.text?.getWidth(font: UDFont.systemFont(ofSize: 12)) {
                    make.width.equalTo(width + 10)
                }
                make.right.lessThanOrEqualTo(powerLable.snp.left).offset(-12)
            }
            // 设置nameTag的抗压缩属性，titleLabel压缩即可
            nameTag.setContentHuggingPriority(.required, for: .horizontal)
            nameTag.isHidden = false
        } else {
            nameTag.isHidden = true
        }
    }

    @objc
    private func clickTap() {
        guard let delegate = delegate, let cellData = cellData else { return }
        delegate.operatePermission(cellData.identifier, sourceView: powerLable)
    }

    @objc
    private func clickIcon() {
        guard let cellData = cellData, cellData.memberType == .user else { return }
        delegate?.clickProfile(cellData.identifier, self)
    }

    @objc
    private func clickContent() {
        guard let cellData = cellData, let url = cellData.url, cellData.memberType == .docs else { return }
        delegate?.clickContent(url, self)
    }
}
