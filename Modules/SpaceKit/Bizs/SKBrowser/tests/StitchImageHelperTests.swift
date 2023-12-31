////
////  StitchImageHelperTests.swift
////  SpaceDemoTests
////
////  Created by chensi(陈思) on 2022/3/8.
////  Copyright © 2022 Bytedance. All rights reserved.
//
//
//import XCTest
//@testable import SKBrowser
//
//class StitchImageHelperTests: XCTestCase {
//    
//    /// 被测对象
//    var testObj: StitchImageHelper! // 逻辑：从左向右，按列拼接
//    
//    /// 完成拼接的异步预期
//    var didFinishStitch: XCTestExpectation!
//    
//    /// 待拼接的原始png路径
//    var originPaths = [String]()
//    
//    /// 预期的完整图片
//    var originFullImage: UIImage!
//    
//    let fullImageSize = CGSize(width: 100, height: 20)
//    let singleImageSize = CGSize(width: 20, height: 20)
//    let singleImageCount = 5
//    
//    override func setUp() {
//        super.setUp()
//        setup()
//    }
//
//    override func tearDown() {
//        super.tearDown()
//        clear()
//    }
//    
//    func testCanReceiveImage() {
//        let canReceive = testObj.canReceiveImage()
//        XCTAssert(canReceive)
//    }
//    
//    func testReceiveImageInfo() {
//        
//        didFinishStitch = self.expectation(description: "StitchImageHelper 未完成拼接")
//        
//        for (i, path) in originPaths.enumerated() {
//            guard let image = UIImage(contentsOfFile: path) else {
//                XCTFail("origin single image is nil: \(path)")
//                return
//            }
//            guard let pixelPtr = image.wk.pixelData() else {
//                XCTFail("origin single image pixelPtr is nil: \(path)")
//                return
//            }
//            let imgInfo = ImageInfo(pixelPtr: pixelPtr,
//                                    width: UInt32(singleImageSize.width),
//                                    height: UInt32(singleImageSize.height),
//                                    isLastCol: i == originPaths.count - 1,
//                                    isFinish: i == originPaths.count - 1)
//            if testObj.canReceiveImage() {
//                testObj.receiveImageInfo(imgInfo)
//            }
//        }
//        
//        // 最多等待秒数
//        waitForExpectations(timeout: 30) { (err: Error?) in
//            XCTAssertNil(err)
//        }
//    }
//    
//    private func setup() {
//        testObj = StitchImageHelper(width: UInt32(fullImageSize.width),
//                                    height: UInt32(fullImageSize.height),
//                                    fileName: "StitchImageHelperTest_out_")
//        testObj.delegate = self
//        
//        originPaths = []
//        for i in 0 ..< singleImageCount {
//            let path = Bundle(for: type(of: self)).path(forResource: "StitchImage_origin_\(i)", ofType: "png")!
//            originPaths.append(path)
//        }
//        
//        let bundle = Bundle(for: type(of: self))
//        let path = bundle.path(forResource: "StitchImage_origin_full", ofType: "png") ?? ""
//        originFullImage = UIImage(contentsOfFile: path)
//    }
//    
//    private func clear() {
//        testObj.cancel()
//        testObj.freeCache()
//    }
//}
//
//private extension StitchImageHelperTests {
//    
//    func checkFinishResult() {
//        
//        let outPath = testObj.imageURL.path
//        
//        guard let outImage = UIImage(contentsOfFile: outPath) else {
//            XCTFail("output image is nil: \(outPath)")
//            return
//        }
//        guard let outImageData = outImage.pngData() else {
//            XCTFail("output image Data is nil: \(outPath)")
//            return
//        }
//        
//        let originData = originFullImage.pngData()
//        XCTAssert(outImageData == originData)
//    }
//}
//
//extension StitchImageHelperTests: StitchImageHelperDelegate {
//    
//    func stitchImageFinished(_ helper: StitchImageHelper) {
//        didFinishStitch.fulfill()
//        checkFinishResult()
//    }
//    
//    func receiveImagePause(_ helper: StitchImageHelper) {
//        debugPrint("\(Self.self): receiveImagePause")
//    }
//    
//    func receiveImageResume(_ helper: StitchImageHelper) {
//        debugPrint("\(Self.self): receiveImageResume")
//    }
//}
