//
//  WorkspacePickerRecentViewModelTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/10/11.
//

import Foundation
import XCTest
import SKFoundation
@testable import SKCommon
import RxSwift
import SpaceInterface

private class NetworkAPI: WorkspacePickerNetworkAPI {

    enum TestError: Error {
        case expectedError
        case notImplement
    }

    static var expectAction = WorkspacePickerAction.createWiki
    static var expectFilter = RecentFilter.all

    class func loadRecentEntries(action: WorkspacePickerAction, filter: RecentFilter) -> Single<[WorkspacePickerRecentEntry]> {
        XCTAssertEqual(action, expectAction)
        XCTAssertEqual(filter, expectFilter)
        return .error(TestError.notImplement)
    }
}

final class WorkspacePickerRecentViewModelTests: XCTestCase {

    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testFilterAction() {

        NetworkAPI.expectAction = .createWiki
        NetworkAPI.expectFilter = .all
        var config = WorkspacePickerConfig(title: "",
                                           actionName: "",
                                           action: .createWiki,
                                           entrances: .wikiAndSpace,
                                           tracker: WorkspacePickerTracker(actionType: .createFile,
                                                                           triggerLocation: .topBar)) { _, _ in }
        var viewModel = WorkspacePickerRecentViewModel(config: config, networkAPI: NetworkAPI.self)
        _ = viewModel.reload()

        NetworkAPI.expectAction = .copySpace
        NetworkAPI.expectFilter = .spaceOnly
        config.action = .copySpace
        config.entrances = .spaceOnly
        viewModel = WorkspacePickerRecentViewModel(config: config, networkAPI: NetworkAPI.self)
        _ = viewModel.reload()

        NetworkAPI.expectFilter = .wikiOnly
        config.entrances = .wikiOnly
        viewModel = WorkspacePickerRecentViewModel(config: config, networkAPI: NetworkAPI.self)
        _ = viewModel.reload()
    }

}
