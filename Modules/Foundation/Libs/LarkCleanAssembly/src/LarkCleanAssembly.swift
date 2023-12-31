//
//  LarkCleanAssembly.swift
//  LarkCleanAssembly
//
//  Created by 李昊哲 on 2023/6/29.
//  

import Foundation
import Swinject
import LarkAssembler
import LarkClean
#if canImport(LarkSafeMode)
import LarkSafeMode
#endif

#if !LARK_NO_DEBUG
import LarkDebugExtensionPoint
#endif

public final class LarkCleanAssembly: LarkAssemblyInterface {
    public init() {
        // TODO: 待迁移成 task
        LarkClean.Cleaner.dependency = CleanerDependencyImpl()
    }

#if !LARK_NO_DEBUG
    public func registDebugItem(container: Container) {
        ({ LarkCleanDebugItem() }, SectionType.debugTool)
    }
#endif
}

final class CleanerDependencyImpl: CleanerDependency {
    func deepClean(completion: @escaping (_ succeed: Bool) -> Void) {
#if canImport(LarkSafeMode)
        LarkSafeModeUtil.deepClearAllUserCache()
#endif
        completion(true)
    }
}
