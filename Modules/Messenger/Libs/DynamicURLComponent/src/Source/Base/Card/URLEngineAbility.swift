//
//  URLEngineAbility.swift
//  DynamicURLComponent
//
//  Created by Ping on 2023/5/11.
//

import TangramComponent

public protocol URLEngineAbility {
    var tcComponent: Component { get }
    /// Cell将要出现的时候
    func willDisplay()
    /// Cell不再显示的时候
    func didEndDisplay()
    /// Size发生变化
    func onResize()
}
