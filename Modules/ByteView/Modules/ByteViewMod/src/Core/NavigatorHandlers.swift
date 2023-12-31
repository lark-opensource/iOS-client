//
//  NavigatorHandlers.swift
//  LarkByteView
//
//  Created by LUNNER on 2019/5/6.
//

import Foundation
import EENavigator
import LarkAccountInterface
import LKCommonsTracker
import LarkNavigation
import LarkTab
import LarkNavigator
import RunloopTools
import LarkSetting
import LarkContainer
import UniverseDesignToast
import ByteView
import ByteViewSetting
import ByteViewCommon
import ByteViewNetwork
import ByteViewInterface
import ByteViewLiveCert
import ByteViewUI
import LarkUIKit

final class StartMeetingHandler: UserTypedRouterHandler {
    func handle(_ body: StartMeetingBody, req: EENavigator.Request, res: Response) {
        let logger = Logger.interface
        let from = req.from.fromViewController
        let fail = req.context["fail"] as? ((ByteViewInterface.MeetingError?) -> Void)
        logger.info("start meeting with body: \(body), from: \(String(describing: from))")
        do {
            let dependency = try MeetingDependencyImpl(userResolver: userResolver)
            let source = MeetingEntrySource(rawValue: body.entrySource.rawValue)
            if body.isCall {
                // 通过开放平台uniqueId开启1v1会议
                if let uniqueId = body.uniqueId, let isVoiceCall = body.isVoiceCall {
                    MeetingFrontier.startCall(.init(openPlatform: uniqueId, isVoiceCall: isVoiceCall), dependency: dependency, from: from)
                } else if let userId = body.userId, let isVoiceCall = body.isVoiceCall {
                    MeetingFrontier.startCall(.init(id: userId, source: source, isVoiceCall: isVoiceCall, secureChatId: body.secureChatId, isE2EeMeeting: body.isE2Ee, onError: { error in
                        if let handler = fail {
                            switch error {
                            case .collaborationBeBlocked:
                                handler(.collaborationBeBlocked)
                            case .collaborationBlocked:
                                handler(.collaborationBlocked)
                            case .collaborationNoRights:
                                handler(.collaborationNoRights)
                            default:
                                handler(.otherError)
                            }
                        }
                    }), dependency: dependency, from: from)
                } else {
                    logger.error("start 1v1 fail, because StartMeetingBody‘s parameter is missing!")
                }
            } else {
                MeetingFrontier.startMeeting(.init(source: source), dependency: dependency, from: from)
            }
            res.end(resource: EmptyResource())
        } catch {
            fail?(.otherError)
            logger.error("start meeting with body: \(body) failed, \(error)")
            res.end(error: error)
        }
    }
}

final class JoinMeetingHandler: UserTypedRouterHandler {
    func handle(_ body: JoinMeetingBody, req: EENavigator.Request, res: Response) {
        let logger = Logger.interface
        let from = req.from.fromViewController
        logger.info("join meeting with body: \(body), from: \(String(describing: from))")
        do {
            let source = MeetingEntrySource(rawValue: body.entrySource.rawValue)
            var isWebinar: Bool = false
            if let subtype = body.meetingSubtype {
                isWebinar = subtype == MeetingSubType.webinar.rawValue
            }
            switch body.idType {
            case .meetingId:
                try startPreview(.init(meetingId: body.id, source: source, topic: body.topic ?? "", isE2EeMeeting: body.isE2Ee, chatID: body.chatId, messageID: body.messageId, isWebinar: isWebinar), from: from)
            case .number:
                try startPreview(.init(meetingNumber: body.id, source: source, isWebinar: isWebinar), from: from)
            case .group:
                try startPreview(.init(group: body.id, source: source, isE2EeMeeting: body.isE2Ee, isFromSecretChat: body.isFromSecretChat, isJoinMeeting: !body.isStartMeeting, isWebinar: isWebinar), from: from)
            case .interview:
                try startPreview(.init(interview: body.id, role: body.role?.pbType, isWebinar: isWebinar), from: from)
            case .openPlatform:
                try startPreview(.init(openPlatform: body.id, preview: body.preview ?? true, isWebinar: isWebinar, mic: body.mic, speaker: body.speaker, camera: body.camera), from: from)
            @unknown default:
                logger.error("join meeting with body: \(body) failed, unsupported idType \(body.idType)")
            }
            res.end(resource: EmptyResource())
        } catch {
            logger.error("join meeting with body: \(body) failed, \(error)")
            res.end(error: error)
        }
    }

