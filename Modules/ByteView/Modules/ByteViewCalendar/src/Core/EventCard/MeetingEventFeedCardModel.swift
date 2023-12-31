//
//  MeetingEventFeedCardModel.swift
//  ByteViewCalendar
//
//  Created by lutingting on 2023/8/2.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon
import ByteViewInterface
import ByteViewTracker
import EENavigator
import LarkContainer

protocol MeetingEventFeedCardModelDelegate: AnyObject {
    func didChangeMeetingInfo(_ infos: [IMNoticeInfo])
}

final class MeetingEventFeedCardModel {
    let userResolver: UserResolver
    let listeners = Listeners<MeetingEventFeedCardModelDelegate>()

    var infos: [IMNoticeInfo] = [] {
        didSet {
            listeners.forEach { $0.didChangeMeetingInfo(infos) }
        }
    }

    var shouldDisplay: Bool { infos.count > 0 }
    private var httpClient: HttpClient? { try? userResolver.resolve(assert: HttpClient.self) }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        Push.vcEventCard.inUser(userResolver.userID).addObserver(self) { [weak self] in
            self?.handleCardInfoResponse($0)
        }
        fetchData()
        syncMeetingStatus()
    }

    func addListener(_ listener: MeetingEventFeedCardModelDelegate) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: MeetingEventFeedCardModelDelegate) {
        listeners.removeListener(listener)
    }

    func removeMeeting(_ meetingId: String) {
        httpClient?.send(SetVcImChatBannerCloseRequest(meetingIds: [meetingId]))
    }

    private func fetchData() {
        httpClient?.getResponse(GetVcImChatBannerRequest(), options: .retry(3, owner: self)) { [weak self] resp in
            guard let self = self else { return }
            switch resp {
            case .success(let content):
                self.infos = content.infos
            case .failure(let error):
                Logger.eventCard.error("MeetingEventFeedCardModel fetch data error: \(error)")
            }
        }
    }

    private func syncMeetingStatus() {
        httpClient?.send(SyncMeetingStatusRequest(meetingID: nil))
    }
}

extension MeetingEventFeedCardModel {
    func handleCardInfoResponse(_ resp: GetVcImChatBannerResponse) {
        Logger.eventCard.info("MeetingEventFeedCardModel handleCardInfoResponse infos.count: \(infos.count)")
        infos = resp.infos
    }
}
