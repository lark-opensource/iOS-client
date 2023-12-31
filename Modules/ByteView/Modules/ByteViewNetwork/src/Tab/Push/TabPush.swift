//
//  TabPush.swift
//  ByteViewNetwork
//
//  Created by kiri on 2023/2/16.
//

import Foundation

public struct TabPush {
    /// 最多返回一个正在进行的会议，在已经加入/等候会议室。
    /// - PUSH_VC_MEETING_JOIN_STATUS = 89345
    /// - Command.pushVcMeetingJoinStatus
    public static let meetingJoinStatus = PushReceiver<GetMeetingJoinStatusResponse>()

    /// - PUSH_DYNAMIC_NET_STATUS = 5046
    /// - Command.pushDynamicNetStatus
    public static let dynamicNetStatus = PushReceiver<DynamicNetStatusResponse>()

    /// - PUSH_VC_SYNC_UPCOMING_INSTANCES = 89362
    /// - Command.pushVcSyncUpcomingInstances
    public static let syncUpcomingInstances = PushReceiver<PushSyncUpcomingInstances>()
}

public struct TabServerPush {

    /// VC-Tab红点数据推送
    /// - notifyVcTabMissedCalls = 89211
    public static let missedCalls = PushReceiver<TabMissedCallInfo>()

    /// 推送录制完成
    /// - pushVcTabRecordInfo = 89217
    public static let recordInfo = PushReceiver<RecordCompletedInfo>()
}
