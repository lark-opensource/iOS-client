//
//  TeamBaseCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/4.
//

import UIKit
import Foundation
import LarkUIKit

class TeamBaseCell: BaseTableViewCell, TeamCellProtocol {
    fileprivate(set) var separater: UIView = .init()

    var item: TeamCellViewModelProtocol? {
        didSet {
            setCellInfo()
        }
    }

    func setCellInfo() {
        assert(false, "没有实现对应的填充方法")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        separater = UIView()
        separater.backgroundColor = UIColor.ud.lineDividerDefault
        separater.isHidden = true
        contentView.addSubview(separater)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutSeparater(_ style: TeamCellSeparaterStyle) {
        if style == .none {
            separater.isHidden = true
        } else {
            separater.isHidden = false
            separater.snp.remakeConstraints { (maker) in
                maker.bottom.right.equalToSuperview()
                maker.height.equalTo(0.5)
                maker.left.equalToSuperview().offset(style == .half ? 16 : 0)
            }
        }
    }

    func updateAvailableMaxWidth(_ width: CGFloat) {}
    func cellForRowTask() {}
}

final class TeamSectionHeaderView: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = false
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    lazy var separator: UIView = {
        let separater = UIView()
        separater.backgroundColor = UIColor.ud.lineDividerDefault
        return separater
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBase
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: 14, left: 16, bottom: 2, right: 16))
            maker.height.equalTo(20)
        }

        contentView.addSubview(separator)
        separator.snp.remakeConstraints { (maker) in
            maker.left.bottom.right.equalToSuperview()
            maker.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TeamSectionFooterView: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.isHidden = false
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBase
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: 2, left: 16, bottom: 14, right: 16))
            maker.height.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
