//
//  LarkJSTimerProtocol.swift
//  LarkJSEngine
//
//  Created by Jiayun Huang on 2022/3/9.
//

import Foundation

@objc public protocol LarkJSTimerProtocol {
    func setTimeOut(functionID: NSInteger, time: NSInteger,  queue: DispatchQueue?, callback: @escaping () -> Void)
    
    // setTimeOut 平台实现，runloop方式
    func setTimeOut(functionID: NSInteger, time: NSInteger, runLoop: RunLoop, callback: @escaping () -> Void)
    
    // clearTimeout 销毁
    func clearTimeout(functionID: NSInteger)

    // setInterval 平台实现，dispatch_queue方式
    func setInterval(functionID: NSInteger, time: NSInteger, queue: DispatchQueue?, callback: @escaping () -> Void)
    
    // setInterval 平台实现，runloop方式
    func setInterval(functionID: NSInteger, time: NSInteger, runLoop: RunLoop, callback: @escaping () -> Void)

    // clearInterval 销毁
    func clearInterval(functionID: NSInteger)
}
