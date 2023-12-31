//
//  StringFixFactoryRegistery.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/6.
//

import Foundation

/// 工厂注册器，使用方可通过此注册自己的处理工厂
public final class StringFixFactoryRegistery {
    /// 所有注册的处理工厂
    private static var registeryFactories: [StringFixFactory.Type] = [UpdateAttribute.self, ReplaceContent.self]

    /// 注册自定义工厂
    public static func registery(factory: StringFixFactory.Type) {
        StringFixFactoryRegistery.registeryFactories.append(factory)
    }

    static func getFactories() -> [StringFixFactory] {
        return StringFixFactoryRegistery.registeryFactories.map({ $0.init() })
    }
}
