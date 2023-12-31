//
//  PermissionExemptContextTests.swift
//  SKPermission-Unit-Tests
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
@testable import SKPermission
import SKFoundation
import SpaceInterface
import XCTest

final class PermissionExemptContextTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testContextForScenes() {
        let contexts = PermissionExemptContext.all
        PermissionExemptScene.allCases.forEach { scene in
            guard contexts[scene] != nil else {
                XCTFail("exempt context for scene: \(scene) not found")
                return
            }
            // 测一下强解会不会 crash
            _ = PermissionRequest(entity: .ccm(token: "MOCK_TOKEN", type: .docX),
                                  exemptScene: scene,
                                  extraInfo: PermissionExtraInfo())
        }
    }
}
