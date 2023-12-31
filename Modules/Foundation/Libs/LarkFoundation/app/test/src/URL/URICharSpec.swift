//
//  URICharSpec.swift
//  LarkFoundationDevEEUnitTest
//
//  Created by qihongye on 2020/1/15.
//

import Foundation
import XCTest

@testable import LarkFoundation

class URICharSpec: XCTestCase {

    // swiftlint:disable overridden_super_call
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    // swiftlint:disable overridden_super_call
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testUriUnescape() {
        let ptr = createURIPtr("%253A%25F0%259F%2598%2584%25E5%2593%2588%25E3%2582%258D%25E3%2583%25AD")
        if true {
            let output = uriUnescape(ptr, 0, ptr.count)
            let outStr = String(bytes: output, encoding: .utf8)
            XCTAssertNotNil(outStr)
            XCTAssertEqual(outStr!, ":😄哈ろロ")
        }
        if true {
            let output = uriUnescape(ptr, 3, ptr.count - 5)
            let outStr = String(bytes: output, encoding: .utf8)
            XCTAssertNil(outStr)
        }
        if true {
            let output = uriUnescape(ptr, 3, ptr.count - 18)
            let outStr = String(bytes: output, encoding: .utf8)
            XCTAssertNotNil(outStr)
            XCTAssertEqual(outStr!, "3A😄哈ろ")
        }
    }

    func testUriUnescapeWithPlus() {
        if true {
            let ptr = createURIPtr("https://applink.feishu.cn/client/virtual_hongbao/popup?activity=ug20200315&amount=12.50&bdp_launch_query=place_holder&desc=%E4%BD%A0%E5%B7%B2%E7%B4%AF%E8%AE%A1%E8%8E%B7%E5%BE%97+220.00+%E5%85%83%E6%B4%BB%E8%B7%83%E7%BA%A2%E5%8C%85%EF%BC%8C%E5%A5%96%E5%8A%B1%E5%B0%86%E4%BA%8E%E6%B4%BB%E5%8A%A8%E7%BB%93%E6%9D%9F%E5%90%8E+7+%E4%B8%AA%E5%B7%A5%E4%BD%9C%E6%97%A5%E5%86%85%E7%BB%9F%E4%B8%80%E5%8F%91%E6%94%BE%EF%BC%8C%E8%AF%B7%E6%B3%A8%E6%84%8F%E9%A2%86%E5%8F%96%E3%80%82&from_scenes=message&title=%E6%81%AD%E5%96%9C%E4%BD%A0%EF%BC%81%E8%8E%B7%E5%BE%97%E4%B8%80%E4%B8%AA%E6%B4%BB%E8%B7%83%E7%BA%A2%E5%8C%85+&type=16")
            let output = uriUnescape(ptr, 0, ptr.count)
            let expect = "https://applink.feishu.cn/client/virtual_hongbao/popup?activity=ug20200315&amount=12.50&bdp_launch_query=place_holder&desc=你已累计获得 220.00 元活跃红包，奖励将于活动结束后 7 个工作日内统一发放，请注意领取。&from_scenes=message&title=恭喜你！获得一个活跃红包 &type=16"
            XCTAssertEqual(String(bytes: output, encoding: .utf8), expect)
        }

        if true {
            let ptr = createURIPtr("http+://domain+a/path+a?query=a+a#a+a")
            let expect = "http+://domain+a/path+a?query=a%20a#a+a"
            switch parseURI(ptr) {
            case .error(let error):
                XCTAssert(false, error.localizedDescription)
            case .ok(let uri):
                let output = String(bytes: uri.validURI(), encoding: .utf8)
                XCTAssertNotNil(output)
                XCTAssertEqual(output!, expect)
            }
        }
    }

    func testIsPChar() {
        let ptr = createURIPtr("?")
        XCTAssertFalse(isPChar(ptr, 0))
    }

    func testNormalParseURI() {
        if true {
            let urlStr = "https://ad.oceanengine.com/athena/index.html?key=cb790ca553ed7253d29a4dbd4041281b62c449f55d6faaeb4e744370c9b34e38#/"
            let ptr = createURIPtr(urlStr)
            switch parseURI(ptr) {
            case .error(let error):
                XCTAssert(false, error.localizedDescription)
            case .ok(let uri):
                let output = String(bytes: uri.validURI(), encoding: .utf8)
                XCTAssertNotNil(output)
                XCTAssertEqual(output!, urlStr)
            }
        }
        if true {
            let urlStr = "foo://example.com:8042/over/there?name=ferret#nose"
            let ptr = createURIPtr(urlStr)
            switch parseURI(ptr) {
            case .error(let error):
                XCTAssert(false, error.localizedDescription)
            case .ok(let uri):
                let output = String(bytes: uri.validURI(), encoding: .utf8)
                XCTAssertNotNil(output)
                XCTAssertEqual(output!, urlStr)
            }
        }
    }

