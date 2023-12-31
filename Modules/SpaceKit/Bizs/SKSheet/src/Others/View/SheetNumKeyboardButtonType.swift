//
//  SheetNumKeyboardButtonType.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/8.
//

import Foundation
import SKCommon
import SKResource
import UniverseDesignIcon

enum SheetNumKeyboardButtonType: String {
    // calc
    case currency = "¥"
    case pecent = "%"
    case slash = "/"
    case sign = "±"

    // digital
    case one = "1"
    case two = "2"
    case three = "3"
    case four = "4"
    case five = "5"
    case six = "6"
    case seven = "7"
    case eight = "8"
    case nine = "9"
    case zerozero = "00"
    case zero = "0"
    case point = "."

    // help
    case delete = "delete"
    case right = "right"
    case down = "down"

    func buttonImage() -> UIImage? {
        if self == .currency {
            return currencyImage()
        }
        let mapping: [String: UIImage] = [
            // 左一列
            SheetNumKeyboardButtonType.currency.rawValue: UDIcon.sheetCurrencyOutlined,
            SheetNumKeyboardButtonType.pecent.rawValue: UDIcon.sheetPercentOutlined,
            SheetNumKeyboardButtonType.slash.rawValue: UDIcon.sheetSlashOutlined,
            SheetNumKeyboardButtonType.sign.rawValue: UDIcon.sheetSignOutlined,
            // 中间数字
            SheetNumKeyboardButtonType.one.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_one,
            SheetNumKeyboardButtonType.two.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_two,
            SheetNumKeyboardButtonType.three.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_three,
            SheetNumKeyboardButtonType.four.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_four,
            SheetNumKeyboardButtonType.five.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_five,
            SheetNumKeyboardButtonType.six.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_six,
            SheetNumKeyboardButtonType.seven.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_seven,
            SheetNumKeyboardButtonType.eight.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_eight,
            SheetNumKeyboardButtonType.nine.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_nine,
            SheetNumKeyboardButtonType.zerozero.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_zerozero,
            SheetNumKeyboardButtonType.zero.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_zero,
            SheetNumKeyboardButtonType.point.rawValue: BundleResources.SKResource.Sheet.Keyboard.sheet_kb_point,
            // 右一列
            SheetNumKeyboardButtonType.delete.rawValue: UDIcon.deleteOutlined,
            SheetNumKeyboardButtonType.right.rawValue: UDIcon.insertRightOutlined,
            SheetNumKeyboardButtonType.down.rawValue: UDIcon.insertDownOutlined
        ]

        return mapping[self.rawValue]
    }

    func inputText() -> String? {
        switch self {
        case .currency:
            return currencySign()
        case .delete, .right, .down, .sign:
            return nil
        default:
            return self.rawValue
        }
    }

    private func currencySign() -> String {
        let lang = DocsSDK.currentLanguage
        switch lang {
        case .ja_JP, .zh_CN:
            return "¥"
        default:
            return "$"
        }
    }

    private func currencyImage() -> UIImage? {
        let lang = DocsSDK.currentLanguage
        switch lang {
        case .ja_JP, .zh_CN:
            return UDIcon.sheetCurrencyOutlined
        default:
            return UDIcon.sheetDollarOutlined
        }
    }
}
