//
//  CollectByTimeTests.swift
//  OpenCombineTests
//
//  Created by bytedance on 2020/8/13.
//  Copyright © 2020 wangyuanxun. All rights reserved.
//

import Foundation
import XCTest

#if OPENCOMBINE_COMPATIBILITY_TEST
import Combine
#else
import OpenCombine
#endif


@available(macOS 10.15, iOS 13.0, *)
final class CollectByTimeTests: XCTestCase {
    // MARK: 1.1 should collect by time
    public func testCollectByTime() {
        let subject = PassthroughSubject<Int, TestingError>()
        let scheduler = VirtualTimeScheduler()
        let pub = subject.collect(.byTime(scheduler, .seconds(2)))
        var downstreamSubscription: Subscription?
        let tracking = TrackingSubscriberBase<[Int], TestingError>(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: { _ in .none}
        )

        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CollectByTime")])

        downstreamSubscription?.request(.unlimited)

        subject.send(1)
        subject.send(2)
        scheduler.rewind(to: .seconds(2))
        subject.send(3)
        subject.send(4)
        subject.send(5)
        scheduler.rewind(to: .seconds(3))
        subject.send(completion: .failure("ooops"))
        let expectedValues: TrackingSubscriberBase<[Int], TestingError>.Event = .value([1, 2])
        XCTAssertEqual(tracking.history, [.subscription("CollectByTime")] + [expectedValues])
    }

    // MARK: 1.2 should collect by time then send unsent values if upstream finishes
    public func testUpstreamFinishes() {
        let subject = PassthroughSubject<Int, TestingError>()
        let scheduler = VirtualTimeScheduler()
        let pub = subject.collect(.byTime(scheduler, .seconds(2)))
        var downstreamSubscription: Subscription?
        let tracking = TrackingSubscriberBase<[Int], TestingError>(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: { _ in .none}
        )

        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CollectByTime")])

        downstreamSubscription?.request(.unlimited)

        subject.send(1)
        subject.send(2)
        scheduler.rewind(to: .seconds(2))
        subject.send(3)
        subject.send(4)
        subject.send(5)
        scheduler.rewind(to: .seconds(3))
        subject.send(completion: .finished)
        scheduler.rewind(to: .seconds(4))

        XCTAssertEqual(tracking.history, [.subscription("CollectByTime")] + [.value([1, 2]), .value([3, 4, 5])] + [.completion(.finished)])
    }

    // MARK: 1.3 should collect by count
    public func testCollectByCount() {
        let subject = PassthroughSubject<Int, TestingError>()
        let scheduler = VirtualTimeScheduler()
        let pub = subject.collect(.byTimeOrCount(scheduler, .seconds(2), 2))
        var downstreamSubscription: Subscription?
        let tracking = TrackingSubscriberBase<[Int], TestingError>(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: { _ in .none}
        )

        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CollectByTime")])

        downstreamSubscription?.request(.unlimited)

        subject.send(1)
        subject.send(2)
        subject.send(3)
        scheduler.rewind(to: .seconds(2))
        subject.send(4)
        subject.send(5)
        subject.send(6)
        subject.send(7)
        subject.send(8)
        scheduler.rewind(to: .seconds(4))
        subject.send(completion: .finished)
        scheduler.rewind(to: .seconds(6))

        XCTAssertEqual(tracking.history, [.subscription("CollectByTime")] +
            [.value([1, 2]),
             .value([3]),
             .value([4, 5]),
             .value([6, 7]),
             .value([8])] + [.completion(.finished)])
    }

    // MARK: 1.4 should send as many as demand when strategy is by time
    public func testDemand() {
        let subject = PassthroughSubject<Int, TestingError>()
        let scheduler = VirtualTimeScheduler()
        let pub = subject.collect(.byTime(scheduler, .seconds(1)))
        var downstreamSubscription: Subscription?
        let tracking = TrackingSubscriberBase<[Int], TestingError>(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: {  v in Set(v).isDisjoint(with: [0, 5]) ? .none : .max(1) }
        )

        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CollectByTime")])

        downstreamSubscription?.request(.max(2))

        var initialTime = 0
        for i in 1...100 {
            if i % 3 == 0 {
                initialTime += 1
                scheduler.rewind(to: .seconds(initialTime))
            }
            subject.send(i)
        }

        XCTAssertEqual(tracking.history.count, 4)
    }

    // MARK: 1.5 should always request 1 when strategy is by time
    public func testStrategy() {
        var downstreamSubscription: Subscription?
        let subject = CustomPublisher(subscription: CustomSubscription())
        let scheduler = VirtualTimeScheduler()
        let pub = subject.collect(.byTime(scheduler, .seconds(1)))
        let tracking = TrackingSubscriberBase<[Int], TestingError>(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: { v in Set(v).isDisjoint(with: [0, 5]) ? .none : .max(2) }
        )

        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CollectByTime")])

        downstreamSubscription?.request(.max(2))

        var requestList: [Subscribers.Demand] = []
        var initialTime = 0
        for i in 1...100 {
            if i % 3 == 0 {
                initialTime += 1
                scheduler.rewind(to: .seconds(initialTime))
            }
            requestList.append(subject.send(i))
        }

        XCTAssertNotNil(downstreamSubscription)
        XCTAssertEqual(requestList.count, 100)

        for demand in requestList {
            XCTAssertEqual(demand, .max(1))
        }
    }
}
