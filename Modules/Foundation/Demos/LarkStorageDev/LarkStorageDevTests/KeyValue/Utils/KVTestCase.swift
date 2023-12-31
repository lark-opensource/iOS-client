//
//  KVTestCase.swift
//  LarkStorageDevTests
//
//  Created by 李昊哲 on 2023/4/10.
//  

import Foundation
import XCTest
import LarkStorage

//// 在该测试类中调用 disposed(store:) 方法，可在测试方法结束或者整个测试类结束后，自动清除 store
open class KVTestCase: XCTestCase {
    // 针对整个测试类的 bag
    static var storeBag: KVStoreBag?

    open override class func setUp() {
        super.setUp()
        storeBag = KVStoreBag()
    }
    
    open override class func tearDown() {
        super.tearDown()
        storeBag = nil
    }

    // 针对单个测试方法的 bag
    var storeBag: KVStoreBag?

    open override func setUp() {
        super.setUp()
        storeBag = KVStoreBag()
    }

    open override func tearDown() {
        super.tearDown()
        storeBag = nil
    }

//    class func disposed<T: KVStore>(store: T) -> T {
//        XCTAssertNotNil(storeBag)
//        if let storeBag {
//            return store.disposed(storeBag)
//        }
//        return store
//    }
//
//    class func disposed<T: KVStore>(store: T?) -> T? {
//        XCTAssertNotNil(storeBag)
//        if let storeBag {
//            return store?.disposed(storeBag)
//        }
//        return store
//    }

//    func disposed<T: KVStore>(store: T) -> T {
//        XCTAssertNotNil(storeBag)
//        if let storeBag {
//            return store.disposed(storeBag)
//        }
//        return store
//    }
//
//    func disposed<T: KVStore>(store: T?) -> T? {
//        XCTAssertNotNil(storeBag)
//        if let storeBag {
//            return store?.disposed(storeBag)
//        }
//        return store
//    }
}

extension KVStore {
    func disposed(_ testCase: KVTestCase) -> Self {
        XCTAssertNotNil(testCase.storeBag)
        if let bag = testCase.storeBag {
            return disposed(bag)
        }
        return self
    }

    func disposed(_ caseType: KVTestCase.Type) -> Self {
        XCTAssertNotNil(caseType.storeBag)
        if let bag = caseType.storeBag {
            return disposed(bag)
        }
        return self
    }
}
