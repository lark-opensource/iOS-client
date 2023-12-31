//
//  DetailCustomFields.swift
//  Todo
//
//  Created by baiyantao on 2023/4/19.
//

import Foundation
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignTag
import UniverseDesignFont

struct DetailCustomFields { }

// MARK: - Const

extension DetailCustomFields {
    static let headerHeight: CGFloat = 56
    static let cellHeight: CGFloat = 40

    static let tagsPanelCellHeight: CGFloat = 48
    static let tagsPanelMaxHeight: CGFloat = 370

    static let contentMaxHeight: CGFloat = 300

    static let hMargin: CGFloat = 16.0
}

// MARK: - Logger

extension DetailCustomFields {
    static let logger = Logger.log(DetailCustomFields.self, category: "Todo.DetailCustomFields")
}

// MARK: - Record & Activity Record

extension DetailCustomFields {

    private static let comma = I18N.Todo_Task_Comma

    static func fieldVal2RecordText(_ field: Rust.TaskField, _ fieldVal: Rust.TaskFieldValue) -> String {
        let recordText: String
        switch fieldVal.value {
        case .numberFieldValue(let value):
            recordText = value.value
        case .memberFieldValue(let value):
            recordText = value.value.map(\.user.name).joined(separator: Self.comma)
        case .datetimeFieldValue(let value):
            guard value.value != 0 else {
                recordText = ""
                break
            }
            let formatter = DetailCustomFields.dateSettings2Formatter(
                field.settings.datetimeFieldSettings
            )
            let date = Date(timeIntervalSince1970: TimeInterval(value.value / 1000))
            recordText = formatter.string(from: date)
        case .singleSelectFieldValue(let value):
            let options = field.settings.singleSelectFieldSettings.options
            guard let option = options.first(where: { $0.guid == value.value }) else {
                recordText = ""
                assertionFailure()
                break
            }
            recordText = option.name
        case .multiSelectFieldValue(let value):
            let guid2Option = Dictionary(
                field.settings.multiSelectFieldSettings.options.map { ($0.guid, $0) },
                uniquingKeysWith: { (first, _) in first }
            )
            let options = value.value.compactMap { guid2Option[$0] }
            recordText = options.sorted { $0.rank < $1.rank }.map(\.name).joined(separator: Self.comma)
        case .textFieldValue(let value):
            recordText = value.value.richText.lc.summerize()
        @unknown default:
            recordText = ""
            assertionFailure()
        }
        return recordText.isEmpty ? "-" : recordText
    }
}

// MARK: - Date format

extension DetailCustomFields {
    static func dateSettings2Formatter(_ settings: Rust.DateFieldSettings) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        switch settings.format {
        case .yyyyMmDdDash:
            formatter.dateFormat = "yyyy-MM-dd"
        case .yyyyMmDdSlash:
            formatter.dateFormat = "yyyy/MM/dd"
        case .mmDdYyyySlash:
            formatter.dateFormat = "MM/dd/yyyy"
        case .ddMmYyyySlash:
            formatter.dateFormat = "dd/MM/yyyy"
        case .default:
            formatter.dateFormat = "yyyy-MM-dd"
        @unknown default:
            assertionFailure()
            formatter.dateFormat = "yyyy-MM-dd"
        }
        return formatter
    }
}

// MARK: - Number format

extension DetailCustomFields {
    static func double2String(_ content: Double, decimalCount: Int32) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        formatter.groupingSeparator = ""
        formatter.maximumFractionDigits = Int(decimalCount)
        return formatter.string(from: NSNumber(value: content))
    }

    static func double2String(_ content: Double, settings: Rust.NumberFieldSettings) -> String? {
        var content = content
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.roundingMode = .halfUp
        switch settings.separator {
        case .no:
            formatter.groupingSeparator = ""
        case .thousand:
            formatter.groupingSeparator = ","
        @unknown default:
            formatter.groupingSeparator = ""
        }
        formatter.maximumFractionDigits = Int(settings.decimalCount)
        formatter.minimumFractionDigits = Int(settings.decimalCount)
        var prefix: String = ""
        var suffix: String = ""
        switch settings.format {
        case .normal:
            break
        case .percentage:
            content *= 100
            suffix = "%"
        case .cny:
            formatter.numberStyle = .currency
            formatter.locale = Locale.zh_CN
        case .usd:
            formatter.numberStyle = .currency
            formatter.locale = Locale.en_US
        case .customSymbol:
            switch settings.customSymbolPosition {
            case .left:
                prefix = settings.customSymbolChars
            case .right:
                suffix = settings.customSymbolChars
            @unknown default:
                assertionFailure()
            }
        @unknown default:
            assertionFailure()
        }
        guard let result = formatter.string(from: NSNumber(value: content)) else { return nil }
        return "\(prefix)\(result)\(suffix)"
    }
}

