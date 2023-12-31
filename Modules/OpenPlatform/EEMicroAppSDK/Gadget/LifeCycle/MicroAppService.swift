//
//  MicroAppService.swift
//  Pods
//
//  Created by lichen on 2018/8/15.
//

import Foundation
import LarkModel
import OPSDK
import ECOProbe

//  原作者：yuanping msg：应用设置页面
public struct MicroAppPermissionData {
    public enum Mod: Int {
    case readOnly = 0
    case readWrite = 1
    }
    public let scope: String
    public let name: String
    public let isGranted: Bool
    public let mod: Mod
    public init(scope: String, name: String, isGranted: Bool, mod: Mod) {
        self.scope = scope
        self.name = name
        self.isGranted = isGranted
        self.mod = mod
    }
}

// 原作者：tujinqiu msg：关于页面升级提示
public enum MicroAppUpdateStatus: UInt {
    case none = 0
    case fetchingMeta = 1
    case metaFailed = 2
    case newestVersion = 3
    case downloading = 4
    case downloadSuccess = 5
    case downloadFailed = 6
}

// 原作者:yinyuan.0 msg：小程序生命周期Listener
public protocol MicroAppService {
    func setup()
    func vote(in chat: Chat)
    func getPermissionDataArrayWith(appID: String, appType: OPAppType) -> [MicroAppPermissionData]
    func getAppVersion(appID: String) -> String
    func fetchAuthorizeData(appID: String, appType: OPAppType, storage: Bool, completion: @escaping ([AnyHashable: Any]?, [AnyHashable: Any]?, Error?) -> Void)
    func setPermissonWith(appID: String, scope: String, isGranted: Bool, appType: OPAppType)
    func fetchMetaAndDownload(appID: String, statusChanged: @escaping (MicroAppUpdateStatus, String?) -> Void)
    func download(appID: String, statusChanged: @escaping (MicroAppUpdateStatus, String?) -> Void)
    func canRestartApp(appID: String) -> Bool
    func restartApp(appID: String)
    // 监听指定小程序的生命周期, listener需自行持有或释放
    func addLifeCycleListener(appid: String, listener: MicroAppLifeCycleListener)
    // 监听所有小程序的生命周期, listener需自行持有或释放
    func addLifeCycleListener(listener: MicroAppLifeCycleListener)
    /// 彻底杀掉小程序
    func closeMicroAppWith(appID: String)
    /// 链接能否打开小程序
    func canOpen(url: String) -> Bool
    /// 网页应用新容器想要调用新整合的API
    /// - Parameters:
    ///   - method: 方法名
    ///   - args: 参数列表
    ///   - api: 网页应用容器
    ///   - sdk: 遵循OPJsSDKImplProtocol的对象
    ///   - needAuth: 调用API是否要走授权体系
    func invokeWeb(method: String, args: [String: Any], api: UIViewController, sdk: AnyObject, needAuth: Bool)

    /// 网页应用新容器想要调用新整合的API 提供给全新的LarkWebViewController使用，其他控制器请勿调用
    /// 网页调用tt系列API， params 必须封装为如下字典，否则无法兼容遗留代码的字典取值，本次修改增加一个shouldUseNewbridgeProtocol用于灰度
    /*
    {
     "params": {
        业务数据
     },
     "callbackId": ""
    }
    */
    /// - Parameters:
    ///   - method: 方法名
    ///   - params: 参数列表
    ///   - api: 网页应用容器
    ///   - sdk: 遵循OPJsSDKImplProtocol的对象
    ///   - needAuth: 调用API是否要走授权体系
    ///   - shouldUseNewbridgeProtocol: 代表是否使用了新的协议，webappengine看了一下代码是和controller生命周期挂钩，但是webvc加载不同的网页的时候，不同网页引入的jssdk可能是新的也可能是老的，需要兼容
    func invokeWeb(method: String, params: [String: Any], api: UIViewController, sdk: AnyObject, needAuth: Bool, shouldUseNewbridgeProtocol: Bool)
    /// 真机调试
    func realMachineDebug(schema: String)
}

// 原作者:yinyuan.0 msg：小程序生命周期Listener
public struct EMALifeCycleContext {
    public let uniqueID: OPAppUniqueID
    public let trace: OPTrace
    //启动参数里的 start_page, 需要传递到应用机制中
    public let startPage: String?
    public init(uniqueID: OPAppUniqueID, traceId: String, startPage: String? = nil) {
        self.uniqueID = uniqueID
        self.trace = OPTrace(traceId: traceId)
        self.startPage = startPage
    }
}

public protocol MicroAppLifeCycleListener: AnyObject {
    // 小程序开始加载
    func onStart(context: EMALifeCycleContext)

    // 小程序DomReady&setup完成
    func onLaunch(context: EMALifeCycleContext)

    // 小程序在onLaunch之前就取消
    func onCancel(context: EMALifeCycleContext)

    // 小程序从后台切回
    func onShow(context: EMALifeCycleContext)

    // 小程序进入后台
    func onHide(context: EMALifeCycleContext)

    // 小程序内存回收
    func onDestroy(context: EMALifeCycleContext)

    // 小程序加载失败
    func onFailure(context: EMALifeCycleContext, code: MicroAppLifeCycleError, msg: String?)

    // 小程序onMeta前提供外部block的机会
    func blockLoading(context: EMALifeCycleContext, callback: MicroAppLifeCycleBlockCallback)
    
    // 小程序第一次执行viewDidAppear生命周期
    func onFirstAppear(context: EMALifeCycleContext)
}

//  原作者：ysl msg：应用机制引导优化
public extension MicroAppLifeCycleListener {
    func onStart(context: EMALifeCycleContext) {}
    func onLaunch(context: EMALifeCycleContext) {}
    func onCancel(context: EMALifeCycleContext) {}
    func onShow(context: EMALifeCycleContext) {}
    func onHide(context: EMALifeCycleContext) {}
    func onDestroy(context: EMALifeCycleContext) {}
    func onFailure(context: EMALifeCycleContext, code: MicroAppLifeCycleError, msg: String?) {}
    func blockLoading(context: EMALifeCycleContext, callback: MicroAppLifeCycleBlockCallback) {
        callback.continueLoading()
    }
    func onFirstAppear(context: EMALifeCycleContext) {}
}

public protocol MicroAppLifeCycleBlockCallback {
    func continueLoading()
    func cancelLoading()
}

public enum MicroAppLifeCycleError: Int {
    case unknown = 0,           // 未知错误
    metaInfoFail = 1,           // meta请求失败
    appDownloadFail = 2,        // 小程序下载失败
    offline = 3,                // 小程序下线
    jsSDKOld = 4,               // jssdk版本太旧
    serviceDisabled = 5,        // 小程序服务不可用
    environmentInvalid = 6      // 小程序环境异常
}
