//
//  RxSelectingOperatorTests.swift
//  SpeedTestTests
//
//  Created by bytedance on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import RxSwift
import XCTest

class RxSelectingOperatorTests: XCTestCase {
    func testFirstWithEvent() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
            }
            .first().asObservable()
            .subscribe(onNext: { x in
                sum += x!
                return
            })

            subscription.dispose()

            XCTAssertEqual(sum, 1)
        }
    }

    func testFirstWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        observer.on(.next(1))
                        return Disposables.create()
                }
                .first().asObservable()
                .subscribe(onNext: { x in
                    sum += x!
                    return
                })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

    func testLastWithEvent() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
            }
            .takeLast(1)
            .subscribe(onNext: { x in
                sum += x
                return
            })

            subscription.dispose()

            XCTAssertEqual(sum, 0)
        }
    }

    func testLastWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        observer.on(.next(1))
                        return Disposables.create()
                }
                .takeLast(1)
                .subscribe(onNext: { x in
                    sum += x
                    return
                })

                subscription.dispose()
            }
            XCTAssertEqual(sum, 0)
        }

    }

    func testElementAtWithEvent() {
        measure {
            var sum = 0

            let subscription = Observable<Int>
                .create { observer in
                    for _ in 0 ..< iterations {
                        observer.on(.next(1))
                    }
                    return Disposables.create()
            }
            .elementAt(0)
            .subscribe(onNext: { x in
                sum += x
                return
            })
            subscription.dispose()

            XCTAssertEqual(sum, 1)
        }
    }

    func testElementAtWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        observer.on(.next(1))
                        return Disposables.create()
                }
                .elementAt(0)
                .subscribe(onNext: { x in
                    sum += x
                    return
                })

                subscription.dispose()
            }

            XCTAssertEqual(sum, iterations)
        }
    }

}
