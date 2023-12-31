//
//  DocsIconUrlUtil.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/25.
//  通过文档链接解析token和type

import Foundation
import LarkContainer

public class DocsUrlUtil: UserResolverWrapper {
    
    public var userResolver: LarkContainer.UserResolver
    
    public init(userResolver: LarkContainer.UserResolver) {
        self.userResolver = userResolver
    }
    
    @ScopedProvider private var iconSetting: DocsIconSetting?
    @ScopedProvider private var pathConfig: H5UrlPathConfig?
    
    
    private let utilLock = NSLock()

    /// 3.10.0开始，使用新的url path 匹配和修改方式
    public func getFileInfoNewFrom(_ url: URL) -> (token: String?, type: CCMDocsType?) {

        let path = url.path
        guard let pathPattern = self.tokenPatternConfig["urlReg"],
              path.isMatch(for: pathPattern) else {
            DocsIconLogger.logger.info("getFileInfoNewFrom match path failed")
            return (nil, nil)
        }
        
        guard let pathConfig = pathConfig else {
            DocsIconLogger.logger.info("getPathConfig nil")
            return (nil, nil)
        }

        let tokenPattern = pathConfig.tokenPattern()
        let typePattern = pathConfig.getTypePattern()

        let token = path.firstMatchedCaptureGroup(for: tokenPattern)
        // 从path中匹配
        guard let typeString = path.firstMatchedCaptureGroup(for: typePattern) else {
            return (token, nil)
        }
        // 根据配置中心下发的配置，映射对应的DocsType
        let (canOpen, type) = pathConfig.getRealType(for: typeString)
        guard canOpen else {
            return (token, nil)
        }
        return (token, type)
    }
    
    
    //tokenPatterns
    private var _privateTokenPatternConfig: [String: String]?
    private var tokenPatternConfig: [String: String] {
        utilLock.lock()
        defer {
            utilLock.unlock()
        }
        if _privateTokenPatternConfig == nil {
            _privateTokenPatternConfig = iconSetting?.domainConfig?["tokenPattern"] as? [String : String]
            DocsIconLogger.logger.info("tokenPatternConfig become \(_privateTokenPatternConfig ?? [:])")

        }
        return _privateTokenPatternConfig ?? [:]
    }
    
    
}


extension String {
    public func isMatch(for pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = self as NSString
            let match = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: nsString.length))
            return match != nil
        } catch {
            return false
        }
    }
    
    /// 根据正则表达式，返回匹配到的第一个Capture Group
    ///
    /// - Parameter pattern: 需要匹配的字符串
    /// - Returns: 匹配到的第一处字符串中的第一个Capture Groups
    public func firstMatchedCaptureGroup(for pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.first.map {
                let range = ($0.numberOfRanges > 1) ? $0.range(at: 1) : $0.range
                return nsString.substring(with: range)
            }
        } catch {
            return nil
        }
    }
}
