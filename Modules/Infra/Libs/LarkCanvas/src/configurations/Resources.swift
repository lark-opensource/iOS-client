//
//  Resources.swift
//  LarkCanvas
//
//  Created by Saafo on 2021/2/18.
//

import UIKit
import Foundation
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkCanvasBundle, compatibleWith: nil) ?? UIImage()
    }
    static let iconUndo = UDIcon.undoOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let iconRedo = UDIcon.redoOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let iconSave = UDIcon.downloadOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let iconClear = UDIcon.clearOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let iconClose = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1)
}
