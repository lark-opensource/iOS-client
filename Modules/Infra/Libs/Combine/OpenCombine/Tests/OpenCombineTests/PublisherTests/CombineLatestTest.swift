//
//  CombineLatestTests.swift
//
//
//  Created by wangyuanxun on 08.11.2020.
//

import Foundation
import XCTest

#if OPENCOMBINE_COMPATIBILITY_TEST
import Combine
#else
import OpenCombine
#endif

@available(macOS 10.15, iOS 13.0, *)
final class CombineLatestTests: XCTestCase {
    // MARK: 1.1 should combine latest of 2
    func testCombineLatest2() {
        let subject0 = PassthroughSubject<Int, TestingError>()
        let subject1 = PassthroughSubject<Int, TestingError>()
        var downstreamSubscription: Subscription?
        let tracking = TrackingSubscriber(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: { _ in .none}
        )

        let pub = subject0.combineLatest(subject1, +)
        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CombineLatest")])

        downstreamSubscription?.request(.unlimited)

        subject0.send(0)
        subject0.send(1)
        subject1.send(2)

        subject0.send(3)
        subject1.send(4)
        subject1.send(5)

        let expectedValues: [TrackingSubscriber.Event] = [3, 5, 7, 8].map { .value($0) }
        XCTAssertEqual(tracking.history, [.subscription("CombineLatest")] + expectedValues)
    }

    // MARK: 1.2 should combine latest of 3
    func testCombineLatest3() {
        let subject0 = PassthroughSubject<Int, TestingError>()
        let subject1 = PassthroughSubject<Int, TestingError>()
        let subject2 = PassthroughSubject<Int, TestingError>()
        var downstreamSubscription: Subscription?
        let tracking = TrackingSubscriber(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: { _ in .none}
        )

        let pub = subject0.combineLatest(subject1, subject2, { $0 + $1 + $2 })
        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CombineLatest")])

        downstreamSubscription?.request(.unlimited)

        subject0.send(0)
        subject0.send(1)
        subject0.send(2)
        subject1.send(3)
        subject1.send(4)
        subject2.send(5)

        subject0.send(6)
        subject1.send(7)
        subject1.send(8)
        subject2.send(9)
        subject2.send(10)
        subject2.send(11)

        let expectedValues: [TrackingSubscriber.Event] = [11, 15, 18, 19, 23, 24, 25].map { .value($0) }
        XCTAssertEqual(tracking.history, [.subscription("CombineLatest")] + expectedValues)
    }

    // MARK: 1.3 should finish when one sends an error
    func testCombineLatestErrror() {
        let subjects = (0..<4).map { _ in PassthroughSubject<Int, TestingError>() }
        var downstreamSubscription: Subscription?
        let tracking = TrackingSubscriber(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: { _ in .none}
        )

        let pub = subjects[0].combineLatest(subjects[1], subjects[2], subjects[3]) {
            $0 + $1 + $2 + $3
        }
        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CombineLatest")])

        downstreamSubscription?.request(.unlimited)

        for i in 0...9 {
            subjects[i%4].send(i)
        }
        subjects[3].send(completion: .failure("ooops"))

        let expectedValues: [TrackingSubscriber.Event] = [6, 10, 14, 18, 22, 26, 30].map { .value($0) }
        XCTAssertEqual(tracking.history, [.subscription("CombineLatest")] + expectedValues + [.completion(.failure("ooops"))])
    }

    // MARK: 1.4 should send as many as demands
    func testCombineLatestDemand() {
        let subjects = (0..<2).map { _ in PassthroughSubject<Int, TestingError>() }
        var downstreamSubscription: Subscription?
        let tracking = TrackingSubscriber(
            receiveSubscription: { downstreamSubscription = $0 },
            receiveValue: { _ in .none }
        )

        let pub = subjects[0].combineLatest(subjects[1], +)
        pub.subscribe(tracking)

        XCTAssertEqual(tracking.history, [.subscription("CombineLatest")])

        downstreamSubscription?.request(.max(51))

        for i in 1...200 {
            subjects[i%2].send(i)
        }

        subjects[0].send(completion: .finished)
        //[.subscription("CombineLatest")] + 51 values
        XCTAssertEqual(tracking.history.count, 52)
    }
}
