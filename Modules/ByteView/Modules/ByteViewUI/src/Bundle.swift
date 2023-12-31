//
//  Bundle.swift
//  ByteViewUI
//
//  Created by kiri on 2021/8/18.
//

import Foundation
import ByteViewCommon

typealias I18n = BundleI18n.ByteViewUI
typealias CommonResources = ByteViewCommon.BundleResources.ByteViewCommon.Common

extension Bundle {
    static let current: Bundle = BundleConfig.SelfBundle
    static let localResources = BundleConfig.ByteViewUIBundle
}
