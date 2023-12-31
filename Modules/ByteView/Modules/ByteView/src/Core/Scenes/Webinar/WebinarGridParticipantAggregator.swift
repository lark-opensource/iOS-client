//
// Created by liujianlong on 2022/11/1.
//

import Foundation
import ByteViewNetwork

protocol GridParticipantAggregatorListener: AnyObject {
    func handleFullParticipants(_ participants: [Participant])
    func handleParticipantChange(removeParticipants: [Participant], upsertParticipants: [Participant])
}

final class WebinarGridParticipantAggregator {
    @RwAtomic private var participantPIDs = Set<ByteviewUser>()
    @RwAtomic private var participants = [ByteviewUser: Participant]()

    @RwAtomic private var attendeePIDs = Set<ByteviewUser>()
    @RwAtomic private var attendees = [ByteviewUser: Participant]()
    private var observers = Listeners<GridParticipantAggregatorListener>()

    func addListener(_ listener: GridParticipantAggregatorListener) {
        self.observers.addListener(listener)
        let callbackData = self.participants.values + self.attendees.values.filter({ !self.participantPIDs.contains($0.user) })
        listener.handleFullParticipants(callbackData)
    }

    func handleFullParticipants(_ participants: [Participant]) {
        let newFullIDs = Set(participants.map(\.user))
        let removeIDs = self.participantPIDs.subtracting(newFullIDs)
        let removed = removeIDs.compactMap { self.participants[$0] }
        self.processParticipantChange(upsert: participants, removed: removed)
        assert(self.participantPIDs == newFullIDs)
    }

    func handleFullAttendees(_ attendees: [Participant]) {
        let newFullIDs = Set(attendees.map(\.user))
        let removeIDs = self.attendeePIDs.subtracting(newFullIDs)
        let removed = removeIDs.compactMap { self.attendees[$0] }
        self.processAttendeeChange(upsert: attendees, removed: removed)
        assert(self.attendeePIDs == newFullIDs)
    }

    func handleParticipantChange(upsertParticipants: [Participant], removeParticipants: [Participant]) {
        self.processParticipantChange(upsert: upsertParticipants, removed: removeParticipants)
    }

    func handleAttendeeChange(upsertParticipants: [Participant], removeParticipants: [Participant]) {
        self.processAttendeeChange(upsert: upsertParticipants, removed: removeParticipants)
    }

    private func processParticipantChange(upsert: [Participant], removed: [Participant]) {
        for p in upsert {
            self.participantPIDs.insert(p.user)
            self.participants[p.user] = p
        }
        var aggregateUpsert = upsert
        var aggregateRemoved: [Participant] = []
        aggregateRemoved.reserveCapacity(removed.count)
        for p in removed {
            self.participantPIDs.remove(p.user)
            self.participants.removeValue(forKey: p.user)
            if let compensateP = self.attendees[p.user] {
                // 当用户同时存在于观众列表和参会人列表时，
                // 用户从参会人列表中被删除，使用观众列表的数据刷新宫格
                Logger.webinarPanel.warn("compensate \(p) --> \(compensateP)")
                aggregateUpsert.append(compensateP)
            } else {
                aggregateRemoved.append(p)
            }
        }
        self.observers.forEach({ $0.handleParticipantChange(removeParticipants: aggregateRemoved, upsertParticipants: aggregateUpsert) })
    }

    private func processAttendeeChange(upsert: [Participant], removed: [Participant]) {
        var aggregateUpsert: [Participant] = []
        var aggregateRemoved: [Participant] = []
        aggregateUpsert.reserveCapacity(upsert.count)
        aggregateRemoved.reserveCapacity(removed.count)
        for p in upsert {
            self.attendeePIDs.insert(p.user)
            self.attendees[p.user] = p
            if self.participantPIDs.contains(p.user) {
                // 如果用户已经存在于参会人列表，就跳过更新
                Logger.webinarPanel.warn("skip update participant as attendee: \(p)")
            } else {
                aggregateUpsert.append(p)
            }
        }
        for p in removed {
            self.attendeePIDs.remove(p.user)
            self.attendees.removeValue(forKey: p.user)
            if self.participantPIDs.contains(p.user) {
                Logger.webinarPanel.warn("skip remove participant as attendee: \(p)")
            } else {
                aggregateRemoved.append(p)
            }
        }
        self.observers.forEach({ $0.handleParticipantChange(removeParticipants: aggregateRemoved, upsertParticipants: aggregateUpsert) })
    }

    // TODO：临时透传方案，待gridDatasource与sorter处理参会人变更的时序依赖被移除后下掉
    private let normalObservers = Listeners<GridParticipantAggregatorListener>()
    func addNormalListener(_ listener: GridParticipantAggregatorListener, full: [Participant]) {
        normalObservers.addListener(listener)
        listener.handleFullParticipants(full)
    }
    func transpondFullParticipants(_ participants: [Participant]) {
        normalObservers.forEach { $0.handleFullParticipants(participants) }
    }
    func transpondParticipantChange(upserts: [Participant], removes: [Participant]) {
        normalObservers.forEach { $0.handleParticipantChange(removeParticipants: removes, upsertParticipants: upserts) }
    }
    private let attendeeObservers = Listeners<GridParticipantAggregatorListener>()
    func addAttendeeListener(_ listener: GridParticipantAggregatorListener, full: [Participant]) {
        attendeeObservers.addListener(listener)
        listener.handleFullParticipants(full)
    }
    func transpondFullAttendeePanel(_ participants: [Participant]) {
        attendeeObservers.forEach { $0.handleFullParticipants(participants) }
    }
    func transpondAttendeePanelChange(upserts: [Participant], removes: [Participant]) {
        attendeeObservers.forEach { $0.handleParticipantChange(removeParticipants: removes, upsertParticipants: upserts) }
    }
}
