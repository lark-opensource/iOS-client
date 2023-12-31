//
//  HelpCenterURLGeneratorTests.swift
//  SKCommon-Unit-Tests
//
//  Created by Weston Wu on 2023/3/16.
//

import Foundation
@testable import SKCommon
import XCTest

final class HelpCenterURLGeneratorTests: XCTestCase {
    typealias Config = HelpCenterURLGenerator.Config
    typealias ArticleID = HelpCenterURLGenerator.ArticleID
    func testGenerator() {
        var config = Config(domain: "mock.domain",
                            locale: "zh_cn",
                            isFeishu: true)
        let articleID = ArticleID(feishuID: "FEISHU_ID", larkID: "LARK_ID")
        do {
            var url = try HelpCenterURLGenerator.generateURL(article: articleID,
                                                             query: ["from": "test_from"],
                                                             config: config)
            XCTAssertEqual(url, URL(string: "https://mock.domain/hc/zh_cn/articles/FEISHU_ID?from=test_from"))
            config.locale = "en_us"
            config.isFeishu = false
            url = try HelpCenterURLGenerator.generateURL(article: articleID,
                                                         config: config)
            XCTAssertEqual(url, URL(string: "https://mock.domain/hc/en_us/articles/LARK_ID"))
        } catch {
            XCTFail("un-expected error found: \(error)")
        }

        do {
            config.domain = nil
            _ = try HelpCenterURLGenerator.generateURL(article: articleID, config: config)
            XCTFail("un-expected success found")
        } catch {
            XCTAssertEqual(error as? HelpCenterURLGenerator.HelpCenterError, .domainNotFound)
        }
    }
}
