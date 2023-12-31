//
//  BlockSyncMessageManager.swift
//  Blockit
//
//  Created by ChenMengqi on 2021/11/4.
//

import Foundation
import OPSDK
import LKCommonsLogging


///https://bytedance.feishu.cn/docx/doxcnXxJQj0FYwwBDXTIGgAvBFe
protocol BlockDataSubscribeProtocol {
    func blockSubscribe(blockId:String ,container:OPContainerProtocol)
    func blockUnsubscribe(blockId: String)
}

enum BlockSyncDataType{
    case BlockSyncDataTypeEntity
    case BlockSyncDataTypeUser
}

final class BlockSyncMessageManager {
    private var blockHandlers = [String: BlockSyncMessageHandler]()
    public static let log = Logger.log(BlockSyncMessageManager.self, category: "BlockitSDK")
    private var retryWaitTime = 3 // 重试时间，每次失败增加间隔3s
    private let lock = MutexLock()

    private let rustAPI: BlockSyncMessageRustAPI
    private let api: BlockitAPI
    private let config: BlockitConfig

    init(api: BlockitAPI, config: BlockitConfig, rustAPI: BlockSyncMessageRustAPI) {
        self.api = api
        self.config = config
        self.rustAPI = rustAPI
    }

    
    //换成uniqueid
    public func subscribeSyncMessage(blockId: String, container: OPContainerProtocol){ //forwardDelegates 获取container
        lock.lock()
        var handler = blockHandlers[blockId]
        if handler == nil {
            handler = BlockSyncMessageHandler(container: container, blockId: blockId, entityVersion: BlockVersionInitial, userVersion: BlockVersionInitial)
            blockHandlers[blockId] = handler
        } 
        lock.unlock()
        let blockEntityVersion = handler?.entityVersion
        let blockUserVersion = handler?.userVersion
        
        ///都有缓存的情况下，直接发起订阅
        if blockEntityVersion != BlockVersionInitial && blockUserVersion != BlockVersionInitial{
            self.subscribeIfNeeded(blockId: blockId, container: container, finishType: .BlockSyncDataTypeEntity)
            return ;
        }
        /// 其中一个有缓存，则请求结束后，发起订阅
        /// 都没有缓存，则两个请求结束后，发起订阅
        if blockEntityVersion != BlockVersionInitial {
            Self.log.info("blockEnitity has local cache \(blockEntityVersion as Int?)")
        } else {
            self.getBlockEntityVersion(blockId: blockId) {[weak self, weak container] messageData in
                handler?.setEntityData(messageData: messageData)
                self?.subscribeIfNeeded(blockId: blockId, container: container, finishType: .BlockSyncDataTypeEntity)
            } failure: {[weak self] error in
                Self.log.error("fail to get getBlockEntityVersion for blockId \(blockId) error \(error.localizedDescription)")
                self?.subscribeIfNeeded(blockId: blockId, container: container, finishType: .BlockSyncDataTypeEntity)
            }
        }
        
        if blockUserVersion != BlockVersionInitial{
            Self.log.info("blockUser has local cache \(blockUserVersion as Int?)")
        } else {
            self.getOpenMessage(blockId: blockId) { [weak self, weak container] messageData in
                handler?.setUserData(userData: messageData, fromMount: true)
                self?.subscribeIfNeeded(blockId: blockId, container: container, finishType: .BlockSyncDataTypeUser)
            } failure: { [weak self, weak container] error in
                Self.log.error("fail to get getOpenMessage for blockId \(blockId) error \(error.localizedDescription)")
                self?.subscribeIfNeeded(blockId: blockId, container: container, finishType: .BlockSyncDataTypeUser)
            }
        }
        
    }
    
    public func processSyncMessage(message: [String: Any]) {
        guard let command = message["command"] as? String else {
            Blockit.log.error("processSyncMessage error: no command")
            return
        }

        guard let dataDic = message["data"] as? [String: Any] else {
            Blockit.log.error("processSyncMessage error: no data")
            return
        }

        guard let header = dataDic["header"] as? [String: Any] else {
            Blockit.log.error("processSyncMessage error: no header")
            return
        }

        guard let version = header["version"] as? Int else {
            Blockit.log.error("processSyncMessage error: no version")
            return
        }
        
        guard let blockID = header["blockID"] as? String else {
            Blockit.log.error("processSyncMessage error: no blockID")
            return
        }

        guard let handler = getHandlerForBlockId(blockID: blockID) else{
            Blockit.log.error("processSyncMessage error: no handler for blockID \(blockID)")
            return

        }
        if command == "pushOpenMessage" {
            guard let event = dataDic["event"] as? String else {
                Blockit.log.error("processSyncMessage pushOpenMessage error: no event for blockID \(blockID)")
                return
            }
            let userData = OpenMessageItemRes(content: event, version: version)
            handler.setUserData(userData: userData, fromMount: false)
        } else if command == "pushBlockEvent"{
            guard let event = dataDic["event"] as? [String: Any] else {
                Blockit.log.error("processSyncMessage pushBlockEvent error: no event for blockID \(blockID)")
                return
            }
            guard let sourceData = event["sourceData"] as? String else {
                Blockit.log.error("processSyncMessage pushBlockEvent error: no sourceData for blockID \(blockID)")
                return
            }
            let entityData = BlockOnEntityMessageData(version: version, sourceData: sourceData)
            handler.setEntityData(messageData: entityData)
        }
    }
    
