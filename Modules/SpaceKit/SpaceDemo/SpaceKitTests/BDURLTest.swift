//
//  BDURLTest.swift
//  DocsTests
//
//  Created by huahuahu on 2018/11/15.
//  Copyright © 2018 Bytedance. All rights reserved.
//  swiftlint:disable type_body_length line_length file_length

import XCTest
@testable import SpaceKit
@testable import Docs
import Quick
import SwiftyJSON
import Nimble

class BDURLTest: BDTestBase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testURLHostAndPort() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let url = URL(string: "https://127.0.0.1:3001/path/")!
        XCTAssertEqual(url.hostAndPort!, "127.0.0.1:3001")
        XCTAssertEqual(URL(string: "https://127.0.0.1:3001")!.hostAndPort!, "127.0.0.1:3001")
        XCTAssertEqual(URL(string: "https://127.0.0.1:3001/")!.hostAndPort!, "127.0.0.1:3001")
    }

    func testUrlRegex() {
        var str1 = "12134http://baidu.com fads"
        var urlRanges = str1.docs.urlRanges
//        str1.

        var urls = urlRanges.map {
            String(str1[Range($0, in: str1)!])
        }
//        XCTAssertEqual(urls, ["http://baidu.com"])

        str1 = "22 baidu.com "
        urlRanges = str1.docs.urlRanges
        urls = urlRanges.map {
            String(str1[Range($0, in: str1)!])
        }
        XCTAssertEqual(urls, ["baidu.com"])

        str1 = "22 www.baidu.com "
        urlRanges = str1.docs.urlRanges
        urls = urlRanges.map {
            String(str1[Range($0, in: str1)!])
        }
        XCTAssertEqual(urls, ["www.baidu.com"])

        str1 = "22 www.baidu.com https://www.baidu.com"
        urlRanges = str1.docs.urlRanges
        urls = urlRanges.map {
            String(str1[Range($0, in: str1)!])
        }
        XCTAssertEqual(urls, ["www.baidu.com", "https://www.baidu.com"])

        str1 = "22 www.baidu.com/dafkjdfasklfjasdfhjk https://www.baidu.com"
        urlRanges = str1.docs.urlRanges
        urls = urlRanges.map {
            String(str1[Range($0, in: str1)!])
        }
        XCTAssertEqual(urls, ["www.baidu.com/dafkjdfasklfjasdfhjk", "https://www.baidu.com"])

        str1 = "https://docs.bytedance.net/doc/W7CAG0ekyhyckshhYsRFOc"
        urlRanges = str1.docs.urlRanges
        urls = urlRanges.map {
            String(str1[Range($0, in: str1)!])
        }
        XCTAssertEqual(urls, ["https://docs.bytedance.net/doc/W7CAG0ekyhyckshhYsRFOc"])

    }
}

struct ServerConfig {
    /// 后台返回的合法的pathlist
    var pathList: [String]!
    /// 后台返回的用户的host
    var userHost: String!
    /// 后台返回的url匹配模式
    var urlMatchPatterns: [String]!
    /// 后台是否下发配置，打开了新域名
    var useNewDomain: Bool!

    var h5PathPrefix: String?

    var pathMapStr: String?
    var tokenPatternStr: String?
    var pathGenerator: String?

    /// 没有开启新域名
    static let noNewDomain: ServerConfig = {
        var config = ServerConfig()
        config.pathList = []
        config.userHost = ""
        config.urlMatchPatterns = []
        config.useNewDomain = false
        config.h5PathPrefix = ""
        config.pathMapStr = "{\n  \"\\/share\\/folders\\/\" : \"share_root\",\n  \"\\/folder\\/\" : \"folder\",\n  \"\" : \"recent\",\n  \"\\/home\\/recents\\/\" : \"recent\",\n  \"\\/help\\/\" : \"help\",\n  \"\\/home\\/share\\/files\\/\" : \"share\",\n  \"\\/shared\\/folders\\/\" : \"share_root\",\n  \"\\/home\\/star\\/\" : \"star\",\n  \"\\/app\\/upgrade\\/\" : \"upgrade\",\n  \"\\/native\\/newyearsurvey\\/\" : \"newyear_survey\",\n  \"\\/home\\/\" : \"recent\",\n  \"\\/app\\/upgrade\\/\" : \"upgrade\"\n}"
        config.tokenPatternStr = "{\n  \"tokenReg\" : \"\\/([\\\\w]{10,})\",\n  \"urlReg\" : \"^(\\/space)?\\/(?<type>(doc|sheet|mindnote|slide|file|bitable|folder))\\/(?<token>[^\\\\\\/]+)\",\n  \"typeReg\" : \"\\/(doc|sheet|mindnote|slide|file|bitable|folder)\\/\"\n}"
        config.pathGenerator = "{\n  \"blank\" : \"\\/blank\\/\",\n  \"default\" : \"\\/${type}\\/${token}\",\n  \"upgrade\" : \"\\/space\\/app\\/upgrade\"\n}"
        return config
    }()

