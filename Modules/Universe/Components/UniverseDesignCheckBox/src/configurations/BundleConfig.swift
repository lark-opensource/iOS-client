//Warning: Do Not Edit It!
//Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
//Toolchains For EE
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

import Foundation
import UIKit
import UniverseDesignIcon

// swiftlint:disable all
class BundleConfig: NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/UniverseDesignCheckBox", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()
    private static let UniverseDesignCheckBoxBundleURL = SelfBundle.url(forResource: "UniverseDesignCheckBox", withExtension: "bundle")!
    static let UniverseDesignCheckBoxBundle = Bundle(url: UniverseDesignCheckBoxBundleURL)!
}

class BundleResources {
    static func image(named: String) -> UIImage {
        return UIImage(named: named,
                       in: BundleConfig.UniverseDesignCheckBoxBundle,
                       compatibleWith: nil) ?? UIImage()
    }

    static let multiple = UDIcon.getIconByKey(.checkOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill)
    static let single = BundleResources.image(named: "single")
    static let mixed = BundleResources.image(named: "mixed")
    static let list = UDIcon.getIconByKey(.listCheckOutlined, iconColor: UIColor.ud.primaryContentDefault)
    static let disabledlist = UDIcon.getIconByKey(.listCheckOutlined, iconColor: UIColor.ud.iconDisabled)
}
// swiftlint:enable all