    private func startPreview(_ params: StartMeetingParams, from: UIViewController?,
                              file: String = #fileID, function: String = #function, line: Int = #line) throws {
        let dependency = try MeetingDependencyImpl(userResolver: userResolver)
        MeetingFrontier.startMeeting(params, dependency: dependency, from: from, file: file, function: function, line: line)
    }
}

private extension JoinMeetingRole {
    var pbType: Participant.Role? {
        switch self {
        case .interviewee:
            return .interviewee
        case .interviewer:
            return .interviewer
        @unknown default:
            return nil
        }
    }
}

final class JoinMeetingByCalendarHandler: UserTypedRouterHandler {
    func handle(_ body: JoinMeetingByCalendarBody, req: EENavigator.Request, res: Response) {
        let logger = Logger.interface
        let from = req.from.fromViewController
        logger.info("join meeting by calendar with body: \(body), from: \(String(describing: from))")
        do {
            let instance = CalendarInstanceIdentifier(uid: body.uid, originalTime: body.originalTime, instanceStartTime: body.instanceStartTime, instanceEndTime: body.instanceEndTime)
            let source = MeetingEntrySource(rawValue: body.entrySource.rawValue)
            let dependency = try MeetingDependencyImpl(userResolver: userResolver)
            let params = StartMeetingParams(calendar: body.uniqueId, source: source, topic: body.title, fromLink: body.linkScene, instance: instance, isJoinMeeting: !body.isStartMeeting, isWebinar: body.isWebinar)
            MeetingFrontier.startMeeting(params, dependency: dependency, from: from)
            res.end(resource: EmptyResource())
        } catch {
            logger.error("join meeting by calendar with body: \(body) failed, \(error)")
            res.end(error: error)
        }
    }
}

final class ShareContentHandler: UserTypedRouterHandler {
    func handle(_ body: ShareContentBody, req: EENavigator.Request, res: Response) throws {
        let logger = Logger.interface
        let from = req.from.fromViewController
        logger.info("startSharingContentToRoom with body: \(body), from: \(String(describing: from))")
        let source = MeetingEntrySource(rawValue: body.source.rawValue)
        let dependency = try MeetingDependencyImpl(userResolver: userResolver)
        MeetingFrontier.startShareToRoom(source: source, dependency: dependency, from: from)
        res.end(resource: EmptyResource())
    }
}

final class PhoneCallHandler: UserTypedRouterHandler {
    func handle(_ body: PhoneCallBody, req: EENavigator.Request, res: Response) throws {
        let logger = Logger.interface
        let from = req.from.fromViewController
        logger.info("startPhoneCall with body \(body), from: \(String(describing: from))")
        let params = PhoneCallParams(id: body.id, idType: try body.idType.toMeeting(), calleeId: body.calleeId, calleeName: body.calleeName, calleeAvatarKey: body.calleeAvatarKey)
        let dependency = try MeetingDependencyImpl(userResolver: userResolver)
        MeetingFrontier.startPhoneCall(params, dependency: dependency, from: from)
        res.end(resource: EmptyResource())
    }
}

final class PhoneCallPickerHandler: UserTypedRouterHandler {
    func handle(_ body: PhoneCallPickerBody, req: EENavigator.Request, res: Response) throws {
        let logger = Logger.interface
        guard let from = req.from.fromViewController else {
            logger.error("handle \(body) failed, from is nil")
            throw RouterError.cannotPresent
        }
        let params = PhoneCallParams(id: body.phoneNumber, idType: try body.phoneType.toMeeting())
        let dependency = try MeetingDependencyImpl(userResolver: userResolver)
        MeetingFrontier.showPhoneCallPicker(params, dependency: dependency, from: from)
        res.end(resource: EmptyResource())
    }
}

final class JoinInterviewHandler: UserTypedRouterHandler {
    func handle(_ body: JoinInterviewBody, req: EENavigator.Request, res: Response) {
        res.redirect(body: JoinMeetingBody(id: body.id, idType: .interview, entrySource: .interview, role: body.role))
    }
}

