//
//  ECOCookieTestCase.swift
//  ECOInfraDevEEUnitTest
//
//  Created by Meng on 2021/2/20.
//

// test

import XCTest
@testable import ECOInfra
import Swinject
import LarkContainer
import LarkOPInterface
import CryptoSwift

// swiftlint:disable all
class ECOCookieDependencyImpl: ECOCookieDependency {
    var syncStrategy: [String: Any] = [:]
    var urlWhiteList: [String] = []
    var enableFGKeys: [String] = []

    var cookieSyncStrategy: [String: Any] {
        return syncStrategy
    }

    var requestCookieURLWhiteListForWebview: [String] {
        return urlWhiteList
    }

    func setUniqueId(_ uniqueId: OPAppUniqueID, for monitor: OPMonitor) -> OPMonitor {
        return monitor
            .addCategoryValue("appId", uniqueId.appID)
            .addCategoryValue("appType", OPAppTypeToString(uniqueId.appType))
    }

    func getFeatureGatingBoolValue(for key: String) -> Bool {
        return enableFGKeys.contains(key)
    }
}

class OPCookieTestCase: XCTestCase {
    static let dependency = ECOCookieDependencyImpl()
    static let container = Container()
    @Provider private var service: ECOCookieService

    override class func setUp() {
        super.setUp()
        implicitResolver = container
        _ = Assembler([ECOCookieAssembly()], container: container)
        container.register(ECOCookieDependency.self) { _ in
            return dependency
        }
    }

    override func setUp() {
        super.setUp()
        HTTPCookieStorage.shared.cookies?.forEach({
            HTTPCookieStorage.shared.deleteCookie($0)
        })
        Self.dependency.syncStrategy = [:]
        Self.dependency.urlWhiteList = []
        Self.dependency.enableFGKeys = [
            ECOCookieConfig.enableCookieIsolate,
            ECOCookieConfig.enableWebviewCookieIsolate
        ]
    }

    func testCookieService() {
        let globalCookie = service.cookieStorage(withIdentifier: nil)
        XCTAssertTrue(globalCookie is ECOCookieGlobalPlugin)

        let gadgetGlobalCookie = service.gadgetCookieStorage(with: nil)
        XCTAssertTrue(gadgetGlobalCookie is ECOCookieGlobalPlugin)

        let gadgetCookie1 = service.cookieStorage(withIdentifier: "identifier")
        XCTAssertTrue(gadgetCookie1 is ECOCookiePlugin)

        let uniqueId = OPAppUniqueID(appID: "appId", identifier: "", versionType: .current, appType: .gadget)
        let gadgetCookie2 = service.gadgetCookieStorage(with: uniqueId)
        XCTAssertFalse(gadgetCookie2 is ECOCookiePlugin) // not in white list
        XCTAssertTrue(gadgetCookie2 is ECOCookieGlobalPlugin)

        Self.dependency.syncStrategy = [
            "mode": 0,
            "white_app_list": ["appId"],
            "apply_all": false
        ]
        let gadgetCookie3 = service.gadgetCookieStorage(with: uniqueId)
        XCTAssertTrue(gadgetCookie3 is ECOCookieGadgetSync)

        // let gadgetCookie4 = service.gadgetCookieStorage(with: uniqueId)
        // XCTAssertTrue(gadgetCookie3 === gadgetCookie4)

        let dataStore3 = service.gadgetWebsiteDataStore(with: nil)
        XCTAssertFalse(dataStore3.isPersistent)

        let cookie = HTTPCookie(properties: [
            .domain: "www.baidu.com",
            .name: "name",
            .path: "/",
            .value: "value"
        ])!
        gadgetCookie3.saveCookies([cookie])
        Self.dependency.urlWhiteList = ["www.baidu.com"]
        let dataStore4 = service.gadgetWebsiteDataStore(with: uniqueId)

        let exception = expectation(description: "website data store cookies")
        DispatchQueue.main.async {
            dataStore4.httpCookieStore.getAllCookies({ cookies in
                XCTAssertEqual(cookies.count, 1)
                XCTAssertEqual(cookies[0].domain, "www.baidu.com")
                XCTAssertEqual(cookies[0].name, "name")
                XCTAssertEqual(cookies[0].path, "/")
                XCTAssertEqual(cookies[0].value, "value")
                exception.fulfill()
            })
        }
        wait(for: [exception], timeout: 1.0)
    }

