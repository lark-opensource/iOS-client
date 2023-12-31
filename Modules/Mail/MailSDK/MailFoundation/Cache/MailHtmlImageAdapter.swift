//
//  MailHtmlImageAdapter.swift
//  MailSDK
//
//  Created by tefeng liu on 2021/3/3.
//

import Foundation

protocol MailHtmlImageAdapterProtocol {
    func createCidTokenMap(messageItem: MailMessageItem) -> [String: String]
    func createTokenSchemeUrl(cid: String, cidTokenMap: [String: String]) -> String
    func createTokenSchemeUrl(cid: String, messageId: String, cidTokenMap: [String: String]) -> String
    /// 按 cid:xxx_msgTokenyyy 的格式获取token
    func getTokenFromUrl(_ originUrl: URL?) -> String
    /// 按 cid:xxx_msgTokenyyy 的格式获取token
    func getTokenFromSrc(_ src: String) -> String
    /// 按 cid:xxx_msgToken 获取 cid，不会返回 cid: 前缀, 如 cid:abc 返回 abc
    ///  三方 按 cid:xxx_msgTokenyyy 的格式获取cid
    func getCidFromSrc(_ src: String) -> String
    /// 按 cid:xxx_msgTokenyyy 的格式获取cid
    func getCidFromUrl(_ originUrl: URL?) -> String
    /// 按 cid:xxx_msgTokenyyy_msgIdzzz 的格式获取msgId
    func getMsgIdFromUrl(_ originUrl: URL?) -> String
    /// 按 cid:xxx_msgTokenyyy_msgIdzzz 的格式获取msgId
    func getMsgIdFromSrc(_ src: String) -> String
    /// 返回替换后的cid值xxx_msgTokenyyy
    func getReplacedCidFromSrc(_ src: String) -> String
}

extension MailHtmlImageAdapterProtocol {
    func getReplacedCidFromSrc(_ src: String) -> String {
        var cid = src
        let cidPrefix = "cid:"
        if cid.starts(with: cidPrefix) {
            cid.removeFirst(cidPrefix.count)
        }
        MailLogger.info("mail image replaced cid \(cid.md5())")
        return cid
    }
}

class MailHtmlImageAdapter: MailHtmlImageAdapterProtocol {
    /// cid:XXX_msgToken1234 -> 1234
    private let cidTokenRegex = try? NSRegularExpression(pattern: "cid:[^\\s]+_msgToken([^_\\s]+)", options: .caseInsensitive)
    /// XXX_msgToken1234 -> 1234, image preview JS 调用时会去掉 cid前缀，这个regex用来适配这种case
    private let noCidTokenRegex = try? NSRegularExpression(pattern: "[^\\s]+_msgToken([^_\\s]+)", options: .caseInsensitive)

    private let cacheService: MailCacheService

    init(cacheService: MailCacheService) {
        self.cacheService = cacheService
    }

    func createCidTokenMap(messageItem: MailMessageItem) -> [String: String] {
        let images = messageItem.message.images
        guard !images.isEmpty else { return [:] }
        var map: [String: String] = [:]
        images.forEach { (image) in
            map[image.cid] = image.fileToken
        }
        // 因为不能打印token
        let debugInfo = map.map { (key: String, value: String) -> (String, String) in
            return (key.md5(), value.isEmpty ? "" : value.md5())
        }
        MailLogger.info("msgId: \(messageItem.message.id) createCidTokenMap cidMD5 map: \(debugInfo)")
        return map
    }

    func createTokenSchemeUrl(cid: String, messageId: String, cidTokenMap: [String: String]) -> String { return "" }

    func createTokenSchemeUrl(cid: String, cidTokenMap: [String: String]) -> String {
        if let token = cidTokenMap[cid] {
            // 设cache，避免cid token替换失败，可以走回cid逻辑
            cacheService.set(object: ["fileToken": token] as NSCoding, for: cid)
            return "\(MailCustomScheme.cid.rawValue):\(cid)_msgToken\(token)"
        }
        MailLogger.error("no fileToken for cid: \(cid.md5())")
        return "\(MailCustomScheme.cid.rawValue):\(cid)" // 原样子
    }

    func getTokenFromUrl(_ originUrl: URL?) -> String {
        guard let urlString = originUrl?.absoluteString else {
            return ""
        }
        return getTokenFromSrc(urlString)
    }

    func getTokenFromSrc(_ src: String) -> String {
        let tokenRegexes = [cidTokenRegex, noCidTokenRegex]
        for regex in tokenRegexes {
            if let match = regex?.firstMatch(in: src, options: [], range: NSRange(location: 0, length: src.utf16.count)), match.numberOfRanges >= 2 {
                let tokenRange = match.range(at: 1)
                let token = (src as NSString).substring(with: tokenRange)
                return token
            }
        }
        MailLogger.info("mail image token not found from src :\(src.md5())")
        return ""
    }
    
