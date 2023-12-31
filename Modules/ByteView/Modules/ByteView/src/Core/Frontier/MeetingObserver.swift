//
//  MeetingObserver.swift
//  ByteView
//
//  Created by kiri on 2023/12/5.
//

import Foundation
import ByteViewCommon
import ByteViewMeeting
import ByteViewNetwork

public protocol MeetingObserverDelegate: AnyObject {
    func meetingObserver(_ observer: MeetingObserver, meetingChanged meeting: MeetingObserver.Meeting, oldValue: MeetingObserver.Meeting?)
}

public final class MeetingObserver {
    private weak var delegate: MeetingObserverDelegate?
    public init() {}

    public var meetings: [MeetingObserver.Meeting] {
        MeetingObserverCenter.shared.fetchMeetings()
    }

    public func setDelegate(_ delegate: MeetingObserverDelegate?) {
        MeetingObserverCenter.shared.addObserver(self)
        self.delegate = delegate
    }

    public var currentMeeting: MeetingObserver.Meeting? {
        meetings.first(where: { !$0.isPending })
    }
}

extension MeetingObserver {
    public struct Meeting: Equatable {
        public let sessionId: String
        public internal(set) var meetingId: String
        public internal(set) var isPending: Bool
        public let isCallKit: Bool
        public internal(set) var state: MeetingState = .start
        public internal(set) var type: MeetingType = .unknown
        public internal(set) var subtype: MeetingSubType = .default
        public internal(set) var meetingSource: VideoChatInfo.MeetingSource = .unknown
        public internal(set) var windowInfo = WindowInfo()
        public internal(set) var isMicrophoneMuted = true
        public internal(set) var isCameraMuted = true
        public internal(set) var isCameraEffectOn = false
        public internal(set) var isBoxSharing = false

        var shareSceneType: InMeetShareSceneType = .none
        public var isSelfSharingScreen: Bool { shareSceneType == .selfSharingScreen }
        public var isOtherSharingScreen: Bool { shareSceneType == .othersSharingScreen }
        public var isSharingDocument: Bool { shareSceneType == .magicShare }
        /// 投屏转妙享
        public var isSharingScreenToFollow: Bool { shareSceneType == .shareScreenToFollow }
        public var isSharingWhiteboard: Bool { shareSceneType == .whiteboard }
        /// 妙享性能数据
        public internal(set) var magicSharePerformanceInfo: MagicSharePerformanceInfo = .initialValue
    }

    /// 会议window信息
    public struct WindowInfo: Equatable, CustomStringConvertible {
        /// 是否存在会议window
        public private(set) var hasWindow: Bool = false
        /// 是否小窗
        public private(set) var isFloating = false
        /// 当前是否打开了会议辅助窗口
        public private(set) var isAuxScene = false

        private weak var _windowScene: AnyObject?
        /// 会议窗口所在的scene
        @available(iOS 13.0, *)
        public var windowScene: UIWindowScene? {
            _windowScene as? UIWindowScene
        }

        mutating func update(_ window: FloatingWindow?) {
            if let window {
                self.hasWindow = true
                self.isFloating = window.isFloating
                if #available(iOS 13.0, *), let ws = window.windowScene {
                    self._windowScene = ws
                    self.isAuxScene = ws.isVcAuxScene
                } else {
                    self._windowScene = nil
                    self.isAuxScene = false
                }
            } else {
                self.hasWindow = false
                self.isFloating = false
                self._windowScene = nil
            }
        }

        public static func == (lhs: WindowInfo, rhs: WindowInfo) -> Bool {
            lhs.hasWindow == rhs.hasWindow
            && lhs.isAuxScene == rhs.isAuxScene
            && lhs.isFloating == rhs.isFloating
            && lhs._windowScene === rhs._windowScene
        }

        public var description: String {
            "WindowInfo(hasWindow: \(hasWindow), isFloating: \(isFloating), isAuxScene: \(isAuxScene))"
        }
    }

    /// 妙享性能信息
    public struct MagicSharePerformanceInfo: Equatable {
        /// 妙享性能表现总评分
        public private(set) var level: CGFloat
        /// 系统负载开关评分
        public private(set) var systemLoadScore: CGFloat
        /// 系统负载动态评分
        public private(set) var dynamicScore: CGFloat
        /// 设备温度评分
        public private(set) var thermalScore: CGFloat
        /// 创建文档频率评分
        public private(set) var openDocScore: CGFloat
        static let initialValue = MagicSharePerformanceInfo(level: 0,
                                                            systemLoadScore: 0,
                                                            dynamicScore: 0,
                                                            thermalScore: 0,
                                                            openDocScore: 0)
    }

}

final class MeetingObserverCenter {
    static let shared = MeetingObserverCenter()
    typealias Meeting = MeetingObserver.Meeting

    private let lock = RwLock()
    private var meetings: [MeetingObserver.Meeting] = []
    private var observers = Listeners<MeetingObserver>()

    func addMeeting(_ session: MeetingSession) {
        let meeting = Meeting(sessionId: session.sessionId, meetingId: session.meetingId,
                              isPending: session.isPending, isCallKit: session.isCallKit)
        lock.withWrite {
            self.meetings.append(meeting)
        }
        Logger.meeting.info("MeetingObserver: Meeting(\(meeting.sessionId)) created, session = \(session)")
        observers.forEach { $0.handleMeetingChanged(meeting, oldValue: nil) }
    }

    func postChanges(for sessionId: String, action: (inout Meeting) -> Void) {
        var oldMeeting: Meeting?
        var changedMeeting: Meeting?
        lock.withWrite {
            guard let (index, old) = self.meetings.enumerated().first(where: { $1.sessionId == sessionId }) else { return }
            oldMeeting = old
            var meeting = old
            action(&meeting)
            if meeting != old {
                if meeting.state == .end {
                    self.meetings.remove(at: index)
                } else {
                    self.meetings[index] = meeting
                }
                changedMeeting = meeting
            }
        }
        if let changedMeeting {
            Logger.meeting.info("MeetingObserver: Meeting(\(changedMeeting.sessionId)) changed to \(changedMeeting)")
            observers.forEach { $0.handleMeetingChanged(changedMeeting, oldValue: oldMeeting) }
        }
    }
}

private extension MeetingObserver {
    func handleMeetingChanged(_ meeting: Meeting, oldValue: Meeting?) {
        self.delegate?.meetingObserver(self, meetingChanged: meeting, oldValue: oldValue)
    }
}

private extension MeetingObserverCenter {
    func addObserver(_ observer: MeetingObserver) {
        self.observers.addListener(observer)
    }

    func fetchMeetings() -> [Meeting] {
        lock.withRead {
            self.meetings
        }
    }
}