final class JoinMeetingByLinkHandler: UserTypedRouterHandler {
    func handle(_ body: JoinMeetingByLinkBody, req: EENavigator.Request, res: Response) {
        Logger.interface.info("handle JoinMeetingByLinkHandler, source: \(body.source)")
        switch body.source {
        case .interview:
            if let role = body.role {
                res.redirect(body: JoinMeetingBody(id: body.id, idType: .interview, entrySource: .interview, role: role))
            } else {
                res.end(error: RouterError.invalidParameters("role"))
            }
        case .calendar:
            if let instance = body.calendarInstance {
                let body = JoinMeetingByCalendarBody(
                    uniqueId: instance.uniqueID,
                    uid: instance.uid,
                    originalTime: instance.originalTime,
                    instanceStartTime: instance.instanceStartTime,
                    instanceEndTime: instance.instanceEndTime,
                    title: nil, entrySource: .calendarDetails,
                    linkScene: true, isStartMeeting: false, isWebinar: false)
                res.redirect(body: body)
            }
        case .openplatform:
            switch body.idType {
            case .reservationid:
                switch body.action {
                case .join:
                    res.redirect(body: JoinMeetingBody(id: body.id, idType: .openPlatform, entrySource: .openPlatform, preview: body.preview, mic: body.mic, speaker: body.speaker, camera: body.camera))
                case .call:
                    let isVoiceCall = !(body.camera == true)
                    res.redirect(body: StartMeetingBody(uniqueId: body.id, isVoiceCall: isVoiceCall, entrySource: .openPlatform1v1, isE2Ee: body.isE2Ee ?? false))
                default:
                    res.end(resource: EmptyResource())
                }
            default:
                res.end(resource: EmptyResource())
            }
        case .widget:
            switch body.action {
            case .start:
                res.redirect(body: StartMeetingBody(entrySource: .widgetCreateMeeting))
            case .join:
                res.redirect(body: JoinMeetingBody(id: "", idType: .number, entrySource: .widgetJoinMeeting))
            case .opentab:
                RunloopDispatcher.shared.addTask(priority: .medium) {
                    self.userResolver.navigator.switchTab(Tab.byteview.url, from: req.from, animated: true, completion: nil)
                }
                res.end(resource: EmptyResource())
            default:
                res.end(resource: EmptyResource())
            }
        case .peopleplatform:
            switch body.action {
            case .call:
                res.redirect(body: PhoneCallBody(id: body.candidateid ?? "", idType: .candidateId))
            default:
                res.end(resource: EmptyResource())
            }
        @unknown default:
            res.end(resource: EmptyResource())
        }
    }
}

final class JoinMeetingByMeetingNoHandler: UserTypedRouterHandler {
    private static let logger = Logger.interface
    func handle(_ body: JoinMeetingByMeetingNoBody, req: EENavigator.Request, res: Response) {
        res.redirect(body: JoinMeetingBody(id: body.no, idType: .number, entrySource: .landingPageLink))
    }
}

final class JoinMeetingByMyAIHandler: UserTypedRouterHandler {

    func handle(_ body: JoinMeetingByMyAIBody, req: EENavigator.Request, res: Response) {
        guard let from = req.from.fromViewController,
              let service = try? userResolver.resolve(assert: MeetingService.self) else { return }
        Logger.interface.info("join meeting with body: \(body), from: \(String(describing: from))")
        if let session = service.currentMeeting, session.meetingId == body.meetingId {
            startPreview(StartMeetingParams(meetingNumber: body.meetingNumber, source: MeetingEntrySource(rawValue: VCMeetingEntry.myAI.rawValue), isWebinar: false), from: from)
        } else {
            userResolver.navigator.push(body: MeetingTabBody(source: .chat, action: .detail, meetingID: body.meetingId), from: from)
            Logger.interface.info("JoinMeetingHandler rediret to MeetingTab")
        }
        res.end(resource: EmptyResource())
    }

    private func startPreview(_ params: StartMeetingParams, from: UIViewController?,
                              file: String = #fileID, function: String = #function, line: Int = #line) {
        do {
            let dependency = try MeetingDependencyImpl(userResolver: userResolver)
            MeetingFrontier.startMeeting(params, dependency: dependency, from: from, file: file, function: function, line: line)
        } catch {
            Logger.interface.error("join meeting with body: JoinMeetingByMyAIBody failed, \(error)")
        }
    }
}

final class ByteViewAppSchemaHandler: UserRouterHandler {
    func handle(req: EENavigator.Request, res: Response) {
        let meetingNumber = req.url.queryParameters["no"] ?? getMeetingNumber(by: req.url.path)
        if let meetingId = req.url.queryParameters["meetingId"], req.url.queryParameters["source"] == "vc_myai" {
            res.redirect(body: JoinMeetingByMyAIBody(meetingNumber: meetingNumber, meetingId: meetingId))
        } else {
            res.redirect(body: JoinMeetingBody(id: meetingNumber, idType: .number, entrySource: .msgLink))
        }
        res.end(resource: EmptyResource())
    }

