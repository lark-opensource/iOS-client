//
//  AtPickerTableViewCell.swift
//  Todo
//
//  Created by 张威 on 2021/2/8.
//

import CTFoundation
import LarkUIKit
import LarkBizAvatar
import LarkTag
import LarkBizTag
import UniverseDesignFont

/// AtPicker - Cell

protocol AtPickerTableViewCellDataType {
    var avatarSeed: AvatarSeed { get }
    var name: String { get }
    var desc: String? { get }
    var tagInfo: [TagDataItem] { get }
}

class AtPickerTableViewCell: UITableViewCell, ViewDataConvertible {

    static let desiredHeight = CGFloat(64)

    var viewData: AtPickerTableViewCellDataType? {
        didSet {
            guard let viewData = viewData else { return }

            nameLabel.text = viewData.name
            descLabel.text = viewData.desc
            descLabel.isHidden = viewData.desc?.isEmpty ?? true
            avatarView.isHidden = false
            avatarView.setAvatarByIdentifier(
                viewData.avatarSeed.avatarId,
                avatarKey: viewData.avatarSeed.avatarKey,
                avatarViewParams: .init(sizeType: .size(avatarSize), format: .webp)
            )

            chatterTagBuilder.update(with: viewData.tagInfo)
            nameTag.isHidden = chatterTagBuilder.isDisplayedEmpty()
            nameLabel.snp.updateConstraints { make in
                make.top.equalTo(avatarView).offset(descLabel.isHidden ? 8 : -2)
            }
        }
    }

    private let avatarSize = CGFloat(40)

    private let avatarView = BizAvatar()
    private let nameLabel = UILabel()
    private lazy var chatterTagBuilder = ChatterTagViewBuilder()
    private lazy var nameTag: TagWrapperView = {
        let tagView = chatterTagBuilder.build()
        tagView.isHidden = true
        return tagView
    }()

    private let descLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UDFont.systemFont(ofSize: 16)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarView).offset(-2)
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.height.equalTo(22)
        }

        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        contentView.addSubview(nameTag)
        nameTag.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.left.equalTo(nameLabel.snp.right).offset(6)
            $0.right.lessThanOrEqualToSuperview().offset(-16)
        }

        descLabel.textColor = UIColor.ud.textPlaceholder
        descLabel.font = UDFont.systemFont(ofSize: 14)
        descLabel.text = nil
        contentView.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.bottom.equalTo(avatarView).offset(2)
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
