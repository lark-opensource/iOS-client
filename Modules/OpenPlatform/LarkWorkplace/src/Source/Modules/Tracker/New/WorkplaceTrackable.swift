//
//  WorkplaceTrackable.swift
//  LarkWorkplace
//
//  Created by Meng on 2023/6/9.
//

import Foundation

/// 工作台业务埋点参数设置协议。
///
/// 符合工作台使用习惯的通用语法封装在此协议。业务自定义结构的语法封装在 `WorkplaceTrackable+Biz.swift`。
protocol WorkplaceTrackable {
    @discardableResult
    func setValue(_ value: Any?, for key: WorkplaceTrackEventKey) -> WorkplaceTrackable

    /// 上报埋点，调用方法后 `WorkpalceTracker` 不会再持有埋点，可以认为此次埋点已经结束，相关上下文会清理。
    func post()
}

extension WorkplaceTrackable {
    @discardableResult
    func setMap(_ map: [WorkplaceTrackEventKey: Any?]) -> WorkplaceTrackable {
        map.forEach { (key, value) in
            setValue(value, for: key)
        }
        return self
    }
}
