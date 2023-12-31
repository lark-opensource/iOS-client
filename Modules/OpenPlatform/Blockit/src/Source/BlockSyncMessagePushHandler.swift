//
//  BlockSyncMessagePushHandler.swift
//  Blockit
//
//  Created by ChenMengqi on 2021/11/11.
//

import Foundation
import RustPB
import LarkRustClient

let RustBlockSyncHandlerAppName = "lark_block_server"
let RustBlockSyncHandlerToken = "e9971a63-1873-4248-bf60-cee84990b60c"

typealias RustSyncPushMessage = RustPB.Sync_V1_SyncPushMessage
typealias RustSyncMessage = RustPB.Sync_V1_SyncMessage

typealias RustSyncPushEvent = RustPB.Sync_V1_SyncPushEvent
typealias RustSyncEvent = RustPB.Sync_V1_SyncEvent


final class RustSyncPushMessageHandler: UserPushHandler {
    func process(push message: RustSyncPushMessage) throws {
        if message.appName != RustBlockSyncHandlerAppName {
            Blockit.log.warn("RustSyncPushMessageHandler not match the right appName")
            return
        }
        let data = message.message.payload
        if !data.isEmpty{
            guard let jsonDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                Blockit.log.error("RustSyncPushMessageHandler cannot convert to valid json dictionary")
                return
            }
            Blockit.log.info("RustSyncPushMessageHandler get payload is \(jsonDict)")
            let syncMessageManager = try userResolver.resolve(assert: BlockSyncMessageManager.self)
            syncMessageManager.processSyncMessage(message: jsonDict)
        } else {
            Blockit.log.info("RustSyncPushMessageHandler message data is empty")
        }
    }
}

final class RustSyncPushEventHandler: UserPushHandler {
    func process(push message: RustSyncPushEvent) throws {
        if message.appName != RustBlockSyncHandlerAppName {
            Blockit.log.warn("RustSyncPushEventHandler not match the right appName")
            return
        }
        let syncEvent = message.syncEvent
        Blockit.log.info("RustSyncPushEventHandler type \(syncEvent.type)")
        if(syncEvent.type == .bizReset){
            //reset
            let syncMessageManager = try userResolver.resolve(assert: BlockSyncMessageManager.self)
            syncMessageManager.reconnectForBlockID(blockID: message.topicID)
        }
    }
}

