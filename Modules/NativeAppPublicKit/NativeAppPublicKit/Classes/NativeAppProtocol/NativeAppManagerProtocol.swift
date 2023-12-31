//
//  NativeAppManagerProtocol.swift
//  NativeAppPublicKit
//
//  Created by bytedance on 2022/6/9.
//

import Foundation
import UIKit

///abstract [简述]定义飞书Native提供为NativeApp提供的能力
@objc
public protocol NativeAppManagerProtocol : NSObjectProtocol {
    
    /**
     push ViewController

     - Parameters:
       - from: 从哪个ViewController push
       - to: 要push的ViewController
     */
    @objc
    func pushNativeAppViewController(from: UIViewController, to: UIViewController)
    
    
    /**
     pop ViewController

     - Parameters:
       - from: 哪个ViewController pop
     */
    @objc
    func popNativeAppViewController(from: UIViewController)
    
    
    /**
     调用OpenAPI

     - Parameters:
       - appID: NativeApp的appID
       - apiName: 要调用的api的名字
       - params: 参数
       - vc: 调用API的vc
       - callback: 执行API后相关的逻辑
     */
    @objc
    func invokeOpenApi(appID: String, apiName: String, params: [String: Any], callback:@escaping (NativeAppOpenApiModel) -> Void)
    
    
    /**
     注入cookie到HTTPCookieStorage中

     - Parameters:
       - cookie: 注入的cookie
     */
    @objc
    func setCookie(cookie: HTTPCookie)
    
    /**
     在已有 UserAgent 基础上 append 字段

     - Parameters:
       - customUA: 要 append 的 UserAgent String
     
     Discussion：建议 application 启动直接注入，确保一次性注入完全，多次调用注入不同的值会造成覆盖；其中的 product 请不要与已有 product 冲突, product 含义请参考 https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent，
     */
    @objc
    func appendUserAgent(customUA: String)
        
}
