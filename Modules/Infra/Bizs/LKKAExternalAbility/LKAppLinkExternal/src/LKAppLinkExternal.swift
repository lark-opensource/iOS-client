//
//  LKAppLinkExternal.swift
//  LKAppLinkExternal
//
//  Created by ByteDance on 2022/8/16.
//

import UIKit
import Foundation

public typealias KACompletion = () -> Void

public enum KAPushStyle {
    /// 根据设备类型默认，在 iPad 的 split view 上时，会在 detail push 新页面
    case `default`
    /// 在 iPad 的 split view 上时，会在 detail set 新页面，无法通过 pop 移除，需要继续调用 detail 覆盖原页面，建议使用 default
    case detail
}

public protocol KANavigator {
    /// 从 from vc push 到下个 applink url
    /// - Parameters:
    ///   - url: applink url
    ///   - from: from vc
    func open(url: NSURL, from: UIViewController)
    
    /// 从当前  window 顶部 vc 的 navigation controller push vc，如果当前无 navigation controller 可能失败
    /// - Parameters:
    ///   - vc: 需要 push 的 vc
    ///   - completion: 完成回调
    ///   - style: push 方式
    func push(vc:UIViewController, style: KAPushStyle, completion: KACompletion?)
    
    /// 从当前 window 顶部 vc 的 navigation controllers 中移除 vc，如果当前无 navigation controller 可能失败
    /// - Parameters:
    ///   - vc: 需要 push 的 vc
    ///   - completion: 完成回调
    func pop(vc:UIViewController, completion: KACompletion?)
    
    /// 从当前 window 顶部 vc present 入参 vc
    /// - Parameters:
    ///   - vc: 需要 push 的 vc
    ///   - completion: 完成回调
    func present(vc:UIViewController, completion: KACompletion?)
}

@objcMembers
public class KAAppLinkExternal: NSObject {
    public override init() {
    }
    public static let shared = KAAppLinkExternal()
    public var navigator: KANavigator?
    public func open(url: NSURL, from: UIViewController) {
        if let navigator = navigator {
            print("KA---Watch: KAAppLinkExternal will open url: \(url), from vc: \(from)")
            navigator.open(url: url, from: from)
        }
    }
}
