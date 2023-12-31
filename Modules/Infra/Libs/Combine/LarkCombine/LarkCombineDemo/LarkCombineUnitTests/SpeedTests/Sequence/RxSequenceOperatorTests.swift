//
//  RxSequenceOperatorTests.swift
//  SpeedTestTests
//
//  Created by bytedance on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import RxSwift
import XCTest

class RxSequenceOperatorTests: XCTestCase {
    func testSkipWithEvent() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
            }
            .skip(1)
            .subscribe(onNext: { x in sum += x })

            subscription.dispose()

            XCTAssertEqual(sum, iterations-1)
        }
    }

    func testSkipWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        observer.on(.next(1))
                        return Disposables.create()
                }
                .skip(1)
                .subscribe(onNext: { x in sum += x })

                subscription.dispose()
            }

            XCTAssertEqual(sum, 0)
        }
    }

    func testConcatEvent() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
            }
            .concat(Observable.of(2))
            .subscribe(onNext: { x in sum += x })

            subscription.dispose()

            XCTAssertEqual(sum, iterations)
        }
    }

    func testConcatWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        observer.on(.next(1))
                        return Disposables.create()
                }
                .concat(Observable.of(2))
                .subscribe(onNext: { x in sum += x })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testTakeUntilWithEvent() {
        measure {
            var sum = 0

            let stop = PublishSubject<Int>()
            let subscription = Observable<Int>
                .create { observer in
                    stop.onNext(1)
                    for i in 0 ..< iterations {
                        observer.on(.next(1))
                        if i == 1 {
                            stop.onNext(1)
                        }
                    }
                    return Disposables.create()
            }
            .takeUntil(stop)
            .subscribe(onNext: { x in sum += x })

            subscription.dispose()

            XCTAssertEqual(sum, 0)
        }
    }

    func testTakeUntilWithCreate() {
        measure {
            var sum = 0

            let stop = PublishSubject<Int>()
            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        stop.onNext(1)
                        observer.on(.next(1))
                        return Disposables.create()
                }
                .takeUntil(stop)
                .subscribe(onNext: { x in sum += x })

                subscription.dispose()
            }

            XCTAssertEqual(sum, 0)
        }
    }
}
