//
//  FeedFilterSelectViews.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/7/5.
//

import Foundation
import LarkUIKit
import LarkOpenFeed
import UIKit

final class FeedFilterSelectCell: BaseTableViewCell {
    var item: FilterItemModel? {
        didSet {
            setCellInfo()
        }
    }

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.text = BundleI18n.LarkFeed.Lark_Feed_MessageFilter // 消息筛选器
        return label
    }()

    private var iconImageView = UIImageView()

    private func setCellInfo() {
        guard let currItem = self.item as? FilterItemModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = currItem.name
        iconImageView.image = Resources.icon_listCheckOutlined
    }

    private func setupViews() {
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(24)
        }
        iconImageView.isHidden = true
    }

    func setIconHidden(_ isHidden: Bool) {
        iconImageView.isHidden = isHidden
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