    func testBadParseURI() {
        if true {
            let urlStr = "https://metrics-fe.byted.org/web/plot/metrics#1⃣️1h-ago,alisg;sum:counter:toutiao.service.thrift.aweme.web.goapi.call.error.throughput{dc=alisg,from_cluster=default,method=GetSettingsFromIES,to=toutiao.settings.settings,to_cluster=iesdy};0"
            let expect = "https://metrics-fe.byted.org/web/plot/metrics#1%E2%83%A3%EF%B8%8F1h-ago,alisg;sum:counter:toutiao.service.thrift.aweme.web.goapi.call.error.throughput%7Bdc=alisg,from_cluster=default,method=GetSettingsFromIES,to=toutiao.settings.settings,to_cluster=iesdy%7D;0"
            XCTAssertNil(URL(string: urlStr))
            let ptr = createURIPtr(urlStr)
            switch parseURI(ptr) {
            case .error(let error):
                XCTAssert(false, error.localizedDescription)
            case .ok(let uri):
                let output = String(bytes: uri.validURI(), encoding: .utf8)
                XCTAssertNotNil(output)
                XCTAssertNotNil(URL(string: output!))
                XCTAssertEqual(output!, expect)
            }
        }
        if true {
            let urlStr = "https://www.baidu.com/😄哈ろロ"
            let expect = "https://www.baidu.com/%F0%9F%98%84%E5%93%88%E3%82%8D%E3%83%AD"
            XCTAssertNil(URL(string: urlStr))

            let ptr = createURIPtr(urlStr)
            switch parseURI(ptr) {
            case .error(let error):
                XCTAssert(false, error.localizedDescription)
            case .ok(let uri):
                let output = String(bytes: uri.validURI(), encoding: .utf8)
                XCTAssertNotNil(output)
                XCTAssertNotNil(URL(string: output!))
                XCTAssertEqual(output!, expect)
            }
        }
        if true {
            let urlStr = "www.baidu.com/😄哈ろロ"
            let expect = "https://www.baidu.com/%F0%9F%98%84%E5%93%88%E3%82%8D%E3%83%AD"
            XCTAssertNil(URL(string: urlStr))

            let ptr = createURIPtr(urlStr)
            switch parseURI(ptr) {
            case .error(let error):
                XCTAssert(false, error.localizedDescription)
            case .ok(let uri):
                let output = String(bytes: uri.validURI(), encoding: .utf8)
                XCTAssertNotNil(output)
                XCTAssertNotNil(URL(string: output!))
                XCTAssertEqual(output!, expect)
            }
        }
        if true {
            let urlStr = "192.168.1.1/?😄=aaa&bb=哈ろロ"
            let expect = "https://192.168.1.1/?%F0%9F%98%84=aaa&bb=%E5%93%88%E3%82%8D%E3%83%AD"
            XCTAssertNil(URL(string: urlStr))

            let ptr = createURIPtr(urlStr)
            switch parseURI(ptr) {
            case .error(let error):
                XCTAssert(false, error.localizedDescription)
            case .ok(let uri):
                let output = String(bytes: uri.validURI(), encoding: .utf8)
                XCTAssertNotNil(output)
                XCTAssertNotNil(URL(string: output!))
                XCTAssertEqual(output!, expect)
            }
        }
    }

//    func testURLWithInvalidChar() {
//        let urlStr = "https://一元机场.com/中文path?s=中文query#/中文hash"
//        let expect = ""
//        do {
//            let url = try URL.forceCreateURL(string: urlStr)
//            XCTAssertEqual(url.absoluteString, expect)
//        } catch {
//            XCTAssertNil(error)
//        }
//    }

    func testMultiURIEncode() {
        let urlStr = "https%253A%252F%252Fmetrics-fe.byted.org%252Fweb%252Fplot%252Fmetrics%25231%25E2%2583%25A3%25EF%25B8%258F1h-ago👌%252Calisg%253Bsum%253Acounter%253Atoutiao.service.thrift.aweme.web.goapi.call.error.throughput%257Bdc%253Dalisg%252Cfrom_cluster%253Ddefault%252Cmethod%253DGetSettingsFromIES%252Cto%253Dtoutiao.settings.settings%252Cto_cluster%253Diesdy%257D%253B0"
        let expect = "https://metrics-fe.byted.org/web/plot/metrics#1%E2%83%A3%EF%B8%8F1h-ago%F0%9F%91%8C,alisg;sum:counter:toutiao.service.thrift.aweme.web.goapi.call.error.throughput%7Bdc=alisg,from_cluster=default,method=GetSettingsFromIES,to=toutiao.settings.settings,to_cluster=iesdy%7D;0"
        do {
            let url = try URL.forceCreateURL(string: urlStr)
            XCTAssertEqual(url.absoluteString, expect)
        } catch {
            XCTAssertNil(error)
        }
    }

