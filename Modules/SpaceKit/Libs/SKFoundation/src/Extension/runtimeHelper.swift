import Foundation

/// check is a class has a selector
public func existSelector(selector: Selector, cls: AnyClass) -> Bool {
    var methodCount: UInt32 = 0
    let methodList = class_copyMethodList(cls.self, &methodCount)
    for i in 0..<methodCount {
        guard let temp = methodList?[Int(i)] else { continue }
        if NSStringFromSelector(method_getName(temp)) == NSStringFromSelector(selector) {
            return true
        }
    }
    return false
}

/// dynamic add selector for classes, default 'v' means one parameters, object function
public func selector(uid: String, types: String = "v", classes: [AnyClass], block: (() -> Swift.Void)?) -> Selector {
    let aSelector = NSSelectorFromString(uid)
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
