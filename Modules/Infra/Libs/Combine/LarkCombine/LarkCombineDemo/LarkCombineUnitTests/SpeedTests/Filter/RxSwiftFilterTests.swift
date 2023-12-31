//
//  RxSwiftFilterTests.swift
//  SpeedTestTests
//
//  Created by 李晨 on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import XCTest
import RxSwift

class RxSwiftFilterTests: XCTestCase {

    func testFilterPumping() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations * 10 {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
                }
                .filter { _ in true }
                .filter { _ in true }
                .filter { _ in true }
                .filter { _ in true }
                .filter { _ in true }
                .subscribe(onNext: { x in
                    sum += x
                })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testFilterCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        for _ in 0 ..< 1 {
                            observer.on(.next(1))
                        }
                        return Disposables.create()
                    }
                    .filter { _ in true }
                    .filter { _ in true }
                    .filter { _ in true }
                    .filter { _ in true }
                    .filter { _ in true }
                    .subscribe(onNext: { x in
                        sum += x
                    })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testCompactMapPumping() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations * 10 {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
                }
                .compactMap({ $0 })
                .compactMap({ $0 })
                .compactMap({ $0 })
                .compactMap({ $0 })
                .compactMap({ $0 })
                .subscribe(onNext: { x in
                    sum += x
                })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testCompactMapCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        for _ in 0 ..< 1 {
                            observer.on(.next(1))
                        }
                        return Disposables.create()
                    }
                    .compactMap({ $0 })
                    .compactMap({ $0 })
                    .compactMap({ $0 })
                    .compactMap({ $0 })
                    .compactMap({ $0 })
                    .subscribe(onNext: { x in
                        sum += x
                    })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testDuplicatesPumping() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for i in 0 ..< iterations * 10 {
                        observer.on(.next(i))
                        observer.on(.next(i))
                        observer.on(.next(i))
                        observer.on(.next(i))
                        observer.on(.next(i))
                    }
                    return Disposables.create()
                }
                .distinctUntilChanged()
                .distinctUntilChanged()
                .distinctUntilChanged()
                .distinctUntilChanged()
                .distinctUntilChanged()
                .subscribe(onNext: { x in
                    sum += 1
                })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testDuplicatesCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        for _ in 0 ..< 1 {
                            observer.on(.next(1))
                            observer.on(.next(1))
                            observer.on(.next(1))
                            observer.on(.next(1))
                            observer.on(.next(1))
                        }
                        return Disposables.create()
                    }
                    .distinctUntilChanged()
                    .distinctUntilChanged()
                    .distinctUntilChanged()
                    .distinctUntilChanged()
                    .distinctUntilChanged()
                    .subscribe(onNext: { x in
                        sum += 1
                    })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testReplaceEmptyPumping() {
        measure {
            var sum = 0

            let subscription = Observable<Int?>
                .create { observer in
                    for i in 0 ..< iterations * 10 {
                        observer.on(.next(i))
                        observer.on(.next(nil))
                    }
                    return Disposables.create()
                }
                .ifEmpty(default: 1)
                .ifEmpty(default: 1)
                .ifEmpty(default: 1)
                .ifEmpty(default: 1)
                .ifEmpty(default: 1)
                .subscribe(onNext: { x in
                    sum += 1
                })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10 * 2)
        }
    }

    func testReplaceEmptyCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int?>
                    .create { observer in
                        for _ in 0 ..< 1 {
                            observer.on(.next(1))
                            observer.on(.next(nil))
                        }
                        return Disposables.create()
                    }
                    .ifEmpty(default: 1)
                    .ifEmpty(default: 1)
                    .ifEmpty(default: 1)
                    .ifEmpty(default: 1)
                    .ifEmpty(default: 1)
                    .subscribe(onNext: { x in
                        sum += 1
                    })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations * 2)
        }
    }
}
