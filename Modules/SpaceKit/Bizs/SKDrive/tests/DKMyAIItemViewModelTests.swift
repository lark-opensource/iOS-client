//
//  DKMyAIItemViewModelTests.swift
//  SKDrive-Unit-Tests
//
//  Created by zenghao on 2023/10/13.
//

import XCTest
import OHHTTPStubs
import SwiftyJSON
import SKFoundation
import SKCommon
import RxSwift
import RxRelay
@testable import SKDrive

class DKMyAIItemViewModelTests: XCTestCase {
    
    
    func testItemDidClicked() {
        let enableRelay = BehaviorRelay<Bool>(value: true)
        let visableRelay = BehaviorRelay<Bool>(value: true)
        let reachable = BehaviorRelay<Bool>(value: true)
        let viewModel = DKMyAIItemViewModel(enable: enableRelay.asObservable(),
                                            visable: visableRelay.asObservable(),
                                            isReachable: reachable.asObservable())
        let result: Bool
        if case .presentMyAIVC = viewModel.itemDidClicked() {
            result = true
        } else {
            result = false
        }
        XCTAssertTrue(result)
    }
}
