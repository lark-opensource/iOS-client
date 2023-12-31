//
//  ByteViewWidgetService.swift
//  ByteViewWidget
//
//  Created by shin on 2023/2/13.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//

import ByteViewCommon
import ByteViewTracker
import ByteViewWidget

#if swift(>=5.7.1)
import ActivityKit

private struct UpdateContainer {
    var createdDate: Date
    var activityID: String
    var contentState: MeetingContentState
    var alert: AlertConfig?
}

@available(iOS 16.1, *)
private final class VCWidgetService {
    static let shared = VCWidgetService()
    /// 后台最大更新次数
    static let maxUpdateLimit = Int.max // 40
    /// 更新间隔
    static let updateInterval = 0.0 // 5.0
    /// meet 仅展示进行中
    static let onlyShowOnGoing = true // false

    @RwAtomic
    fileprivate var lastUpdateDate: Date?
    @RwAtomic
    fileprivate var lastUpdateContent: UpdateContainer?
    @RwAtomic
    fileprivate var lastState: MeetingContentState?
    @RwAtomic
    fileprivate var updateCount: Int = 0
    @RwAtomic
    fileprivate var activity: Activity<MeetingAttributes>?

    var activities: [Activity<MeetingAttributes>] {
        Activity<MeetingAttributes>.activities
    }

    init() {}

    func findActivity(_ activityID: String) -> Activity<MeetingAttributes>? {
        activities.first { $0.id == activityID }
    }

    func reset() {
        activity = nil
        lastUpdateDate = nil
        lastUpdateContent = nil
        lastState = nil
        updateCount = 0
    }
}
#endif

public enum ByteViewWidgetService {
    /// 是否可以发起 Live Activity
    public static var areActivitiesEnabled: Bool {
#if swift(>=5.7.1)
        guard #available(iOS 16.3, *), Self.areActivitiesApiCallable else {
            return false
        }
        return ActivityAuthorizationInfo().areActivitiesEnabled
#else
        return false
#endif
    }

    /// M 系列芯片，调用灵动岛 api 会直接 crash，调用前需要判断是否可用
    public static var areActivitiesApiCallable: Bool {
        #if swift(>=5.7.1)
        // 与 PM 沟通，16.3 灵动岛比较稳定，从 16.3 开始支持
        guard #available(iOS 16.3, *), !Util.isiOSAppOnMacSystem else {
            return false
        }
        return true
        #else
        return false
        #endif
    }

    static let logger = Logger.getLogger("LiveActivity")

    public static func request(data: MeetingWidgetData, state: MeetingContentState) -> String? {
#if swift(>=5.7.1)
        guard #available(iOS 16.1, *), Self.areActivitiesApiCallable else {
            return nil
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Self.logger.warn("activity auth disenabled")
            return nil
        }

        VCWidgetService.shared.reset()
        let attributes = data.activityAttributes()
        var activityID: String?
        do {
            let activity = try Activity.request(attributes: attributes, contentState: state)
            VCWidgetService.shared.activity = activity
            activityID = activity.id
            Self.logger.info("request activity succceed, id: \(String(describing: activityID))")
        } catch {
            Self.logger.error("request activity error: \(error)")
        }
        return activityID
#else
        return nil
#endif
    }

    public static func update(_ activityID: String, state: MeetingContentState, alert: AlertConfig? = nil) {
#if swift(>=5.7.1)
        guard #available(iOS 16.1, *), Self.areActivitiesApiCallable else {
            return
        }
        // 灵动岛在后台有更新次数限制，类似 Widget 策略，所以在后台时候，需要限制
        let isBackgroud = AppInfo.shared.applicationState == .background
        if VCWidgetService.shared.lastState == state, isBackgroud {
            Self.logger.info("same state, not update in bkg")
            return
        }

        if isBackgroud, VCWidgetService.shared.updateCount > VCWidgetService.maxUpdateLimit {
            Self.logger.info("ignore update activity limit: \(activityID)")
            return
        }

        let now = Date()
        let interval = VCWidgetService.updateInterval
        if let lastUpdateDate = VCWidgetService.shared.lastUpdateDate, now.timeIntervalSince1970 - lastUpdateDate.timeIntervalSince1970 < interval {
            VCWidgetService.shared.lastUpdateContent = UpdateContainer(
                createdDate: now,
                activityID: activityID,
                contentState: state,
                alert: alert
            )
            Self.logger.info("delay update activity: \(activityID)")
            return
        }

        guard activityID == VCWidgetService.shared.activity?.id else {
            Self.logger.warn("update error, not found activity \(activityID)")
            return
        }

        VCWidgetService.shared.lastState = state
        VCWidgetService.shared.lastUpdateDate = now
        Self.logger.info("update activity \(activityID), state: \(state)")
        Task(priority: .high) {
            if let activity = VCWidgetService.shared.activity {
                await activity.update(using: state, alertConfiguration: alert?.alertConfiguration())
            }
        }

        if isBackgroud {
            VCWidgetService.shared.updateCount += 1
        }

        VCWidgetService.shared.lastUpdateContent = nil
        if interval == 0.0 {
            return
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(Int(interval))) {
            guard let updateContent = VCWidgetService.shared.lastUpdateContent else {
                return
            }
            if let lastUpdateDate = VCWidgetService.shared.lastUpdateDate, lastUpdateDate >= updateContent.createdDate {
                return
            }
            let lastContent = VCWidgetService.shared.lastUpdateContent
            guard let activityID = lastContent?.activityID, let state = lastContent?.contentState else {
                return
            }
            Self.update(activityID, state: state, alert: lastContent?.alert)
        }
#endif
    }

    public static func end(activityID: String) {
#if swift(>=5.7.1)
        guard #available(iOS 16.1, *), Self.areActivitiesApiCallable else {
            return
        }

        guard activityID == VCWidgetService.shared.activity?.id else {
            Self.logger.warn("end error, not found activity \(activityID)")
            return
        }
        Self.logger.info("end activity \(activityID), bkg update \(VCWidgetService.shared.updateCount)")
        Task(priority: .high) {
            if let activity = VCWidgetService.shared.activity {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
#endif
    }

    public static func forceEndAllActivities(_ reason: String? = nil) {
#if swift(>=5.7.1)
        guard #available(iOS 16.1, *), Self.areActivitiesApiCallable else {
            return
        }

        Self.logger.info("end all activities via \(reason ?? "unkown"), bkg update \(VCWidgetService.shared.updateCount)")
        Task(priority: .high) {
            for activity in Activity<MeetingAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
#endif
    }
}
