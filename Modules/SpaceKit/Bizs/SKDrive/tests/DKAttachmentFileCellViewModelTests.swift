//
//  DKAttachmentFileCellViewModelTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by ByteDance on 2022/9/28.
//

import XCTest
import SKFoundation
import SKCommon
import RxSwift
import RxCocoa
import OHHTTPStubs
import SpaceInterface
import SKUIKit
import SwiftyJSON
@testable import SKDrive
@testable import SKFoundation
import SKInfra
import LarkDocsIcon

final class DKAttachmentFileCellViewModelTests: XCTestCase {
    let bag = DisposeBag()
    var cacheService: DKCacheServiceProtocol!
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        cacheService = MockCacheService()
        DocsContainer.shared.register(DocsRustNetStatusService.self) { _ in
            return MockDocsRustNetStatusService()
        }
        UserScopeNoChangeFG.setMockFG(key: "ccm.wiki.mobile.deleted_restore_optimization", value: true)
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }
    
    func testGetters() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        XCTAssertEqual(sut.fileType, .pdf)
        XCTAssertEqual(sut.objToken, "token")
        XCTAssertEqual(sut.title, "xx.pdf")
        XCTAssertEqual(sut.fileID, "token")
        XCTAssertEqual(sut.isInVCFollow, false)
        XCTAssertEqual(sut.scene, .attach)
        XCTAssertNil(sut.urlForSuspendable)
        XCTAssertNotNil(sut.hostModule)
    }
    
    func testStartPreviewFailedWithDownloadFailed() {
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
        
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let vc = UIViewController()
        sut.startPreview(hostContainer: vc)
        let expect = expectation(description: "wait for state")
        expect.expectedFulfillmentCount = 4
        var states = [DKFilePreviewState]()
        // .loading -> .showDownloading -> .downloadCompleted -> .setupFailed
        sut.previewStateUpdated.drive(onNext: { state in
            print("previewStateUpdated: \(state)")
            states.append(state)
            expect.fulfill()
        }).disposed(by: bag)
        

        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
        let failedData = DKPreviewFailedViewData(showRetryButton: true,
                                                 retryEnable: BehaviorRelay<Bool>(value: true),
                                                 retryHandler: {},
                                                 showOpenWithOtherApp: BehaviorRelay<Bool>(value: true),
                                                 openWithOtherEnable: BehaviorRelay<Bool>(value: true)) { _, _ in }
        XCTAssertEqual(states, [.loading,
            .showDownloading(fileType: .pdf),
            .downloadCompleted,
            .setupFailed(data: failedData)])
    }
    
    func testRefreshVersion() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        sut.refreshVersion("111")
        XCTAssertEqual(sut.fileInfo.version, "111")
    }
    
    func testWillChangeMode() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let expect = expectation(description: "wait for testWillChangeMode")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .willChangeMode(_) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.willChangeMode(.normal)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testChangingMode() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let expect = expectation(description: "wait for testChangingMode")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .changingMode(_) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.changingMode(.normal)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testDidChangeModee() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let expect = expectation(description: "wait for testDidChangeModee")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .didChangeMode(_) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.didChangeMode(.normal)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHanlde() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let expect = expectation(description: "wait for testHanlde")
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
    
    func testUpdate() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let leftBar = [DriveNavBarItemData(type: .notify, enable: true, target: nil, action: nil, isHighLighted: true)]
        let rightBar = [DriveNavBarItemData(type: .notify, enable: false, target: nil, action: nil)]
        let expect = expectation(description: "wait for testUpdate")
        sut.subModuleActionsCenter.subscribe(onNext: {[weak self] event in
            if case .updateAdditionNavibarItem(_, _) = event {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.update(additionLeftBarItems: leftBar, additionRightBarItems: rightBar)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleNoNet() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
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
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
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
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
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
    // TODO: tanyunpeng 无效case
//    func testHandleBizPreviewDowngrade() {
//        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
//        let sut = createSut(file: file)
//        sut.startPreview(hostContainer: UIViewController())
//        let expect = expectation(description: "wait for testHandleBizPreviewDowngrade")
//        sut.previewStateUpdated.drive(onNext: { state in
//            if case .setupUnsupport(_, _) = state {
//                XCTAssertTrue(true)
//                expect.fulfill()
//            } else {
//                XCTAssertTrue(false)
//            }
//        }).disposed(by: bag)
//        sut.handleBizPreviewDowngrade()
//        waitForExpectations(timeout: 10.0) { error in
//            XCTAssertNil(error)
//        }
//    }
    
    func testHandleOpenFileSuccessType() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let expect = expectation(description: "wait for testHandleOpenFileSuccessType")
        sut.handleOpenFileSuccessType(openType: .pdfView)
        sut.previewAction.subscribe(onNext: {[weak self] action in
            guard let self = self else { return }
            if case .openSuccess(_) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleOpenFileSuccessType(openType: .pdfView)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleState() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let expect = expectation(description: "wait for testHandleState")
        sut.previewStateUpdated.drive(onNext: { state in
            if case .setupFailed(_) = state {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleState(.fetchFailed(error: DriveError.serverError(code: 3), isPreviewing: true))
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testHandleOpenWithOtherApp() {
        let file = createFile(token: "token", fileType: "pdf", name: "xx.pdf")
        let sut = createSut(file: file)
        let expect = expectation(description: "wait for testHandleState")
        sut.previewAction.subscribe(onNext: { action in
            if case .downloadAndOpenWithOtherApp(_, _, _, _, _) = action {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: bag)
        sut.handleOpenWithOtherApp(sourceView: nil, sourceRect: nil)
        waitForExpectations(timeout: 10.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testShowBannerAction() {
        var uiActionSubject = PublishSubject<DriveSDKUIAction>()
        let file = createFile(token: "token", fileType: "png", name: "testFile", uiAction: uiActionSubject.asObserver())
        let sut = createSut(file: file)
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
    
    func testHideBannerAction() {
        var uiActionSubject = PublishSubject<DriveSDKUIAction>()
        let file = createFile(token: "token", fileType: "png", name: "testFile", uiAction: uiActionSubject.asObserver())
        let sut = createSut(file: file)
        let expect = expectation(description: "wait show banner action")
        sut.previewAction.subscribe(onNext:{ action in
            if case .hideCustomBanner(_) = action {
                XCTAssertTrue(true)
            } else {
                XCTFail("wrong action \(action)")
            }
            expect.fulfill()
        }).disposed(by: bag)
        uiActionSubject.onNext(.hideBanner(bannerID: "banner"))
        waitForExpectations(timeout: 2.0)
    }

    func testHandleDeleteFileRestoreForSpace() {
        let file = createFile(token: "boxFile", fileType: "docx", name: "file.docx")
        let vm = createSut(file: file)
        let expect = expectation(description: "handle delete")
        vm.previewStateUpdated.drive { state in
            if case let .deleteFileRestore(_, compeltion) = state {
                compeltion()
                expect.fulfill()
            }
        }.disposed(by: bag)
        vm.handleFileDeletedRouter()
        waitForExpectations(timeout: 5)
    }
    // TODO: zhuangyizhong 这个测试无效
    // func testHandleDeleteFileRestoreForWiki() {
    //     let file = createFile(token: "boxFile", fileType: "docx", name: "file.docx")
    //     let vm = createSut(file: file, preViewForm: .wiki, wikiToken: "wiki-token")
    //     vm.startPreview(hostContainer: MockDKHostSubModule())
    //     let expect = expectation(description: "handle delete")
    //     expect.expectedFulfillmentCount = 2
    //     vm.previewStateUpdated.drive { state in
    //         print("preview state update: \(state)")
    //         if case let .deleteFileRestore(_, compeltion) = state {
    //             print("get preview state")
    //             compeltion()
    //             expect.fulfill()
    //         }
    //     }.disposed(by: bag)
    //     vm.hostModule?.subModuleActionsCenter.subscribe(onNext: { action in
    //         switch action {
    //         case .resotreSuccess:
    //             expect.fulfill()
    //         default:
    //             return
    //         }
    //     }).disposed(by: bag)
    //     vm.handleFileDeletedRouter()
    //     waitForExpectations(timeout: 5)
    // }

    /* 单测高概率Crash，临时注释
    // 测试权限变更 密码 -> 有权限
    func testPermissionChangeFromPasswordToReadable() {
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
        guard let json = jsonWith(fileName: "DriveUserPermissionNeedPass", ext: "json") else {
            XCTFail("can not read json")
            return
        }
        
        let userPermissons = UserPermission(json: json)
        let permissionModel = PermissionResponseModel(userPermissions: userPermissons,
                                                      publicPermissionMeta: nil,
                                                      permissionStatusCode: PermissionStatusCode(rawValue: 10016),
                                                      error: NSError(domain: "permission failed", code: 999))
        let permissionService = MockDrivePermissionHelperProtocol(permissionModel: permissionModel)
        let file = createFile(token: "boxFile", fileType: "docx", name: "file.docx")
        let sut = createSut(file: file, permissionService: permissionService)
        sut.startPreview(hostContainer: MockHostViewController())
        let expectPermissonChanged = expectation(description: "wait for permission changed")
        expectPermissonChanged.expectedFulfillmentCount = 2
        let expectPermissionPush = expectation(description: "wait for permission push")
        expectPermissionPush.expectedFulfillmentCount = 3
        
        var permissions = [DrivePermissionInfo]()
        sut.permissionRelay.subscribe(onNext: { info in
            permissions.append(info)
            if permissions.count < 3 {
                expectPermissonChanged.fulfill()
            }
            expectPermissionPush.fulfill()
        }).disposed(by: bag)
        wait(for: [expectPermissonChanged], timeout: 1.0)
        
        // 模拟权限推送 -> 可读
        let permissionInfo = DrivePermissionInfo(isReadable: true,
                                                 isEditable: true,
                                                 canComment: true,
                                                 canExport: true,
                                                 canCopy: true,
                                                 canShowCollaboratorInfo: true,
                                                 isCACBlock: false)
        permissionService.permissionChanged?(permissionInfo)
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        sut.reset()
        let firstPermisson = permissions.first // 默认可读
        let secondPermission = permissions[1] // 第一次请求权限
        let thirdPermission = permissions[2] // 权限推送
        XCTAssertTrue(firstPermisson?.isReadable == true)
        XCTAssertTrue(secondPermission.isReadable == false)
        XCTAssertTrue(thirdPermission.isReadable == true)
    }
    */
    
    // 无权限cac管控
    func testPermissionBlockByCACNoPermissionFailed() {
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
        guard let json = jsonWith(fileName: "DriveUserPermissionNeedPassCAC", ext: "json") else {
            XCTFail("can not read json")
            return
        }
        
        let userPermissons = UserPermission(json: json)
        let permissionModel = PermissionResponseModel(userPermissions: userPermissons,
                                                      publicPermissionMeta: nil,
                                                      permissionStatusCode: PermissionStatusCode(rawValue: 0),
                                                      error: NSError(domain: "permission failed", code: 999))
        let permissionService = MockDrivePermissionHelperProtocol(permissionModel: permissionModel)
        let file = createFile(token: "boxFile", fileType: "docx", name: "file.docx")
        let sut = createSut(file: file, permissionService: permissionService)
        sut.startPreview(hostContainer: MockHostViewController())
        let expectPermissonChanged = expectation(description: "wait for permission changed")
        expectPermissonChanged.expectedFulfillmentCount = 2
        let expectPermissionPush = expectation(description: "wait for permission push")
        expectPermissionPush.expectedFulfillmentCount = 3
        
        var permissions = [DrivePermissionInfo]()
        sut.permissionRelay.subscribe(onNext: { info in
            permissions.append(info)
            if permissions.count < 3 {
                expectPermissonChanged.fulfill()
            }
            expectPermissionPush.fulfill()
        }).disposed(by: bag)
        wait(for: [expectPermissonChanged], timeout: 1.0)
        
        // 模拟权限推送 -> 可读
        let permissionInfo = DrivePermissionInfo(isReadable: true,
                                                 isEditable: true,
                                                 canComment: true,
                                                 canExport: true,
                                                 canCopy: true,
                                                 canShowCollaboratorInfo: true,
                                                 isCACBlock: false)
        permissionService.permissionChanged?(permissionInfo)
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        sut.reset()
        guard permissions.count >= 3 else {
            XCTFail("permissions count in-correct")
            return
        }
        let firstPermisson = permissions.first // 默认可读
        let secondPermission = permissions[1] // 第一次请求权限
        let thirdPermission = permissions[2] // 权限推送
        XCTAssertTrue(firstPermisson?.isReadable == true)
        XCTAssertTrue(secondPermission.isReadable == false)
        XCTAssertTrue(thirdPermission.isReadable == true)

    }
        
    // 无权限 code:4
    func testPermissionBlockByForbidden() {
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
        guard let json = jsonWith(fileName: "DriveUserPermissionNoPerm", ext: "json") else {
            XCTFail("can not read json")
            return
        }
        
        let userPermissons = UserPermission(json: json)
        let permissionModel = PermissionResponseModel(userPermissions: userPermissons,
                                                      publicPermissionMeta: nil,
                                                      permissionStatusCode: PermissionStatusCode(rawValue: 0),
                                                      error: DocsNetworkError(4))
        let permissionService = MockDrivePermissionHelperProtocol(permissionModel: permissionModel)
        let file = createFile(token: "boxFile", fileType: "docx", name: "file.docx")
        let sut = createSut(file: file, permissionService: permissionService)
        sut.startPreview(hostContainer: MockHostViewController())
        let expectPermissonChanged = expectation(description: "wait for permission changed")
        expectPermissonChanged.expectedFulfillmentCount = 2
        let expectPermissionPush = expectation(description: "wait for permission push")
        expectPermissionPush.expectedFulfillmentCount = 3
        
        var permissions = [DrivePermissionInfo]()
        sut.permissionRelay.subscribe(onNext: { info in
            permissions.append(info)
            if permissions.count < 3 {
                expectPermissonChanged.fulfill()
            }
            expectPermissionPush.fulfill()
        }).disposed(by: bag)
        wait(for: [expectPermissonChanged], timeout: 1.0)
        
        // 模拟权限推送 -> 可读
        let permissionInfo = DrivePermissionInfo(isReadable: true,
                                                 isEditable: true,
                                                 canComment: true,
                                                 canExport: true,
                                                 canCopy: true,
                                                 canShowCollaboratorInfo: true,
                                                 isCACBlock: false)
        permissionService.permissionChanged?(permissionInfo)
        waitForExpectations(timeout: 1.0) { error in
            XCTAssertNil(error)
        }
        sut.reset()
        guard permissions.count >= 3 else {
            XCTFail("permissions count in-correct")
            return
        }
        let firstPermisson = permissions.first // 默认可读
        let secondPermission = permissions[1] // 第一次请求权限
        let thirdPermission = permissions[2] // 权限推送
        XCTAssertTrue(firstPermisson?.isReadable == true)
        XCTAssertTrue(secondPermission.isReadable == false)
        XCTAssertTrue(thirdPermission.isReadable == true)

    }

    func testStartPreviewUserDownloadWhenGenerating() {
        stub(
            condition: { request in
                guard let urlString = request.url?.absoluteString else {
                    return false
                }
                let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfo)
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

        let file = createFile(token: "token", fileType: "mp4", name: "test.mp4")
        let sut = createSut(file: file)
        var isTranscodingHit = false

        // Expect: .loading -> .loading -> .endLoading -> .transcoding
        let stateExpectation = expectation(description: "wait for state")
        stateExpectation.expectedFulfillmentCount = 4

        let expectedStates: [DKFilePreviewState] = [
            .loading,
            .loading,
            .endLoading,
            .transcoding(fileType: "", handler: nil, downloadForPreviewHandler: nil)
        ]
        var states = [DKFilePreviewState]()
        sut.previewStateUpdated.drive(onNext: { state in
            print("DKAttachmentFileCellViewModelTests, previewStateUpdated: \(state)")
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
            print("DKAttachmentFileCellViewModelTests, previewAction: \(action)")
            if case .downloadAndOpenWithOtherApp(_, _, _, _, _) = action {
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

//    // 无权限 handle: cac
//    func testPermissionBlockHandleCAC() {
//        stub(condition: { request in
//            guard let urlString = request.url?.absoluteString else { return false }
//            let contain = urlString.contains(OpenAPI.APIPath.fetchFileInfo)
//            return contain
//        }, response: { _ in
//            HTTPStubsResponse(
//                fileAtPath: OHPathForFile("DriveFileInfoSucc.json", type(of: self))!,
//                statusCode: 200,
//                headers: ["Content-Type": "application/json"])
//        })
//        let permissionService = MockDrivePermissionHelperProtocol(permissionInfo: DrivePermissionInfo(isReadable: false, isEditable: false, canComment: false, canExport: false, canCopy: false, canShowCollaboratorInfo: false, isCACBlock: true))
//        let file = createFile(token: "boxFile", fileType: "docx", name: "file.docx")
//        let sut = createSut(file: file, permissionService: permissionService)
//        sut.startPreview(hostContainer: MockHostViewController())
//        let expectPermissonChanged = expectation(description: "wait for permission changed")
//        expectPermissonChanged.expectedFulfillmentCount = 2
//        let expectPermissionPush = expectation(description: "wait for permission push")
//        expectPermissionPush.expectedFulfillmentCount = 3
//
//        var permissions = [DrivePermissionInfo]()
//        sut.permissionRelay.subscribe(onNext: { info in
//            permissions.append(info)
//            if permissions.count < 3 {
//                expectPermissonChanged.fulfill()
//            }
//            expectPermissionPush.fulfill()
//        }).disposed(by: bag)
//        wait(for: [expectPermissonChanged], timeout: 1.0)
//
//        // 模拟权限推送 -> 可读
//        let permissionInfo = DrivePermissionInfo(isReadable: true,
//                                                 isEditable: true,
//                                                 canComment: true,
//                                                 canExport: true,
//                                                 canCopy: true,
//                                                 canShowCollaboratorInfo: true,
//                                                 isCACBlock: false)
//        permissionService.permissionChanged?(permissionInfo)
//        waitForExpectations(timeout: 1.0) { error in
//            XCTAssertNil(error)
//        }
//        sut.reset()
//        let firstPermisson = permissions.first // 默认可读
//        let secondPermission = permissions[1] // 第一次请求权限
//        let thirdPermission = permissions[2] // 权限推送
//        XCTAssertTrue(firstPermisson?.isReadable == true)
//        XCTAssertTrue(secondPermission.isReadable == false)
//        XCTAssertTrue(thirdPermission.isReadable == true)
//
//    }
    
    private func jsonWith(fileName: String, ext: String) -> JSON? {
        let curBundle = Bundle(for: type(of: self))
        guard let url = curBundle.url(forResource: fileName, withExtension: ext),
                let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSON(data: data)
    }
}

extension DKAttachmentFileCellViewModelTests {
    private func createFile(token: String,
                            fileType: String,
                            name: String,
                            uiAction: Observable<DriveSDKUIAction> = .never()) -> SpaceInterface.DriveSDKAttachmentFile {
        let actions = [DriveSDKMoreAction.customOpenWithOtherApp(customAction: nil, callback: nil)]
        let more = DKAttachDefaultMoreDependencyImpl(actions: actions,
                                                     moreMenueVisable: Observable<Bool>.just(true),
                                                     moreMenuEnable: .just(true))
        let action = DKAttachDefaultActionDependencyImpl(uiActionSignal: uiAction)
        let dependency = DKAttachDefaultDependency(actionDependency: action, moreDependency: more)
        return DriveSDKAttachmentFile(fileToken: token,
                                      mountNodePoint: nil,
                                      mountPoint: "explore", fileType: fileType, name: name, authExtra: nil, dependency: dependency)
    }

    private func createSut(file: DriveSDKAttachmentFile,
                           preViewForm: DrivePreviewFrom = .docsList,
                           wikiToken: String? = nil,
                           permissionService: DrivePermissionHelperProtocol = MockDrivePermissionHelperProtocol()) -> DKAttachmentFileCellViewModel {
        let performance = DrivePerformanceRecorder(fileToken: file.fileToken,
                                                   fileType: file.fileType ?? "",
                                                   sourceType: .preview,
                                                   additionalStatisticParameters: nil)
        let dependency = MockDKAttachmentFileDependency(file: file, cacheService: cacheService,
                                                        performanceRecord: performance,
                                                        permissionService: permissionService)
        let commonContext = DKSpacePreviewContext(previewFrom: preViewForm,
                                                  canImportAsOnlineFile: false,
                                                  isInVCFollow: false,
                                                  wikiToken: wikiToken,
                                                  feedId: nil,
                                                  isGuest: false,
                                                  hostToken: nil)
        let sut = DKAttachmentFileCellViewModel(dependency: dependency,
                                                previewFrom: preViewForm,
                                                commonContext: commonContext,
                                                scene: .attach)
        return sut
    }
}

class MockDKAttachmentFileDependency: DKAttachmentFileDependency {
    var appID: String = "2"
    
    var file: SpaceInterface.DriveSDKAttachmentFile
    
    var cacheService: SKDrive.DKCacheServiceProtocol
    
    var permissionHelper: SKDrive.DrivePermissionHelperProtocol
    
    var moreConfiguration: SpaceInterface.DriveSDKMoreDependency
    
    var actionProvider: SpaceInterface.DriveSDKActionDependency
    
    var statistics: SKDrive.DKStatisticsService
    
    var performanceRecorder: SKDrive.DrivePerformanceRecorder
    
    var isInVCFollow: Bool = false
    
    var canImportAsOnlineFile: Bool
    
    init(file: DriveSDKAttachmentFile,
         cacheService: DKCacheServiceProtocol,
         performanceRecord: DrivePerformanceRecorder,
         permissionService: SKDrive.DrivePermissionHelperProtocol = MockDrivePermissionHelperProtocol()) {
        self.file = file
        self.cacheService = cacheService
        self.performanceRecorder = performanceRecord
        self.moreConfiguration = file.dependency.moreDependency
        self.actionProvider = file.dependency.actionDependency
        self.permissionHelper = permissionService
        self.statistics = DKStatistics(appID: "2",
                                       fileID: file.fileToken,
                                       fileType: DriveFileType(fileExtension: file.fileType ?? ""),
                                       previewFrom: .docsList,
                                       mountPoint: nil,
                                       isInVCFollow: false,
                                       isAttachMent: false,
                                       statisticInfo: nil)
        self.canImportAsOnlineFile = false
    }
}
//DKMainViewModel
class MockDrivePermissionHelperProtocol: DrivePermissionHelperProtocol {
    var permissionService: UserPermissionService = MockUserPermissionService()
    var didStart: (() -> Void)?
    var didUnRegist: (() -> Void)?
    var permissionChanged: SKDrive.PermissionChangedBlock?
    var failedBlock: ((SKCommon.PermissionResponseModel) -> Void)?
    private let initailPermission: DrivePermissionInfo?
    private let permissionModel: PermissionResponseModel?
    init(permissionInfo: DrivePermissionInfo? = nil, permissionModel: PermissionResponseModel? = nil) {
        self.initailPermission = permissionInfo
        self.permissionModel = permissionModel
    }
    func startMonitorPermission(startFetch: @escaping () -> Void,
                                permissionChanged: @escaping SKDrive.PermissionChangedBlock,
                                failed: @escaping (SKCommon.PermissionResponseModel) -> Void) {
        didStart?()
        self.permissionChanged = permissionChanged
        self.failedBlock = failed
        if let permission = initailPermission {
            self.permissionChanged?(permission)
        } else if let model = permissionModel {
            self.failedBlock?(model)
        } else {
            let permissionInfo = DrivePermissionInfo(isReadable: true,
                                                     isEditable: true,
                                                     canComment: true,
                                                     canExport: true,
                                                     canCopy: true,
                                                     canShowCollaboratorInfo: true,
                                                     isCACBlock: false)
            self.permissionChanged?(permissionInfo)
        }
    }
    
    func unRegister() {
        didUnRegist?()
    }
}

class MockDocsRustNetStatusService: DocsRustNetStatusService {
    var status: BehaviorRelay<RustNetStatus> {
        return BehaviorRelay<RustNetStatus>(value: .excellent)
    }
}
