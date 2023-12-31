//
//  TagTypeTest.swift
//  LarkTagDevEEUnitTest
//
//  Created by Crazy凡 on 2020/2/19.
//

import Foundation
import XCTest
@testable import LarkTag

class TagTypeTest: XCTestCase {

    func testInit() {
        // 要保证tag顺序，会影响排序权重
        XCTAssertEqual(TagType(rawValue: 0), nil)

        /// 互通
        XCTAssertEqual(TagType(rawValue: 1), .connect)

        /// 外部
        XCTAssertEqual(TagType(rawValue: 2), .external)

        /// 家校
        XCTAssertEqual(TagType(rawValue: 3), .homeSchool)

        /// 免打扰，用在除密聊chat头部以外的地方
        XCTAssertEqual(TagType(rawValue: 4), .doNotDisturb)

        /// 密聊免打扰，只用在密聊chat头部
        XCTAssertEqual(TagType(rawValue: 5), .cryptoDoNotDisturb)

        /// 未注册
        XCTAssertEqual(TagType(rawValue: 6), .unregistered)

        /// 已停用
        XCTAssertEqual(TagType(rawValue: 7), .deactivated)

        /// 账号冻结
        XCTAssertEqual(TagType(rawValue: 8), .isFrozen)

        /// 请假
        XCTAssertEqual(TagType(rawValue: 9), .onLeave)

        /// 值班号
        XCTAssertEqual(TagType(rawValue: 10), .oncall)

        /// 密聊
        XCTAssertEqual(TagType(rawValue: 11), .crypto)

        /// 密聊chat中的加密icon
        XCTAssertEqual(TagType(rawValue: 12), .secretCrypto)

        /// 租户超级管理员（组织架构界面显示）
        XCTAssertEqual(TagType(rawValue: 13), .tenantSuperAdmin)

        /// 租户管理员（组织架构界面显示）
        XCTAssertEqual(TagType(rawValue: 14), .tenantAdmin)

        /// 负责人
        XCTAssertEqual(TagType(rawValue: 15), .supervisor)

        /// 管理员(群主)
        XCTAssertEqual(TagType(rawValue: 16), .groupOwner)

        /// 管理员(群主)
        XCTAssertEqual(TagType(rawValue: 17), .groupAdmin)

        /// 部门
        XCTAssertEqual(TagType(rawValue: 18), .team)

        /// 全员
        XCTAssertEqual(TagType(rawValue: 19), .allStaff)

        /// 新版本
        XCTAssertEqual(TagType(rawValue: 20), .newVersion)

        /// 未读
        XCTAssertEqual(TagType(rawValue: 21), .unread)

        /// 应用
        XCTAssertEqual(TagType(rawValue: 22), .app)

        /// 机器人
        XCTAssertEqual(TagType(rawValue: 23), .robot)

        /// “#”
        XCTAssertEqual(TagType(rawValue: 24), .thread)

        /// 已读
        XCTAssertEqual(TagType(rawValue: 25), .read)

        /// 公开群
        XCTAssertEqual(TagType(rawValue: 26), .public)

        /// 官方服务台
        XCTAssertEqual(TagType(rawValue: 27), .officialOncall)

        /// 服务台“用户”
        XCTAssertEqual(TagType(rawValue: 28), .oncallUser)

        /// 服务台“客服”
        XCTAssertEqual(TagType(rawValue: 29), .oncallAgent)

        /// 群分享历史：已失效
        XCTAssertEqual(TagType(rawValue: 30), .shareDeactivated)

        // helpdesk offline status
        XCTAssertEqual(TagType(rawValue: 31), .oncallOffline)

        // 超大群
        XCTAssertEqual(TagType(rawValue: 32), .superChat)

        // 团队负责人
        XCTAssertEqual(TagType(rawValue: 33), .teamOwner)

        // MARK: - 下面是日历相关的

        /// 日程外部（灰色）
        XCTAssertEqual(TagType(rawValue: 1001), .calendarExternalGrey)

        /// 日程组织者
        XCTAssertEqual(TagType(rawValue: 1002), .calendarOrganizer)

        /// 日程创建者
        XCTAssertEqual(TagType(rawValue: 1003), .calendarCreator)

        /// 日程不参与
        XCTAssertEqual(TagType(rawValue: 1004), .calendarNotAttend)

        /// 日程可选参加
        XCTAssertEqual(TagType(rawValue: 1005), .calendarOptionalAttend)

        /// 日程有冲突
        XCTAssertEqual(TagType(rawValue: 1006), .calendarConflict)

        /// 日程30天内有冲突
        XCTAssertEqual(TagType(rawValue: 1007), .calendarConflictInMonth)

        /// 日程当前地点
        XCTAssertEqual(TagType(rawValue: 1008), .calendarCurrentLocation)

        /// 自定义文本类型
        XCTAssertEqual(TagType(rawValue: 10000), .customTitleTag)

        /// 自定义图片类型
        XCTAssertEqual(TagType(rawValue: 10001), .customIconTag)

        XCTAssertEqual(TagType(rawValue: 10002), nil)
    }

