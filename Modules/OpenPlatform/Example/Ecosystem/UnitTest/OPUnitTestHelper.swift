//
//  OPUnitTestHelper.swift
//  Ecosystem
//
//  Created by baojianjun on 2023/2/10.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import Foundation

final class OPUnitTestHelper {
    class func isUnitTest() -> Bool {
        let result = ProcessInfo.processInfo.environment["IS_TESTING_OPEN_PLATFORM_SDK"]
        return result == "1"
    }
}
