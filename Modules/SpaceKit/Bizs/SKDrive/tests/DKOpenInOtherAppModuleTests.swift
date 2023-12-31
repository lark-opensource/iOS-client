//
//  DKOpenInOtherAppModuleTests.swift
//  SKDrive_Tests-Unit-_Tests
//
//  Created by Tanyunpeng on 2022/4/25.
//

import XCTest
import OHHTTPStubs
import SwiftyJSON
import SKFoundation
import SKCommon
import RxSwift
import RxRelay
import RxCocoa
import SpaceInterface
import LarkSecurityComplianceInterface
@testable import SKDrive

class DKOpenInOtherAppModuleTests: XCTestCase {
    var hostModule: DKHostModuleType!
    var openInOtherApp: DKOpenInOtherAppModule!

    func testCanOpenInOtherAppShowFailure() {
        let expect = expectation(description: "did push")
        hostModule = MockHostModule()
        let mockOpenInOtherAppSubModuleDependencyImpl = MockOpenInOtherAppSubModuleDependencyImpl()
        mockOpenInOtherAppSubModuleDependencyImpl.complete = {
            expect.fulfill()
        }
        openInOtherApp = DKOpenInOtherAppModule(hostModule: hostModule, submodulesMethod: mockOpenInOtherAppSubModuleDependencyImpl, cacManager: MockCACMangerSecurity.self)
        _ = openInOtherApp.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.spaceOpenWithOtherApp)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(mockOpenInOtherAppSubModuleDependencyImpl.hasShowFailure)
        XCTAssertFalse(mockOpenInOtherAppSubModuleDependencyImpl.hasOpenOtherApp)

    }
    
    func testCanOpenInOtherApp() {
        let expect = expectation(description: "did push")
        hostModule = MockHostModule()
        let mockOpenInOtherAppSubModuleDependencyImpl = MockOpenInOtherAppSubModuleDependencyImpl()
        mockOpenInOtherAppSubModuleDependencyImpl.complete = {
            expect.fulfill()
        }
        mockOpenInOtherAppSubModuleDependencyImpl.canOpenWithOtherApp = true
        openInOtherApp = DKOpenInOtherAppModule(hostModule: hostModule, submodulesMethod: mockOpenInOtherAppSubModuleDependencyImpl, cacManager: MockCACMangerFile.self)
        _ = openInOtherApp.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.spaceOpenWithOtherApp)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertFalse(mockOpenInOtherAppSubModuleDependencyImpl.hasShowFailure)
        XCTAssertTrue(mockOpenInOtherAppSubModuleDependencyImpl.hasOpenOtherApp)

    }
}



public class MockOpenInOtherAppSubModuleDependencyImpl: OpenInOtherAppSubModuleDependency {
    var hasOpenOtherApp: Bool = false
     
    var hasShowFailure: Bool = false
    
    var canOpenWithOtherApp: Bool = false
    
    var complete: (() -> Void)?
    
    public init() {}

    public func openWith3rdApp(context: OpenInOtherAppContext) {
        hasOpenOtherApp = true
        complete?()
    }
    
    public func showFailure(with text: String, on view: UIView) {
        hasShowFailure = true
        complete?()
    }
}

class MockCACMangerFile: CACManagerBridge {
    static func syncValidate(entityOperate: LarkSecurityComplianceInterface.EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: SpaceInterface.DocsType, token: String?) -> CCMSecurityPolicyService.ValidateResult {
        return CCMSecurityPolicyService.ValidateResult(allow: true, validateSource: .fileStrategy)
    }

    static func asyncValidate(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?, completion: @escaping (CCMSecurityPolicyService.ValidateResult) -> Void) {
        completion(CCMSecurityPolicyService.ValidateResult(allow: true, validateSource: .fileStrategy))
    }
    
    static func showInterceptDialog(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) {
    }
}

class MockCACMangerSecurity: CACManagerBridge {
    static func syncValidate(entityOperate: LarkSecurityComplianceInterface.EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: SpaceInterface.DocsType, token: String?) -> CCMSecurityPolicyService.ValidateResult {
        return CCMSecurityPolicyService.ValidateResult(allow: false, validateSource: .securityAudit)
    }

    static func asyncValidate(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?, completion: @escaping (CCMSecurityPolicyService.ValidateResult) -> Void) {
        completion(CCMSecurityPolicyService.ValidateResult(allow: false, validateSource: .securityAudit))
    }
    
    static func showInterceptDialog(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) {
    }
}