// MARK: - Tags

extension DetailCustomFields {
    static func initTagListView() -> UDTagListView {
        let view = UDTagListView()
        view.isUserInteractionEnabled = false
        view.tagBackgroundColor = UIColor.ud.udtokenTagBgGreen
        view.paddingX = 4
        view.paddingY = 4
        view.marginX = 8
        view.marginY = 8
        view.tagCornerRadius = 4
        view.textFont = UDFont.systemFont(ofSize: 14)
        view.textColor = UIColor.ud.textTitle
        view.tagLineBreakMode = .byTruncatingTail
        return view
    }

    static func options2TagViews(
        _ options: [Rust.SelectFieldOption],
        with view: UDTagListView
    ) -> [UDTagListItemView] {
        return options.sorted { $0.rank < $1.rank }.compactMap {
            guard let token = DetailCustomFields.index2ColorToken($0.colorIndex),
                  let textColor = DetailCustomFields.getColor(by: token.textColor),
                  let backgroundColor = DetailCustomFields.getColor(by: token.color) else {
                assertionFailure()
                return nil
            }
            let tagView = view.createNewTagView("")
            tagView.contentHorizontalAlignment = .left
            var attributes: [NSAttributedString.Key: Any] = [
                .font: UDFont.systemFont(ofSize: 14),
                .foregroundColor: textColor
            ]
            if $0.isHidden {
                attributes[.strikethroughStyle] = NSNumber(value: 1)
            }
            tagView.setAttributedTitle(
                NSAttributedString(
                    string: $0.name,
                    attributes: attributes
                ),
                for: UIControl.State()
            )
            tagView.tagBackgroundColor = backgroundColor
            return tagView
        }
    }
}

// MARK: - Color

extension DetailCustomFields {

    static func getColor(by name: String) -> UIColor? {
        let result = basicColorDic[name] ?? UDColor.getValueByBizToken(token: name)
        assert(result != nil)
        return result
    }

    static func index2ColorToken(_ index: Int32) -> ColorToken? {
        guard index >= 0, index < colorTokens.count else {
            assertionFailure()
            return nil
        }
        return colorTokens[Int(index)]
    }

    struct ColorToken {
        let color: String
        let textColor: String
        let iconColor: String
        let iconHover: String
        init(_ color: String, _ textColor: String, _ iconColor: String, _ iconHover: String) {
            self.color = color
            self.textColor = textColor
            self.iconColor = iconColor
            self.iconHover = iconHover
        }
    }

