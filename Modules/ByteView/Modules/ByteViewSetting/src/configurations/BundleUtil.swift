//
//  BundleUtil.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/12.
//

import Foundation

typealias I18n = BundleI18n.ByteViewSetting

extension Bundle {
    static let current: Bundle = BundleConfig.SelfBundle
    static let settingResources = BundleConfig.ByteViewSettingBundle
}
