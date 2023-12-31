//
//  SettingDisplaySection.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/2/28.
//

import Foundation
import UniverseDesignColor
import ByteViewCommon

struct SettingDisplaySection {
    let group: SettingDisplayGroup
    var header: SettingDisplayHeader?
    var footer: SettingDisplayFooter?
    var rows: [SettingDisplayRow]
}

struct SettingDisplayHeaderFooter {
    let title: String
    let style: Style
    var textStyle: VCFontConfig = .bodyAssist

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

struct SettingDisplayHeaderFooterType: Hashable, CustomStringConvertible {
    let reuseIdentifier: String
    var description: String { reuseIdentifier }

    init(reuseIdentifier: String) {
        self.reuseIdentifier = reuseIdentifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(reuseIdentifier)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reuseIdentifier == rhs.reuseIdentifier
    }
}

struct SettingDisplayRow {
    let item: SettingDisplayItem
    let cellType: SettingCellType
    var title: String
    var subtitle: String?
    var serviceTerms: String?
    var useLKLabel: Bool?
    var accessoryText: String?
    var cellStyle: SettingCellStyle = .insetCorner
    /// 用于含开关的cell，比如checkbox/switch
    var isOn = false
    var isEnabled = true

    /// 显示左侧view，默认为true
    /// - checkbox: UDCheckBox
    var showsLeftView = true
    /// 显示右侧view，默认为true
    /// - goto/checkbox: accessoryLabel和disclosureIndicator
    /// - switch: switchControl
    /// - checkmark: checkmarkIcon
    var showsRightView = true
    var attributedTitle: (() -> NSAttributedString?)?

    /// 是否自动跳转
    var autoJump: Bool = false

    var data: [String: Any] = [:]

    var action: ((SettingRowActionContext) -> Void)?
}

struct SettingCellType: Hashable, CustomStringConvertible {
    let reuseIdentifier: String
    let cellType: UITableViewCell.Type
    let supportSelection: Bool
    init(_ reuseIdentifier: String, cellType: UITableViewCell.Type, supportSelection: Bool = false) {
        self.reuseIdentifier = reuseIdentifier
        self.cellType = cellType
        self.supportSelection = supportSelection
    }

    var description: String { reuseIdentifier }

    func hash(into hasher: inout Hasher) {
        hasher.combine(reuseIdentifier)
    }

    static func == (lhs: SettingCellType, rhs: SettingCellType) -> Bool {
        lhs.reuseIdentifier == rhs.reuseIdentifier
    }
}

extension Array where Element == SettingDisplaySection {
    func findIndexPath(for item: SettingDisplayItem) -> IndexPath? {
        for (i, section) in self.enumerated() {
            for (j, row) in section.rows.enumerated() {
                if row.item == item {
                    return IndexPath(row: j, section: i)
                }
            }
        }
        return nil
    }

    mutating func updateRow(_ row: SettingDisplayRow, at indexPath: IndexPath) {
        self[indexPath.section].rows[indexPath.row] = row
    }
}
