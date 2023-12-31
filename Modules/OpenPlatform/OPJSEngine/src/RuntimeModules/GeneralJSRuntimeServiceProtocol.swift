//
//  GeneralJSRuntimeModuleProtocol.swift
//  TTMicroApp
//
//  Created by yi on 2021/11/29.
//
// runtime module协议
import Foundation

@objc
public protocol GeneralJSRuntimeModuleProtocol: NSObjectProtocol {
    var jsRuntime: GeneralJSRuntime? { get set }

    func runtimeLoad() // js runtime初始化
    func runtimeReady()

}


