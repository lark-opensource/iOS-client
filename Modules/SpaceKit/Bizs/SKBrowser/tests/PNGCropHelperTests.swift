////
////  PNGCropHelperTests.swift
////  SpaceDemoTests
////
////  Created by chensi(陈思) on 2022/3/7.
////  Copyright © 2022 Bytedance. All rights reserved.
//
//
//import XCTest
//@testable import SKBrowser
//
//class PNGCropHelperTests: XCTestCase {
//
//    /// 被测对象
//    var testObj: PNGCropHelper!
//
//    /// 完成裁剪的异步预期
//    var didFinishCrop: XCTestExpectation!
//
//    /// 原始png路径
//    var originPath = "" // 原始图片尺寸: 宽20 * 高100，高度分为5等分
//
//    /// 高度等分的序号数组
//    let indices = [0, 1, 2, 3, 4]
//
//    /// 每次测试cropImage方法，选取的随机序号
//    var randomIndex = 0
//
//    override func setUp() {
//        super.setUp()
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        testObj = PNGCropHelper(20) // 每次切分像素行数
//        testObj.delegate = self
//
//        didFinishCrop = self.expectation(description: "PNGCropHelper 未完成裁剪")
//
//        let path = Bundle(for: type(of: self)).path(forResource: "PNGCrop_origin", ofType: "png")!
//        originPath = path
//    }
//    override func tearDown() {
//        super.tearDown()
//        testObj.cancel()
//        testObj.clearResources()
//    }
//
//    func testGetImage() {
////
////        randomIndex = indices.randomElement()!
////
////        // 先执行裁剪
////        testObj.cropImage(originPath)
////
////        // 最多等待秒数
////        waitForExpectations(timeout: 30) { (err: Error?) in
////            XCTAssertNil(err)
////        }
//    }
//}
//
//private extension PNGCropHelperTests {
//
//    func checkFinishResult() {
//        let firstImage = testObj.getImage(x: 0, y: UInt32(indices.first!))
//        let lastImage = testObj.getImage(x: 0, y: UInt32(indices.last!))
//        let randomImage = testObj.getImage(x: 0, y: UInt32(randomIndex))
//        let firstImageData = firstImage?.pngData()
//        let lastImageData = lastImage?.pngData()
//        let randomImageData = randomImage?.pngData()
//
//        let originFirstImage = UIImage.namedInThisBundle("PNGCrop_origin_0", "png")
//        let originLastImage = UIImage.namedInThisBundle("PNGCrop_origin_4", "png")
//        let originRandomImage = UIImage.namedInThisBundle("PNGCrop_origin_\(randomIndex)", "png")
//        let originFirstImageData = originFirstImage?.pngData()
//        let originLastImageData = originLastImage?.pngData()
//        let originRandomImageData = originRandomImage?.pngData()
//        // TODO: chensi fixit
////        XCTAssert(firstImageData == originFirstImageData)
////        XCTAssert(lastImageData == originLastImageData)
////        XCTAssert(randomImageData == originRandomImageData)
//    }
//}
//
//extension PNGCropHelperTests: PNGCropHelperDelegate {
//
//    func didFinishCropImage(_ helper: PNGCropHelper) {
//        didFinishCrop.fulfill()
//        checkFinishResult()
//    }
//
//    func didGenerateOneImage(_ helper: PNGCropHelper, _ y: Int32) {
//        debugPrint("\(Self.self): didGenerateOneImage")
//    }
//
//    func didCancelled(_ helper: PNGCropHelper) {
//        debugPrint("\(Self.self): didCancelled")
//    }
//
//    func cropFailed(_ helper: PNGCropHelper) {
//        debugPrint("\(Self.self): cropFailed")
//        XCTFail("\(Self.self): cropFailed")
//    }
//}
//
//extension UIImage {
//
//    private class Class {}
//
//    class func namedInThisBundle(_ name: String, _ ext: String) -> UIImage? {
//        let bundle = Bundle(for: Class.self)
//        let path = bundle.path(forResource: name, ofType: ext) ?? ""
//        let image = UIImage(contentsOfFile: path)
//        return image
//    }
//}
