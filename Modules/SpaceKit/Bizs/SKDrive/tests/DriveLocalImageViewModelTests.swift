//
//  DriveLocalImageViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by ByteDance on 2023/3/2.
//

import XCTest
import SKFoundation
import RxSwift
import RxCocoa
@testable import SKDrive

final class DriveLocalImageViewModelTests: XCTestCase {
    private var bag = DisposeBag()
    override func setUp() {
        bag = DisposeBag()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testInitailize() {
        let sut = DriveLocalImageViewModel(url: SKFilePath(absPath: "/test/path.jpg"))
        XCTAssertNotNil(sut)
    }
    
    func testIsLineImage() {
        let sut = DriveLocalImageViewModel(url: SKFilePath(absPath: "/test/path.jpg"))
        XCTAssertFalse(sut.isLineImage)
    }
    
    func teztImageSourceResult() {
        let sut = DriveLocalImageViewModel(url: SKFilePath(absPath: "/test/path.jpg"))
        let expect = expectation(description: "wait for source")
        var result: DriveImagePreviewResult = .failed
        sut.imageSource.drive(onNext: { r in
            result = r
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 1.0)
        if case DriveImagePreviewResult.local(_) = result {
            XCTAssert(true)
        } else {
            XCTFail()
        }
    }
}
