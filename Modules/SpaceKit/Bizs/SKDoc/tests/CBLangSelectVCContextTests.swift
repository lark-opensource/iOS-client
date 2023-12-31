//
//  CBLangSelectVCContextTests.swift
//  SKDoc_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/9/28.
//

import Foundation
@testable import SKDoc
@testable import SKCommon
@testable import SKBrowser
import XCTest

class CBLangSelectVCContextTests: XCTestCase {
    
    private var context: CBLangSelectVCContext!
    
    override func setUp() {
        super.setUp()
        let languages = ["Plain Text", "Ada", "ABAP", "Apache", "Apex", "Assembly language", "Bash", "C#", "C++", "C"]
        let selectLanguage = "Plain Text"
        context = CBLangSelectVCContext(languages: languages, selectLanguage: selectLanguage)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSelectIndex() {
        let count = context.obtainLanguages().count
        let selectIndex = context.obtainSelectIndex()
        let languageInfo = context.ontainLanguageInfoWithIndex(0)
        context.filterRelatedLanguagesWithKeyword("test") {}
        context.resetFilterLanguages {}
    }
    
}
