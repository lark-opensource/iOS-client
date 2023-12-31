//
//  FileCryptoAssembly.swift
//  LarkSecurityCompliance
//
//  Created by 汤泽川 on 2022/12/5.
//

import Foundation
import LarkAssembler
import LarkStorage
import LarkContainer
import AppContainer
import LarkAccountInterface

public final class FileCryptoAssembly: LarkAssemblyInterface {
    public init() { }

    @_silgen_name("Lark.LarkStorage_SandboxCryptoRegistry.FileCryptoAssembly")
    public static func registCipherSuite() {
        SBCipherManager.shared.register(suite: .default) { mode in
            switch mode {
            case .compatible:
                let passportService = BootLoader.container.resolve(PassportService.self)
                guard let userID = passportService?.foregroundUser?.userID else { return nil } // Global
                let resolver = try? BootLoader.container.getUserResolver(userID: userID)
                return try? resolver?.resolve(assert: FileCryptoService.self)
            case .space(let space):
                switch space {
                case .global:
                    return nil
                case .user(id: let userID):
                    let resolver = try? BootLoader.container.getUserResolver(userID: userID)
                    return try? resolver?.resolve(assert: FileCryptoService.self)
                @unknown default:
                    return nil
                }
            @unknown default:
                return nil
            }
        }
        SBCipherManager.shared.register(suite: .writeBack) { mode in
            switch mode {
            case .compatible:
                let passportService = BootLoader.container.resolve(PassportService.self)
                guard let userID = passportService?.foregroundUser?.userID else { return nil } // Global
                let resolver = try? BootLoader.container.getUserResolver(userID: userID)
                return try? resolver?.resolve(assert: FileCryptoWriteBackService.self)
            case .space(let space):
                switch space {
                case .global:
                    return nil
                case .user(id: let userID):
                    let resolver = try? BootLoader.container.getUserResolver(userID: userID)
                    return try? resolver?.resolve(assert: FileCryptoWriteBackService.self)
                @unknown default:
                    return nil
                }
            @unknown default:
                return nil
            }
        }
    }
}
