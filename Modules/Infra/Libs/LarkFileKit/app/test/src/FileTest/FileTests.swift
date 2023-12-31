//
//  FileTests.swift
//  LarkFileKitDev
//
//  Created by Supeng on 2020/10/10.
//

import UIKit
import Foundation
import XCTest
@testable import LarkFileKit

class FileTests: XCTestCase {
    var dir: Path!
    var path: Path!

    class override func setUp() {
        super.setUp()
        FileTrackInfoHandlerRegistry.register(handler: handler)
    }

    class override func tearDown() {
        FileTrackInfoHandlerRegistry.handlers = []
        super.tearDown()
    }

    override func setUp() {
        super.setUp()
        do {
            dir = Path.userTemporary + "arrayFileTest"
            try? dir.deleteFile()

            path = dir + "temp.txt"
            try? path.deleteFile()

            try dir.createDirectory()
            try path.touch()
        } catch {
            XCTFail("\(error)")
        }
    }

    func testFile() {
        let arrayFile = ArrayFile<String>(path: path)
        XCTAssertEqual(arrayFile.fileSize, arrayFile.path.fileSize)
        XCTAssertTrue(true, "Get path attribute from File class success")
    }

    func testReadableWritableProtocol() throws {
        try [1, 2].write(to: path)
        let arr = try [Int](contentsOfPath: path)
        XCTAssertEqual(arr, [1, 2])
    }

    func testArrayFile() throws {
        let arrayFile = ArrayFile<String>(path: path)
        let array = ["ABCD", "WXYZ"]

        try arrayFile.write(array)
        XCTAssert(handler.trackInfos.last!.operation == .fileWrite)
        XCTAssert(handler.trackInfos.last!.size == arrayFile.fileSize!)

        let result = try arrayFile.read()
        XCTAssertEqual(array, result)

        let tempArrayFile1 = ArrayFile<String>(path: "random_path_afjewfjao")
        XCTAssertThrowsError(try tempArrayFile1.read())
        XCTAssertThrowsError(try tempArrayFile1.write(array))

        let arrayFile1 = ArrayFile<Int>(path: path)
        XCTAssertThrowsError(try arrayFile1.read())

        XCTAssert(handler.trackInfos.last!.operation == .fileRead)
        XCTAssert(handler.trackInfos.last!.size == arrayFile.fileSize!)
    }

    func testDataFile() throws {
        let dataFile = DataFile(path: path)
        let data = ("FileKit test" as NSString).data(using: String.Encoding.utf8.rawValue)!

        try dataFile.write(data)
        XCTAssert(handler.trackInfos.last!.operation == .fileWrite)
        XCTAssert(handler.trackInfos.last!.size == dataFile.fileSize!)

        let result = try dataFile.read()
        XCTAssertEqual(data, result)

        XCTAssert(handler.trackInfos.last!.operation == .fileRead)
        XCTAssert(handler.trackInfos.last!.size == dataFile.fileSize!)

        let result1 = try dataFile.read([.mappedIfSafe])
        XCTAssertEqual(data, result1)

        try dataFile.path.deleteFile()
        try dataFile.write(data, options: [.atomic])
        XCTAssertEqual(data, try dataFile.read())

        try path.deleteFile()
        try path.write("123".data(using: .utf8)!)
        XCTAssertEqual(try path.read(), "123".data(using: .utf8)!)

        //Read data from empty path
        let emptyPath: Path = "23u4r09q2urfoaj"
        XCTAssertThrowsError(try Data.read(from: emptyPath))
        XCTAssertThrowsError(try Data.read(from: emptyPath, options: [.alwaysMapped]))

        let illegalPath: Path = "12o3ij/a3orjfawo/roawjer/afaowef"
        XCTAssertThrowsError(try data.write(to: illegalPath, atomically: false))
        XCTAssertThrowsError(try data.write(to: illegalPath, options: []))
    }

    func testDictionaryFile() throws {
        let dicFile = DictionaryFile<String, String>(path: path)
        let dic = ["key": "value"]

        try dicFile.write(dic)
        XCTAssert(handler.trackInfos.last!.operation == .fileWrite)
        XCTAssert(handler.trackInfos.last!.size == dicFile.fileSize!)

        let result = try dicFile.read()
        XCTAssertEqual(dic, result)

        XCTAssert(handler.trackInfos.last!.operation == .fileRead)
        XCTAssert(handler.trackInfos.last!.size == dicFile.fileSize!)

        let tempDicFile1 = DictionaryFile<String, String>(path: "random_path_afjewfjao")
        XCTAssertThrowsError(try tempDicFile1.read())
        XCTAssertThrowsError(try tempDicFile1.write(dic))

        let dicFile1 = DictionaryFile<Int, Int>(path: path)
        XCTAssertThrowsError(try dicFile1.read())
    }

    func testImageFile() throws {
        let bundle = Bundle(for: FileTests.self)
        let image = UIImage(named: "Unknown", in: bundle, compatibleWith: nil)!
        XCTAssertNotNil(image)

        let imageFile = ImageFile(path: path)
        XCTAssertThrowsError(try imageFile.read())

        XCTAssertNoThrow(try imageFile.write(UIImage()))
        try imageFile.write(image)

        XCTAssert(handler.trackInfos.last!.operation == .fileWrite)
        XCTAssert(handler.trackInfos.last!.size == imageFile.fileSize!)

        let result = try imageFile.read()
        XCTAssertEqual(image.size, result.size)

        XCTAssert(handler.trackInfos.last!.operation == .fileRead)
        XCTAssert(handler.trackInfos.last!.size == imageFile.fileSize!)
    }

    func testTextFile() throws {
        let textFile = TextFile(path: path)
        try textFile.write("1234")

        XCTAssert(handler.trackInfos.last!.operation == .fileWrite)
        XCTAssert(handler.trackInfos.last!.size == textFile.fileSize!)

        let result = try textFile.read()
        XCTAssertEqual("1234", result)

        XCTAssert(handler.trackInfos.last!.operation == .fileRead)
        XCTAssert(handler.trackInfos.last!.size == textFile.fileSize!)

        let str = try String.read(from: path)
        XCTAssertEqual("1234", str)

        try "12345".write(to: path)
        XCTAssertEqual("12345", (try? String.read(from: path)) ?? "")
        XCTAssertEqual("12345", (try? textFile.read()))

        let textFile1 = TextFile(path: path, encoding: .ascii)
        try textFile1.write("1234")
        let result1 = try textFile1.read()
        XCTAssertEqual("1234", result1)

        XCTAssertThrowsError(try textFile1.write("哈哈"))

        let tempPath: Path = "empty_path_o2a3joifja"
        XCTAssertThrowsError(try String.read(from: tempPath))
        XCTAssertThrowsError(try "哈哈".write(to: tempPath))
    }
}
