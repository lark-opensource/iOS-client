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
        if let url = Bundle.main.url(forResource: "Frameworks/LarkNotificationContentExtensionSDK", withExtension: "framework") {
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
    private static let LarkNotificationContentExtensionSDKBundleURL = SelfBundle.url(forResource: "LarkNotificationContentExtensionSDK", withExtension: "bundle")!
    private static let LarkNotificationContentExtensionSDKAutoBundleURL = SelfBundle.url(forResource: "LarkNotificationContentExtensionSDKAuto", withExtension: "bundle")!
    static let LarkNotificationContentExtensionSDKBundle = Bundle(url: LarkNotificationContentExtensionSDKBundleURL)!
    static let LarkNotificationContentExtensionSDKAutoBundle = Bundle(url: LarkNotificationContentExtensionSDKAutoBundleURL)!
}
// swiftlint:enable all
