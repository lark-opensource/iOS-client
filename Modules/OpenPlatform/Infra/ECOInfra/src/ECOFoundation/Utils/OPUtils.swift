//
//  OPUtils.swift
//  OPFoundation
//
//  Created by yinyuan on 2020/12/16.
//

/// 安全的异步派发到主线程执行任务
/// - Parameter block: 任务
public func executeOnMainQueueAsync(_ block: @escaping os_block_t) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block()
        }
    }
}

/// 安全的同步派发到主线程执行任务
/// - Parameter block: 任务
public func executeOnMainQueueSync(_ block: os_block_t) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.sync {
            block()
        }
    }
}

/// 将一个被声明为 nonnull 的 OC 对象转换为 nullable，因为OC的 nonnull 声明是不可靠的
@inline(never)
public func OPUnsafeObject<T: Any>(_ object: T?) -> T? {
    return object
}

/// 将一个被声明为 nonnull 的 OC 对象转换为安全 Swift 对象，因为OC的 nonnull 声明是不可靠的，需要提供一个默认值
@inline(never)
public func OPSafeObject<T: Any>(_ object: T?, _ default: T) -> T {
    return OPUnsafeObject(object) ?? `default`
}
