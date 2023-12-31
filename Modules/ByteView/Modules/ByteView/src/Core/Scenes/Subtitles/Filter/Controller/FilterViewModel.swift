//
//  FilterViewModel.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/6/27.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

class FilterViewModel {

    let meeting: InMeetMeeting
    /// 初始状态，none代表无初始筛选人 清除筛选灰色，tableview无需高亮；filterPeople代表有初始化人选 清除筛选灰色亮色 Table某Cell高亮
    var state: FilterInitializeState = .none
    /// 用户基本信息数组
    @RwAtomic
    var byteviewUserArray = [ParticipantId]()
    /// 头像信息+人名数组
    @RwAtomic
    var avatarInfoAndNameArray = [(AvatarInfo, String, ParticipantId?)]()
    /// 成功筛选Block
    var filterBlock: ((ParticipantId) -> Void)
    /// 清除筛选Block
    var clearBlock: (() -> Void)

    var selectedUser: (AvatarInfo, String, ParticipantId?)?

    init(meeting: InMeetMeeting, state: FilterInitializeState, filterBlock: @escaping (ParticipantId) -> Void, clearBlock: @escaping () -> Void) {
        self.meeting = meeting
        self.state = state
        self.filterBlock = filterBlock
        self.clearBlock = clearBlock
    }

    /// 从Rust拉取参会人列表
    func fetchParticipantList(success: @escaping () -> Void, failure: @escaping () -> Void) {}

    func filter(with participantIds: [ParticipantId] = [], completion: ((Result<Void, Error>) -> Void)? = nil) {}

    /// 获取人的具体信息
    func getAvatarAndName(with participantIds: [ParticipantId], avatarAndNameArrayBlock: @escaping ([(AvatarInfo, String, ParticipantId?)]) -> Void) {
        let participantService = meeting.httpClient.participantService
        participantService.participantInfo(pids: participantIds, meetingId: meeting.meetingId) { aps in
            avatarAndNameArrayBlock(aps.map { ($0.avatarInfo, $0.name, $0.pid) })
        }
    }

    func handleResponse(with list: [SubtitleUser], completion: @escaping () -> Void) {
        let participants: [ParticipantId] = list.map {
            return $0.participantId
        }
        byteviewUserArray = participants
        //  拉去人员具体数据
        getAvatarAndName(with: participants, avatarAndNameArrayBlock: { [weak self] (avatarAndNames) in
            guard let `self` = self else { return }
            self.avatarInfoAndNameArray = avatarAndNames
            completion()
        })
    }

    func filter(withIndex index: Int, completion: @escaping () -> Void) {
        let newUser = byteviewUserArray[index]
        state = .filterPeople(people: newUser)
        selectedUser = avatarInfoAndNameArray[index]
        filter(with: [newUser]) { [weak self] _ in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.filterBlock(newUser)
                completion()
            }
        }
    }

    func clear(excuteClearBlock: Bool = true, completion: (() -> Void)? = nil) {
        selectedUser = nil
        state = .none
        filter { [weak self] _ in
            if excuteClearBlock, let block = self?.clearBlock {
                block()
            }
            completion?()
        }
    }
    /// 进入状态
    enum FilterInitializeState {
        case none
        case filterPeople(people: ParticipantId)
    }
}

class SubtitleFilterViewModel: FilterViewModel {

    override func fetchParticipantList(success: @escaping () -> Void, failure: @escaping () -> Void) {
        let breakoutRoomId = self.meeting.data.breakoutRoomId
        meeting.httpClient.getResponse(GetParticipantListRequest(breakoutRoomId: breakoutRoomId)) { [weak self] result in
            guard let `self` = self else {
                return
            }
            switch result {
            case .success(let response):
                if self.meeting.data.isOpenBreakoutRoom == false || (self.meeting.data.isMainBreakoutRoom && BreakoutRoomUtil.isMainRoom(response.breakoutRoomId)) || self.meeting.data.breakoutRoomId == response.breakoutRoomId {
                    self.handleResponse(with: response.userInfoList, completion: success)
                } else {
                    failure()
                }
            case .failure:
                failure()
            }
        }
    }

    override func filter(with participantIds: [ParticipantId] = [], completion: ((Result<Void, Error>) -> Void)? = nil) {
        let users: [ByteviewUser] = participantIds.map { ByteviewUser(id: $0.id, type: $0.type, deviceId: $0.deviceId) }
        let breakoutRoomId = self.meeting.data.breakoutRoomId
        let request = SetSubtitlesFilterRequest(users: users, breakoutRoomId: breakoutRoomId)
        meeting.httpClient.getResponse(request) { [weak self] result in
            guard let `self` = self else {
                return
            }
            switch result {
            case .success(let response):
                if self.meeting.data.isOpenBreakoutRoom == false || (self.meeting.data.isMainBreakoutRoom && BreakoutRoomUtil.isMainRoom(response.breakoutRoomId)) || self.meeting.data.breakoutRoomId == response.breakoutRoomId {
                    completion?(.success(()))
                } else {
                    completion?(.failure(VCError.unknown))
                }
            case .failure:
                completion?(.failure(VCError.unknown))
            }
        }
    }

}

class TranscriptFilterViewModel: FilterViewModel {

    override func fetchParticipantList(success: @escaping () -> Void, failure: @escaping () -> Void) {
        meeting.httpClient.getResponse(GetTranscriptParticipantListRequest()) { [weak self] result in
            switch result {
            case .success(let resp):
                self?.handleResponse(with: resp.userInfoList, completion: success)
            case .failure:
                failure()
            }
        }
    }

    override func filter(with participantIds: [ParticipantId] = [], completion: ((Result<Void, Error>) -> Void)? = nil) {
        let users: [ByteviewUser] = participantIds.map { ByteviewUser(id: $0.id, type: $0.type, deviceId: $0.deviceId) }
        let request = SetTranscriptFilterRequest(users: users)
        meeting.httpClient.send(request, completion: completion)
    }
}
