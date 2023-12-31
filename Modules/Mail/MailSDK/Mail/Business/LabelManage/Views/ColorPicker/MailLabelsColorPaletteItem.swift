//
//  MailLabelsColorPaletteItem.swift
//  MailSDK
//
//  Created by majx on 2019/10/29.
//

import Foundation
import LarkUIKit
import UniverseDesignColorPicker

struct MailLabelsColorPaletteItem {
    enum ColorNames {
        case blue
        case lightBlue
        case purple
        case lightPurple
        case pink
        case lightPink
        case orange
        case redOrange
        case yellow
        case lime
        case green
        case teal
        case aqua
        case custom
    }

    var name: ColorNames
    var bgColor: UIColor
    var fontColor: UIColor
    var item: UDPaletteItem?
}
