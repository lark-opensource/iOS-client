//
//  UGRuleMockAssembly.swift
//  UGRule
//
//  Created by zhenning on 2021/1/21.
//

import Foundation
import Swinject

public class UGRuleMockAssembly: Assembly {
    public init() { }

    public func assemble(container: Container) {
        assembleService(container: container)
    }

    private func assembleService(container: Container) {

    }
}
