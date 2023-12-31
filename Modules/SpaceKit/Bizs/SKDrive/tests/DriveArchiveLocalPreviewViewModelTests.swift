//
//  DriveArchiveLocalPreviewViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by ByteDance on 2023/3/3.
//

import XCTest
import SKFoundation
@testable import SKDrive

final class DriveArchiveLocalPreviewViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testInitailize() {
        let sut = createSut(url: SKFilePath(absPath: "/test/path.zip"), fileName: "path.zip")
        XCTAssertNotNil(sut)
        XCTAssert(sut.rootNodeName == "path")
    }
    
    func testStartPreview() {
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: "test", withExtension: "zip") else {
            XCTFail("test resource not found")
            return
        }
        let path = SKFilePath(absUrl: url)
        let expect = expectation(description: "wait for parse result")
        expect.expectedFulfillmentCount = 5
        let sut = createSut(url: path, fileName: "test.zip")
        var actions = [DriveArchivePreviewAction]()
        var rootNode: DriveArchiveFolderNode?
        sut.actionHandler = { action in
            if case let DriveArchivePreviewAction.updateRootNode(node) = action {
                rootNode = node
            }
            actions.append(action)
            if actions.count == 3, let rootNode = rootNode {
                sut.didClick(node: rootNode.childNodes[0])
            }
            print("testStartPreview action \(action)")
            expect.fulfill()
        }
        sut.startPreview()
        waitForExpectations(timeout: 10)
        XCTAssertTrue(actions.count == 5)
        if case DriveArchivePreviewAction.openFile(_) = actions[3] {
            XCTAssert(true)
        } else {
            XCTFail()
        }
    }
    
    private func createSut(url: SKFilePath, fileName: String) -> DriveArchiveLocalPreviewViewModel {
        let sut = DriveArchiveLocalPreviewViewModel(url: url, fileName: fileName, previewFrom: .docsList, additionalStatisticParameters: nil)
        return sut
    }
}
