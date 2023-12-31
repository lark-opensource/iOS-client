//
//  LarkFeatureGating.swift
//  FeatureGating
//
//  Created by 李勇 on 2019/9/5.
//

import Foundation
import LarkFoundation
import RxSwift
import ThreadSafeDataStructure
import LarkSetting

import LarkActionSheet // 为了修复间接依赖问题

/// LarkFeatureGating功能实现
public final class LarkFeatureGating {
    /// 全局单例
    @available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
    public static let shared: LarkFeatureGating = LarkFeatureGating()

    @available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
    public func getFeatureBoolValue(for key: FeatureGatingKey) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key.rawValue)) //Global
    }

    @available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
    public func getFeatureBoolValue(for key: String) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key)) //Global
    }

    @available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
    public func getFeatureBoolValue(for key: FeatureGatingKey, defaultValue: Bool = false) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key.rawValue)) //Global
    }

    @available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
    public func getFeatureBoolValue(for key: String, defaultValue: Bool = false) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key)) //Global
    }

    @available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
    public func getStaticBoolValue(for key: FeatureGatingKey, defaultValue: Bool = false) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key.rawValue)) //Global
    }

    @available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
    public func getStaticBoolValue(for key: String, defaultValue: Bool = false) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key)) //Global
    }

    @available(*, deprecated, message: "please use FeatureGatingManager instead, will remove")
    public func getABTestValue(for key: String) -> Bool {
        FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: key)) //Global
    }
}

extension FeatureGatingManager.Key {
    public init(key: FeatureGatingKey) { self.init(stringLiteral: key.rawValue) }
}