    func getCidFromUrl(_ originUrl: URL?) -> String {
        guard let urlString = originUrl?.absoluteString else {
            return ""
        }
        return getCidFromSrc(urlString)
    }

    func getCidFromSrc(_ src: String) -> String {
        if let cidRegex = try? NSRegularExpression(pattern: "([^\\s]+)_msgToken([^_\\s]*)", options: .caseInsensitive) {
            if let match = cidRegex.firstMatch(in: src, options: [], range: NSRange(location: 0, length: src.utf16.count)), match.numberOfRanges >= 2 {
                let cidRange = match.range(at: 1)
                var cid = (src as NSString).substring(with: cidRange)
                let cidPrefix = "cid:"
                if cid.starts(with: cidPrefix) {
                    cid.removeFirst(cidPrefix.count)
                }
                return cid
            }
        }
        MailLogger.info("mail image cid not found from src :\(src.md5())")
        return ""
    }

    func getMsgIdFromUrl(_ originUrl: URL?) -> String {
        guard let urlString = originUrl?.absoluteString else {
            return ""
        }
        return getMsgIdFromSrc(urlString)
    }

    func getMsgIdFromSrc(_ src: String) -> String {
        let regexes = [cidTokenRegex, noCidTokenRegex]
        for regex in regexes {
            if let match = regex?.firstMatch(in: src, options: [], range: NSRange(location: 0, length: src.utf16.count)), match.numberOfRanges >= 3 {
                let msgIdRange = match.range(at: 2)
                let msgId = (src as NSString).substring(with: msgIdRange)
                return msgId
            }
        }
        MailLogger.info("mail image msgId not found from src :\(src.md5())")
        return ""
    }
}

class MailThirdPartyImageAdapter: MailHtmlImageAdapterProtocol {
    private let cacheService: MailCacheService

    init(cacheService: MailCacheService) {
        self.cacheService = cacheService
    }

    func createCidTokenMap(messageItem: MailMessageItem) -> [String: String] {
        let images = messageItem.message.images
        guard !images.isEmpty else { return [:] }
        var map: [String: String] = [:]
        images.forEach { (image) in
            map[image.cid] = image.fileToken
        }
        // 因为不能打印token
        let debugInfo = map.map { (key: String, value: String) -> (String, Bool) in
            return (key.md5(), value.isEmpty ? false : true)
        }
        MailLogger.info("vvImage msgId: \(messageItem.message.id) createCidTokenMap cid map: \(debugInfo)")
        return map
    }

    func createTokenSchemeUrl(cid: String, cidTokenMap: [String: String]) -> String { return "" }
    
    func createTokenSchemeUrl(cid: String, messageId: String, cidTokenMap: [String: String]) -> String {
        if let token = cidTokenMap[cid], !token.isEmpty {
            // 设cache，避免cid token替换失败，可以走回cid逻辑
            cacheService.set(object: ["fileToken": token] as NSCoding, for: cid)
            return "\(MailCustomScheme.cid.rawValue):\(token)_msgId\(messageId)" // 新逻辑 cid改token
        }
//        mailAssertionFailure("no fileToken for cid: \(cid)")
        MailLogger.info("vvImage no fileToken for cid: \(cid.md5())")
        return "\(MailCustomScheme.cid.rawValue):\(cid)_msgId\(messageId)" // 原样子
    }

    func getTokenFromUrl(_ originUrl: URL?) -> String {
        guard let urlString = originUrl?.absoluteString else {
            return ""
        }
        return getTokenFromSrc(urlString)
    }

    func getTokenFromSrc(_ src: String) -> String {
        return ""
    }

    func getCidAndMsgId(_ src: String) -> (String, String) {
        let splitRange = src.range(of: "_msgId")
        if let splitIndex = splitRange?.lowerBound {
            let count: Int = src.distance(from: src.startIndex, to: splitIndex)
            let index = src.index(src.startIndex, offsetBy: count)
            var msgIdStr = String(src.suffix(from: index))
            let cidStr = src.replacingOccurrences(of: msgIdStr, with: "").replacingOccurrences(of: "cid:", with: "")
            msgIdStr = msgIdStr.replacingOccurrences(of: "_msgId", with: "")
            return (cidStr, msgIdStr)
        }
        return ("", "")
    }

    func getCidFromUrl(_ originUrl: URL?) -> String {
        guard let urlString = originUrl?.absoluteString else {
            return ""
        }
        return getCidFromSrc(urlString)
    }

    func getCidFromSrc(_ src: String) -> String {
        return getCidAndMsgId(src).0
    }

    func getMsgIdFromUrl(_ originUrl: URL?) -> String {
        guard let urlString = originUrl?.absoluteString else {
            return ""
        }
        return getMsgIdFromSrc(urlString)
    }

    func getMsgIdFromSrc(_ src: String) -> String {
        return getCidAndMsgId(src).1
    }
}
