//
//  MessagePacker.swift
//  Lark
//
//  Created by liuwanlin on 2018/8/8.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkModel
import RxSwift

public enum MessagePackType: String {
    case chatter
    case rootParent
    case reaction
    case systemTrigger
    case callChatter
    case recaller
    case manipulator
}

public protocol MessagePacker {
    func asyncPack(_ models: [Message]) -> Observable<[Message]>
    func asyncPack(_ models: [Message], with types: [MessagePackType]) -> Observable<[Message]>
}
