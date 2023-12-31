//
//  OpenComponentRenderFactory.swift
//  OPPlugin
//
//  Created by yi on 2021/8/12.
//
// 组件渲染能力工厂类

import Foundation

// 组件渲染能力类型
public enum OpenNativeComponentRenderType: String {
    case native_component_overlay // 非同层渲染，盖在webview上
    case native_component_sandwich // 同层渲染，嵌入webview内
    case native_component_sandwich_sync // 同层渲染升级
}

// 组件渲染能力工厂类
final class OpenComponentRenderFactory {

    // 获取渲染处理对象
    static func componentRender(type: OpenNativeComponentRenderType) -> OpenComponentRenderProtocol.Type {
        switch type {
        case .native_component_overlay:
            return OpenComponentOverlayRender.self
        case .native_component_sandwich_sync:
            return OpenComponentNativeSyncRender.self
        case .native_component_sandwich:
            return OpenComponentNativeRender.self
        }
    }
}
