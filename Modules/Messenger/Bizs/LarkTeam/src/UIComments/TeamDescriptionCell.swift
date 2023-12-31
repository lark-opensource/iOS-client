//
//  TeamDescriptionCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/17.
//

import Foundation
import UIKit
import SnapKit
import LarkTag
import LarkCore
import LarkUIKit
import LarkBizAvatar
import LarkFeatureSwitch
import LarkMessengerInterface

// MARK: - 团队描述 - viewModel
struct TeamDescriptionCellViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle

    var title: String
    var description: String = ""
    var tapHandler: TeamCellTapHandler
}

// MARK: - 团队描述- cell
final class TeamDescriptionCell: TeamBaseCell {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        return label
    }()
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()
    private var arrow = UIImageView(image: Resources.right_arrow)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(arrow)

        titleLabel.snp.makeConstraints { (maker) in
            maker.top.left.equalTo(16)
        }
        descriptionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(5)
            maker.left.equalTo(titleLabel.snp.left)
            maker.bottom.right.equalTo(-16)
        }
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalTo(titleLabel.snp.centerY)
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? TeamDescriptionCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        descriptionLabel.text = item.description
        if descriptionLabel.text?.isEmpty ?? true {
            descriptionLabel.snp.updateConstraints { maker in
                maker.top.equalTo(titleLabel.snp.bottom).offset(0)
            }
        } else {
            descriptionLabel.snp.updateConstraints { maker in
                maker.top.equalTo(titleLabel.snp.bottom).offset(5)
            }
        }
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let infoItem = self.item as? TeamDescriptionCellViewModel {
            infoItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
