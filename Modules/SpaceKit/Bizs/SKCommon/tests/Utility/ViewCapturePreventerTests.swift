//
//  ViewCapturePreventerTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by chensi(陈思) on 2022/4/1.
//  


import XCTest
@testable import SKCommon

class ViewCapturePreventerTests: XCTestCase {
    
    // 防截图关闭(允许截图)时，预期图片
    private var expectedAllowImageData: Data?
    // 防截图打开(禁止截图)时，预期图片
    private var expectedNotAllowImage: Data?
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let bundle = Bundle(for: type(of: self))
        if let path = bundle.path(forResource: "capture_prevent_isallow", ofType: "pngdata") {
            expectedAllowImageData = try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        
        if let path = bundle.path(forResource: "capture_prevent_notallow", ofType: "pngdata") {
            expectedNotAllowImage = try? Data(contentsOf: URL(fileURLWithPath: path))
        }
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPreventerValid() {
        
        let testObj = ViewCapturePreventer()
        
        // 防截图视图(带有背景色)放在一个容器视图(带有背景色)上，
        //  当防截图开启时，调用容器视图的drawHierarchy方法，防截图视图会呈透明状态；
        //  当防截图关闭时，调用容器视图的drawHierarchy方法，防截图视图会呈正常有颜色；
        
        let bgView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        bgView.backgroundColor = .blue
        
        testObj.contentView.frame = .init(x: 10, y: 10, width: 10, height: 10)
        testObj.contentView.backgroundColor = .yellow
        
        bgView.addSubview(testObj.contentView)
        
        // 测试允许截图
        testObj.isCaptureAllowed = true
        // TODO: chensi fixit
//        if let image = bgView.drawHierarchyImage(), let data = expectedAllowImageData {
//            XCTAssert(image.pngData() == data)
//        }
        
        // 测试不允许截图
        testObj.isCaptureAllowed = false
        // TODO: chensi fixit
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
//            if let image = bgView.drawHierarchyImage(), let data = self.expectedNotAllowImage {
//                XCTAssert(image.pngData() == data)
//            }
//        })
    }
    
    func testToastShown() {
        
        var toastHasBeenShowed = false
        
        let testObj = ViewCapturePreventer()
        testObj.isCaptureAllowed = false
        testObj.setShowToastCallback({
            toastHasBeenShowed = true
        })
        
        testObj.triggerSnapshot()
        // TODO: chensi fixit
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            XCTAssertTrue(toastHasBeenShowed)
//        }
    }
    
    func testReportToastEvent() {
        
        let testObj = ViewCapturePreventer()
        
        let fileIdKey = "file_id"
        let fileTypeKey = "file_type"
        
        let testFileId = "mock_fileId"
        let testFileType = "mock_fileType"
        let result = testObj.reportToast(fileId: testFileId, fileType: testFileType) as? [String: String]
        let expect: [String: String] = [fileIdKey: testFileId, fileTypeKey: testFileType]
        
        XCTAssertEqual(result?[fileIdKey], expect[fileIdKey])
        XCTAssertEqual(result?[fileTypeKey], expect[fileTypeKey])
    }
    
    func testFG() {
        
        var testObj = ViewCapturePreventer(FGService: { true }, settingService: { true })
        if let textField = testObj.getAssociatedTextField() {
            let internalView = testObj.contentView
            XCTAssert(internalView === textField.subviews.first)
        } else {
            XCTFail("can not get AssociatedTextField when FG is TRUE")
        }
        
        testObj = .init(FGService: { false }, settingService: { true })
        if let textField = testObj.getAssociatedTextField() {
            let internalView = testObj.contentView
            XCTAssert(internalView !== textField.subviews.first)
        } else {
            // 符合预期
        }
    }
    
    func testSetting() {
        
        var testObj = ViewCapturePreventer(FGService: { true }, settingService: { true })
        if let textField = testObj.getAssociatedTextField() {
            let internalView = testObj.contentView
            XCTAssert(internalView === textField.subviews.first)
        } else {
            XCTFail("can not get AssociatedTextField when setting is Open, system version:\(UIDevice.current.systemVersion)")
        }
        
        testObj = .init(FGService: { true }, settingService: { false })
        if let textField = testObj.getAssociatedTextField() {
            let internalView = testObj.contentView
            XCTAssert(internalView !== textField.subviews.first)
        } else {
            // 符合预期
        }
    }
}

private extension UIView {
    
    func drawHierarchyImage() -> UIImage? {
        var renderSize = bounds.size
        if renderSize.width == 0 { renderSize.width = 1 }
        if renderSize.height == 0 { renderSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(renderSize, isOpaque, 2)
        drawHierarchy(in: frame, afterScreenUpdates: true)
        if let image = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return image
        }
        return nil
    }
}
