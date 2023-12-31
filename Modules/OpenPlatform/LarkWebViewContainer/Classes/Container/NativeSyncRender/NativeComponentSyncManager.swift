//
//  NativeComponentSyncManager.swift
//  LarkWebViewContainer
//
//  Created by wangjin on 2022/10/19.
//

import Foundation
import ECOProbe
import LKCommonsLogging

/// 新同层渲染框架同步渲染管理类
public final class OpenNativeComponentSyncManager: NSObject {
    static private let logger = Logger.oplog(OpenNativeComponentSyncManager.self, category: "NativeComponentSyncManager")
    
    /// API上下文信息暂存池
    private var apiContextPool: [String: APIContextProtocol] = [:]
    
    /// WKChildScrollView暂存池
    var scrollViewPool: NSMapTable<NSString, UIScrollView> = NSMapTable(valueOptions: [.weakMemory])
    
    /// 同步渲染代理
    public weak var syncRenderDelegate: NativeComponentSyncDelegate?
    
    public func pushAPIContextPool(_ apiContext: APIContextProtocol) {
        self.apiContextPool[apiContext.renderId] = apiContext
        if let scrollView = self.scrollViewPool.object(forKey: apiContext.renderId as NSString) {
            /// 如果API上下文和WKChildScrollView都已经创建好，那么就可以开始生成并插入native view
            guard let delegate = syncRenderDelegate else {
                Self.logger.error("OpenNativeComponentSyncManager, pushAPIContextPool fail, syncRenderDelegate is nil")
                return
            }
            delegate.insertComponent(scrollView: scrollView, apiContext: apiContext)
        }
    }
    
    public func pushScrollViewPool(_ scrollView: UIScrollView) {
        /// 区别于APIContextPool的添加，scrollViewWrapper无论此次是否命中都需要添加进暂存池中。
        /// 原因：如果此次没命中，则加入暂存池，等待APIContext准备好后调用insert
        ///      如果此次命中，后续insert逻辑中需要在暂存池中找到renderId所对应的UIScrollView，并将native view添加上去，所以也需要加入暂存池
        guard let renderID = scrollView.op_renderID else {
            Self.logger.error("OpenNativeComponentSyncManager, pushScrollViewPool fail, WKChildScrollView renderID is nil")
            return
        }
        
        self.scrollViewPool.setObject(scrollView, forKey: renderID as NSString)
        
        if let apiContext = self.apiContextPool[renderID] {
            /// 如果API上下文和WKChildScrollView都已经创建好，那么就可以开始生成并插入native view
            guard let delegate = syncRenderDelegate  else {
                /// 如果ScrollView上下文和APIContext都已经创建好，那么就可以开始生成并插入native view
                Self.logger.error("OpenNativeComponentSyncManager, pushScrollViewPool fail, syncRenderDelegate is nil")
                return
            }
            
            delegate.insertComponent(scrollView: scrollView, apiContext: apiContext)
        }
    }
    
    /// 清除APIContext暂存池中renderId对应的资源对象
    public func popAPIContextPoolIfNeeded(renderId: String) {
        /// 如果暂存池中存在多个组件的insert上下文，则删除renderId对应的APIContext
        apiContextPool.removeValue(forKey: renderId)
    }
    
    /// 清除ScrollView暂存池中renderId对应的资源对象
    public func cleanScrollViewPoolIfNeeded(renderId: String) {
        /// 如果暂存池中存在多个组件的ScrollView上下文，则删除renderId对应的ScrollViewWrapper
        self.scrollViewPool.removeObject(forKey: renderId as NSString)
        if let scrollview = self.scrollViewPool.object(forKey: renderId as NSString) {
            scrollview.lkw_syncRenderObject?.nativeView = nil
        }
    }
}
