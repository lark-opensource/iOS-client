//
//  SandboxProxy.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

/// Sandbox Proxy
public class SandboxProxy<RawPath: PathType>: Sandbox<RawPath> {

    private let initialWrapped: Sandbox<RawPath>

    var wrapped: Sandbox<RawPath> { initialWrapped }

    init(wrapped: Sandbox<RawPath>) {
        self.initialWrapped = wrapped
    }

    public override func forwardResponder() -> ForwardResponder {
        return .sandbox(wrapped)
    }
}
