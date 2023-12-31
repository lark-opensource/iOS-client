//
//  MeetingSettingWaitableItem.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/7/22.
//

import Foundation

public struct MeetingSettingWaitableItem: CustomStringConvertible, Hashable {
    private let rawValue: String
    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let firstFetch = MeetingSettingWaitableItem("firstFetch")
    public static let onTheCallFetch = MeetingSettingWaitableItem("onTheCallFetch")
    public static let firstCombinedInfo = MeetingSettingWaitableItem("firstCombinedInfo")

    static let callMePhone = MeetingSettingWaitableItem("callMePhone")
    static let rtcFeatureGating = MeetingSettingWaitableItem("rtcFeatureGating")
    static let adminOrgSettings = MeetingSettingWaitableItem("adminOrgSettings")
    static let appConfig = MeetingSettingWaitableItem("appConfig")
    static let videoChatConfig = MeetingSettingWaitableItem("videoChatConfig")
    static let adminMediaServerSettings = MeetingSettingWaitableItem("adminMediaServerSettings")
    static let suiteQuota = MeetingSettingWaitableItem("suiteQuota")
    static let viewUserSetting = MeetingSettingWaitableItem("viewUserSetting")
    static let adminSettings = MeetingSettingWaitableItem("adminSettings")
    static let adminPermissionInfo = MeetingSettingWaitableItem("adminPermissionInfo")

    static let subtitleSettings = MeetingSettingWaitableItem("subtitleSettings")
    static let meetingSuiteQuota = MeetingSettingWaitableItem("meetingSuiteQuota")
    static let sponsorAdminSettings = MeetingSettingWaitableItem("sponsorAdminSettings")

    public var description: String { rawValue }
}
