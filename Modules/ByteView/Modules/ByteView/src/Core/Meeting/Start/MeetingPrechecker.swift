//
//  MeetingPrechecker.swift
//  ByteView
//
//  Created by lutingting on 2023/8/17.
//

import Foundation
import ByteViewMeeting

typealias PrecheckOutput = (Result<PrecheckResult, Error>) -> Void

enum PrecheckResult {
    case preview(PreviewEntranceOutputParams)
    case noPreview
    case call(CallEntranceOutputParams)
    case enterpriseCall(CallEntranceOutputParams)
    case rejoin
    case push
    case voipPush
    case shareToRoom
}

final class MeetingPrechecker {
    static let shared: MeetingPrechecker = MeetingPrechecker()
    let log = Logger.precheck

    func precheck(_ session: MeetingSession, entry: MeetingEntry, completion: @escaping PrecheckOutput) {
        switch entry {
        case .call(let params):
            handleStartCallEntry(session, params: params, completion: completion)
        case .enterpriseCall(let params):
            handleEnterpriseCallEntry(session, params: params, completion: completion)
        case .preview(let params):
            handlePreviewEntry(session, params: params, completion: completion)
        case .noPreview(let params):
            handleNoPreviewEntry(session, params: params, completion: completion)
        case .rejoin(let params):
            handleRejoinEntry(session, params: params, completion: completion)
        case .push(let message):
            handlePushEntry(session, params: message, completion: completion)
        case .voipPush(let pushInfo):
            handleVoipPushEntry(session, pushInfo: pushInfo, completion: completion)
        case .shareToRoom(let params):
            handleShateToRoomEntry(session, entryParams: params, completion: completion)
        }
    }
}

extension MeetingSession {
    func precheck(entry: MeetingEntry) {
        let logTag = description
        MeetingPrechecker.shared.precheck(self, entry: entry) { [weak self] result in
            guard let self = self else {
                Logger.meeting.warn("\(logTag), precheck cancelled, MeetingSession is released")
                return
            }
            self.precheckEntrance = nil
            switch result {
            case .success(let prechekcResult):
                switch prechekcResult {
                case .preview(let output):
                    self.startPreviewMeeting(output)
                case .noPreview:
                    guard case let .noPreview(params) = entry else {
                        self.loge("the entry before(noPreview) and after(\(entry)) does not match")
                        self.leave()
                        return
                    }
                    self.joinMeetingWithNoPreviewParams(params)
                case .call(let output):
                    guard case let .call(params) = entry else {
                        self.loge("the entry before(call) and after(\(entry)) does not match")
                        self.leave()
                        return
                    }
                    self.startCall(params, extraInfo: output)
                case .enterpriseCall(let output):
                    guard case let .enterpriseCall(params) = entry else {
                        self.loge("the entry before(enterpriseCall) and after(\(entry)) does not match")
                        self.leave()
                        return
                    }
                    self.startCall(params, extraInfo: output)
                case .rejoin:
                    guard case let .rejoin(params) = entry else {
                        self.loge("the entry before(rejoin) and after(\(entry)) does not match")
                        self.leave()
                        return
                    }
                    self.rejoinMeeting(params)
                case .push:
                    guard case let .push(message) = entry else {
                        self.loge("the entry before(push) and after(\(entry)) does not match")
                        self.leave()
                        return
                    }
                    self.joinMeetingWithPushMessage(message)
                case .voipPush:
                    guard case let .voipPush(info) = entry else {
                        self.loge("the entry before(voipPush) and after(\(entry)) does not match")
                        self.leave()
                        return
                    }
                    self.joinMeetingWithVoipPushInfo(info)
                case .shareToRoom:
                    guard case let .shareToRoom(params) = entry else {
                        self.loge("the entry before(shareToRoom) and after(\(entry)) does not match")
                        self.leave()
                        return
                    }
                    self.startSharingToRoom(params)
                }
            case .failure(let error):
                self.loge("\(logTag), precheck failed, error = \(error)")
                self.leave()
            }
        }
    }
}


extension MeetingSession {
    var precheckEntrance: PrecheckEntrance? {
        get { attr(.precheckEntrance) }
        set { setAttr(newValue, for: .precheckEntrance) }
    }
}

extension MeetingAttributeKey {
    static let precheckEntrance: MeetingAttributeKey = "vc.precheckEntrance"
}
