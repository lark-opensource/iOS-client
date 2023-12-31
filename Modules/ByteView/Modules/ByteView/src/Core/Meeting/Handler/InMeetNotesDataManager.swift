//
//  InMeetNotesDataManager.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/5/11.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewSetting
import ByteViewUI

protocol InMeetNotesDataListener: AnyObject {
    /// 会议纪要变化
    func didChangeNotesInfo(_ notes: NotesInfo?, oldValue: NotesInfo?)
    /// 外部参会人提示
    func didHintNotesPermission(_ content: String)
    /// notes 页面状态开关变更
    func didChangeNotesOn(_ isOn: Bool)
}

extension InMeetNotesDataListener {
    func didChangeNotesInfo(_ notes: NotesInfo?, oldValue: NotesInfo?) {}
    func didHintNotesPermission(_ content: String) {}
    func didChangeNotesOn(_ isOn: Bool) {}
}

/// 会议纪要数据管理器
/// - 处理服务端推送的会议纪要数据，推送会议纪要数据的变化
final class InMeetNotesDataManager: VideoChatCombinedInfoPushObserver, MeetingNoticeListener {

    private let info: VideoChatInfo
    private let session: MeetingSession
    private let settings: MeetingSettingManager
    private let listeners = Listeners<InMeetNotesDataListener>()

    @RwAtomic
    /// 日程信息
    var calendarInfo: CalendarInfo?

    /// 本场会议的会议信息
    @RwAtomic private var inMeetingInfo: VideoChatInMeetingInfo?
    /// 会议纪要信息
    @RwAtomic var notesInfo: NotesInfo?
    /// 已经自动打开过纪要
    /// 此变量无需存储在Session，这样从等候室重新入会还会自动打开Notes
    @RwAtomic var hasTriggeredAutoOpen: Bool = false
    /// notes 页面是否打开
    @RwAtomic private(set) var isNotesOn: Bool = false {
        didSet {
            listeners.forEach({ $0.didChangeNotesOn(isNotesOn) })
        }
    }

    private var meetType: MeetingType { inMeetingInfo?.vcType ?? info.type }

    init(session: MeetingSession, info: VideoChatInfo, settings: MeetingSettingManager) {
        self.session = session
        self.info = info
        self.settings = settings
        session.push?.combinedInfo.addObserver(self)
        NoticeService.shared.addListener(self)
        startNotesSceneMonitor()
    }

    deinit {
        stopNotesSceneMonitor()
    }

    // MARK: - Listeners

    func addListener(_ listener: InMeetNotesDataListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately {
            fireListenerOnAdd(listener)
        }
    }

    func removeListener(_ listener: InMeetNotesDataListener) {
        listeners.removeListener(listener)
    }

    private func fireListenerOnAdd(_ listener: InMeetNotesDataListener) {
        listener.didChangeNotesInfo(notesInfo, oldValue: nil)
        listener.didChangeNotesOn(isNotesOn)
    }

    // MARK: - VideoChatCombinedInfoPushObserver

    func didReceiveCombinedInfo(inMeetingInfo: VideoChatInMeetingInfo, calendarInfo: CalendarInfo?) {
        self.inMeetingInfo = inMeetingInfo
        self.calendarInfo = calendarInfo
        handleNotesInfo(inMeetingInfo.notesInfo)
    }

    // MARK: - MeetingNoticeListener

    func didReceiveNotesPermissionHint(_ content: String) {
        session.shouldShowPermissionHint = true
        session.permissionHintContent = content
        listeners.forEach { $0.didHintNotesPermission(content) }
    }

    // MARK: - inner funcs

    private func handleNotesInfo(_ notesInfo: NotesInfo?) {
        guard let setting = session.setting else { return }
        guard setting.isMeetingNotesEnabled && !setting.isCrossWithKa else { return }
        guard notesInfo != nil else { return }
        var modifiedNotesInfo = notesInfo
        let notesUrlWithParams = generateNotesUrl(from: modifiedNotesInfo?.notesURL)
        modifiedNotesInfo?.notesURL = notesUrlWithParams
        let oldNotesInfo = self.notesInfo
        let newNotesInfo = modifiedNotesInfo
        guard oldNotesInfo != newNotesInfo else { return }
        checkNewAgendaHint(newNotesInfo)
        self.notesInfo = newNotesInfo
        Logger.notes.info("did change notesInfo to: \(newNotesInfo), from: \(oldNotesInfo)")
        listeners.forEach { $0.didChangeNotesInfo(newNotesInfo, oldValue: oldNotesInfo) }
    }

