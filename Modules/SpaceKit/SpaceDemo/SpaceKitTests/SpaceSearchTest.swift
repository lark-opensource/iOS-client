//
//  SpaceSearchTest.swift
//  DocsTests
//
//  Created by litao_dev on 2019/5/21.
//  Copyright © 2019 Bytedance. All rights reserved.

import Foundation
import XCTest
@testable import SpaceKit
@testable import Docs

class SpaceSearchTest: BDTestBase {
    // MARK: - test formate search result to htmlString
    func testGetKeyWordsMarkedByServer() {
        let keywords = SpaceSearch.getKeyWordsMarkedByServer(in: "<em>互联网</em>信息，边界<em>互联网</em>")
        XCTAssertTrue(keywords.count == 2, "parse <em>...</em> error")
    }
    func testReplaceMarkAndFormateContentToHtml() {
        let htmlContent = SpaceSearch.replaceMarkAndFormatContentToHtml(content: "<em>互联网</em>信息，边界",
                                                             fontSize: 14,
                                                             highlightColor: "#AEAEAE",
                                                             normalColor: "#000000")
        XCTAssertNotNil(htmlContent, "htmlContent can't be nil")
    }

    func testMarkKeyWordsToHighlight() {
        let attStr = SpaceSearch.markKeyWordsToHighlight(content: "<em>互联网</em>信息，边界", fontSize: 16, highlightColor: "#AEAEAE", normalColor: "#000000")
        XCTAssertNotNil(attStr, "attStr can't not be nil in func 'testMarkKeyWordsToHighlight'")
    }
    // MARK: - title formate
    /// test formate everything to htmlString for search result title
    func testGetAttributeStr() {
        checkGetAttStr(keyword: "", content: nil)
        checkGetAttStr(keyword: "E", content: "气泡位置  显示正常")
        checkGetAttStr(keyword: "em", content: "<em></em>")
        checkGetAttStr(keyword: "大", content: "<em>大文档</em>")
        checkGetAttStr(keyword: "大", content: "<em>大文档</em>大文档")
        checkGetAttStr(keyword: "大", content: "文<em>大文档</em>大文档")
        checkGetAttStr(keyword: "大", content: "文<em>大</em><em>大</em>文档")
        checkGetAttStr(keyword: "AA", content: "AA BB")
        checkGetAttStr(keyword: "AA", content: "<em>AA</em> BB")
        checkGetAttStr(keyword: "BB", content: "AA <em>BB</em>")
        checkGetAttStr(keyword: "AA/:BB", content: "<em>AABB</em>") // 线上问题
    }

    func checkGetAttStr(keyword: String, content: String?) {
        let attTitle = SpaceSearch.getAttributeStr(keyword: keyword, content: content)
        XCTAssertNotNil(attTitle, "attTitle can't be nil")
    }
    // MARK: - detail formate
    /// test formate everything to htmlString for search result detail
    func testGetPreviewAttributeStr() {
        checkGetPreviewAttributeStr(keyword: "", content: nil)
        checkGetPreviewAttributeStr(keyword: "E", content: "气泡位置  显示正常")
        checkGetPreviewAttributeStr(keyword: "em", content: "<em></em>")
        checkGetPreviewAttributeStr(keyword: "大", content: "<em>大文档</em>")
        checkGetPreviewAttributeStr(keyword: "大", content: "<em>大文档</em>大文档")
        checkGetPreviewAttributeStr(keyword: "大", content: "文<em>大文档</em>大文档")
        checkGetPreviewAttributeStr(keyword: "大", content: "文<em>大</em><em>大</em>文档")
        checkGetPreviewAttributeStr(keyword: "AA", content: "AA BB")
        checkGetPreviewAttributeStr(keyword: "AA", content: "<em>AA</em> BB")
        checkGetPreviewAttributeStr(keyword: "BB", content: "AA <em>BB</em>")
        checkGetPreviewAttributeStr(keyword: "AA/:BB", content: "<em>AABB</em>") // 线上问题
    }

    func checkGetPreviewAttributeStr(keyword: String, content: String?) {
        let attDetail = SpaceSearch.getPreviewAttributeStr(keyword: keyword, content: content)
        XCTAssertNotNil(attDetail, "attDetail can't be nil")
    }
}