    /// 新域名，a.feishu.cn
    static let newDomainAfeishu: ServerConfig = {
        var config = ServerConfig()
        config.pathList = ["space"]
        config.userHost = "a.feishu.cn"
        config.urlMatchPatterns = ["feishu\\.cn/space", "larksuit\\.com/space", "bear-test\\.bytedance\\.net/space"]
        config.useNewDomain = true
        config.h5PathPrefix = "space"

        config.pathMapStr = "{\n  \"\\/space\\/app\\/upgrade\\/\" : \"upgrade\",\n  \"\\/space\\/native\\/newyearsurvey\\/\" : \"newyear_survey\",\n  \"\\/space\\/home\\/share\\/files\\/\" : \"share\",\n  \"\\/space\\/home\\/\" : \"recent\",\n  \"\\/space\\/home\\/star\\/\" : \"star\",\n  \"\\/space\\/help\\/\" : \"help\",\n  \"\\/space\\/home\\/recents\\/\" : \"recent\",\n  \"\\/space\" : \"recent\",\n  \"\\/app\\/upgrade\\/\" : \"upgrade\",\n  \"\\/space\\/folder\\/\" : \"folder\",\n  \"\\/space\\/share\\/folders\\/\" : \"share_root\",\n  \"\\/space\\/shared\\/folders\\/\" : \"share_root\"\n}"
        config.tokenPatternStr = "{\n  \"tokenReg\" : \"\\/([\\\\w]{16,})\",\n  \"typeReg\" : \"\\/(doc|sheet|mindnote|slide|file|bitable|folder)\\/\",\n  \"urlReg\" : \"^(\\/space)?\\/(?<type>(doc|sheet|mindnote|slide|file|bitable|folder))\\/(?<token>[^\\\\\\/]+)\"\n}"
        config.pathGenerator =  "{\n  \"upgrade\" : \"\\/space\\/app\\/upgrade\",\n  \"blank\" : \"\\/space\\/blank\\/\",\n  \"default\" : \"\\/space\\/${type}\\/${token}\"\n}"

        return config
    }()

    /// 新域名没有开启，初始化SDK时，用户域名是a.feishu.cn
    static let newDomainCloseUserNew: ServerConfig = {
        var config = ServerConfig()
        config.pathList = ["space"]
        config.userHost = "a.feishu.cn"
        config.urlMatchPatterns = ["feishu\\.cn/space", "larksuit\\.com/space", "bear-test\\.bytedance\\.net/space"]
        config.useNewDomain = false
        config.h5PathPrefix = "space"
        config.pathMapStr = "{\n  \"\\/space\\/share\\/folders\\/\" : \"share_root\",\n  \"\\/space\\/folder\\/\" : \"folder\",\n  \"\\/space\" : \"recent\",\n  \"\\/space\\/home\\/recents\\/\" : \"recent\",\n  \"\\/space\\/help\\/\" : \"help\",\n  \"\\/space\\/home\\/share\\/files\\/\" : \"share\",\n  \"\\/space\\/shared\\/folders\\/\" : \"share_root\",\n  \"\\/space\\/home\\/star\\/\" : \"star\",\n  \"\\/space\\/app\\/upgrade\\/\" : \"upgrade\",\n  \"\\/space\\/native\\/newyearsurvey\\/\" : \"newyear_survey\",\n  \"\\/space\\/home\\/\" : \"recent\",\n  \"\\/app\\/upgrade\\/\" : \"upgrade\"\n}"
        config.tokenPatternStr = "{\n  \"typeReg\" : \"\\/(doc|sheet|mindnote|slide|file|bitable|folder)\\/\",\n  \"tokenReg\" : \"\\/([\\\\w]{16,})\",\n  \"urlReg\" : \"^(\\/space)?\\/(?<type>(doc|sheet|mindnote|slide|file|bitable))\\/(?<token>[^\\\\\\/]+)\"\n}"
        config.pathGenerator = "{\n  \"upgrade\" : \"\\/space\\/app\\/upgrade\",\n  \"default\" : \"\\/space\\/${type}\\/${token}\",\n  \"blank\" : \"\\/space\\/blank\\/\"\n}"

        return config
    }()

    static let newDomainNoSpace: ServerConfig = {
        var config = ServerConfig()
        config.pathList = ["space"]
        config.userHost = "a.feishu.cn"
        config.urlMatchPatterns = ["feishu\\.cn/space", "larksuit\\.com/space", "bear-test\\.bytedance\\.net/space"]
        config.useNewDomain = true
        config.h5PathPrefix = ""
        config.pathMapStr = "{\n  \"\\/space\\/share\\/folders\\/\" : \"share_root\",\n  \"\\/space\" : \"recent\",\n  \"\\/space\\/native\\/newyearsurvey\\/\" : \"newyear_survey\",\n  \"\\/space\\/home\\/star\\/\" : \"star\",\n  \"\\/space\\/home\\/share\\/files\\/\" : \"share\",\n  \"\\/app\\/upgrade\\/\" : \"upgrade\",\n  \"\\/space\\/folder\\/\" : \"folder\",\n  \"\\/space\\/home\\/\" : \"recent\",\n  \"\\/space\\/shared\\/folders\\/\" : \"share_root\",\n  \"\\/space\\/app\\/upgrade\\/\" : \"upgrade\",\n  \"\\/space\\/help\\/\" : \"help\",\n  \"\\/space\\/home\\/recents\\/\" : \"recent\"\n}"
        config.tokenPatternStr = "{\n  \"tokenReg\" : \"\\/([\\\\w]{10,})\",\n  \"urlReg\" : \"^(\\/space)?\\/(?<type>(doc|sheet|mindnote|slide|file|bitable|folder))\\/(?<token>[^\\\\\\/]+)\",\n  \"typeReg\" : \"\\/(doc|sheet|mindnote|slide|file|bitable|folder)\\/\"\n}"
        config.pathGenerator = "{\n  \"blank\" : \"\\/blank\\/\",\n  \"default\" : \"\\/${type}\\/${token}\",\n  \"upgrade\" : \"\\/space\\/app\\/upgrade\"\n}"
        return config
    }()
}

func getcurrentConfig() -> ServerConfig {
    var config = ServerConfig()
    config.pathList = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.validPathsKey) ?? []
    config.userHost = UserDefaults.standard.string(forKey: UserDefaultKeys.domainKey)
    config.urlMatchPatterns = UserDefaults.standard.stringArray(forKey: UserDefaultKeys.validURLMatchKey) ?? []
    config.useNewDomain = UserDefaults.standard.bool(forKey: UserDefaultKeys.isNewDomainSystemKey)
    config.h5PathPrefix = UserDefaults.standard.string(forKey: UserDefaultKeys.domainConfigH5PathPrefix)
    config.pathMapStr = UserDefaults.standard.string(forKey: UserDefaultKeys.domainConfigPathMap)
    config.tokenPatternStr = UserDefaults.standard.string(forKey: UserDefaultKeys.domainConfigTokenTypePattern)
    config.pathGenerator = UserDefaults.standard.string(forKey: UserDefaultKeys.domainConfigPathGenerator)
    return config
}

