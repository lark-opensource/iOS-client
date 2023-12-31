//
//  MeetingManager.swift
//  ByteView
//
//  Created by kiri on 2022/6/11.
//

import Foundation
import ByteViewMeeting
import ByteViewTracker
import ByteViewNetwork
import ByteViewUI

enum MeetingEntry {
    case push(JoinMeetingMessage)
    case call(StartCallParams)
    case enterpriseCall(EnterpriseCallParams)
    case preview(PreviewEntryParams)
    case noPreview(NoPreviewParams)
    case rejoin(RejoinParams)
    case voipPush(VoIPPushInfo)
    case shareToRoom(ShareToRoomEntryParams)
}

enum StartMeetingError: String, Error, CustomStringConvertible {
    case invalidUser
    case preloadFailed
    case alreadyExists

    var description: String { rawValue }
}

extension MeetingSession {
    private(set) var userId: String {
        get { attr(.userId, "") }
        set { setAttr(newValue, for: .userId) }
    }

    /// 启动参数
    var meetingEntry: MeetingEntry? { attr(.meetingEntry) }
    /// 基础服务
    var service: MeetingBasicService? { attr(.basicService) }

    var startCallParams: StartCallParams? {
        switch meetingEntry {
        case .call(let params):
            return params
        default:
            return nil
        }
    }

    var enterpriseCallParams: EnterpriseCallParams? {
        switch meetingEntry {
        case .enterpriseCall(let params):
            return params
        default:
            return nil
        }
    }

    var previewEntryParams: PreviewEntryParams? {
        switch meetingEntry {
        case .preview(let params):
            return params
        default:
            return nil
        }
    }

    var pushParams: JoinMeetingMessage? {
        switch meetingEntry {
        case .push(let message):
            return message
        default:
            return nil
        }
    }

    fileprivate func setupInitialProps(entry: MeetingEntry, dependency: MeetingDependency) {
        if let meetingId = entry.meetingId {
            self.meetingId = meetingId
        }
        let service = MeetingBasicService(session: self, dependency: dependency)
        self.setAttr(entry, for: .meetingEntry)
        self.setAttr(service, for: .basicService)
        self.userId = dependency.account.userId
        #if BYTEVIEW_CALLKIT
        self.createCallKitComponent()
        #endif
        if AppInfo.shared.applicationState == .active {
            executeInQueue(source: "migrateStorageToUser") {
                dependency.migrateStorageToUser()
            }
        } else {
            DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
                dependency.migrateStorageToUser()
            }
        }
    }
}

extension MeetingManager {
    /// 所有的vc发起会议都应该走这里的入口（voipPush除外）
    /// - parameters:
    ///     - entry: 启动参数
    ///     - dependency: 会议依赖
    ///     - completion: 执行完preparing后回调, (session, isCreated)
    ///  - returns: 是否成功创建session
    @discardableResult
    func startMeeting(_ entry: MeetingEntry, dependency: MeetingDependency, from: RouteFrom?,
                      file: String = #fileID, function: String = #function, line: Int = #line,
                      completion: ((Result<MeetingSession, Error>) -> Void)? = nil) -> Result<MeetingSession, StartMeetingError> {
        let startTime = CACurrentMediaTime()
        Logger.meeting.info("startMeeting start, entry = \(entry), from = \(from)", file: file, function: function, line: line)
        let meetingId = entry.meetingId
        let accountInfo = dependency.account
        var checkForeground = true
        if case .voipPush(let pushInfo) = entry {
            guard accountInfo.userId == pushInfo.userID else {
                Logger.meeting.error("startMeeting failed: account is not valid", file: file, function: function, line: line)
                completion?(.failure(StartMeetingError.invalidUser))
                return .failure(.invalidUser)
            }
            checkForeground = false
        }
        do {
            try ByteViewApp.shared.preload(account: accountInfo, reason: "startMeeting", checkForeground: checkForeground)
        } catch {
            Logger.meeting.error("startMeeting failed: preload ByteViewApp error, \(error)", file: file, function: function, line: line)
            completion?(.failure(error))
            return .failure(.preloadFailed)
        }

        JoinMeetingQueue.shared.suspend()
        if let meetingId = meetingId, !meetingId.isEmpty, let another = findSession(meetingId: meetingId, sessionType: .vc) {
            Logger.meeting.warn("startMeeting ignored, find another \(another)", file: file, function: function, line: line)
            another.executeInQueue(source: "startMeetingWithAnother") {
                completion?(.failure(StartMeetingError.alreadyExists))
                JoinMeetingQueue.shared.resume()
                self.handleExistSession(another, for: entry)
            }
            return .failure(.alreadyExists)
        }

        Util.runInMainThread {
            if let from = from?.window {
                VCScene.setPreferredWindowScene(from: from)
            }
        }
        let session = createSession(.vc, forcePending: entry.forcePending(accountInfo), file: file, function: function, line: line)
        session.setupInitialProps(entry: entry, dependency: dependency)
        MeetingObserverCenter.shared.addMeeting(session)
        session.start()
        session.sendEvent(.startPreparing(entry)) {
            completion?($0.map({ _ in session }))
            JoinMeetingQueue.shared.resume()
        }
        let duration = CACurrentMediaTime() - startTime
        session.log("startMeeting success, duration = \(Util.formatTime(duration)), entry = \(entry)",
                    file: file, function: function, line: line)
        return .success(session)
    }

    private func handleExistSession(_ session: MeetingSession, for entry: MeetingEntry) {
        switch entry {
        case .push(let message):
            assert(session.state != .start, "warning: session.state is start, should not accept VideoChatInfo: \(message.info)")
            session.sendToMachine(info: message.info)
        case .rejoin(let params):
            if params.type == .registerClientInfo {
                JoinMeetingQueue.shared.send(JoinMeetingMessage(info: params.info, type: .registerClientInfo, sessionId: session.sessionId))
            }
        default:
            break
        }
    }
}

private extension MeetingEntry {
    var meetingId: String? {
        switch self {
        case .push(let joinMeetingMessage):
            return joinMeetingMessage.info.id
        case .call, .enterpriseCall, .shareToRoom:
            return nil
        case .preview, .noPreview:
            return nil
        case .rejoin(let rejoinParams):
            return rejoinParams.info.id
        case .voipPush(let voIPPushInfo):
            return voIPPushInfo.conferenceID
        }
    }

    func forcePending(_ accountInfo: AccountInfo) -> Bool {
        switch self {
        case .push(let params):
            if params.type == .registerClientInfo {
                return shouldForcePending(params.info, accountInfo)
            }
            return false
        case .rejoin(let params):
            if params.type == .registerClientInfo {
                return shouldForcePending(params.info, accountInfo)
            }
            return false
        default:
            return false
        }
    }

    func shouldForcePending(_ info: VideoChatInfo, _ accountInfo: AccountInfo) -> Bool {
        let account = accountInfo.user
        if let myself = info.participant(byUser: account), let id = myself.ongoingMeetingId,
           let interactiveId = myself.ongoingMeetingInteractiveId {
            return !MeetingTerminationCache.shared.isTerminated(meetingId: id, interactiveId: interactiveId)
        }
        return false
    }
}

private extension MeetingAttributeKey {
    static let userId = MeetingAttributeKey("vc.userId", releaseOnEnd: false)
    static let meetingEntry: MeetingAttributeKey = "vc.meetingEntry"
    static let basicService: MeetingAttributeKey = "vc.basicService"
}