    func testLessThan() {
        XCTAssertTrue(TagType.external < .doNotDisturb)
        XCTAssertTrue(TagType.doNotDisturb < .cryptoDoNotDisturb)
        XCTAssertTrue(TagType.cryptoDoNotDisturb < .unregistered)
        XCTAssertTrue(TagType.unregistered < .deactivated)
        XCTAssertTrue(TagType.deactivated < .isFrozen)
        XCTAssertTrue(TagType.isFrozen < .onLeave)
        XCTAssertTrue(TagType.onLeave < .oncall)
        XCTAssertTrue(TagType.oncall < .crypto)
        XCTAssertTrue(TagType.crypto < .secretCrypto)
        XCTAssertTrue(TagType.secretCrypto < .tenantSuperAdmin)
        XCTAssertTrue(TagType.tenantSuperAdmin < .tenantAdmin)
        XCTAssertTrue(TagType.tenantAdmin < .mainSupervisor)
        XCTAssertTrue(TagType.mainSupervisor < .supervisor)
        XCTAssertTrue(TagType.supervisor < .groupOwner)
        XCTAssertTrue(TagType.groupOwner < .groupAdmin)
        XCTAssertTrue(TagType.groupAdmin < .team)
        XCTAssertTrue(TagType.team < .allStaff)
        XCTAssertTrue(TagType.allStaff < .newVersion)
        XCTAssertTrue(TagType.deactivated < .unread)
        XCTAssertTrue(TagType.unread < .app)
        XCTAssertTrue(TagType.app < .robot)
        XCTAssertTrue(TagType.robot < .thread)
        XCTAssertTrue(TagType.thread < .read)
        XCTAssertTrue(TagType.read < .officialOncall)
        XCTAssertTrue(TagType.officialOncall < .oncallUser)
        XCTAssertTrue(TagType.oncallUser < .oncallAgent)
        XCTAssertTrue(TagType.oncallAgent < .shareDeactivated)
        XCTAssertTrue(TagType.shareDeactivated < .oncallOffline)

        XCTAssertTrue(TagType.oncallOffline < .calendarExternalGrey)
        XCTAssertTrue(TagType.calendarExternalGrey < .calendarOrganizer)
        XCTAssertTrue(TagType.calendarOrganizer < .calendarCreator)
        XCTAssertTrue(TagType.calendarCreator < .calendarNotAttend)
        XCTAssertTrue(TagType.calendarNotAttend < .calendarOptionalAttend)
        XCTAssertTrue(TagType.calendarOptionalAttend < .calendarConflict)
        XCTAssertTrue(TagType.calendarConflict < .calendarConflictInMonth)
        XCTAssertTrue(TagType.calendarConflictInMonth < .calendarCurrentLocation)
        XCTAssertTrue(TagType.calendarCurrentLocation < .customTitleTag)

        XCTAssertTrue(TagType.customTitleTag < .customIconTag)
    }

    func testNoTypeRawValueMoreThanCustomType() {
        for `case` in TagType.allCases {
            XCTAssert(`case` <= .customIconTag, "不应该在Custom后面添加自定义类型")
        }
    }

    func testTitleOrImage() {
        var types = Set(TagType.allCases)
        types.subtract(TagType.titleTypes)
        types.subtract(TagType.iconTypes)
        XCTAssert(types.isEmpty, "不应该有一个Tag类型既不属于title类型，也不属于icon类型")
    }

    func testTagType() {
        XCTAssertEqual(TagType.iconTypes.first, .doNotDisturb)
        XCTAssertEqual(Tag(type: .oncallAgent, style: .red).type, .oncallAgent)
    }

    func testTagWrapperView() {
        XCTAssertNotNil(TagWrapperView.iconTagView(for: Tag.init(type: .doNotDisturb)))
        XCTAssertNotNil(TagWrapperView.titleTagView(for: Tag.init(type: .external)))
    }
}
