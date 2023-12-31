//
//  MailGroupInfoCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/19.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignIcon

enum SeparaterStyle {
    /// 将会根据 Cell 位置自动设置分割线
    case auto
    /// 没有分割线
    case none
}

class MailGroupInfoCell: BaseTableViewCell {
    fileprivate(set) var separater: UIView = .init()
    fileprivate(set) var arrow: UIImageView = .init(image: nil)

    var item: GroupInfoCellItem? {
        didSet {
            setCellInfo()
        }
    }

    func setCellInfo() {
        assert(false, "没有实现对应的填充方法")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgFloat
        separater = UIView()
        separater.backgroundColor = UIColor.ud.lineDividerDefault
        separater.isHidden = true
        contentView.addSubview(separater)

        arrow = UIImageView(image: UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate))
        arrow.tintColor = UIColor.ud.iconN3
        contentView.addSubview(arrow)
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutSeparater(_ style: SeparaterStyle) {
        if style == .none {
            separater.isHidden = true
        } else {
            separater.isHidden = false
            separater.snp.remakeConstraints { (maker) in
                maker.bottom.right.equalToSuperview()
                maker.height.equalTo(0.5)
                maker.left.equalToSuperview().offset(16)
            }
        }
    }

    func updateAvailableMaxWidth(_ width: CGFloat) {}
}

final class MailGroupInfoSectionView: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = true
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgFloatBase
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: 14, left: 4, bottom: 2, right: 16))
            maker.height.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
