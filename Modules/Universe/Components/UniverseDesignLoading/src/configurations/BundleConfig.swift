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
class BundleConfig: NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/UniverseDesignLoading", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
            return Bundle.main
        }
    }()
    private static let UniverseDesignLoadingBundleURL = SelfBundle.url(forResource: "UniverseDesignLoading", withExtension: "bundle")!
    private static let UniverseDesignLoadingAutoBundleURL = SelfBundle.url(forResource: "UniverseDesignLoadingAuto", withExtension: "bundle")!
    static let UniverseDesignLoadingBundle = Bundle(url: UniverseDesignLoadingBundleURL)!
    static let UniverseDesignLoadingAutoBundle = Bundle(url: UniverseDesignLoadingAutoBundleURL)!
}
// swiftlint:enable all
