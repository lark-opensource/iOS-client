//
//  ViewTests.swift
//  ViewTests
//
//  Created by Yuri on 2023/5/31.
//

import XCTest
import FBSnapshotTestCase

class ViewTestCase: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func verify(_ view: UIView) {
        FBSnapshotVerifyView(view)
    }
}
