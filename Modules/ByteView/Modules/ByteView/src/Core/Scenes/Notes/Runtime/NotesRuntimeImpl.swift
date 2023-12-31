//
//  NotesRuntimeImpl.swift
//  ByteView
//
//  Created by imac-pro on 2023/5/29.
//

import Foundation
import ByteViewNetwork

final class NotesRuntimeImpl: NotesRuntime, NotesDocumentDelegate {

    let notesDocumentFactory: NotesDocumentFactory

    lazy var notesDocument: NotesDocument = {
        let notesDocument = self.createNotesDocument()
        notesDocument.setDelegate(self)
        return notesDocument
    }()

    weak var notesRuntimeDelegate: NotesRuntimeDelegate?

    let notesUrl: String

    var documentVC: UIViewController {
        notesDocument.docVC
    }

    var status: NotesDocumentStatus {
        notesDocument.status
    }

    init(notesUrl: String, notesDocumentFactory: NotesDocumentFactory) {
        self.notesUrl = notesUrl
        self.notesDocumentFactory = notesDocumentFactory
        notesDocument.setDelegate(self)
    }

    func setDelegate(_ delegate: NotesRuntimeDelegate) {
        self.notesRuntimeDelegate = delegate
    }

    func invoke(command: String, payload: [String: Any]?, callback: NotesInvokeCallBack?) {
        notesDocument.invoke(command: command, payload: payload, callback: callback)
    }

    func updateMeetingInfo(isRecordTipEnabled: Bool, isRecording: Bool, isHostOrCohost: Bool, deviceId: String, meetingId: String, apiVersion: Int64) {
        Logger.notes.info("updateMeetingInfo, isRecordTipEnabled: \(isRecordTipEnabled), isRecording: \(isRecording), isHostOrCohost: \(isHostOrCohost), did: \(deviceId), mid: \(meetingId), apiVersion: \(apiVersion)")
        let payload = generateMeetingInfoPayload(isRecordTipEnabled: isRecordTipEnabled,
                                                 isRecording: isRecording,
                                                 isHostOrCohost: isHostOrCohost,
                                                 deviceId: deviceId,
                                                 meetingId: meetingId,
                                                 apiVersion: apiVersion)
        invoke(command: InMeetNotesKeyDefines.Command.updateMeetingInfo,
               payload: payload,
               callback: nil)
    }

    func updateActiveAgenda(_ agendaInfo: AgendaInfo, pausedAgenda: PausedAgenda, meetingPassedTime: Int64) {
        Logger.notes.info("updateActiveAgenda, agendaInfo: \(agendaInfo), pausedAgenda: \(pausedAgenda), meetingPassedTime: \(meetingPassedTime)")
        let payload = generateAgendaInfoPayload(with: agendaInfo, pausedAgenda: pausedAgenda, meetingPassedTime: meetingPassedTime)
        invoke(command: InMeetNotesKeyDefines.Command.updateAgendaInfo,
               payload: payload,
               callback: nil)
    }

    func showNotesPermissionHint(_ content: String) {
        Logger.notes.info("showNotesPermissionHint, content: \(content)")
        let payload = generateNotesPermissionHintPayload(with: content)
        invoke(command: InMeetNotesKeyDefines.Command.callPassThroughFunc,
               payload: payload,
               callback: nil)
    }

    func openPermissionSettings() {
        Logger.notes.info("openPermissionSettings")
        let payload = generateOpenPermissionSettingsPayload()
        invoke(command: InMeetNotesKeyDefines.Command.callPassThroughFunc,
               payload: payload,
               callback: nil)
    }

    func setQuickShareButtonHidden(_ isHidden: Bool, isTapEnabled: Bool) {
        Logger.notes.info("setQuickShareButtonHidden: \(isHidden), isTapEnabled: \(isTapEnabled)")
        let settings: [String: Any] = [
            "extensions": [
                "mobileHeader": [
                    "vcShareIcon": [
                        "enable": !isHidden,
                        "status": isTapEnabled ? "enable" : "disable"
                    ]
                ]
            ]
        ]
        notesDocument.updateSettingConfig(settings)
    }

