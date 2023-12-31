//
//  RxSwiftReduceTests.swift
//  SpeedTestTests
//
//  Created by 李晨 on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import XCTest
import RxSwift

class RxSwiftReduceTests: XCTestCase {

    func testReducePumping() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations * 10 {
                        observer.on(.next(1))
                    }
                    observer.onCompleted()
                    return Disposables.create()
            }
            .reduce(0, accumulator: { (a, b) -> Int in return a + b })
            .reduce(0, accumulator: { (a, b) -> Int in return a + b })
            .reduce(0, accumulator: { (a, b) -> Int in return a + b })
            .reduce(0, accumulator: { (a, b) -> Int in return a + b })
            .reduce(0, accumulator: { (a, b) -> Int in return a + b })
            .subscribe(onNext: { x in
                sum += x
            })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testReduceCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        for _ in 0 ..< 1 {
                            observer.on(.next(1))
                        }
                        observer.onCompleted()
                        return Disposables.create()
                }
                .reduce(0, accumulator: { (a, b) -> Int in return a + b })
                .reduce(0, accumulator: { (a, b) -> Int in return a + b })
                .reduce(0, accumulator: { (a, b) -> Int in return a + b })
                .reduce(0, accumulator: { (a, b) -> Int in return a + b })
                .reduce(0, accumulator: { (a, b) -> Int in return a + b })
                .subscribe(onNext: { x in
                    sum += x
                })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testCollectPumping() {
        measure {
            var sum = 0
            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations * 10 {
                        observer.on(.next(1))
                    }
                    observer.onCompleted()
                    return Disposables.create()
            }
            .toArray()
            .asObservable()
            .subscribe(onNext: { x in
                sum += x.count
            })

            subscription.dispose()

            XCTAssertEqual(sum, iterations * 10)
        }
    }

    func testCollectCreating() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        for _ in 0 ..< 1 {
                            observer.on(.next(1))
                        }
                        observer.onCompleted()
                        return Disposables.create()
                }
                .toArray()
                .asObservable()
                .subscribe(onNext: { x in
                    sum += x.count
                })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }
}
