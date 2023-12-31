//
//  LarkNSExtensionByteViewProcessor.swift
//  LarkNotificationServiceExtension
//
//  Created by 刘建龙 on 2019/9/24.
//

import Foundation
import NotificationUserInfo
import UserNotifications
import AudioToolbox
import LarkExtensionServices
import LarkHTTP
#if CALLKIT_ENABLE
import CallKit
#else
import CoreTelephony
#endif

private var msgID: Int32 = Int32(bitPattern: arc4random())
private func getMsgID() -> Int32 {
    msgID &+= 1
    return msgID
}
private var appGroup = Bundle.main.infoDictionary?["EXTENSION_GROUP"] as? String

/// QueryHostAPPState
/// - Returns: 0 active, 1 inactive, 2 background, -1 not running or suspended
private func getHostAPPState() -> Int {
    if let group = appGroup,
       let port = CFMessagePortCreateRemote(kCFAllocatorDefault,
                                            (group + ".host_app_state") as CFString) {
        var data: Unmanaged<CFData>?
        let rc = CFMessagePortSendRequest(port,
                                          getMsgID(),
                                          nil,
                                          0.01,
                                          0.01,
                                          CFRunLoopMode.defaultMode.rawValue,
                                          &data)
        if rc == kCFMessagePortSuccess,
           let receivedData = data?.takeRetainedValue() as Data?,
           receivedData.count == MemoryLayout<Int>.size {
            let intVal = receivedData.withUnsafeBytes { ptr in
                return ptr.load(fromByteOffset: 0, as: Int.self)
            }
            NSLog("[NSE] recieve reply \(intVal)")
            return intVal
        } else {
            NSLog("[NSE] receive data failed \(rc)")
            return -1
        }
    } else {
        NSLog("[NSE] create port failed")
        return -1
    }
}

struct BizByteViewRingingExtra: Decodable {
    var action: String
    var vibrate: Bool

    enum CodingKeys: CodingKey {
        case action
        case vibrate
    }

    init(from decoder: Swift.Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        action = try container.decode(String.self, forKey: .action)
        vibrate = (try? container.decode(Bool.self, forKey: .vibrate)) ?? false
    }
}

private struct ByteViewPushContent: PushContent {
    init?(dict: [String: Any]) {
        self.url = dict["url"] as? String ?? ""
        self.extraStr = dict["extraStr"] as? String ?? ""
    }

    init(url: String, extraStr: String) {
        self.url = url
        self.extraStr = extraStr
    }

    func toDict() -> [String: Any] {
        return ["url": url, "extraStr": extraStr]
    }

    var url: String
    var extraStr: String
}

private final class PlayToken {
    var isCancelled: Bool {
        lock.lock()
        defer {
            lock.unlock()
        }
        return _cancelled
    }
    private var lock = NSLock()
    private var _cancelled: Bool = false
    func cancel() {
        lock.lock()
        _cancelled = true
        lock.unlock()
    }
}

private final class VibratePlayer {
    static var shared: VibratePlayer = VibratePlayer()
    var lock = NSLock()
    var currentToken: PlayToken? {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _token
        }

        set {
            lock.lock()
            defer {
                lock.unlock()
            }
            if _token === newValue {
                return
            }

            _token?.cancel()
            _token = newValue
        }
    }

    private var _token: PlayToken?

    func play(repeatCount: Int, expiration: Date) {
        let token = PlayToken()
        playAux(repeatCount: repeatCount, token: token, expiration: expiration)
        currentToken = token
    }

    private func playAux(repeatCount: Int, token: PlayToken, expiration: Date) {
        guard repeatCount >= 1 && !token.isCancelled && Date() < expiration else {
            return
        }
        AudioServicesPlayAlertSoundWithCompletion(kSystemSoundID_Vibrate) {
            if repeatCount > 1 && !token.isCancelled && Date() < expiration {
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.8) {
                    self.playAux(repeatCount: repeatCount - 1, token: token, expiration: expiration)
                }
            }
        }
    }

    func stop() {
        self.currentToken = nil
    }
}

