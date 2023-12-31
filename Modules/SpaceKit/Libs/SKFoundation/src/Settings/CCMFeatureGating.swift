//
//  CCMFeatureGating.swift
//  SKFoundation
//
//  Created by ByteDance on 2023/7/18.
//

import Foundation
import LarkContainer
import LarkSetting
import ThreadSafeDataStructure

public extension CCMExtension where Base == UserResolver {
    
    /// 静态FG, 用户生命周期内不变
    func fg(_ key: String) -> Bool {
        staticFG(key)
    }
    
    /// 静态FG, 用户生命周期内不变
    func staticFG(_ key: String) -> Bool {
        let userResolver = self.base
        let service = try? userResolver.resolve(type: CCMFeatureGatingService.self)
        let value = service?.staticFG(key) ?? false
        return value
    }
    
    /// 实时FG, https://bytedance.feishu.cn/docx/doxcnJ7dzCiiqRxTi7yc9Jhebxe
    func dynamicFG(_ key: String) -> Bool {
        let userResolver = self.base
        let service = try? userResolver.resolve(type: CCMFeatureGatingService.self)
        let value = service?.dynamicFG(key) ?? false
        return value
    }
}

public protocol CCMFeatureGatingService {
    
    func dynamicFG(_ key: String) -> Bool
    
    func staticFG(_ key: String) -> Bool
}

public final class CCMFeatureGatingImpl: CCMFeatureGatingService {
    
    let resolver: UserResolver
    
    private var printedKeys = SafeSet<String>()
    
    #if DEBUG
    // mock fg使用，仅在单元测试场景进行 mock，非单元测试请直接使用主端基建的mock界面
    private static var mockValues = [String: Bool]()
    #endif
    
    public init(resolver: UserResolver) {
        self.resolver = resolver
    }
    
    public func dynamicFG(_ key: String) -> Bool {
        if let value = useMockValueWhenDebug(key) { return value }
        
        let fgKey = FeatureGatingManager.Key(stringLiteral: key)
        let value = resolver.fg.dynamicFeatureGatingValue(with: fgKey)
        printLogIfNeeded(key: key, value: value)
        return value
    }
    
    public func staticFG(_ key: String) -> Bool {
        if let value = useMockValueWhenDebug(key) { return value }
        
        let fgKey = FeatureGatingManager.Key(stringLiteral: key)
        let value = resolver.fg.staticFeatureGatingValue(with: fgKey)
        printLogIfNeeded(key: key, value: value)
        return value
    }
    
    private func printLogIfNeeded(key: String, value: Bool) {
        if printedKeys.contains(key) { return } // 每个FG只打印一次值
        DocsLogger.info("Get FeatureGate value success",
                        extraInfo: ["key": key, "value": value],
                        component: LogComponents.larkFeatureGate)
        printedKeys.insert(key)
    }
    
    private func useMockValueWhenDebug(_ key: String) -> Bool? {
        #if DEBUG
        if let mockValue = Self.mockFG(key: key) {
            DocsLogger.info("CCM_FG use mock value, key:\(key) value:\(mockValue)")
            return mockValue
        }
        #endif
        return nil
    }
}

#if DEBUG
//这里的方法请不要改public，引入SKFoundation的时候请使用 @testable import SKFoundation
extension CCMFeatureGatingImpl {
    static func setMockFG(key: String, value: Bool) {
        mockValues[key] = value
    }
    static func removeMockFG(key: String) {
        mockValues.removeValue(forKey: key)
    }
    fileprivate static func mockFG(key: String) -> Bool? {
        mockValues[key]
    }
}
#endif
