//
//  URLExtensionTests.swift
//  SpaceDemoTests
//
//  Created by Weston Wu on 2022/2/22.
//  Copyright © 2022 Bytedance. All rights reserved.
//

import XCTest
@testable import SKCommon
import SKFoundation

// URL+Ext.swift
class URLExtensionTests: XCTestCase {

    // Xcode 15 上这个也是非法 URL 了
//    static let validURLButInvalidURLComponentString = "a://@@"

    func testChangeScheme() {
        // Xcode 15 统一了 URL 和 URLComponent 的非法判断逻辑，以下 URL 现在是 nil
//        let invalidURLComponentURL = URL(string: Self.validURLButInvalidURLComponentString)!
//        var result = invalidURLComponentURL.docs.changeSchemeTo("http")
//        var expect = invalidURLComponentURL
//        XCTAssertEqual(result, expect)

        let applinkURL = URL(string: "//path/to/ccm")!
        var result = applinkURL.docs.changeSchemeTo("lark")
        var expect = URL(string: "lark://path/to/ccm")!
        XCTAssertEqual(result, expect)

        let normalURL = URL(string: "http://www.feishu.cn/test?a=b#fragment")!
        result = normalURL.docs.changeSchemeTo("https")
        expect = URL(string: "https://www.feishu.cn/test?a=b#fragment")!
        XCTAssertEqual(result, expect)
        result = normalURL.docs.changeSchemeTo("rust")
        expect = URL(string: "rust://www.feishu.cn/test?a=b#fragment")!
        XCTAssertEqual(result, expect)
        result = normalURL.docs.changeSchemeTo("feishu")
        expect = URL(string: "feishu://www.feishu.cn/test?a=b#fragment")!
        XCTAssertEqual(result, expect)
        result = normalURL.docs.changeSchemeTo("lark")
        expect = URL(string: "lark://www.feishu.cn/test?a=b#fragment")!
        XCTAssertEqual(result, expect)
    }

    func testIsDocHistoryURL() {
        let simple = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXXXX#history")!
        XCTAssertTrue(simple.docs.isDocHistoryUrl)
        let complex = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#history")!
        XCTAssertTrue(complex.docs.isDocHistoryUrl)
    }

    func testNotDocHistoryURL() {
        let noFragment = URL(string: "www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d")!
        XCTAssertFalse(noFragment.docs.isDocHistoryUrl)
        let wrongFragment = URL(string: "www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#appeal")!
        XCTAssertFalse(wrongFragment.docs.isDocHistoryUrl)
    }

    func testIsAppealURL() {
        let simple = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXXXX#appeal")!
        XCTAssertTrue(simple.docs.isAppealUrl)
        let complex = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#appeal")!
        XCTAssertTrue(complex.docs.isAppealUrl)
    }

    func testNotAppealURL() {
        let noFragment = URL(string: "www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d")!
        XCTAssertFalse(noFragment.docs.isAppealUrl)
        let wrongFragment = URL(string: "www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#history")!
        XCTAssertFalse(wrongFragment.docs.isAppealUrl)
    }

    func testAvoidNoDefaultScheme_withScheme() {
        let https = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#appeal")!
        XCTAssertEqual(https, https.docs.avoidNoDefaultScheme)

        let rust = URL(string: "rust://www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#appeal")!
        XCTAssertEqual(rust, rust.docs.avoidNoDefaultScheme)

        let http = URL(string: "http://www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#appeal")!
        XCTAssertEqual(http, http.docs.avoidNoDefaultScheme)
    }

    func testAvoidNoDefaultScheme_withoutScheme() {
        let url = URL(string: "www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#appeal")!
        let expect = URL(string: "http://www.feishu.cn/doc/doccnXXXXXXXXX?a=b&c=d#appeal")!
        let new = url.docs.avoidNoDefaultScheme
        XCTAssertEqual(expect, new)
    }

    func testIsGroupTabURL() {
        let trueURL = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXX?from=\(FromSource.groupTab.rawValue)")!
        var result = trueURL.docs.isGroupTabUrl
        XCTAssertTrue(result)

        var falseURL = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXX?from=\(FromSource.notice.rawValue)")!
        result = falseURL.docs.isGroupTabUrl
        XCTAssertFalse(result)

        falseURL = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXX?from=")!
        result = falseURL.docs.isGroupTabUrl
        XCTAssertFalse(result)

        falseURL = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXX?foo=bar")!
        result = falseURL.docs.isGroupTabUrl
        XCTAssertFalse(result)

        falseURL = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXX?")!
        result = falseURL.docs.isGroupTabUrl
        XCTAssertFalse(result)

        falseURL = URL(string: "https://www.feishu.cn/doc/doccnXXXXXXX")!
        result = falseURL.docs.isGroupTabUrl
        XCTAssertFalse(result)
    }

