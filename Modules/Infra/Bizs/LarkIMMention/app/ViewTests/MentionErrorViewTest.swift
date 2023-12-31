//
//  MentionErrorViewTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/1/5.
//

import Foundation
@testable import LarkIMMention

final class MentionErrorViewTest: ViewTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }
    
    /// 长文字
    func testErrorViewWithLongString() {
        let view = IMMentionErrorView()
        view.errorString = "abcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabcabc"
        view.backgroundColor = .white
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 300)
        verify(view)
    }
    
    /// 短文字
    func testErrorViewWithShortString() {
        let view = IMMentionErrorView()
        view.errorString = "abc"
        view.backgroundColor = .white
        view.frame = CGRect(x: 0, y: 0, width: 320, height: 300)
        verify(view)
    }
}
