//
//  EMAPreloadFactory.swift
//  EEMicroAppSDK
//
//  Created by laisanpin on 2022/8/8.
//

import Foundation
import OPSDK
import ECOInfra
import LKCommonsLogging
import LarkContainer
import TTMicroApp
import OPBlock
import OPWebApp
import OPDynamicComponent

/// 业务方业务数据来源需要遵守的协议
@objc public protocol EMAPackagePreInfoProvider {
    // pull-预处理; 在需要主动pull数据的时候,调用该方法.
    // 需要在该方法中构建BDPPreloadHandleInfo数据, 然后传给BDPPreloadHandlerManager
    @objc func fetchPreUpdateSettings()

    // push-预处理; 在接收到push的时候, 调用该方法
    // 需要在该方法中构建BDPPreloadHandleInfo数据, 然后传给BDPPreloadHandlerManager
    @objc func pushPreUpdateSettings(_ item: Any)
}

public struct EMAPreloadError: Error {
    let errorMsg: String
}

@objc public enum EMAAppPreloadScene: Int {
    case silence = 0 // 止血
    case preUpdate   // 预安装
    case expired     // meta过期
}

/// 获取对应的预处理对象(线程安全)
@objcMembers final class EMAPackagePreloadFactory: NSObject {
    public static func createPackagePreload(scene: EMAAppPreloadScene, appType: OPAppType) -> EMAPackagePreInfoProvider? {
        var provider: EMAPackagePreInfoProvider? = nil
        switch scene {
        case .silence:
            provider = EMASilenceUpdateFactory.getAppSilenceUpdate(appType)
        case .preUpdate:
            provider = EMAAppPreUpdateFactory.getAppPreloadUpdate(appType)
        case .expired:
            provider = EMAMetaExpireUpdateFactory.getAppMetaExpired(appType)
        default:
            break
        }
        return provider
    }
}

class EMAAppPreUpdateFactory {
    private static var managerDic = [OPAppType : EMAPackagePreInfoProvider]()

    private static let lock = NSLock()

    public static func getAppPreloadUpdate(_ appType: OPAppType) -> EMAPackagePreInfoProvider? {
        var provider: EMAPackagePreInfoProvider? = nil
        Self.lock.lock()
        switch appType {
        case .gadget:
            if let _provider = managerDic[.gadget] {
                provider = _provider
            } else {
                provider = EMAGadgetPreUpdateManager()
                managerDic[appType] = provider
            }
        case .webApp:
            if let _provider = managerDic[.webApp] {
                provider = _provider
            } else {
                provider = EMAWebAppPreUpdateManager()
                managerDic[.webApp] = provider
            }
        default:
            break
        }
        Self.lock.unlock()
        return provider
    }
}

class EMASilenceUpdateFactory {
    private static var managerDic = [OPAppType : EMAPackagePreInfoProvider]()

    private static let lock = NSLock()

    public static func getAppSilenceUpdate(_ appType: OPAppType) -> EMAPackagePreInfoProvider? {
        var provider: EMAPackagePreInfoProvider? = nil
        Self.lock.lock()
        switch appType {
        case .gadget:
            if let _provider = managerDic[.gadget] {
                provider = _provider
            } else {
                provider = EMAGadgetSilenceUpdateManager()
                managerDic[appType] = provider
            }
        case .webApp:
            if let _provider = managerDic[.webApp] {
                provider = _provider
            } else {
                provider = EMAWebAppSilenceUpdateManager()
                managerDic[.webApp] = provider
            }
        default:
            break
        }
        Self.lock.unlock()
        return provider
    }
}

final class EMAMetaExpireUpdateFactory {
    private static var managerDic = [OPAppType : EMAPackagePreInfoProvider]()

    private static let lock = NSLock()

    public static func getAppMetaExpired(_ appType: OPAppType) -> EMAPackagePreInfoProvider? {
        var provider: EMAPackagePreInfoProvider? = nil
        Self.lock.lock()
        switch appType {
        case .gadget:
            if let _provider = managerDic[.gadget] {
                provider = _provider
            } else {
                provider = EMAGadgetExpiredManager()
                managerDic[appType] = provider
            }
        default:
            break
        }
        Self.lock.unlock()
        return provider
    }
}

/// 通用拦截器提供类
final class EMAInterceptorUtils {
    /// 无网络拦截器
    public static func networkInterceptor() -> BDPPreHandleInterceptor {
        return {(info: BDPPreloadHandleInfo) -> BDPInterceptorResponse in
            let networkConnected = BDPNetworking.isNetworkConnected()
            let needIntercept = !networkConnected
            return BDPInterceptorResponse(intercepted: needIntercept, interceptedType: .networkUnavailable)
        }
    }

    /// 非wifi情况下拦截
    public static func cellularInterceptor() -> BDPPreHandleInterceptor {
        return {(info: BDPPreloadHandleInfo) -> BDPInterceptorResponse in
            let networkType = BDPCurrentNetworkType()
            // 如果是在wifi白名单中,则直接放过
            if BDPPreloadHelper.cellularDataAllowList().contains(BDPSafeString(info.uniqueID.appID)) {
                return BDPInterceptorResponse(intercepted: false)
            }

            let needIntercept = networkType != String.Wifi
            return BDPInterceptorResponse(intercepted: needIntercept, interceptedType: .notWifiAllow)
        }
    }
}

/// 预安装重构工具类
@objcMembers public final class EMAPreloadHelper: NSObject {
    /// 注入预安装的handler
    static public func injectMetaProvidersIntoPrelaodHandler() {
        //注入预加载对象
        BDPPreloadHandlerManagerBridge.injectorProvider(provider: OPBlockMetaProvider(), appType: .block)
        BDPPreloadHandlerManagerBridge.injectorProvider(provider: OPWebAppMetaProvider(), appType: .webApp)
        BDPPreloadHandlerManagerBridge.injectorProvider(provider: OPDynamicComponentMetaProvider(), appType: .dynamicComponent)
    }
}

fileprivate extension String {
    static let Wifi = "wifi"
}
