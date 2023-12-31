//
//  DriveGIFPreviewViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by tanyunpeng on 2023/4/5.
//  


import XCTest
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
@testable import SKDrive

final class DriveGIFPreviewViewModelTests: XCTestCase {
    let mockDelegate: MockDriveGIFRenderDelegate = MockDriveGIFRenderDelegate()
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    
    func testPraseContent() {
        let curBundle = Bundle(for: type(of: self))
        let url = fileURL(name: "damageGIF", ext: "gif")
        let sut = DriveGIFPreviewViewModel(fileURL: url)
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didRenderFailed = {
            expect.fulfill()
        }
        sut.loadContent()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    private func fileURL(name: String, ext: String) -> SKFilePath {
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: name, withExtension: ext) else {
            return SKFilePath(absPath: "/error/path")
        }
        return SKFilePath(absUrl: url)
    }
}

class MockDriveGIFRenderDelegate: DriveGIFRenderDelegate {
    var didRenderRichText: (() -> Void)?
    var didRenderFailed: (() -> Void)?
    func updateFrame(newFrame: UIImage) {
        didRenderRichText?()
    }
    
    func renderFailed() {
        didRenderFailed?()
    }
    
    func fileUnsupport(reason: SKDrive.DriveUnsupportPreviewType) {
        didRenderRichText?()
    }
    
    
}
