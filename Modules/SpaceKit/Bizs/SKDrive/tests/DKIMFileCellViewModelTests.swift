//
//  DKIMFileCellViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by tanyunpeng on 2022/12/20.
//  


import XCTest
import RxSwift
import RxCocoa
import SKCommon
import OHHTTPStubs
@testable import SKFoundation
import SpaceInterface
import SKInfra
@testable import SKDrive
import LarkDocsIcon
// swiftlint:disable type_body_length  file_length
class DKIMFileCellViewModelTests: XCTestCase {
    var bag = DisposeBag()
    var cacheService: DKCacheServiceProtocol!

    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        cacheService = MockCacheService()
        DocsContainer.shared.register(DocsRustNetStatusService.self) { _ in
            return MockDocsRustNetStatusService()
        }
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        HTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testGetter() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "testGetter")
        XCTAssertEqual(sut.fileID, "test")
        XCTAssertEqual(sut.title, "test.png")
        XCTAssertEqual(sut.objToken, "test")
        XCTAssertEqual(sut.fileType, DriveFileType(fileExtension: "png"))
        XCTAssertEqual(sut.shouldShowWatermark, false)
        XCTAssertNil(sut.urlForSuspendable)
        XCTAssertNil(sut.hostModule)
        XCTAssertFalse(sut.isInVCFollow)
        sut.canReadAndCanCopy?.subscribe(onNext: { canRead, canCopy in
            XCTAssertTrue(canRead)
            XCTAssertTrue(canCopy)
            expect.fulfill()
        })
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    func testStartPreviewFailed() {
        // stub network dependency
        print("start setup http stubs")
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfo)
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("DriveFileInfoSucc.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })
        
        let sut = createSut(fileName: "test.png")
        let vc = UIViewController()
        sut.startPreview(hostContainer: vc)
        let expect = expectation(description: "wait for state")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .setupUnsupport( _, _) = state {
                XCTAssertTrue(true)
            } else {
                XCTAssertTrue(false)
            }
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCustomerUserDefineAction() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[1].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .customUserDefine = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testUpdategAdditionItems() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        sut.update(additionLeftBarItems: [DriveNavBarItemData(type: .notify, enable: true, target: nil, action: #selector(mockAction))],
                   additionRightBarItems: [DriveNavBarItemData(type: .bookmark, enable: true, target: nil, action: #selector(mockAction))])
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.leftBarItemsUpdated.debug("leftBarItemsUpdated").drive(onNext: { items in
                XCTAssertTrue(items.count == 1)
                expect.fulfill()
            }).disposed(by: self.bag)
            vm.rightBarItemsUpdated.drive(onNext: { items in
                XCTAssertTrue(items.count == 2)
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandle() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "wait for testHandleState")
        sut.previewAction.subscribe(onNext: {[weak self] action in
            guard let self = self else { return }
            if case .cancelDownload = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handle(previewAction: .cancelDownload)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleNoNet() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "wait for testHandleNoNet")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .setupFailed(_) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleNoNet()
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleBizPreviewUnsupport() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "wait for testHandleBizPreviewUnsupport")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .setupUnsupport(_, _) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleBizPreviewUnsupport(type: .sizeIsZero)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleBizPreviewFailed() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "wait for testHandleBizPreviewFailed")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .setupUnsupport(_, _) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleBizPreviewFailed(canRetry: false)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleBizPreviewFailed2() {
        let sut = createSut(fileName: "test.png")
        var fileInfo = DKFileInfo(appId: "111", fileId: "222", name: "test.png", size: 1, fileToken: "333", authExtra: nil)
        fileInfo.mimeType = "png"
        fileInfo.realMimeType = "png"
        sut.updateFileInfo(fileInfo)
        let expect = expectation(description: "wait for testHandleBizPreviewFailed")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .setupFailed(_) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleBizPreviewFailed(canRetry: false)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleBizPreviewDowngrade() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "wait for testHandleBizPreviewFailed")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .setupFailed( _) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleBizPreviewDowngrade()
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testOpenWithOtherApp() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[0].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .openWithOtherApp(_, _, _, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    func testCustomUserDefine() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[1].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .customUserDefine(_, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testForward() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[3].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .forward(_, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testIMSaveToLocal() {
        let sut = createSut(fileName: "test.png")
        sut.updateFileInfo(DKFileInfo(appId: "111", fileId: "222", name: "3.doc", size: 1, fileToken: "444", authExtra: nil))
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[4].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .completeDownloadToSave(_, _, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testConvertToOnlineFile() {
        let sut = createSut(fileName: "test.doc")
        sut.updateFileInfo(DKFileInfo(appId: "111", fileId: "222", name: "3.doc", size: 1, fileToken: "444", authExtra: nil))
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        sut.naviBarViewModel.subscribe(onNext: {[weak self] vm in
            guard let self = self else { return }
            vm.rightBarItemsUpdated.drive(onNext: { items in
                more = items[0] as? DKMoreViewModel
                expect.fulfill()
            }).disposed(by: self.bag)
        }).disposed(by: bag)
        if case let .attach(items) = more?.moreType {
            items[5].handler(nil, nil)
        }
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .importAs(_, _, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleStartFetch() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .loading = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.startFetch(isAsycn: false))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedFalse() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .setupFailed(_) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.fetchHistoryError, isPreviewing: false))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedTrue() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .toast(_, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.fetchHistoryError, isPreviewing: true))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedTrue1002() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .setupFailed(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.serverError(code: 1002), isPreviewing: true))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedTrue3() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .setupFailed(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.serverError(code: 3), isPreviewing: true))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedTrue90002104() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .setupFailed(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.serverError(code: 90002104), isPreviewing: true))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedTrue90002105() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .alert(_) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.serverError(code: 90002105), isPreviewing: true))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedTrue900021001() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .setupFailed(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.serverError(code: 900021001), isPreviewing: true))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedTrue900099003() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .setupFailed(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.serverError(code: 900099003), isPreviewing: true))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleFetchFailedTrue90001072() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewAction.subscribe(onNext: { previewAction in
            if case .toast(_, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.serverError(code: 90001072), isPreviewing: true))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleShowDownloading() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .showDownloading(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.showDownloading(fileType: .png))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleloading() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .downloading(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.downloading(progress: 0.1))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleDownloadingFailed() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .setupFailed(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.downloadFailed(errorMessage: "111", handler: {  }))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleDownloadingCompleted() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .downloadCompleted = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.downloadCompleted)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleDownloadNoPermission() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .setupFailed(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.downloadNoPermission)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleUnsupport() {
        let sut = createSut(fileName: "test.png")
        let expect = expectation(description: "update items")
        sut.previewStateUpdated.drive(onNext: { action in
            if case .setupUnsupport(_, _) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.unsupport(fileInfo: DKFileInfo(appId: "111", fileId: "222", name: "3.doc", size: 1, fileToken: "444", authExtra: nil), type: .sizeIsZero))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testShowBanner() {
        var uiActionSubject = PublishSubject<DriveSDKUIAction>()
        let sut = createSut(fileName: "testfile", uiAction: uiActionSubject.asObserver())
        let expect = expectation(description: "wait show banner action")
        sut.previewAction.subscribe(onNext:{ action in
            if case .showCustomBanner(_, _) = action {
                XCTAssertTrue(true)
            } else {
                XCTFail("wrong action \(action)")
            }
            expect.fulfill()
        }).disposed(by: bag)
        uiActionSubject.onNext(.showBanner(banner: UIView(), bannerID: "banner"))
        waitForExpectations(timeout: 1.0)
    }
    
    func testHideBanner() {
        var uiActionSubject = PublishSubject<DriveSDKUIAction>()
        let sut = createSut(fileName: "testfile", uiAction: uiActionSubject.asObserver())
        let expect = expectation(description: "wait hide banner action")
        sut.previewAction.subscribe(onNext:{ action in
            if case .hideCustomBanner(_) = action {
                XCTAssertTrue(true)
            } else {
                XCTFail("wrong action \(action)")
            }
            expect.fulfill()
        }).disposed(by: bag)
        uiActionSubject.onNext(.hideBanner(bannerID: "banner"))
        waitForExpectations(timeout: 1.0)
    }

    func testIMExcelEditWithSheet() {
        UserScopeNoChangeFG.setMockFG(key: "ccm.drive.im_wps_edit_enable", value: true)
        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfoV2)
            print("=== fetchFileInfo")
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("DriveFileInfoExcelSucc.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        stub(condition: { request in
            guard let urlString = request.url?.absoluteString else { return false }
            let contain = urlString.contains(OpenAPI.APIPath.excelFileEditType)
            print("=== excelFileEditType")
            return contain
        }, response: { _ in
            HTTPStubsResponse(
                fileAtPath: OHPathForFile("DriveFileEditTypeSheetSucc.json", type(of: self))!,
                statusCode: 200,
                headers: ["Content-Type": "application/json"])
        })

        let sut = createSut(fileName: "Drive代码Issue列表.xlsx")
        let vc = UIViewController()
        sut.startPreview(hostContainer: vc)
        let expect = expectation(description: "wait for state")
        sut.previewAction.subscribe(onNext: { action in
            print("== action \(action)")
            if case .openShadowFile(_, _) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }

    func testIMExcelOpenSuccess() {
        let sut = createSut(fileName: "Drive代码Issue列表.xlsx")
        let openType: DriveOpenType = .wps
        sut.handleOpenFileSuccessType(openType: .wps)
        XCTAssertEqual(openType.rawValue, FileEditMethod.wps.statisticValue)
    }

    func testIMStartPreviewUserDownloadWhenGenerating() {
        stub(
            condition: { request in
                guard let urlString = request.url?.absoluteString else {
                    return false
                }
                let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfoV2)
                return contain
            },
            response: { _ in
                HTTPStubsResponse(
                    fileAtPath: OHPathForFile("DriveFileInfoGenerating.json", type(of: self))!,
                    statusCode: 200,
                    headers: ["Content-Type": "application/json"]
                )
            }
        )

        let permissionSDKEnable = UserScopeNoChangeFG.WWJ.permissionSDKEnable
        let sut = createSut(fileName: "test.mp4")
        var isTranscodingHit = false

        let stateExpectation = expectation(description: "wait for state")
        stateExpectation.expectedFulfillmentCount = 4

        // Expect: .loading -> .loading -> .endLoading -> .transcoding
        let expectedStates: [DKFilePreviewState] = [
            .loading,
            .loading,
            .endLoading,
            .transcoding(fileType: "", handler: nil, downloadForPreviewHandler: nil)
        ]
        var states = [DKFilePreviewState]()
        sut.previewStateUpdated.drive(onNext: { state in
            print("DKIMFileCellViewModelTests, previewStateUpdated: \(state)")
            states.append(state)
            stateExpectation.fulfill()

            if case .transcoding(_, let handler, _) = state {
                isTranscodingHit = true
                handler?(UIView(), nil)  // trigger openWithOtherApp
                sut.reset()
            }
        }).disposed(by: bag)

        let actionExpectation = expectation(description: "wait for action")
        sut.previewAction.subscribe(onNext: { action in
            print("DKIMFileCellViewModelTests, previewAction: \(action)")
            if case .openWithOtherApp(_, _, _, _) = action {
                XCTAssertTrue(isTranscodingHit)
                actionExpectation.fulfill()
            }
        }).disposed(by: bag)

        let vc = UIViewController()
        sut.startPreview(hostContainer: vc)
        wait(for: [stateExpectation, actionExpectation], timeout: 10.0)

        XCTAssertEqual(states, expectedStates)
        XCTAssertTrue(isTranscodingHit)
    }

    @objc
    func mockAction() {
        
    }
}

extension DKIMFileCellViewModelTests {
    private func createSut(fileName: String, uiAction: Observable<DriveSDKUIAction> = .never()) -> DKIMFileCellViewModel {
        let file = DriveSDKIMFile(fileName: fileName,
                                  fileID: "test",
                                  msgID: "123",
                                  uniqueID: nil,
                                  senderTenantID: nil,
                                  extraAuthInfo: nil,
                                  dependency: TestIMDependencyImpl(uiAction: uiAction),
                                  isEncrypted: false)
        let performance = DrivePerformanceRecorder(fileToken: file.fileID,
                                                   fileType: SKFilePath.getFileExtension(from: fileName) ?? "",
                                                   sourceType: .preview,
                                                   additionalStatisticParameters: nil)
        let dependency = MockDKIMFileDependency(file: file, cacheService: cacheService, performanceRecord: performance)
        return DKIMFileCellViewModel(dependency: dependency, permissionService: MockUserPermissionService(), cacManager: MockCACMangerFile.self)
    }
}

class MockDKIMFileDependency: DKIMFileDependency {
    var appID: String = "1003"
    
    var onlineFile: SpaceInterface.DriveSDKIMFile
    
    var fileInfoProvider: SKDrive.DKDefaultFileInfoProvider
    
    var cacheService: SKDrive.DKCacheServiceProtocol
    
    var saveService: SKDrive.DKSaveToSpaceService
    
    var moreConfiguration: SpaceInterface.DriveSDKMoreDependency
    
    var actionProvider: SpaceInterface.DriveSDKActionDependency
    
    var statistics: SKDrive.DKStatisticsService
    
    var performanceRecorder: SKDrive.DrivePerformanceRecorder
    
    init(file: DriveSDKIMFile,
         cacheService: DKCacheServiceProtocol,
         performanceRecord: DrivePerformanceRecorder) {
        self.onlineFile = file
        self.fileInfoProvider = DKDefaultFileInfoProvider(appID: "2", fileID: file.fileID)
        self.cacheService = cacheService
        self.performanceRecorder = performanceRecord
        self.moreConfiguration = file.dependency.moreDependency
        self.actionProvider = file.dependency.actionDependency
        self.saveService = DKSaveToSpacePushService(appID: "2", fileID: file.fileID, authExtra: nil, userID: "123")
        self.statistics = MockStatisticService()
    }
}

struct TestIMDependencyImpl: DriveSDKDependency {
    let more = IMMoreDependencyImpl()
    let action: ActionDependencyImpl
    init(uiAction: Observable<DriveSDKUIAction> = .never()) {
        action = ActionDependencyImpl(uiActionSignal: uiAction)
    }
    var actionDependency: DriveSDKActionDependency {
        return action
    }
    var moreDependency: DriveSDKMoreDependency {
        return more
    }
}
struct IMMoreDependencyImpl: DriveSDKMoreDependency {

    var moreMenuVisable: Observable<Bool> {
        return .just(true)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(true)
    }

    var actions: [DriveSDKMoreAction] {
        return [.openWithOtherApp(fileProvider: MockIMDriveSDKFileProvider()),
                .customUserDefine(provider: MockDriveSDKCustomMoreActionProvider()),
                .saveToSpace(handler: { _ in }),
                .forward(handler: { _, _ in }),
                .IMSaveToLocal(fileProvider: MockIMDriveSDKFileProvider()),
                .convertToOnlineFile]
    }
}

class MockIMDriveSDKFileProvider: DriveSDKFileProvider {
    var fileSize: UInt64 { return 10000 }
    var localFileURL: URL? { return  URL(string: "www.test.com") }
    var mockDownloadState = PublishSubject<DriveSDKDownloadState>()
    
    func canDownload(fromView: UIView?) -> Observable<Bool> {
        return .just(true)
    }

    func download() -> Observable<DriveSDKDownloadState> {
        return self.mockDownloadState.asObservable()
    }
    func cancelDownload() {}
}
