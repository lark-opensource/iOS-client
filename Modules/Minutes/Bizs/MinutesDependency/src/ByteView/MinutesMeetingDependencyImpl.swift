//
//  MinutesDependencyImpl.swift
//  MinutesMod
//
//  Created by Supeng on 2021/10/15.
//

import Foundation
import RxSwift
import Swinject
import EENavigator
import LarkContainer
import Minutes
import EEAtomic
import ByteViewInterface

public class MinutesMeetingDependencyImpl: MinutesMeetingDependency {
    private static let didChangeMutexNotificationName = NSNotification.Name("MinutesMeetingDependencyImpl.didChangeMutexNotificationName")
    private static let mutexModuleKey = "currentMutexSessionId"

    private let userResolver: UserResolver
    
    public init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    @AtomicObject
    private var lastActiveSessionId: String?
    private lazy var meetingObserver: MeetingObserver? = {
        let observer = try? userResolver.resolve(assert: MeetingService.self).createMeetingObserver()
        if let observer {
            if let meeting = observer.currentMeeting, meeting.isActive {
                self.lastActiveSessionId = meeting.sessionId
            }
            observer.setDelegate(self)
        }
        return observer
    }()

    public var isInMeeting: Bool {
        if let service = try? userResolver.resolve(assert: MeetingService.self) {
            return service.currentMeeting?.isActive == true
        }
        return false
    }
    
    public var mutexDidChangeNotificationName: NSNotification.Name? {
        _ = meetingObserver
        return Self.didChangeMutexNotificationName
    }

    public var mutexDidChangeNotificationKey: String {
        Self.mutexModuleKey
    }
}

extension MinutesMeetingDependencyImpl: MeetingObserverDelegate {
    public func meetingObserver(_ observer: MeetingObserver, meetingChanged meeting: Meeting, oldValue: Meeting?) {
        if meeting.isPending { return }
        let currentMeeting = meeting.state == .end ? observer.currentMeeting : meeting
        var sessionId: String?
        if let currentMeeting, currentMeeting.isActive {
            sessionId = currentMeeting.sessionId
        }
        if sessionId != self.lastActiveSessionId {
            self.lastActiveSessionId = sessionId
            if let sessionId {
                NotificationCenter.default.post(name: Self.didChangeMutexNotificationName, object: self, userInfo: [Self.mutexModuleKey: sessionId])
            } else {
                NotificationCenter.default.post(name: Self.didChangeMutexNotificationName, object: self)
            }
        }
    }
}
