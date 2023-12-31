//
//  KeyboardKitTest.swift
//  LarkKeyboardKitDevEEUnitTest
//
//  Created by 李晨 on 2020/3/20.
//

import Foundation
import XCTest
import UIKit
import RxCocoa
import RxSwift
@testable import LarkKeyboardKit

class KeyboardKitTest: XCTestCase {

    var disposeBag = DisposeBag()

    override func setUp() {
        KeyboardKit.shared.start()
    }

    override func tearDown() {
        KeyboardKit.shared.stop()
        disposeBag = DisposeBag()
    }

    func testKeyboardKit() {
        let textView = UITextView()
        UIApplication.shared.delegate?.window??.addSubview(textView)
        defer {
            textView.removeFromSuperview()
        }
        let e = self.expectation(description: "test")

        var keyboardChange: Int = 0
        var eventChange: Int = 0
        var heightChange: Int = 0

        KeyboardKit.shared.keyboardChange.drive(onNext: { (_) in
            keyboardChange += 1
        }).disposed(by: self.disposeBag)

        KeyboardKit.shared.keyboardEventChange.subscribe(onNext: { (_) in
            eventChange += 1
        }).disposed(by: self.disposeBag)

        KeyboardKit.shared.keyboardHeightChange.drive(onNext: { (_) in
            heightChange += 1
        }).disposed(by: self.disposeBag)

        textView.becomeFirstResponder()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            assert(keyboardChange > 0)
            assert(eventChange > 0)
            assert(heightChange > 0)
            assert(KeyboardKit.shared.current != nil)
            assert(KeyboardKit.shared.currentHeight != 0)

            keyboardChange = 0
            eventChange = 0
            heightChange = 0

            textView.resignFirstResponder()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                assert(keyboardChange > 0)
                assert(eventChange > 0)
                assert(heightChange > 0)
                assert(KeyboardKit.shared.current == nil)
                assert(KeyboardKit.shared.currentHeight == 0)
                e.fulfill()
            }
        }
        self.wait(for: [e], timeout: 3)
    }

    func testFirstResponder() {
        let testView = TestView()
        UIApplication.shared.delegate?.window??.addSubview(testView)
        defer {
            testView.removeFromSuperview()
        }
        testView.becomeFirstResponder()
        assert(KeyboardKit.shared.firstResponder == testView)
        testView.resignFirstResponder()
        assert(KeyboardKit.shared.firstResponder == nil)
    }
}

class TestView: UIView {
    override var canBecomeFirstResponder: Bool {
        return true
    }
}
