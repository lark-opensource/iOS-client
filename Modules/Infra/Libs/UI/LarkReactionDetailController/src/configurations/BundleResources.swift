// Warning: Do Not Edit It!
// Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
// Toolchains For EE
/*
*
*
*  ______ ______ _____        __
* |  ____|  ____|_   _|      / _|
* | |__  | |__    | |  _ __ | |_ _ __ __ _
* |  __| |  __|   | | | '_ \|  _| '__/ _` |
* | |____| |____ _| |_| | | | | | | | (_| |
* |______|______|_____|_| |_|_| |_|  \__,_|
*
*
*/
import UIKit
import Foundation
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(
            named: named,
            in: BundleConfig.LarkReactionDetailControllerBundle,
            compatibleWith: nil) ?? UIImage()
    }

    static let reactionDetailClose = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN3)

    public static let verticalLineImage = getVerticalLineImage()

    private static func getVerticalLineImage() -> UIImage {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 1, height: 16)
        let view = UIView()
        view.frame = CGRect(x: 0, y: 2, width: 1, height: 12)
        view.backgroundColor = UIColor.ud.lineDividerDefault
        containerView.addSubview(view)
        UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        containerView.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}
