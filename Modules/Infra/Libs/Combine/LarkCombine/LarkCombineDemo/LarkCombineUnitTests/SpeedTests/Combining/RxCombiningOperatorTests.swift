//
//  RxCombiningOperatorTests.swift
//  SpeedTestTests
//
//  Created by bytedance on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import XCTest
import RxSwift

class RxCombiningOperatorTests: XCTestCase {
    func testMergeWithEvent() {
        measure {
            var sum = 0
            let subject0 = PublishSubject<Int>()
            let subject1 = PublishSubject<Int>()

            let disposable = Observable.of(subject0, subject1)
                .merge()
                .subscribe(onNext: { x in
                    sum += x
                    return
                })

            for _ in 0..<iterations {
                subject1.onNext(1)
            }
            disposable.disposed(by: RxSwift.DisposeBag())

            XCTAssertEqual(sum, iterations)
        }
    }

    func testMergeWithCreate() {
        measure {
            var sum = 0

            for _ in 0 ..< iterations {
                let subject0 = PublishSubject<Int>()
                let subject1 = PublishSubject<Int>()

                let disposable = Observable.of(subject0, subject1)
                    .merge()
                    .subscribe(onNext: { x in
                        sum += x
                        return
                    })

                subject1.onNext(1)
                disposable.disposed(by: RxSwift.DisposeBag())
            }

            XCTAssertEqual(sum, iterations)
        }
    }
}