private extension UNNotificationContent {
    var pushContent: PushContent? {
        guard let extra = LarkNSEExtra.getExtraDict(from: userInfo) else {
            return nil
        }
        var url: String
        let extraStr = extra.extraString ?? ""
        if let chatID = extra.chatId { // 跳转到消息详情
            url = "//client/chat/\(chatID)?fromWhere=push"
            if let position = extra.position {
                url += "&position=\(position)"
            }
        } else if let data = extraStr.data(using: .utf8),
            let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let theURL = dict["url"] as? String { // 动态URL
            url = theURL
        } else {
            url = ""
        }

        return ByteViewPushContent(url: url, extraStr: extraStr)
    }

    var isRecall: Bool {
        return LarkNSEExtra.getExtraDict(from: userInfo)?.isRecall ?? false
    }
}

public final class LarkNSExtensionByteViewProcessor: LarkNSExtensionContentProcessor {
    let pushType: PushType

    public init(pushType: PushType) {
        self.pushType = pushType
    }

    public func transformNotificationExtra(with content: UNNotificationContent) -> Extra? {
        return handleBizExtra(with: content) ??
            Extra(type: pushType,
                  content: content.pushContent ?? ByteViewPushContent(url: "", extraStr: ""),
                  pushAction: content.isRecall ? .removeThenNotice : .noticeImmediatly)
    }

    public func transformNotificationAlter(with content: UNNotificationContent) -> Alert? {
        return Alert(title: content.title,
                     subtitle: content.subtitle,
                     body: content.body,
                     sound: content.sound)
    }

    public func transformNotificationExtra(with content: UNNotificationContent,
                                    relatedContents: [UNNotificationContent]?) -> Extra? {
        if let recallContent = relatedContents?.first(where: { $0.isRecall }) {
            // 乱序
            return Extra(type: pushType,
                         content: recallContent.pushContent ?? ByteViewPushContent(url: "", extraStr: ""),
                         pushAction: .noticeImmediatly)
        }

        return transformNotificationExtra(with: content)
    }

    public func transformNotificationAlter(with content: UNNotificationContent,
                                    relatedContents: [UNNotificationContent]?) -> Alert? {
        if let recallContent = relatedContents?.first(where: { $0.isRecall }) {
            // 乱序
            return Alert(title: recallContent.title,
                         subtitle: recallContent.subtitle,
                         body: recallContent.body,
                         soundName: "silence.m4a")
        }
        return transformNotificationAlter(with: content)
    }
}

extension LarkNSExtensionByteViewProcessor {

    private func handleBizExtra(with content: UNNotificationContent) -> Extra? {
        guard let extra = LarkNSEExtra.getExtraDict(from: content.userInfo),
              let bizExtra = extra.extraString,
              let bizData = bizExtra.data(using: .utf8),
              let bizDict = try? JSONSerialization.jsonObject(with: bizData, options: []) as? [String: Any],
              let action = bizDict["action"] as? String else {
            LarkNSELogger.logger.info("[NSE] parse `extra` failed")
            VibratePlayer.shared.stop()
            return nil
        }

        let useStartCallIntent = getVCNotificationStyleAndTrack(extra)
        // 使用了 INStartCallIntent 就不走以震动处理逻辑
        if useStartCallIntent {
            LarkNSELogger.logger.info("[NSE] handle byteview ringing \(String(describing: extra.extraString))")
            return nil
        }

        if action == "ringing",
           let ringingExtra = try? JSONDecoder().decode(BizByteViewRingingExtra.self, from: bizData) {
            return handleRingingExtra(ringingExtra)
        } else {
            VibratePlayer.shared.stop()
        }
        return nil
    }

    private func handleRingingExtra(_ ringingExtra: BizByteViewRingingExtra) -> Extra? {
        LarkNSELogger.logger.info("[NSE] handle ringing \(ringingExtra.vibrate)")
        // 由后端 FG: byteview.apns.ringing_vibrate.backend 控制
        if ringingExtra.vibrate {
            let hostAppState = getHostAPPState()
            if hostAppState == 2 || hostAppState == -1 {
                // host app is background or not running
                VibratePlayer.shared.play(repeatCount: 8, expiration: Date(timeIntervalSinceNow: 5.0))
            } else {
                VibratePlayer.shared.stop()
            }
        } else {
            VibratePlayer.shared.stop()
        }
        return nil
    }