    func testURLs() {
        if true {
            let urlStr = "https://sso.bytedance.com/oauth2/userinfo?access_token={token}"
            let expect = "https://sso.bytedance.com/oauth2/userinfo?access_token=%7Btoken%7D"
            do {
                let url = try URL.forceCreateURL(string: urlStr)
                XCTAssertEqual(url.absoluteString, expect)
            } catch {
                XCTAssertNil(error)
            }
        }

        let urls = ["http://h1.ioliu.cn/bing/HighlandsSquirrel_ZH-CN1369975915_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/SunlitScree_ZH-CN7556627842_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/SpeedFlying_ZH-CN1276366046_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/GypsumSand_ZH-CN1223884637_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/CormorantMackerel_ZH-CN1167678548_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/ValGardena_ZH-CN3346883933_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/Boudhanath_ZH-CN2114569722_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/MuskOxWinter_ZH-CN2030874541_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/SeventeenSolstice_ZH-CN4901756341_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/Zugspitze_ZH-CN1831794930_1920x1080.jpg",
        "http://h1.ioliu.cn/bing/Rakan_ZH-CN8521004423_1920x1080.jpg",
        "https://www.google.com/search?safe=strict&ei=rXU6XuDICarAz7sPxKC_8AY&q=dec-octet&oq=dec-octet&gs_l=psy-ab.3..0i8i10i30.24055.24428..24954...0.0..0.176.550.0j4......0....1j2..gws-wiz.....0..0i13j0i13i30j0i13i10i30.3fVTu76W-VQ&ved=0ahUKEwig0-Ww-LnnAhUq4HMBHUTQD24Q4dUDCAs&uact=5"]
        for url in urls {
            do {
                let output = try URL.forceCreateURL(string: url)
                XCTAssertEqual(output.absoluteString, url)
            } catch {
                XCTAssertNil(error)
            }
        }
    }

    func testInvalidUrls() {
        let urlTuples = [
            ("http://[2001:db8:1:0:20c:29ff:fe96:8b55]:8080/?=<>[#]", "http://[2001:db8:1:0:20c:29ff:fe96:8b55]:8080/?=%3C%3E%5B#%5D"),
            ("http://10.43.159.11:8080/?=<>[]", "http://10.43.159.11:8080/?=%3C%3E%5B%5D"),
            ("http://zdh-11-IPv4:8080/?=<#>[#]", "http://zdh-11-IPv4:8080/?=%3C#%3E%5B%23%5D"),
            ("//123abc/456def", "//123abc/456def"),
            ("/123abc/456def", "/123abc/456def")
        ]
        for (url, expect) in urlTuples {
            do {
                let output = try URL.forceCreateURL(string: url)
                XCTAssertEqual(output.absoluteString, expect)
            } catch {
                XCTAssertNil(error)
            }
        }
    }

