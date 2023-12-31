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

import Foundation

// swiftlint:disable all
final class BundleConfig : NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/LarkBadge", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()
    private static let LarkBadgeBundleURL = SelfBundle.url(forResource: "LarkBadge", withExtension: "bundle")!
    private static let LarkBadgeAutoBundleURL = SelfBundle.url(forResource: "LarkBadgeAuto", withExtension: "bundle")!
    static let LarkBadgeBundle = Bundle(url: LarkBadgeBundleURL)!
    static let LarkBadgeAutoBundle = Bundle(url: LarkBadgeAutoBundleURL)!
}
// swiftlint:enable all
