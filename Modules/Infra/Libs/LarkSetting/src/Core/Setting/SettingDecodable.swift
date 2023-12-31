//
//  SettingDecodable.swift
//  LarkSetting
//
//  Created by Supeng on 2021/6/3.
//

import Foundation

public protocol SettingDecodable: Decodable {
    associatedtype Key: SettingKeyConvertible
    static var settingKey: Key { get }
}

public protocol SettingDefaultDecodable: SettingDecodable {
    static var defaultValue: Self { get }
}
