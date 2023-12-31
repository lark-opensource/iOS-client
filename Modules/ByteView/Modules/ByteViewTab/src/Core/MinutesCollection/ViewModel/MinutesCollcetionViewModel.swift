//
//  MinutesCollcetionViewModel.swift
//  ByteViewTab
//
//  Created by 陈乐辉 on 2023/5/8.
//

import Foundation
import ByteViewNetwork

protocol MinutesCollcetionViewModelDelegate: AnyObject {
    func minutesCollcetionDidUpdate()
}

final class MinutesCollcetionViewModel {
    let meetingDetail: MeetingDetailViewModel

    var title: String = ""
    var subtitle: String = ""

    var items: [MeetingDetailFile] = []

    weak var delegate: MinutesCollcetionViewModelDelegate?

    var router: TabRouteDependency? { meetingDetail.router }

    var meetingID: String {
        meetingDetail.meetingID ?? ""
    }

    var isMeetingEnd: Bool {
        guard let commonInfo = meetingDetail.commonInfo.value else { return true }
        return commonInfo.meetingStatus == .meetingEnd
    }

    init(detail: MeetingDetailViewModel) {
        self.meetingDetail = detail
        detail.recordInfo.addObserver(self)
    }

    func generateItems() {
        guard let meetingID = meetingDetail.meetingID,
              let recordInfo = meetingDetail.recordInfo.value,
              let model = meetingDetail.commonInfo.value,
              let hostInfo = recordInfo.minutesInfoV2.first(where: { $0.breakoutRoomID == 1 })
        else { return }
        var minutesInfo: [TabDetailRecordInfo.MinutesInfo] = [hostInfo]
        minutesInfo.append(contentsOf: recordInfo.minutesBreakoutInfo)
        title = model.meetingTopic
        var items: [MeetingDetailFile] = []
        minutesInfo.forEach { info in
            if info.status == .pending {
                let topic = info.topic.isEmpty ? model.meetingTopic : info.topic
                items.append(MeetingDetailFile(placeholderType: recordInfo.type, topic: topic, breakoutMinutesCount: 0, objectID: info.objectID))
            } else {
                var data = MeetingDetailFile(info: info, icon: recordInfo.type.icon, objectID: info.objectID)
                data.minutesDuration = info.duration
                items.append(data)
            }
        }
        self.items = items
        let count = items.count
        meetingDetail.httpClient.participantService.participantInfo(pid: hostInfo, meetingId: meetingID) { [weak self] user in
            self?.subtitle = I18n.View_G_NumRecordings(count) + " ︳" + I18n.View_MV_MinuteFileOwner_Note(user.name, lang: nil)
            self?.delegate?.minutesCollcetionDidUpdate()
        }
    }
}

extension MinutesCollcetionViewModel: MeetingDetailRecordInfoObserver {
    func didReceive(data: TabDetailRecordInfo) {
        generateItems()
    }
}
