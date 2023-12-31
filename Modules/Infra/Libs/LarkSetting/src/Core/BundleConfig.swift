//
//  BundleConfig.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/3.
//

// swiftlint:disable all
import Foundation
final class BundleConfig: NSObject {
    static let SelfBundle: Bundle = {
        if let url = Bundle.main.url(forResource: "Frameworks/LarkSetting", withExtension: "framework") {
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
    private static let LarkSettingBundleURL = SelfBundle.url(forResource: "LarkSetting", withExtension: "bundle")!
    static let LarkSettingBundle = Bundle(url: LarkSettingBundleURL)!
}
// swiftlint:enable all
