//
//  DomainSettingTest.swift
//  LarkSettingDevEEUnitTest
//
//  Created by Supeng on 2021/7/3.
//

import Foundation
import XCTest
@testable import LarkSetting
import LarkEnv

//swiftlint:disable no_space_in_method_call identifier_name

class DomainSettingTest: XCTestCase {
    enum AllEnv: String, CaseIterable {
        case release
        case pre_release
    }

    enum AllUnit: String, CaseIterable {
        case eu_nc
        case eu_ea
        case larksgaws
        case larkjpaws

        var geo: String {
            switch self {
            case .eu_nc: return "cn"
            case .eu_ea: return "us"
            case .larkjpaws: return "jp"
            case .larksgaws: return "sg"
            }
        }
    }

    enum AllBrand: String, CaseIterable {
        case feishu
        case lark
    }

    let settingKey = "biz_domain_config"

    override func setUp() {
        super.setUp()
        SettingManager.currentChatterID = { testUserID }
        cache.removeAllObjects()
    }

    func testUpdateDomain() {
        // 测试直接调用DomainSettingManager的update方法可以正常工作
        let result = DomainSettingManager.shared.currentSetting
        DomainSettingManager.shared.update(domain: [.api: ["1234"]], envString: EnvManager.env.settingDescription)
        let newResult = DomainSettingManager.shared.currentSetting
        XCTAssertNotEqual(result, newResult)
        XCTAssertEqual(newResult.count, 1)
    }

    func testCanGetDomain() {
        // 测试不同环境下都能获取到DomainMap
        [Env.TypeEnum.release, Env.TypeEnum.preRelease]
            .flatMap { env in
                AllUnit.allCases.flatMap { unit in
                    AllBrand.allCases.map { (Env(unit: unit.rawValue, geo: unit.geo, type: env), $0) }
                }
            }
            .forEach {
                XCTAssertTrue(!(DomainSettingManager
                    .shared
                    .getDestinedDomainSetting(with: $0.0, and: $0.1.rawValue)?.isEmpty ?? false))
            }
    }

    func testDiskCache() {
        // 初始DiskCache数目为0
        XCTAssertEqual(cache.diskCache?.totalCount() ?? -1, 0)

        DomainSettingManager.shared.update(domain: [.api: ["123"]], envString: EnvManager.env.settingDescription)

        // 磁盘缓存是异步的，所以需要等一小段时间再读才能读到正确的数据
        let expect = expectation(description: "disk cache")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            // 有fg更新以后，disk cache数目为1
            XCTAssertEqual(cache.diskCache?.totalCount() ?? -1, 1)
            let setting = DomainSettingManager.shared.getDestinedDomainSetting(with: EnvManager.env, and: "feishu")

            XCTAssertNotNil(setting)
            XCTAssertEqual(setting![.api], ["123"])

            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)
    }

    func testMultiEnv() {
        DomainSettingManager.shared.update(domain: [.api: ["1234"]], envString: "pre_release_eu_nc_feishu")

        // 切换到其它环境，获取不到该数据
        DomainSettingManager.shared.update(domain: [.api: ["123"]], envString: EnvManager.env.settingDescription)
        XCTAssertNotEqual(DomainSettingManager.shared.currentSetting[.api], ["1234"])

        // 切换其它环境以后，磁盘缓存有两份数据
        let expect = expectation(description: "disk cache")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            XCTAssertEqual(cache.diskCache?.totalCount() ?? -1, 2)
            expect.fulfill()
        }
        wait(for: [expect], timeout: 1.0)

        // 切换回最开始的环境，可以获取到原数据
        XCTAssertNotNil(DomainSettingManager.shared.currentSetting[.api])
        XCTAssertEqual(DomainSettingManager.shared.currentSetting[.api]!, ["123"])
    }
}
