//
//  DriveThumbImageViewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/8/24.
//

import XCTest
import SKCommon
import SpaceInterface
import RxSwift
import SKFoundation
@testable import SKDrive

class DriveThumbImageViewModelTests: XCTestCase {
    var bag = DisposeBag()
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testImageSourceWithImage() {
        let fileInfo = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()
        let sut = createSub(fileInfoReplay: fileInfo, downloader: downloader, retry: {}, previewType: .similarFiles, reachable: Observable<Bool>.just(true))
        let expect = expectation(description: "wait for image")
        sut.imageSource.drive(onNext: { image in
            XCTAssertNotNil(image)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testStartDownloadSimilarWhenSubscribe() {
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()

        let sut = createSub(fileInfoReplay: fileInfoReplay, downloader: downloader, retry: {}, previewType: .similarFiles, reachable: Observable<Bool>.just(true))
        let expect = expectation(description: "wait for image")
        expect.expectedFulfillmentCount = 2
        sut.imageSource.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        downloader.didDownloadSimilar = {
            print("state download similar")
            expect.fulfill()
        }
        fileInfoReplay.onNext(.success(fileInfo))
        fileInfoReplay.onNext(.success(fileInfo))
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testStartDownloadPreviewWhenSubscribe() {
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()

        let sut = createSub(fileInfoReplay: fileInfoReplay, downloader: downloader, retry: {}, previewType: .jpgLin, reachable: Observable<Bool>.just(true))
        let expect = expectation(description: "wait for image")
        expect.expectedFulfillmentCount = 2
        sut.imageSource.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        downloader.didDownloadPreview = {
            print("state download preview")
            expect.fulfill()
        }
        fileInfoReplay.onNext(.success(fileInfo))
        fileInfoReplay.onNext(.success(fileInfo))
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testResumWhenFileInfoFailed() {
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()
        var retryFetchFileInfo = false
        let expect = expectation(description: "wait for retry")
        expect.expectedFulfillmentCount = 2

        let sut = createSub(fileInfoReplay: fileInfoReplay, downloader: downloader, retry: {
            retryFetchFileInfo = true
            expect.fulfill()
        }, previewType: .jpgLin, reachable: Observable<Bool>.just(true))
        sut.imageSource.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        fileInfoReplay.onNext(.success(fileInfo))
        let error = NSError(domain: "download thumbnail error", code: -1, userInfo: nil) as Error
        fileInfoReplay.onNext(.failure(error))
        sut.resume()
        XCTAssertTrue(retryFetchFileInfo)
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testResumWhenFileInfoSuccess() {
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()
        var retryDownload = false
        let expect = expectation(description: "wait for retry")
        expect.expectedFulfillmentCount = 2

        let sut = createSub(fileInfoReplay: fileInfoReplay, downloader: downloader, retry: {}, previewType: .jpgLin, reachable: Observable<Bool>.just(true))
        sut.imageSource.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        fileInfoReplay.onNext(.success(fileInfo))
        fileInfoReplay.onNext(.success(fileInfo))
        downloader.didRetry = {
            retryDownload = true
            expect.fulfill()
        }
        sut.resume()
        XCTAssertTrue(retryDownload)
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testDownloadCompleted() {
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()
        let expect = expectation(description: "wait for download state")
        expect.expectedFulfillmentCount = 3
        var imageSourceCount = 0
        let sut = createSub(fileInfoReplay: fileInfoReplay, downloader: downloader, retry: {}, previewType: .jpgLin, reachable: Observable<Bool>.just(true))
        sut.imageSource.drive(onNext: { _ in
            imageSourceCount += 1
            expect.fulfill()
        }).disposed(by: bag)
        fileInfoReplay.onNext(.success(fileInfo))
        fileInfoReplay.onNext(.success(fileInfo))
        downloader.downloadStatusHandler?(.success)
        sut.downloadState.drive(onNext: { state in
            if case .done = state {
                XCTAssertTrue(true)
            } else {
                XCTFail("expect done state get \(state)")
            }
            expect.fulfill()
        }).disposed(by: bag)
        XCTAssertTrue(imageSourceCount == 2)
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testDownloadProgress() {
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()
        let expect = expectation(description: "wait for download state")
        expect.expectedFulfillmentCount = 2

        let sut = createSub(fileInfoReplay: fileInfoReplay, downloader: downloader, retry: {}, previewType: .jpgLin, reachable: Observable<Bool>.just(true))
        sut.imageSource.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        fileInfoReplay.onNext(.success(fileInfo))
        fileInfoReplay.onNext(.success(fileInfo))
        downloader.downloadStatusHandler?(.downloading(progress: 0.5))
        sut.downloadState.drive(onNext: { state in
            if case .progress = state {
                XCTAssertTrue(true)
            } else {
                XCTFail("expect progress state get \(state)")
            }
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testDownloadFailed() {
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()
        let expect = expectation(description: "wait for download state")
        expect.expectedFulfillmentCount = 2

        let sut = createSub(fileInfoReplay: fileInfoReplay, downloader: downloader, retry: {}, previewType: .jpgLin, reachable: Observable<Bool>.just(true))
        sut.imageSource.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        fileInfoReplay.onNext(.success(fileInfo))
        fileInfoReplay.onNext(.success(fileInfo))
        downloader.downloadStatusHandler?(.failed(errorCode: "999"))
        sut.downloadState.drive(onNext: { state in
            if case .failed = state {
                XCTAssertTrue(true)
            } else {
                XCTFail("expect failed state get \(state)")
            }
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }
    
    func testDisableTouch() {
        let meta = metaData(size: 1024, fileName: "name.png")
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let fileInfoReplay = ReplaySubject<Result<DKFileProtocol, Error>>.create(bufferSize: 2)
        let downloader = MockPreviewDownloader()
        let expect = expectation(description: "wait for touchable")
        expect.expectedFulfillmentCount = 3

        let sut = createSub(fileInfoReplay: fileInfoReplay, downloader: downloader, retry: {}, previewType: .jpgLin, reachable: Observable<Bool>.just(false))
        sut.imageSource.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        fileInfoReplay.onNext(.success(fileInfo))
        fileInfoReplay.onNext(.success(fileInfo))
        downloader.downloadStatusHandler?(.failed(errorCode: "999"))
        sut.downloadState.drive(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        sut.progressTouchable.drive(onNext: { touchable in
            XCTAssertFalse(touchable)
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1.0, handler: { error in
            XCTAssertNil(error)
        })
    }







    private func createSub(fileInfoReplay: ReplaySubject<Result<DKFileProtocol, Error>>,
                           downloader: DKPreviewDownloadService,
                           retry: @escaping () -> Void,
                           previewType: DrivePreviewFileType,
                           reachable: Observable<Bool>,
                           hasCache: Bool = true) -> DriveThumbImageViewModel {
        let cacheService = MockCacheService()
        let meta = metaData(size: 1024, fileName: "name")
        let node = cacheNode(fileName: "name", meta: meta)
        if hasCache {
            cacheService.fileResult = .success(node)
        }
        cacheService.fileExist = hasCache
        let dependency = DriveThumbImageViewModelDependencyImpl(fileInfoReplay: fileInfoReplay,
                                                                image: UIImage(),
                                                                downloader: downloader,
                                                                retryFetchFileInfo: retry,
                                                                cacheSource: .standard,
                                                                previewType: previewType,
                                                                networkReachable: reachable,
                                                                cacheService: cacheService)
        
        return DriveThumbImageViewModel(dependency: dependency)
    }
}

class MockPreviewDownloader: DKPreviewDownloadService {
    var didStop: (() -> Void)?
    var didDownloadSimilar: (() -> Void)?
    var didDownloadPreview: (() -> Void)?
    var didRetry: (() -> Void)?
    var didUpdateFileInfo: (() -> Void)?
    var downloadStatusHandler: ((DriveDownloadService.DownloadStatus) -> Void)?
    var forbidDownloadHandler: (() -> Void)?
    var beginDownloadHandler: (() -> Void)?
    var cacheStageHandler: ((DriveStage) -> Void)?
    func stop() {
        didStop?()
    }
    func downloadSimilar(meta: DriveFileMeta, cacheSource: DriveCacheService.Source) {
        didDownloadSimilar?()
    }
    func download(previewType: DrivePreviewFileType, cacheSource: DriveCacheService.Source, cacheCustomID: String?) {
        didDownloadPreview?()
    }
    func retryDownload(cacheSource: DriveCacheService.Source) {
        didRetry?()
    }
    func updateFileInfo(_ info: DKFileProtocol) {
        didUpdateFileInfo?()
    }
}
