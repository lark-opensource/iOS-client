//
//  NetWorkTest.swift
//  LarkExtensionServicesDevEEUnitTest
//
//  Created by 王元洵 on 2021/4/19.
//

import Foundation
import XCTest
@testable import LarkExtensionServices
import ExtensionPB

class NetworkTest: XCTestCase {
    override func setUp() {
        super.setUp()

        NetworkService.shared.currentAccountSession = "XN0YXJ0-95c5ddab-3ea6-4c30-981c-e09889abf2ag-WVuZA"
        NetworkService.shared.domainSettingMap = ["gateway": ["https://internal-api-lark-api.feishu.cn/im/gateway/"]]
        NetworkService.shared.currentEnvType = .release

        let config = TTNetInitializor.Configuration(appName: "Lark",
                                                    userAgent: """
                                                        Mozilla/5.0 (iPhone; CPU iPhone OS 14_4 like Mac OS X)
                                                        AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.4
                                                        Mobile/15E148 Safari/604.1 Lark/3.46.0 LarkLocale/zh_CN
                                                        """,
                                                    deviceID: "4152205354470488",
                                                    session: "XN0YXJ0-95c5ddab-3ea6-4c30-981c-e09889abf2ag-WVuZA",
                                                    tenentID: "1",
                                                    envType: .release,
                                                    envUnit: "eu_nc",
                                                    certificateList: nil,
                                                    isLark: false,
                                                    appID: "1161")
        NetworkService.shared.setUpTTNet(with: config)
    }

//    func testHTTPPost() {
//        var adRequest = ExtensionPB_Ad_PullSplashADRequest()
//        adRequest.lastSplashAdID = 0
//
//        let expectation = XCTestExpectation(description: "test")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            NetworkService.shared.send(request: adRequest,
//                                command: .pullSplashAd,
//                                responseType: ExtensionPB_Ad_PullSplashADResponse.self) { (result) in
//                switch result {
//                case .success(let rep):
//                    guard let dict = try?JSONSerialization.jsonObject(with: rep.splash,
//                                                                      options: .mutableContainers) as? [String: Any],
//                          let config = dict["data"] as? [String: Any] else {
//                        XCTAssert(true)
//                        return
//                    }
//
//                    XCTAssertEqual(config["splash_interval"] as? Int, 0)
//                    XCTAssertEqual(config["leave_interval"] as? Int, 0)
//                    XCTAssertEqual(config["splash_load_interval"] as? Int, 0)
//                case .failure: XCTAssert(true)
//                }
//
//                expectation.fulfill()
//            }
//        }
//
//        wait(for: [expectation], timeout: 5)
//    }
}
