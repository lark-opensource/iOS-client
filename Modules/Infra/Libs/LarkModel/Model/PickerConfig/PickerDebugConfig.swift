//
//  PickerDebugConfig.swift
//  CryptoSwift
//
//  Created by Yuri on 2023/5/11.
//

import Foundation



public struct PickerDebugConfig: Codable {
    public var featureConfig = PickerFeatureConfig()
    public var searchConfig = PickerSearchConfig()
    public var contactConfig = PickerContactViewConfig(entries: [])

    public var style: Style = .picker
    public var recommendType: RecommendType = .contact

    public var disablePrefix: String = ""
    public var forceSelectPrefix: String = ""

    public init(featureConfig: PickerFeatureConfig = PickerFeatureConfig(),
                searchConfig: PickerSearchConfig = PickerSearchConfig(),
                contactConfig: PickerContactViewConfig = PickerContactViewConfig(entries: []),
                disablePrefix: String = "",
                forceSelectPrefix: String = "") {
        self.featureConfig = featureConfig
        self.searchConfig = searchConfig
        self.contactConfig = contactConfig
        self.disablePrefix = disablePrefix
        self.forceSelectPrefix = forceSelectPrefix
    }
}

public extension PickerDebugConfig {
    enum Style: String, Codable {
        case picker
        case search
    }

    enum RecommendType: String, Codable {
        case contact
        case search
        case none
    }
}
