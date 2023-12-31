//
//  ParticipantManagerPerfTest.swift
//  ByteView-Unit-Tests
//
//  Created by liujianlong on 2023/9/13.
//

import XCTest
@testable import ByteView
@testable import ByteViewNetwork

class DataLoader {
    func loadFramedMessage() {

    }
}

@available(iOS 13.0, *)
final class ParticipantManagerPerfTest: XCTestCase {
    private var fullParticipants: [Participant] = []
    private var upsert: [Participant] = []
    private var remove: [Participant] = []

    override func setUpWithError() throws {
        let gen = ParticipantMessageGenerator(userID: "x",
                                              meetingID: "xxx",
                                              pushType: .participant,
                                              count: 1000,
                                              rng: Xoroshiro256StarStar(seed: (0, 1, 2, 3)))
        let fullParticipants = gen.generateInitialMessage().upsertParticipants.map { $0.vcType(meetingID: "xxx") }
        let change = gen.generateChangeMsg(changeCount: 100, removeCount: 100)
        self.upsert = change.upsertParticipants.map { $0.vcType(meetingID: "xxx") }
        self.remove = change.removeParticipants.map { $0.vcType(meetingID: "xxx") }
    }

    override func tearDownWithError() throws {
    }

    func testWebinarGridAggregator() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let agg = WebinarGridParticipantAggregator()
            agg.handleFullParticipants(self.fullParticipants)
            agg.handleParticipantChange(upsertParticipants: upsert, removeParticipants: remove)
        }
    }
}
