//
//  BDPTag.swift
//  Timor
//
//  Created by 武嘉晟 on 2020/4/28.
//

import Foundation
//  Timor模块Tag枚举
public enum BDPTagEnum: String {
    /// 引擎基础Tag
    case gadget
    /// 引擎WebView Tag
    case webview
    /// 引擎卡片API
    case cardApi
    /// 引擎卡片请求Template
    case cardRequestTemplate
    /// 引擎卡片图片请求器
    case cardImageFetcher
    /// 引擎卡片容器
    case cardContainer
    /// 卡片渲染引擎
    case cardRenderEngine
    /// 卡片引擎生命周期
    case cardLifeCycle
    /// 卡片信息回调
    case cardInfoListener
    /// meta管理器
    case metaManager
    /// meta远端请求器
    case metaRemoteRequester
    /// meta本地存取器
    case metaLocalAccessor
    /// meta本地存取器【PKM】
    case metaLocalAccessorPKM
    /// 包管理
    case packageManager
    /// 大组件管理器
    case componentsManager
    /// 大组件下载器
    case componentDownloader
    /// 卡片 provider
    case cardProvider
    /// 小程序 provider
    case gadgetProvider
    /// 卡片门面
    case cardFacade
    /// gadget 分享
    case gadgetShare
    /// getEnvVariable api tag
    case getEnvVariable
    /// 文件系统API
    case fileSystemAPI
    /// storage API
    case storageAPI
    /// webview API
    case webviewAPI
    /// debugger
    case debugger
    /// logManager API
    case logManager
    /// network API
    case network
    /// 应用加载
    case appLoad
    /// APIBridge
    case apiBridge
    /// 规则引擎
    case strategy
    /// prefetch
    case prefetch
}

//  Timor模块Tag定义类(仅供OC打Log使用)
@objcMembers
open class BDPTag: NSObject {
    /// 引擎基础Tag
    public static let gadget = BDPTagEnum.gadget.rawValue
    /// 引擎WebView Tag
    public static let webview = BDPTagEnum.webview.rawValue
    /// 引擎卡片API
    public static let cardApi = BDPTagEnum.cardApi.rawValue
    /// 引擎卡片请求Template
    public static let cardRequestTemplate = BDPTagEnum.cardRequestTemplate.rawValue
    /// 引擎卡片图片请求器
    public static let cardImageFetcher = BDPTagEnum.cardImageFetcher.rawValue
    /// 引擎卡片容器
    public static let cardContainer = BDPTagEnum.cardContainer.rawValue
    /// 卡片渲染引擎
    public static let cardRenderEngine = BDPTagEnum.cardRenderEngine.rawValue
    /// 卡片引擎生命周期
    public static let cardLifeCycle = BDPTagEnum.cardLifeCycle.rawValue
    /// 卡片信息回调
    public static let cardInfoListener = BDPTagEnum.cardInfoListener.rawValue
    /// meta管理器
    public static let metaManager = BDPTagEnum.metaManager.rawValue
    /// meta本地存取器
    public static let metaLocalAccessor = BDPTagEnum.metaLocalAccessor.rawValue
    /// meta本地存取器
    public static let metaLocalAccessorPKM = BDPTagEnum.metaLocalAccessorPKM.rawValue
    /// meta远端请求器
    public static let metaRemoteRequester = BDPTagEnum.metaRemoteRequester.rawValue
    /// 包管理
    public static let packageManager = BDPTagEnum.packageManager.rawValue
    /// 大组件管理器
    public static let componentManager = BDPTagEnum.componentsManager.rawValue
    /// 大组件下载器
    public static let componentDownloader = BDPTagEnum.componentDownloader.rawValue
    /// 卡片 provider
    public static let cardProvider = BDPTagEnum.cardProvider.rawValue
    /// 小程序 provider
    public static let gadgetProvider = BDPTagEnum.gadgetProvider.rawValue
    /// 卡片门面
    public static let cardFacade = BDPTagEnum.cardFacade.rawValue
    /// gadget 分享
    public static let gadgetShare = BDPTagEnum.gadgetShare.rawValue
    /// getEnvVariable api tag
    public static let getEnvVariable = BDPTagEnum.getEnvVariable.rawValue
    /// 文件系统API
    public static let fileSystemAPI = BDPTagEnum.fileSystemAPI.rawValue
    /// storage API
    public static let storageAPI = BDPTagEnum.storageAPI.rawValue
    /// webview API
    public static let webviewAPI = BDPTagEnum.webviewAPI.rawValue
    /// debugger
    public static let debugger = BDPTagEnum.debugger.rawValue
    /// logManager API
    public static let logManager = BDPTagEnum.logManager.rawValue
    /// network API
    public static let network = BDPTagEnum.network.rawValue
    /// 应用加载
    public static let appLoad = BDPTagEnum.appLoad.rawValue
    /// APIBridge
    public static let apiBridge = BDPTagEnum.apiBridge.rawValue
    /// 规则引擎
    public static let strategy = BDPTagEnum.strategy.rawValue
    /// prefetch
    public static let prefetch = BDPTagEnum.prefetch.rawValue
}
