//
//  CustomHeader.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/11/25.
//

import Foundation
import LarkContainer

public enum DocsCustomHeader: String {
    case requestID = "request-id"
    case xRequestID = "x-request-id"
    case xttTraceID = "x-tt-trace-id" //全链路分析需求
    case accessCredentials = "access-control-allow-credentials"
    case accessMethods = "access-control-allow-methods"
    case accessOrigin = "access-control-allow-origin"
    case deviceId = "doc-device-id"
    case xCommandID = "x-command"
    case csrfToken = "x-csrftoken"
    case fromSource = "fromsource"
    case cookie = "cookie"
    case env = "env"
    case xttLogId = "x-tt-logid"
    
    public typealias CookieMissClosure = ((URL) -> Void)
    // cookie miss时的回调
    public static var cookieMissClosure: CookieMissClosure?

    public static func addCookieHeaderIfNeed(_ urlRequest: URLRequest, userResolver: UserResolver) -> URLRequest {
        var request = urlRequest
        var neetAuthCookieIfSystemEmpty = false
        var existCookieStr: String?
        var authCookieStr: String?
        let otherCookieStr: String? = generateOtherCookieStr(urlRequest, userResolver: userResolver)
        guard let url = request.url else {
            return request
        }
        let headerCookie = request.allHTTPHeaderFields?.first(where: { (k, _) in k.lowercased() == DocsCustomHeader.cookie.rawValue })?.value ?? ""
        if headerCookie.isEmpty {
            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
            let cookiesValue = HTTPCookie.requestHeaderFields(with: cookies)
               .first(where: { (k, _) in k.lowercased() == DocsCustomHeader.cookie.rawValue })?.value ?? ""
            if cookiesValue.isEmpty == false {
                existCookieStr = cookiesValue
                
                //筛选是否有存在session
    
                let hasSession = cookies.contains { cookie in
                    return cookie.name == "session" && !cookie.value.isEmpty
                }
                
                if !hasSession {
                    DocsLogger.info("[requestCookie] hasNot session cookie of cookiesValue, host=\(String(describing: request.url?.host))")
                    neetAuthCookieIfSystemEmpty = true
                }
            } else {
                DocsLogger.info("[requestCookie] cookiesValue.isEmpty, cookies=\(cookies), host=\(String(describing: request.url?.host))")
                neetAuthCookieIfSystemEmpty = true
            }
        } else {
            existCookieStr = headerCookie
            
            let cookieArr = headerCookie.split(separator: ";")
            var hasSession = false
            for subStr in cookieArr {
                //前面可能会有空格或者换行
                let subStrTemp = subStr.trimmingCharacters(in: .whitespaces)
                let sessionName = "session="
                //判断大于sessinName.count，是为了判断value是否有值
                if subStrTemp.hasPrefix(sessionName), subStrTemp.count > sessionName.count {
                    hasSession = true
                    break
                }
            }
            
            if !hasSession {
                DocsLogger.info("[requestCookie] hasNot session cookie of headerCookie, host=\(String(describing: request.url?.host))")
                neetAuthCookieIfSystemEmpty = true
            }
        }
        // 如果系统cookie里面找不到auth cookie，尝试生成cookie
        if neetAuthCookieIfSystemEmpty {
            authCookieStr = self.createAuthCookieIfSystemEmpty(request, userResolver: userResolver)
        }

        var resultCookieArray: [String] = []
        //兜底cookie
        authCookieStr.map { resultCookieArray.append($0) }
        //已经存在的cookie
        existCookieStr.map { resultCookieArray.append($0) }
        //预发环境添加的cookie的
        otherCookieStr.map { resultCookieArray.append($0) }
        let resultCookieStr: String = resultCookieArray.joined(separator: "; ")

        if resultCookieStr.isEmpty == false {
            request.setValue(resultCookieStr, forHTTPHeaderField: DocsCustomHeader.cookie.rawValue)
        }
        return request
    }

    private static func createAuthCookieIfSystemEmpty(_ urlRequest: URLRequest, userResolver: UserResolver) -> String? {
        var createCookieStr: String?
        guard let url = urlRequest.url else {
            return nil
        }
        if needAuthSession(url: url, userResolver: userResolver), let resultCookie = self.generateAuthCookieVaule(userResolver: userResolver) {
            createCookieStr = resultCookie
            DocsLogger.info("[requestCookie] createBackupCookie, host=\(String(describing: url.host)))")
        }
        return createCookieStr
    }

    private static func needAuthSession(url: URL, userResolver: UserResolver) -> Bool {
        guard let host = url.host,
              let doscMainDomain = userResolver.docs.netConfig?.docsMainDomain,
              !doscMainDomain.isEmpty else {
            DocsLogger.info("[requestCookie] needAuthSession is false")
            return false
        }
        
        func match(with domain: String) -> Bool {
            var pattenDocDomain: String
            //fg默认是关闭的，开启走旧逻辑
            if UserScopeNoChangeFG.HZK.disableModifyDomainRegular {
                pattenDocDomain = ".\(domain)"
            } else {
                pattenDocDomain = ".\(domain)$"
            }
            pattenDocDomain = pattenDocDomain.replacingOccurrences(of: ".", with: "\\.")
            let match = host.matches(for: pattenDocDomain).isEmpty == false
            return match
        }
        // check main domain
        let isMatch = match(with: doscMainDomain)
        
        // check settings domain
        let needAuthDomains = userResolver.docs.netConfig?.needAuthDomains ?? []
        if !isMatch, !needAuthDomains.isEmpty {
            for domain in needAuthDomains where !domain.isEmpty {
                if match(with: domain) {
                    return true
                }
            }
        }
        if isMatch {
            cookieMissClosure?(url)
        }
        return isMatch
    }

    private static func generateAuthCookieVaule(userResolver: UserResolver) -> String? {
        let config = userResolver.docs.netConfig
        guard let token = config?.authToken else {
            DocsLogger.info("[requestCookie] generateAuthCookieVaule, token nil")
            return nil
        }
        if token.isEmpty {
            DocsLogger.info("[requestCookie] generateAuthCookieVaule, token isEmpty")
        }
        let cookieDictionary = ["session": token,
                                "bear-session": token,
                                "lang": config?.currentLang ?? "",
                                "locale": config?.currentLangLocale ?? ""
                            ] as [String: String]
        let resultCookieStr = cookieDictionary.map { (key, value) -> String in
            "\(key)=\(value)"
        }.joined(separator: ";")
        return resultCookieStr
    }

    private static func generateOtherCookieStr(_ urlRequest: URLRequest, userResolver: UserResolver) -> String? {
        let otherCookieStr = userResolver.docs.netConfig?.preleaseCookieStr
        return otherCookieStr
    }
}

public struct DocsCustomHeaderValue {
    public static let fromMobileWeb: String = "mobileweb"
}


public enum DocsCookiesName: String {
    case csrfToken = "_csrf_token"
}