func setConfig(_ config: ServerConfig) {
    UserDefaults.standard.set(config.pathList, forKey: UserDefaultKeys.validPathsKey)
    UserDefaults.standard.set(config.userHost, forKey: UserDefaultKeys.domainKey)
    UserDefaults.standard.set(config.urlMatchPatterns, forKey: UserDefaultKeys.validURLMatchKey)
    UserDefaults.standard.set(config.useNewDomain, forKey: UserDefaultKeys.isNewDomainSystemKey)
    var json = JSON()
    if let h5Prefix = config.h5PathPrefix {
        json["h5PathPrefix"] = JSON(parseJSON: h5Prefix)
    }
    config.pathMapStr.map { json["pathMap"] = JSON(parseJSON: $0) }
    config.tokenPatternStr.map { json["tokenPattern"] = JSON(parseJSON: $0) }
    config.pathGenerator.map { json["pathGenerator"] = JSON(parseJSON: $0) }
    DocsUrlUtil.updateConfig(json)
}

///测试不同的后台domain 配置，是否都符合预期
class DomainConfigSpec: QuickSpec {
    func testNewBaseUrl() {
        var urlStr = OpenAPI.docs.baseUrl
        expect(urlStr).to(equal("https://internal-api.feishu.cn/space"))
        urlStr = OpenAPI.docs.baseUrlForDocs
        expect(urlStr).to(equal("https://a.feishu.cn"))
        urlStr = OpenAPI.docs.baseUrlForBDDocs
        expect(urlStr).to(equal("https://bytedance.feishu.cn"))
    }

    func testOldBaseUrl() {
        var urlStr = OpenAPI.docs.baseUrl
        expect(urlStr).to(equal("https://docs.bytedance.net"))
        urlStr = OpenAPI.docs.baseUrlForDocs
        expect(urlStr).to(equal("https://docs.bytedance.net"))
        urlStr = OpenAPI.docs.baseUrlForBDDocs
        expect(urlStr).to(equal("https://docs.bytedance.net"))
    }

    func testOldDocUrlGen() {
        let url = DocsUrlUtil.url(type: .doc, token: "token")
        expect(url.absoluteString).to(equal("https://docs.bytedance.net/doc/token"))
    }

    func testNewDocUrlGen() {
        let url = DocsUrlUtil.url(type: .doc, token: "token")
        expect(url.absoluteString).to(equal("https://a.feishu.cn/space/doc/token"))
    }

    func testNewDocUrlGenNoSpace() {
        let url = DocsUrlUtil.url(type: .doc, token: "token")
        expect(url.absoluteString).to(equal("https://a.feishu.cn/doc/token"))
    }

    func testParseOldDoc() {
        var url = URL(string: "https://docs.bytedance.net/doc/xxx")!
        expect(DocsUrlUtil.getFileType(from: url)).to(equal(.doc))
        url = URL(string: "https://docs.bytedance.net/bitable/xxx")!
        expect(DocsUrlUtil.getFileType(from: url)).to(equal(.bitable))
        url = URL(string: "https://docs.bytedance.net/folder/xxx")!
        expect(DocsUrlUtil.getFileType(from: url)).to(equal(.folder))
    }

    func testParseNewDoc() {
        it("old test") {
            var url = URL(string: "https://a.feishu.cn/space/doc/xxx")!
            expect(DocsUrlUtil.getFileType(from: url)).to(equal(.doc))
            url = URL(string: "https://a.feishu.cn/api/v2/sheet/sub_block?token=9bHtyuPZbcQAMk3rGcD7Fh&block_token=block_6649518948989534734_3263527808_3")!
            expect(DocsUrlUtil.getFileType(from: url)).to(beNil())
        }
        it("识别模板", closure: {
            let url = URL(string: "https://bytedance.feishu.cn/space/blank/")!
            expect(DocsUrlUtil.getFileType(from: url)).to(beNil())
        })
        it("识别doc", closure: {
            let url = URL(string: "https://bytedance.feishu.cn/space/doc/AHIfC4uV0q95atVGC3zBVh")!
            expect(DocsUrlUtil.getFileType(from: url)).to(equal(.doc))
        })
        it("识别sheet", closure: {
            let url = URL(string: "https://bytedance.feishu.cn/space/sheet/shtcnVYCBeYWNam9sQZaNO#295957")!
            expect(DocsUrlUtil.getFileType(from: url)).to(equal(.sheet))
        })
        it("识别mindnote", closure: {
            let url = URL(string: "https://bytedance.feishu.cn/space/mindnote/bmncn6bxJvFV3VWGtshg2B")!
            expect(DocsUrlUtil.getFileType(from: url)).to(equal(.mindnote))
        })
    }

    func testOldGetFileToken() {
        let token = "ee2jJ6bT22wLOWsYDeRDoh"

        // 原始+有片段+有参数
        var url = URL(string: "https://docs.bytedance.net/doc/" + token)!
        var resultToken = DocsUrlUtil.getFileToken(from: url)
        expect(resultToken).to(equal(token))
        url = URL(string: "https://docs.bytedance.net/doc/" + token + "#history")!
        resultToken = DocsUrlUtil.getFileToken(from: url)
        expect(resultToken).to(equal(token))
        url = URL(string: "https://docs.bytedance.net/doc/" + token + "?doc=df" + "#history")!
        resultToken = DocsUrlUtil.getFileToken(from: url)
        expect(resultToken).to(equal(token))

        url = URL(string: "https://docs.bytedance.net/doc/" + token + "?doc=df&dfd=wer" + "#history")!
        resultToken = DocsUrlUtil.getFileToken(from: url)
        expect(resultToken).to(equal(token))
    }

