//
//  PathBaseTest.swift
//  LarkFileKitDevEEUnitTest
//
//  Created by Supeng on 2020/10/12.
//

import Foundation
import XCTest
@testable import LarkFileKit

class PathBaseTest: XCTestCase {

    func testSafeRawValue() throws {
        let path: Path = ""
        XCTAssertEqual(path.safeRawValue, ".")
    }

    class Delegate: NSObject, FileManagerDelegate {
        var expectedSourcePath: Path = ""
        var expectedDestinationPath: Path = ""
        func fileManager(
            _ fileManager: FileManager,
            shouldCopyItemAtPath srcPath: String,
            toPath dstPath: String
        ) -> Bool {
            XCTAssertEqual(srcPath, expectedSourcePath.rawValue)
            XCTAssertEqual(dstPath, expectedDestinationPath.rawValue)
            return true
        }
    }

    func testPathDelegate() throws {
        var sourcePath = Path.userTemporary + "filekit_test_filemanager_delegate"
        let destinationPath = Path("\(sourcePath)1")
        try sourcePath.createFile()

        var delegate: Delegate {
            let delegate = Delegate()
            delegate.expectedSourcePath = sourcePath
            delegate.expectedDestinationPath = destinationPath
            return delegate
        }

        let d1 = delegate
        sourcePath.fileManagerDelegate = d1
        XCTAssertTrue(d1 === sourcePath.fileManagerDelegate)

        try sourcePath.forceCopyFile(to: destinationPath)

        var secondSourcePath = sourcePath
        secondSourcePath.fileManagerDelegate = delegate
        XCTAssertFalse(sourcePath.fileManagerDelegate === secondSourcePath.fileManagerDelegate)
        try secondSourcePath.forceCopyFile(to: destinationPath)
    }
}
