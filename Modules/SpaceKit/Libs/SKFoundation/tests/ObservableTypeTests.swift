//
//  ObservableTypeTests.swift
//  SKFoundation_Tests-Unit-_Tests
//
//  Created by huayufan on 2022/10/9.
//  


import UIKit
import XCTest
@testable import SKFoundation
import RxCocoa
import RxSwift

class ObservableTypeTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testBufferBeforTrigger() {
        let disposeBag = DisposeBag()
        
        let stringSubject = PublishSubject<String>()
        let trigger = BehaviorRelay<Bool>(value: false)
        var arr: [String] = []
        stringSubject.bufferBeforTrigger(trigger).subscribe { s in
            arr.append(s)
        }.disposed(by: disposeBag)
        
        stringSubject.onNext("🅰️")
        stringSubject.onNext("🅱️")
        XCTAssertTrue(arr.isEmpty)
        
        trigger.accept(true)
        XCTAssertTrue(arr.count == 2)
        
        stringSubject.onNext("⚽️")
        XCTAssertTrue(arr.count == 3)
        
        stringSubject.onNext("🍷")
        XCTAssertTrue(arr.count == 4)
        
        trigger.accept(false)
        stringSubject.onNext("🍾")
        XCTAssertTrue(arr.count == 4)
        
        trigger.accept(true)
        XCTAssertTrue(arr.count == 5)
        
        stringSubject.onNext("🥗")
        XCTAssertTrue(arr.count == 6)
        
    }
}