    func testNewGetFileToken() {
        let token = "ee2jJ6bT22wLOWsYDeRDoh"
        let busness = "space"
        var url = URL(string: "https://feishu.cn/" + busness + "/doc/" + token)!
        var resultToken = DocsUrlUtil.getFileToken(from: url)
        expect(resultToken).to(equal(token))
        url = URL(string: "https://feishu.cn/" + busness + "/doc/" + token + "#history")!
        resultToken = DocsUrlUtil.getFileToken(from: url)
        expect(resultToken).to(equal(token))
        url = URL(string: "https://feishu.cn/" + busness + "/doc/" + token + "?doc=df" + "#history")!
        resultToken = DocsUrlUtil.getFileToken(from: url)
        expect(resultToken).to(equal(token))
        url = URL(string: "https://feishu.cn/" + busness + "/doc/" + token + "?doc=df&dfd=wer" + "#history")!
        resultToken = DocsUrlUtil.getFileToken(from: url)
        expect(resultToken).to(equal(token))
    }

    func testNewPathAfterURL() {
        var url = URL(string: "https://docs.bytedance.net/doc/token")!
        expect(URLValidator.pathAfterBaseUrl(url)).to(equal("/space/doc/token"))
        url = URL(string: "https://docs.bytedance.net/")!
        expect(URLValidator.pathAfterBaseUrl(url)).to(equal("/space/"))
        url = URL(string: "https://docs.bytedance.net")!
        expect(URLValidator.pathAfterBaseUrl(url)).to(equal("/space"))
        url = URL(string: "https://a.feishu.cn/space")!
        expect(URLValidator.pathAfterBaseUrl(url)).to(equal("/space"))
        url = URL(string: "https://a.feishu.cn/space/doc/sss")!
        expect(URLValidator.pathAfterBaseUrl(url)).to(equal("/space/doc/sss"))
        url = URL(string: "https://docs.bytedance.net/home/")!
        expect(URLValidator.pathAfterBaseUrl(url)).to(equal("/space/home"))
    }

    func testOldGetRenderPath() {
        var render =  "/doc/123afjdiko293"
        var url = URL(string: "https://docs.bytedance.net/doc/123afjdiko293")!
        var renderPath = DocsUrlUtil.getRenderPath(url)
        expect(renderPath).to(equal(render))

        render =  "/doc/123afjdiko293?df=q3e"
        url = URL(string: "https://docs.bytedance.net/doc/123afjdiko293?df=q3e")!
        renderPath = DocsUrlUtil.getRenderPath(url)
        expect(renderPath).to(equal(render))

        render =  "/doc/123afjdiko293?df=q3e&wer=2342"
        url = URL(string: "https://docs.bytedance.net/doc/123afjdiko293?df=q3e&wer=2342")!
        renderPath = DocsUrlUtil.getRenderPath(url)
        expect(renderPath).to(equal(render))

        render = "/doc/ee2jJ6bT22wLOWsYDeRDoh?dfd=2234&dfds=23423#history"
        url = URL(string: "https://docs.bytedance.net/doc/ee2jJ6bT22wLOWsYDeRDoh?dfd=2234&dfds=23423#history")!
        renderPath = DocsUrlUtil.getRenderPath(url)
        expect(renderPath).to(equal(render))
    }

    func testNewGetRenderPath() {
        var render = "/space/doc/123afjdiko293?df=q3e"
        var url = URL(string: "https://feishu.cn/space/doc/123afjdiko293?df=q3e")!
        var renderPath = DocsUrlUtil.getRenderPath(url)
        expect(renderPath).to(equal(render))

        render = "/space/doc/123afjdiko293?df=q3e"
        url = URL(string: "https://a.feishu.cn/space/doc/123afjdiko293?df=q3e")!
        renderPath = DocsUrlUtil.getRenderPath(url)
        expect(renderPath).to(equal(render))
    }

    func testOldIsSupportedUrl() {
        var url = URL(string: "https://docs.bytedance.net/doc/token")!
        var (isSupport, type, token) = URLValidator.isSupportURLType(url: url)
        expect(isSupport).to(beTrue())
        expect(type).to(equal("doc"))
        expect(token).to(equal("token"))

        url = URL(string: "https://docs.bytedance.net/folder/xxx")!
        (isSupport, type, token) = URLValidator.isSupportURLType(url: url)
        expect(isSupport).to(beTrue())
        expect(type).to(equal("folder"))
        expect(token).to(equal("xxx"))

        url = URL(string: "https://a.feishu.cn/api/v2/sheet/sub_block?token=9bHtyuPZbcQAMk3rGcD7Fh&block_token=block_6649518948989534734_3263527808_3")!
        (isSupport, type, token) = URLValidator.isSupportURLType(url: url)
        expect(isSupport).to(beFalse())
        expect(type).to(equal("other"))
        expect(token).to(equal(""))
    }

    func testNewStandardUrl() {
        let serverDomain = "a.feishu.cn"
        let sufix = "feishu.cn"
        var url = URL(string: "https://" + sufix + "/space/dd")!
        var standardUrl = URLValidator.standardizeDocURL(url)
        expect(standardUrl).to(equal(URL(string: "https://" + serverDomain + "/space/dd")))

        url = URL(string: "https://a." + sufix + "/space/dd")!
        standardUrl = URLValidator.standardizeDocURL(url)
        expect(standardUrl).to(equal(URL(string: "https://" + serverDomain + "/space/dd")))
        url = URL(string: "https://" + "docs.bytedance.net" + "/doc/dd")!
        standardUrl = URLValidator.standardizeDocURL(url)
        expect(standardUrl).to(equal(URL(string: "https://" + serverDomain + "/space/doc/dd")))
        url = URL(string: "https://" + serverDomain + "/space/dd")!
        standardUrl = URLValidator.standardizeDocURL(url)
        expect(url).to(equal(standardUrl))
    }

