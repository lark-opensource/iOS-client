//
//  TracerEvent.swift
//  Calendar
//
//  Created by Rico on 2021/6/25.
//

import Foundation

/// 新埋点框架下，代表一个页面的埋点事件结构
/// 可以页面为单位，定义在业务场景中
protocol TracerEvent {

    /// 事件模块名称，不包含 「_view」  或 「_target」、比如 cal_event_detail
    static var eventName: String { get }

    /// View埋点的参数结构，通常继承于BaseViewParams
    associatedtype ViewParam where ViewParam: Encodable

    /// Click埋点的参数结构，通常继承于BaseClickParams
    associatedtype ClickParam where ClickParam: Encodable

    /// 默认View埋点的参数结构实例
    static var defaultViewParam: ViewParam { get }

    /// 默认Click埋点的参数结构实例
    static var defaultClickParam: ClickParam { get }

}

/// View埋点参数
protocol ViewParamType: Encodable {
    var base: BaseViewParams { get set }
}

/// Click埋点参数
protocol ClickParamType: Encodable {
    var base: BaseClickParams { get set }
    mutating func setClick(_ params: BaseClickParams)
}

extension ClickParamType {
    mutating func setClick(_ params: BaseClickParams) {
        base.click = params.click
        base.target = params.target
    }
}
