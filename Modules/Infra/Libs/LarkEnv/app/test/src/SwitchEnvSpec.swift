//
//  SwitchEnvSpec.swift
//  LarkEnvDevEEUnitTest
//
//  Created by Yiming Qu on 2021/1/26.
//

import Foundation
import XCTest
import RxSwift
@testable import LarkEnv

class Test1EnvDelegate: EnvDelegate {
    var name: String = "Test1"

    func config() -> EnvDelegateConfig {
        return [
            .before: .highest
        ]
    }

    func beforeSwitch(_ env: Env) -> Observable<Void> {
        return .just(())
    }

}

class Test2EnvDelegate: EnvDelegate {
    var name: String = "Test2"

    func config() -> EnvDelegateConfig {
        return [
            .before: .high
        ]
    }

    func beforeSwitch(_ env: Env) -> Observable<Void> {
        return .just(())
    }
}

enum TestError: Error {
    case beforeError
}

class TestErrorEnvDelegate: EnvDelegate {
    var name: String = "Test3"

    func config() -> EnvDelegateConfig {
        return [
            .before: .medium
        ]
    }

    func beforeSwitch(_ env: Env) -> Observable<Void> {
        return .error(TestError.beforeError)
    }
}

class Test4AfterEnvDelegate: EnvDelegate {

    let afterSwitchBlock: (Result<Env, Error>) -> Void

    init(afterSwitchBlock: @escaping (Result<Env, Error>) -> Void) {
        self.afterSwitchBlock = afterSwitchBlock
    }

    var name: String = "Test4"

    func config() -> EnvDelegateConfig {
        return [
            .after: .highest
        ]
    }

    func afterSwitch(_ result: Result<Env, Error>) {
        afterSwitchBlock(result)
    }
}

class SwitchEnvSpec: XCTestCase {

    var disposeBag = DisposeBag()

    override func setUpWithError() throws {
        disposeBag = DisposeBag()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        EnvDelegateRegistry.factories.removeAll()
        EnvDelegateRegistry.delegatesCache.removeAll()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSwitchSuccess() throws {
        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
            return Test1EnvDelegate()
        }))
        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
            return Test2EnvDelegate()
        }))
        let completedExpectation = expectation(description: "track")
        let payload = ["EnvDelegate.EnvPayloadKey.Brand": "feishu"]
        EnvManager.switchEnv(.oversea, payload: payload)
            .subscribe(onNext: { _ in
                completedExpectation.fulfill()
            })
            .disposed(by: disposeBag)
        waitForExpectations(timeout: 1, handler: nil)
    }

//    func testSwitchError() throws {
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return Test1EnvDelegate()
//        }))
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return Test2EnvDelegate()
//        }))
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return TestErrorEnvDelegate()
//        }))
//        let completedExpectation = expectation(description: "track")
//        let payload = ["EnvDelegate.EnvPayloadKey.Brand": "feishu"]
//        EnvManager.switchEnv(.oversea, payload: payload)
//            .subscribe(onError: { _ in
//                completedExpectation.fulfill()
//            })
//            .disposed(by: disposeBag)
//        waitForExpectations(timeout: 1, handler: nil)
//    }

//    func testSwitchSuccessAfterSwitch() {
//        let completedExpectation = expectation(description: "track")
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return Test1EnvDelegate()
//        }))
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return Test2EnvDelegate()
//        }))
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return Test4AfterEnvDelegate { (_) in
//                completedExpectation.fulfill()
//            }
//        }))
//        let payload = ["EnvDelegate.EnvPayloadKey.Brand": "feishu"]
//        EnvManager.switchEnv(.oversea, payload: payload)
//            .subscribe()
//            .disposed(by: disposeBag)
//        waitForExpectations(timeout: 1, handler: nil)
//    }

//    func testSwitchFailAfterSwitch() {
//        let completedExpectation = expectation(description: "track")
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return Test1EnvDelegate()
//        }))
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return Test2EnvDelegate()
//        }))
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return TestErrorEnvDelegate()
//        }))
//        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
//            return Test4AfterEnvDelegate { (_) in
//                completedExpectation.fulfill()
//            }
//        }))
//        let payload = ["EnvDelegate.EnvPayloadKey.Brand": "feishu"]
//        EnvManager.switchEnv(.oversea, payload: payload)
//            .subscribe()
//            .disposed(by: disposeBag)
//        waitForExpectations(timeout: 1, handler: nil)
//    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
