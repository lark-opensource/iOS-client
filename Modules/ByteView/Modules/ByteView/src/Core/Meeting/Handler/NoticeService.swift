//
//  NoticeService.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/4/22.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork
import ByteViewMeeting
import ByteViewUI

struct PopupNoticeInfo {
    let noticeID: String
    let messageID: String
    let popupType: VideoChatNotice.PopupType
    let title: String
    let messageContent: String
    let extra: [String: String]
}

struct MSExternalPermChangedInfo {
    let display: Bool
    let seqID: Int
    let shareID: String
}

protocol MeetingNoticeListener: AnyObject {
    func didReceiveDocPermissionPopup(_ info: PopupNoticeInfo)
    func didReceiveBreakoutRoomBroadcast(_ message: String)
    /// 创建纪要后，如果有外部参会人无权限，需要在纪要页面展示时提示创建者
    /// - Parameter content: 提示的内容
    func didReceiveNotesPermissionHint(_ content: String)
}

extension MeetingNoticeListener {
    func didReceiveDocPermissionPopup(_ info: PopupNoticeInfo) {}
    func didReceiveBreakoutRoomBroadcast(_ message: String) {}
    func didReceiveNotesPermissionHint(_ content: String) {}
}

final class NoticeService {
    private(set) static var shared = NoticeService()
    static func destroy() {
        shared = NoticeService()
    }

