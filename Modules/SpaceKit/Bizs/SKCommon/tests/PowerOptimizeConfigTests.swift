//
//  PowerOptimizeConfigTests.swift
//  SKCommon-Unit-Tests
//
//  Created by ByteDance on 2023/12/5.
//

import XCTest
@testable import SKCommon
import SKFoundation
import LarkContainer

final class PowerOptimizeConfigTests: XCTestCase {

    var powerOptimizeConfigImpl: PowerOptimizeConfigImpl?
    
    override func setUp() {
        super.setUp()
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)
        powerOptimizeConfigImpl = PowerOptimizeConfigImpl(userResolver: userResolver)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testValues() {
        _ = powerOptimizeConfigImpl?.evaluateJSOptEnable
        _ = powerOptimizeConfigImpl?.evaluateJSOptList
        _ = powerOptimizeConfigImpl?.dateFormatOptEnable
        _ = powerOptimizeConfigImpl?.fePkgFilePathsMapOptEnable
    }
}
