//
//  AssigneeListCell.swift
//  Todo
//
//  Created by 张威 on 2021/8/16.
//

import CTFoundation
import LarkBizAvatar
import LarkTag
import UniverseDesignIcon
import ByteWebImage
import UniverseDesignFont

protocol GroupedAssigneeListCellDataType {
    var name: String { get }
    var avatar: AvatarSeed { get }
    var showMore: Bool { get }
}

class GroupedAssigneeListCell: UITableViewCell, ViewDataConvertible {
    var viewData: GroupedAssigneeListCellDataType? {
        didSet {
            guard let viewData = viewData else { return }

            avatarView.setAvatarByIdentifier(
                viewData.avatar.avatarId,
                avatarKey: viewData.avatar.avatarKey,
                avatarViewParams: .init(
                    sizeType: .size(avatarSize),
                    format: .webp
                )
            )
            nameLabel.text = viewData.name
            moreButton.isHidden = !viewData.showMore
        }
    }

    var onMoreClick: (() -> Void)?

    private let avatarSize: CGFloat = 40
    private let avatarView = BizAvatar()
    private let nameLabel = UILabel()
    private let moreButton = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody

        nameLabel.font = UDFont.systemFont(ofSize: 16)
        nameLabel.textColor = UIColor.ud.textTitle

        moreButton.hitTestEdgeInsets = .init(edges: -10)
        moreButton.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN2), for: .normal)
        moreButton.addTarget(self, action: #selector(handleMoreButtonClick), for: .touchUpInside)
        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(16)
        }

        avatarView.isUserInteractionEnabled = false
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleMoreButtonClick() {
        onMoreClick?()
    }
}

final class DetailAssingeeHeaderView: UIView {

    var onAddHandler: (() ->Void)?

    var title: String? {
        didSet {
            headerLabel.text = title
        }
    }

    var count: Int = 0 {
        didSet {
            if count >= 1 {
                headerLabel.text = "\(I18N.Todo_New_Owner_Text)\(count)"
            } else {
                headerLabel.text = I18N.Todo_New_Owner_Text
            }
        }
    }
    var enableClickBtn: Bool = false {
        didSet {
            btn.isHidden = !enableClickBtn
        }
    }

    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 20, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var btn: UIButton = {
        let btn = UIButton()
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = UDFont.systemFont(ofSize: 14, weight: .medium)
        btn.setTitle(I18N.Todo_common_Add, for: .normal)
        btn.addTarget(self, action: #selector(clickBtn), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        addSubview(headerLabel)
        addSubview(btn)
        headerLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(15)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(48)
        }
        btn.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(40)
        }

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clickBtn() {
        onAddHandler?()
    }
}
