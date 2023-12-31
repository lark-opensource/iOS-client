//
//  EventDetailContext.swift
//  Calendar
//
//  Created by Rico on 2021/10/21.
//

import Foundation
import RxSwift
import RxRelay

struct EventDetailContext {

    // 数据源 在更改/响应日程之后会发生改变
    let rxModel: BehaviorRelay<EventDetailModel>

    // 页面状态
    let state: EventDetailState

    // 页面全局配置
    let options: EventDetailOptions

    // 页面入口数据
    let payload: EventDetailEntrancePayload

    // 用作日程刷新
    let refreshHandle: EventDetailRefreshHandle

    // 统计监控上报的对象
    let monitor: EventDetailMonitor
    
    // 页面入口场景
    let scene: EventDetailScene

}

protocol ModuleContextHolder: AnyObject {
    associatedtype Context

    typealias ContextObject<Value> = AnyContextProxy<Self, Value>

    var context: Context { get }
}

@propertyWrapper
struct AnyContextProxy<EnclosingModuleType: ModuleContextHolder, Value> {

    static subscript(
        _enclosingInstance observed: EnclosingModuleType,
        wrapped wrappedKeyPath: KeyPath<EnclosingModuleType, Value>,
        storage storageKeyPath: KeyPath<EnclosingModuleType, Self>
    ) -> Value {
        get {
            let contextKeyPath = observed[keyPath: storageKeyPath].contextKeyPath
            return observed.context[keyPath: contextKeyPath]
        }
        set {
            assert(false, "not supported")
        }
    }

    @available(*, unavailable, message: "@AnyContextProxy is only available on properties of classes")
    var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    private let contextKeyPath: KeyPath<EnclosingModuleType.Context, Value>

    init(_ contextKeyPath: KeyPath<EnclosingModuleType.Context, Value>) {
        self.contextKeyPath = contextKeyPath
    }
}
