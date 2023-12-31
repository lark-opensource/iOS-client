//
//  MeetingDetailNotifier.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/12/1.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon

class MeetingDetailNotifier<Value, Observer> {
    private let observers = Listeners<Observer>()

    func addObserver(_ observer: Observer) {
        observers.addListener(observer)
    }

    func removeObserver(_ observer: Observer) {
        observers.removeListener(observer)
    }

    @RwAtomic private var _value: Value?

    func send(data: Value) {
        Util.runInMainThread { [weak self] in
            self?.observers.forEach {
                self?.handle(data: data, for: $0)
            }
        }
    }

    func handle(data: Value, for observer: Observer) {
        self._value = data
    }

    var value: Value? { _value }
}

protocol MeetingDetailJoinStatusObserver {
    func didReceive(data: MeetingJoinInfo.JoinStatus)
}

class MeetingDetailJoinStatusNotifier: MeetingDetailNotifier<MeetingJoinInfo.JoinStatus, MeetingDetailJoinStatusObserver> {
    override func handle(data: MeetingJoinInfo.JoinStatus, for observer: any MeetingDetailJoinStatusObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailCommonInfoObserver {
    func didReceive(data: TabHistoryCommonInfo)
}

class MeetingDetailCommonInfoNotifier: MeetingDetailNotifier<TabHistoryCommonInfo, MeetingDetailCommonInfoObserver> {
    override func handle(data: TabHistoryCommonInfo, for observer: any MeetingDetailCommonInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailHistoryInfoObserver {
    func didReceive(data: [HistoryInfo])
}

class MeetingDetailHistoryInfoNotifier: MeetingDetailNotifier<[HistoryInfo], MeetingDetailHistoryInfoObserver> {
    override func handle(data: [HistoryInfo], for observer: any MeetingDetailHistoryInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailStatisticsInfoObserver {
    func didReceive(data: TabStatisticsInfo)
}

class MeetingDetailStatisticsInfoNotifier: MeetingDetailNotifier<TabStatisticsInfo, MeetingDetailStatisticsInfoObserver> {
    override func handle(data: TabStatisticsInfo, for observer: any MeetingDetailStatisticsInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailChatHistoryObserver {
    func didReceive(data: TabDetailChatHistoryV2)
}

class MeetingDetailChatHistoryNotifier: MeetingDetailNotifier<TabDetailChatHistoryV2, MeetingDetailChatHistoryObserver> {
    override func handle(data: TabDetailChatHistoryV2, for observer: any MeetingDetailChatHistoryObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailAppLinkInfoObserver {
    func didReceive(data: MeetingSourceAppLinkInfo)
}

class MeetingDetailAppLinkInfoNotifier: MeetingDetailNotifier<MeetingSourceAppLinkInfo, MeetingDetailAppLinkInfoObserver> {
    override func handle(data: MeetingSourceAppLinkInfo, for observer: any MeetingDetailAppLinkInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailNotesInfoObserver {
    func didReceive(data: TabNotesInfo)
}

class MeetingDetailNotesInfoNotifier: MeetingDetailNotifier<TabNotesInfo, MeetingDetailNotesInfoObserver> {
    override func handle(data: TabNotesInfo, for observer: any MeetingDetailNotesInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailRecordInfoObserver {
    func didReceive(data: TabDetailRecordInfo)
}

class MeetingDetailRecordInfoNotifier: MeetingDetailNotifier<TabDetailRecordInfo, MeetingDetailRecordInfoObserver> {
    override func handle(data: TabDetailRecordInfo, for observer: any MeetingDetailRecordInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailCheckinInfoObserver {
    func didReceive(data: TabDetailCheckinInfo)
}

class MeetingDetailCheckinInfoNotifier: MeetingDetailNotifier<TabDetailCheckinInfo, MeetingDetailCheckinInfoObserver> {
    override func handle(data: TabDetailCheckinInfo, for observer: any MeetingDetailCheckinInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailVoteStatisticsInfoObserver {
    func didReceive(data: TabVoteStatisticsInfo)
}

class MeetingDetailVoteStatisticsInfoNotifier: MeetingDetailNotifier<TabVoteStatisticsInfo, MeetingDetailVoteStatisticsInfoObserver> {
    override func handle(data: TabVoteStatisticsInfo, for observer: any MeetingDetailVoteStatisticsInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailAudienceInfoObserver {
    func didReceive(data: AudienceInfo)
}

class MeetingDetailAudienceInfoNotifier: MeetingDetailNotifier<AudienceInfo, MeetingDetailAudienceInfoObserver> {
    override func handle(data: AudienceInfo, for observer: any MeetingDetailAudienceInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailParticipantAbbrInfoObserver {
    func didReceive(data: [ParticipantAbbrInfo])
}

class MeetingDetailParticipantAbbrInfoNotifier: MeetingDetailNotifier<[ParticipantAbbrInfo], MeetingDetailParticipantAbbrInfoObserver> {
    override func handle(data: [ParticipantAbbrInfo], for observer: any MeetingDetailParticipantAbbrInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailCollectionInfoObserver {
    func didReceive(data: [CollectionInfo])
}

class MeetingDetailCollectionInfoNotifier: MeetingDetailNotifier<[CollectionInfo], MeetingDetailCollectionInfoObserver> {
    override func handle(data: [CollectionInfo], for observer: any MeetingDetailCollectionInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}

protocol MeetingDetailFollowInfoInfoObserver {
    func didReceive(data: [FollowAbbrInfo])
}

class MeetingDetailFollowInfoNotifier: MeetingDetailNotifier<[FollowAbbrInfo], MeetingDetailFollowInfoInfoObserver> {
    override func handle(data: [FollowAbbrInfo], for observer: any MeetingDetailFollowInfoInfoObserver) {
        super.handle(data: data, for: observer)
        observer.didReceive(data: data)
    }
}
