//
//  OPAPIModel.swift
//  Timor
//
//  Created by yinyuan on 2020/9/15.
//

import Foundation

/// StringEnum 类型，为了支持 OC 做了一些兼容工作
public typealias StringEnum = OPAPIModel

@objcMembers public class OPAPIModel: JSONModel {
    
    /// 目前受语法限制，默认都设定为 optional，后续需要找到一个更好的同时适用于 Swift 和 OC 的 model parse 方案
    public override class func propertyIsOptional(_ propertyName: String!) -> Bool {
        return true
    }
}
