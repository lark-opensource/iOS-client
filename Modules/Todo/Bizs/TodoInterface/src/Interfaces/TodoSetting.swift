//
//  TodoSetting.swift
//  TodoInterface
//
//  Created by 白言韬 on 2021/2/25.
//

import EENavigator

/// 跳转 Todo 设置页

public struct TodoSettingBody: CodablePlainBody {
    public static let pattern = "//client/todo/setting"

    public init() { }
}
