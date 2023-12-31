//
//  AppLinkHandlers.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkAppLinkSDK
import ByteViewCommon
import ByteViewInterface
import EENavigator
import ByteViewNetwork
import UniverseDesignToast
import LarkRustClient
import LarkShortcut
import ServerPB
import SwiftProtobuf

final class OpenMeetingLinkHandler {

    private static let logger = Logger.getLogger("AppLink")

    func handle(appLink: AppLink) {
        guard let from = appLink.context?.from() else {
            Self.logger.error("applink.context.from is nil")
            return
        }
        let queryParameters = appLink.url.queryParameters
        Self.logger.info("handle applink by OpenMeetingLinkHandler")

        let source = queryParameters["source"]
        let action = queryParameters["action"]
        let candidateid = queryParameters["candidateid"]
        var id = queryParameters["id"]
        if let s = source, let sourceParam = JoinMeetingByLinkBody.Source(rawValue: s),
           sourceParam == .widget || sourceParam == .peopleplatform && (candidateid != nil && !(candidateid?.isEmpty ?? true)) {
            id = ""
        }
        let role = queryParameters["role"]
        let roleParam = role.flatMap { JoinMeetingRole(rawValue: $0) }
        let no = queryParameters["no"]
        var uniqueID: String?
        if let id = queryParameters["uniqueID"] {
            uniqueID = id
        }
        var uid: String?
        if let id = queryParameters["uid"] {
            uid = id
        }
        var originalTime: Int64?
        if let time = queryParameters["originalTime"], let timeInt = Int64(time) {
            originalTime = timeInt
        }
        var instanceStartTime: Int64?
        if let time = queryParameters["instanceStartTime"], let timeInt = Int64(time) {
            instanceStartTime = timeInt
        }
        var instanceEndTime: Int64?
        if let time = queryParameters["instanceEndTime"], let timeInt = Int64(time) {
            instanceEndTime = timeInt
        }

        var idType: JoinMeetingByLinkBody.OpenPlatformIdType
        if let idTypeString = queryParameters["idtype"], let idTypeEnum = JoinMeetingByLinkBody.OpenPlatformIdType(rawValue: idTypeString) {
            idType = idTypeEnum
        } else {
            idType = .unknown
        }
        var preview: Bool
        if let previewString = queryParameters["preview"], let previewInt = Int(previewString) {
            preview = previewInt == 1 ? true : false
        } else {
            preview = true
        }
        var mic: Bool?
        if let micString = queryParameters["mic"], let micInt = Int(micString) {
            mic = micInt == 1 ? true : false
        }
        var speaker: Bool?
        if let speakerString = queryParameters["speaker"], let speakerInt = Int(speakerString) {
            speaker = speakerInt == 1 ? true : false
        }
        var camera: Bool?
        if let cameraString = queryParameters["camera"], let cameraInt = Int(cameraString) {
            camera = cameraInt == 1 ? true : false
        }
        var isE2Ee: Bool?
        if let isE2EeString = queryParameters["isE2Ee"], let isE2EeInt = Int(isE2EeString) {
            isE2Ee = isE2EeInt == 1 ? true : false
        }

        guard let s = source, let sourceParam = JoinMeetingByLinkBody.Source(rawValue: s),
              let a = action, let actionParam = JoinMeetingByLinkBody.Action(rawValue: a),
              let idParam = id else {
            let errorLog = "handle applink error by unsupported param: source = \(String(describing: source)), action = \(String(describing: action)), id = \(String(describing: id))"
            Self.logger.error(errorLog)
            return
        }

        let body = JoinMeetingByLinkBody(source: sourceParam,
                                         action: actionParam,
                                         id: idParam,
                                         no: no,
                                         uniqueID: uniqueID,
                                         uid: uid,
                                         originalTime: originalTime,
                                         instanceStartTime: instanceStartTime,
                                         instanceEndTime: instanceEndTime,
                                         role: roleParam,
                                         idType: idType,
                                         preview: preview,
                                         candidateid: candidateid,
                                         mic: mic,
                                         speaker: speaker,
                                         camera: camera,
                                         isE2Ee: isE2Ee)
        Navigator.currentUserNavigator.push(body: body, from: from)
    }
}

final class OpenByteViewSettingsLinkHandler {
    private static let logger = Logger.getLogger("AppLink")

    func handle(appLink: AppLink) {
        guard let from = appLink.context?.from() else {
            Self.logger.error("applink.context.from is nil")
            return
        }
        let queryParameters = appLink.url.queryParameters
        let source = queryParameters["source"]
        Self.logger.info("handle applink by OpenByteViewSettingsLinkHandler, source = \(source ?? "<nil>")")
        let body = ByteViewSettingsBody(source: source)
        Navigator.currentUserNavigator.push(body: body, from: from)
    }
}

