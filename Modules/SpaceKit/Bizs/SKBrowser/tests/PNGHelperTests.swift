//
//  PNGHelperTests.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/3.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
import SKFoundation
@testable import SKBrowser

class PNGHelperTests: XCTestCase {
    
    /// 被测对象
    var testObj: PNGHelper!
    
    /// 原始图片路径
    let inputPath = ""
    /// 原始图片
    var inputImage: UIImage!
    
    
    
    /// 预期输出图片尺寸
    var expectSize: CGSize { inputImage.size }
    
    func testInitialize() {
        testObj = PNGHelper()
        let fileName = UUID().uuidString
        _ = testObj.initialize(width: 100, height: 100, compressLevel: 5, fileName: fileName)
        
        testObj = PNGHelper()
        _ = testObj.initialize(width: 100, height: 100, compressLevel: 5, fileName: nil)
    }
    
    func testOpenFile() {
        testObj = PNGHelper()
        let fileName = UUID().uuidString
        _ = testObj.initialize(width: 100, height: 100, compressLevel: 5, fileName: fileName)
        
        let path = SKFilePath.globalSandboxWithTemporary.appendingRelativePath("pngHelper_test")
        _ = testObj.openFile(path: path)
    }
    
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        testObj = PNGHelper()
//        inputImage = UIImage(contentsOfFile: inputPath)
//    }
//
//    override func tearDown() {
//        super.tearDown()
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//    // TODO: chensi crash
//
//    func testInitialize() throws {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//        
//        // 预期生成一张UIImage
//        let result = testObj.initialize(width: UInt32(expectSize.width),
//                                        height: UInt32(expectSize.height),
//                                        compressLevel: 3,
//                                        fileName: "PNGHelperTest")
//        XCTAssert(result == true)
//        
//        let path = testObj.filePath
//        XCTAssert(path.isEmpty == false)
//    }
//    
//    func testOpenFile() throws {
//        
//        let path = testObj.filePath
//        let openResult = testObj.openFile(path: path)
//        XCTAssert(openResult == true)
//    }
//    
//    func testGetFileSize() throws {
//        
//        let size = testObj.getFileSize()
//        XCTAssert(size > 0)
//    }
//    
//    func testReadIHDR() throws {
//        
//        let path = testObj.filePath
//        let size = testObj.readIHDR(path)
//        XCTAssert(size == expectSize)
//    }
//    
//    func testWriteRow() throws {
//        
//        guard let originBuffer = inputImage.wk.scaleAndGetPixels(shouldDoDecorate: { _ in false }) else {
//            throw NSError(domain: "\(Self.self)", code: -1, userInfo: [NSLocalizedDescriptionKey: "scaleAndGetPixels failed"])
//        }
//        
//        let bitsPerRow = Int(expectSize.width * 4)
//        let lines = Int(expectSize.height) // 总行数
//        for i in 0 ..< lines {
//            let offsetBuffer = originBuffer.advanced(by: bitsPerRow * i)
//            testObj.writeRow(offsetBuffer)
//        }
//        testObj.flush()
//        
//        let inputData = try NSData(contentsOfFile: inputPath) as Data
//        let outputData = try NSData(contentsOfFile: testObj.filePath) as Data
//        XCTAssert(inputData == outputData)
//    }
//    
//    func testFreeCache() throws {
//        // 需要改造
//    }
//    
//    
//    
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
