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

// swiftlint:disable all
struct BundleResources {
    static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkListItemBundle, compatibleWith: nil) ?? UIImage()
    }
}
//swiftlint:enable all