    func testCreateURL3986() {
        let urlTuples = [
            ("http://[2001:db8:1:0:20c:29ff:fe96:8b55]:8080/?=<>[#]", "http://[2001:db8:1:0:20c:29ff:fe96:8b55]:8080/?=%3C%3E%5B#%5D"),
            ("http://10.43.159.11:8080/?=<>[]", "http://10.43.159.11:8080/?=%3C%3E%5B%5D"),
            ("http://zdh-11-IPv4:8080/?=<#>[#]", "http://zdh-11-IPv4:8080/?=%3C#%3E%5B%23%5D"),
            ("https://applink.feishu.cn/client/virtual_hongbao/popup?activity=ug20200315&amount=12.50&bdp_launch_query=place_holder&desc=%E4%BD%A0%E5%B7%B2%E7%B4%AF%E8%AE%A1%E8%8E%B7%E5%BE%97+220.00+%E5%85%83%E6%B4%BB%E8%B7%83%E7%BA%A2%E5%8C%85%EF%BC%8C%E5%A5%96%E5%8A%B1%E5%B0%86%E4%BA%8E%E6%B4%BB%E5%8A%A8%E7%BB%93%E6%9D%9F%E5%90%8E+7+%E4%B8%AA%E5%B7%A5%E4%BD%9C%E6%97%A5%E5%86%85%E7%BB%9F%E4%B8%80%E5%8F%91%E6%94%BE%EF%BC%8C%E8%AF%B7%E6%B3%A8%E6%84%8F%E9%A2%86%E5%8F%96%E3%80%82&from_scenes=message&title=%E6%81%AD%E5%96%9C%E4%BD%A0%EF%BC%81%E8%8E%B7%E5%BE%97%E4%B8%80%E4%B8%AA%E6%B4%BB%E8%B7%83%E7%BA%A2%E5%8C%85+&type=16", "https://applink.feishu.cn/client/virtual_hongbao/popup?activity=ug20200315&amount=12.50&bdp_launch_query=place_holder&desc=%E4%BD%A0%E5%B7%B2%E7%B4%AF%E8%AE%A1%E8%8E%B7%E5%BE%97%20220.00%20%E5%85%83%E6%B4%BB%E8%B7%83%E7%BA%A2%E5%8C%85%EF%BC%8C%E5%A5%96%E5%8A%B1%E5%B0%86%E4%BA%8E%E6%B4%BB%E5%8A%A8%E7%BB%93%E6%9D%9F%E5%90%8E%207%20%E4%B8%AA%E5%B7%A5%E4%BD%9C%E6%97%A5%E5%86%85%E7%BB%9F%E4%B8%80%E5%8F%91%E6%94%BE%EF%BC%8C%E8%AF%B7%E6%B3%A8%E6%84%8F%E9%A2%86%E5%8F%96%E3%80%82&from_scenes=message&title=%E6%81%AD%E5%96%9C%E4%BD%A0%EF%BC%81%E8%8E%B7%E5%BE%97%E4%B8%80%E4%B8%AA%E6%B4%BB%E8%B7%83%E7%BA%A2%E5%8C%85%20&type=16"),
            ("http+s://domain+a/path+a/?query+a=a+a/#a+a", "http+s://domain+a/path+a/?query+a=a%20a/#a+a")
        ]
        for (url, expect) in urlTuples {
            do {
                let output = try URL.createURL3986(string: url)
                XCTAssertEqual(output.absoluteString, expect)
            } catch {
                XCTAssertNil(error)
            }
        }
    }

    func testURIError() {
        XCTAssertEqual(URIError.outOfMaxLength.localizedDescription, "Out of max uri length(\(1024 * 1024))")
        XCTAssertEqual(URIError.createUTF8StringFailed.localizedDescription, "Can not create utf8 string from uint8 array.")
        XCTAssertEqual(URIError.createURLFailed.localizedDescription, "Invalid input url string, can not create URL from string.")
        XCTAssertEqual(URIError.nullInputURIString.localizedDescription, "Input uri string is null.")
        XCTAssertEqual(URIError.parseOutOfBounds("Test").localizedDescription, "Index out of string bounds when parseTest")
        XCTAssertEqual(URIError.parseError("Test").localizedDescription, "Parse uri error: {Test}")

    }

    func testBadInputErrorHandler() {
        if true {
            let input = "https://a/b/?c+c=d+d"
            do {
                try URL.createURL3986(string: input)
            } catch {
                XCTAssertNotNil(error)
                XCTAssertEqual(error.localizedDescription, URIError.createURLFailed.localizedDescription)
            }
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        let urlStr = "https%253A%252F%252Fmetrics-fe.byted.org%252Fweb%252Fplot%252Fmetrics%25231%25E2%2583%25A3%25EF%25B8%258F1h-ago👌%252Calisg%253Bsum%253Acounter%253Atoutiao.service.thrift.aweme.web.goapi.call.error.throughput%257Bdc%253Dalisg%252Cfrom_cluster%253Ddefault%252Cmethod%253DGetSettingsFromIES%252Cto%253Dtoutiao.settings.settings%252Cto_cluster%253Diesdy%257D%253B0"
        self.measure {
            // Put the code you want to measure the time of here.
            _ = try? URL.forceCreateURL(string: urlStr)
        }
    }

    func testPerformanceSystemURL() {
        // This is an example of a performance test case.
        let urlStr = "https%253A%252F%252Fmetrics-fe.byted.org%252Fweb%252Fplot%252Fmetrics%25231%25E2%2583%25A3%25EF%25B8%258F1h-ago%252Calisg%253Bsum%253Acounter%253Atoutiao.service.thrift.aweme.web.goapi.call.error.throughput%257Bdc%253Dalisg%252Cfrom_cluster%253Ddefault%252Cmethod%253DGetSettingsFromIES%252Cto%253Dtoutiao.settings.settings%252Cto_cluster%253Diesdy%257D%253B0"
        self.measure {
            // Put the code you want to measure the time of here.
            _ = URL(string: urlStr)
        }
    }
}
