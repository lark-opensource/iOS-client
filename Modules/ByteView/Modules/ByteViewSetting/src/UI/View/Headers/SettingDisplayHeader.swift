//
//  SettingDisplayHeader.swift
//  ByteViewSetting
//
//  Created by liurundong.henry on 2023/10/27.
//

import Foundation
import ByteViewCommon

struct SettingDisplayHeader {
    let type: SettingDisplayHeaderType
    var title: String
    let titleStyle: Style = .normal
    var titleTextStyle: VCFontConfig = .bodyAssist
    var description: String?
    var descriptionTextStyle: VCFontConfig = .r_14_22
    var serviceTerms: String?

    enum Style: String, CustomStringConvertible {
        case normal
        case error

        var color: UIColor {
            switch self {
            case .normal:
                return .ud.textPlaceholder
            case .error:
                return .ud.functionDangerContentDefault
            }
        }

        var description: String { rawValue }
    }
}

struct SettingDisplayHeaderType: Hashable, CustomStringConvertible {
    let reuseIdentifier: String
    let headerViewType: UITableViewHeaderFooterView.Type
    var description: String { reuseIdentifier }

    init(reuseIdentifier: String, headerViewType: UITableViewHeaderFooterView.Type) {
        self.reuseIdentifier = reuseIdentifier
        self.headerViewType = headerViewType
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(reuseIdentifier)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reuseIdentifier == rhs.reuseIdentifier
    }
}

struct SettingDisplayHeaderLayoutDefines {
    static let horizontalEdgeInsets: CGFloat = 16.0
}
