//
//  ChatChatterLeanCell.swift
//  LarkCore
//
//  Created by ByteDance on 2022/9/5.
//

import Foundation
import UIKit
import SnapKit
import LarkTag
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import LarkListItem
import LarkBizAvatar
import LarkContainer

// swiftlint:disable unused_setter_value
open class ChatChatterLeanCell: BaseTableViewCell, ChatChatterCellProtocol {
    public var isCheckboxHidden: Bool {
        get { return true }
        set {}
    }
    public func setCellSelect(canSelect: Bool,
                              isSelected: Bool,
                              isCheckboxHidden: Bool) {
        self.isCheckboxHidden = isCheckboxHidden
        self.isUserInteractionEnabled = canSelect
    }

    public var isCheckboxSelected: Bool {
        get { return false }
        set {}
    }
    private let avatarSize: CGFloat = 40
    private lazy var avatarView: BizAvatar = {
       let avatarView = BizAvatar()
        avatarView.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        })
        return avatarView
    }()
    private lazy var infoView: UIView = {
        var infoView = UIView()
        infoView.backgroundColor = .clear
        return infoView
    }()
    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        return nameLabel
    }()

    public private(set) var item: ChatChatterItem?

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(infoView)
        infoView.addSubview(avatarView)
        infoView.addSubview(nameLabel)
        infoView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.bottom.top.equalToSuperview()
        }
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        contentView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)
        self.isUserInteractionEnabled = false
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(_ item: ChatChatterItem, filterKey: String?, userResolver: UserResolver) {
        self.item = item
        avatarView.setAvatarByIdentifier(item.itemId, avatarKey: item.itemAvatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        nameLabel.text = item.itemName
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.setAvatarByIdentifier("", avatarKey: "")
        avatarView.image = nil
        nameLabel.text = nil
    }
}
// swiftlint:enable unused_setter_value
