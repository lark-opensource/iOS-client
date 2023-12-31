//
//  AssignNewSharerViewModel.swift
//  ByteView
//
//  Created by liurundong.henry on 2019/10/29.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork

final class AssignNewSharerViewModel: InMeetShareDataListener, InMeetParticipantListener {
    let meeting: InMeetMeeting
    let remoteDocument: MagicShareDocument
    var currentDocumentURL: String = ""
    private let isSelfSharingRelay = BehaviorRelay<Bool>(value: false)
    var isSelfSharingObservable: Observable<Bool> { isSelfSharingRelay.asObservable() }
    /// 除了本设备之外，其他onTheCall的参会人的数量
    var participantCountRelay = BehaviorRelay<Int>(value: 0)

    init(meeting: InMeetMeeting, remoteDocument: MagicShareDocument) {
        self.meeting = meeting
        self.remoteDocument = remoteDocument
        meeting.shareData.addListener(self)
        meeting.participant.addListener(self)
    }

    private let cellModelsRelay = BehaviorRelay<[AssignNewSharerCellModel]>(value: [])
    var cellModels: Observable<[AssignNewSharerCellModel]> { cellModelsRelay.asObservable() }

    private var participantsRequestKey = ""

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        let key = UUID().uuidString
        self.participantsRequestKey = key
        let filteredResultArray = output.newData.nonRingingDict.filter { $0.key != meeting.account }.map(\.value)
        participantCountRelay.accept(filteredResultArray.count)
        participantInfos(by: filteredResultArray) { [weak self] (models) in
            guard let self = self, self.participantsRequestKey == key else { return }
            // 为参会人排序，此处逻辑与PC保持一致
            self.cellModelsRelay.accept(models.sortForAssignNewSharer())
        }
    }

    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        let magicShareUrl = newScene.magicShareData?.urlString ?? ""
        if currentDocumentURL != magicShareUrl { currentDocumentURL = magicShareUrl }
        let isSelfSharingDocument = meeting.shareData.isSelfSharingDocument
        if isSelfSharingDocument != isSelfSharingRelay.value { isSelfSharingRelay.accept(isSelfSharingDocument) }
    }
}

extension AssignNewSharerViewModel {
    private func participantInfos(by participants: [Participant], completion: @escaping ([AssignNewSharerCellModel]) -> Void) {
        let selfParticipant = meeting.myself
        let roleStrategy = meeting.data.roleStrategy
        let service = meeting.service
        let participantService = meeting.httpClient.participantService
        let meetingSource = meeting.info.meetingSource
        participantService.participantInfo(pids: participants, meetingId: meeting.meetingId, completion: { aps in
            let duplicatedParticipantIds = Set(Dictionary(grouping: aps.map { $0.id }, by: { $0 }).filter { $0.value.count > 1 }.map { $0.key })
            var models: [AssignNewSharerCellModel] = []
            for (p, ap) in zip(participants, aps) {
                var participant = p
                let role = participant.role
                let isExternal = participant.isExternal(localParticipant: selfParticipant)
                participant.isHost = participant.isHost && !participant.isLarkGuest && roleStrategy.participantCanBecomeHost(role: role)
                let isDuplicated = duplicatedParticipantIds.contains(ap.id)
                let model = AssignNewSharerCellModel.construct(with: participant, userInfo: ap, isDuplicated: isDuplicated, isExternal: isExternal, service: service, meetingSource: meetingSource)
                models.append(model)
            }
            completion(models)
        })
    }
}

private extension Array where Element == AssignNewSharerCellModel {

    /// 为参会人排序
    /// - Returns: [能发起共享的用户] + [无法发起共享的用户] + [Room用户]
    func sortForAssignNewSharer() -> [AssignNewSharerCellModel] {
        let models = self

        var canShares = [AssignNewSharerCellModel]()
        var cannotShares = [AssignNewSharerCellModel]()
        var rooms = [AssignNewSharerCellModel]()

        for model in models {
            let canFollow = model.participant.capabilities.follow
            if model.participant.type == .room {
                rooms.append(model)
            } else if canFollow {
                canShares.append(model)
            } else {
                cannotShares.append(model)
            }
        }

        return canShares.innerSort() + cannotShares.innerSort() + rooms.innerSort()
    }

    /// 为某类参会人排序
    /// - Returns: [主持人] + [举手参会人] + [联席主持人] + [一般参会人] + [呼叫中的参会人]
    func innerSort() -> [AssignNewSharerCellModel] {
        let models = self

        var hosts = [AssignNewSharerCellModel]()
        var handsUps = [AssignNewSharerCellModel]()
        var cameraHandsUps = [AssignNewSharerCellModel]()
        var coHosts = [AssignNewSharerCellModel]()
        var normals = [AssignNewSharerCellModel]()
        var ringings = [AssignNewSharerCellModel]()

        for model in models {
            if model.participant.isHost {
                hosts.append(model)
            } else if model.participant.isMicHandsUp {
                handsUps.append(model)
            } else if model.participant.isCameraHandsUp {
                cameraHandsUps.append(model)
            } else if model.participant.isCoHost {
                coHosts.append(model)
            } else if model.participant.isRing {
                ringings.append(model)
            } else {
                normals.append(model)
            }
        }

        return hosts
        // 优先显示（新）举手的参会人
        + handsUps.sorted { $0.participant.micHandsUpTime < $1.participant.micHandsUpTime }
        // 其次显示（新）举手开摄像头的参会人
        + cameraHandsUps.sorted { $0.participant.cameraHandsUpTime < $1.participant.cameraHandsUpTime }
        // 其次是（先）入会的联席主持人
        + coHosts.sorted { $0.participant.joinTime > $1.participant.joinTime }
        // 再次是（先）入会的一般用户
        + normals.sorted { $0.participant.joinTime > $1.participant.joinTime }
        // 最后是（先）入会的响铃用户
        + ringings.sorted { $0.participant.joinTime > $1.participant.joinTime }
    }

}
