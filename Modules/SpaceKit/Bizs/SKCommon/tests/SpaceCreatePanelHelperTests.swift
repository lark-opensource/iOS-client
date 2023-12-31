//
//  SpaceCreatePanelHelperTests.swift
//  SKCommon-Unit-Tests
//
//  Created by zoujie on 2022/12/1.
//  

import XCTest
@testable import SKCommon
@testable import SKFoundation
@testable import SpaceInterface
import SKInfra
import RxSwift
import RxRelay
import LarkContainer

final class SpaceCreatePanelHelperTests: XCTestCase {
    var helper: SpaceCreatePanelHelper?
    private let permissionSDK = MockPermissionSDK()
    private var disposeBag = DisposeBag()

    private static func createBitableHelper() -> SpaceCreatePanelHelper {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: .bitableHome,
                                                                   module: .baseHomePage(context: BaseHomeContext(userResolver: userResolver, containerEnv: .workbench, baseHpFrom: nil, version: .original)),
                                                                   ccmOpenSource: .bitableHome)

        return SpaceCreatePanelHelper(trackParameters: trackParameters,
                                      mountLocation: .folder(token: "mock_folderToken", ownerType: 0),
                                      createDelegate: nil,
                                      createRouter: nil,
                                      createButtonLocation: .bottomRight)
    }

    override func setUp() {
        super.setUp()
        let permissionSDK = self.permissionSDK
        AssertionConfigForTest.disableAssertWhenTesting()
        DocsContainer.shared.register(PermissionSDK.self) { _ in
            permissionSDK
        }
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
        disposeBag = DisposeBag()
    }

    func testCreateBitableHandler() {
        let helper = Self.createBitableHelper()
        let vc = helper.createBitableAddButtonHandler(sourceView: UIView())
        XCTAssertNotNil(vc)
    }
    
    func testGenerateItemsForLark() {
        DocsType.updateMindnoteEnabled()
        let intent = SpaceCreateIntent(context: .recent, source: .fromOnboardingBanner, createButtonLocation: .bottomRight)
        let helper = Self.createBitableHelper()
        let items = helper.generateItemsForLark(intent: intent, reachable: .just(true))
        //docX doc sheet mindnote bitable folder image file
        XCTAssert(items.count > 0)
    }

    func testGenerateUploadItems() {
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: .recent, module: .home(.recent), ccmOpenSource: .home)
        let helper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                            mountLocation: .mySpaceV2,
                                            createDelegate: nil,
                                            createRouter: nil,
                                            createButtonLocation: .blankPage)
        let service = permissionSDK.userPermissionService
        UserScopeNoChangeFG.setMockFG(key: "ccm.permission.permissionsdk.space", value: true)

        let normalIntent = SpaceCreateIntent(context: .recent,
                                             source: .recent,
                                             createButtonLocation: .bottomRight)
        permissionSDK.response = .pass
        var items = helper.generateUploadItemForLark(intent: normalIntent,
                                                     reachable: BehaviorRelay<Bool>(value: true).asObservable())
        XCTAssertEqual(items.count, 2)
        if items.count == 2 {
            let uploadImage = items[0]
            let uploadImageEnableExpect = expectation(description: "upload image enable")
            uploadImage.enableState.subscribe(onNext: { enable in
                XCTAssertTrue(enable)
                uploadImageEnableExpect.fulfill()
            })
            .disposed(by: disposeBag)
            waitForExpectations(timeout: 1)
        }

        permissionSDK.response = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockBySecurityAudit, preferUIStyle: .hidden) { _, _ in }
        items = helper.generateUploadItemForLark(intent: normalIntent, reachable: .just(true))
        XCTAssertTrue(items.isEmpty)

        permissionSDK.response = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockBySecurityAudit, preferUIStyle: .disabled) { _, _ in }
        items = helper.generateUploadItemForLark(intent: normalIntent,
                                                 reachable: BehaviorRelay<Bool>(value: true).asObservable())
        XCTAssertEqual(items.count, 2)
        if items.count == 2 {
            let uploadImage = items[0]
            let uploadImageEnableExpect = expectation(description: "upload image enable")
            uploadImage.enableState.subscribe(onNext: { enable in
                XCTAssertFalse(enable)
                uploadImageEnableExpect.fulfill()
            })
            .disposed(by: disposeBag)
            waitForExpectations(timeout: 1)
        }

        permissionSDK.response = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockBySecurityAudit, preferUIStyle: .default) { _, _ in }
        items = helper.generateUploadItemForLark(intent: normalIntent,
                                                 reachable: BehaviorRelay<Bool>(value: true).asObservable())
        XCTAssertEqual(items.count, 2)
        if items.count == 2 {
            let uploadImage = items[0]
            let uploadImageEnableExpect = expectation(description: "upload image enable")
            uploadImage.enableState.subscribe(onNext: { enable in
                XCTAssertTrue(enable)
                uploadImageEnableExpect.fulfill()
            })
            .disposed(by: disposeBag)
            waitForExpectations(timeout: 1)
        }
    }

    func testGenerateUploadItemsInShareRoot() {
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: .recent, module: .home(.recent), ccmOpenSource: .home)
        let helper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                            mountLocation: .mySpaceV2,
                                            createDelegate: nil,
                                            createRouter: nil,
                                            createButtonLocation: .blankPage)
        let service = permissionSDK.userPermissionService
        UserScopeNoChangeFG.setMockFG(key: "ccm.permission.permissionsdk.space", value: true)
        defer {
            UserScopeNoChangeFG.removeMockFG(key: "ccm.permission.permissionsdk.space")
        }

        let normalIntent = SpaceCreateIntent(context: .sharedFolderRoot,
                                             source: .recent,
                                             createButtonLocation: .bottomRight)
        permissionSDK.response = .pass
        var items = helper.generateUploadItemForLark(intent: normalIntent,
                                                     reachable: BehaviorRelay<Bool>(value: true).asObservable())
        XCTAssertEqual(items.count, 2)
        if items.count == 2 {
            let uploadImage = items[0]
            let uploadImageEnableExpect = expectation(description: "upload image enable")
            uploadImage.enableState.subscribe(onNext: { enable in
                XCTAssertTrue(enable)
                uploadImageEnableExpect.fulfill()
            })
            .disposed(by: disposeBag)
            waitForExpectations(timeout: 1)
        }

        permissionSDK.response = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockBySecurityAudit, preferUIStyle: .hidden) { _, _ in }
        items = helper.generateUploadItemForLark(intent: normalIntent, reachable: .just(true))
        XCTAssertTrue(items.isEmpty)

        permissionSDK.response = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockBySecurityAudit, preferUIStyle: .disabled) { _, _ in }
        items = helper.generateUploadItemForLark(intent: normalIntent,
                                                 reachable: BehaviorRelay<Bool>(value: true).asObservable())
        XCTAssertEqual(items.count, 2)
        if items.count == 2 {
            let uploadImage = items[0]
            let uploadImageEnableExpect = expectation(description: "upload image enable")
            uploadImage.enableState.subscribe(onNext: { enable in
                XCTAssertFalse(enable)
                uploadImageEnableExpect.fulfill()
            })
            .disposed(by: disposeBag)
            waitForExpectations(timeout: 1)
        }

        permissionSDK.response = .forbidden(traceID: "MOCK_TRACE_ID", denyType: .blockBySecurityAudit, preferUIStyle: .default) { _, _ in }
        items = helper.generateUploadItemForLark(intent: normalIntent,
                                                 reachable: BehaviorRelay<Bool>(value: true).asObservable())
        XCTAssertEqual(items.count, 2)
        if items.count == 2 {
            let uploadImage = items[0]
            let uploadImageEnableExpect = expectation(description: "upload image enable")
            uploadImage.enableState.subscribe(onNext: { enable in
                XCTAssertTrue(enable)
                uploadImageEnableExpect.fulfill()
            })
            .disposed(by: disposeBag)
            waitForExpectations(timeout: 1)
        }
    }
}
