//
//  DocsCustomHeaderTests.swift
//  SKFoundation-Unit-Tests
//
//  Created by huangzhikai on 2023/2/2.
//

import Foundation
import XCTest
@testable import SKFoundation
import LarkContainer

class DocsCustomHeaderTests: XCTestCase {
    
    var currentUserResolver: UserResolver {
        Container.shared.getCurrentUserResolver(compatibleMode: true)
    }
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testCustomHeaderAddCookie() {
        let requestUrl = "https://bytedance.feishu.net/aaa/bbb"
        let authToken = "token-aaaa-bbbb-cccc" //真正的token
        let testOtherToken = "token_testCookie_aaaa" // 测试其他token
        let docsMainDomain = "feishu.net"
        
        let tempAuthToken = NetConfig.shared.authToken
        let tempDocsMainDomain = NetConfig.shared.docsMainDomain
        
        NetConfig.shared.authToken = authToken
        NetConfig.shared.docsMainDomain = docsMainDomain
        
        // ------------headerFields 为空 和 HTTPCookieStorage 都没有session--------------
        let request = URLRequest(method: .post, url: requestUrl)
        let resultRequest = DocsCustomHeader.addCookieHeaderIfNeed(request!, userResolver: currentUserResolver)
        let headerCookie = resultRequest.allHTTPHeaderFields?.first(where: { (k, _) in k.lowercased() == DocsCustomHeader.cookie.rawValue })?.value ?? ""
        let sessionResult = checkHasSession(headerCookie: headerCookie)
        
        XCTAssertTrue(sessionResult.hasSession)
        XCTAssertTrue(sessionResult.session == authToken)
        
        
        // ------------headerFields 不为空且没有session ， HTTPCookieStorage没有session--------------
        var request1 = URLRequest(method: .post, url: requestUrl)!
        request1.setValue("test_session=\(testOtherToken)", forHTTPHeaderField: DocsCustomHeader.cookie.rawValue)
        let resultRequest1 =  DocsCustomHeader.addCookieHeaderIfNeed(request1, userResolver: currentUserResolver)
        let headerCookie1 = resultRequest1.allHTTPHeaderFields?.first(where: { (k, _) in k.lowercased() == DocsCustomHeader.cookie.rawValue })?.value ?? ""
        let sessionResult1 = checkHasSession(headerCookie: headerCookie1)
        
        XCTAssertTrue(sessionResult1.hasSession)
        // 添加了兜底的token
        XCTAssertTrue(sessionResult1.session == authToken)
        //其他token还需要保持存在
        XCTAssertTrue(headerCookie1.contains(testOtherToken))
        
        
        // ------------headerFields 不为空且有session ， HTTPCookieStorage没有session--------------
        var request2 = URLRequest(method: .post, url: requestUrl)!
        let orginSession = "origintoken-dddd-eeee-ffff"
        request2.setValue("session=\(orginSession)", forHTTPHeaderField: DocsCustomHeader.cookie.rawValue)
        let resultRequest2 =  DocsCustomHeader.addCookieHeaderIfNeed(request2, userResolver: currentUserResolver)
        let headerCookie2 = resultRequest2.allHTTPHeaderFields?.first(where: { (k, _) in k.lowercased() == DocsCustomHeader.cookie.rawValue })?.value ?? ""
        let sessionResult2 = checkHasSession(headerCookie: headerCookie2)
        
        XCTAssertTrue(sessionResult2.hasSession)
        //保持原来的session
        XCTAssertTrue(sessionResult2.session == orginSession)
        
        
        // ------------headerFields 为空 ， HTTPCookieStorage不为空 且没有session--------------
        let request3 = URLRequest(method: .post, url: requestUrl)!
        // HTTPCookieStorage设置个其他session
        let properties3: [HTTPCookiePropertyKey: Any] = genCookieProperties(domain: ".feishu.net", name: "test_session", value: testOtherToken)
        let cookie3 = HTTPCookie(properties: properties3)!
        HTTPCookieStorage.shared.setCookie(cookie3)
        
        let resultRequest3 = DocsCustomHeader.addCookieHeaderIfNeed(request3, userResolver: currentUserResolver)
        let headerCookie3 = resultRequest3.allHTTPHeaderFields?.first(where: { (k, _) in k.lowercased() == DocsCustomHeader.cookie.rawValue })?.value ?? ""
        let sessionResult3 = checkHasSession(headerCookie: headerCookie3)
        
        XCTAssertTrue(sessionResult3.hasSession)
        //保持原来的session
        XCTAssertTrue(sessionResult3.session == authToken)
        //其他token还需要保持存在
        XCTAssertTrue(headerCookie3.contains(testOtherToken))
        
        HTTPCookieStorage.shared.deleteCookie(cookie3)
        
        
        // ------------headerFields 为空 ， HTTPCookieStorage不为空 且有session--------------
        let request4 = URLRequest(method: .post, url: requestUrl)!
        
        // HTTPCookieStorage设置个session
        let properties4: [HTTPCookiePropertyKey: Any] = genCookieProperties(domain: ".feishu.net", name: "session", value: orginSession)
        let cookie4 = HTTPCookie(properties: properties4)!
        HTTPCookieStorage.shared.setCookie(cookie4)
        
        let resultRequest4 = DocsCustomHeader.addCookieHeaderIfNeed(request4, userResolver: currentUserResolver)
        let headerCookie4 = resultRequest4.allHTTPHeaderFields?.first(where: { (k, _) in k.lowercased() == DocsCustomHeader.cookie.rawValue })?.value ?? ""
        let sessionResult4 = checkHasSession(headerCookie: headerCookie4)
        
        XCTAssertTrue(sessionResult4.hasSession)
        //保持原来的session
        XCTAssertTrue(sessionResult4.session == orginSession)
        
        HTTPCookieStorage.shared.deleteCookie(cookie4)
        
        
        // ------------测试其他接口，不会做token兜底--------------
        let request5 = URLRequest(method: .post, url: "https://bytedance.feishuaaa.net/aaa/bbb")
        let resultRequest5 = DocsCustomHeader.addCookieHeaderIfNeed(request5!, userResolver: currentUserResolver)
        let headerCookie5 = resultRequest5.allHTTPHeaderFields?.first(where: { (k, _) in k.lowercased() == DocsCustomHeader.cookie.rawValue })?.value ?? ""
        let sessionResult5 = checkHasSession(headerCookie: headerCookie5)
        
        XCTAssertTrue(sessionResult5.hasSession == false)
        XCTAssertTrue(sessionResult5.session.isEmpty)
    
   
        //还原修复的数据
        NetConfig.shared.authToken = tempAuthToken
        NetConfig.shared.docsMainDomain = tempDocsMainDomain
    }
    
