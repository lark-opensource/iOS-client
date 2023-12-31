//
//  DKPreviewViewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/9/27.
//

import XCTest
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import OHHTTPStubs
import LarkDocsIcon
@testable import SKDrive
import SKInfra

// swiftlint:disable type_body_length file_length
final class DKPreviewViewModelTests: XCTestCase {
    let bag = DisposeBag()
    var cacheService: DKCacheServiceProtocol!
    var downloader: MockPreviewDownloader!

    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        cacheService = MockCacheService()
        downloader = MockPreviewDownloader()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    func testGetPerformanceRecorder() {
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        XCTAssertNotNil(sut.performanceRecorder)
    }

    // loading, endloading, downloadPreview
    func testStartSubscribeToStateWithoutPreviewType() {
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: nil,
                           dependency: dependency)
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 3
        var states = [DKPreviewViewModel.State]()
        self.downloader.didDownloadPreview = {
            expect.fulfill()
        }
        sut.previewState.drive(onNext: { state in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)


        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }

    // loading, endloading, endTranscoding, downloadPreview
    func testStartSubscribeToStateWithPreviewType() {
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        self.downloader.didDownloadPreview = {
            expect.fulfill()
        }
        sut.previewState.drive(onNext: { state in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)

        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateUnsupport() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateState(.unsupport(type: .sizeIsZero))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateTranscoding() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateState(.startTranscoding(pullInterval: 1, handler: nil))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateEndTranscoding() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateState(.endTranscoding(status: .sizeIsZero))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateFetchPreviewURLFailg() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateState(.fetchPreviewURLFail(canRetry: true, errorMsg: "111"))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateSetUpPreviewLocal() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        let urlPath = SKFilePath(absUrl: url)
        sut.updateState(.setupPreview(fileType: .heic, info: .local(url: urlPath, originFileType: .heic)))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateSetUpPreviewLocalMeida() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        let urlPath = SKFilePath(absUrl: url)
        sut.updateState(.setupPreview(fileType: .heic, info: .localMedia(url: urlPath, video: DriveVideo(type: .local(url: urlPath), info: nil, title: "xxx", size: 1, cacheKey: "123", authExtra: nil))))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateSetUpPreviewStreamVideo() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        let urlPath = SKFilePath(absUrl: url)
        sut.updateState(.setupPreview(fileType: .heic, info: .streamVideo(video: DriveVideo(type: .local(url: urlPath), info: nil, title: "123", size: 1, cacheKey: "234", authExtra: nil))))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateSetUpPreviewHtml() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateState(.setupPreview(fileType: .heic, info: .previewHtml(extraInfo: "111")))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateSetUpPreviewArchive() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateState(.setupPreview(fileType: .heic,
                                      info: .archive(viewModel: DriveArchivePreviewViewModel(fileID: "111", fileName: "2",
                                                                                             archiveContent: nil,
                                                                                             previewFrom: nil,
                                                                                             additionalStatisticParameters: nil))))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testUpdateStateSetUpPreviewLinearizedImage() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        let curBundle = Bundle(for: type(of: self))
        let url = curBundle.url(forResource: "support", withExtension: "heic")
        guard let url = url else {
            XCTAssertFalse(true)
            return
        }
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        let context = DriveFilePreviewContext(status: 1)
        let preview = DriveFilePreview(context: context)
        sut.updateState(.setupPreview(fileType: .heic, info: .linearizedImage(preview: preview)))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testDownLoading() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        downloader.downloadStatusHandler?(.downloading(progress: 0.8))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testDownLoadFailed403() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        downloader.downloadStatusHandler?(.failed(errorCode: "403"))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testDownLoadFailed404() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        downloader.downloadStatusHandler?(.failed(errorCode: "404"))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testDownLoadSuccess() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 5
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in

            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        downloader.downloadStatusHandler?(.success)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testDownLoadRetry() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        downloader.downloadStatusHandler?(.retryFetch(errorCode: "403"))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testBeginDownloader() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 4
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        downloader.beginDownloadHandler?()
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testForbinDownloader() {
        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 3
        var states = [DKPreviewViewModel.State]()
        let dependency = createDependency(token: "token",
                                          fileType: .pdf,
                                          fileName: "name.pdf",
                                          fileSize: 1024,
                                          previewType: .linerizedPDF)
        let sut = creatSut(token: "token",
                           fileType: .pdf,
                           fileName: "name.pdf",
                           fileSize: 1024,
                           previewType: .linerizedPDF,
                           dependency: dependency)
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        downloader.forbidDownloadHandler?()
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testPushServiceWhenTranscoding() {
        stub(
            condition: { request in
                guard let urlString = request.url?.absoluteString else {
                    return false
                }
                let contain =
                urlString.contains(OpenAPI.APIPath.driveGetServerPreviewURL)
                || urlString.contains(OpenAPI.APIPath.previewGetV2)
                return contain
            },
            response: { _ in
                HTTPStubsResponse(
                    // Trigger DriveError.fileInfoParserError
                    fileAtPath: OHPathForFile("DriveFileInfoGenerating.json", type(of: self))!,
                    statusCode: 200,
                    headers: ["Content-Type": "application/json"]
                )
            }
        )

        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 5

        let previewType: DrivePreviewFileType = .mp4

        let pushData = DKFilePreviewPushData(appID: "appID",
                                            fileID: "fileID",
                                            dataVersion: "",
                                            previewType: previewType.rawValue,
                                            previewStatus: .ready)
        let pushDataModel = MockPushDataModel(pushData: pushData)

        let dependency = createDependency(token: "token",
                                          fileType: .mp4,
                                          fileName: "name.mp4",
                                          fileSize: 1024,
                                          previewType: previewType,
                                          pushDataModel: pushDataModel)

        let sut = creatSut(token: "token",
                           fileType: .mp4,
                           fileName: "name.mp4",
                           fileSize: 1024,
                           previewType: previewType,
                           dependency: dependency,
                           allowDowngradeToOrigin: false)

        // The last state should be .fetchFailed
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            print("DKPreviewViewModelTests, testPushServiceWhenTranscoding: \(state)")
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateState(.startTranscoding(pullInterval: 10000000, handler: nil))

        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testPullingPreviewInfoWhenTranscoding() {
        stub(
            condition: { request in
                guard let urlString = request.url?.absoluteString else {
                    return false
                }
                let contain =
                    urlString.contains(OpenAPI.APIPath.driveGetServerPreviewURL)
                    || urlString.contains(OpenAPI.APIPath.previewGetV2)
                return contain
            },
            response: { _ in
                HTTPStubsResponse(
                    // Trigger DriveError.fileInfoParserError
                    fileAtPath: OHPathForFile("DriveFileInfoGenerating.json", type(of: self))!,
                    statusCode: 200,
                    headers: ["Content-Type": "application/json"]
                )
            }
        )

        let expect = expectation(description: "wait for preview state")
        expect.expectedFulfillmentCount = 5

        let previewType: DrivePreviewFileType = .mp4
        let dependency = createDependency(token: "token",
                                          fileType: .mp4,
                                          fileName: "name.mp4",
                                          fileSize: 1024,
                                          previewType: previewType)

        let sut = creatSut(token: "token",
                           fileType: .mp4,
                           fileName: "name.mp4",
                           fileSize: 1024,
                           previewType: previewType,
                           dependency: dependency,
                           allowDowngradeToOrigin: false)

        // The last state should be .fetchFailed
        sut.previewState.asObservable().subscribe(onNext: { (state) in
            print("DKPreviewViewModelTests, testPullingPreviewInfoWhenTranscoding: \(state)")
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateState(.startTranscoding(pullInterval: 1, handler: nil))

        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
}

extension DKPreviewViewModelTests {
    private func createDependency(token: String,
                                  fileType: DriveFileType,
                                  fileName: String,
                                  fileSize: UInt64,
                                  previewType: DrivePreviewFileType,
                                  pushDataModel: MockPushDataModel? = nil) -> MockAttachPreviewVMDependency {
        let meta = metaData(size: fileSize, fileName: fileName)
        let fileInfo = DriveFileInfo(fileMeta: meta)
        let performanceRecorder = DrivePerformanceRecorder(fileToken: token,
                                                           fileType: fileType.rawValue,
                                                           sourceType: .other,
                                                           additionalStatisticParameters: nil)
        let previewProcessorProvider = DefaultPreviewProcessorProvider(cacheService: cacheService)
        let dependency = MockAttachPreviewVMDependency(
            performanceRecorder: performanceRecorder,
            cacheService: cacheService,
            filePreviewProcessorProvider: previewProcessorProvider,
            previewPushService: MockFilePreviewPushService(pushDataModel: pushDataModel),
            fileInfo: fileInfo,
            previewType: previewType,
            downloader: self.downloader)
        return dependency
    }

    private func creatSut(token: String,
                          fileType: DriveFileType,
                          fileName: String,
                          fileSize: UInt64,
                          isInVCFollow: Bool = false,
                          previewType: DrivePreviewFileType?,
                          dependency: DKPreviewVMDependency,
                          allowDowngradeToOrigin: Bool = true) -> DKPreviewViewModel {
        let meta = metaData(size: fileSize, fileName: fileName)
        let context = DriveFilePreviewContext(status: 0,
                                              interval: nil,
                                              longPushInterval: nil,
                                              previewURL: "http://xx/xxx.pdf",
                                              previewFileSize: nil,
                                              linearized: true,
                                              videoInfo: nil,
                                              extra: nil)
        let preview = DriveFilePreview(context: context)
        var metas = [DrivePreviewFileType: DriveFilePreview]()
        if let previewType = previewType {
            metas[previewType] = preview
        }
        let fileInfo = DriveFileInfo(fileMeta: meta,
                                     previewType: previewType,
                                     previewMetas: metas)
        let performanceRecorder = DrivePerformanceRecorder(fileToken: token,
                                                           fileType: fileType.rawValue,
                                                           sourceType: .other,
                                                           additionalStatisticParameters: nil)

        let config = DrivePreviewProcessorConfig(allowDowngradeToOrigin: allowDowngradeToOrigin,
                                                 canDownloadOrigin: true,
                                                 previewFrom: performanceRecorder.previewFrom,
                                                 isInVCFollow: isInVCFollow,
                                                 cacheSource: .standard,
                                                 authExtra: nil)
        let vm = DKPreviewViewModel(fileInfo: fileInfo,
                                    isLatest: true,
                                    processorConfig: config,
                                    dependency: dependency)
        return vm
    }
}

class MockAttachPreviewVMDependency: DKPreviewVMDependency {
    var downloader: SKDrive.DKPreviewDownloadService = MockDKPreviewDownloadService()

    var filePreviewProvider: SKDrive.FilePreviewProvider

    var filePreviewProcessorProvider: SKDrive.PreviewProcessorProvider

    var cacheService: SKDrive.DKCacheServiceProtocol

    var previewPushService: SKDrive.FilePreviewPushService

    let netStateRelay = BehaviorRelay<Bool>(value: true)
    var networkState: RxSwift.Observable<Bool> {
        return netStateRelay.asObservable()
    }

    var performanceRecorder: SKDrive.DrivePerformanceRecorder
    init(performanceRecorder: SKDrive.DrivePerformanceRecorder,
         cacheService: DKCacheServiceProtocol,
         filePreviewProcessorProvider: SKDrive.PreviewProcessorProvider,
         previewPushService: SKDrive.FilePreviewPushService,
         fileInfo: DriveFileInfo, previewType: DrivePreviewFileType,
         downloader: DKPreviewDownloadService) {
        self.performanceRecorder = performanceRecorder
        self.filePreviewProcessorProvider = filePreviewProcessorProvider
        self.previewPushService = previewPushService
        self.filePreviewProvider = DriveFilePreviewProvider(fileInfo: fileInfo,
                                                            previewType: previewType)
        self.cacheService = cacheService
        self.downloader = downloader
    }
}

struct MockPushDataModel {
    var pushData: DKFilePreviewPushData
}

class MockFilePreviewPushService: FilePreviewPushService {
    var didUnregist: (() -> Void)?
    let pushDataReplay = PublishRelay<DKFilePreviewPushData>()
    var pushDataModel: MockPushDataModel?

    init() {}

    init(pushDataModel: MockPushDataModel?) {
        self.pushDataModel = pushDataModel
    }

    func registPushService() -> RxSwift.Observable<SKDrive.DKFilePreviewPushData> {
        defer {
            if let pushDataModel = pushDataModel {
                DispatchQueue.main.async { [weak self] in
                    guard let self, let pushDataModel = self.pushDataModel else {
                        return
                    }
                    self.pushDataReplay.accept(pushDataModel.pushData)
                }
            }
        }
        return pushDataReplay.asObservable()
    }

    func unRegistPushService() {
        didUnregist?()
    }
}

class MockDKPreviewDownloadService: DKPreviewDownloadService {
    var downloadStatusHandler: ((SKDrive.DriveDownloadService.DownloadStatus) -> Void)?

    var forbidDownloadHandler: (() -> Void)?

    var beginDownloadHandler: (() -> Void)?

    var cacheStageHandler: ((SKDrive.DriveStage) -> Void)?

    var didStop: (() -> Void)?

    func stop() {
        didStop?()
    }

    var didDownloadSimiar: (() -> Void)?
    func downloadSimilar(meta: SKDrive.DriveFileMeta, cacheSource: SKDrive.DriveCacheService.Source) {
        didDownloadSimiar?()
    }

    var didDownloadPreview: (() -> Void)?
    func download(previewType: SKDrive.DrivePreviewFileType, cacheSource: SKDrive.DriveCacheService.Source, cacheCustomID: String?) {
        didDownloadPreview?()
    }

    var didRetry: (() -> Void)?
    func retryDownload(cacheSource: SKDrive.DriveCacheService.Source) {
        didRetry?()
    }

    var didUpdateFile: (() -> Void)?
    func updateFileInfo(_ info: SKDrive.DKFileProtocol) {
        didUpdateFile?()
    }
}