    // MARK: - NotesDocumentDelegate

    func docComponent(_ doc: NotesDocument, onInvoke data: [String: Any]?, callback: NotesInvokeCallBack?) {
        notesRuntimeDelegate?.notesRuntime(self, onInvoke: data, callback: callback)
    }

    func docComponent(_ doc: NotesDocument, onEvent event: NotesDocumentEvent) {
        notesRuntimeDelegate?.notesRuntime(self, onEvent: event)
    }

    func docComponent(_ doc: NotesDocument, onOperation operation: NotesDocumentOperation) -> Bool {
        return notesRuntimeDelegate?.notesRuntime(self, onOperation: operation) ?? false
    }

    // MARK: - Private Functions

    private func generateMeetingInfoPayload(isRecordTipEnabled: Bool,
                                            isRecording: Bool,
                                            isHostOrCohost: Bool,
                                            deviceId: String,
                                            meetingId: String,
                                            apiVersion: Int64) -> [String: Any] {
        return ["isRecordTipEnabled": isRecordTipEnabled, // 是否*可以*显示AItip
                "isRecording": isRecording, // 是否已经开始录制或转录
                "isHostOrCohost": isHostOrCohost,
                "deviceId": deviceId,
                "meetingId": meetingId,
                "apiVersion": apiVersion]
    }

    private func generateAgendaInfoPayload(with agendaInfo: AgendaInfo, pausedAgenda: PausedAgenda, meetingPassedTime: Int64) -> [String: Any] {
        return ["activeAgendaInfo": ["agendaID": agendaInfo.agendaID,
                                     "relativeActivatedTime": agendaInfo.relativeActivatedTime,
                                     "duration": agendaInfo.duration,
                                     "suiteVersion": agendaInfo.suiteVersion,
                                     "status": agendaInfo.status.rawValue,
                                     "title": agendaInfo.title,
                                     "realEndTime": agendaInfo.realEndTime],
                "pausedAgenda": ["agendaId": pausedAgenda.agendaID],
                "meetingPassedTime": meetingPassedTime]
    }

    private func generateNotesPermissionHintPayload(with hintContent: String) -> [String: Any] {
        return [InMeetNotesKeyDefines.Params.method: InMeetNotesKeyDefines.Command.showPermissionTips,
                InMeetNotesKeyDefines.Params.payload: ["type": "normal",
                                                       "text": hintContent,
                                                       "textBtn": ["text": I18n.View_G_SetPermissions_Button,
                                                                   "action": "openPermissionSetting"],
                                                       "canClose": true],
                InMeetNotesKeyDefines.Params.callbackCommand: InMeetNotesKeyDefines.Event.closePermissionTips]
    }

    private func generateOpenPermissionSettingsPayload() -> [String: Any] {
        return [
            "method": "lark.biz.permission.openSettingPanel"
        ]
    }
}

extension NotesDocumentFactory {

    func createRuntime(with url: String) -> NotesRuntime {
        assert(Thread.current.isMainThread)
        return NotesRuntimeImpl(notesUrl: url, notesDocumentFactory: self)
    }
}

extension NotesRuntimeImpl {

    func createNotesDocument() -> NotesDocument {
        if let url = URL(string: notesUrl) {
            return notesDocumentFactory.create(url: url, config: NotesAPIConfig(module: "vc", sceneID: "scencID")) ?? DefaultNotesDocument()
        }
        return DefaultNotesDocument()
    }
}

final class DefaultNotesDocument: NotesDocument {

    var docVC: UIViewController = {
        let vc = UIViewController()
        vc.view.backgroundColor = .red
        return vc
    }()

    var status: NotesDocumentStatus = .success

    func setDelegate(_ delegate: NotesDocumentDelegate) {
    }

    func updateSettingConfig(_ settingConfig: [String: Any]) {
    }

    func invoke(command: String, payload: [String: Any]?, callback: NotesInvokeCallBack?) {
    }
}
