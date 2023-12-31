//
//  TestI18n.swift
//  LarkTagDevEEUnitTest
//
//  Created by Crazy凡 on 2021/1/29.
//

import Foundation
import XCTest
@testable import LarkTag

// 为了保证单侧覆盖率
class I18nTypeTest: XCTestCase {
    func testAllKey() {
        typealias I18n = LarkTag.BundleI18n.LarkTag

        XCTAssertEqual(I18n.Lark_Legacy_TagExternal, I18n.Lark_Legacy_TagExternal())
        XCTAssertEqual(I18n.Lark_Legacy_TagCalendarOrganizer, I18n.Lark_Legacy_TagCalendarOrganizer())
        XCTAssertEqual(I18n.Lark_Legacy_TagCalendarCreator, I18n.Lark_Legacy_TagCalendarCreator())
        XCTAssertEqual(I18n.Lark_Legacy_TagCalendarNotAttend, I18n.Lark_Legacy_TagCalendarNotAttend())
        XCTAssertEqual(I18n.Lark_Legacy_TagCalendarOptionalAttend, I18n.Lark_Legacy_TagCalendarOptionalAttend())
        XCTAssertEqual(I18n.Lark_Legacy_TagCalendarConfliect, I18n.Lark_Legacy_TagCalendarConfliect())
        XCTAssertEqual(I18n.Lark_Legacy_TagCalendarConfliectInMonth, I18n.Lark_Legacy_TagCalendarConfliectInMonth())
        XCTAssertEqual(I18n.Lark_Legacy_TagCalendarCurrentLocation, I18n.Lark_Legacy_TagCalendarCurrentLocation())
        XCTAssertEqual(I18n.Lark_Legacy_ReadStatus, I18n.Lark_Legacy_ReadStatus())
        XCTAssertEqual(I18n.Lark_Group_CreateGroup_TypeSwitch_Public, I18n.Lark_Group_CreateGroup_TypeSwitch_Public())
        XCTAssertEqual(I18n.Lark_Search_AppLabel, I18n.Lark_Search_AppLabel())
        XCTAssertEqual(I18n.Lark_HelpDesk_AgentIcon, I18n.Lark_HelpDesk_AgentIcon())
        XCTAssertEqual(I18n.Lark_HelpDesk_UserIcon, I18n.Lark_HelpDesk_UserIcon())
        XCTAssertEqual(I18n.Lark_Group_InvitationDeactivated, I18n.Lark_Group_InvitationDeactivated())
        XCTAssertEqual(I18n.Lark_Chat_OfficialTag, I18n.Lark_Chat_OfficialTag())
        XCTAssertEqual(I18n.Lark_Status_TeamTag, I18n.Lark_Status_TeamTag())
        XCTAssertEqual(I18n.Lark_Status_ExternalTag, I18n.Lark_Status_ExternalTag())
        XCTAssertEqual(I18n.Lark_Status_DeactivatedTag, I18n.Lark_Status_DeactivatedTag())
        XCTAssertEqual(I18n.Lark_Status_AllStaffTag, I18n.Lark_Status_AllStaffTag())
        XCTAssertEqual(I18n.Lark_Status_SupervisorTag, I18n.Lark_Status_SupervisorTag())
        XCTAssertEqual(I18n.Lark_Status_OnLeaveTag, I18n.Lark_Status_OnLeaveTag())
        XCTAssertEqual(I18n.Lark_Status_AdminTag, I18n.Lark_Status_AdminTag())
        XCTAssertEqual(I18n.Lark_Status_BotTag, I18n.Lark_Status_BotTag())
        XCTAssertEqual(I18n.Lark_Status_TagUnread, I18n.Lark_Status_TagUnread())
        XCTAssertEqual(I18n.Lark_Status_TagUnregistered, I18n.Lark_Status_TagUnregistered())
        XCTAssertEqual(I18n.Lark_Core_SuperAdministratorLable, I18n.Lark_Core_SuperAdministratorLable())
        XCTAssertEqual(I18n.Lark_Core_RegularAdministratorLable, I18n.Lark_Core_RegularAdministratorLable())
        XCTAssertEqual(I18n.Lark_Education_SchoolParentGroupLabel, I18n.Lark_Education_SchoolParentGroupLabel())
        XCTAssertEqual(I18n.Lark_Profile_AccountPausedLabel, I18n.Lark_Profile_AccountPausedLabel())
        XCTAssertEqual(I18n.Lark_Group_ConnectGroupLabel, I18n.Lark_Group_ConnectGroupLabel())
        XCTAssertEqual(I18n.Lark_Group_GroupAdministratorLabel, I18n.Lark_Group_GroupAdministratorLabel())
    }
}