    func testOldStandardUrl() {
        let host = "docs.bytedance.net"
        let url = URL(string: "https://" + host + "/space/dd")!
        let standardUrl = URLValidator.standardizeDocURL(url)
        expect(standardUrl.absoluteString).to(equal("https://docs.bytedance.net/space/dd"))
    }

    func testNewIsSupportedUrl() {
        let url = URL(string: "https://a.feishu.cn/space/doc/token")!
        let (isSupport, type, token) = URLValidator.isSupportURLType(url: url)
        expect(isSupport).to(beTrue())
        expect(type).to(equal("doc"))
        expect(token).to(equal("token"))
    }

    func testOldIsDocsURL() {
        var url = DocsUrlUtil.mainFrameTemplateURL()
//        expect(URLValidator.isDocsURL(url)).to(beTrue())

        let releastHost = "docs.bytedance.net"
        url = URL(string: "https://\(releastHost)/doc/12342adsfj")!
        expect(URLValidator.isDocsURL(url)).to(beTrue())
        url = URL(string: "https://\(releastHost)/sheet/12342adsfj")!
        expect(URLValidator.isDocsURL(url)).to(beTrue())
        url = URL(string: "https://\(releastHost)/folder")!
        expect(URLValidator.isDocsURL(url)).to(beTrue())
        url = URL(string: "https://\(releastHost)/recent")!
        expect(URLValidator.isDocsURL(url)).to(beTrue())
        url = URL(string: "https://a.feishu.cn/space/doc/ssssdfsdfsdfsdfsdfsdfsdf")!
        expect(URLValidator.isDocsURL(url)).to(beTrue())
    }

    func testNewIsDocsURL() {
        let sufix = "feishu.cn"
        //正确判断预加载模板
//        let url = DocsUrlUtil.mainFrameTemplateURL()
//        expect(URLValidator.isDocsURL(url)).to(beTrue())
        let busness = NetConfig.shared.busness
        // 能正确判断后台返回域名
        expect(URLValidator.isDocsURL(URL(string: "http://\(sufix)/\(busness)")!)).to(beTrue())
        expect(URLValidator.isDocsURL(URL(string: "http://a.\(sufix)/\(busness)")!)).to(beTrue())
        expect(URLValidator.isDocsURL(URL(string: "http://11.\(sufix)/\(busness)")!)).to(beTrue())
        //        XCTAssertFalse(URLValidator.isDocsURL(URL(string: "http://.\(sufix)/\(busness)")!))
        expect(URLValidator.isDocsURL(URL(string: "http://..\(sufix)/\(busness)")!)).to(beFalse())
        expect(URLValidator.isDocsURL(URL(string: "http://..\(sufix)d/\(busness)")!)).to(beFalse())
        expect(URLValidator.isDocsURL(URL(string: "http://a..\(sufix)d/\(busness)")!)).to(beFalse())
        //        XCTAssertFalse(URLValidator.isDocsURL(URL(string: "http://a.#b.\(sufix)/\(busness)")!))

        expect(URLValidator.isDocsURL(URL(string: "http://a.b.\(sufix)d/\(busness)")!)).to(beFalse())
        expect(URLValidator.isDocsURL(URL(string: "http://a.b.\(sufix)/\(busness)")!)).to(beTrue())
        //        XCTAssertFalse(URLValidator.isDocsURL(URL(string: "https://.\(sufix)/\(busness)d")!))
        expect(URLValidator.isDocsURL(URL(string: "https://.\(sufix)/dfd/doc/df")!)).to(beFalse())
    }

