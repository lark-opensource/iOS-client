//
//  PathEnumerateTests.swift
//  LarkFileKitDevEEUnitTest
//
//  Created by Supeng on 2020/10/10.
//

import Foundation
import XCTest
import LarkFileKit

class PathEnumerateTests: XCTestCase {

    var rootDir: Path!
    var dir1: Path!
    var dir2: Path!
    var file1: Path!
    var file2: Path!
    var file3: Path!
    var file4: Path!

    override func setUp() {
        super.setUp()
        do {
            rootDir = Path.userTemporary + "Root"
            try rootDir.createDirectory()

            dir1 = rootDir + "dir1"
            try dir1.createDirectory()

            file1 = dir1 + "file1"
            try file1.touch()

            file2 = dir1 + "file2"
            try file2.touch()

            dir2 = rootDir + "dir2"
            try dir2.createDirectory()

            file3 = dir1 + "file3"
            try file3.touch()

            file4 = dir1 + "file4"
            try file4.touch()
        } catch {
            XCTFail("\(error)")
        }
    }

    override func tearDown() {
        try? rootDir.deleteFile()
        super.tearDown()
    }

    func testSequence() throws {
        let pathes = Set(rootDir.map { $0 })
        XCTAssertEqual(pathes, Set([dir1, dir2, file1, file2, file3, file4]))
    }

    func testChildren() {
        var chidren = Set(rootDir.children(recursive: false))
        XCTAssertEqual(chidren, Set([dir1, dir2]))

        chidren = Set(rootDir.children(recursive: true))
        XCTAssertEqual(chidren, Set([dir1, dir2, file1, file2, file3, file4]))

        XCTAssertTrue(Path("awefawejfawjefoajwefojawef").children().isEmpty)
    }
}
