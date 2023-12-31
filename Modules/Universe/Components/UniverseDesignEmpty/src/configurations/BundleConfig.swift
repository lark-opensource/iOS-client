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
import UIKit

// swiftlint:disable all
class BundleConfig: NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/UniverseDesignEmpty", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()
    private static let UniverseDesignEmptyBundleURL = SelfBundle.url(forResource: "UniverseDesignEmpty", withExtension: "bundle")
    static let UniverseDesignEmptyBundle: Bundle? = { 
        if let bundleURL = UniverseDesignEmptyBundleURL {
            return Bundle(url: bundleURL)
        }
        return nil
    }()
}
 
open class EmptyBundleResources {
    static public func image(named: String) -> UIImage {
        return UIImage(named: named,
                       in: BundleConfig.UniverseDesignEmptyBundle,
                       compatibleWith: nil) ?? UIImage()
    }
}
// swiftlint:enable all
