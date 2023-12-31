//
//  SecurityInfoChecker.swift
//  SKFoundation
//
//  Created by lijuyou on 2021/2/5.
//  


import Foundation

/// 日志和上报安全信息检测
class SecurityInfoChecker {
    static let shared = SecurityInfoChecker()
    private var queue: DispatchQueue = DispatchQueue(label: "docs.security.check", qos: .background)
    var assertPattern: String {
        if let pattern = SKFoundationConfig.shared.tokenPattern {
            return pattern
        }
        return "((sht|doc|dox|bas|app|sld|bmn|fld|nod|box|jsn|img|isv|wik|wia|wib|wic|wid|wie|whb)(cn|us|lg|jp)[A-Za-z0-9]{22})|[A-Z][a-zA-Z0-9]{3}([sdbafnjiw])[a-zA-Z0-9]{4}([oaplmsih])[a-zA-Z0-9]{4}([txspdngvkabce])[a-zA-Z0-9]{4}([culj])[a-zA-Z0-9]{4}([nsgp])[a-zA-Z0-9]{2}"
    }

    private var sharedAssertPatternRegex: NSRegularExpression?
 
    
    private init() { }
    
    func checkLog(_ logEvent: DocsLogEvent) {
        guard SKFoundationConfig.shared.isInDocsApp else { return }
        guard !AssertionConfigForTest.isEnable else { return }
        queue.async {
            let log = "\(logEvent.message),\(String(describing: logEvent.extraInfo)),\(String(describing: logEvent.error))"
            if !log.matches(for: self.assertPattern).isEmpty {
                spaceAssertionFailureWithoutLog("[FBI Warning] 注意: log里包含token: \(log)")
            }
        }
    }
    
    func checkTracker(_ trackParam: [AnyHashable: Any]) {
        guard SKFoundationConfig.shared.isInDocsApp else { return }
        queue.async {
            guard let json = trackParam.toJSONString() else { return }
            if !json.matches(for: self.assertPattern).isEmpty {
//                spaceAssertionFailure("[FBI Warning] 上报里包含token: \(json)")
            }
        }
    }
    
    /// 对 log 数据进行加密脱敏
    func encryptLogIfNeed(_ logEvent: DocsLogEvent, completion: @escaping (DocsLogEvent) -> Void) {
        guard logEvent.level.rawValue >= DocsLogLevel.error.rawValue else {
            completion(logEvent)
            return
        }
        var logEvent = logEvent
        
        var log = "msg: \(logEvent.message), extraInfo: \(logEvent.extraInfo?.jsonString ?? "")"
        if let error = logEvent.error {
            log += ", errorDesc: \(String(describing: error))"
        }
        
        let assertPatternRegex = self.getAssertPatternRegex(shared: false) // log线程使用单独的regex对象
        let replacedText = log.replace(with: "******", regex: assertPatternRegex)
        logEvent.message = replacedText
        logEvent.error = nil
        logEvent.extraInfo = nil
        completion(logEvent)
    }

    
    /// 用于对含有 token 的文本进行加密，会保留 token 的前几位，然后中间的位数进行加密，替换为 *****_。 "wikcnxLWslQ3YdojkRZL6GyQDs" ->  "wikcnxLWsl************_yQDs"
    /// - Parameters:
    ///   - text: 可能含有 token 的文本
    /// - Returns: 混淆后的结果
    func encryptToShort(text: String) -> String {
        var text = text
        let prefixCount: Int = 10
        let sharedRegex = !Thread.isMainThread // 主线程使用单独的regex对象
        let assertPatternRegex = self.getAssertPatternRegex(shared: sharedRegex)
        let needEncryptTexts = Set(text.matches(regex: assertPatternRegex))
        needEncryptTexts.forEach { needEncrpyText in
            let length = needEncrpyText.utf8.count
            if length > prefixCount {
                let encryptedText = String(needEncrpyText.prefix(prefixCount)) + String(repeating: "*", count: length - prefixCount)
                text = text.replacingOccurrences(of: needEncrpyText, with: encryptedText)
            }
        }
        return text
    }
    
    /// 获取正则表达式对象
    /// - Parameter shared: 是否多线程共享实例，true表示多线程共享一个实例，false则每个线程保存一个实例
    /// - Returns: 正则表达式对象
    private func getAssertPatternRegex(shared: Bool) -> NSRegularExpression {
        
        if shared {
            let regex: NSRegularExpression
            if let shared = sharedAssertPatternRegex {
                regex = shared
            } else {
                regex = self.createAssertPatternRegex()
                sharedAssertPatternRegex = regex
            }
            return regex
        }
        
        let key = NSString(string: "ccm.security.check.regex")
        let threadDict = Thread.current.threadDictionary
        if let regex = threadDict.object(forKey: key) as? NSRegularExpression {
            return regex
        }
        let newRegex = self.createAssertPatternRegex()
        threadDict.setObject(newRegex, forKey: key)
        return newRegex
    }
    
    private func createAssertPatternRegex() -> NSRegularExpression {
        if let regex = try? NSRegularExpression(pattern: assertPattern) {
            return regex
        } else {
            spaceAssertionFailure("regex pattern invalid !")
            return NSRegularExpression()
        }
    }
}
