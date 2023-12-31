//
//  BDPVersionManagerTests.swift
//  OPSDKTest
//
//  Created by laisanpin on 2022/7/12.
//

import XCTest

@testable import OPGadget
@testable import TTMicroApp

extension PKMMetaUpdateStrategy: Comparable {
    public static func < (lhs: TTMicroApp.PKMMetaUpdateStrategy, rhs: TTMicroApp.PKMMetaUpdateStrategy) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

final class OPGadgetPKMStrategyTests: XCTestCase {
    let mockAppMetaJson = """
    {
        \"name\": \"横屏适配小程序\",
        \"version\": \"1.0.80\",
        \"iconUrl\": \"https:\\/\\/s1-imfile.feishucdn.com\\/static-resource\\/v1\\/v2_1e9951d8-8ea5-42ed-9cef-e79bb3ca700g\",
        \"appType\": 1,
        \"packageData\": {
            \"urls\": [\"https:\\/\\/sf3-scmcdn-cn.feishucdn.com\\/obj\\/larkdeveloper\\/app\\/cli_a229a06320b9d013\\/current\\/gadget_mobile_splits_pkg\\/lc4m37jj_xbr9x8b6i0k.ttpkg.js\", \"https:\\/\\/sf3-cn.feishucdn.com\\/obj\\/larkdeveloper\\/app\\/cli_a229a06320b9d013\\/current\\/gadget_mobile_splits_pkg\\/lc4m37jj_xbr9x8b6i0k.ttpkg.js\"],
            \"md5\": \"7a3a86e2c1f503a9213e1fd7715a4483\"
        },
        \"identifier\": \"cli_a229a06320b9d013\",
        \"mobileSubPackage\": {},
        \"appID\": \"cli_a229a06320b9d013\",
        \"compileVersion\": \"default\",
        \"appVersion\": \"1.2.9\",
        \"components\": [{
            \"name\": \"editor\"
        }],
        \"batchMetaVersion\": 0,
        \"authData\": {
            \"versionUpdateTime\": 1672048076,
            \"versionState\": 0,
            \"authList\": [],
            \"appStatus\": 1,
            \"domainsAuthDict\": {},
            \"blackList\": [],
            \"gadgetSafeUrls\": [\"https:\\/\\/www.baidu.com\", \"https:\\/\\/open.feishu.cn\", \"https:\\/\\/open.larksuite.com\", \"https:\\/\\/app.feishu.cn\", \"https:\\/\\/wj.bytedance.com\", \"https:\\/\\/seal.bytedance.net\", \"https:\\/\\/applink.feishu.cn\", \"https:\\/\\/applink.larksuite.com\", \"https:\\/\\/i.snssdk.com\", \"https:\\/\\/www.feishu.cn\", \"https:\\/\\/applink.feishu.cn\", \"https:\\/\\/applink.larksuite.com\", \"https:\\/\\/larksuite.help\", \"https:\\/\\/getfeishu.cn\", \"https:\\/\\/wiki.bytedance.net\", \"https:\\/\\/sso.bytedance.com\", \"https:\\/\\/passport.feishu.cn\", \"https:\\/\\/jira.feishu.cn\"]
        },
        \"versionType\": \"current\",
        \"businessData\": {
            \"message_action\": true,
            \"isFromBuildin\": false,
            \"minJSsdkVersion\": \"1.5.3\",
            \"shareLevel\": 0,
            \"extraDict\": {
                \"feedback\": false,
                \"orgAuthScope\": {},
                \"useOpenSchemaWhiteList\": false,
                \"openSchemaWhiteList\": [],
                \"lark_version\": \"0\",
                \"web_app\": {
                    \"md5\": \"\",
                    \"url\": \"\",
                    \"version_code\": \"\"
                }
            },
            \"versionCode\": 1672047822,
            \"minLarkVersion\": \"0\",
            \"webURL\": \"\",
            \"chat_action\": true
        }
    }
"""