    private func getVCNotificationStyleAndTrack(_ extra: LarkNSEExtra) -> Bool {
        var useStartCallIntent: Bool = false
        // 处理 byteview 的推送埋点
        if extra.biz == .voip || extra.biz == .vc {
            var meetingCalleeStatus: [String: Any] = [
                "client_receive_time": Int((Date().timeIntervalSince1970 * 1000)),
                "action_name": "receive_call_push",
                "is_voip": 0,
//                "is_new_feat": useStartCallIntent ? 1 : 0,
                "sid": extra.Sid,
                "call_type": extra.biz == .voip ? "call" : "meeting"
            ]

            if let bizExtra = extra.extraString,
               let bizData = bizExtra.data(using: .utf8),
               let bizDict = try? JSONSerialization.jsonObject(with: bizData, options: []) as? [String: Any] {
                if let meetingID = bizDict["meeting_id"] as? String {
                    meetingCalleeStatus["conference_id"] = meetingID
                }
                if let interactiveID = bizDict["interactive_id"] as? String {
                    meetingCalleeStatus["interactive_id"] = interactiveID
                }
                #if swift(>=5.5.2)
                // 仅 iOS 15.2 及以上系统且 start_call_intent == true && action == 'ringing' 才能走通信通知新特性
                if #available(iOSApplicationExtension 15.2, iOS 15.2, *),
                   let action = bizDict["action"] as? String,
                   let startCallIntent = bizDict["start_call_intent"] as? Bool {
                    useStartCallIntent = action == "ringing" && startCallIntent == true
                }
                // 通知增强存在会打断系统音频 bug，苹果 RD 建议在 NSE 里判断是否有通话，
                // 防止打断系统电话、Callkit通话等造成音频无法恢复
                if useStartCallIntent, LarkNSECallProvider.shared.hasActiveCall {
                    LarkNSELogger.logger.info("[NSE] has active call, do not use INStartIntentCall")
                    useStartCallIntent = false
                }
                #endif
            } else {
                LarkNSELogger.logger.info("byteview extra failed: \(extra.extraString ?? "")")
            }
            let isNewFeat = useStartCallIntent && !extra.isNotComm
            meetingCalleeStatus["is_new_feat"] = isNewFeat ? 1 : 0
            HTTP.trackForLark(event: "vc_meeting_callee_status", parameters: meetingCalleeStatus) { response in
                LarkNSELogger.logger.info("[track receive vc notification] \(String(describing: response.text))")
            }
        }

        return useStartCallIntent
    }
}

final class LarkNSECallProvider {
    static let shared = LarkNSECallProvider()
    init() {}

    #if CALLKIT_ENABLE
    private let callObserver = CXCallObserver()

    var hasActiveCall: Bool {
        let calls = callObserver.calls
        let callInfos = calls.map { call in
            call.nseDescription
        }
        LarkNSELogger.logger.info("[NSE] callInfos:\(callInfos)")
        let hasActiveCall = calls.contains { call in
            call.isOnHold || call.hasConnected || !call.hasEnded
        }
        return hasActiveCall
    }
    #else
    @available(*, deprecated)
    private let callCenter = CTCallCenter()

    /// 是否有进行中的通话
    @available(*, deprecated)
    var hasActiveCall: Bool {
        guard let calls = callCenter.currentCalls else {
            return false
        }
        let callInfos = calls.map { call in
            call.nseDescription
        }
        LarkNSELogger.logger.info("[NSE] callInfos:\(callInfos)")
        let hasActiveCall = calls.contains { call in
            let callState = call.callState
            return callState == CTCallStateConnected || callState == CTCallStateDialing || callState == CTCallStateIncoming
        }
        return hasActiveCall
    }
    #endif
}

#if CALLKIT_ENABLE
extension CXCall {
    var nseDescription: String {
        "id:\(uuid) o:\(isOutgoing) h:\(isOnHold) c:\(hasConnected) e:\(hasEnded)"
    }
}
#else
extension CTCall {
    @available(*, deprecated)
    var nseDescription: String {
        "id:\(callID),\(callState)"
    }
}
#endif
