//
//  ViewTests.swift
//  ViewTests
//
//  Created by Yuri on 2023/1/5.
//

import UIKit
import Foundation
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
