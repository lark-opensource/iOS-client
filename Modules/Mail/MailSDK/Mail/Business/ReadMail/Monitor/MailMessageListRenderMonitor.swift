//
//  MailMessageListDomReadyMonitor.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2020/9/21.
//

import Foundation
import ThreadSafeDataStructure

private enum MessageListRenderResult: Int {
    // 正常渲染
    case normal = 0
    // 返回白屏
    case back_not_render = 1
    // 超时白屏
    case timeout = 2
    // 误判, timeout 后渲染成功
    case normalDelay = 3
    // 左右滑，取消了加载
    case swipe_not_render = 4
}

private enum MessageListRenderState: Int {
    case loading
    case domReady
    case timeout
}

private class MailMessageListRenderEvent: Hashable {
    let threadID: String
    let timeoutInterval: TimeInterval
    var hasLogged = false

    private var beginTime: TimeInterval
    private(set) var datalen: UInt
    private(set) var renderTime: Int = -1
    private(set) var timeoutTimer: Timer?

    var state: MessageListRenderState = .loading

    init(threadID: String, datalen: UInt, beginTime: TimeInterval, timeoutInterval: TimeInterval, timeoutcallback: @escaping () -> Void) {
        self.threadID = threadID
        self.datalen = datalen
        self.beginTime = beginTime
        self.timeoutInterval = timeoutInterval
        self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { (timer) in
            timer.invalidate()
            timeoutcallback()
        }
    }

    func updateRenderTime() {
        renderTime = Int((Date().timeIntervalSince1970 - beginTime) * 1000)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(threadID)
    }

    static func == (lhs: MailMessageListRenderEvent, rhs: MailMessageListRenderEvent) -> Bool {
        return lhs.threadID == rhs.threadID
    }
}

class MailMessageListRenderMonitor {

    private let enterTime: TimeInterval
    private var events: Set<MailMessageListRenderEvent> = []

    typealias MailRenderTimeout = (dataLen: Int, time: TimeInterval)

    // timeouts sorted in ascending order by DataLen
    private lazy var sortedRenderTimeouts: [MailRenderTimeout]? = {
        guard let renderTimeout = ProviderManager.default.commonSettingProvider?.arrayValue(key: "renderTimeout") as? [[String: Int]] else {
            return nil
        }

        return renderTimeout.compactMap { (dict) -> MailRenderTimeout? in
            guard let dataLen = dict["dataLen"], let time = dict["time"] else {
                return nil
            }
            return (dataLen, TimeInterval(time) / 1000.0)
        }.sorted(by: { $0.dataLen < $1.dataLen })
    }()

    init() {
        enterTime = Date().timeIntervalSince1970
    }

    func start(threadID: String, datalen: UInt) {
        if let preEvent = getEvent(threadID: threadID) {
            preEvent.timeoutTimer?.invalidate()
            events.remove(preEvent)
        }

        // create event
        let event = MailMessageListRenderEvent(threadID: threadID, datalen: datalen,
                                               beginTime: Date().timeIntervalSince1970,
                                               timeoutInterval: timeoutInterval(dataLen: datalen),
                                               timeoutcallback: { [weak self] in
                                                self?.update(threadID: threadID, newState: .timeout)
        })
        events.insert(event)
        update(threadID: threadID, newState: .loading)
    }

    func onDomReady(threadID: String) {
        update(threadID: threadID, newState: .domReady)
    }

    func onExit() {
        let readtime = Int((Date().timeIntervalSince1970 - enterTime) * 1000)
        if let event = events.first(where: { $0.state == .loading }) {
            log(event: event, result: .back_not_render, readtime: readtime)
        }
    }

    func onSwipe(_ threadID: String) {
        let readtime = Int((Date().timeIntervalSince1970 - enterTime) * 1000)
        if let event = events.first(where: { $0.threadID == threadID }) {
            MailMessageListController.logger.info("DomreadyMonitor on swipe \(threadID)")
            event.timeoutTimer?.invalidate()
            switch event.state {
            case .loading:
                log(event: event, result: .swipe_not_render, readtime: readtime)
            case .domReady, .timeout:
                break
            }
            events.remove(event)
        }
    }
}

extension MailMessageListRenderMonitor {
    private func timeoutInterval(dataLen: UInt) -> TimeInterval {
        let defaultTimeoutInterval: TimeInterval = 5
        guard let sortedRenderTimeouts = sortedRenderTimeouts else {
            MailLogger.log(level: .info, message: "renderTimeouts not fetched from settings")
            return defaultTimeoutInterval
        }

        let settingInterval = (sortedRenderTimeouts.first(where: { dataLen < $0.dataLen })?.time ?? 0)
        return (settingInterval > 0) ? settingInterval: defaultTimeoutInterval
    }

    private func getEvent(threadID: String) -> MailMessageListRenderEvent? {
        return events.first(where: { $0.threadID == threadID })
    }

    private func log(event: MailMessageListRenderEvent, result: MessageListRenderResult, readtime: Int? = nil) {
        guard !event.hasLogged || result == .normalDelay else { return }
        event.hasLogged = true
        event.timeoutTimer?.invalidate()

        switch result {
        case .timeout, .back_not_render, .swipe_not_render:
            break
        case .normal, .normalDelay:
            event.updateRenderTime()
        }

        var params: [String: Any] = ["ret": result.rawValue,
                                      "datalen": event.datalen,
                                      "rendertime": event.renderTime,
                                      "timeout": Int(event.timeoutInterval * 1000)]
        if let readtime = readtime {
            params["readtime"] = readtime
        }

        MailTracker.log(event: "mail_webview_render", params: params)
        var paramsStr = ""
        for (key, value) in params {
            paramsStr = paramsStr + "\(key):\(String(describing: value)),"
        }
        MailLogger.log(level: .info, message: "mail_webview_render \(paramsStr) \(event.threadID)")
    }

    private func update(threadID: String, newState: MessageListRenderState) {
        guard let event = getEvent(threadID: threadID) else { return }

        let previousState = event.state
        event.state = newState
        switch newState {
        case .loading:
            break
        case .domReady:
            if previousState == .timeout {
                log(event: event, result: .normalDelay)
            } else {
                log(event: event, result: .normal)
            }
        case .timeout:
            log(event: event, result: .timeout)
        }
    }
}
