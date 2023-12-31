//
//  IsoPath+Config.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension IsoPath {
    /// 使用加密
    public func usingCipher(suite: SBCipherSuite = .default) -> IsoPath {
        let newSandbox = SandboxIsoDynamicCryptoProxy(wrapped: sandbox, suite: suite)
        let ret = IsoPath(base: base, sandbox: newSandbox)
        ret.context[IsoPath.ContextKeys.cryptoSuite.rawValue] = suite
        return ret
    }
}

extension IsoPath {
    private func setContext(key: ContextKeys, value: Any) {
        context[key.rawValue] = value
    }
}

extension IsoPath {
    /// 配置加密，接口还未验证，后续启用，替代 `usingCipher(suite:)`
    func setCrypto(suite: SBCipherSuite = .default) {
        setContext(key: .cryptoSuite, value: suite)
    }
}
