//
//  StringFixFactory.swift
//  LKContentFix
//
//  Created by 李勇 on 2020/9/6.
//

import Foundation

/// 内容修复工厂，业务方可自己新增工厂
open class StringFixFactory {
    /// 初始化方法
    public required init() {}

    /// 配置对应的key
    open var key: String { return "" }
    /// 重置所有的配置
    open func reset() {}
    /// 这里传入的config是根据configKey得到的，str表示config是对于哪个内容下发的配置
    open func loadConfig(_ str: String, _ config: Any) {}
    /// 开始处理内容
    open func fix(_ attrStr: NSMutableAttributedString) -> NSMutableAttributedString { return attrStr }
}
