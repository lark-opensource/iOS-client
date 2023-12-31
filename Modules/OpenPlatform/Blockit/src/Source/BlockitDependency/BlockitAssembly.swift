//
//  BlockitAssembly.swift
//  Blockit
//
//  Created by 夏汝震 on 2020/10/10.
//

import Swinject
import LarkAccountInterface
import LarkSetting
import LarkLocalizations
import LarkRustClient
import RustPB
import RxSwift
import LKCommonsLogging
import OPBlockInterface
import LarkFoundation
import LarkContainer
import LarkAssembler
import LarkDebugExtensionPoint
import ECOInfra

public final class BlockitAssembly: LarkAssemblyInterface {
    private let disposeBag: DisposeBag = DisposeBag()
    public init() {}
    static let logger = Logger.log(BlockitAssembly.self, category: "BlockitSDK")

    public func registContainer(container: Container) {
        let user = container.inObjectScope(BlockScope.userScope)
        let userGraph = container.inObjectScope(BlockScope.userGraph)

        user.register(BlockitConfig.self) { r in
            let userService = try r.resolve(assert: PassportUserService.self)
            let passportService = try r.resolve(assert: PassportService.self)
            let token = userService.user.sessionKey ?? ""
            let deviceId = passportService.deviceID
            return BlockitConfig(token: token, deviceId: deviceId)
        }

        user.register(BlockitAPI.self) { r in
            let netStatusService = try r.resolve(assert: OPNetStatusHelper.self)
            let config = try r.resolve(assert: BlockitConfig.self)
            let network = try r.resolve(assert: HttpClientManager.self)
            return BlockitAPI(
                netStatusService: netStatusService,
                config: config,
                network: network
            )
        }

        user.register(HttpClientManager.self) { r in
            let config = try r.resolve(assert: BlockitConfig.self)
            return HttpClientManager(config: config)
        }

        user.register(BlockSyncMessageManager.self) { r in
            let api = try r.resolve(assert: BlockitAPI.self)
            let config = try r.resolve(assert: BlockitConfig.self)
            let rustAPI = try r.resolve(assert: BlockSyncMessageRustAPI.self)
            return BlockSyncMessageManager(api: api, config: config, rustAPI: rustAPI)
        }

        userGraph.register(BlockitService.self) { r in
            let api = try r.resolve(assert: BlockitAPI.self)
            let syncMessageManager = try r.resolve(assert: BlockSyncMessageManager.self)
            let preLoadService = try r.resolve(assert: OPBlockPreUpdateProtocol.self)
            return Blockit(
                userResolver: r,
                api: api,
                syncMessageManager: syncMessageManager,
                preLoadService: preLoadService
            )
        }

        user.register(BlockSyncMessageRustAPI.self) { r in
            let rustService = try r.resolve(assert: RustService.self)
            return BlockSyncMessageRustAPIImpl(rustService: rustService)
        }
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.syncPushMessageBlock, RustSyncPushMessageHandler.init(resolver:))
        (Command.syncPushEventBlock, RustSyncPushEventHandler.init(resolver:))
    }
}
