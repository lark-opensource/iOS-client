//
//  MyAiOnboardingConfig.swift
//  ByteViewSetting
//
//  Created by ByteDance on 2023/8/16.
//

import Foundation

public struct MyAiOnboardingConfig: Decodable {
    public let serviceTerms: String

    static let `default` = MyAiOnboardingConfig(serviceTerms: "")
}
