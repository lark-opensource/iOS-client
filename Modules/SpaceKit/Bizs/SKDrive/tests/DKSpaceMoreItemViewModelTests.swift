//
//  DKSpaceMoreItemViewModelTests.swift
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
import SpaceInterface
@testable import SKDrive


class DKSpaceMoreItemViewModelTests: XCTestCase {
    
    func testItemDidClicked() {
        let enableRelay = BehaviorRelay<Bool>(value: true)
        let visableRelay = BehaviorRelay<Bool>(value: true)
        let reachable = BehaviorRelay<Bool>(value: true)
        let viewModel = DKSpaceMoreItemViewModel(enable: enableRelay.asObservable(),
                                                 visable: visableRelay.asObservable(),
                                                 isReachable: reachable.asObservable())
        let result: Bool
        if case .presentSpaceMoreVC = viewModel.itemDidClicked() {
            result = true
        } else {
            result = false
        }
        XCTAssertTrue(result)
    }
}
