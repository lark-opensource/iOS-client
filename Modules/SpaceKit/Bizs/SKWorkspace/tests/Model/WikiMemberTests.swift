//
//  WikiMemberTests.swift
//  SKWikiV2-Unit-Tests
//
//  Created by Weston Wu on 2022/11/21.
//

import XCTest
@testable import SKWorkspace
import SKFoundation
import LarkLocalizations
import SKCommon
import SpaceInterface

final class WikiMemberTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }
    
    func testDisplayName() {
        let currentLang = LanguageManager.currentLanguage
        defer {
            LanguageManager.setCurrent(language: currentLang, isSystem: true)
        }
        
        var member = WikiMember(memberID: "MOCK_MEMBER_ID",
                                type: 0,
                                name: "MOCK_NAME",
                                enName: "MOCK_EN_NAME",
                                aliasInfo: nil,
                                iconPath: "www.test.com/mock_icon",
                                memberDescription: "MOCK_DESCRIPTION",
                                role: 0)
        LanguageManager.setCurrent(language: .en_US, isSystem: false)
        XCTAssertEqual(member.displayName, member.enName)
        LanguageManager.setCurrent(language: .zh_CN, isSystem: false)
        XCTAssertEqual(member.displayName, member.name)
        
        let alias = UserAliasInfo(displayName: "MOCK_DISPLAY_NAME", i18nDisplayNames: [:])
        member.aliasInfo = alias
        XCTAssertEqual(member.displayName, alias.displayName)
    }
}
