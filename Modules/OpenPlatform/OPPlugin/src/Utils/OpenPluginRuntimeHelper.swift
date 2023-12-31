//
//  OpenPluginRuntimeHelper.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/7/18.
//

import Foundation

/// 防止动态添加的方法名与系统方法或已有方法冲突，添加 prefix 前缀
private let kSELPrefix = "__op_"

/// dynamic add selector for classes, default 'v' means one parameters, object function
/// - Parameters:
///   - uid: selector的名称,unique
///   - types: 参考runtime中的type说明
///   - classes: 这个selector需要添加到的类
///   - block: selector的具体实现(Imp)
/// - Returns: Selector
func createSelector(uid: String, types: String = "v", classes: [AnyClass], block: (() -> Swift.Void)?) -> Selector {
    let selName = kSELPrefix + uid
    let aSelector = NSSelectorFromString(selName)
    let block = { () -> Swift.Void in block?() }
    let castedBlock: AnyObject = unsafeBitCast(block as @convention(block) () -> Swift.Void, to: AnyObject.self)
    let imp = imp_implementationWithBlock(castedBlock)

    classes.forEach { (cls) in
        "v".withCString { (unsafePointer) -> Void in
            if class_addMethod(cls, aSelector, imp, unsafePointer) {
            } else {
                class_replaceMethod(cls, aSelector, imp, unsafePointer)
            }
        }
    }

    return aSelector
}
