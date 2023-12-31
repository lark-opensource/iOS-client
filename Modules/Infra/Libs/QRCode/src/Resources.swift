//
//  File.swift
//  QRCode
//
//  Created by SuPeng on 4/16/19.
//

import UIKit
import Foundation
import UniverseDesignIcon
// swiftlint:disable identifier_name
final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.QRCodeBundle, compatibleWith: nil) ?? UIImage()
    }

    static let scanning = Resources.image(named: "scanning")
    static let navigation_back_white_cross = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let navigation_back_white_light = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let qrscan_album = Resources.image(named: "qrcode_album")
    static let qrcode_scanning = Resources.image(named: "qr_scanning")
    static let light = Resources.image(named: "qrcode_light")
    static let arrow = Resources.image(named: "qrcode_arrow")
}
// swiftlint:enable identifier_name
