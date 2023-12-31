//
//  DocCookieChecker.swift
//  SKFoundation
//
//  Created by huayufan on 2022/9/8.
//  

// https://bytedance.feishu.cn/docx/S3rMdf5q1oLzjLx7u3WcEevqnue

import UIKit
import LarkContainer

public final class DocCookieChecker: NSObject {

    public static var slardarEnable = false

    public static func hookCookie() {
        HTTPCookieStorage.shared.beginHook()
    }
}

extension HTTPCookieStorage {
    
    func beginHook() {
        swizzlingForClass(HTTPCookieStorage.self,
                          originalSelector: #selector(HTTPCookieStorage.setCookies(_:for:mainDocumentURL:)),
                          swizzledSelector: #selector(self.docSetCookies(_:for:mainDocumentURL:)))
        swizzlingForClass(HTTPCookieStorage.self, originalSelector: #selector(HTTPCookieStorage.setCookie(_:)), swizzledSelector: #selector(self.docSetCookie(_:)))
        
        swizzlingForClass(HTTPCookieStorage.self, originalSelector: #selector(HTTPCookieStorage.deleteCookie(_:)), swizzledSelector: #selector(self.docDeleteCookie(_:)))
        
        swizzlingForClass(HTTPCookieStorage.self, originalSelector: #selector(HTTPCookieStorage.removeCookies(since:)), swizzledSelector: #selector(self.docRemoveCookies(since:)))
    }
    
    /// 只监听设置session的操作
    func filter(cookies: [HTTPCookie]) -> [HTTPCookie] {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let netConfig = userResolver.docs.netConfig
        var domains = netConfig?.needAuthDomains ?? []
        if let docsMainDomain = netConfig?.docsMainDomain {
            domains.append(docsMainDomain)
        }
        var needs: [HTTPCookie] = []
        for cookie in cookies where cookie.name == "session" {
            let pass = domains.contains { cookie.domain.contains($0) }
            if pass {
                needs.append(cookie)
            }
        }
        return needs
    }

    
    func encrypt(_ text: String) -> String {
        var encrpyText = ""
        let length = text.count
        if length >= 20 {
            let startIndex = text.startIndex
            let endIndex = text.index(startIndex, offsetBy: 10)

            let endIndex2 = text.endIndex
            let startIndex2 = text.index(endIndex2, offsetBy: -10)
            encrpyText = "\(text[startIndex..<endIndex])***\(text[startIndex2..<endIndex2])"
        } else if length >= 10 {
            let startIndex = text.startIndex
            let endIndex = text.index(startIndex, offsetBy: 10)
            encrpyText = "\(text[startIndex..<endIndex])"
        }
        return encrpyText
    }
    
    private func encryptDocCookies(_ cookies: [HTTPCookie]) -> String {
        var strs: [String] = []
        for coo in cookies {
            let str = "name=\(coo.name) value=\(encrypt(coo.value)) expiresDate=\(String(describing: coo.expiresDate)) domain=\(coo.domain)"
            strs.append(str)
        }
        return strs.joined(separator: "\n")
    }
    
    func swizzlingForClass(_ forClass: AnyClass, originalSelector: Selector, swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
              let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
        }
        if class_addMethod(forClass, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
            class_replaceMethod(forClass, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    @objc
    func docSetCookies(_ cookies: [HTTPCookie], for URL: URL?, mainDocumentURL: URL?) {
        defer { self.docSetCookies(cookies, for: URL, mainDocumentURL: mainDocumentURL) }
        let filterCookies = filter(cookies: cookies)
        guard !filterCookies.isEmpty else { return }
        // id是为了让日志和slardar上报匹配 下同
        let id = UUID().uuidString
        let urlString = URL?.host ?? ""
        let encrpyText = encryptDocCookies(filterCookies)
        DocsLogger.warning("setCookies: \(encrpyText) for URL:\(String(describing: URL)) id:\(id)", component: LogComponents.cookie)
        
        // 上报堆栈信息到slardar 下同
        if DocCookieChecker.slardarEnable {
            DocsExceptionTracker.trackException(.cookie, customParams: ["setCookies": encrpyText,
                                                                        "id": id,
                                                                        "URL": urlString])
        }
    }

    @objc
    func docSetCookie(_ cookie: HTTPCookie) {
        defer { self.docSetCookie(cookie) }
        let filterCookies = filter(cookies: [cookie])
        guard !filterCookies.isEmpty else { return }
        let id = UUID().uuidString
        let encrpyText = encryptDocCookies(filterCookies)
        DocsLogger.warning("setCookie: \(encrpyText) id:\(id)", component: LogComponents.cookie)
        if DocCookieChecker.slardarEnable {
            DocsExceptionTracker.trackException(.cookie, customParams: ["setCookie": encrpyText,
                                                                        "id": id])
        }
    }

    @objc
    func docDeleteCookie(_ cookie: HTTPCookie) {
        defer { self.docDeleteCookie(cookie) }
        let filterCookies = filter(cookies: [cookie])
        guard !filterCookies.isEmpty else { return }
        let id = UUID().uuidString
        let encrpyText = encryptDocCookies(filterCookies)
        DocsLogger.warning("deleteCookie: \(encrpyText) id:\(id)", component: LogComponents.cookie)
        if DocCookieChecker.slardarEnable {
            DocsExceptionTracker.trackException(.cookie, customParams: ["deleteCookie": encrpyText,
                                                                        "id": id])
        }
    }

    @objc
    func docRemoveCookies(since date: Date) {
        let id = UUID().uuidString
        DocsLogger.warning("deleteCookie since:\(date) id:\(id)", component: LogComponents.cookie)
        if DocCookieChecker.slardarEnable {
            DocsExceptionTracker.trackException(.cookie, customParams: ["deleteCookie": "since \(date)",
                                                                        "id": id])
        }
        self.docRemoveCookies(since: date)
    }

}
