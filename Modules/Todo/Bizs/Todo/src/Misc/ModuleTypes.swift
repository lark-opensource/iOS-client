//
//  ModuleTypes.swift
//  Todo
//
//  Created by 张威 on 2021/4/29.
//

import Foundation

protocol ModuleContext: AnyObject {
    associatedtype State: RxStoreState
    associatedtype Action: RxStoreAction
    associatedtype Event: RxBusEvent
    var store: RxStore<State, Action> { get }
    var bus: RxBus<Event> { get }
}

protocol ModuleContextHolder: AnyObject {
    associatedtype Context: ModuleContext
    var context: Context { get }
}
