//
//  DoneFeedsViewModelTest.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import XCTest
@testable import LarkFeed

class DoneFeedsViewModelTest: XCTestCase {
    var doneFeedsVM: DoneFeedsViewModel!

    override func setUp() {
        doneFeedsVM = DoneFeedsViewModel(dependency: MockTabFeedsViewModelDependency(),
                                         baseDependency: MockBaseFeedsViewModelDependency())
        super.setUp()
    }

    override func tearDown() {
        doneFeedsVM = nil
        super.tearDown()
    }

    // MARK: - bizType

    /// case 1: bizType = .done
    func test_bizType() {
        XCTAssert(doneFeedsVM.bizType == .done)
    }

    // MARK: - feedType

    /// case 1: feedType = .done
    func test_feedType() {
        XCTAssert(doneFeedsVM.feedType() == .done)
    }
}
