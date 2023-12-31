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
final class BundleConfig: NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/LarkLaunchGuide", withExtension: "framework") {
            return Bundle(url: url)!
        } else {
          // 单测会有问题，所以DEBUG模式不动
          #if DEBUG
            return Bundle(for: BundleConfig.self)
          #else
            return Bundle.main
          #endif
        }
    }()
    private static let LarkLaunchGuideBundleURL = SelfBundle.url(forResource: "LarkLaunchGuide", withExtension: "bundle")!
    private static let LarkLaunchGuideAutoBundleURL = SelfBundle.url(forResource: "LarkLaunchGuideAuto", withExtension: "bundle")!
    static let LarkLaunchGuideBundle = Bundle(url: LarkLaunchGuideBundleURL)!
    static let LarkLaunchGuideAutoBundle = Bundle(url: LarkLaunchGuideAutoBundleURL)!
}
// swiftlint:enable all
