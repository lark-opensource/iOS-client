//
//  SpaceNoticeViewModelTests.swift
//  SKCommon-Unit-Tests
//
//  Created by zoujie on 2022/12/1.
//  

import XCTest
@testable import SKSpace
@testable import SKCommon
@testable import SKFoundation
import LarkContainer


class SpaceNoticeViewModelTests: XCTestCase {
    var viewModel: SpaceNoticeViewModel?
    let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    func testCreateBitableHandler() {
        viewModel = SpaceNoticeViewModel(userResolver: userResolver, bulletinManager: nil, commonTrackParams: [:])
        viewModel?.prepare()
        viewModel?.bulltinTrack(event: .close(bulletin: BulletinInfo(id: "mock_id",
                                                                     content: [:],
                                                                     startTime: 20_221_201,
                                                                     endTime: 20_221_201,
                                                                     products: [],
                                                                     version: [:])))
        viewModel = nil
        XCTAssertNil(viewModel)
    }
}
