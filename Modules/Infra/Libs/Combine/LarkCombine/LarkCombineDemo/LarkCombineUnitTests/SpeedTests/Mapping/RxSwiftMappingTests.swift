//
//  RxSwiftMappingTests.swift
//  SpeedTestTests
//
//  Created by 李晨 on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import XCTest
import RxSwift

class RxSwiftMappingTests: XCTestCase {

    func testMapPumping() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations * 10 {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
            }
            .map { $0 }
            .map { $0 }
            .map { $0 }
            .map { $0 }
            .map { $0 }
            .subscribe(onNext: { x in
                sum += x
            })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testMapCreating() {
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
                .map { $0 }
                .map { $0 }
                .map { $0 }
                .map { $0 }
                .map { $0 }
                .subscribe(onNext: { x in
                    sum += x
                })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testFlatMapsPumping() {
        measure {
            var sum = 0
            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations * 10 {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
                }
                .flatMap { x in Observable.just(x) }
                .flatMap { x in Observable.just(x) }
                .flatMap { x in Observable.just(x) }
                .flatMap { x in Observable.just(x) }
                .flatMap { x in Observable.just(x) }
                .subscribe(onNext: { x in
                    sum += x
                })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testFlatMapsCreating() {
        measure {
            var sum = 0
            for _ in 0 ..< iterations {
                let subscription = Observable<Int>.create { observer in
                    for _ in 0 ..< 1 {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
                }
                .flatMap { x in Observable.just(x) }
                .flatMap { x in Observable.just(x) }
                .flatMap { x in Observable.just(x) }
                .flatMap { x in Observable.just(x) }
                .flatMap { x in Observable.just(x) }
                .subscribe(onNext: { x in
                    sum += x
                })

            subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testScanPumping() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations * 10 {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
            }
            .scan(1, accumulator: { (a, b) -> Int in
                    return a + b
                })
            .subscribe(onNext: { _ in
                sum += 1
            })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testScanCreating() {
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
                .scan(1, accumulator: { (a, b) -> Int in
                    return a + b
                })
                .subscribe(onNext: { _ in
                    sum += 1
                })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }
}
