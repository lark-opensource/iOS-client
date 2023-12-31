//
//  PathOperatorsTests.swift
//  LarkFileKitDevEEUnitTest
//
//  Created by Supeng on 2020/10/10.
//

import Foundation
import XCTest
import LarkFileKit

class PathOperatorsTests: XCTestCase {
    var systemDocumentPath: String {
        NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }

    func testPathAddToPath() {
        var path1: Path = Path.documentsPath
        var path2: Path = "temp"
        var path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, systemDocumentPath + Path.separator + "temp")

        path1 = Path.documentsPath
        path2 = ""
        path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, systemDocumentPath)

        path1 = Path.documentsPath
        path2 = "."
        path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, systemDocumentPath)

        path1 = ""
        path2 = "temp"
        path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, "temp")

        path1 = "."
        path2 = "temp"
        path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, "temp")

        path1 = Path.documentsPath
        path2 = "/temp"
        path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, systemDocumentPath + Path.separator + "temp")

        path1 = "/temp1/"
        path2 = "/temp"
        path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, "/temp1/temp")

        path1 = "/temp1/"
        path1 += "/temp"
        XCTAssertEqual(path1.rawValue, "/temp1/temp")
    }

    func testAddStringToPath() {
        let path1: String = Path.documentsPath.rawValue
        let path2: Path = "temp"
        let path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, systemDocumentPath + Path.separator + "temp")
    }

    func testAddPathToString() {
        let path1: Path = Path.documentsPath
        let path2: String = "temp"
        let path3 = path1 + path2
        XCTAssertEqual(path3.rawValue, systemDocumentPath + Path.separator + "temp")
    }
}
