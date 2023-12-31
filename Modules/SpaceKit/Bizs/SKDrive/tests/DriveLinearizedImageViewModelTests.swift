//
//  DriveLinearizedImageViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by ByteDance on 2023/3/2.
//

import XCTest
import RxSwift
import RxCocoa
import SKFoundation
@testable import SKDrive

final class DriveLinearizedImageViewModelTests: XCTestCase {
    private var bag = DisposeBag()
    override func setUp() {
        bag = DisposeBag()
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDownloadImageSuccess() {
        let downloader = ImageDownloaderStub()
        downloader.success = true
        let sut = DriveLinearizedImageViewModel(downloader: downloader)
        var event = [DriveImagePreviewResult]()
        let expect = expectation(description: "wait for result")
        expect.expectedFulfillmentCount = 2
        sut.imageSource.drive(onNext: { result in
            event.append(result)
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 1.0)
        guard let first = event.first else {
            XCTFail("no event")
            return
        }
        if case DriveImagePreviewResult.linearized(_) = first , case DriveImagePreviewResult.local(_) = event[1] {
            XCTAssert(true)
        } else {
            XCTFail()
        }
    }
    
    func testDownloadImageFailed() {
        let downloader = ImageDownloaderStub()
        downloader.success = false
        let sut = DriveLinearizedImageViewModel(downloader: downloader)
        var event = [DriveImagePreviewResult]()
        let expect = expectation(description: "wait for result")
        expect.expectedFulfillmentCount = 1
        sut.imageSource.drive(onNext: { result in
            event.append(result)
            expect.fulfill()
        }).disposed(by: bag)
        
        waitForExpectations(timeout: 1.0)
        if case DriveImagePreviewResult.failed = event[0] {
            XCTAssert(true)
        } else {
            XCTFail()
        }
    }

    func testSetHostContainer() {
        let downloader = ImageDownloaderStub()
        let sut = DriveLinearizedImageViewModel(downloader: downloader)
        let hostVC = UIViewController()
        sut.hostContainer = hostVC
        XCTAssertNotNil(downloader.hostContainer)
    }
    
    func testForbidDownload() {
        let downloader = ImageDownloaderStub()
        let sut = DriveLinearizedImageViewModel(downloader: downloader)
        let expect = expectation(description: "wait for result")
        var isForbided = false
        sut.forbidDownload.drive(onNext: {
            isForbided = true
            expect.fulfill()
        }).disposed(by: bag)
        sut.imageSource.drive().disposed(by: bag)
        downloader.forbidDownload?()
        waitForExpectations(timeout: 1.0)
        XCTAssert(isForbided)
    }
    
    func testIsLineImage() {
        let downloader = ImageDownloaderStub()
        let sut = DriveLinearizedImageViewModel(downloader: downloader)
        XCTAssert(sut.isLineImage)
    }

}


class ImageDownloaderStub: DriveImageLinearizedDownloader {
    typealias ImageResult = DriveImageDownloader.ImageResult
    var downloadStream: Driver<ImageResult> {
        return downloadStreamOutput.asDriver(onErrorJustReturn: .failure(NSError() as Error))
    }
    var forbidDownload: (() -> Void)?
    var hostContainer: UIViewController?
    var success: Bool = true
    private let downloadStreamOutput = PublishRelay<ImageResult>()
    func downloadLinearizedImage() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1, execute:  {
            if self.success {
                self.downloadStreamOutput.accept(.success((UIImage(), nil)))
                self.downloadStreamOutput.accept(.success((nil, SKFilePath(absPath: "/test/path.pdf"))))
            } else {
                self.downloadStreamOutput.accept(.failure(NSError() as Error))
            }
        })
    }
    func suspend() {
        
    }
    func resume() {
        
    }
}

