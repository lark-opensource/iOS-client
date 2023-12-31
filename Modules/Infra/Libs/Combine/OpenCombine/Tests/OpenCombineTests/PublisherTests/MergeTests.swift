//
//  MergeTests.swift
//
//
//  Created by Sergej Jaskiewicz on 06.01.2020.
//

import Foundation
import XCTest

#if OPENCOMBINE_COMPATIBILITY_TEST
import Combine
#else
import OpenCombine
#endif

@available(macOS 10.15, iOS 13.0, *)
final class MergeTests: XCTestCase {

    // MARK: basic function test
    func testMergeLimitedInitialDemand() {
        func test<Merger: Publisher>(
            forArity arity: Int,
            _ makeMerger: ([PassthroughSubject<Int, TestingError>]) -> Merger
        ) where Merger.Output == Int, Merger.Failure == TestingError {
            let publishers = (0..<arity).map { _ in PassthroughSubject<Int, TestingError>() }
            let merger = makeMerger(publishers)
            var downstreamSubscription: Subscription?
            let tracking = TrackingSubscriber(
                receiveSubscription: { downstreamSubscription = $0 },
                receiveValue: { _ in .none}
            )
            merger.subscribe(tracking)
            downstreamSubscription?.request(arity == 0 ? .max(1) : .max(arity))

            if(arity == 0){
                XCTAssertEqual(tracking.history, [.subscription("Merge"), .completion(.finished)])
                return
            }

            for i in 1...arity {
                publishers.randomElement()!.send(i)
            }
            let expectedValues: [TrackingSubscriber.Event] = (1 ... arity).map { .value($0) }
            XCTAssertEqual(tracking.history, [.subscription("Merge")] + expectedValues)
        }

        test(forArity: 2) { publishers in
            Publishers.Merge(publishers[0],
                             publishers[1])
        }

        test(forArity: 3) { publishers in
            Publishers.Merge3(publishers[0],
                              publishers[1],
                              publishers[2])
        }

        test(forArity: 4) { publishers in
            Publishers.Merge4(publishers[0],
                              publishers[1],
                              publishers[2],
                              publishers[3])
        }

        test(forArity: 4) { publishers in
            Publishers.Merge4(publishers[0],
                              publishers[1],
                              publishers[2],
                              publishers[3])
        }

        test(forArity: 5) { publishers in
            Publishers.Merge5(publishers[0],
                              publishers[1],
                              publishers[2],
                              publishers[3],
                              publishers[4])
        }

        test(forArity: 6) { publishers in
            Publishers.Merge6(publishers[0],
                              publishers[1],
                              publishers[2],
                              publishers[3],
                              publishers[4],
                              publishers[5])
        }

        test(forArity: 7) { publishers in
            Publishers.Merge7(publishers[0],
                              publishers[1],
                              publishers[2],
                              publishers[3],
                              publishers[4],
                              publishers[5],
                              publishers[6])
        }

        test(forArity: 8) { publishers in
            Publishers.Merge8(publishers[0],
                              publishers[1],
                              publishers[2],
                              publishers[3],
                              publishers[4],
                              publishers[5],
                              publishers[6],
                              publishers[7])
        }

        test(forArity: 0) { _ in
            Publishers.MergeMany<CustomPublisher>()
        }

        test(forArity: 2) { publishers in
            Publishers.MergeMany(publishers[0], publishers[1])
        }

        test(forArity: 20) { publishers in
            Publishers.MergeMany(publishers)
        }
    }

    // MARK: test reflection
    func testMergeReflection() throws {
        func testMergeSubscriptionReflection<Sut: Publisher>(_ sut: Sut) throws {
            try testSubscriptionReflection(
                description: "Merge",
                customMirror: childrenIsEmpty,
                playgroundDescription: "Merge",
                sut: sut
            )
        }
        
        func testMergeSideReflection<Merger: Publisher>(
            _ makeMerger: (CustomPublisher) -> Merger
        ) throws where Merger.Output == Int, Merger.Failure == TestingError {
            try testReflection(parentInput: Int.self,
                               parentFailure: TestingError.self,
                               description: "Merge",
                               customMirror: expectedChildren(
                                   ("parentSubscription", .anything)
                               ),
                               playgroundDescription: "Merge",
                               subscriberIsAlsoSubscription: false,
                               makeMerger)
            let publisher = CustomPublisher(subscription: CustomSubscription())
            let merger = makeMerger(publisher)
            let tracking = TrackingSubscriber()
            merger.subscribe(tracking)
            let side = try XCTUnwrap(publisher.erasedSubscriber)
            let expectedParentID =
                try XCTUnwrap(tracking.subscriptions.first?.combineIdentifier)
            let actualParentID = Mirror(reflecting: side)
                .descendant("parentSubscription") as? CombineIdentifier
            XCTAssertEqual(expectedParentID, actualParentID)
        }

        let publisher = CustomPublisher(subscription: CustomSubscription())

        try testMergeSubscriptionReflection(
            publisher.merge(with: publisher) as Publishers.Merge
        )
        try testMergeSideReflection {
            $0.merge(with: publisher) as Publishers.Merge
        }

        try testMergeSubscriptionReflection(
            publisher.merge(with: publisher,
                            publisher) as Publishers.Merge3
        )
        try testMergeSideReflection {
            $0.merge(with: publisher,
                     publisher) as Publishers.Merge3
        }

        try testMergeSubscriptionReflection(
            publisher.merge(with: publisher,
                            publisher,
                            publisher) as Publishers.Merge4
        )
        try testMergeSideReflection {
            $0.merge(with: publisher,
                     publisher,
                     publisher) as Publishers.Merge4
        }

        try testMergeSubscriptionReflection(
            publisher.merge(with: publisher,
                            publisher,
                            publisher,
                            publisher) as Publishers.Merge5
        )
        try testMergeSideReflection {
            $0.merge(with: publisher,
                     publisher,
                     publisher,
                     publisher) as Publishers.Merge5
        }

        try testMergeSubscriptionReflection(
            publisher.merge(with: publisher,
                            publisher,
                            publisher,
                            publisher,
                            publisher) as Publishers.Merge6
        )
        try testMergeSideReflection {
            $0.merge(with: publisher,
                     publisher,
                     publisher,
                     publisher,
                     publisher) as Publishers.Merge6
        }

        try testMergeSubscriptionReflection(
            publisher.merge(with: publisher,
                            publisher,
                            publisher,
                            publisher,
                            publisher,
                            publisher) as Publishers.Merge7
        )
        try testMergeSideReflection {
            $0.merge(with: publisher,
                     publisher,
                     publisher,
                     publisher,
                     publisher,
                     publisher) as Publishers.Merge7
        }

        try testMergeSubscriptionReflection(
            publisher.merge(with: publisher,
                            publisher,
                            publisher,
                            publisher,
                            publisher,
                            publisher,
                            publisher) as Publishers.Merge8
        )
        try testMergeSideReflection {
            $0.merge(with: publisher,
                     publisher,
                     publisher,
                     publisher,
                     publisher,
                     publisher,
                     publisher) as Publishers.Merge8
        }

        try testMergeSubscriptionReflection(
            publisher.merge(with: publisher) as Publishers.MergeMany
        )
        try testMergeSideReflection {
            $0.merge(with: $0) as Publishers.MergeMany
        }
    }
}
