//
//  Bundle.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/17.
//

import Foundation
import ByteViewCommon

typealias I18n = BundleI18n.ByteViewTab
typealias CommonResources = ByteViewCommon.BundleResources.ByteViewCommon.Common

extension Bundle {
    static let current = BundleConfig.SelfBundle
    static let localResources = BundleConfig.ByteViewTabBundle

    var shortVersion: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
