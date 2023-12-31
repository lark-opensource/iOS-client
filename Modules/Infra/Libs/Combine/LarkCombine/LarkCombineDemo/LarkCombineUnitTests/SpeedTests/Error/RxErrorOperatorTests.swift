//
//  RxErrorOperatorTests.swift
//  SpeedTestTests
//
//  Created by bytedance on 2020/8/18.
//  Copyright © 2020 QuickBird Studios. All rights reserved.
//

import Foundation
import RxSwift
import XCTest

class RxErrorTests: XCTestCase {
    enum Error: Swift.Error {
        case testError
    }

    func testCatchErrorWithCreate() {
        measure {
            let sum = 0

            for _ in 0 ..< iterations {
                let subscription = Observable<Int>
                    .create { observer in
                        observer.onError(Error.testError)
                        return Disposables.create()
                }
                .catchError { _ in Observable<Int>
                .create { observer in
                    observer.onError(Error.testError)
                    return Disposables.create()
                    }
                }
                .catchError { _ in Observable<Int>
                    .create { observer in
                        observer.onError(Error.testError)
                        return Disposables.create()
                    }
                }
                .catchError { _ in Observable<Int>
                .create { observer in
                    observer.onError(Error.testError)
                    return Disposables.create()
                    }
                }
                .catchError { _ in Observable<Int>
                .create { observer in
                    observer.onError(Error.testError)
                    return Disposables.create()
                    }
                }
                .catchError { _ in Observable<Int>
                .create { observer in
                    observer.onError(Error.testError)
                    return Disposables.create()
                    }
                }
                .subscribe(onNext: { _ in })

                subscription.dispose()
            }

            XCTAssertEqual(sum, 0)
        }
    }
}
