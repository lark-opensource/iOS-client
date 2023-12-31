//
//  DKDownloadViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by ZhangYuanping on 2022/3/24.
//  


import XCTest
import SKFoundation
import SpaceInterface
import SKCommon
import RxSwift
import RxCocoa
@testable import SKDrive

class DKDownloadViewModelTests: XCTestCase {

    var sut: DKDownloadViewModel!
    var mockFileProvider: DriveSDKFileProvider!
    var mockCompletion: ((URL?) -> Void)!
    let mockDownloadState = PublishSubject<DriveSDKDownloadState>()
    let disposeBag = DisposeBag()
    
    override func setUp() {
        super.setUp()
        mockCompletion = { url in }
        mockFileProvider = MockDriveSDKFileProvider(downloadState: mockDownloadState)
        sut = DKDownloadViewModel(fileProvider: mockFileProvider, completion: self.mockCompletion)
        
    }

    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDownloadViewAction() {
        let expect = expectation(description: "test download progress")
        expect.expectedFulfillmentCount = 5
        
        var progresses = [Double]()
        var resultUrl = ""
        sut.viewAction.drive(onNext: { action in
            if case .update(let data) = action {
                guard let progressValue = data.progress else { return }
                progresses.append(progressValue)
            }
            if case .success(let url) = action {
                resultUrl = url.absoluteString
            }
            expect.fulfill()
        }).disposed(by: disposeBag)
        
        mockDownloadState.onNext(.downloading(progress: 20))
        mockDownloadState.onNext(.downloading(progress: 50))
        mockDownloadState.onNext(.downloading(progress: 80))
        mockDownloadState.onNext(.success(fileURL: URL(string: "/test/downloaded")!))
        
        wait(for: [expect], timeout: 1.0)
        XCTAssertEqual(progresses, [0, 20, 50, 80])
        XCTAssertEqual(resultUrl, "/test/downloaded")
    }
    
    func testCancelDownload() {
        let expect = expectation(description: "test cancel download")
        expect.expectedFulfillmentCount = 5
        
        var progresses = [Double]()
        var finalStatus: DKDownloadProgressView.DownloadViewAction?
        sut.viewAction.drive(onNext: { action in
            if case .update(let data) = action {
                guard let progressValue = data.progress else { return }
                progresses.append(progressValue)
            }
            if case .cancel = action {
                finalStatus = .cancel
            }
            expect.fulfill()
        }).disposed(by: disposeBag)
        
        mockDownloadState.onNext(.downloading(progress: 20))
        mockDownloadState.onNext(.downloading(progress: 50))
        mockDownloadState.onNext(.downloading(progress: 80))
        sut.cancelDownload()
        
        wait(for: [expect], timeout: 1.0)
        XCTAssertEqual(progresses, [0, 20, 50, 80])
        XCTAssertTrue({ () -> Bool in
            if case .cancel = finalStatus {
                return true
            } else {
                return false
            }
        }())
    }
}

class MockDriveSDKFileProvider: DriveSDKFileProvider {
    var fileSize: UInt64 { return 10000 }
    var localFileURL: URL? { return  URL(string: "www.test.com") }
    var mockDownloadState = PublishSubject<DriveSDKDownloadState>()
    
    init(downloadState: PublishSubject<DriveSDKDownloadState>) {
        self.mockDownloadState = downloadState
    }
    
    func canDownload(fromView: UIView?) -> Observable<Bool> {
        return .just(true)
    }

    func download() -> Observable<DriveSDKDownloadState> {
        return self.mockDownloadState.asObservable()
    }
    func cancelDownload() {}
}
