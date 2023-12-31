//
//  DriveSubModuleManagerTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/4/28.
//

import XCTest
import SKFoundation

@testable import SKDrive

class DriveSubModuleManagerTests: XCTestCase {
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }

    func testRegisterSubModulesAttach() {
        let hostModule = MockHostModule()
        let driveSubModuleManagerModule = DriveSubModuleManager()
        driveSubModuleManagerModule.registerSubModules(secne: .attach, hostModule: hostModule)
        XCTAssertEqual(driveSubModuleManagerModule.count(), 1)
    }

    func testRegisterSubModulesSpace() {
        let hostModule = MockHostModule()
        let driveSubModuleManagerModule = DriveSubModuleManager()
        driveSubModuleManagerModule.registerSubModules(secne: .space, hostModule: hostModule)
        XCTAssertEqual(driveSubModuleManagerModule.count(), 19)
    }

    func testRegisterSubModulesSpaceUnRegist() {
        let hostModule = MockHostModule()
        let driveSubModuleManagerModule = DriveSubModuleManager()
        driveSubModuleManagerModule.registerSubModules(secne: .space, hostModule: hostModule)
        driveSubModuleManagerModule.unRegist()
        XCTAssertEqual(driveSubModuleManagerModule.count(), 0)
    }

}
