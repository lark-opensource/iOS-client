//
//  LarkCoreUnitTest.swift
//  LarkCoreUnitTest
//
//  Created by SuPeng on 2/27/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
import LarkCore
import Swinject

class LarkCoreUnitTest: XCTestCase {

    func testExample() {
        let id = InputUtil.randomId()
        assert(id < 100_000_000)

        let assembly = ImageAssembly()
        assembly.assemble(container: Container())
        assert(true)
    }
}
