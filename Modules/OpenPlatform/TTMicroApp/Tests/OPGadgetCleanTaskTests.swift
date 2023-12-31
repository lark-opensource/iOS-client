//
//  OPGadgetCleanTaskTests.swift
//  TTMicroApp-Unit-Tests
//
//  Created by laisanpin on 2022/10/11.
//

import Foundation
import XCTest
import LarkCache

@testable import TTMicroApp

class MockAppMeta: AppMetaProtocol {
    var uniqueID: TTMicroApp.BDPUniqueID

    var version: String

    var name: String

    var iconUrl: String

    var packageData: TTMicroApp.AppMetaPackageProtocol

    var authData: TTMicroApp.AppMetaAuthProtocol

    var businessData: TTMicroApp.AppMetaBusinessDataProtocol

    init(uniqueID: TTMicroApp.BDPUniqueID,
         version: String = "0.1.1",
         name: String = "mock app",
         iconUrl: String = "mock icon url",
         packageData: TTMicroApp.AppMetaPackageProtocol = MockMetaPackageData(),
         authData: TTMicroApp.AppMetaAuthProtocol = MockMetaAuthData(),
         businessData: TTMicroApp.AppMetaBusinessDataProtocol = MockMetaBussinessData()) {
        self.uniqueID = uniqueID
        self.version = version
        self.name = name
        self.iconUrl = iconUrl
        self.packageData = packageData
        self.authData = authData
        self.businessData = businessData
    }

    func toJson() throws -> String {
        return "mock json"
    }

}

class MockMetaPackageData: TTMicroApp.AppMetaPackageProtocol{
    var urls: [URL]

    var md5: String

    init(urls: [URL] = [URL](),
         md5: String = "mock md5") {
        self.urls = urls
        self.md5 = md5
    }
}

class MockMetaAuthData: TTMicroApp.AppMetaAuthProtocol {}
class MockMetaBussinessData: TTMicroApp.AppMetaBusinessDataProtocol {}

class MockGadgetCleanStrategy: OPGadgetCleanStrategyProtocol {
    func cleanGadgetMetaAndPkg(deleteAction: DeleteActionCallback) {
        let mockAllGadgetMetas = [
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_0", identifier: nil, versionType: .current, appType: .gadget)),
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget)),
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_2", identifier: nil, versionType: .current, appType: .gadget))
            ]

        let needDeletedGadgetMetas = [
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget))
        ]

        let appPkgSizeMap = ["cli_mock_0" : 1,
                             "cli_mock_1" : 2,
                             "cli_mock_2" : 3]

        deleteAction(mockAllGadgetMetas, [], needDeletedGadgetMetas, appPkgSizeMap)
    }
}

