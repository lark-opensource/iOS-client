//
//  MagicShareRuntimeImpl+STG.swift
//  ByteView
//
//  Created by chentao on 2020/4/14.
//

import Foundation
import RxSwift

extension MagicShareRuntimeImpl {

    func updateStrategy() {
        var stgs = magicShareDocument.strategies
        if stgs.isEmpty {
            stgs.append(defaultStrategy())
        }
        magicShareAPI.updateStrategies(stgs)
    }
}