final class LiveCertLinkHandler {
    private static let logger = Logger.getLogger("AppLink")

    func handle(appLink: AppLink) {
        guard let from = appLink.context?.from()?.fromViewController else {
            Self.logger.error("handleLiveCertLink failed: from is nil")
            return
        }
        let token = appLink.url.queryParameters["token"]
        Self.logger.info("handle applink by LiveCertLinkHandler, token is nil? \(token == nil)")
        Navigator.currentUserNavigator.present(body: MeetingLiveCertBody(token: token ?? "defaultToken"), from: from)
    }
}

final class MyAIActionLinkHandler {
    private typealias VcMyAiActionData = ServerPB_Videochat_my_ai_VcMyAIActionData
    private static let logger = Logger.getLogger("AppLink")

    func handle(appLink: AppLink) {
        guard let from = appLink.context?.from()?.fromViewController else {
            Self.logger.error("MyAIActionLinkHandler failed: from is nil")
            return
        }
        guard let rawData = appLink.url.queryParameters["raw_data"], let data = Data(base64Encoded: rawData) else {
            Self.logger.info("MyAIActionLinkHandler, decode data failed")
            return
        }
        do {
            let topMost = from.view.window ?? from.view
            var options = BinaryDecodingOptions()
            options.discardUnknownFields = true
            let actionData = try VcMyAiActionData(serializedData: data, options: options)
            let meetingId = actionData.meetingID
            let resolver = Container.shared.getCurrentUserResolver()
            guard let session = try? resolver.resolve(assert: MeetingService.self).currentMeeting, session.isActive,
                  session.meetingId == meetingId else {
                Util.runInMainThread { [weak topMost] in
                    if let topMost {
                        UDToast.showTips(with: I18n.View_M_CantDoNotinMeeting_Desc, on: topMost)
                    }
                }
                Self.logger.error("MyAIActionLinkHandler failed: meeting not found, meetingId = \(meetingId)")
                return
            }
            Self.logger.info("handle my ai action: \(actionData)")
            switch actionData.apiType {
            case .serverApi:
                guard let cmd = ServerCommand(rawValue: Int(actionData.serverCommand)) else {
                    Self.logger.error("MyAIActionLinkHandler failed: can't resolve RustService or ServerCommand")
                    return
                }
                let rust = try resolver.resolve(assert: RustService.self)
                let contextId = uuid()
                let logger = Logger.getLogger("MyAI").withContext(contextId).withTag("[\(cmd)][\(session.sessionId)]")
                logger.info("MyAIActionLinkHandler sendRustRequest start")
                var packet = RawRequestPacket(serCommand: cmd, message: actionData.payload)
                packet.parentID = contextId
                packet.contextIdGenerationCallback = {
                    logger.info("MyAIActionLinkHandler createRequestPacket, fullContextId = \($0)")
                }
                rust.async(packet) { (response: ResponsePacket<Data>) in
                    switch response.result {
                    case .success:
                        logger.info("MyAIActionLinkHandler sendRustRequest success")
                        Util.runInMainThread { [weak topMost] in
                            if let topMost {
                                UDToast.showTips(with: I18n.View_G_DoneYourCommand_Toast, on: topMost)
                            }
                        }
                    case .failure(let error):
                        logger.error("MyAIActionLinkHandler sendRustRequest failed: error = \(error)")
                    }
                }
            case .clientApi:
                let shortcut: Shortcut
                switch actionData.action {
                case .startRecoring:
                    let action = StartRecordAction(meetingId: meetingId, isFromNotes: true)
                    shortcut = Shortcut(name: "VcMyAiAction.startRecord", actions: [action])
                default:
                    Self.logger.error("MyAIActionLinkHandler call clientApi failed: error = unsupportedAction \(actionData.action)")
                    return
                }
                let service = try resolver.resolve(assert: ShortcutService.self)
                let contextId = uuid()
                let logger = Logger.getLogger("MyAI").withContext(contextId).withTag("[\(actionData.action)][\(session.sessionId)]")
                logger.info("MyAIActionLinkHandler sendShortcutRequest start")
                let request = ShortcutRequest(requestId: contextId, shortcut: shortcut)
                service.getClient(.myai).sendRequest(request) { response in
                    switch response {
                    case .success:
                        logger.info("MyAIActionLinkHandler sendShortcutRequest success")
                    case .failure(let error):
                        logger.error("MyAIActionLinkHandler sendShortcutRequest failed: error = \(error)")
                    }
                }
            @unknown default:
                Self.logger.error("MyAIActionLinkHandler failed: unknown VcMyAiAction \(actionData.apiType)")
            }
        } catch {
            Self.logger.error("MyAIActionLinkHandler failed: \(error)")
        }
    }

    func uuid() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...6).map { _ in letters.randomElement() ?? letters[letters.startIndex] })
    }
}
