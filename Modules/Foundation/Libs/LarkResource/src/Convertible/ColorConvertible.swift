//
//  ColorConvertible.swift
//  LarkResource
//
//  Created by 李晨 on 2020/3/17.
//

import UIKit
import Foundation

extension UIColor: ResourceConvertible {
    public static var convertEntry: ConvertibleEntryProtocol = ConvertibleEntry<UIColor> { (result: MetaResource, _: OptionsInfoSet) throws -> UIColor in
        guard case let .number(value) = result.index.value else {
            throw ResourceError.transformFailed
        }
        let rgb = value.intValue
        let iAlpha = rgb & 0xFF
        let iBlue = (rgb >> 8) & 0xFF
        let iGreen = (rgb >> 16) & 0xFF
        let iRed = (rgb >> 24) & 0xFF
        return UIColor(
            red: CGFloat(iRed) / 255,
            green: CGFloat(iGreen) / 255,
            blue: CGFloat(iBlue) / 255,
            alpha: CGFloat(iAlpha) / 255
        )
    }
}
