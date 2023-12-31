//
//  ListItemLogger.swift
//  LarkListItem
//
//  Created by Yuri on 2023/5/29.
//

import Foundation
import LarkContactComponent

final class ListItemLogger: LarkBaseLogger {
    public override var moduleName: String { "ListItem" }
    public enum Module: String, BaseLoggerModuleType {
        public var value: String { self.rawValue }
        /// 数据转换
        case convert
        case service
    }
    public static let shared = ListItemLogger()
}
