//
//  CardSettingTableViewCell.swift
//  Moment
//
//  Created by ByteDance on 2022/6/27.
//
import Foundation
import LarkUIKit
import UIKit

final class CardMomentSettingItem: MomentSettingItem {
    var type: MomentSettingItemType = .nickNamce
    var cellIdentifier: String = CardSettingTableViewCell.lu.reuseIdentifier
    var title: String
    var subtitleLabel: String
    init(title: String, subtitleLabel: String) {
        self.title = title
        self.subtitleLabel = subtitleLabel
    }
}

final class CardSettingTableViewCell: BaseTableViewCell, MomentSettingTableViewCell {
    private(set) var settingItem: MomentSettingItem?
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        /// 设置抗压缩优先级更高，防止两个label接触时被压缩
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return titleLabel
    }()
    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.textColor = UIColor.ud.textPlaceholder
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.numberOfLines = 1
        subtitleLabel.lineBreakMode = .byTruncatingTail
        return subtitleLabel
    }()
    private lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.image = Resources.momentsRightOutlined
        return icon
    }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        /// 箭头icon
        self.contentView.addSubview(self.icon)
        self.icon.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        /// 标题
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        /// 花名名片名称
        self.contentView.addSubview(self.subtitleLabel)
        self.subtitleLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-36)
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(titleLabel.snp.right)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setItem(_ item: MomentSettingItem?) {
        guard let settingItem = item as? CardMomentSettingItem else {
            assertionFailure("item type error")
            return
        }
        self.settingItem = settingItem
        self.titleLabel.text = settingItem.title
        self.subtitleLabel.text = settingItem.subtitleLabel
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
