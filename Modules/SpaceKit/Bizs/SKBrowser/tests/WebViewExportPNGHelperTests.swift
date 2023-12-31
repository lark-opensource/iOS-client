//
//  WebViewExportPNGHelperTests.swift
//  SpaceDemoTests
//
//  Created by chensi(陈思) on 2022/3/10.
//  Copyright © 2022 Bytedance. All rights reserved.


import XCTest
import WebKit
import SKFoundation
@testable import SKBrowser

class WebViewExportPNGHelperTests: XCTestCase {
    
    /// 被测对象
    var testObj: WebViewExportPNGHelper!
    
    var webview: WKWebView!
    
    /// 完成导出的异步预期
    var didFinishExport: XCTestExpectation!
    
    /// 预期的完整图片
    var originImage: UIImage!
    
    override func setUp() {
        super.setUp()
        try? setup()
    }

    override func tearDown() {
        super.tearDown()
        clear()
    }
    
    
    func testExportPNGImage() {
//        do {
//            try setup()
//        } catch {
//            XCTFail("setup failed")
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // 让loadHTMLString加载完成
//            self.webview.scrollView.contentSize = self.webview.bounds.size
//            self.testObj.exportPNGImage(webView: self.webview, fileName: "WebViewExportPNGHelperTest_output_")
//        }
//
//        // 最多等待秒数
//        waitForExpectations(timeout: 30) { (err: Error?) in
//            XCTAssertNil(err)
//            self.clear()
//        }
    }
    
    private func setup() throws {
//        testObj = WebViewExportPNGHelper(compressLevel: 3)
//        testObj.delegate = self
//
//        webview = WKWebView(frame: .init(x: 0, y: 0, width: 100, height: 200))
//
//        let path = Bundle(for: type(of: self)).path(forResource: "web_export_png_orgin", ofType: "html")!
//        let string = try String(contentsOfFile: path)
//        webview.loadHTMLString(string, baseURL: nil)
//
//        didFinishExport = self.expectation(description: "WebViewExportPNGHelper 未完成导出")
//
//        let img_path = Bundle(for: type(of: self)).path(forResource: "web_export_expected", ofType: "png")!
//        originImage = UIImage(contentsOfFile: img_path)
    }
    
    private func clear() {
//        testObj.cancel()
    }
    
    func testDealloc() {
        let newInstance = WebViewExportPNGHelper(compressLevel: 1, millisecondsPerPage: ._50)
        _ = newInstance
    }

    func testImageIsValid() {
        let obj = WebViewExportPNGHelper(compressLevel: 1, millisecondsPerPage: ._50)
        let result = obj.imageIsValid(UIImage())
        XCTAssert(result.0 == true)
    }
}

private extension WebViewExportPNGHelperTests {
    
    func checkFinishResult(isFinished: Bool, imagePath: SKFilePath) {
        
        debugPrint("imagePath:\(imagePath)")
        
        guard let outImage = try? UIImage.read(from: imagePath) else {
            XCTFail("output image is nil: \(imagePath)")
            return
        }
        guard let outImageData = outImage.pngData() else {
            XCTFail("output image Data is nil: \(imagePath)")
            return
        }
        
        let originData = originImage.pngData()
        
        // TODO: chensi.123 处理一下
//        if isFinished, outImageData == originData {
//            didFinishExport.fulfill()
//        } else {
//            XCTFail("checkFinishResult fail: isFinished：\(isFinished)， outImageData：\(outImageData)")
//        }
    }
}

extension WebViewExportPNGHelperTests: WebViewExportPNGHelperDelegate {
    func helperDidFinishExport(_: SKBrowser.WebViewExportPNGHelper, isFinished: Bool, imagePath: SKFoundation.SKFilePath) {
        checkFinishResult(isFinished: isFinished, imagePath: imagePath)
    }
    
    
    func helperDidDrawImage(_: WebViewExportPNGHelper, context: CGContext, size: CGSize) {
        debugPrint("helperDidDrawImage: context:\(context), size:\(size)")
    }
    
    func exportFailed(_ helper: WebViewExportPNGHelper) {
        XCTFail("exportFailed")
    }
}
