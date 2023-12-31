//
//  DKFeedItemViewModelTests.swift
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
@testable import SKDrive

class DKFeedItemViewModelTests: XCTestCase {
    
    
    func testItemDidClicked() {
        let enableRelay = BehaviorRelay<Bool>(value: true)
        let visableRelay = BehaviorRelay<Bool>(value: true)
        let reachable = BehaviorRelay<Bool>(value: true)
        let viewModel = DKFeedItemViewModel(enable: enableRelay.asObservable(),
                                            visable: visableRelay.asObservable(),
                                            isReachable: reachable.asObservable())
        let result: Bool
        if case .presentFeedVC = viewModel.itemDidClicked() {
            result = true
        } else {
            result = false
        }
        XCTAssertTrue(result)
    }
}