    private func checkHasSession(headerCookie: String) -> (hasSession: Bool, session: String) {
        let cookieArr = headerCookie.split(separator: ";")
        var hasSession = false
        var session = ""
        for subStr in cookieArr {
            //前面可能会有空格或者换行
            let subStrTemp = subStr.trimmingCharacters(in: .whitespaces)
            let sessionName = "session="
            //判断大于sessinName.count，是为了判断value是否有值
            if subStrTemp.hasPrefix(sessionName) {
                let subArr = subStrTemp.split(separator: "=")
                if subArr.count > 1 {
                    session = String(subArr[1])
                    if !session.isEmpty {
                        hasSession = true
                        break
                    }
                }
                break
            }
        }
        return (hasSession, session)
    }
    
    private func genCookieProperties(domain: String, name: String, value: String) -> [HTTPCookiePropertyKey: Any] {
        [
            .name: name,
            .value: value,
            .path: "/",
            .domain: domain,
            .expires: self.cookieExpiresDate(),
            HTTPCookiePropertyKey(rawValue: "HttpOnly"): "YES",
            .secure: "TRUE"
        ]
    }
    
    private func cookieExpiresDate() -> Date {
        if let oneYearAfter = Calendar.current.date(byAdding: .year, value: 1, to: Date()) {
            return oneYearAfter
        }
        let year = Calendar.autoupdatingCurrent.component(.year, from: Date())
        return self.date(year: year + 2, month: 1, day: 1)
    }
    
    private func date(year: Int, month: Int, day: Int) -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = 0
        dateComponents.minute = 0
        dateComponents.second = 0

        return Calendar.current.date(from: dateComponents) ?? Date()
    }

}