    /// 拼接参数，生成notes链接
    private func generateNotesUrl(from notesUrl: String?) -> String {
        guard let rawUrl = notesUrl else { return "" }
        var modifiedUrl: String = ""
        if !rawUrl.isEmpty, rawUrl.contains("?") {
            modifiedUrl = rawUrl + "&agenda_platform=vc_ios&scene=agenda&sub_scene=\(subScene)&doc_app_id=101"
        } else {
            modifiedUrl = rawUrl + "?agenda_platform=vc_ios&scene=agenda&sub_scene=\(subScene)&doc_app_id=101"
        }
        return modifiedUrl
    }

    /// 检查是否需要显示新议程提示
    private func checkNewAgendaHint(_ newNotesInfo: NotesInfo?) {
        if let newInfo = newNotesInfo,
           !newInfo.activatingAgenda.agendaID.isEmpty,
           newInfo.activatingAgenda.status == .start {
            if newInfo.activatingAgenda.agendaID == newInfo.pausedAgenda.agendaID { // 说明当前议程被暂停了，下次无论开启哪个议程都应该提示
                session.lastHintAgendaID = nil
            } else if newInfo.activatingAgenda.agendaID != session.lastHintAgendaID {
                session.shouldShowNewAgendaHint = true
                session.lastHintAgendaID = newInfo.activatingAgenda.agendaID
            }
        }
    }

    @objc private func handleNotesSceneChange() {
        Util.runInMainThread { [weak self] in
            guard let self = self, #available(iOS 13.0, *), VCScene.supportsMultipleScenes else { return }
            let scene = VCScene.connectedScene(scene: InMeetNotesKeyDefines.generateNotesSceneInfo(with: self.session.meetingId))
            let isOn = scene?.activationState == .foregroundActive
            self.setNotesOn(isOn)
        }
    }
}

// 供外部获取的计算属性
extension InMeetNotesDataManager {

    /// 已生成会议纪要，即存在有效的NotesInfo
    var hasCreatedNotes: Bool {
        if let notes = notesInfo, URL(string: notes.notesURL) != nil {
            return true
        }
        return false
    }

    /// 当前会议纪要中的高亮议程版本号
    var currentNotesInfoVersion: Int64 {
        return notesInfo?.activatingAgenda.suiteVersion ?? -1
    }

    /// 当前场景参数，分为1v1、日程会议与即时会议
    var subScene: String {
        if meetType == .call {
            return InMeetNotesKeyDefines.MeetType.vcCallMeeting
        } else if info.meetingSource == .vcFromCalendar {
            return InMeetNotesKeyDefines.MeetType.vcCalendarMeeting
        } else {
            return InMeetNotesKeyDefines.MeetType.vcNormalMeeting
        }
    }

    /// 通过纪要链接获取的token
    var urlToken: String {
        guard let url = notesInfo?.notesURL else {
            return ""
        }
        return url.vc.removeParams().components(separatedBy: "/").last ?? ""
    }

}

// notes 页面状态变更
extension InMeetNotesDataManager {
    func setNotesOn(_ isOn: Bool) {
        isNotesOn = isOn
    }

    private func startNotesSceneMonitor() {
        if #available(iOS 13.0, *), VCScene.supportsMultipleScenes {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleNotesSceneChange),
                                                   name: UIScene.didActivateNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleNotesSceneChange),
                                                   name: UIScene.willDeactivateNotification,
                                                   object: nil)
        }
    }

    private func stopNotesSceneMonitor() {
        if #available(iOS 13.0, *), VCScene.supportsMultipleScenes {
            NotificationCenter.default.removeObserver(self, name: UIScene.didActivateNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIScene.willDeactivateNotification, object: nil)
        }
    }
}