    // 每列 5 个，共 11 列
    // https://bytedance.feishu.cn/docx/TK6qdNnGSowcWwxQ6pBcADeWn0A 末尾
    private static let colorTokens: [ColorToken] = [
        // 1
        ColorToken("R100", "text-title", "N900-70", "N900"),
        ColorToken("R200", "text-title", "N900-70", "N900"),
        ColorToken("R300", "text-title", "N900-70", "N900"),
        ColorToken("R500", "N00", "N00-70", "N00"),
        ColorToken("R700", "N00", "N00-70", "N00"),
        // 2
        ColorToken("O100", "text-title", "N900-70", "N900"),
        ColorToken("O200", "text-title", "N900-70", "N900"),
        ColorToken("O300", "text-title", "N900-70", "N900"),
        ColorToken("O500", "N00", "N00-70", "N00"),
        ColorToken("O700", "N00", "N00-70", "N00"),
        // 3
        ColorToken("Y100", "text-title", "N900-70", "N900"),
        ColorToken("Y200", "text-title", "N900-70", "N900"),
        ColorToken("Y300", "static-black", "N900-70", "N900"),
        ColorToken("Y500", "N00", "N00-70", "N00"),
        ColorToken("Y700", "N00", "N00-70", "N00"),
        // 4
        ColorToken("L100", "text-title", "N900-70", "N900"),
        ColorToken("L200", "text-title", "N900-70", "N900"),
        ColorToken("L300", "static-black", "N900-70", "N900"),
        ColorToken("L500", "N00", "N00-70", "N00"),
        ColorToken("L700", "N00", "N00-70", "N00"),
        // 5
        ColorToken("G100", "text-title", "N900-70", "N900"),
        ColorToken("G200", "text-title", "N900-70", "N900"),
        ColorToken("G300", "text-title", "N900-70", "N900"),
        ColorToken("G500", "N00", "N00-70", "N00"),
        ColorToken("G700", "N00", "N00-70", "N00"),
        // 6
        ColorToken("T100", "text-title", "N900-70", "N900"),
        ColorToken("T200", "text-title", "N900-70", "N900"),
        ColorToken("T300", "text-title", "N900-70", "N900"),
        ColorToken("T500", "N00", "N00-70", "N00"),
        ColorToken("T700", "N00", "N00-70", "N00"),
        // 7
        ColorToken("W100", "text-title", "N900-70", "N900"),
        ColorToken("W200", "text-title", "N900-70", "N900"),
        ColorToken("W300", "text-title", "N900-70", "N900"),
        ColorToken("W500", "N00", "N00-70", "N00"),
        ColorToken("W700", "N00", "N00-70", "N00"),
        // 8
        ColorToken("B100", "text-title", "N900-70", "N900"),
        ColorToken("B200", "text-title", "N900-70", "N900"),
        ColorToken("B300", "text-title", "N900-70", "N900"),
        ColorToken("B500", "N00", "N00-70", "N00"),
        ColorToken("B700", "N00", "N00-70", "N00"),
        // 9
        ColorToken("C100", "text-title", "N900-70", "N900"),
        ColorToken("C200", "text-title", "N900-70", "N900"),
        ColorToken("C300", "text-title", "N900-70", "N900"),
        ColorToken("C500", "static-white", "N900-70", "N900"),
        ColorToken("C700", "N00", "N00-70", "N00"),
        // 10
        ColorToken("P100", "text-title", "N900-70", "N900"),
        ColorToken("P200", "text-title", "N900-70", "N900"),
        ColorToken("P300", "text-title", "N900-70", "N900"),
        ColorToken("P500", "N00", "N00-70", "N00"),
        ColorToken("P700", "N00", "N00-70", "N00"),
        // 11
        ColorToken("N100", "text-title", "N900-70", "N900"),
        ColorToken("N200", "text-title", "N900-70", "N900"),
        ColorToken("N300", "text-title", "N900-70", "N900"),
        ColorToken("N500", "N00", "N00-70", "N00"),
        ColorToken("N700", "N00", "N00-70", "N00")
    ]

    // UDColor 不支持用字符串的形式取一些原始颜色，因此这里做一层封装
    private static let basicColorDic: [String: UIColor] = [
        "R100": UDColor.R100, "R200": UDColor.R200, "R300": UDColor.R300, "R500": UDColor.R500, "R700": UDColor.R700,
        "O100": UDColor.O100, "O200": UDColor.O200, "O300": UDColor.O300, "O500": UDColor.O500, "O700": UDColor.O700,
        "Y100": UDColor.Y100, "Y200": UDColor.Y200, "Y300": UDColor.Y300, "Y500": UDColor.Y500, "Y700": UDColor.Y700,
        "L100": UDColor.L100, "L200": UDColor.L200, "L300": UDColor.L300, "L500": UDColor.L500, "L700": UDColor.L700,
        "G100": UDColor.G100, "G200": UDColor.G200, "G300": UDColor.G300, "G500": UDColor.G500, "G700": UDColor.G700,
        "T100": UDColor.T100, "T200": UDColor.T200, "T300": UDColor.T300, "T500": UDColor.T500, "T700": UDColor.T700,
        "W100": UDColor.W100, "W200": UDColor.W200, "W300": UDColor.W300, "W500": UDColor.W500, "W700": UDColor.W700,
        "B100": UDColor.B100, "B200": UDColor.B200, "B300": UDColor.B300, "B500": UDColor.B500, "B700": UDColor.B700,
        "C100": UDColor.C100, "C200": UDColor.C200, "C300": UDColor.C300, "C500": UDColor.C500, "C700": UDColor.C700,
        "P100": UDColor.P100, "P200": UDColor.P200, "P300": UDColor.P300, "P500": UDColor.P500, "P700": UDColor.P700,
        "N100": UDColor.N100, "N200": UDColor.N200, "N300": UDColor.N300, "N500": UDColor.N500, "N700": UDColor.N700,
        "N900": UDColor.N900, "N00": UDColor.N00
    ]
}
