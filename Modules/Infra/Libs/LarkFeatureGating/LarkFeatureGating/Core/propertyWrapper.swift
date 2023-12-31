//
//  propertyWrapper.swift
//  LarkFeatureGating
//
//  Created by huangjianming on 2019/12/11.
//

import Foundation
import LarkContainer
import LarkSetting

/// LarkFeatureGating对应的快捷propertyWrapper
@available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
@propertyWrapper
public struct FeatureGating {
    private let key: String

    public init(_ key: String) {
        self.key = key
    }
    public init(_ featureKey: FeatureGatingKey) {
        self.key = featureKey.rawValue
    }
    public var wrappedValue: Bool {
        mutating get {
            return LarkFeatureGating.shared.getFeatureBoolValue(for: self.key)  //Global
        }
    }
}
