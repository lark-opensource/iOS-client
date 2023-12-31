//
//  File.swift
//  SuiteAppConfig
//
//  Created by aslan on 2022/8/31.
//

import Foundation

public struct FeatureConf {

    /// 当前Feature是否开启
    public var isOn: Bool

    /// Feature相关参数 json
    public var traits: String

    /// Creates a new message with all of its fields initialized to their default
    /// values.
    public init(isOn: Bool, traits: String) {
        self.isOn = isOn
        self.traits = traits
    }
}
