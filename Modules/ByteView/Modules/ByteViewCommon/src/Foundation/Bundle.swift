//
//  BundleConfig.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/8/18.
//

import Foundation

extension Bundle {
    static let current: Bundle = BundleConfig.SelfBundle
    static let localResources = BundleConfig.ByteViewCommonBundle
}

typealias I18n = BundleI18n.ByteViewCommon
