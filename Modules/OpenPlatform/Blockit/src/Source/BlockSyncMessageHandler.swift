//
//  BlockSyncMessageHandler.swift
//  Blockit
//
//  Created by ChenMengqi on 2021/11/4.
//

import Foundation
import OPSDK

let BlockVersionInitial = -1

class BlockSyncMessageHandler {
    public weak var container: OPContainerProtocol?
    private var blockId : String
    ///blockEntity数据纬度的版本，需分开维护
    private(set) public var entityVersion : Int
    ///用户纬度数据的版本，需分开维护
    private(set) public var userVersion : Int

    init(container:OPContainerProtocol, blockId: String,entityVersion:Int, userVersion:Int) {
        self.blockId = blockId
        self.container = container
        self.entityVersion = entityVersion
        self.userVersion = userVersion
    }
    
    public func setEntityData(messageData:BlockOnEntityMessageData?){
        guard let  messageData = messageData else {
            Blockit.log.error("setEntityVersion empty messageData")
            return
        }
        if messageData.version <= entityVersion {
            Blockit.log.info("\(messageData.version) <= \(entityVersion)")
            return
        }
        entityVersion = messageData.version
        onResourceChange(content: messageData.sourceData)
    }
    
    public func setUserData(userData:OpenMessageItemRes?, fromMount: Bool){
        guard let  userData = userData else {
            Blockit.log.error("setUserData empty userData")
            return
        }
        if userData.version <= userVersion {
            Blockit.log.info("\(userData.version) <= \(userVersion)")
        }
        userVersion = userData.version
        if  fromMount{
            Blockit.log.info("not trigger on typemessage because it's from mount")
            return ;
        }
        onTypedMessage(event: userData.content)
    }
}

extension BlockSyncMessageHandler {
    private func onResourceChange(content: String) {
        do {
            if let data = content.data(using: .utf8) {
                let params = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                Blockit.log.info("\(blockId) onResourceChange \(content)")
                if let ctn = container {
                    try ctn.bridge.sendEvent(eventName: "onResourceChange", params: params, callback: nil)
                } else {
                    Blockit.log.error("onResourceChange container is nil")
                }
                
            } else {
                Blockit.log.error("onResourceChange data is nil")
            }
        } catch let e {
            Blockit.log.error("onResourceChange error blockId is \(blockId) error \(e.localizedDescription)")
        }
    }
    
    private func onTypedMessage(event:String) {
        do {
            Blockit.log.info("\(self.blockId) onTypedMessage \(event)")
            if let ctn = container {
                try ctn.bridge.sendEvent(
                    eventName: "onTypedMessage",
                    params: [
                        "type": "customMessage",
                        "data": event
                    ],
                    callback: nil
                )
            } else {
                Blockit.log.error("onTypedMessage container is nil")
            }
            
        } catch let e {
            Blockit.log.error("onTypedMessage error blockId is \(blockId) error \(e.localizedDescription)")
        }
    }

}
