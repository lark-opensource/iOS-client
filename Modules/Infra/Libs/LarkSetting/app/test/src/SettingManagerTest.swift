//
//  SettingManagerTest.swift
//  LarkSettingDevEEUnitTest
//
//  Created by Supeng on 2021/6/3.
//

import Foundation
import XCTest
@testable import LarkSetting
import LarkCombine

//swiftlint:disable no_space_in_method_call

let testUserID = "testUserID"

class SettingManagerTest: XCTestCase {

    private var combineDisposeBag: [AnyCancellable] = []
    private let previewTransforms = UserSettingKey.make(userKeyLiteral: "previewTransforms")
    private let TestKey = UserSettingKey.make(userKeyLiteral: "TestKey")

    override func setUp() {
        super.setUp()
        SettingManager.currentChatterID = { testUserID }
        cache.removeAllObjects()
        combineDisposeBag = []
    }

    func testGetSetting() throws {
        let setting1: HelpDeskCommon = try SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                                         decodeStrategy: .useDefaultKeys)
        XCTAssertFalse(setting1.feishuMiniAppLink.isEmpty)

        let setting2: VCMutePromptConfig = try SettingManager.shared.setting(with: VCMutePromptConfig.self,
                                                                             key: UserSettingKey..make(userKeyLiteral: "vc_mute_prompt_config"))
        XCTAssertTrue(setting2.interval > 0)
    }

    func testGetStaticSetting() throws {
        // 先给一个初始配置
        SettingStorage.shared.update(["previewTransforms": str], id: testUserID)

        // 测试能正常取到配置
        let result = try SettingManager.shared.staticSetting(with: previewTransforms)
        XCTAssertFalse(result.isEmpty)

        // 更新一下配置
        SettingStorage.shared.update(["previewTransforms": ""], id: testUserID)
        let result2 = try SettingManager.shared.staticSetting(with: previewTransforms)
        XCTAssertFalse(result2.isEmpty)

        // 静态接口应该取得一样，还是之前的配置
        XCTAssertEqual(result.keys.count, result2.keys.count)
        result.keys.forEach { XCTAssertNotNil(result2[$0]) }
    }

    func testStaticMultiUsers() throws {
        // 首先设置成用户1
        SettingManager.currentChatterID = { "uid1" }
        // 先给一个用户1的初始配置
        SettingStorage.shared.update(["previewTransforms": str], id: "uid1")

        // 测试用户1能正常取到配置
        let result = try SettingManager.shared.staticSetting(with: previewTransforms)
        XCTAssertFalse(result.isEmpty)

        // 再给一个用户2的初始配置
        SettingStorage.shared.update(["previewTransforms": str2], id: "uid2")

        // 切换到用户2
        SettingManager.currentChatterID = { "uid2" }

        // 用户2应该取到不同的配置
        let result2 = try SettingManager.shared.staticSetting(with: previewTransforms)
        XCTAssertNotEqual(result.keys.count, result2.keys.count)

        // 再切换回用户1
        SettingManager.currentChatterID = { "uid1" }

        // 用户1能正常取到之前的配置
        let result3 = try SettingManager.shared.staticSetting(with: previewTransforms)
        XCTAssertEqual(result3.count, 2)
    }

    func testRxObserveSetting() throws {
        let setting1: HelpDeskCommon = try SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                                         decodeStrategy: .useDefaultKeys)

        var result: [String] = []
        _ = SettingManager.shared.observe(type: HelpDeskCommon.self, decodeStrategy: .useDefaultKeys)
            .subscribe(onNext: { value in
                print(value)
                result.append(value.feishuMiniAppLink)
            })

        let temp = HelpDeskCommon(feishuMiniAppLink: "NewValue", helpdeskMiniProgramAppId: "")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let data = try JSONEncoder().encode(temp)
        let string = String(data: data, encoding: .utf8)!

        let settingDic: [String: String] = [HelpDeskCommon.settingKey: string]
        SettingStorage.shared.update(settingDic, id: testUserID)

        XCTAssertEqual(result, [setting1.feishuMiniAppLink, "NewValue"])
    }

    func testCombineObserveSetting() throws {
        let setting1: HelpDeskCommon = try SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                                         decodeStrategy: .useDefaultKeys)

        var result: [String] = []
        SettingManager.shared.observe(type: HelpDeskCommon.self, decodeStrategy: .useDefaultKeys)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in
                    print(value)
                    result.append(value.feishuMiniAppLink)
            })
            .store(in: &combineDisposeBag)

        let temp = HelpDeskCommon(feishuMiniAppLink: "NewValue", helpdeskMiniProgramAppId: "")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let data = try JSONEncoder().encode(temp)
        let string = String(data: data, encoding: .utf8)!
        let settingDic: [String: String] = [HelpDeskCommon.settingKey: string]
        SettingStorage.shared.update(settingDic, id: testUserID)

        XCTAssertEqual(result, [setting1.feishuMiniAppLink, "NewValue"])
    }

    func testSettingProperyWrapper() {
        SettingStorage.shared.update(["previewTransforms": str], id: testUserID)

        let model = SettingProperyWrapperTestModel()
        XCTAssertNotNil(model.helpDeskCommon)
        XCTAssertFalse(model.helpDeskCommon!.feishuMiniAppLink.isEmpty)

        XCTAssertNil(model.abbrCommon1)
        XCTAssertNil(model.nonExistModel)
        XCTAssertNotNil(model.previewTransforms)
        XCTAssertFalse(model.previewTransforms!.isEmpty)
    }

    func testDiskCache() throws {
        // 初始DiskCache数目为0
        XCTAssertEqual(LarkSetting.cache.diskCache?.totalCount() ?? -1, 0)

        let temp = HelpDeskCommon(feishuMiniAppLink: "NewValue", helpdeskMiniProgramAppId: "")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let data = try JSONEncoder().encode(temp)
        let string = String(data: data, encoding: .utf8)!
        let settingDic: [String: String] = ["TestKey": string]
        SettingStorage.shared.update(settingDic, id: testUserID)

        // 磁盘缓存是异步的，所以需要等一小段时间再读才能读到正确的数据
        let expect = expectation(description: "disk cache")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // 有Setting更新以后，disk cache数目为1
            XCTAssertEqual(LarkSetting.cache.diskCache?.totalCount() ?? -1, 1)
            let setting1: HelpDeskCommon? = try? SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                                               key: "TestKey",
                                                                               decodeStrategy: .useDefaultKeys)

            XCTAssertNotNil(setting1)
            XCTAssertTrue(SettingStorage.shared.allSettingKeys(with: testUserID).count > 1)

            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testDiskCache2() throws {
        // 测试磁盘持久化
        let setting: HelpDeskCommon? = try? SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                                          key: TestKey,
                                                                          decodeStrategy: .useDefaultKeys)
        XCTAssertNil(setting)

        let temp = HelpDeskCommon(feishuMiniAppLink: "NewValue", helpdeskMiniProgramAppId: "")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let data = try JSONEncoder().encode(temp)
        let string = String(data: data, encoding: .utf8)!
        let settingDic: [String: String] = ["TestKey": string]
        SettingStorage.shared.update(settingDic, id: testUserID)

        // 重置SettingManager，可以读取到磁盘缓存
        let expect = expectation(description: "disk cache")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let setting1: HelpDeskCommon? = try? SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                                               key: "TestKey",
                                                                               decodeStrategy: .useDefaultKeys)
            XCTAssertNotNil(setting1)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testMemoryCache() {
        // 调用过一次setting接口以后内存缓存有数据
        _ = try? SettingManager.shared.setting(with: HelpDeskCommon.self,
                                               key: TestKey,
                                               decodeStrategy: .useDefaultKeys)
        XCTAssertTrue(!SettingStorage.shared.allSettingKeys(with: testUserID).isEmpty)

        // 切换用户以后，内存缓存数据跟着切换
        let anotherUser = "not valid user"
        SettingManager.currentChatterID = { anotherUser }
        _ = try? SettingManager.shared.setting(with: HelpDeskCommon.self, key: TestKey,
                                               decodeStrategy: .useDefaultKeys)

        XCTAssertTrue(!SettingStorage.shared.allSettingKeys(with: anotherUser).isEmpty)
    }

    func testMultiUser() throws {
        let temp = HelpDeskCommon(feishuMiniAppLink: "NewValue", helpdeskMiniProgramAppId: "")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        let data = try JSONEncoder().encode(temp)
        let string = String(data: data, encoding: .utf8)!
        var settingDic: [String: String] = ["TestKey": string]
        SettingStorage.shared.update(settingDic, id: testUserID)

        var setting1: HelpDeskCommon? = try? SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                                           key: TestKey,
                                                                           decodeStrategy: .useDefaultKeys)
        XCTAssertNotNil(setting1)

        // 切换到其它用户，获取不到uid user的setting
        SettingManager.currentChatterID = { "not valid user" }
        setting1 = try? SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                      key: TestKey,
                                                      decodeStrategy: .useDefaultKeys)
        XCTAssertNil(setting1)

        // 更新其它用户以后，磁盘缓存有两份数据
        settingDic = ["TestKey1": string]
        SettingStorage.shared.update(settingDic, id: "not valid user")

        let expect = expectation(description: "disk cache")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(LarkSetting.cache.diskCache?.totalCount() ?? -1, 2)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)

        // 切换会123用户，可以继续获取该用户的setting
        SettingManager.currentChatterID = { testUserID }
        setting1 = try? SettingManager.shared.setting(with: HelpDeskCommon.self,
                                                      key: TestKey,
                                                      decodeStrategy: .useDefaultKeys)
        XCTAssertNotNil(setting1)
    }

    func testSettingReturnString() throws {
        // 测试直接返回String场景
        SettingStorage.shared.update(["previewTransforms": str], id: testUserID)
        let result = try SettingManager.shared.setting(with: previewTransforms)
        XCTAssertFalse(result.isEmpty)
    }
}