    func testJumpDestination() {
        it("正确识别主页", closure: {
            func checkHomeDirectory(_ str: String) {
                let url = URL(string: str)!
                let pathAfterUrl = URLValidator.pathAfterBaseUrl(url)!
                expect(DocsUrlUtil.jumpDirectionfor(pathAfterUrl)).to(equal(DocsSDK.DocsJumpDestination.recents))
            }
            checkHomeDirectory("https://docs.bytedance.net/home/")
            checkHomeDirectory("https://docs.bytedance.net/")
            checkHomeDirectory("https://docs.bytedance.net")
            checkHomeDirectory("https://docs.bytedance.net/home")
            checkHomeDirectory("https://docs.bytedance.net/HOME")
            checkHomeDirectory("https://a.feishu.cn/space")
            checkHomeDirectory("https://a.feishu.cn/space/")
            checkHomeDirectory("https://a.feishu.cn/space/home")
            checkHomeDirectory("https://a.feishu.cn/space/home/")
            checkHomeDirectory("https://a.feishu.cn/space/hoMe")
        })
        it("正确识别最近浏览", closure: {
            func checkDirectory(_ str: String) {
                let url = URL(string: str)!
                let pathAfterUrl = URLValidator.pathAfterBaseUrl(url)!
                expect(DocsUrlUtil.jumpDirectionfor(pathAfterUrl)).to(equal(DocsSDK.DocsJumpDestination.recents))
            }
            checkDirectory("https://docs.bytedance.net/home/recents")
            checkDirectory("https://docs.bytedance.net/home/recents/")
            checkDirectory("https://docs.bytedance.net/home/receNts")
            checkDirectory("https://a.feishu.cn/space/home/recents")
            checkDirectory("https://a.feishu.cn/space/home/recents/")
            checkDirectory("https://a.feishu.cn/space/home/recentS")
            checkDirectory("https://a.feishu.cn/space/home/recenTS")
        })
        it("正确识别共享列表", closure: {
            func checkDirectory(_ str: String) {
                let url = URL(string: str)!
                let pathAfterUrl = URLValidator.pathAfterBaseUrl(url)!
                expect(DocsUrlUtil.jumpDirectionfor(pathAfterUrl)).to(equal(DocsSDK.DocsJumpDestination.shareFiles))
            }
            checkDirectory("https://docs.bytedance.net/home/share/files")
            checkDirectory("https://docs.bytedance.net/home/share/files/")
            checkDirectory("https://docs.bytedance.net/home/share/filEs/")
            checkDirectory("https://a.feishu.cn/space/home/share/files")
            checkDirectory("https://a.feishu.cn/space/home/share/files/")
            checkDirectory("https://a.feishu.cn/space/home/share/files")
        })
        it("正确识别收藏列表", closure: {
            func checkDirectory(_ str: String) {
                let url = URL(string: str)!
                let pathAfterUrl = URLValidator.pathAfterBaseUrl(url)!
                expect(DocsUrlUtil.jumpDirectionfor(pathAfterUrl)).to(equal(DocsSDK.DocsJumpDestination.star))
            }
            checkDirectory("https://docs.bytedance.net/home/star")
            checkDirectory("https://docs.bytedance.net/home/star/")
            checkDirectory("https://a.feishu.cn/space/home/star")
            checkDirectory("https://a.feishu.cn/space/home/star/")
        })
        it("正确识别收藏folder列表", closure: {
            func checkDirectory(_ str: String) {
                let url = URL(string: str)!
                let pathAfterUrl = URLValidator.pathAfterBaseUrl(url)!
                expect(DocsUrlUtil.jumpDirectionfor(pathAfterUrl)).to(equal(DocsSDK.DocsJumpDestination.folder))
            }
            checkDirectory("https://docs.bytedance.net/folder")
            checkDirectory("https://docs.bytedance.net/folder/")
            checkDirectory("https://a.feishu.cn/space/folder/")
            checkDirectory("https://a.feishu.cn/space/folder")
        })
        it("正确识别收藏share folder", closure: {
            func checkDirectory(_ str: String) {
                let url = URL(string: str)!
                let pathAfterUrl = URLValidator.pathAfterBaseUrl(url)!
                expect(DocsUrlUtil.jumpDirectionfor(pathAfterUrl)).to(equal(DocsSDK.DocsJumpDestination.shareFolders))
            }
            checkDirectory("https://docs.bytedance.net/share/folders")
            checkDirectory("https://docs.bytedance.net/share/folders/")
            checkDirectory("https://a.feishu.cn/space/share/folders/")
            checkDirectory("https://a.feishu.cn/space/share/folders")
        })
        it("正确识别收藏新年调查", closure: {
            func checkDirectory(_ str: String) {
                let url = URL(string: str)!
                let pathAfterUrl = URLValidator.pathAfterBaseUrl(url)!
                expect(DocsUrlUtil.jumpDirectionfor(pathAfterUrl)).to(equal(DocsSDK.DocsJumpDestination.newYearSurvey))
            }
            checkDirectory("https://docs.bytedance.net/native/newyearsurvey")
            checkDirectory("https://docs.bytedance.net/native/newyearsurvey/")
            checkDirectory("https://a.feishu.cn/space/native/newyearsurvey/")
            checkDirectory("https://a.feishu.cn/space/native/newyearsurvey")
        })
    }

    func testDomainChange() {
        let webviewUrl = URL(string: "https://a.feishu.cn/space/doc/xxxx")!
        it("正确替换图片域名", closure: {
            let url = URL(string: "https://docs.bytedance.net/file/f/fs2")!
            let changeUrl = DocsUrlUtil.changeUrlForNewDomain(url, webviewUrl: webviewUrl)
            expect(changeUrl.absoluteString).to(equal("https://internal-api.feishu.cn/space/api/file/f/fs2"))
        })
        it("正确替换当前域名host的普通请求", closure: {
            let url = URL(string: "https://a.feishu.cn/api/rr")!
            let changeUrl = DocsUrlUtil.changeUrlForNewDomain(url, webviewUrl: webviewUrl)
            expect(changeUrl.absoluteString).to(equal("https://internal-api.feishu.cn/space/api/rr"))
        })
        it("不替换普通请求", closure: {
            let url = URL(string: "docsource://s3.pstatp.com/eesz/resource/bear/js/manifest.e6ff9ef98f2f951e5b14.js")!
            let changeUrl = DocsUrlUtil.changeUrlForNewDomain(url, webviewUrl: webviewUrl)
            expect(changeUrl.absoluteString).to(equal(url.absoluteString))
        })
    }

    func folderTest() {
        it("文件夹") {
            var url: URL? = URL(string: "https://bytedance.feishu.cn/space/folder/P2QvQfHG5amGhK49")
            expect(URLValidator.getFolderPath(url: url)).to(equal("P2QvQfHG5amGhK49"))
            url = URL(string: "https://docs.bytedance.net/folder/P2QvQfHG5amGhK49")
            expect(URLValidator.getFolderPath(url: url)).to(equal("P2QvQfHG5amGhK49"))
            url = URL(string: "https://docs.bytedance.net/folder/P2QvQfHG5amGhK49222")
            expect(URLValidator.getFolderPath(url: url)).to(equal("P2QvQfHG5amGhK49222"))
            url = URL(string: "https://bytedance.feishu.cn/space/doc/gbOJAzuvyo7zmN2DYdwidc")
            expect(URLValidator.getFolderPath(url: url)).to(beNil())
        }
    }

    func testToken(_ str: String) {
        let url = URL(string: str)!
        expect(DocsUrlUtil.getFileToken(from: url)).to(equal("testtesttesttesttest"))
    }

    func testNoToken(_ str: String) {
        let url = URL(string: str)!
        expect(DocsUrlUtil.getFileToken(from: url)).to(beNil())
    }

