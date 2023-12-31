//
//  MeetingObserver.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/12/6.
//

import Foundation

public protocol MeetingObserverDelegate: AnyObject {
    func meetingObserver(_ observer: MeetingObserver, meetingChanged meeting: Meeting, oldValue: Meeting?)
}

public protocol MeetingObserver: AnyObject {
    /// Retrieve the current meeting list, blocking on initial state retrieval if necessary
    var meetings: [Meeting] { get }

    /// Set delegate for changes. The delegate is stored weakly
    func setDelegate(_ delegate: MeetingObserverDelegate?)
}

public protocol Meeting {
    /// 客户端的sessionId
    var sessionId: String { get }
    /// 会议ID
    var meetingId: String { get }
    /// 会议类型
    var type: MeetingType { get }
    /// 是否忙线会议
    var isPending: Bool { get }
    /// 会议状态（end时会从MeetingObserver.meetings里移除）
    var state: MeetingState { get }
    /// 窗口信息
    var windowInfo: MeetingWindowInfo { get }
    /// 是否关闭麦克风，包含主动、被动/打断
    var isMicrophoneMuted: Bool { get }
    /// 是否关闭摄像头，包含主动、被动/打断
    var isCameraMuted: Bool { get }
    /// 是否开启特效
    var isCameraEffectOn: Bool { get }
    /// 是否正在共享文档，包含自己和别人共享
    var isSharingDocument: Bool { get }
    /// 是否是盒子投屏会议
    var isBoxSharing: Bool { get }
    /// 是否callkit
    var isCallKit: Bool { get }
    /// 会中妙享性能信息
    var magicSharePerformanceInfo: MeetingMagicSharePerfInfo { get }

//    var isSelfSharingScreen: Bool { get }
//    var isOtherSharingScreen: Bool { get }
//    var isSharingScreenToFollow: Bool { get }
//    var isSharingWhiteboard: Bool { get }
}

/// 会议window信息
public protocol MeetingWindowInfo {
    /// 是否存在会议window
    var hasWindow: Bool { get }
    /// 是否小窗
    var isFloating: Bool { get }
    /// 当前是否打开了会议辅助窗口
    var isAuxScene: Bool { get }
    /// 会议窗口所在的scene
    @available(iOS 13.0, *)
    var windowScene: UIWindowScene? { get }
}

public extension MeetingObserver {
    var currentMeeting: Meeting? { meetings.first(where: { !$0.isPending }) }
}

public extension Meeting {
    /// state = end
    var isEnd: Bool { state == .end }
    /// state == .lobby || state == .prelobby
    var isInLobby: Bool { state == .lobby || state == .prelobby }
    /// state != .start && state != .preparing && state != .end
    var isActive: Bool { state != .start && state != .preparing && state != .end }

    func toActiveMeeting() -> Meeting? { self.isActive ? self : nil }
}

public enum MeetingState: String, Hashable, CustomStringConvertible {
    /// 起始状态
    case start
    /// 会前
    case preparing
    /// 拨号（createVideoChat)
    case dialing
    /// 拨号成功后呼叫
    case calling
    /// 响铃
    case ringing
    /// 会前等候室
    case prelobby
    /// 会中等候室
    case lobby
    /// 会中
    case onTheCall
    /// 结束
    case end

    public var description: String { rawValue }
}

public enum MeetingType: String, Hashable, CustomStringConvertible {
    case unknown
    case call
    case meet
    public var description: String { rawValue }
}

/// 会中妙享性能信息
public protocol MeetingMagicSharePerfInfo {
    /// 妙享性能表现总评分
    var level: CGFloat { get }
    /// 系统负载开关评分
    var systemLoadScore: CGFloat { get }
    /// 系统负载动态评分
    var dynamicScore: CGFloat { get }
    /// 设备温度评分
    var thermalScore: CGFloat { get }
    /// 创建文档频率评分
    var openDocScore: CGFloat { get }
}
