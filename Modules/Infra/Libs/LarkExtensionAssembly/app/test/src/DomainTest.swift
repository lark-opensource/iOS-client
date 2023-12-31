//
//  DomainTest.swift
//  LarkExtensionAssemblyDevEEUnitTest
//
//  Created by 王元洵 on 2021/4/19.
//

import Foundation
import XCTest
@testable import LarkExtensionAssembly
@testable import LarkExtensionServices
import ExtensionPB
import SwiftProtobuf

class SaveDomainTest: XCTestCase {
    override func setUp() {
        super.setUp()

        NetworkService.shared.currentAccountSession = "XN0YXJ0-95c5ddab-3ea6-4c30-981c-e09889abf2ag-WVuZA"
    }

    func testSaveDomain() {
        ExtensionDomain.writeDomain(with: [.api: ["internal-api-lark-api.feishu.cn"]])

        var adRequest = ExtensionPB_Ad_PullSplashADRequest()
        adRequest.lastSplashAdID = 0

        let expectation = XCTestExpectation(description: "test")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NetworkService.shared.send(request: adRequest,
                                command: .pullSplashAd,
                                responseType: ExtensionPB_Ad_PullSplashADResponse.self) { (result) in
                switch result {
                case .success(let rep):
                    guard let dict = try?JSONSerialization.jsonObject(with: rep.splash,
                                                                      options: .mutableContainers) as? [String: Any],
                          let config = dict["data"] as? [String: Any] else {
                        XCTAssert(true)
                        return
                    }

                    XCTAssertEqual(config["splash_interval"] as? Int, 0)
                    XCTAssertEqual(config["leave_interval"] as? Int, 0)
                    XCTAssertEqual(config["splash_load_interval"] as? Int, 0)
                case .failure: XCTAssert(true)
                }

                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }
}
