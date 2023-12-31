//
//  TeamTapCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/4.
//

import UIKit
import Foundation
import LarkUIKit

// MARK: - 点击 - viewModel
struct TeamTapCellViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle
    var attributedText: NSAttributedString
    var backgroundColor: UIColor?
    var tapHandler: TeamCellTapHandler
}

// MARK: - 点击 - cell
final class TeamTapCell: TeamBaseCell {
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        contentView.addSubview(label)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        titleLabel.textColor = UIColor.ud.functionDangerContentDefault
        titleLabel.textAlignment = .center
        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
            maker.height.equalTo(52)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? TeamTapCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        if let color = item.backgroundColor {
            contentView.backgroundColor = color
        }
        titleLabel.attributedText = item.attributedText
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = item as? TeamTapCellViewModel {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
