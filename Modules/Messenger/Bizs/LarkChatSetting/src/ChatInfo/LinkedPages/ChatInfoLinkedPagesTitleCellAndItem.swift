//
//  ChatInfoLinkedPagesTitleCellAndItem.swift
//  LarkChatSetting
//
//  Created by zhaojiachen on 2023/10/18.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

struct ChatInfoLinkedPagesTitleItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var totalCount: Int
    var tapHandler: ChatInfoTapHandler
}

final class ChatInfoLinkedPagesTitleCell: ChatInfoCell {

    static var maxTotalCount: Int { 3 }

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    private lazy var arrowView: UIImageView = {
        let arrowView = UIImageView()
        arrowView.image = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.textPlaceholder)
        return arrowView
    }()

    private lazy var countLabel: UILabel = {
        let countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = UIColor.ud.textPlaceholder
        return countLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        arrow.isHidden = true
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(arrowView)
        titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview().inset(15)
            make.left.equalTo(16)
        }
        arrowView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        countLabel.snp.makeConstraints { make in
            make.right.equalTo(arrowView.snp.left).offset(-4)
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(titleLabel.snp.right)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatInfoLinkedPagesTitleItem else {
            return
        }
        titleLabel.text = item.title
        if item.totalCount > Self.maxTotalCount {
            countLabel.isHidden = false
            arrowView.isHidden = false
            countLabel.text = "\(item.totalCount)"
        } else {
            countLabel.isHidden = true
            arrowView.isHidden = true
        }
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = self.item as? ChatInfoLinkedPagesTitleItem, item.totalCount > Self.maxTotalCount {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

struct ChatInfoLinkedPagesFooterItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
}

final class ChatInfoLinkedPagesFooterCell: ChatInfoCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        arrow.isHidden = true
        self.contentView.snp.makeConstraints { make in
            make.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatInfoLinkedPagesFooterItem else {
            return
        }
        layoutSeparater(item.style)
    }
}
