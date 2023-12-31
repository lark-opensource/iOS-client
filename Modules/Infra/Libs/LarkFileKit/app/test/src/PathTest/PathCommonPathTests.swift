//
//  PathCommonPathTests.swift
//  LarkFileKitDevEEUnitTest
//
//  Created by Supeng on 2020/11/4.
//

import Foundation
import XCTest
import LarkFileKit

class PathCommonPathTests: XCTestCase {
    func testCommonPath() {
        XCTAssert(Path.current.rawValue ==
                    FileManager.default.currentDirectoryPath)
        XCTAssert(Path.documentsPath.rawValue ==
                    NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        XCTAssert(Path.libraryPath.rawValue ==
                    NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0])
        XCTAssert(Path.cachePath.rawValue ==
                    NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0])
        XCTAssert(Path.userTemporary.rawValue ==
                    Path(NSTemporaryDirectory()).standardized.rawValue)
    }
}
