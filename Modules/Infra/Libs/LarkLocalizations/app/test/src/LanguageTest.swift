//
//  LanguageTest.swift
//  LarkLocalizationsDevEEUnitTest
//
//  Created by Crazy凡 on 2020/1/16.
//

import Foundation
import XCTest
@testable import LarkLocalizations

// 测试Language和对应标识的一致性
class LanguageTest: XCTestCase {
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testLanguageInit() {
        XCTAssertEqual(Language(rawValue: "zh_CN"), Language.zh_CN)
        XCTAssertEqual(Language(rawValue: "en_US"), Language.en_US)
        XCTAssertEqual(Language(rawValue: "ja_JP"), Language.ja_JP)

        XCTAssertEqual(Language(string: "ZH_cn"), Language.zh_CN)
        XCTAssertEqual(Language(string: "En_us"), Language.en_US)
        XCTAssertEqual(Language(string: "jA_jp"), Language.ja_JP)

        XCTAssertEqual(Language(string: "ZH"), Language.zh_CN)
        XCTAssertEqual(Language(string: "En"), Language.en_US)
        XCTAssertEqual(Language(string: "jA"), Language.ja_JP)

        XCTAssertEqual(Lang(rawValue: "zh_CN"), Lang.zh_CN)
        XCTAssertEqual(Lang(rawValue: "en_US"), Lang.en_US)
        XCTAssertEqual(Lang(rawValue: "ja_JP"), Lang.ja_JP)

        XCTAssertEqual(Lang(rawValue: "ZH_cn"), Lang.zh_CN)
        XCTAssertEqual(Lang(rawValue: "En_us"), Lang.en_US)
        XCTAssertEqual(Lang(rawValue: "jA_jp"), Lang.ja_JP)

        XCTAssertEqual(Lang(rawValue: "ZH-Hans-cn"), Lang.zh_CN)
        XCTAssertEqual(Lang(rawValue: "ZH-cn"), Lang.zh_CN)
        XCTAssertEqual(Lang(rawValue: "En-us"), Lang.en_US)
        XCTAssertEqual(Lang(rawValue: "jA-jp"), Lang.ja_JP)
    }

    func testTableName() {
        XCTAssertEqual(Language.zh_CN.tableName, "zh-CN")
        XCTAssertEqual(Language.en_US.tableName, "en-US")
        XCTAssertEqual(Language.ja_JP.tableName, "ja-JP")
    }

    /// equal to old tableName
    func testLanguageIdentifier() {
        XCTAssertEqual(Lang.zh_CN.languageIdentifier, "zh-CN")
        XCTAssertEqual(Lang.en_US.languageIdentifier, "en-US")
        XCTAssertEqual(Lang.ja_JP.languageIdentifier, "ja-JP")
    }

    func testAltTableName() {
        XCTAssertEqual(Language.zh_CN.altTableName, "zh_CN")
        XCTAssertEqual(Language.en_US.altTableName, "en_US")
        XCTAssertEqual(Language.ja_JP.altTableName, "ja_JP")
    }

    /// equal to old altTableName
    func testLocaleIdentifier() {
        XCTAssertEqual(Lang.zh_CN.localeIdentifier, "zh_CN")
        XCTAssertEqual(Lang.en_US.localeIdentifier, "en_US")
        XCTAssertEqual(Lang.ja_JP.localeIdentifier, "ja_JP")
    }

    func testPrefix() {
        XCTAssertEqual(Language.zh_CN.prefix, "zh")
        XCTAssertEqual(Language.en_US.prefix, "en")
        XCTAssertEqual(Language.ja_JP.prefix, "ja")
    }

    func testLanguageCode() {
        XCTAssertEqual(Lang.zh_CN.languageCode, "zh")
        XCTAssertEqual(Lang.en_US.languageCode, "en")
        XCTAssertEqual(Lang.ja_JP.languageCode, "ja")
    }

    func testDispalyName() {
        XCTAssertEqual(Language.zh_CN.displayName, "简体中文")
        XCTAssertEqual(Language.en_US.displayName, "English")
        XCTAssertEqual(Language.ja_JP.displayName, "日本語")

        XCTAssertEqual(Lang.zh_CN.displayName, "简体中文")
        XCTAssertEqual(Lang.en_US.displayName, "English")
        XCTAssertEqual(Lang.ja_JP.displayName, "日本語")
        XCTAssertEqual(Lang.rw.displayName, "Pseudo Language")
    }
}

class LanguageManagerTest: XCTestCase {
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: LanguageManager.systemLanguageIsSelected)
        UserDefaults.standard.removeObject(forKey: LanguageManager.appleLanguages)
        UserDefaults.standard.removeObject(forKey: LanguageManager.appleLocale)
        super.setUp()
    }
    /// equal to old Language init
    func testCompatibleLanguage() {
        LanguageManager.shared.supportLanguages = [.en_US, .zh_CN, .ja_JP, .zh_HK]

        XCTAssertEqual(LanguageManager.compatibleSupportedLanguage(Lang(rawValue: "ZH")), Lang.zh_CN)
        XCTAssertEqual(LanguageManager.compatibleSupportedLanguage(Lang(rawValue: "En")), Lang.en_US)
        XCTAssertEqual(LanguageManager.compatibleSupportedLanguage(Lang(rawValue: "jA")), Lang.ja_JP)
        XCTAssertEqual(LanguageManager.compatibleSupportedLanguage(Lang(rawValue: "zh-Hant-HK")), Lang.zh_HK)
    }
    func testCurrentLanguage() {
        LanguageManager.shared.supportLanguages = [.en_US, .zh_CN, .ja_JP]
        LanguageManager.setCurrent(language: .zh_CN, isSystem: false)
        XCTAssertEqual(LanguageManager.currentLanguage, .zh_CN)
    }
}
