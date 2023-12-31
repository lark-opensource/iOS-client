import UIKit
import Foundation
import UniverseDesignIcon

// swiftlint:disable all
public final class URLPreviewUDIcon {
    public static func getIconByKey(_ key: String, renderingMode: UIImage.RenderingMode = .automatic, iconColor: UIColor? = nil, size: CGSize? = nil) -> UIImage? {
        switch key {
        case "wiki-bitable_colorful":
            return UDIcon.getIconByKey(.fileBitableColorful, renderingMode: renderingMode, iconColor: iconColor, size: size)
        default:
            return UDIcon.getIconByString(key, renderingMode: renderingMode, iconColor: iconColor, size: size)
        }
    }
}
// swiftlint:enable all