    let mockUniqueID = BDPUniqueID(appID: "mock", identifier: nil, versionType: .current, appType: .gadget)
    func test_downloadPriority_loadTypeNormal() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.normal, useLocalMeta: true, expireStrategy: OPGadgetMetaUpdateStrategy.async)
        // Assert
        XCTAssertEqual(strategy.pkgDownloadPriority, URLSessionTask.highPriority)
    }

    func test_downloadPriority_loadTypeUpdate() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.update, useLocalMeta: true, expireStrategy: OPGadgetMetaUpdateStrategy.async)
        // Assert
        XCTAssertEqual(strategy.pkgDownloadPriority, URLSessionTask.lowPriority)
    }

    func test_updateStrategy_notUseLocalMeta() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.normal, useLocalMeta: false, expireStrategy: OPGadgetMetaUpdateStrategy.async)
        let triggerCtx = PKMTriggerStrategyContext(localMeta: PKMMockMeta(), timestamp: nil)

        // Act
        let updateType = strategy.updateStrategy(triggerCtx, beforeInvoke: nil)

        // Assert
        XCTAssertEqual(updateType, PKMMetaUpdateStrategy.forceRemote)
    }

    func test_updateStrategy_noLocalMetaCache() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.normal, useLocalMeta: true, expireStrategy: OPGadgetMetaUpdateStrategy.async)
        let triggerCtx = PKMTriggerStrategyContext(localMeta: nil, timestamp: nil)

        // Act
        let updateType = strategy.updateStrategy(triggerCtx, beforeInvoke: nil)

        // Assert
        XCTAssertEqual(updateType, PKMMetaUpdateStrategy.forceRemote)
    }

    func test_updateStrategy_expiredAsync() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.normal, useLocalMeta: true, expireStrategy: OPGadgetMetaUpdateStrategy.async)
        let triggerCtx = PKMTriggerStrategyContext(localMeta: PKMMockMeta(), timestamp: nil)

        // Act
        let updateType = strategy.updateStrategy(triggerCtx, beforeInvoke: nil)

        // Assert
        XCTAssertEqual(updateType, PKMMetaUpdateStrategy.useLocal)
    }

    func test_updateStrategy_expiredSyncTry() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.normal, useLocalMeta: true, expireStrategy: OPGadgetMetaUpdateStrategy.syncTry)
        let triggerCtx = PKMTriggerStrategyContext(localMeta: PKMMockMeta(), timestamp: nil)

        // Act
        let updateType = strategy.updateStrategy(triggerCtx, beforeInvoke: nil)

        // Assert
        XCTAssertEqual(updateType, PKMMetaUpdateStrategy.tryRemote)
    }

    func test_updateStrategy_expiredSyncForce() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.normal, useLocalMeta: true, expireStrategy: OPGadgetMetaUpdateStrategy.syncForce)
        let triggerCtx = PKMTriggerStrategyContext(localMeta: PKMMockMeta(), timestamp: nil)

        // Act
        let updateType = strategy.updateStrategy(triggerCtx, beforeInvoke: nil)

        // Assert
        XCTAssertEqual(updateType, PKMMetaUpdateStrategy.forceRemote)
    }

    func test_buildMeta() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.normal, useLocalMeta: true, expireStrategy: OPGadgetMetaUpdateStrategy.syncTry, metaProvider: GadgetMetaProvider(type: .gadget))
        // Act
        let gadgetMeta = strategy.buildMeta(with: self.mockAppMetaJson)

        // Assert
        XCTAssert(gadgetMeta != nil)
    }

    func test_copy() {
        // Arrange
        let strategy = OPGadgetPKMStrategy(uniqueID: mockUniqueID, loadType: PKMLoadType.normal, useLocalMeta: true, expireStrategy: OPGadgetMetaUpdateStrategy.syncTry)
        // Act
        let copyStrategy = strategy.copy()

        // Assert
        let result = strategy.loadType == copyStrategy.loadType && strategy.pkgDownloadPriority == copyStrategy.pkgDownloadPriority
        XCTAssert(result)
    }
}

final class PKMMockMeta: PKMBaseMetaProtocol {
    var pkmID: TTMicroApp.PKMUniqueID {
        return PKMUniqueID(appID: "cli_a229a06320b9d013", identifier: nil)
    }

    var bizType: String {
        return "gadget"
    }

    var urls: [String] {
        ["https:\\/\\/sf3-scmcdn-cn.feishucdn.com\\/obj\\/larkdeveloper\\/app\\/cli_a229a06320b9d013\\/current\\/gadget_mobile_splits_pkg\\/lc4m37jj_xbr9x8b6i0k.ttpkg.js"]
    }

    var md5: String? {
        return nil
    }

    var appVersion: String {
        return "1.0.0"
    }

    var originalJSONString: String {
        return ""
    }
}
