//
//  MentionViewTest.swift
//  ViewTests
//
//  Created by Yuri on 2023/1/5.
//

import Foundation
import XCTest
@testable import LarkIMMention

final class MentionViewTest: ViewTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }
    
    /// Mention View
    func testMentionView() {
        let view = IMMentionView()
        view.frame = CGRect(x: 0, y: 0, width: 375, height: 800)
        verify(view)
    }

}
