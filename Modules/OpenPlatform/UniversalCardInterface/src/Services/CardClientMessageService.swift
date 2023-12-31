//
//  CardClientMessageService.swift
//  UniversalCardInterface
//
//  Created by zhangjie.alonso on 2023/10/24.
//

import Foundation


// handler会在收到通知时，会异步抛出到主线程执行
public class CardClientMessageHandler: NSObject {
    private let handler: ((String) -> Void)
    public init(handler: @escaping (String) -> Void) {
        self.handler = handler
    }
    public func exec(_ value: String) {
        handler(value)
    }
}

public protocol CardClientMessageService {

    //业务方注册channel 以及对应的 handler
    func register(channel: String, handler: CardClientMessageHandler)
    //取消注册单个handler
    func unRegister(channel: String, unRegisterHandler: CardClientMessageHandler)
    //取消注册指定channel下所有Handler
    func unRegisterAll(channel: String)
}

//发布方的协议，目前发布方只能是卡片方，暂不对外暴露
public protocol CardClientMessagePublishService {

    func publish(channel: String, value: String) -> Bool
}
