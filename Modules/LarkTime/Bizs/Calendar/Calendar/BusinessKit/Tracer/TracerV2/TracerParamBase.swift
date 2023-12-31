//
//  TracerParamBase.swift
//  Calendar
//
//  Created by Rico on 2021/6/25.
//

import Foundation

/// 便于参数赋值，包装 若干个 类型结构，可直接赋值，也可使用链式语法赋值
@dynamicMemberLookup
final class ParamRefer<Source> {
    fileprivate var value: Source

    init(value: Source) {
        self.value = value
    }

    /// 直接设置属性
    subscript<T>(dynamicMember keyPath: WritableKeyPath<Source, T>) -> T {
        get { value[keyPath: keyPath] }
        set { value[keyPath: keyPath] = newValue }
    }

    /// 根据keyPath设置参数，可链式调用
    @discardableResult
    func assign<Value>(_ path: WritableKeyPath<Source, Value>, _ value: Value) -> ParamRefer<Source> {
        self.value[keyPath: path] = value
        return self
    }
}

extension ParamRefer where Source: Encodable {
    func getParamDic() -> [String: Any] {
        value.toTracerFlatDic
    }
}

protocol ViewParamBaseType: Encodable, TracerCommonParams {
    /// View类型埋点无额外强制参数
}

protocol ClickParamBaseType: Encodable, TracerCommonParams {
    /// Click类型埋点必有click和target参数
    var click: String { get set }
    var target: String { get set }
}

/// 基础View参数类型
struct BaseViewParams: ViewParamBaseType {

    var view_type: TracerViewType?
    var event_start_time: String?
    var is_organizer: String?
    var is_repeated: String?
    var uid: String?
    var cal_event_id: String?
    var original_time: String?
}

/// 基础Click参数类型
struct BaseClickParams: ClickParamBaseType {

    var click: String = "none"
    var target: String = "none"

    var event_start_time: String?
    var view_type: TracerViewType?
    var is_organizer: String? = "none"
    var is_repeated: String? = "none"
    var uid: String?
    var cal_event_id: String?
    var original_time: String?
}

// MARK: - 便捷方法参数设置

/// View公参的便捷设置
extension ParamRefer where Source: ViewParamType {

    subscript<T>(dynamicMember keyPath: WritableKeyPath<BaseViewParams, T>) -> T {
        get { value.base[keyPath: keyPath] }
        set { value.base[keyPath: keyPath] = newValue }
    }

    @discardableResult
    func assign<Value>(_ path: WritableKeyPath<BaseViewParams, Value>, _ value: Value) -> ParamRefer<Source> {
        self.value.base[keyPath: path] = value
        return self
    }

    /// 设置日历公参
    @discardableResult
    func mergeCalendarCommonParams(viewType: TracerViewType) -> Self {
        self.value.base.view_type = viewType
        return self
    }

    /// 设置日程公参
    @discardableResult
    func mergeEventCommonParams(commonParam: CommonParamData) -> Self {
        self.value.base.cal_event_id = commonParam.cal_event_id
        self.value.base.event_start_time = commonParam.event_start_time
        self.value.base.original_time = commonParam.original_time
        self.value.base.uid = commonParam.uid
        if let is_organizer = commonParam.is_organizer, let is_repeated = commonParam.is_repeated {
            self.value.base.is_organizer = is_organizer.description
            self.value.base.is_repeated = is_repeated.description
        }
        return self
    }
}

/// Click公参的便捷设置
extension ParamRefer where Source: ClickParamType {

    subscript<T>(dynamicMember keyPath: WritableKeyPath<BaseClickParams, T>) -> T {
        get { value.base[keyPath: keyPath] }
        set { value.base[keyPath: keyPath] = newValue }
    }

    @discardableResult
    func assign<Value>(_ path: WritableKeyPath<BaseClickParams, Value>, _ value: Value) -> ParamRefer<Source> {
        self.value.base[keyPath: path] = value
        return self
    }

    /// 设置target值
    /// - Parameter value: target枚举
    @discardableResult
    func target(_ target: TracerTarget) -> Self {
        self.value.base.target = target.rawValue
        return self
    }

    /// 设置click值
    /// - Parameter value: click值
    @discardableResult
    func click(_ value: String) -> Self {
        self.value.base.click = value
        return self
    }

    /// 设置target值
    /// - Parameter value: target值
    @discardableResult
    func target(_ value: String) -> Self {
        self.value.base.target = value
        return self
    }

    /// 设置日历公参
    @discardableResult
    func mergeCalendarCommonParams(viewType: TracerViewType) -> Self {
        self.value.base.view_type = viewType
        return self
    }

    /// 设置日程公参
    @discardableResult
    func mergeEventCommonParams(commonParam: CommonParamData) -> Self {
        self.value.base.cal_event_id = commonParam.cal_event_id
        self.value.base.event_start_time = commonParam.event_start_time
        self.value.base.original_time = commonParam.original_time
        self.value.base.uid = commonParam.uid
        if let is_organizer = commonParam.is_organizer, let is_repeated = commonParam.is_repeated {
            self.value.base.is_organizer = is_organizer.description
            self.value.base.is_repeated = is_repeated.description
        }
        return self
    }
}