    func testConfigMode0() {
        Self.dependency.syncStrategy = [
            "mode": 0, // rw_all
            "white_app_list": ["app"],
            "apply_all": false
        ]
        let uniqueId = OPAppUniqueID(appID: "app", identifier: "", versionType: .current, appType: .gadget)
        let storage = service.gadgetCookieStorage(with: uniqueId)

        let cookie = HTTPCookie(properties: [
            .name: "name",
            .domain: "www.baidu.com",
            .path: "/",
            .value: "value"
        ])!

        // write all
        storage.saveCookies([cookie])
        let cookies = HTTPCookieStorage.shared.cookies?.filter({ $0.name == "name" }) ?? []
        XCTAssertEqual(cookies.count, 2)
        XCTAssertTrue(cookies.allSatisfy({ $0.name == "name" }))
        XCTAssertTrue(cookies.allSatisfy({ $0.value == "value" }))
        XCTAssertTrue(cookies.allSatisfy({ $0.path == "/" }))
        XCTAssertTrue(cookies.allSatisfy({ $0.domain.hasPrefix("www.baidu.com") }))
        XCTAssertEqual(cookies.filter({ $0.domain == "www.baidu.com" }).count, 1)
        XCTAssertEqual(cookies.filter({ $0.domain == "www.baidu.com.\(uniqueId.appID.md5()).gadget.lark" }).count, 1)

        // clear
        HTTPCookieStorage.shared.cookies?.forEach({ HTTPCookieStorage.shared.deleteCookie($0) })

        // read all
        let isolateCookie = HTTPCookie(properties: [
            .name: "name1",
            .domain: "www.baidu.com.\("app".md5()).gadget.lark",
            .path: "/",
            .value: "value"
        ])!

        let otherCookie = HTTPCookie(properties: [
            .name: "name1",
            .domain: "www.apple.com",
            .path: "/",
            .value: "value"
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
        HTTPCookieStorage.shared.setCookie(isolateCookie)
        HTTPCookieStorage.shared.setCookie(otherCookie)
        let readCookies = storage.cookies(for: URL(string: "https://www.baidu.com/index.html")!)
        XCTAssertEqual(readCookies.count, 2)
        XCTAssertTrue(readCookies.allSatisfy({ $0.domain == "www.baidu.com" }))
        XCTAssertTrue(readCookies.allSatisfy({ $0.value == "value" }))
        XCTAssertEqual(readCookies.filter({ $0.name == "name" }).count, 1)
        XCTAssertEqual(readCookies.filter({ $0.name == "name1" }).count, 1)
    }

    func testConfigMode1() {
        Self.dependency.syncStrategy = [
            "mode": 1, // rw_gadget
            "white_app_list": ["app"],
            "apply_all": false
        ]
        let uniqueId = OPAppUniqueID(appID: "app", identifier: "", versionType: .current, appType: .gadget)
        let storage = service.gadgetCookieStorage(with: uniqueId)

        let cookie = HTTPCookie(properties: [
            .name: "name",
            .domain: "www.baidu.com",
            .path: "/",
            .value: "value"
        ])!
        storage.saveCookies([cookie])

        // write gadget
        let allCookies = HTTPCookieStorage.shared.cookies ?? []
        XCTAssertEqual(allCookies.count, 1)
        XCTAssertEqual(allCookies[0].name, "name")
        XCTAssertEqual(allCookies[0].domain, "www.baidu.com.\("app".md5()).gadget.lark")
        XCTAssertEqual(allCookies[0].path, "/")
        XCTAssertEqual(allCookies[0].value, "value")

        // clear
        HTTPCookieStorage.shared.cookies?.forEach({ HTTPCookieStorage.shared.deleteCookie($0) })

        // read gadget
        let gadgetCookie = HTTPCookie(properties: [
            .name: "name1",
            .domain: "www.baidu.com.\("app".md5()).gadget.lark",
            .path: "/",
            .value: "value1"
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
        HTTPCookieStorage.shared.setCookie(gadgetCookie)
        XCTAssertEqual(HTTPCookieStorage.shared.cookies?.count ?? 0, 2)
        let readCookies = storage.cookies(for: URL(string: "https://www.baidu.com/index.html")!)
        XCTAssertEqual(readCookies.count, 1)
        XCTAssertEqual(readCookies[0].name, "name1")
        XCTAssertEqual(readCookies[0].value, "value1")
    }

    func testConfigMode2() {
        Self.dependency.syncStrategy = [
            "mode": 2, // r_gadget_w_all
            "white_app_list": ["app"],
            "apply_all": false
        ]
        let uniqueId = OPAppUniqueID(appID: "app", identifier: "", versionType: .current, appType: .gadget)
        let storage = service.gadgetCookieStorage(with: uniqueId)

        let cookie = HTTPCookie(properties: [
            .name: "name",
            .domain: "www.baidu.com",
            .path: "/",
            .value: "value"
        ])!

        // write all
        storage.saveCookies([cookie])
        let cookies = HTTPCookieStorage.shared.cookies?.filter({ $0.name == "name" }) ?? []
        XCTAssertEqual(cookies.count, 2)
        XCTAssertTrue(cookies.allSatisfy({ $0.name == "name" }))
        XCTAssertTrue(cookies.allSatisfy({ $0.value == "value" }))
        XCTAssertTrue(cookies.allSatisfy({ $0.path == "/" }))
        XCTAssertTrue(cookies.allSatisfy({ $0.domain.hasPrefix("www.baidu.com") }))
        XCTAssertEqual(cookies.filter({ $0.domain == "www.baidu.com" }).count, 1)
        XCTAssertEqual(cookies.filter({ $0.domain == "www.baidu.com.\("app".md5()).gadget.lark" }).count, 1)

        // clear
        HTTPCookieStorage.shared.cookies?.forEach({ HTTPCookieStorage.shared.deleteCookie($0) })

        // read gadget
        let gadgetCookie = HTTPCookie(properties: [
            .name: "name1",
            .domain: "www.baidu.com.\("app".md5()).gadget.lark",
            .path: "/",
            .value: "value1"
        ])!
        HTTPCookieStorage.shared.setCookie(cookie)
        HTTPCookieStorage.shared.setCookie(gadgetCookie)
        XCTAssertEqual(HTTPCookieStorage.shared.cookies?.count ?? 0, 2)
        let readCookies = storage.cookies(for: URL(string: "https://www.baidu.com/index.html")!)
        XCTAssertEqual(readCookies.count, 1)
        XCTAssertEqual(readCookies[0].name, "name1")
        XCTAssertEqual(readCookies[0].value, "value1")
    }

    func testWhiteAppList() {
        Self.dependency.syncStrategy = [
            "mode": 0,
            "white_app_list": ["app1"],
            "apply_all": false
        ]
        let uniqueId1 = OPAppUniqueID(appID: "app1", identifier: "", versionType: .current, appType: .gadget)
        let storage1 = service.gadgetCookieStorage(with: uniqueId1)
        XCTAssertTrue(storage1 is ECOCookieGadgetSync)

        let uniqueId2 = OPAppUniqueID(appID: "app2", identifier: "", versionType: .current, appType: .gadget)
        let storage2 = service.gadgetCookieStorage(with: uniqueId2)
        XCTAssertTrue(storage2 is ECOCookieGlobalPlugin)
    }

    func testApplyAll() {
        Self.dependency.syncStrategy = [
            "mode": 0,
            "white_app_list": ["app1"],
            "apply_all": true
        ]
        let uniqueId = OPAppUniqueID(appID: "app2", identifier: "", versionType: .current, appType: .gadget)
        let storage = service.gadgetCookieStorage(with: uniqueId)
        XCTAssertTrue(storage is ECOCookieGadgetSync)
    }

    func testIsolateIdentifier() {
        let storage1 = service.cookieStorage(withIdentifier: nil)
        let storage2 = service.cookieStorage(withIdentifier: "identifier1")
        let storage3 = service.cookieStorage(withIdentifier: "identifier2")
        let storage4 = service.cookieStorage(withIdentifier: "identifier2")

        XCTAssertTrue(storage1 is ECOCookieGlobalPlugin)
        XCTAssertTrue(storage2 is ECOCookiePlugin)
        XCTAssertTrue(storage3 is ECOCookiePlugin)
        XCTAssertTrue(storage4 is ECOCookiePlugin)
        XCTAssertTrue(storage1 !== storage2)
        XCTAssertTrue(storage2 !== storage3)

        let plugin2 = storage2 as? ECOCookiePlugin
        let plugin3 = storage3 as? ECOCookiePlugin
        let plugin4 = storage4 as? ECOCookiePlugin
        XCTAssertNotEqual(plugin2?.identifier, plugin3?.identifier)
        XCTAssertEqual(plugin3?.identifier, plugin4?.identifier)
    }

    func testURLWhiteListForWebview() {
        Self.dependency.syncStrategy = [
            "mode": 0,
            "white_app_list": ["app"],
            "apply_all": true
        ]
        Self.dependency.urlWhiteList = ["www.baidu.com"]

        let cookie1 = HTTPCookie(properties: [
            .name: "name1",
            .domain: "www.baidu.com",
            .path: "/",
            .value: "value1"
        ])!
        let cookie2 = HTTPCookie(properties: [
            .name: "name2",
            .domain: "www.google.com",
            .path: "/",
            .value: "value2"
        ])!
        let cookie3 = HTTPCookie(properties: [
            .name: "name3",
            .domain: "www.baidu.com.\("app".md5()).gadget.lark",
            .path: "/",
            .value: "value3"
        ])!
        let cookie4 = HTTPCookie(properties: [
            .name: "name4",
            .domain: "www.google.com.\("app".md5()).gadget.lark",
            .path: "/",
            .value: "value4"
        ])!

        [cookie1, cookie2, cookie3, cookie4].forEach({ HTTPCookieStorage.shared.setCookie($0) })

        let uniqueId = OPAppUniqueID(appID: "app", identifier: "", versionType: .current, appType: .gadget)
        let dataStore = service.gadgetWebsiteDataStore(with: uniqueId)
        XCTAssertFalse(dataStore.isPersistent)

        let exception = expectation(description: "website data store cookies")
        DispatchQueue.main.async {
            dataStore.httpCookieStore.getAllCookies { cookies in
                XCTAssertEqual(cookies.count, 2)
                XCTAssertEqual(cookies.filter({ $0.name == "name1" }).count, 1)
                XCTAssertEqual(cookies.filter({ $0.name == "name3" }).count, 1)
                exception.fulfill()
            }
        }
        wait(for: [exception], timeout: 1.0)
    }

    func testSaveHTTPResponseCookie() {
        Self.dependency.syncStrategy = [
            "mode": 1,
            "white_app_list": ["app"],
            "apply_all": true
        ]

        let url = URL(string: "https://www.baidu.com/index.html")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "2.0", headerFields: [
            "Set-Cookie": "name=value; Path=/"
        ])!


        let uniqueId = OPAppUniqueID(appID: "app", identifier: "", versionType: .current, appType: .gadget)
        let storage = service.gadgetCookieStorage(with: uniqueId)
        storage.saveCookie(with: response)

        let allCookies = HTTPCookieStorage.shared.cookies ?? []
        XCTAssertEqual(allCookies.count, 1)
        XCTAssertEqual(allCookies[0].name, "name")
        XCTAssertEqual(allCookies[0].value, "value")
        XCTAssertEqual(allCookies[0].path, "/")
        XCTAssertEqual(allCookies[0].domain, "www.baidu.com.\("app".md5()).gadget.lark")
    }

    func testFGClose() {
        Self.dependency.enableFGKeys = []
        Self.dependency.syncStrategy = [
            "mode": 1,
            "white_app_list": ["app"],
            "apply_all": true
        ]

        let uniqueId = OPAppUniqueID(appID: "app", identifier: "", versionType: .current, appType: .gadget)
        let storage = service.gadgetCookieStorage(with: uniqueId)
        XCTAssertTrue(storage is ECOCookieGlobalPlugin)

        let dataStore = service.gadgetWebsiteDataStore(with: uniqueId)
        XCTAssertTrue(dataStore.isPersistent)

        XCTAssertFalse(service.enableCookieIsolate)
    }

    func testURLDomainConvert() {
        let url = URL(string: "https://www.baidu.com?param=xxx")!
        let convertURL = url.convertHost(handler: { $0 + ".suffix" })
        XCTAssertEqual(convertURL?.host ?? "", "www.baidu.com.suffix")
    }

    func testCookieDomainConvert() {
        let url = URL(string: "https://www.baidu.com?param=xxx")!
        let cookie = HTTPCookie(properties: [
            .name: "cookie-name",
            .domain: "www.baidu.com",
            .originURL: url,
            .path: "/",
            .value: "cookie-value"
        ])
        let convertCookie = cookie?.convertDomain(handler: { $0 + ".suffix" })

        // let convertURL = convertCookie?.properties?[.originURL] as? URL
        // XCTAssertEqual(convertURL?.host ?? "", "www.baidu.com.suffix") // 系统默认始终没有返回
        XCTAssertEqual(convertCookie?.domain ?? "", "www.baidu.com.suffix")
        XCTAssertEqual(convertCookie?.name ?? "", "cookie-name")
        XCTAssertEqual(convertCookie?.value ?? "", "cookie-value")
        XCTAssertEqual(convertCookie?.path ?? "", "/")
    }

    func testDomainSuffix() {
        Self.dependency.syncStrategy = [
            "mode": 1,
            "white_app_list": ["app"],
            "apply_all": true
        ]
        let url1 = URL(string: "https://localhost/index.html")!
        let cookie1 = HTTPCookie(properties: [
            .name: "name1",
            .domain: "localhost",
            .originURL: url1,
            .path: "/",
            .value: "value1"
        ])!
        let url2 = URL(string: "https://192.168.0.0:8080/index.html")!
        let cookie2 = HTTPCookie(properties: [
            .name: "name2",
            .domain: "192.168.0.0",
            .originURL: url2,
            .path: "/",
            .value: "value2"
        ])!
        let uniqueId = OPAppUniqueID(appID: "app", identifier: "", versionType: .current, appType: .gadget)
        let storage = service.gadgetCookieStorage(with: uniqueId)
        storage.saveCookies([cookie1, cookie2])

        let readCookies = HTTPCookieStorage.shared.cookies ?? []
        XCTAssertEqual(readCookies.count, 2)
        XCTAssertEqual(readCookies.filter({ $0.name == "name1" }).count, 1)
        XCTAssertEqual(readCookies.filter({ $0.name == "name2" }).count, 1)
        XCTAssertEqual(readCookies.filter({ $0.value == "value1" }).count, 1)
        XCTAssertEqual(readCookies.filter({ $0.value == "value2" }).count, 1)
        XCTAssertEqual(readCookies.filter({ $0.domain == "localhost.\("app".md5()).gadget.lark" }).count, 1)
        XCTAssertEqual(readCookies.filter({ $0.domain == "192.168.0.0.\("app".md5()).gadget.lark" }).count, 1)
    }
}
