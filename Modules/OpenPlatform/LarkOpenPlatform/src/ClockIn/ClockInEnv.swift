//
//  ClockInEnv.swift
//  LarkOpenPlatform
//
//  Created by zhaojingxin on 2022/3/4.
//

import Foundation

protocol OPClockInEnv {

    var speedClockRefactorEnabled: Bool? { get set }
}

final class OPClockInEnvIMP: OPClockInEnv {

    var speedClockRefactorEnabled: Bool?

}
