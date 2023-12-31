//
//  EmptyFilterShouldWithMsgFilterIntegrationTest.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/9/25.
//

import XCTest
import RustPB
@testable import LarkFeed

// MARK: 【自定义分组】【IM】操作删除所有分组只展示消息分组，操作重启app多次，固定feed入口消失
// https://meego.feishu.cn/larksuite/issue/detail/6096322
// 服务端分组数据为空时，端上没有进行兜底处理，导致没有分组展示
final class EmptyFilterShouldWithMsgFilterIntegrationTest: XCTestCase {

    func testFixedFilterOnlyShowMsgFilter() {

        let feedFilters: [Feed_V1_FeedFilter] = []
        let feedFilterInfos: [Feed_V1_FeedFilterInfo] = []

        let vaildUsedFilters = FiltersModel.getVaildUsedFilters(feedFilters, true, [:])
        XCTAssertEqual(1, vaildUsedFilters.count)

        let vaildUsedInfos = FiltersModel.getVaildUsedFilters(feedFilterInfos, true, [:])
        XCTAssertEqual(1, vaildUsedFilters.count)
    }
}
