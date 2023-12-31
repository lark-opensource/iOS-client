//
//  DKHistoryRecordModuleTests.swift
//  SKDrive-Unit-Tests
//
//  Created by majie.7 on 2022/3/9.
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
import EENavigator
@testable import SKDrive

class DKHistoryRecordModuleTests: XCTestCase {
    var historyModule: DKHistoryRecordModule!
    var hostModule: DKHostModuleType!
    func testOpenHistory() {
        let expect = expectation(description: "did push")
        let navigator = MockNavigator()
        navigator.complete = {
            expect.fulfill()
        }
        hostModule = MockHostModule()
        historyModule = DKHistoryRecordModule(hostModule: hostModule, navigator: navigator)
        _ = historyModule.bindHostModule()
        hostModule.subModuleActionsCenter.accept(.openHistory)
        waitForExpectations(timeout: 10) { error in
            XCTAssertNil(error)
        }
        XCTAssertTrue(navigator.pushVC is DriveActivityViewController)
        XCTAssertTrue(navigator.fromVC is DKSubModleHostVC)
    }
}

public class MockNavigator: DKNavigatorProtocol {
    var pushVC: UIViewController?
    var fromVC: UIViewController?
    var complete: (() -> Void)?
    var didPresent: Bool = false
    
    var didPush: Bool = false
    public init() {}
    
    public func push(vc: UIViewController, from: UIViewController, animated: Bool, completion:(() -> Void)?) {
        self.pushVC = vc
        self.fromVC = from
        didPush = true
        self.complete?()
        completion?()
    }
    
    public func present(vc: UIViewController, from: UIViewController, animated: Bool, completion:(() -> Void)?) {
        didPresent = true
        complete?()
        completion?()
    }
}
