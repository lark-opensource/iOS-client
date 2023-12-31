//
//  RTRuntimeHelper.swift
//  RichTextEditor
//
//  Created by chenhuaguan on 2020/6/29.
//

import Foundation

/// dynamic add selector for classes, default 'v' means one parameters, object function
func selector(uid: String, types: String = "v", classes: [AnyClass], block: (() -> Swift.Void)?) -> Selector {
    let aSelector = NSSelectorFromString(uid)
    let block = { () -> Swift.Void in block?() }
    let castedBlock: AnyObject = unsafeBitCast(block as @convention(block) () -> Swift.Void, to: AnyObject.self)
    let imp = imp_implementationWithBlock(castedBlock)
    classes.forEach({ (cls) in
        if class_addMethod(cls, aSelector, imp, UnsafeMutablePointer(mutating: "v")) {
        } else { class_replaceMethod(cls, aSelector, imp, UnsafeMutablePointer(mutating: "v")) }
    })
    return aSelector
}
