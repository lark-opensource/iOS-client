//
//  FilesystemBaseTests.swift
//  OPCorePlugin-Unit-Tests
//
//  Created by ByteDance on 2023/6/15.
//

import XCTest
import OPUnitTestFoundation
@testable import LarkSetting

@available(iOS 13.0, *)
class FilesystemBaseTests: XCTestCase {
    var testUtils = OpenPluginGadgetTestUtils()
    private var originLarkStorageFG: Bool?

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        //mock fg & settings
        originLarkStorageFG =  FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: FileSettings.Key.larkStorageEnable))
        FeatureGatingStorage.updateDebugFeatureGating(fg: FileSettings.Key.larkStorageEnable, isEnable: true, id: "")
        
        testUtils.prepareGadgetSandboxPath(pkgName: "testPkg")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        if let originLarkStorageFG {
            FeatureGatingStorage.updateDebugFeatureGating(fg: FileSettings.Key.larkStorageEnable, isEnable: originLarkStorageFG, id: "")
        }
        originLarkStorageFG = nil
    }

}