class OPGadgetCleanTaskTests: XCTestCase {
    lazy var mockAllGadgetMetas: [AppMetaProtocol] = {
        [
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_0", identifier: nil, versionType: .current, appType: .gadget)),
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget)),
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_2", identifier: nil, versionType: .current, appType: .gadget)),
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_3", identifier: nil, versionType: .current, appType: .gadget)),
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_4", identifier: nil, versionType: .current, appType: .gadget)),
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_5", identifier: nil, versionType: .current, appType: .gadget)),
            MockAppMeta(uniqueID: OPAppUniqueID(appID: "cli_mock_6", identifier: nil, versionType: .current, appType: .gadget))
        ]
    }()

    lazy var mockRetainApps: [String] = {
        ["cli_mock_0", "cli_mock_2", "cli_mock_4"]
    }()

    lazy var mockAppPkgSizeMap: [String : Int] = {
        ["cli_mock_0" : 1,
         "cli_mock_1" : 2,
         "cli_mock_2" : 3,
         "cli_mock_3" : 4,
         "cli_mock_4" : 5,
         "cli_mock_5" : 6,
         "cli_mock_6" : 7]
    }()

    func test_deleteGadgetMetaAndPkg() {
        // Arrange
        let mockConfig = BDPPreloadCleanStrategyConfig(enable: true, cleanBeforeDays: 7, cleanMaxRetainAppCount: 3)
        let gadgetCleanStrategy = OPGadgetCleanStrategy(cleanStrategyConfig: mockConfig)

        let promise = expectation(description: "delete completion invoked")

        var deleteSuccess = false

        // Act
        gadgetCleanStrategy.deleteGadgetMetaAndPkg(allGadgetMetas: mockAllGadgetMetas, needRetainApps: mockRetainApps) { allMetas, _, needDeleteAppMetas, appPkgSizeMap in
            // 获取所有小程序ID集合
            let allGadgetMetaSet = Set(mockAllGadgetMetas.map({
                $0.uniqueID.appID
            }))

            // 获取需要删除小程序ID集合
            let needDeleteAppSet = Set(needDeleteAppMetas.map {
                $0.uniqueID.appID
            })

            // 将要删除的小程序和要保留的小程序取并集
            let unionApps = needDeleteAppSet.union(mockRetainApps)

            if allGadgetMetaSet == unionApps {
                deleteSuccess = true
            }

            promise.fulfill()
        }

        wait(for: [promise], timeout: 5)

        // Assert
        XCTAssertTrue(deleteSuccess)
    }

    func test_cleanStrategyConfigUnable() {
        // Arrange
        let mockConfig = BDPPreloadCleanStrategyConfig(enable: false, cleanBeforeDays: 7, cleanMaxRetainAppCount: 3)
        let gadgetCleanStrategy = OPGadgetCleanStrategy(cleanStrategyConfig: mockConfig)
        var cleanSuccess = false


        // Act
        gadgetCleanStrategy.cleanGadgetMetaAndPkg {allMetas ,_, needDeleteAppMetas, appPkgSizeMap in
            if needDeleteAppMetas.isEmpty, !gadgetCleanStrategy.cleanStrategyConfig.enable {
                cleanSuccess = true
            }
        }

        // Assert
        XCTAssertTrue(cleanSuccess)
    }

    func test_packageTaskSizeArray() {
        // Arrange
        let cleanTask = OPGadgetCacheCleanTask()
        let mockUniques = [
            OPAppUniqueID(appID: "cli_mock_0", identifier: nil, versionType: .current, appType: .gadget),
            OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget),
            OPAppUniqueID(appID: "cli_mock_2", identifier: nil, versionType: .current, appType: .gadget)
        ]

        // Act
        let taskSizes = cleanTask.packageTaskSizeArray(uniqueIDs: mockUniques,
                                                       appPkgSizeMap: mockAppPkgSizeMap)

        let expectResult = [1, 2, 3]

        // Assert
        XCTAssertEqual(expectResult.count, taskSizes.count)
    }

    func test_configGadgetCleanMonitor() {
        // Arrange
        let cleanTask = OPGadgetCacheCleanTask()

        let mockDeletedUniques = [
            OPAppUniqueID(appID: "cli_mock_0", identifier: nil, versionType: .current, appType: .gadget),
            OPAppUniqueID(appID: "cli_mock_1", identifier: nil, versionType: .current, appType: .gadget),
            OPAppUniqueID(appID: "cli_mock_2", identifier: nil, versionType: .current, appType: .gadget)
        ]

        let expectRemainCount = mockAllGadgetMetas.count - mockDeletedUniques.count

        // Act
        let monitor = cleanTask.configGadgetCleanMonitor(allGedgetMetas: mockAllGadgetMetas, deletedUniqueIDs: mockDeletedUniques, appPkgSizeMap: mockAppPkgSizeMap, costTime: 10, isUserTriggered: true)

        // Assert
        guard let dataMap = monitor.data else {
            XCTFail("monitor data is nil")
            return
        }

        guard let cleanType = dataMap["clean_type"] as? Int, cleanType == 0 else {
            XCTFail("clean_type incorrect")
            return
        }

        guard let remainCount = dataMap["remain_count"] as? Int, remainCount == expectRemainCount else {
            XCTFail("remain_count incorrect")
            return
        }

        XCTAssertTrue(true)
    }

    func test_needDeleteGadgetMetaArray() {
        // Arrange
        let expectResult = Set(["cli_mock_1", "cli_mock_3", "cli_mock_5", "cli_mock_6"])

        let mockConfig = BDPPreloadCleanStrategyConfig(enable: true, cleanBeforeDays: 7, cleanMaxRetainAppCount: 3)
        let gadgetCleanStrategy = OPGadgetCleanStrategy(cleanStrategyConfig: mockConfig)

        // Act
        let needDeletedApps = gadgetCleanStrategy.needDeleteGadgetMetaArray(allAppArray: mockAllGadgetMetas, retainAppArray: mockRetainApps).map {
            $0.uniqueID.appID
        }

        XCTAssertEqual(expectResult, Set(needDeletedApps))
    }
}
