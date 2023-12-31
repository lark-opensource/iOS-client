//
//  OperationInterceptor.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/5/30.
//  


import SKFoundation
import SKCommon
import SpaceInterface
import LarkUIKit
import EENavigator


public typealias OperationInterceptorHandle = (() -> Void)

/// 操作拦截器
public class OperationInterceptor {
    
    public static func interceptUrlIfNeed(_ url: String,
                                          from vc: UIViewController?,
                                          followDelegate: BrowserVCFollowDelegate?,
                                          handler: OperationInterceptorHandle? = nil) -> Bool {
        let isAsync = handler != nil
        if let followDelegate = followDelegate {
            DocsLogger.vcfInfo("intercept Url in magicshare, async:\(isAsync)")
            if let handler = handler {
                followDelegate.follow(onOperate: .vcOperation(value: .openUrlWithHandlerBeforeOpen(url: url, handler: handler)))
            } else {
                followDelegate.follow(onOperate: .vcOperation(value: .openUrl(url: url)))
            }
            return true
        }
        
        guard let docComponent = vc as? DocComponentHost,
              let dcHostDelegate = docComponent.browserView?.docComponentDelegate else {
            return false
        }
        var intercept = false
        if let handler = handler {
            intercept = dcHostDelegate.docComponentHost(docComponent,
                                                        onOperation: .openUrlWithHandlerBeforeOpen(url: url, handler: handler))
        } else {
            intercept = dcHostDelegate.docComponentHost(docComponent,
                                                        onOperation: .openUrl(url: url))
        }
        
        if intercept {
            DocsLogger.info("intercept url in docComponent, async:\(isAsync)", component: LogComponents.docComponent)
        } else {
            DocsLogger.info("notify open url in docComponent", component: LogComponents.docComponent)
        }
        return intercept
    }
    
    
    public static func interceptOpenImageIfNeed(_ url: String,
                                                from vc: UIViewController?,
                                                followDelegate: BrowserVCFollowDelegate?) -> Bool  {
        if let followDelegate = followDelegate {
            DocsLogger.vcfInfo("notify open image in magicshare")
            followDelegate.follow(onOperate: .vcOperation(value: .openPic(url: url)))
            return false //MS不拦截打开图片
        }
        guard let docComponent = vc as? DocComponentHost,
              let dcHostDelegate = docComponent.browserView?.docComponentDelegate else {
            return false
        }
        let intercept = dcHostDelegate.docComponentHost(docComponent,
                                                    onOperation: .openPic(url: url))
        if intercept {
            DocsLogger.info("intercept open image", component: LogComponents.docComponent)
        }
        return intercept
    }
    
    public static func interceptShowUserProfileIfNeed(_ userId: String,
                                                      from vc: UIViewController?,
                                                      followDelegate: BrowserVCFollowDelegate?) -> Bool  {
        if let followDelegate = followDelegate {
            DocsLogger.vcfInfo(" intercept show userprofile in magicshare")
            followDelegate.follow(onOperate: .vcOperation(value: .showUserProfile(userId: userId)))
            return true
        }
        guard let docComponent = vc as? DocComponentHost,
              let dcHostDelegate = docComponent.browserView?.docComponentDelegate else {
            return false
        }
        let intercept = dcHostDelegate.docComponentHost(docComponent,
                                                    onOperation: .showUserProfile(userId: userId))
        if intercept {
            DocsLogger.info("intercept show userprofile", component: LogComponents.docComponent)
        }
        return intercept
    }
    
    public static func interceptMoveToWiki(_ wikiUrl: String,
                                           originUrl: String,
                                           from vc: UIViewController?,
                                           followDelegate: BrowserVCFollowDelegate?) -> Bool {
        if let followDelegate = followDelegate {
            DocsLogger.vcfInfo(" intercept show userprofile in magicshare")
            followDelegate.follow(onOperate: .vcOperation(value: .openMoveToWikiUrl(wikiUrl: wikiUrl, originUrl: originUrl)))
            return false
        }
        guard let docComponent = vc as? DocComponentHost,
              let dcHostDelegate = docComponent.browserView?.docComponentDelegate else {
            return false
        }
        dcHostDelegate.docComponentHost(docComponent, onMoveToWiki: wikiUrl, originUrl: originUrl)
        return false
    }
}
