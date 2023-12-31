//
//  LarkWebView+RegisterScheme.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/29.
//  注册Scheme(支持http/https)

import LKCommonsLogging
import WebKit

/// 下方代码和头条的代码保持完全一致，只是用Swift实现了，头条代码线上有上亿用户的在用
/// 如果其他业务方不调用统一功能而是自己写一套，则无法复用统一的代码，导致任何问题此处不承担任何责任
/// 已经注册过的 scheme 由于下边的注册是全局注册而不是针对 WebView 实例，所以需要通过一个集合避免重复注册
private var registerdSchemes = Set<String>()

extension LarkWebView {
    /// 注册支持 URLProtocol 拦截 WKWebView 请求的scheme 请在主线程调用
    /// - Parameter scheme: 需要被拦截的scheme
    public class func register(scheme: String) {
        guard !scheme.isEmpty else {
            logger.error("scheme cannot be empty")
            assertionFailure("scheme cannot be empty")
            return
        }
        if registerdSchemes.contains(scheme) {
            logger.warn("has register \(scheme)")
            unregister(scheme: scheme)
        }
//        guard let str = "cmVnaXN0ZXJTY2hlbWVGb3JDdXN0b21Qcm90b2NvbDo=".lkw_fromBase64() else {
//            logger.error("build register str error")
//            assertionFailure()
//            return
//        }
        // str: "registerSchemeForCustomProtocol:"
        let str = "registerSchemeForCustomProtocol:"
        let register = NSSelectorFromString(str)
        perform_browsing_contextController(aSelector: register, scheme: scheme)
        registerdSchemes.insert(scheme)
    }
    
    /// 反注册支持 URLProtocol 拦截 WKWebView 请求的scheme 请在主线程调用
    /// - Parameter scheme: 已经被被拦截的scheme
    public class func unregister(scheme: String) {
        guard !scheme.isEmpty else {
            logger.error("scheme cannot be empty")
            assertionFailure("scheme cannot be empty")
            return
        }
        guard registerdSchemes.contains(scheme) else {
            logger.warn("has no \(scheme) register")
            return
        }
//        guard let str = "dW5yZWdpc3RlclNjaGVtZUZvckN1c3RvbVByb3RvY29sOg==".lkw_fromBase64() else {
//            logger.error("build unregister str error")
//            assertionFailure()
//            return
//        }
        //str: "unregisterSchemeForCustomProtocol:"
        let str = "unregisterSchemeForCustomProtocol:"
        let unregister = NSSelectorFromString(str)
        perform_browsing_contextController(aSelector: unregister, scheme: scheme)
        registerdSchemes.remove(scheme)
    }
    
    private class func perform_browsing_contextController(aSelector: Selector, scheme: String) {
        // className: WKBrowsingContextController
//        guard let className = "V0tCcm93c2luZ0NvbnRleHRDb250cm9sbGVy".lkw_fromBase64(), let cls = NSClassFromString(className) as? NSObject.Type else {
//            logger.error("build WKBCC str error")
//            assertionFailure()
//            return
//        }
        guard let cls = NSClassFromString("WKBrowsingContextController") as? NSObject.Type else {
            logger.error("build WKBCC str error")
            assertionFailure()
            return
        }
        guard cls.responds(to: aSelector) else {
            logger.error("WKBCC not responds to selector")
            assertionFailure()
            return
        }
        cls.perform(aSelector, with: scheme) //[WKBrowsingContextController registerSchemeForCustomProtocol:];
    }
}
