//
//  WebLoader+SSR.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/6/7.
//  


import Foundation
import SKFoundation
import SKUIKit
import SKCommon
import SKResource
import SpaceInterface
import SKInfra
import LKCommonsTracker
import LarkContainer

enum RenderSSRWebviewType: String {
    case none
    case localSSR
    case fetchSSR
    
    //返回枚举对于的int类型
    func getIntValue() -> Int {
        switch self {
        case .none:
            return 0
        case.localSSR:
            return 1
        case.fetchSSR:
            return 2
        }
    }
}

extension WebLoader {
    func canRenderCacheInSSRWebView() -> Bool {
        guard OpenAPI.docs.enableSSRWebView(docsInfo: self.docsInfo) else {
            return false
        }
        
        //是否有提前发起请求ssr，如果有发起，证明本地没有ssr，先用ssrwebview打开，等待下载成功渲染
        if DocHtmlCacheFetchManager.fetchSSRBeforeRenderEnable(),
           let docsInfo = self.docsInfo,
           let manager = try? Container.shared.getCurrentUserResolver().resolve(type: DocHtmlCacheFetchManager.self) {
            let beginFetchSSR = manager.hasFetchSSR(token: docsInfo.token)
            DocsLogger.info("[ssr] enableSSRWebView fetch SSR before render = \(beginFetchSSR)", component: LogComponents.ssrWebView)
            if beginFetchSSR {
                return true
            }
        }
        
        //根据WebView预加载状态，决定是否开启SSRWebView独立渲染策略
        if self.canRender() {
            //完全预加载
            if !OpenAPI.docs.enableSSRWebViewInFullPreload {
                DocsLogger.info("[ssr] enableSSRWebView In Full Preload = false", component: LogComponents.ssrWebView)
                return false
            }
        } else if self.preloadStatus.value.hasLoadSomeThing {
            //部分预加载
            if !OpenAPI.docs.enableSSRWebViewInPartPreload {
                DocsLogger.info("[ssr] enableSSRWebView In Part Preload = false", component: LogComponents.ssrWebView)
                return false
            }
        } else {
            //未预加载，空白webivew
            if !OpenAPI.docs.enableSSRWebViewInNotPreload {
                DocsLogger.info("[ssr] enableSSRWebView In Not Preload = false", component: LogComponents.ssrWebView)
                return false
            }
        }
        return true
    }
}

extension OpenAPI.Docs {
    
    func enableSSRWebView(docsInfo: DocsInfo?) -> Bool {
        let isSupportType = docsInfo?.urlType == .docX ||
        (OpenAPI.docs.enableSSRWebViewInWiki && docsInfo?.originType == .docX)
        return isSupportType && OpenAPI.docs.enableSSRWebView
    }
    
    var enableSSRWebView: Bool {
        guard MobileClassify.isLow == false else {
            return false //低端机不生效
        }
        return UserScopeNoChangeFG.LJY.enableSSRWebView
    }
    
    var enableSSRWebViewInFullPreload: Bool {
        return SettingConfig.ssrWebviewConfig?.enableInFullPreload ?? false
    }
    
    var enableSSRWebViewInPartPreload: Bool {
#if DEBUG
        return true
#else
        return SettingConfig.ssrWebviewConfig?.enableInPartPreload ?? false
#endif
    }
    
    var enableSSRWebViewInNotPreload: Bool {
#if DEBUG
        return true
#else
        return SettingConfig.ssrWebviewConfig?.enableInNotPreload ?? false
#endif
    }
    
    var enableSSRWebViewInWiki: Bool {
#if DEBUG
        return true
#else
        return SettingConfig.ssrWebviewConfig?.enableDocxAtWiki ?? false
#endif
    }
}
