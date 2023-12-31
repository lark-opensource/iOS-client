//
//  GadgetRecoveryResponder.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK

protocol GadgetRecoveryResponder {
    func respondGadgetRecovery(with context: RecoveryContext)
}
