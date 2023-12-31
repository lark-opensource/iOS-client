//
//  LynxNetworkModule.swift
//  ByteViewHybrid
//
//  Created by Tobb Huang on 2022/10/21.
//

import Foundation
import SwiftProtobuf
import RustPB
import ServerPB
import Lynx
import ByteViewNetwork

struct LynxNetworkParam {
    let userId: String
    let httpClient: HttpClient
}

class LynxVoteNetworkModule: NSObject, LynxNativeModule {
    typealias Param = LynxNetworkParam

    static var name: String = "VoteNetwork"

    static var methodLookup: [String: String] = [
        "createMeetingVote": NSStringFromSelector(#selector(createMeetingVote)),
        "participateVote": NSStringFromSelector(#selector(participateVote)),
        "pullUserVoteInfo": NSStringFromSelector(#selector(pullUserVoteInfo)),
        "pullVoteChooseUserList": NSStringFromSelector(#selector(pullVoteChooseUserList)),
        "pullVoteStatisticInfo": NSStringFromSelector(#selector(pullVoteStatisticInfo)),
        "pullVoteStatisticList": NSStringFromSelector(#selector(pullVoteStatisticList)),
        "voteOneClickReminder": NSStringFromSelector(#selector(voteOneClickReminder)),
        "pullUserInfo": NSStringFromSelector(#selector(pullUserInfo)),
        "updateMeetingVote": NSStringFromSelector(#selector(updateMeetingVote)),
        "clearUserVote": NSStringFromSelector(#selector(clearUserVote)),
        "makeVoteStatPublish": NSStringFromSelector(#selector(makeVoteStatPublish))
    ]

    private var httpClient: HttpClient?
    override required init() { super.init() }
    required init(param: Any) {
        super.init()
        if let p = param as? Param {
            self.httpClient = p.httpClient
        }
    }

    @objc func createMeetingVote(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        let request = CreateMeetingVoteRequest(dict: params)
        httpClient?.getResponse(request) { result in
            switch result {
            case .success(let res):
                let dict = res.dict
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("createMeetingVote failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func participateVote(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        httpClient?.send(ParticipateVoteRequest(dict: params)) { result in
            switch result {
            case .success:
                let dict: [String: Any] = [:]
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("participateVote failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func pullUserVoteInfo(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        let request = PullUserVoteInfoRequest(dict: params)
        httpClient?.getResponse(request) { result in
            switch result {
            case .success(let res):
                let dict = res.dict
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("pullUserVoteInfo failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func pullVoteChooseUserList(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        let request = PullVoteChooseUserListRequest(dict: params)
        httpClient?.getResponse(request) { result in
            switch result {
            case .success(let res):
                let dict = res.dict
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("pullVoteChooseUserList failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func pullVoteStatisticInfo(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        let request = PullVoteStatisticInfoRequest(dict: params)
        httpClient?.getResponse(request) { result in
            switch result {
            case .success(let res):
                let dict = res.dict
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("pullVoteStatisticInfo failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func pullVoteStatisticList(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        let request = PullVoteStatisticListRequest(dict: params)
        httpClient?.getResponse(request) { result in
            switch result {
            case .success(let res):
                let dict = res.dict
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("pullVoteStatisticList failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func voteOneClickReminder(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        let request = VoteOneClickReminderRequest(dict: params)
        httpClient?.getResponse(request) { result in
            switch result {
            case .success(let res):
                let dict = res.dict
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("voteOneClickReminder failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func pullUserInfo(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        guard let meetingID = params["meetingID"] as? String else { return }
        guard let userList = params["userList"] as? [[String: Any]] else { return }
        httpClient?.participantService.participantInfo(
            pids: userList.map { ByteviewUser.init(dict: $0) },
            meetingId: meetingID) { (infos: [ParticipantUserInfo]) in
            let userInfoList = infos.map { (info: ParticipantUserInfo) in
                var avatar: [String: String] = [:]
                if case let .remote(key, entityId) = info.avatarInfo {
                    avatar["key"] = key
                    avatar["entityId"] = entityId
                }
                return [
                    "user": info.pid?.pid.dict ?? [:],
                    "name": info.name,
                    "avatar": avatar
                ]
            }
            callback(["userInfoList": userInfoList])
        }
    }

    @objc func updateMeetingVote(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        httpClient?.getResponse(UpdateMeetingVoteRequest(dict: params)) { result in
            switch result {
            case .success:
                let dict: [String: Any] = [:]
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("updateMeetingVote failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func clearUserVote(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        httpClient?.send(ClearUserVoteRequest(dict: params)) { result in
            switch result {
            case .success:
                let dict: [String: Any] = [:]
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("clearUserVote failed, err = \(err)")
            default:
                break
            }
        }
    }

    @objc func makeVoteStatPublish(params: [String: Any], callback: @escaping LynxCallbackBlock) {
        let request = MakeVoteStatPublishRequest(dict: params)
        httpClient?.getResponse(request) { result in
            switch result {
            case .success(let res):
                let dict = res.dict
                callback(dict)
            case .failure(let err):
                Logger.lynx.error("makeVoteStatPublish failed, err = \(err)")
            default:
                break
            }
        }
    }
}