    func testIsWikiDocURL() {
        var inputURL = URL(string: "https://www.feishu.cn/wiki/wikcnTlRNZnJhesGFz6WI06dXgg")!
        var result = inputURL.docs.isWikiDocURL
        XCTAssertTrue(result)

        inputURL = URL(string: "https://www.feishu.cn/wiki/doxcnt92ugs8rwbo6WZyVLAZcgd")!
        result = inputURL.docs.isWikiDocURL
        XCTAssertTrue(result)

        inputURL = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb")!
        result = inputURL.docs.isWikiDocURL
        XCTAssertFalse(result)

        // TODO: wuwenjian 
//        inputURL = URL(string: "https://www.feishu.cn/wiki/xxxxxxx")!
//        result = inputURL.docs.isWikiDocURL
//        XCTAssertFalse(result)

        inputURL = URL(string: "https://www.feishu.cn/space/home")!
        result = inputURL.docs.isWikiDocURL
        XCTAssertFalse(result)

        inputURL = URL(string: "https://www.feishu.cn")!
        result = inputURL.docs.isWikiDocURL
        XCTAssertFalse(result)

        inputURL = URL(string: "https://www.feishu.cn/docx/wikcnezSBjXLyY3m97gT85dQhXb")!
        result = inputURL.docs.isWikiDocURL
        XCTAssertFalse(result)
    }

    func testQueryParams() {
        var input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?from=a&foo=bar")!
        var result = input.docs.queryParams
        var expect: [String: String]? = [
            "from": "a",
            "foo": "bar"
        ]
        XCTAssertEqual(result, expect)

        input = URL(string: "https://www.feishu.cn/docx/docxXXXXXXXX?test=%E6%B5%8B%E8%AF%95&foo=bar&a=b")!
        result = input.docs.queryParams
        expect = [
            "test": "测试",
            "foo": "bar",
            "a": "b"
        ]
        XCTAssertEqual(result, expect)

        input = URL(string: "https://www.feishu.cn/docx/docxXXXXXXXX?test=%25E6%25B5%258B%25E8%25AF%2595&foo=%E6%B5%8B%E8%AF%95")!
        result = input.docs.queryParams
        expect = [
            "test": "%E6%B5%8B%E8%AF%95",
            "foo": "测试"
        ]
        XCTAssertEqual(result, expect)
    }

