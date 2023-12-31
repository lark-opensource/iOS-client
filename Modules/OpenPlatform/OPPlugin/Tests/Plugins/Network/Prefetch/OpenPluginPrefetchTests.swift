//
//  PrefetchTests.swift
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by 刘焱龙 on 2023/3/30.
//

import XCTest
import RustPB
import LarkRustClient
import LarkContainer
import LarkOpenAPIModel
import TTMicroApp
import Swinject
import LarkAssembler
import AppContainer
import ECOInfra
import OPUnitTestFoundation
@testable import LarkSetting
@testable import OPPlugin

@available(iOS 13.0, *)
class OpenPluginPrefetchTests: XCTestCase {
    private let task = BDPTask()

    @Provider private var rustService: RustService

    var testUtils = OpenPluginGadgetTestUtils()
    var prefetcher: BDPAppPagePrefetcher?
    var mockRustService: OPMockRustService {
        return rustService as! OPMockRustService
    }

    override func setUpWithError() throws {
        // 替换RustClient实现者
        let assemblies: [LarkAssemblyInterface] = [
            OpenPluginRustMockAssembly(),
            OpenPluginMockCookieAssembly()
        ]

        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }

        try mockFG()
        try mockSetting()
        FeatureGatingStorage.updateDebugFeatureGating(fg: "openplatform.prefetch.crash.fix.opt", isEnable: true, id: "")

        prefetcher = BDPAppPagePrefetcher(uniqueID: testUtils.uniqueID)

        BDPTracingManager.sharedInstance().generateTracing(by: testUtils.uniqueID)
        BDPTaskManager.shared().add(task, uniqueID: testUtils.uniqueID)
    }

    override func tearDownWithError() throws {
        // 恢复RustClient
        let assemblies: [LarkAssemblyInterface] = [
            OpenPluginRustRestoreAssembly(),
        ]

        _ = assemblies.forEach { $0.registContainer(container: BootLoader.container) }

        prefetcher = nil
        FeatureGatingStorage.updateDebugFeatureGating(fg: "openplatform.prefetch.crash.fix.opt", isEnable: false, id: "")

        BDPTracingManager.sharedInstance().clearAllTracing()
        BDPTaskManager.shared().removeTask(with: testUtils.uniqueID)
    }

    func test_prefetch_open() throws {
        PrefetchMockSetting.enableFixDecode()
        FeatureGatingStorage.updateDebugFeatureGating(fg: "bdp_startpage_prefetch.enable", isEnable: true, id: "")
        XCTAssertNotNil(BDPAppPagePrefetchManager.shared())
        addTeardownBlock {
            PrefetchMockSetting.disableFixDecode()
        }
    }
    
    func test_prefetch_open_not_fix_decode() throws {
        PrefetchMockSetting.disableFixDecode()
        FeatureGatingStorage.updateDebugFeatureGating(fg: "bdp_startpage_prefetch.enable", isEnable: true, id: "")
        XCTAssertNotNil(BDPAppPagePrefetchManager.shared())
        addTeardownBlock {
            PrefetchMockSetting.enableFixDecode()
        }
    }

    // common mock

    func mockSetting() throws {
        let mockNetworkValue = """
        {
            "request": {
                "default": true,
                "forceDisable": false
            },
            "download": {
                "default": false,
                "forceDisable": false
            },
            "upload": {
                "default": false,
                "forceDisable": false
            }
        }
        """
        SettingStorage.updateSettingValue(mockNetworkValue, with: SettingManager.currentChatterID(), and: "use_new_network_api")
    }

    func mockFG() throws {
        FeatureGatingStorage.updateDebugFeatureGating(fg: "bdp_startpage_prefetch.enable", isEnable: true, id: "")
        FeatureGatingStorage.updateDebugFeatureGating(fg: "openplatform.api.request.prefetch.align", isEnable: true, id: "")
        FeatureGatingStorage.updateDebugFeatureGating(fg: "openplatform.gadget.enable.config.from.lark.setting", isEnable: true, id: "")
    }

    func mockPrefetchRequestSuccessResult() throws -> [MockRustResponse] {
        let responsePayload = """
        {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": "Hello World",
            "requestTaskId": "rtyiombf-3y6276678432-fvueyguf23g7vyuce"
        }
        """
        let extra = """
        {
            "url": "https://www.feishu.cn",
            "statusCode": 200,
            "cookies": []
        }
        """

        var response = Openplatform_Api_OpenAPIResponse()
        response.payload = responsePayload
        response.extra = extra
        return [MockRustResponse(response: response, success: true)]
    }

    func mockPrefetchRequestFailResult(errorCode: Int = 500) throws -> [MockRustResponse] {
        let realErrorCode = Int32(truncatingIfNeeded: errorCode)
        let errorInfo = BusinessErrorInfo(code: realErrorCode, errorStatus: realErrorCode, errorCode: realErrorCode, debugMessage: "fail", displayMessage: "fail", serverMessage: "fail", userErrTitle: "fail", requestID: "123456")
        let error = RCError.businessFailure(errorInfo: errorInfo)
        return [MockRustResponse(response: error, success: false)]
    }
}