    private func getMeetingNumber(by path: String) -> String {
        let replace = path.trimmingCharacters(in: .whitespaces)
        let pattern = "[0-9]{1,9}"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let matchStrings = regex?.matches(replace)

        var numberString = ""
        for number in matchStrings ?? [] {
            numberString.append(number)
        }
        return numberString
    }

    static func isMatch(url: URL) -> Bool {
        guard let config = try? SettingManager.shared.setting(with: MeetingUrlKeys.self, key: UserSettingKey.make(userKeyLiteral: "vc_meeting_url_keys")) else {
            return false
        }
        let hosts = config.meetingUrlKeys
        let paths = config.meetingUrlPathKeys
        guard let host = url.host, hosts.contains(host) else {
            return false
        }

        for pattern in paths {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return false
            }
            let path = url.path
            let range = NSRange(location: 0, length: path.count)
            guard regex.matches(in: path, range: range).first != nil else {
                continue
            }
            return true
        }
        return false
    }

    private struct MeetingUrlKeys: Decodable {
        let meetingUrlKeys: [String]
        let meetingUrlPathKeys: [String]

    }
}

class ByteViewUrlTrackHandler: UserRouterHandler {
    static func verifyURL(url: URL, hosts: [String]?, pathRule: [String]) -> Bool {
        if let hosts = hosts {
            guard let host = url.host, hosts.contains(host) else {
                return false
            }
        }

        let path = url.path
        for pattern in pathRule {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
                return false
            }
            let range = NSRange(location: 0, length: path.count)
            guard regex.matches(in: path, range: range).first != nil else {
                continue
            }
            return true
        }
        return false
    }

    static func test(req: EENavigator.Request, linkSource: String) -> Bool {
        if let scene = (req.context["scene"] as? String), scene == "messenger" {
            Logger.interface.info("click link of \(linkSource)")
            Tracker.post(TeaEvent("link_clicked", params: ["link_source": linkSource]))
        }
        return false
    }

    func handle(req: EENavigator.Request, res: Response) {
        res.end(error: nil)
    }
}

final class VideoChatPromptHandler: UserTypedRouterHandler {
    func handle(_ body: VideoChatPromptBody, req: EENavigator.Request, res: Response) {
        switch body.source {
        case .calendar:
            guard let from = req.context.from(), let url = URL(string: "//client/calendar/event/detailWithUniqueId") else {
                return
            }
            Logger.interface.info("gotoCalendarDetail: \(body.id)")
            userResolver.navigator.push(url, context: ["uniqueId": body.id, "videoStartTimeStamp": 0], from: from)
        @unknown default:
            Logger.interface.error("source not supported: \(body.source.rawValue)")
        }
        res.end(resource: EmptyResource())
    }
}

final class ByteViewSettingsHandler: UserTypedRouterHandler {
    func handle(_ body: ByteViewSettingsBody, req: EENavigator.Request, res: Response) throws {
        let service = try req.getUserResolver().resolve(assert: UserSettingManager.self)
        let vc = service.ui.createGeneralSettingViewController(source: body.source)
        res.end(resource: vc)
    }
}

final class VCCalendarSettingsHandler: UserTypedRouterHandler {
    func handle(_ body: VCCalendarSettingsBody, req: EENavigator.Request, res: Response) throws {
        let cid = ByteViewNetwork.CalendarInstanceIdentifier(uid: body.uid,
                                                             originalTime: body.originalTime,
                                                             instanceStartTime: body.instanceStartTime,
                                                             instanceEndTime: body.instanceEndTime)
        let context = CalendarSettingContext(type: .edit(body.uniqueID, cid))
        let service = try userResolver.resolve(assert: UserSettingManager.self).ui
        res.end(resource: service.createCalendarSettingViewController(context: context))
    }
}

final class MeetingLiveCertHandler: UserTypedRouterHandler {
    func handle(_ body: MeetingLiveCertBody, req: EENavigator.Request, res: Response) throws {
        guard let from = req.from.fromViewController else {
            throw RouterError.notHandled
        }
        let service = try userResolver.resolve(assert: CertService.self)
        service.handleLiveCertLink(token: body.token, from: from, wrap: LkNavigationController.self)
        res.end(resource: EmptyResource())
    }
}