    private let listeners = Listeners<MeetingNoticeListener>()
    func addListener(_ listener: MeetingNoticeListener) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: MeetingNoticeListener) {
        listeners.removeListener(listener)
    }

    private let interceptors = MeetingNoticeInterceptor()
    func addInterceptor(_ listener: MeetingNoticeInterceptorListener) {
        interceptors.addListener(listener)
    }

    func removeInterceptor(_ listener: MeetingNoticeInterceptorListener) {
        interceptors.removeListener(listener)
    }

    lazy var msExternalPermChangedInfoObservable = msExternalPermChangedInfoRelay.asObservable().compactMap { $0 }

    private var disposeBag = DisposeBag()
    private let msExternalPermChangedInfoRelay = BehaviorRelay<MSExternalPermChangedInfo?>(value: nil)

    let hasReceivedReclaimAlertRelay = BehaviorRelay<ReclaimAlertNotice?>(value: nil)
    lazy var hasReceivedReclaimAlertObservable = hasReceivedReclaimAlertRelay
        .asObservable()
        .compactMap { $0 }
        .filter { !$0.isHandled }

    func handlePushMessage(_ notice: VideoChatNotice, httpClient: HttpClient) {
        switch notice.type {
        case .toast:
            guard !interceptors.checkIfInterceptToast(extra: notice.extra) else {
                break
            }
            let persistingTime = notice.toastDurationMs > 0 ? TimeInterval(notice.toastDurationMs) / 1000 : nil
            httpClient.i18n.get(by: notice.msgI18NKey, defaultContent: notice.message, meetingId: notice.meetingID) {
                Toast.showOnVCScene($0, duration: persistingTime)
            }
        case .popup:
            switch notice.popupType {
            case .popupForceJoin:
                // common popup
                popupNoticeInfo(notice, httpClient: httpClient) { (info) in
                    let cancel = I18n.View_G_CancelButton
                    let confirm = I18n.View_G_ConfirmButton
                    ByteViewDialog.Builder()
                        .id(.forceJoin)
                        .title(info.title)
                        .message(info.messageContent)
                        .leftTitle(cancel)
                        .leftHandler({ _ in
                            httpClient.send(ReplyNoticeRequest(noticeId: info.noticeID, action: .cancel))
                        })
                        .rightTitle(confirm)
                        .rightHandler({ _ in
                            httpClient.send(ReplyNoticeRequest(noticeId: info.noticeID, action: .confirm))
                        })
                        .show()
                }
            case .popupDocPermConfirm:
                popupNoticeInfo(notice, httpClient: httpClient) { [weak self] (info) in
                    self?.listeners.forEach { $0.didReceiveDocPermissionPopup(info) }
                }
            case .noticeExternalPermChanged:
                let display: Bool = notice.extra["display"] == "true"
                let seqID: Int = Int(notice.extra["seq_id"] ?? "") ?? 0
                let shareID: String = notice.extra["share_id"] ?? ""
                let info = MSExternalPermChangedInfo(display: display, seqID: seqID, shareID: shareID)
                if let lastInfo = msExternalPermChangedInfoRelay.value {
                    if shareID == lastInfo.shareID {
                        if seqID >= lastInfo.seqID {
                            // 同一共享的新通知
                            msExternalPermChangedInfoRelay.accept(info)
                        }
                    } else {
                        // 不同共享
                        msExternalPermChangedInfoRelay.accept(info)
                    }
                } else {
                    // 第一条通知
                    msExternalPermChangedInfoRelay.accept(info)
                }
            case .popupManualCallbackHost:
                hasReceivedReclaimAlertRelay.accept(ReclaimAlertNotice())
            case .unknown:
                // 会议纪要-外部参会人权限提示
                if notice.msgI18NKey?.newKey == "View_G_Notes_TurnOnDocExternal_Toast" {
                    Logger.notes.info("did receive notes external notice, key: \(notice.msgI18NKey)")
                    httpClient.i18n.get(by: notice.msgI18NKey,
                                        defaultContent: notice.message,
                                        meetingId: notice.meetingID) { [weak self] content in
                        self?.listeners.forEach { $0.didReceiveNotesPermissionHint(content) }
                    }
                }
            default:
                break
            }
        case .broadcast:
            listeners.forEach { $0.didReceiveBreakoutRoomBroadcast(notice.message) }
        case .alert:
            guard let title = notice.titleI18NKey, let msg = notice.msgI18NKey, let btn = notice.btnI18NKey else { return }
            httpClient.i18n.get([title.newKey, msg.newKey, btn.newKey]) {
                guard let km = $0.value, let btnText = km[btn.newKey] else {
                    return
                }
                let title: String = km[title.newKey] ?? notice.title
                let message: String = km[msg.newKey] ?? notice.message
                guard !title.isEmpty || !message.isEmpty else { return }
                ByteViewDialog.Builder()
                    .needAutoDismiss(true)
                    .title(title)
                    .message(message)
                    .rightTitle(btnText)
                    .show()
            }
        default:
            break
        }
    }

    func handleMsgInfo(_ msg: MsgInfo, httpClient: HttpClient) {
        switch msg.type {
        case .toast:
            let duration = msg.expire > 0 ? TimeInterval(msg.expire) / 1000.0 : nil
            httpClient.i18n.get(by: msg.msgI18NKey, defaultContent: msg.message) {
                Toast.showOnVCScene($0, duration: duration)
            }
        case .popup:
            updateI18NContents([msg.msgTitleI18NKey, msg.msgI18NKey], httpClient: httpClient) { contents in
                guard contents.count == 2 else { return }
                if let title = contents[0], let message = contents[1] {
                    ByteViewDialog.Builder()
                        .id(.netBusinessError)
                        .needAutoDismiss(true)
                        .title(title)
                        .message(message)
                        .rightTitle(I18n.View_G_ConfirmButton)
                        .show()
                }
            }
        case .alert:
            guard let alert = msg.alert, let footer = alert.footer else { return }
            httpClient.i18n.get([alert.title.i18NKey, alert.body.i18NKey, footer.text.i18NKey]) {
                guard let dict = $0.value else { return }
                let title: String? = dict[alert.title.i18NKey]
                let content: String? = dict[alert.body.i18NKey]
                let buttonTitle: String? = dict[footer.text.i18NKey]
                ByteViewDialog.Builder()
                    .id(.netBusinessError)
                    .needAutoDismiss(true)
                    .title(title)
                    .message(content)
                    .rightTitle(buttonTitle)
                    .rightType(.countDown(time: TimeInterval(footer.waitTime)))
                    .show()
            }
        default:
            break
        }
    }

    func handleMeetingEnd() {
        disposeBag = DisposeBag()
    }

    private func popupNoticeInfo(_ notice: VideoChatNotice, httpClient: HttpClient, completion: @escaping (PopupNoticeInfo) -> Void) {
        updateI18NContents([notice.titleI18NKey, notice.msgI18NKey], httpClient: httpClient) { contents in
            guard contents.count == 2 else {
                return
            }
            let title: String = contents[0] ?? notice.title
            let message: String = contents[1] ?? notice.message
            completion(PopupNoticeInfo(noticeID: notice.noticeID, messageID: notice.messageID, popupType: notice.popupType,
                                       title: title, messageContent: message, extra: notice.extra))
        }
    }

    func updateI18NContent(_ i18NKey: I18nKeyInfo?, httpClient: HttpClient, completion: @escaping (String?) -> Void) {
        updateI18NContents([i18NKey], httpClient: httpClient) { contents in
            guard contents.count == 1 else {
                return
            }
            completion(contents[0])
        }
    }

    func updateI18NContents(_ i18NKeys: [I18nKeyInfo?], httpClient: HttpClient, completion: @escaping ([String?]) -> Void) {
        let keys = i18NKeys.compactMap { $0?.newKey }.uniqued()
        let ids: [ParticipantId] = i18NKeys.map { [$0?.i18NParams.pid, $0?.params.pid] }.flatMap { $0 }.compactMap { $0 }.uniqued()
        if let meeting = MeetingManager.shared.currentSession, !ids.isEmpty {
            var i18n: [String: String]?
            var users: [ParticipantUserInfo]?
            let block: () -> Void = { [weak self] in
                guard let templates = i18n, let aps = users else { return }
                let userNames = aps.compactMap { $0 }.reduce(into: [String: String]()) { $0[$1.id] = $1.name }
                var contents: [String?] = []
                for i18NKey in i18NKeys {
                    var content: String?
                    if let i18NKey = i18NKey,
                       let template = templates[i18NKey.newKey] {
                        if userNames.isEmpty {
                            content = template
                        } else {
                            content = self?.replaceI18NNames(template, keyInfo: i18NKey, userNames: userNames)
                        }
                    }
                    contents.append(content)
                }
                completion(contents)
            }
            httpClient.i18n.get(keys) { result in
                if let template = result.value {
                    i18n = template
                    block()
                } else if users != nil {
                    completion(i18NKeys.map { _ in nil })
                }
            }
            httpClient.participantService.participantInfo(pids: ids, meetingId: meeting.meetingId) { aps in
                users = aps
                block()
            }
        } else {
            httpClient.i18n.get(keys) { result in
                guard let template = result.value else {
                    completion(i18NKeys.map { _ in nil })
                    return
                }
                var contents: [String?] = []
                for i18NKey in i18NKeys {
                    var content: String?
                    if let i18NKey = i18NKey {
                        content = template[i18NKey.newKey]
                    }
                    contents.append(content)
                }
                completion(contents)
            }
        }
    }

    private func replaceI18NNames(_ text: String, keyInfo: I18nKeyInfo, userNames: [String: String]) -> String? {
        var s = text
        for (key, value) in keyInfo.i18NParams {
            let pattern = "{{\(key)}}"
            if !s.contains(pattern) { continue }
            switch value.type {
            case .rawText:
                s = s.replacingOccurrences(of: pattern, with: value.val)
            case .userID:
                if let name = userNames[value.val], !name.isEmpty {
                    s = s.replacingOccurrences(of: pattern, with: name)
                } else {
                    break
                }
            default:
                break
            }
        }
        for value in keyInfo.params.values {
            if let name = userNames[value], !name.isEmpty {
                s = s.replacingOccurrences(of: "{{name}}", with: name)
                break
            }
        }
        let array = s.components(separatedBy: "@@")
        if array.count >= 3 {
            s = s.replacingOccurrences(of: "@@\(array[1])@@", with: array[1])
        }
        return s
    }
}

class ReclaimAlertNotice {
    var isHandled: Bool = false
}
