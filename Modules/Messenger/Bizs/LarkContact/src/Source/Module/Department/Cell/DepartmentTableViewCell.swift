//
//  DepartmentTableViewCell.swift
//  Lark
//
//  Created by zc09v on 2017/7/23.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import SnapKit
import LarkUIKit

final class DepartmentTableViewCell: UITableViewCell {
    private lazy var departmentIconView: UIImageView = UIImageView()
    private var departmentLabel: UILabel = .init()
    private var arrowimageView: UIImageView = .init(image: nil)

    private lazy var highlightView: UIView = {
        let highlightView = UIView()
        highlightView.backgroundColor = UIColor.ud.fillHover
        highlightView.layer.cornerRadius = IGLayer.commonHighlightCellRadius
        highlightView.isHidden = true
        return highlightView
    }()

    private var departmentUserCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()
        self.selectionStyle = .none

        contentView.addSubview(highlightView)
        highlightView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(1.0)
            make.bottom.equalToSuperview().offset(-1.0)
            make.left.equalToSuperview().offset(8.0)
            make.right.equalToSuperview().offset(-6.0)
        }

        departmentIconView.image = Resources.department_picker_default_icon
        self.contentView.addSubview(departmentIconView)
        departmentIconView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.iconWidth)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(Layout.itemSpace)
        }

        arrowimageView = UIImageView()
        arrowimageView.image = Resources.mine_right_arrow
        self.contentView.addSubview(arrowimageView)
        arrowimageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(13)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-Layout.itemSpace)
        }

        let departmentContainer = UIView()
        contentView.addSubview(departmentContainer)
        departmentContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(departmentIconView.snp.right).offset(Layout.itemSpace)
            make.right.equalTo(arrowimageView.snp.left).offset(-Layout.itemSpace)
        }

        departmentLabel = UILabel()
        departmentLabel.font = UIFont.systemFont(ofSize: Layout.itemSpace)
        departmentLabel.textColor = UIColor.ud.textTitle
        departmentContainer.addSubview(departmentLabel)

        departmentContainer.addSubview(departmentUserCountLabel)

        departmentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalTo(departmentUserCountLabel.snp.left)
        }

        departmentUserCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        departmentUserCountLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(departmentLabel.snp.right)
            make.right.lessThanOrEqualToSuperview()
        }

//        self.lu.addBottomBorder(leading: 16, trailing: 0, color: UIColor.ud.lineDividerDefault)
    }

    func set(departmentName: String, userCount: Int32, isShowMemberCount: Bool) {
        departmentUserCountLabel.text = isShowMemberCount ? "(\(userCount))" : ""
        departmentLabel.text = departmentName
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        self.highlightView.isHidden = !highlighted
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DepartmentTableViewCell {
    struct Layout {
        static let itemSpace: CGFloat = 16
        static let iconWidth: CGFloat = 40
    }
}
