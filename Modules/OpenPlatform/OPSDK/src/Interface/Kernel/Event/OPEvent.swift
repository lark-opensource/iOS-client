//
//  OPEvent.swift
//  EventBubble
//
//  Created by Nicholas Tau on 2020/12/4.
//

import Foundation

open class OPEvent: NSObject{
    
    public private(set) var eventName: String
    
    public private(set) var context: OPEventContext = OPEventContext(userInfo: [:])
    
    /// 事件数据
    public private(set) var params: [AnyHashable: Any] = [:]
    
    // 发送消息的原始节点【默认空节点】
    public private(set) var srcNode: OPNodeProtocol = OPNode()

    init(eventName: String, params: [AnyHashable: Any], srcNode: OPNodeProtocol, context: OPEventContext) {
        self.eventName = eventName
        self.params = params
        self.srcNode = srcNode
        self.context = context
    }
}
