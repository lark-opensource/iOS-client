//
//  ChatInfoReportCellAndItem.swift
//  LarkChat
//
//  Created by 李勇 on 2019/8/2.
//

import UIKit
import Foundation
import UniverseDesignIcon

// MARK: - 举报 - item
struct ChatInfoReportModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 举报 - item
final class ChatInfoReportCell: ChatInfoCell {
    private let container = UIView()
    private let titleLabel = UILabel()
    private let icon = UIImageView(image: UDIcon.reportOutlined.ud.withTintColor(UIColor.ud.textCaption))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.backgroundColor = UIColor.ud.bgFloatBase
        self.arrow.isHidden = true

        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.titleLabel.textColor = UIColor.ud.textCaption
        self.contentView.addSubview(self.container)
        self.container.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(20)
            make.top.equalTo(14)
        }

        self.container.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.top.right.bottom.equalToSuperview()
        }

        self.container.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.left.centerY.equalToSuperview()
            make.right.equalTo(titleLabel.snp.left).offset(-5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? ChatInfoReportModel else { return }
        self.titleLabel.text = item.title
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? ChatInfoReportModel {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
