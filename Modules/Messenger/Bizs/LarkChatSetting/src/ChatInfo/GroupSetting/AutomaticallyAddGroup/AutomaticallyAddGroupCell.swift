//
//  AutomaticallyAddGroupCell.swift
//  LarkChatSetting
//
//  Created by Yaoguoguo on 2023/5/23.
//

import Foundation
import LarkUIKit
import UniverseDesignFont

final class AutomaticallyAddGroupCell: BaseSettingCell {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private var ruleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 3
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.isUserInteractionEnabled = false

        self.addSubview(titleLabel)
        self.addSubview(ruleLabel)

        titleLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }

        ruleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setRule(order: Int?, refName: String) {
        if let orderName = order {
            titleLabel.text = BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_RuleNo_Title(orderName)
        } else {
            titleLabel.text = BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_RuleNo_Title("")
        }
        ruleLabel.text = calculateText(refName)
    }

    func calculateText(_ refName: String) -> String {
        let numberOfLine = numberOfLine(refName)

        guard numberOfLine > 3 else { return BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_RuleDetail_Text(refName) }

        var left = 0
        var mid = 0
        var right = refName.count - 1

        while right > left {
            let rightName = refName[0...right]
            let rightNumberOfLine = self.numberOfLine(rightName)
            guard rightNumberOfLine > 3 else { return BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_RuleDetail_Text(rightName) }

            mid = (right - left) / 2 + left
            let newName = refName[0...mid]
            let numberOfLine = self.numberOfLine(newName)
            if numberOfLine <= 3 {
                let rightMidName = refName[0...(mid + 1)]
                let rightLine = self.numberOfLine(rightMidName)
                if rightLine > 3 {
                    var lastName = newName.substring(to: newName.count - 4) + "..."
                    return BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_RuleDetail_Text(lastName)
                } else {
                    left = mid + 1
                }
            } else {
                right = mid - 1
            }
        }
        return BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_RuleDetail_Text(refName)
    }

    func numberOfLine(_ name: String) -> Int {
        let text = BundleI18n.LarkChatSetting.Lark_GroupSettings_AutoJoin_RuleDetail_Text(name)
        let height = text.getHeight(withConstrainedWidth: self.frame.width, font: ruleLabel.font)
        let numberOfLine: Int = Int(height / ruleLabel.font.lineHeight)

        return numberOfLine
    }
}
