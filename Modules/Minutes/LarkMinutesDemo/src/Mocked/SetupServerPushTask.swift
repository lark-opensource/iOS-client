//
//  SetupServerPushTask.swift
//  LarkRustClient
//
//  Created by huangjianming on 2020/12/17.
//

import Foundation
import BootManager
import LarkContainer
import RustPB
import LarkRustClient
import OPFoundation


public class SetupServerPushTask: FlowBootTask, Identifiable {
    public static var identify = "SetupServerPushTask"
    @InjectedLazy private var rustService: RustService

    public override func execute(_ context: BootContext) {
        var command = [Int32]()
        ServerPushHandlerRegistry.shared.getPushHandlers().forEach { (dict) in
            let cmds = dict.keys.map { (cmd) -> Int32 in
                return Int32(cmd.rawValue)
            }
            command.append(contentsOf: cmds)
            rustService.registerPushHandler(factories: dict)
        }
        // 把需要透传的server pb向rust注册
        var req = Im_V1_SetPassThroughPushCommandsRequest()
        req.commands = command
        _ = rustService.sendAsyncRequest(req).subscribe()
    }
}
