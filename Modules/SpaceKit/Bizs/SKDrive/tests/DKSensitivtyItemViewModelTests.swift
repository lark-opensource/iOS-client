//
//  DKSensitivtyItemViewModelTests.swift
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


class DKSensitivityItemViewModelTests: XCTestCase {
    
    
    func testItemDidClicked() {
        let visableRelay = BehaviorRelay<Bool>(value: true)
        let viewModel = DKSensitivtyItemViewModel(visable: visableRelay.asObservable())
        let result: Bool
        if case .presentSercetSetting = viewModel.itemDidClicked() {
            result = true
        } else {
            result = false
        }
        XCTAssertTrue(result)
    }
}
