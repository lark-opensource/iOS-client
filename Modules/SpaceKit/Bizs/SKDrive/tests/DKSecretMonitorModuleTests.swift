//
//  DKSecretMonitorModuleTests.swift
//  SKDrive-Unit-Tests
//
//  Created by majie.7 on 2022/11/14.
//

import Foundation
import XCTest
import RxSwift
@testable import SKDrive

final class DKSecretMonitorModuleTests: XCTestCase {
    private var bag = DisposeBag()
    override func setUp() {
        super.setUp()
        bag = .init()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testSecretDidChanged() {
        let hostModule = MockHostModule()
        let module = DKSecretMonitorModule(hostModule: hostModule)
        let expect = expectation(description: "secret did change")
        hostModule.subModuleActionsCenter.subscribe { action in
            if case .updateDocsInfo = action {
                expect.fulfill()
            }
        }.disposed(by: bag)
        module.secretDidChanged(token: "Token", type: 22)
        waitForExpectations(timeout: 5)
    }
}
