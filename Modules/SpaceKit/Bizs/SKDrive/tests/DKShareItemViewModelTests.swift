//
//  DKShareItemViewModelTests.swift
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


class DKShareItemViewModelTests: XCTestCase {
    
    
    func testItemDidClicked() {
        let enableRelay = BehaviorRelay<Bool>(value: true)
        let visableRelay = BehaviorRelay<Bool>(value: true)
        let reachable = BehaviorRelay<Bool>(value: true)
        let viewModel = DKShareItemViewModel(enable: enableRelay.asObservable(),
                                             visable: visableRelay.asObservable(),
                                             isReachable: reachable.asObservable())
        let action: DKNaviBarItemAction = viewModel.itemDidClicked()
        let result: Bool
        if case .presentShareVC = action {
            result = true
        } else {
            result = false
        }
        XCTAssertTrue(result)
    }
}
