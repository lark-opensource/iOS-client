//
//  CreateVoteSwitchCell.swift
//  LarkVote
//
//  Created by Fan Hui on 2022/4/5.
//

import Foundation
import UIKit
import UniverseDesignColor
final class CreateVoteSwitchCell: CreateVoteBaseCell {
    let label: UILabel = UILabel()
    let switchBtn: UISwitch = UISwitch()

    func setupCellContent() {
        self.contentView.addSubview(label)
        self.label.snp.makeConstraints {
            $0.left.equalTo(16)
            $0.top.equalTo(13)
            $0.height.equalTo(22)
            $0.bottom.equalTo(-13)
        }
        self.contentView.addSubview(switchBtn)
        self.switchBtn.snp.makeConstraints {
            $0.bottom.equalTo(-10)
            $0.right.equalTo(-16)
            $0.top.equalTo(10)
            $0.height.equalTo(28)
        }
        self.switchBtn.onTintColor = UIColor.ud.color(51, 112, 255, 1)
    }

    public func updateCellContent(text: String) {
        self.label.text = text
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCellContent()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
