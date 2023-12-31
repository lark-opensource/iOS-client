//
//  Queue.swift
//  LarkMeegoStorage
//
//  Created by shizhengyu on 2023/4/3.
//

import Foundation
import RxSwift

let kvStorageOptScheduler = SerialDispatchQueueScheduler(
    qos: .default,
    internalSerialQueueName: "lark.meego.rust.storage.kv.queue"
)

let structureStorageOptScheduler = SerialDispatchQueueScheduler(
    qos: .default,
    internalSerialQueueName: "lark.meego.rust.storage.structure.queue"
)
