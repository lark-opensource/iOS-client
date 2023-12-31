//
//  PickerLogger.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/1/2.
//

import Foundation
import LarkContactComponent

final public class PickerLogger: LarkBaseLogger {
    public override var moduleName: String { "Picker" }
    public enum Module: String, BaseLoggerModuleType {
        public var value: String { self.rawValue }

        case view // 控制器,视图生命周期
        case recommend // 推荐内容
        case search // 搜索
        case contact // 联系人视图
        case data // 数据处理
        case preload // 预加载
        case router // 路由
    }
    public static let shared = PickerLogger()
}