final class FloatWindowHandler: UserMiddlewareHandler {
    private lazy var whiteListPrefix = {
        var settings = self.getSettings() ?? [
            "/client/chat/by/chat", // 加急
            "/client/todo/detail", // todo 任务
            "/client/extension/share", // 分享
            "/client/scan" // 扫一扫
        ]
        // 临时在代码层面放开对模板页面的自动小窗处理，后续修改平台参数 #tbd:liurundong.henry
        if let index = settings.firstIndex(of: "/client/docs/template") {
            settings.remove(at: index)
        }
        return settings
    }()

    func handle(req: EENavigator.Request, res: Response) {
        guard self.whiteListPrefix.contains(where: { req.url.relativeString.contains($0) }) && !hitBlackList(req: req) else {
            return
        }
        Logger.interface.info("Floating or dismiss ByteView window with url = \(req.url.safeURLString)")
        try? userResolver.resolve(assert: MeetingService.self).floatingOrDismissWindow()
    }

    private func getSettings() -> [String]? {
        do {
            return try userResolver.resolve(assert: SettingService.self).setting(with: [String].self, key: UserSettingKey.make(userKeyLiteral: "vc_floating_window_path_config"))
        } catch {
            Logger.network.error("failed decoding settings vc_floating_window_path_config, error: \(error)")
        }
        return nil
    }

    private func hitBlackword(_ url: URL) -> Bool {
        let from = url.queryParameters["from"]
        let pathFrom = URL(string: url.queryParameters["path"] ?? "")?.queryParameters["from"]
        Logger.interface.info("Floating or dismiss queryParameters from: \(String(describing: from)), pathFrom: \(String(describing: pathFrom))")
        return from == "lark_profile" || pathFrom == "larkProfile"
    }

    private func hitBlackList(req: EENavigator.Request) -> Bool {
        if hitBlackword(req.url) { return true }
        if let viewControllers = req.from.fromViewController?.navigationController?.viewControllers, viewControllers.contains(where: { type(of: $0).description() == "ByteView.PreviewParticipantsViewController" }) {
            return true
        }
        return false
    }
}

private extension PhoneCallBody.IdType {
    func toMeeting() throws -> PhoneCallParams.IdType {
        switch self {
        case .candidateId: return .candidateId
        case .chatId: return .chatId
        case .enterprisePhone: return .enterprisePhone
        case .ipPhone: return .ipPhone
        case .recruitmentPhone: return .recruitmentPhone
        case .telephone: return .telephone
        @unknown default:
            throw RouterError.resourceWithWrongFormat
        }
    }
}

private extension PhoneCallPickerBody.PhoneType {
    func toMeeting() throws -> PhoneCallParams.IdType {
        switch self {
        case .ipPhone: return .ipPhone
        case .enterprisePhone: return .enterprisePhone
        case .recruitmentPhone: return .recruitmentPhone
        @unknown default:
            throw RouterError.resourceWithWrongFormat
        }
    }
}

struct PreviewParticipantsBody: PlainBody {
    static let pattern: String = "//client/byteview/previewparticipants"

    var participants: [PreviewParticipant]
    var isPopover: Bool
    var totalCount: Int
    var meetingId: String?
    var chatId: String?
    var isInterview: Bool
    var isWebinar: Bool
    var selectCellAction: ((PreviewParticipant, UIViewController) -> Void)?
}

final class PreviewParticipantsHandler: UserTypedRouterHandler {
    func handle(_ body: PreviewParticipantsBody, req: EENavigator.Request, res: Response) throws {
        let params = PreviewParticipantParams(participants: body.participants, isPopover: body.isPopover, totalCount: body.totalCount, meetingId: body.meetingId, chatId: body.chatId, isInterview: body.isInterview, isWebinar: body.isWebinar, selectCellAction: body.selectCellAction)
        let dependency = try MeetingDependencyImpl(userResolver: userResolver)
        res.end(resource: try MeetingFrontier.createPreviewParticipantsViewController(params, dependency: dependency))
    }
}

struct PstnPhonesBody: PlainBody {
    static let pattern: String = "//client/byteview/pstnphones"

    let meetingNumber: String
    let phones: [PSTNPhone]
}

final class PstnPhonesHandler: UserTypedRouterHandler {
    func handle(_ body: PstnPhonesBody, req: EENavigator.Request, res: Response) throws {
        let params = PstnPhonesParams(meetingNumber: body.meetingNumber, phones: body.phones)
        let dependency = try userResolver.resolve(assert: LarkDependency.self).security
        res.end(resource: MeetingFrontier.createPstnPhonesViewController(params, dependency: dependency))
    }
}
