//
//  DKNaviBarModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by bupozhuang on 2022/6/1.
//

import XCTest
import RxSwift
import SKFoundation
import SpaceInterface
import LarkSecurityComplianceInterface
import SKCommon
@testable import SKDrive

class DKNaviBarModuleTests: XCTestCase {
    var bag = DisposeBag()
    override func setUp() {
        AssertionConfigForTest.disableAssertWhenTesting()
        super.setUp()
    }

    override func tearDown() {
        AssertionConfigForTest.reset()
        super.tearDown()
    }

    func testSetupNaviBarItems() {
        let hostModule = MockHostModule()
        let expect = expectation(description: "update navibar")
        expect.expectedFulfillmentCount = 2
        hostModule.subModuleActionsCenter.subscribe(onNext: { action in
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    XCTAssertTrue(items.count == 1)
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testSetupNaviBarItemsPreviewFromAttachment() {
        let hostModule = MockHostModule(isFromPreviewFrom: .docsAttach)
        let expect = expectation(description: "update navibar")
        expect.expectedFulfillmentCount = 2
        hostModule.subModuleActionsCenter.subscribe(onNext: { action in
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    XCTAssertTrue(items.count == 1)
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testSetupNaviBarItemsPreviewFromAttachmentNotAllow() {
        let hostModule = MockHostModule(isFromPreviewFrom: .docsAttach)
        hostModule.cacManager = MockCACMangerFileNotAllow.self
        let expect = expectation(description: "update navibar")
        expect.expectedFulfillmentCount = 2
        hostModule.subModuleActionsCenter.subscribe(onNext: { action in
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    XCTAssertTrue(items.count == 1)
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testSetupNaviBarItemsPreviewFromCalender() {
        let hostModule = MockHostModule(isFromPreviewFrom: .calendar)
        hostModule.cacManager = MockCACMangerFileNotAllow.self
        let expect = expectation(description: "update navibar")
        expect.expectedFulfillmentCount = 2
        hostModule.subModuleActionsCenter.subscribe(onNext: { action in
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    XCTAssertTrue(items.count == 1)
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testSetupNaviBarItemsPreviewFromCalenderSecurity() {
        let hostModule = MockHostModule(isFromPreviewFrom: .calendar)
        hostModule.cacManager = MockCACMangerFileNotAllowSecurity.self
        let expect = expectation(description: "update navibar")
        expect.expectedFulfillmentCount = 2
        hostModule.subModuleActionsCenter.subscribe(onNext: { action in
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    XCTAssertTrue(items.count == 1)
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testCustomUserDefine() {
        let hostModule = MockHostModule()
        let expect = expectation(description: "run customUserDefine")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        hostModule.subModuleActionsCenter.subscribe(onNext: { [weak self] action in
            guard let self = self else { return }
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    more = items[0] as? DKMoreViewModel
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        if case let .attach(items) = more?.moreType {
            items[4].handler(nil, nil)
        }
        hostModule.previewActionSubject.subscribe(onNext: { previewAction in
            if case .customUserDefine = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: self.bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    
    func testBindPermissionRelay() {
        let hostModule = MockHostModule()
        hostModule.moreDependency = MockMoreDependencyImpl()
        let sut = DKNaviBarModule(hostModule: hostModule)
        let expect = expectation(description: "run customUserDefine")
        expect.expectedFulfillmentCount = 2
        sut.moreItemVisable.subscribe(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        _ = sut.bindHostModule()
        
        hostModule.permissionRelay.accept(DrivePermissionInfo(isReadable: true,
                                                              isEditable: true,
                                                              canComment: true,
                                                              canExport: true,
                                                              canCopy: true,
                                                              canShowCollaboratorInfo: true,
                                                              isCACBlock: false,
                                                              permissionStatusCode: nil))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testUpdateNavibarMoreItem10009() {
        let hostModule = MockHostModule()
        let sut = DKNaviBarModule(hostModule: hostModule)
        let expect = expectation(description: "run customUserDefine")
        expect.expectedFulfillmentCount = 2
        var enableValue: [Bool] = []
        sut.moreItemEanble.subscribe(onNext: { enable in
            enableValue.append(enable)
            expect.fulfill()
        }).disposed(by: bag)
        sut.updateNaviBarMoreItem(with: .serverError(code: 10009))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertEqual(enableValue.last, false)
    }
    
    func testUpdateNavibarMoreItem900021001() {
        let hostModule = MockHostModule()
        let expect = expectation(description: "run customUserDefine")
        expect.expectedFulfillmentCount = 2
        hostModule.subModuleActionsCenter.subscribe(onNext: { action in
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { _ in
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.updateNaviBarMoreItem(with: .serverError(code: 900021001))
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testUpdategAdditionItems() {
        let hostModule = MockHostModule()
        let expect = expectation(description: "update items")
        expect.expectedFulfillmentCount = 4
        var countVlue: [Int] = []
        hostModule.subModuleActionsCenter.subscribe(onNext: { action in
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    countVlue.append(items.count)
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        _ = sut.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.clearNaviBarItems)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertEqual(countVlue.last, 0)
    }
    
    func testForward() {
        let hostModule = MockHostModule()
        let expect = expectation(description: "run customUserDefine")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        hostModule.subModuleActionsCenter.subscribe(onNext: { [weak self] action in
            guard let self = self else { return }
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    more = items[0] as? DKMoreViewModel
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        if case let .attach(items) = more?.moreType {
            items[5].handler(nil, nil)
        }
        hostModule.previewActionSubject.subscribe(onNext: { previewAction in
            if case .forward(_, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: self.bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testSaveToSpace() {
        let hostModule = MockHostModule(isFromPreviewFrom: .docsAttach)
        hostModule.cacManager = MockCACMangerFileNotAllow.self
        let expect = expectation(description: "run customUserDefine")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        hostModule.subModuleActionsCenter.subscribe(onNext: { [weak self] action in
            guard let self = self else { return }
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    more = items[0] as? DKMoreViewModel
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        if case let .attach(items) = more?.moreType {
            items[2].handler(nil, nil)
            items[1].handler(nil, nil)
            items[6].handler(nil, nil)
            items[8].handler(nil, nil)
            items[7].handler(nil, nil)
        }
        hostModule.previewActionSubject.subscribe(onNext: { previewAction in
            if case .forward(_, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: self.bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }
    
    func testSaveToSpaceNotAttach() {
        let hostModule = MockHostModule(isFromPreviewFrom: .wiki)
        hostModule.cacManager = MockCACMangerFileNotAllow.self
        let expect = expectation(description: "run customUserDefine")
        expect.expectedFulfillmentCount = 2
        var more: DKMoreViewModel?
        hostModule.subModuleActionsCenter.subscribe(onNext: { [weak self] action in
            guard let self = self else { return }
            if case let .updateNaviBar(vm) = action {
                vm.rightBarItemsUpdated.drive(onNext: { items in
                    more = items[0] as? DKMoreViewModel
                    expect.fulfill()
                }).disposed(by: self.bag)
            }
        }).disposed(by: self.bag)
        let sut = DKNaviBarModule(hostModule: hostModule)
        sut.setupNaviBarItems(moreDependency: MockMoreDependencyImpl())
        if case let .attach(items) = more?.moreType {
            items[2].handler(nil, nil)
        }
        hostModule.previewActionSubject.subscribe(onNext: { previewAction in
            if case .forward(_, _) = previewAction {
                XCTAssertTrue(true)
                expect.fulfill()
            } else {
                XCTAssertTrue(false)
            }
        }).disposed(by: self.bag)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
    }

}

struct MockMoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        return .just(true)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(true)
    }
    var actions: [DriveSDKMoreAction] {
        return [.saveToLocal(handler: { _, _  in }),
                .customOpenWithOtherApp(customAction: nil, callback: nil),
                .saveToSpace(handler: { _ in }),
                .convertToOnlineFile,
                .customUserDefine(provider: MockDriveSDKCustomMoreActionProvider()),
                .forward(handler: { _, _  in }),
                .saveAlbum(handler: { _, _  in }),
                .saveToLocal(handler: { _, _  in }),
                .saveToFile(handler: { _, _  in })]
    }
}

struct MockDriveSDKCustomMoreActionProvider: DriveSDKCustomMoreActionProvider {
    var actionId: String { return "xxx" }
    var text: String { return "111" }
    var handler: (UIViewController, DKAttachmentInfo) -> Void = { _, _ in }
}

class MockCACMangerFileNotAllow: CACManagerBridge {
    static func syncValidate(entityOperate: LarkSecurityComplianceInterface.EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: SpaceInterface.DocsType, token: String?) -> CCMSecurityPolicyService.ValidateResult {
        return CCMSecurityPolicyService.ValidateResult(allow: false, validateSource: .fileStrategy)
    }

    static func asyncValidate(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?, completion: @escaping (CCMSecurityPolicyService.ValidateResult) -> Void) {
        completion(CCMSecurityPolicyService.ValidateResult(allow: false, validateSource: .fileStrategy))
    }
    
    static func showInterceptDialog(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) {
    }
}

class MockCACMangerFileNotAllowSecurity: CACManagerBridge {
    static func syncValidate(entityOperate: LarkSecurityComplianceInterface.EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: SpaceInterface.DocsType, token: String?) -> CCMSecurityPolicyService.ValidateResult {
        return CCMSecurityPolicyService.ValidateResult(allow: false, validateSource: .securityAudit)
    }

    static func asyncValidate(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?, completion: @escaping (CCMSecurityPolicyService.ValidateResult) -> Void) {
        completion(CCMSecurityPolicyService.ValidateResult(allow: false, validateSource: .securityAudit))
    }
    
    static func showInterceptDialog(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) {
    }
}
