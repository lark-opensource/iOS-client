//
//  FeatureGatingPropertyWrapper.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/20.
//

/// 取静态FG值的propertyWrapper，启动的时候从rust获取，app生命周期内不变
import Foundation
@propertyWrapper
public struct FeatureGatingValue {
    /// wrapped value
    public let wrappedValue: Bool

    /// 外部可以使用@FeatureGatingValue声明FG变量
    ///
    /// ```swift
    /// @FeatureGatingValue(key: "someKey") private var someFG: Bool
    /// ```
    public init(key: FeatureGatingManager.Key) {
        wrappedValue = FeatureGatingManager.shared.featureGatingValue(with: key) //Global
    }
}

/// 取实时FG值的propertyWrapper，第一次取的时候获取当前最新值，之后每次取都和第一次取的值相同
@propertyWrapper
public struct RealTimeFeatureGating {
    /// wrapped value
    public let wrappedValue: Bool

    /// 外部可以使用@RealTimeFeatureGating声明FG变量
    ///
    /// ```swift
    /// @RealTimeFeatureGating(key: "someKey") private var someFG: Bool
    /// ```
    public init(key: FeatureGatingManager.Key) {
        wrappedValue = FeatureGatingManager.realTimeManager.featureGatingValue(with: key) //Global
    }
}

/// 取实时FG值的propertyWrapper，每一次取的时候获取当前最新值
@propertyWrapper
public struct RealTimeFeatureGatingProvider {
    /// FG的key
    private let key: FeatureGatingManager.Key

    /// wrapped value
    public var wrappedValue: Bool {
        FeatureGatingManager.realTimeManager.featureGatingValue(with: key) //Global
    }

    /// 外部可以使用@RealTimeFeatureGatingProvider声明FG变量
    ///
    /// ```
    /// @RealTimeFeatureGatingProvider(key: "someKey") private var someFG: Bool
    /// ```
    public init(key: FeatureGatingManager.Key) { self.key = key }
}
