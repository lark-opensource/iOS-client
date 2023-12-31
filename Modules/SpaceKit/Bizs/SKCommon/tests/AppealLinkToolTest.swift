//
//  AppealLinkToolTest.swift
//  SKCommon-Unit-Tests
//
//  Created by peilongfei on 2023/10/25.
//  


import Foundation
import XCTest
@testable import SKCommon
import SKUIKit

class AppealLinkToolTest: XCTestCase {
    
    func testAppealLinkText() {
        let entityId = "MOCK_ENTITY_ID"
        let testState: [ComplaintState] = [.machineVerify, .reachVerifyLimitOfAll, .reachVerifyLimitOfDay, .verifyFailed, .verifying]
        testState.forEach { state in
            let linkTexts = AppealLinkTool.appealLinkText(state: state, entityId: entityId)
            XCTAssertTrue(linkTexts.count > 0)
            linkTexts.forEach { text, link in
                XCTAssertNotNil(text)
                //let url = URL(string: link)
                //XCTAssertNotNil(url)
            }
        }

        //let link = AppealLinkTool.reportLink(token: "MOCK_TOKEN", type: .docX)
        //XCTAssertNotNil(link)
    }
}
