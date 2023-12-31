//
//  SandboxBase.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import LKCommonsLogging

/// Real Sandbox
final class SandboxBase<Path: PathType>: Sandbox<Path> {
    let fm = FileManager()

    override func forwardResponder() -> ForwardResponder {
        return .manager(fm)
    }
}