    func testAddQuery() {
        // 拼接普通参数
        var input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb")!
        var result = input.docs.addQuery(parameters: ["foo": "bar"])
        var expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?foo=bar")!
        XCTAssertEqual(result, expect)

        // 拼接需要 encode 的参数
        result = input.docs.addQuery(parameters: ["test": "测试"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95")!
        XCTAssertEqual(result, expect)

        // 拼接已经 encode 的参数
        result = input.docs.addQuery(parameters: ["test": "%E6%B5%8B%E8%AF%95"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%25E6%25B5%258B%25E8%25AF%2595")! // 会被再 encode 1次
        XCTAssertEqual(result, expect)

        // 拼接已有参数，实际不会生效，不确定是否符合预期，但是现在是这么实现的
        input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95")!
        result = input.docs.addQuery(parameters: ["test": "test"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95")!
        XCTAssertEqual(result, expect)

        // 拼接多个参数, 顺序可能会被打乱
        result = input.docs.addQuery(parameters: ["foo": "bar", "test": "测试"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95&foo=bar")!
        var resultQuery = result.docs.queryParams!
        var expectQuery = expect.docs.queryParams!
        // 参数顺序不保证一致，因此不再比较 URL
        XCTAssertEqual(resultQuery, expectQuery)

        // 已有参数时，拼接多个参数，新增参数的顺序可能会被打乱
        input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95")!
        result = input.docs.addQuery(parameters: ["a": "b", "c": "d", "e": "测试"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95&e=%E6%B5%8B%E8%AF%95&c=d&a=b")!
        resultQuery = result.docs.queryParams!
        expectQuery = expect.docs.queryParams!
        XCTAssertEqual(resultQuery, expectQuery)

        // 如果url有已编码的+号 %2B，处理完保持不变
        //如果url有已编码的+号 %2B，处理完保持不变，后续要把这个方法去掉，改成测试addQuery
        input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?change=WJBhDf47%2BVBg%3D%3D")!
        result = input.docs.addEncodeQuery(parameters: ["test": "测试"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?change=WJBhDf47%2BVBg%3D%3D&test=%E6%B5%8B%E8%AF%95")!
        XCTAssertEqual(result, expect)
        
    }

    func testAddOrChangeQuery() {
        // 拼接普通参数
        var input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb")!
        var result = input.docs.addOrChangeQuery(parameters: ["foo": "bar"])
        var expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?foo=bar")!
        XCTAssertEqual(result, expect)

        // 拼接需要 encode 的参数
        result = input.docs.addOrChangeQuery(parameters: ["test": "测试"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95")!
        XCTAssertEqual(result, expect)

        // 拼接已经 encode 的参数
        result = input.docs.addOrChangeQuery(parameters: ["test": "%E6%B5%8B%E8%AF%95"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%25E6%25B5%258B%25E8%25AF%2595")! // 会被再 encode 1次
        XCTAssertEqual(result, expect)

        // 拼接已有参数，会覆盖旧参数
        input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95")!
        result = input.docs.addOrChangeQuery(parameters: ["test": "test"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=test")!
        XCTAssertEqual(result, expect)

        // 拼接多个参数, 顺序可能会被打乱
        result = input.docs.addOrChangeQuery(parameters: ["foo": "bar", "test": "测试"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95&foo=bar")!
        var resultQuery = result.docs.queryParams!
        var expectQuery = expect.docs.queryParams!
        // 参数顺序不保证一致，因此不再比较 URL
        XCTAssertEqual(resultQuery, expectQuery)

        // 已有参数时，拼接多个参数，新增参数的顺序可能会被打乱
        input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95")!
        result = input.docs.addOrChangeQuery(parameters: ["a": "b", "c": "d", "e": "测试"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95&e=%E6%B5%8B%E8%AF%95&c=d&a=b")!
        resultQuery = result.docs.queryParams!
        expectQuery = expect.docs.queryParams!
        XCTAssertEqual(resultQuery, expectQuery)

        // 覆盖已有参数并拼接多个参数，新增参数的顺序可能会被打乱
        input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=%E6%B5%8B%E8%AF%95")!
        result = input.docs.addOrChangeQuery(parameters: ["a": "b", "c": "d", "e": "测试", "test": "test"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?test=test&e=%E6%B5%8B%E8%AF%95&c=d&a=b")!
        resultQuery = result.docs.queryParams!
        expectQuery = expect.docs.queryParams!
        XCTAssertEqual(resultQuery, expectQuery)
        
        //如果url有已编码的+号 %2B，处理完保持不变，后续要把这个方法去掉，只保留addOrChangeQuery
        input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?change=WJBhDf47%2BVBg%3D%3D")!
        result = input.docs.addOrChangeEncodeQuery(parameters: ["test": "测试"])
        expect = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?change=WJBhDf47%2BVBg%3D%3D&test=%E6%B5%8B%E8%AF%95")!
        XCTAssertEqual(result, expect)
    }

    func testFetchQuery() {
        var input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb?from=a&foo=bar")!
        var result = input.docs.fetchQuery()
        var expect: [String: String]? = [
            "from": "a",
            "foo": "bar"
        ]
        XCTAssertEqual(result, expect)

        input = URL(string: "https://www.feishu.cn/docx/docxXXXXXXXX?test=%E6%B5%8B%E8%AF%95&foo=bar&a=b")!
        result = input.docs.fetchQuery()
        expect = [
            "test": "测试",
            "foo": "bar",
            "a": "b"
        ]
        XCTAssertEqual(result, expect)

        input = URL(string: "https://www.feishu.cn/docx/docxXXXXXXXX?test=%25E6%25B5%258B%25E8%25AF%2595&foo=%E6%B5%8B%E8%AF%95")!
        result = input.docs.fetchQuery()
        expect = [
            "test": "%E6%B5%8B%E8%AF%95",
            "foo": "测试"
        ]
        XCTAssertEqual(result, expect)
    }
    
    func testEncodeQueryParameters() {
        var input = URL(string: "https://www.feishu.cn/docx/doxcnezSBjXLyY3m97gT85dQhXb")!
        
        var result = input.docs.encodeQueryParameters(parameters: [
            "from": "a",
            "foo": "bar"
        ])
        var expect: [String: String]? = [
            "from": "a",
            "foo": "bar"
        ]
        XCTAssertEqual(result, expect)
        
        result = input.docs.encodeQueryParameters(parameters: [
            "from": "测试",
            "foo": "bar"
        ])
        expect = [
            "from": "%E6%B5%8B%E8%AF%95",
            "foo": "bar"
        ]
        XCTAssertEqual(result, expect)
    }
    
    func testUrlByResolvingApplicationDirectoryWithSamePrefix() {
        let sut = URL(fileURLWithPath: "/base/dir/file.txt")
        let result = sut.docs.urlByResolvingApplicationDirectory(baseDir: "/base/")
        XCTAssertEqual(sut, result)
    }
    
    func testUrlByResolvingApplicationDirectoryBasePathHasMoreComponents() {
        let sut = URL(fileURLWithPath: "/base/dir/file.txt")
        let result = sut.docs.urlByResolvingApplicationDirectory(baseDir: "/base/dir/aaa/bbb")
        XCTAssertEqual(sut, result)
    }
    
    func testUrlByResolvingApplicationDirectoryReplaceWithNewBaseDir() {
        let sut = URL(fileURLWithPath: "/base/dir/file.txt")
        let result = sut.docs.urlByResolvingApplicationDirectory(baseDir: "/baseNew/dir")
        XCTAssertEqual(result.path, "/baseNew/dir/file.txt")
    }
    
    func testEmail() {
        let res = ["asan@163.com": true,
         "21412AFC2f@gmail.com": true,
         "www.feishu.cn": false,
         "https://www.feishu.cn": false,
         "21412AFC2f@feishu.com": true,
                   "21412AFC2f@feishu.com.cn": true]
        let urls = res.keys.compactMap { URL(string: $0) }
        XCTAssertFalse(urls.isEmpty)
        for url in urls {
            XCTAssertEqual(url.docs.isEmail, res[url.absoluteString] ?? false)
        }
    }
}
