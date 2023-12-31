//
//  SuiteLoginAfterAccountLoaded.swift
//  LarkAccount
//
//  Created by KT on 2020/7/7.
//

import Foundation
import BootManager

class SuiteLoginAfterAccountLoaded: FlowBootTask, Identifiable {

    static var identify = "SuiteLoginAfterAccountLoaded"

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        AccountIntegrator.shared.adjustLogger()
    }
}