    override func spec() {
        let config = getcurrentConfig()
        afterSuite {
            setConfig(config)
        }
        context("老域名正确", closure: {
            setConfig(.noNewDomain)
            self.testOldBaseUrl()
            self.testOldDocUrlGen()
            self.testParseOldDoc()
            self.testOldGetFileToken()
            self.testOldIsSupportedUrl()
            self.testOldGetRenderPath()
            self.testOldStandardUrl()
            self.testOldIsDocsURL()
        })
        context("新域名") {
            setConfig(.newDomainAfeishu)
            it("", closure: {
                setConfig(.newDomainAfeishu)
                self.testNewBaseUrl()
                self.testNewDocUrlGen()
                self.testParseOldDoc()
                self.testOldGetFileToken()
                self.testNewGetFileToken()
                self.testNewPathAfterURL()
                self.testOldIsSupportedUrl()
                self.testNewIsSupportedUrl()
                self.testNewGetRenderPath()
                self.testNewStandardUrl()
                self.testOldIsDocsURL()
                self.testNewIsDocsURL()
                expect(DocsUrlUtil.mainFrameTemplateURL()).to(equal(URL(string: "https://a.feishu.cn/space/blank/")))
                expect(DocsUrlUtil.upgradePath).to(equal("/space/app/upgrade"))
            })
            self.testJumpDestination()
            self.testDomainChange()
            self.folderTest()
            self.testParseNewDoc()
            it("合法的token", closure: {
                self.testToken("https://a.feishu.cn/doc/testtesttesttesttest")
                self.testToken("https://a.feishu.cn/space/doc/testtesttesttesttest")
                self.testToken("https://a.feishu.cn/space/folder/testtesttesttesttest")
                self.testToken("https://a.feishu.cn/space/slide/testtesttesttesttest")
                self.testToken("https://a.feishu.cn/space/doc/testtesttesttesttest#43")
                self.testToken("https://a.feishu.cn/space/doc/testtesttesttesttest#")
                self.testToken("https://a.feishu.cn/space/doc/testtesttesttesttest?aa=bb")
            })
            it("不合法的token", closure: {
                self.testNoToken("https://a.feishu.cn/space/dOc/testtesttesttesttest")
                self.testNoToken("https://a.feishu.cn/space/space/dOc/testtesttesttesttest")
                self.testNoToken("https://a.feishu.cn/dOc/testtesttesttesttest")
                self.testNoToken("https://a.feishu.cn/space/ioy/testtesttesttesttest?aa=bb")
            })
            it("特殊域名测试", closure: {
                expect(DocsUrlUtil.mainFrameTemplateURL()).to(equal(URL(string: "https://a.feishu.cn/space/blank/")))
                expect(DocsUrlUtil.upgradePath).to(equal("/space/app/upgrade"))
            })

        }
        context("新域名没有space") {
            setConfig(.newDomainNoSpace)
            it("", closure: {
                setConfig(.newDomainNoSpace)
                self.testNewBaseUrl()
                self.testNewDocUrlGenNoSpace()
                self.testParseOldDoc()
                self.testOldGetFileToken()
                self.testNewGetFileToken()
                self.testNewPathAfterURL()
                self.testOldIsSupportedUrl()
                self.testNewIsSupportedUrl()
//                self.testNewGetRenderPath()
//                self.testNewStandardUrl()
                self.testOldIsDocsURL()
                self.testNewIsDocsURL()
            })
            self.testJumpDestination()
            self.testDomainChange()
            self.folderTest()
            self.testParseNewDoc()
            it("合法的token", closure: {
                self.testToken("https://a.feishu.cn/doc/testtesttesttesttest")
                self.testToken("https://a.feishu.cn/space/doc/testtesttesttesttest")
                self.testToken("https://a.feishu.cn/space/folder/testtesttesttesttest")
                self.testToken("https://a.feishu.cn/space/slide/testtesttesttesttest")
                self.testToken("https://a.feishu.cn/space/doc/testtesttesttesttest#43")
                self.testToken("https://a.feishu.cn/space/doc/testtesttesttesttest#")
                self.testToken("https://a.feishu.cn/space/doc/testtesttesttesttest?aa=bb")
                self.testToken("https://bytedance.feishu.cn/doc/testtesttesttesttest?from=tab_recent")
            })
            it("不合法的token", closure: {
                self.testNoToken("https://a.feishu.cn/dOc/testtesttesttesttest")
                self.testNoToken("https://a.feishu.cn/space/dOc/testtesttesttesttest")
                self.testNoToken("https://a.feishu.cn/space/space/dOc/testtesttesttesttest")
                self.testNoToken("https://a.feishu.cn/dOc/testtesttesttesttest")
                self.testNoToken("https://a.feishu.cn/space/ioy/testtesttesttesttest?aa=bb")
            })
            it("特殊域名测试", closure: {
                expect(DocsUrlUtil.mainFrameTemplateURL()).to(equal(URL(string: "https://a.feishu.cn/blank/")))
                expect(DocsUrlUtil.upgradePath).to(equal("/space/app/upgrade"))
            })
        }

    }
}

