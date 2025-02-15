////
//  Swizzle.swift
//  Swizzle
//
//  Created by Yasuhiro Inami on 2014/09/14.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//
import ObjectiveC

private func _swizzleMethod(_ class_: AnyClass, from selector1: Selector, to selector2: Selector, isClassMethod: Bool) {
    let c: AnyClass
    if isClassMethod {
        guard let c_ = object_getClass(class_) else {
            return
        }
        c = c_
    } else {
        c = class_
    }

    guard let method1: Method = class_getInstanceMethod(c, selector1),
        let method2: Method = class_getInstanceMethod(c, selector2) else {
        return
    }

    if class_addMethod(c, selector1, method_getImplementation(method2), method_getTypeEncoding(method2)) {
        class_replaceMethod(c, selector2, method_getImplementation(method1), method_getTypeEncoding(method1))
    } else {
        method_exchangeImplementations(method1, method2)
    }
}

/// Instance-method swizzling.
func swizzleInstanceMethod(_ class_: AnyClass, from sel1: Selector, to sel2: Selector) {
    _swizzleMethod(class_, from: sel1, to: sel2, isClassMethod: false)
}

/// Instance-method swizzling for unsafe raw-string.
/// - Note: This is useful for non-`#selector`able methods e.g. `dealloc`, private ObjC methods.
func swizzleInstanceMethodString(_ class_: AnyClass, from sel1: String, to sel2: String) {
    swizzleInstanceMethod(class_, from: Selector(sel1), to: Selector(sel2))
}

/// Class-method swizzling.
func swizzleClassMethod(_ class_: AnyClass, from sel1: Selector, to sel2: Selector) {
    _swizzleMethod(class_, from: sel1, to: sel2, isClassMethod: true)
}

/// Class-method swizzling for unsafe raw-string.
func swizzleClassMethodString(_ class_: AnyClass, from sel1: String, to sel2: String) {
    swizzleClassMethod(class_, from: Selector(sel1), to: Selector(sel2))
}

/// 交换 class1 的 sel1 和 class2 的 sel2
func swizzleInstanceMethod(from class1: AnyClass, sel1: Selector, to class2: AnyClass, sel2: Selector) {
    guard let method1: Method = class_getInstanceMethod(class1, sel1),
        let method2: Method = class_getInstanceMethod(class2, sel2) else {
        return
    }
    if class_addMethod(class1, sel2, method_getImplementation(method2), method_getTypeEncoding(method2)),
       let method = class_getInstanceMethod(class1, sel2) {
        method_exchangeImplementations(method1, method)
    }
}
