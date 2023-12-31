//
//  FakeGadgetControler.swift
//  LarkTourDev
//
//  Created by Meng on 2020/6/19.
//

import Foundation
import LarkUIKit

class FakeGadgetControler: FakeDependencyController {
    override var description: String {
        return "假装你打开了一个小程序"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleString = "FakeGadgetController"
    }
}