class UrlExtSpec: QuickSpec {
    override func spec() {
        describe("添加/覆盖parames") {
            let rawUrl = URL(string: "https://docs.bytedance.net/doc/nbsWkiQfYrjWFvaP3Gc9Qf?from=tab_recent&doc_rn_enabled=true#history")!
            it("已有的参数要处理", closure: {
                let addedURL = rawUrl.docs.addOrChangeQuery(parameters: ["from": "tab_other"])
                expect(addedURL.absoluteString).to(equal("https://docs.bytedance.net/doc/nbsWkiQfYrjWFvaP3Gc9Qf?doc_rn_enabled=true&from=tab_other#history"))
            })
            it("添加新的参数", closure: {
                let addedURL = rawUrl.docs.addOrChangeQuery(parameters: ["from1": "tab_other"])
                expect(addedURL.absoluteString).to(equal("https://docs.bytedance.net/doc/nbsWkiQfYrjWFvaP3Gc9Qf?from=tab_recent&doc_rn_enabled=true&from1=tab_other#history"))
            })
        }

        describe("添加parames") {
            let rawUrl = URL(string: "https://docs.bytedance.net/doc/nbsWkiQfYrjWFvaP3Gc9Qf?from=tab_recent&doc_rn_enabled=true#history")!
            it("已有的参数不处理", closure: {
                let addedURL = rawUrl.docs.addQuery(parameters: ["from": "tab_other"])
                expect(addedURL.absoluteString).to(equal("https://docs.bytedance.net/doc/nbsWkiQfYrjWFvaP3Gc9Qf?from=tab_recent&doc_rn_enabled=true#history"))
            })
            it("添加新的参数", closure: {
                let addedURL = rawUrl.docs.addQuery(parameters: ["from1": "tab_other"])
                expect(addedURL.absoluteString).to(equal("https://docs.bytedance.net/doc/nbsWkiQfYrjWFvaP3Gc9Qf?from=tab_recent&doc_rn_enabled=true&from1=tab_other#history"))
            })
        }
        describe("移除私有协议") {
            var url: URL?
            expect(WebViewSchemeManager.disableDocsSourceSchemeIfNeed(for: url)).to(beNil())
            url = URL(string: "docsource://docs.bytedance.net")
            expect(WebViewSchemeManager.disableDocsSourceSchemeIfNeed(for: url)?.absoluteString).to(equal("https://docs.bytedance.net"))
        }
    }
}

class RegexSpec: QuickSpec {
    override func spec() {
        describe("正则表达式识别") {
            context("url -> token", closure: {
                func getMatchedTokenAndTypeFrom(_ url: URL) -> [String: String] {
                    let path = url.path
                    let pattern = ##"^(/space)?/(?<type>(doc|sheet|mindnote|slide))/(?<token>[^\/]+)"##
                    var regex: NSRegularExpression!
                    do {
                        regex = try NSRegularExpression(pattern: pattern, options: [])
                    } catch {
                        XCTFail("regex fail")
                    }
                    var matched: [String: String] = [:]
                    let nsrange = NSRange(path.startIndex..<path.endIndex, in: path)
                    if let match = regex.firstMatch(in: path,
                                                    options: [],
                                                    range: nsrange) {
                        for component in ["type", "token"] {
                            let nsrange = match.range(withName: component)
                            if nsrange.location != NSNotFound,
                                let range = Range(nsrange, in: path) {
                                let str = path[range]
                                matched[component] = String(str)
                            }
                        }
                    }
                    return matched
                }

                var url = URL(string: "https://a.feishu.cn/space/doc/doccnQIlkhqGX08tW4wcMJ")!
                var matched = getMatchedTokenAndTypeFrom(url)
                it("正常解析", closure: {
                    url = URL(string: "https://a.feishu.cn/space/doc/doccnQIlkhqGX08tW4wcMJ")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(2))
                    expect(matched["type"]).to(equal("doc"))
                    expect(matched["token"]).to(equal("doccnQIlkhqGX08tW4wcMJ"))
                })

                it("支持url里有fragment", closure: {
                    url = URL(string: "https://a.feishu.cn/space/doc/doccnQIlkhqGX08tW4wcMJ#dfdf")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(2))
                    expect(matched["type"]).to(equal("doc"))
                    expect(matched["token"]).to(equal("doccnQIlkhqGX08tW4wcMJ"))
                })

                it("支持url里有fragment,但是没写对", closure: {
                    url = URL(string: "https://a.feishu.cn/space/doc/doccnQIlkhqGX08tW4wcMJ#")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(2))
                    expect(matched["type"]).to(equal("doc"))
                    expect(matched["token"]).to(equal("doccnQIlkhqGX08tW4wcMJ"))
                })

                it("支持url里有param", closure: {
                    url = URL(string: "https://a.feishu.cn/space/doc/doccnQIlkhqGX08tW4wcMJ?t=9")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(2))
                    expect(matched["type"]).to(equal("doc"))
                    expect(matched["token"]).to(equal("doccnQIlkhqGX08tW4wcMJ"))
                })

                it("大小写敏感", closure: {
                    url = URL(string: "https://a.feishu.cn/space/dOc/doccnQIlkhqGX08tW4wcMJ")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(0))
                })

                it("sheet 也正常", closure: {
                    url = URL(string: "https://a.feishu.cn/space/sheet/doccnQIlkhqGX08tW4wcMJ")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(2))
                    expect(matched["type"]).to(equal("sheet"))
                    expect(matched["token"]).to(equal("doccnQIlkhqGX08tW4wcMJ"))
                })

                it("不支持类型不支持", closure: {
                    url = URL(string: "https://a.feishu.cn/space/sheet1/fdfdfd")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(0))
                })

                it("测试有没有space的情况", closure: {
                    url = URL(string: "https://a.feishu.cn/sheet/doccnQIlkhqGX08tW4wcMJ")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(2))
                    expect(matched["type"]).to(equal("sheet"))
                    expect(matched["token"]).to(equal("doccnQIlkhqGX08tW4wcMJ"))
                })

                it("测试space过多失败", closure: {
                    url = URL(string: "https://a.feishu.cn/space/space/sheet/doccnQIlkhqGX08tW4wcMJ")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(0))
                })

                it("测试不是space开头失败", closure: {
                    url = URL(string: "https://a.feishu.cn/io/space/sheet/doccnQIlkhqGX08tW4wcMJ")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(0))
                })

                it("测试前缀不对", closure: {
                    url = URL(string: "https://a.feishu.cn/space1/sheet/doccnQIlkhqGX08tW4wcMJ")!
                    matched = getMatchedTokenAndTypeFrom(url)
                    expect(matched.count).to(equal(0))
                })
            })
        }
    }
}
