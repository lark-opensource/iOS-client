//
//  MailLabelColorConfig.swift
//  MailSDK
//
//  Created by majx on 2019/10/29.
//

import Foundation
import UniverseDesignColorPicker

protocol MailLabelColorConfig {
    var paletteItems: [MailLabelsColorPaletteItem] { get }
}

struct MailLabelDefultColorConfig {

    func defaultConfig() -> UDColorPickerConfig {
        let paletteItems: [UDPaletteItem] = colorItems.map({ UDPaletteItem(color: $0) })
        return UDColorPickerConfig(models: [UDPaletteModel(category: .basic, title: "", items: paletteItems)],
                                   backgroudColor: ModelViewHelper.listColor())
    }

    var bgColorHexItems: [String] {
        return MailLabelTransformer.LabelColorType.allCases.map { $0.bgColorValue() }
    }

    var colorItems: [UIColor] {
        return pickerColorMap.map({ $0.0 })
    }

    var pickerColorMap: [(UIColor, UIColor)] {
        return MailLabelTransformer.LabelColorType.allCases.reduce([]) { result, type in
            return result + [(type.displayPickerColor(), type.displayBgColor())]
        }
    }

    func findColorTypeWithPickerColor(_ pickerColor: UIColor) -> MailLabelTransformer.LabelColorType {
        for item in MailLabelTransformer.LabelColorType.allCases where item.displayPickerColor().hex6 == pickerColor.hex6 {
            return item
        }
        return MailLabelTransformer.LabelColorType.blue
    }

    func pickerMapToBgColor(_ pickerColor: UIColor) -> UIColor {
        for item in MailLabelTransformer.LabelColorType.allCases where item.displayPickerColor().hex6 == pickerColor.hex6 {
            return item.displayBgColor()
        }

        return UIColor.ud.B100.alwaysLight
    }
}

/// old version2 color config
/// Yes, the designer change colors again 😢
struct MailLabelColorOldVersion2Config: MailLabelColorConfig {
    var paletteItems: [MailLabelsColorPaletteItem] = [
        MailLabelsColorPaletteItem(name: .lightBlue, bgColor: UIColor.ud.B100, fontColor: UIColor.ud.colorfulBlue),
        MailLabelsColorPaletteItem(name: .blue, bgColor: UIColor.ud.I100, fontColor: UIColor.ud.colorfulIndigo),
        MailLabelsColorPaletteItem(name: .purple, bgColor: UIColor.ud.P100, fontColor: UIColor.ud.colorfulPurple),
        MailLabelsColorPaletteItem(name: .lightPink, bgColor: UIColor.ud.V100, fontColor: UIColor.ud.colorfulViolet),
        MailLabelsColorPaletteItem(name: .pink, bgColor: UIColor.ud.C100, fontColor: UIColor.ud.colorfulCarmine),
        MailLabelsColorPaletteItem(name: .redOrange, bgColor: UIColor.ud.R100, fontColor: UIColor.ud.colorfulRed),
        MailLabelsColorPaletteItem(name: .orange, bgColor: UIColor.ud.O100, fontColor: UIColor.ud.colorfulOrange),
        MailLabelsColorPaletteItem(name: .yellow, bgColor: UIColor.ud.Y100, fontColor: UIColor.ud.colorfulYellow),
        MailLabelsColorPaletteItem(name: .lime, bgColor: UIColor.ud.L100, fontColor: UIColor.ud.colorfulLime),
        MailLabelsColorPaletteItem(name: .green, bgColor: UIColor.ud.G100, fontColor: UIColor.ud.colorfulGreen),
        MailLabelsColorPaletteItem(name: .teal, bgColor: UIColor.ud.T100, fontColor: UIColor.ud.colorfulTurquoise),
        MailLabelsColorPaletteItem(name: .aqua, bgColor: UIColor.ud.W100, fontColor: UIColor.ud.colorfulWathet)
    ]
}

/// old version color config
struct MailLabelColorOldVersionConfig: MailLabelColorConfig {
    var paletteItems: [MailLabelsColorPaletteItem] = [
        MailLabelsColorPaletteItem(name: .lightBlue, bgColor: UIColor.ud.B100, fontColor: UIColor.ud.B600),
        MailLabelsColorPaletteItem(name: .blue, bgColor: UIColor.ud.I100, fontColor: UIColor.ud.I600),
        MailLabelsColorPaletteItem(name: .purple, bgColor: UIColor.ud.P100, fontColor: UIColor.ud.P600),
        MailLabelsColorPaletteItem(name: .lightPink, bgColor: UIColor.ud.V100, fontColor: UIColor.ud.V600),
        MailLabelsColorPaletteItem(name: .pink, bgColor: UIColor.ud.C100, fontColor: UIColor.ud.C600),
        MailLabelsColorPaletteItem(name: .redOrange, bgColor: UIColor.ud.R100, fontColor: UIColor.ud.R600),
        MailLabelsColorPaletteItem(name: .orange, bgColor: UIColor.ud.O100, fontColor: UIColor.ud.O600),
        MailLabelsColorPaletteItem(name: .yellow, bgColor: UIColor.ud.Y100, fontColor: UIColor.ud.Y600),
        MailLabelsColorPaletteItem(name: .lime, bgColor: UIColor.ud.L100, fontColor: UIColor.ud.L600),
        MailLabelsColorPaletteItem(name: .green, bgColor: UIColor.ud.G100, fontColor: UIColor.ud.G600),
        MailLabelsColorPaletteItem(name: .teal, bgColor: UIColor.ud.T100, fontColor: UIColor.ud.T600),
        MailLabelsColorPaletteItem(name: .aqua, bgColor: UIColor.ud.W100, fontColor: UIColor.ud.W600)
    ]
}
