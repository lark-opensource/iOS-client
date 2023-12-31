//
//  SettingDisplayFooter.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/27.
//

import Foundation
import ByteViewCommon

struct SettingDisplayFooter {
    let type: SettingDisplayFooterType
    var description: String
    var descriptionTextStyle: VCFontConfig = .bodyAssist
    var descriptionTextColor: UIColor = .ud.textPlaceholder
    var serviceTerms: String?
}

struct SettingDisplayFooterType: Hashable, CustomStringConvertible {
    let reuseIdentifier: String
    let footerViewType: UITableViewHeaderFooterView.Type
    var description: String { reuseIdentifier }

    init(reuseIdentifier: String, footerViewType: UITableViewHeaderFooterView.Type) {
        self.reuseIdentifier = reuseIdentifier
        self.footerViewType = footerViewType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(reuseIdentifier)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reuseIdentifier == rhs.reuseIdentifier
    }
}