    public func reconnectForBlockID(blockID:String){
        guard let handler = getHandlerForBlockId(blockID: blockID) else {
            Self.log.error("reconnectForBlockID not find \(blockID) handler")
            return
        }

        self.getBlockEntityVersion(blockId: blockID) { messageData in
            handler.setEntityData(messageData: messageData)
        } failure: {error in
            Self.log.error("fail to get getBlockEntityVersion for blockId \(blockID) error \(error.localizedDescription)")
        }
        
        Blockit.log.info("reconnectForBlockID \(blockID)")
        self.getOpenMessage(blockId: blockID) {  messageData in
            handler.setUserData(userData: messageData, fromMount: true)
        } failure: { error in
            Self.log.error("fail to get getOpenMessage for blockId \(blockID) error \(error.localizedDescription)")
        }
        guard let container = handler.container else {
            Self.log.error("reconnectForBlockID error\(blockID) no container")
            return 
        }
        
        self.blockSubscribe(blockId: blockID, container: container)
    }
}


extension BlockSyncMessageManager: BlockDataSubscribeProtocol{
    
    func blockSubscribe(blockId: String, container: OPContainerProtocol) {
        var request =  RustSubscribeTopicRequest()
        var header = RustSyncHeader()
        header.appName = RustBlockSyncHandlerAppName
        header.token = RustBlockSyncHandlerToken
        request.header = header
        request.topicID = blockId
        rustAPI.subscribeTopic(request: request) { [weak self, weak container] response in
            guard let self = self, let container = container else { return }
            if response.code != .success{
                Blockit.log.error("\(blockId) blockSubscribe faild error:\(response.msg)")
                self.blockSubscribeRetry(blockId: blockId, container: container, retryWaitTime: self.retryWaitTime)
                self.retryWaitTime = self.retryWaitTime + 3
            } else {
                Blockit.log.info("\(blockId) blockSubscribe success")
            }
        }
    }
    
    func blockUnsubscribe(blockId: String) {
        self.lock.lock()
        self.blockHandlers[blockId] = nil
        self.lock.unlock()

        var request =  RustUnsubscribeSyncTopicRequest()
        var header = RustSyncHeader()
        header.appName = RustBlockSyncHandlerAppName
        header.token = RustBlockSyncHandlerToken
        request.header = header
        request.topicID = blockId
        rustAPI.unsubscribeSyncTopic(request: request){[weak self] response in
            guard let self = self else { return }
            if response.code != .success {
                Blockit.log.error("\(blockId) unsubscribeSyncTopic faild error:\(response.msg)")
            } else {
                Blockit.log.info("\(blockId) unsubscribeSyncTopic success")
            }
        }

    }
    
    private func blockSubscribeRetry(blockId: String, container: OPContainerProtocol, retryWaitTime:Int) {
        Blockit.log.info("\(blockId) blockSubscribeRetry retry in \(retryWaitTime)s")
        let dispatchAfter = DispatchTimeInterval.seconds(retryWaitTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + dispatchAfter) { [weak self] in
            guard let self = self else { return }
            self.blockSubscribe(blockId: blockId, container: container)
        }

    }
    
}

extension BlockSyncMessageManager {
    private func getOpenMessage(blockId: String,success: @escaping (OpenMessageItemRes?) -> Void, failure: @escaping (Error) -> Void) {
        let headers = ["Session": config.token]
        let blockIDs = [blockId]
        api.getOpenMessage(headers: headers, params: ["blockIDs":blockIDs]) { openMessageRes in
            let openMessageItemRes = openMessageRes.messages[blockId]
            success(openMessageItemRes ?? OpenMessageItemRes(content: "", version: 0))
        } failure: { error in
            Blockit.log.error("doRequest getOpenMessage error and error:\(error)")
            failure(error)
        }
    }
    
    private func getBlockEntityVersion(blockId: String,success: @escaping (BlockOnEntityMessageData?) -> Void, failure: @escaping (Error) -> Void) {
        api.getBlockEntityVersion(blockIDs: [blockId]) { messageData in
            success(messageData.first ?? nil)
        } failure: { error in
            Blockit.log.error("doRequest getBlockEntity error and error:\(error)")
            failure(error)
        }
    }

    
    private func subscribeIfNeeded(blockId: String, container: OPContainerProtocol?, finishType:BlockSyncDataType){
        guard let container = container else {
            Self.log.error("fail to get container for subscribeSyncMessage blockId \(blockId)")
            return
        }
        guard let handler = getHandlerForBlockId(blockID:blockId) else {
            Self.log.error("subscribeIfNeeded not find \(blockId) handler")
            return
        }
        
        let blockEntityVersion = handler.entityVersion
        let blockUserVersion = handler.userVersion

        switch finishType {
        case .BlockSyncDataTypeUser:
            if blockEntityVersion != BlockVersionInitial {
                self.blockSubscribe(blockId: blockId, container: container)
            } else {
                Self.log.info("entity version is not ready \(blockId)")
            }
        case .BlockSyncDataTypeEntity:
            if blockUserVersion != BlockVersionInitial {
                self.blockSubscribe(blockId: blockId, container: container)
            } else {
                Self.log.info("user version is not ready \(blockId)")
            }
        }
    }
    
    private func getHandlerForBlockId(blockID:String) -> BlockSyncMessageHandler? {
        lock.lock()
        defer { lock.unlock() }
        guard let handler = self.blockHandlers[blockID] else{
            Blockit.log.error("processSyncMessage error: no handler for blockID \(blockID)")
            return nil
        }
        return handler
    }
}


