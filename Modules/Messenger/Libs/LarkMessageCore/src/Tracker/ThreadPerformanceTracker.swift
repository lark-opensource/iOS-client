//
//  PerformanceTracker.swift
//  LarkThread
//
//  Created by lizhiqiang on 2020/1/15.
//

import UIKit
import Foundation
import LKCommonsTracker
import LarkSDKInterface
import LKCommonsLogging
import AppReciableSDK
import LarkModel
import LarkMessengerInterface

public enum ThreadSourceType: Int {
    case Unknown = 0
    // 话题详情
    case Topic = 3
    //话题页面
    case Thread = 5
}

public final class ThreadPerformanceTracker {
    private static let shared = ThreadPerformanceTracker()

    private static let logger = Logger.log(ThreadPerformanceTracker.self, category: "LarkThread")

    private var startEnter: Double = 0
    private var uiRenderStart: Double = 0
    private var dataRenderStart: Double = 0

    private var uiRenderCost: Double = 0
    private var requestCost: Double = 0
    private var parseCost: Double = 0
    private var contextIDs: String = ""

    private static let groupLoadTime = "group_load_time"
    private static let groupRecommendLoadTime = "group_recommend_load_time"
    private static let groupDetailLoadTime = "group_detail_load_time"

    private let queue = DispatchQueue(label: "lark.thread.performance.tracker.queue", qos: .background)
    private var fromWhere: ChatFromWhere = .ignored
    private var enterBackground: Bool = false

    private init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterBackgroundHandle),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func enterBackgroundHandle() {
        self.enterBackground = true
    }

    public static func startEnter(fromWhere: ChatFromWhere = .ignored) {
        let start = CACurrentMediaTime()
        self.shared.queue.async {
            self.shared.startEnter = start
            self.shared.uiRenderStart = 0
            self.shared.uiRenderCost = 0
            self.shared.requestCost = 0
            self.shared.parseCost = 0
            self.shared.contextIDs = ""
            self.shared.fromWhere = fromWhere
            self.shared.enterBackground = false
        }
    }

    /// not supprot nested
    public static func startUIRender() {
        let time = CACurrentMediaTime()
        self.shared.queue.async {
            self.shared.uiRenderStart = time
        }
    }

    /// not supprot nested
    public static func endUIRender() {
        guard self.shared.uiRenderCost == 0 else {
            return
        }
        let start = CACurrentMediaTime()
        self.shared.queue.async {
            self.shared.uiRenderCost = start - self.shared.uiRenderStart
        }
    }

    /// not supprot nested
    public static func startDataRender() {
        let time = CACurrentMediaTime()
        self.shared.queue.async {
            self.shared.dataRenderStart = time
        }
    }

    public static func updateRequestCost(trackInfo: ThreadRequestTrackInfo) {
        self.shared.queue.async {
            self.shared.requestCost += trackInfo.requestCost
            self.shared.parseCost += trackInfo.parseCost
            let preContextID = self.shared.contextIDs.isEmpty ? "" : (self.shared.contextIDs + "_")
            self.shared.contextIDs = preContextID + trackInfo.contextId
        }
    }
    // Thread页面的耗时埋点
    public static func trackThreadLoadTime(chat: Chat?, pageName: String) {
        trackLoadTime(by: groupLoadTime, chat: chat, pageName: pageName)
    }
    // Thread推荐页的耗时
    public static func trackRecommendThreadLoadTime() {
        self.shared.queue.async {
            self.trackLoadTime(by: groupRecommendLoadTime)
        }
    }

    // threadDetial页面的耗时埋点
    public static func trackThreadDetailLoadTime(chat: Chat?, pageName: String) {
        self.shared.queue.async {
            self.trackLoadTime(by: groupDetailLoadTime, chat: chat, pageName: pageName)
        }
    }

    public static func trackLoadTime(by key: String, chat: Chat? = nil, pageName: String = "") {
        let now = CACurrentMediaTime()
        self.shared.queue.async {
            #if DEBUG
            return
            #endif
            // swiftlint:disable all
            let lantency = Int((now - self.shared.startEnter) * 1000)
            let sdk_cost = Int(self.shared.requestCost * 1000)
            let client_data_cost = Int(self.shared.parseCost * 1000)
            let client_render_cost = Int((now - self.shared.dataRenderStart) * 1000)

            let metric: [String: Any] = [
                "latency": lantency,
                "sdk_cost": sdk_cost,
                "client_data_cost": client_data_cost,
                "client_render_cost": client_render_cost
            ]

            /// 这里打日志 -> 方便后续排查问题 拉取本地日志
            let chatID = chat?.id ?? ""
            self.logger.info(
                    """
                    chatID: \(chatID) threadTrackLoadTime:
                    \(key): \(metric)
                    """
            )

            if (key == groupLoadTime || key == groupDetailLoadTime), let chat = chat {
                let latencyDetail: [String: Any] = ["sdk_cost": sdk_cost,
                                                    "client_data_cost": client_data_cost,
                                                    "client_render_cost": client_render_cost,
                                                    "first_render": Int(self.shared.uiRenderCost * 1000)]
                var type: ThreadSourceType = .Unknown
                if key == groupLoadTime {
                    type = .Thread
                } else if key == groupDetailLoadTime {
                    type = .Topic
                }
                AppReciableSDK.shared.timeCost(params: TimeCostParams(biz: .Messenger,
                                                                      scene: .Thread,
                                                                      event: .enterChat,
                                                                      cost: lantency,
                                                                      page: pageName,
                                                                      extra: Extra(isNeedNet: false,
                                                                                   latencyDetail: latencyDetail,
                                                                                   metric: reciableExtraMetric(chat),
                                                                                   category: reciableExtraCategory(chat, type: type))))
            }
            // swiftlint:enable all
        }
    }

    public static func reciableExtraMetric(_ chat: Chat?) -> [String: Any] {
        guard let chat = chat else { return [:] }
        return ["chatter_count": chat.userCount,
                "feed_id": chat.id]
    }

    public static func reciableExtraCategory(_ chat: Chat?, type: ThreadSourceType) -> [String: Any] {
        guard let chat = chat else {
            return ["source_type": self.shared.fromWhere.sourceTypeForReciableTrace,
                    "chat_type": type.rawValue,
                    "is_background": self.shared.enterBackground]
        }
        return ["source_type": self.shared.fromWhere.sourceTypeForReciableTrace,
                "chat_type": type.rawValue,
                "is_background": self.shared.enterBackground,
                "is_external": chat.isCrossTenant,
                "is_metting": chat.isMeeting]
    }
}
