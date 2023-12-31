//
//  OPDynamicComponentManagerProtocol.swift
//  OPDynamicComponent
//
//  Created by Nicholas Tau on 2022/5/31.
//

import Foundation
import OPSDK
/// loader阶段
@objc
public enum OPDynamicComponentLoaderState: Int {
    // meta请求阶段
    case meta
    // pkg拉包阶段
    case pkg

}

public typealias completeCallback = (Error?,  OPDynamicComponentLoaderState?, (OPBizMetaProtocol & OPMetaPackageProtocol)? ) -> Void
public typealias innerCompleteCallback = (OPBizMetaProtocol?,  Error?,  OPDynamicComponentLoaderState, OPAppLoaderStrategy) -> Void


public protocol OPDynamicComponentManagerProtocol: AnyObject {
    
    /// 为宿主准备动态组件
    /// - Parameters:
    ///   - componentAppID: 动态组件的 appID
    ///   - requireVersion: 动态组件的 版本
    ///   - hostAppID: 宿主小程序的 appID
    ///   - previewToken: 如果是小程序预览模式，需要传递。可以为空
    ///   - completeBlock: callback
    func prepareDynamicComponent(componentAppID: String,
                                 requireVersion: String,
                                 hostAppID: String,
                                 previewToken: String?,
                                 completeBlock: completeCallback?)
    /// 预加载的方法，收到预推后执行该方法predownload离线包
    ///  - Parameters:
    ///  - componentAppID: 动态组件的 appID
    func preloadDynamicComponentWith(componentAppID: String,
                                     requireVersion: String,
                                     hostAppID: String,
                                     completeBlock: completeCallback?)
    
    /// 获取组件资源
    /// - Returns: 返回组件资源
    func getComponentResourceByPath(path: String, previewToken: String? , componentID: String, requireVersion: String) -> Data?
    
    /// 清理动态组件缓存
    func cleanDynamicCompoments()
}
