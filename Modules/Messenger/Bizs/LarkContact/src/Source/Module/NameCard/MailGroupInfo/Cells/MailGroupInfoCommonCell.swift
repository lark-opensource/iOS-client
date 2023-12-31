//
//  MailGroupInfoCommonCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/21.
//

import UIKit
import Foundation

struct MailGroupInfoCommonModel: GroupInfoCellItem {
    var type: GroupInfoItemType
    var style: SeparaterStyle
    var title: String
    var descriptionText: String
    var enterAble: Bool
    var enterDetail: MailGroupInfoTapHandler
}

final class MailGroupInfoCommonCell: MailGroupInfoCell {
    fileprivate var titleLabel: UILabel = .init()
    fileprivate var descriptionLabel: UILabel = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalToSuperview().offset(13)
            maker.left.equalToSuperview().offset(16)
            maker.height.equalTo(22).priority(.high)
        }

        descriptionLabel = UILabel()
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.ud.textPlaceholder
        descriptionLabel.numberOfLines = 2
        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(titleLabel.snp.bottom).offset(4)
            maker.left.equalTo(titleLabel.snp.left)
            maker.right.equalToSuperview().offset(-79)
            maker.bottom.equalToSuperview().offset(-13)
        }

        arrow.isHidden = false

        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didClickEnter)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let model = item as? MailGroupInfoCommonModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        arrow.isHidden = !model.enterAble
        titleLabel.text = model.title
        layoutSeparater(model.style)
        setCell(descriptionText: model.descriptionText)
    }

    private func setCell(descriptionText: String = "") {
        titleLabel.alpha = alpha
        descriptionLabel.text = descriptionText
        if descriptionText.isEmpty {
            descriptionLabel.isHidden = true
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.left.right.equalToSuperview()
                    .inset(UIEdgeInsets(top: 15, left: 16, bottom: 0, right: 75))
                maker.height.equalTo(22.5).priority(.high)
            }
            descriptionLabel.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-12.5)
            }
        } else {
            descriptionLabel.isHidden = false
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.equalToSuperview().offset(12.5)
                maker.left.equalToSuperview().offset(16)
                maker.right.equalToSuperview().offset(-44)
            }
            descriptionLabel.snp.updateConstraints { (make) in
                make.bottom.equalToSuperview().offset(-11.5)
            }
        }
    }

    @objc
    func didClickEnter() {
        guard let item = item as? MailGroupInfoCommonModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        item.enterDetail(self)
    }
}
