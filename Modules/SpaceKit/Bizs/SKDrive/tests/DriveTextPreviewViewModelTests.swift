//
//  DriveTextPreviewViewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/9/25.
// swiftlint:disable weak_delegate type_body_length

import XCTest
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
@testable import SKDrive

final class DriveTextPreviewViewModelTests: XCTestCase {
    let mockDelegate: MockDriveTestRenderDelegate = MockDriveTestRenderDelegate()
    let bag = DisposeBag()
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }
    
    func testRenderRtfWithTextView() {
        let url = fileURL(name: "rtf-test-file", ext: "rtf")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didRenderRichText = {
            expect.fulfill()
        }
        
        sut.setup()
        sut.loadContent()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRenderCodeWithWebView() {
        let url = fileURL(name: "html_test_file", ext: "html")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didLoadHtmlString = {
            expect.fulfill()
        }
        
        sut.setup()
        sut.loadContent()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRenderLogWithTextView() {
        let url = fileURL(name: "test", ext: "log")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didRenderPlainText = {
            expect.fulfill()
        }
        
        sut.setup()
        sut.loadContent()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRenderLogWithPainTextFailed() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.log")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .plainText,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didRenderUnsupport = {
            expect.fulfill()
        }
        
        sut.loadContent()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRenderRenderUnsupportFile() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.png")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didRenderUnsupport = {
            expect.fulfill()
        }
        
        sut.setup()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRenderRenderSizeTooBig() {
        let url = fileURL(name: "html_test_file", ext: "html")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            sizeLimited: 10,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didRenderUnsupport = {
            expect.fulfill()
        }
        
        sut.setup()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testRenderRenderFailed() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.txt")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didRenderFailed = {
            expect.fulfill()
        }
        
        sut.setup()
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testGetSecurityCopyDriver() {
        let url = fileURL(name: "html_test_file", ext: "html")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for caculate security copy result")
        sut.needSecurityCopyDriver.drive(onNext: { (token, canCopy) in
            XCTAssertFalse(canCopy)
            XCTAssertNil(token)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testGetCanCopyUpdated() {
        let url = fileURL(name: "html_test_file", ext: "html")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for caculate can copy result")
        sut.canCopyUpdated.drive(onNext: { canCopy in
            XCTAssertFalse(canCopy)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1) { error in
            XCTAssertNil(error)
        }
    }
    
    func testGetCanCopy() {
        let url = fileURL(name: "html_test_file", ext: "html")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let result = sut.canCopy
        XCTAssertFalse(result)
    }
    
    func testNeedCopyIntercept() {
        let url = fileURL(name: "html_test_file", ext: "html")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let result = sut.needCopyIntercept()
        XCTAssertTrue(result.needInterceptCopy)
    }
    
    // render mode 为plain text 的场景
    func testUpdateModeWtihRenderModePlainText() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.log")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .plainText,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        sut.updateMode(fileType: .log, fileSize: 1024)
        XCTAssertEqual(sut.renderMode, .plainText)
    }

    // render mode 为rich text, 实际文件类型不是richText, 降级为plainText
    func testUpdateModeRichTextDowngradeToPlainText() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.log")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .richText,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        sut.updateMode(fileType: .log, fileSize: 1024)
        XCTAssertEqual(sut.renderMode, .plainText)
    }
    
    
    // render mode 为rich text, 超出支持的文件大小降级为plainText
    func testUpdateModeRichTextOverSizeDowngradeToPlainText() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.rtf")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .richText,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        sut.updateMode(fileType: .rtf, fileSize: 2 * 1024 * 1024)
        XCTAssertEqual(sut.renderMode, .plainText)
    }
    
    // render 为markdown，实际类型为非md
    func testUpdateModeMarkDownToPlainText() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.md")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .markdown,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        sut.updateMode(fileType: .log, fileSize: 2 * 1024 * 1024)
        XCTAssertEqual(sut.renderMode, .plainText)
    }
    
    // render 为markdown， 大小超出限制降级为plainText
    func testUpdateModeMarkDownOverSizeDowngradeToPlainText() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.md")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .markdown,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        sut.updateMode(fileType: .md, fileSize: 2 * 1024 * 1024)
        XCTAssertEqual(sut.renderMode, .plainText)
    }
    
    // render 为code，实际类型为非code
    func testUpdateModeCodeToPlainText() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.log")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .code,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        sut.updateMode(fileType: .log, fileSize: 2 * 1024 * 1024)
        XCTAssertEqual(sut.renderMode, .plainText)
    }
    
    // render 为markdown， 大小超出限制降级为plainText
    func testUpdateModeCodeOverSizeDowngradeToPlainText() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.swift")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .code,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        sut.updateMode(fileType: .swift, fileSize: 2 * 1024 * 1024)
        XCTAssertEqual(sut.renderMode, .plainText)
    }
    
    // render 为auto， 实际文件类型为mardown
    func testUpdateModeAutoWithFileTypeMardownMode() {
        let url = SKFilePath.driveLibraryDir.appendingRelativePath("test").appendingRelativePath("file.md")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            preferedRenderMode: .auto,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        sut.updateMode(fileType: .md, fileSize: 1024)
        XCTAssertEqual(sut.renderMode, .markdown)
    }
    
    func testLoadWebContent() {
        let url = fileURL(name: "html_test_file", ext: "html")
        let canEdit = BehaviorRelay<Bool>(value: false)
        let canCopy = BehaviorRelay<Bool>(value: false)
        let sut = DriveTextPreviewViewModel(fileURL: url,
                                            token: nil,
                                            hostToken: nil,
                                            canEdit: canEdit,
                                            canCopy: canCopy,
                                            enableCopySecurity: true,
                                            copyMananger: DriveCopyMananger(permissionService: MockUserPermissionService()))
        let expect = expectation(description: "wait for render")
        sut.renderDelegate = self.mockDelegate
        self.mockDelegate.didWebRenderSuccess = {
            expect.fulfill()
        }
        sut.setup()
        sut.loadWebContent()
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


class MockDriveTestRenderDelegate: DriveTextRenderDelegate {
    var didRenderPlainText: (() -> Void)?
    var didLoadHtmlString: (() -> Void)?
    var didRenderFailed: (() -> Void)?
    var didRenderUnsupport: (() -> Void)?
    var didRenderRichText: (() -> Void)?
    var didWebRenderSuccess: (() -> Void)?

    func renderPlainText(content: String) {
        didRenderPlainText?()
    }
    func renderRichText(content: NSAttributedString) {
        didRenderRichText?()
    }

    func loadHTMLFileURL(_: URL, baseURL: URL) {
        didLoadHtmlString?()
    }
    func evaluateJavaScript(_: String, completionHandler: ((Any?, Error?) -> Void)?) {
        completionHandler?(nil, nil)
    }
    func webViewRenderSuccess() {
        didWebRenderSuccess?()
    }

    func renderFailed() {
        didRenderFailed?()
    }
    func fileUnsupport(reason: DriveUnsupportPreviewType) {
        didRenderUnsupport?()
    }
}