struct HelpDeskCommon: SettingDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "helpdesk_common")

    let feishuMiniAppLink: String
    let helpdeskMiniProgramAppId: String

    enum CodingKeys: String, CodingKey {
        case feishuMiniAppLink = "feishu_mini_app_link"
        case helpdeskMiniProgramAppId = "helpdesk-mini-program-appId"
    }
}

struct VCMutePromptConfig: Decodable {
    let interval: Int
    let level: Int
}

struct NonExistModel: SettingDecodable{
    static let settingKey = UserSettingKey.make(userKeyLiteral: "none-exist-key")
    let noneExistProperty: [String]
}

struct SettingProperyWrapperTestModel {
    @Setting(.useDefaultKeys) var helpDeskCommon: HelpDeskCommon?
    @Setting(key: UserSettingKey.make(userKeyLiteral: "none-exist-key")) var abbrCommon1: HelpDeskCommon?
    @Setting var nonExistModel: NonExistModel?
    @RawSetting(key: previewTransforms) var previewTransforms: [String: Any]?
}

extension HelpDeskCommon: Encodable {}
extension VCMutePromptConfig: Encodable {}
extension NonExistModel: Encodable {}

let str =
"""
{
            "1001": {
                "bmp": [
                    16
                ],
                "csv": [
                    14,
                    16
                ],
                "doc": [
                    16,
                    9
                ],
                "docx": [
                    16,
                    9
                ],
                "dot": [
                    16,
                    9
                ],
                "dotx": [
                    16,
                    9
                ],
                "gif": [
                    16
                ],
                "html": [
                    16
                ],
                "jpeg": [
                    16
                ],
                "jpg": [
                    16
                ],
                "key": [
                    16
                ],
                "mov": [
                    3,
                    16
                ],
                "mp4": [
                    3,
                    16
                ],
                "numbers": [
                    16
                ],
                "pages": [
                    16
                ],
                "pdf": [
                    16,
                    9
                ],
                "png": [
                    16
                ],
                "pot": [
                    9,
                    16
                ],
                "pps": [
                    9,
                    16
                ],
                "ppsx": [
                    9,
                    16
                ],
                "ppt": [
                    9,
                    16
                ],
                "pptx": [
                    9,
                    16
                ],
                "rtf": [
                    9,
                    16
                ],
                "txt": [
                    14,
                    16
                ],
                "xls": [
                    16,
                    9
                ],
                "xlsm": [
                    16,
                    9
                ],
                "xlsx": [
                    16,
                    9
                ]
            },
            "1002": {
                "csv": [
                    -2
                ],
                "doc": [
                    -2
                ],
                "docx": [
                    -2
                ],
                "gif": [
                    -2
                ],
                "jpeg": [
                    -2
                ],
                "jpg": [
                    -2
                ],
                "pdf": [
                    -2
                ],
                "png": [
                    -2
                ],
                "ppt": [
                    -2
                ],
                "pptx": [
                    -2
                ],
                "txt": [
                    -2
                ],
                "xls": [
                    -2
                ],
                "xlsm": [
                    -2
                ],
                "xlsx": [
                    -2
                ]
            }
    }
"""

let str2 =
"""
{
            "1001": {
                "bmp": [
                    16
                ]
            }
    }
"""
