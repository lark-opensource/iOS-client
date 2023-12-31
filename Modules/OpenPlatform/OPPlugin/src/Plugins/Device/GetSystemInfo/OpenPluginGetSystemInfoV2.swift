//
//  OpenPluginGetSystemInfoV2.swift
//  OPPlugin
//
//  Created by 王飞 on 2022/3/21.
//

import LarkOpenPluginManager
import LarkOpenAPIModel
import OPSDK
import OPPluginManagerAdapter
import UIKit
import WebBrowser
import TTMicroApp

extension OpenPluginGetSystemInfo {
    
    /// 获取当前容器 window 配置
    /// - Parameter gadgetContext: 当前 API 运行上下文
    /// - Returns: window 对象及 size
    private func currentWindowAndSize(gadgetContext: OPAPIContextProtocol) -> (UIWindow?, CGSize) {
        let uniqueID = gadgetContext.uniqueID
        // 目前只处理三种形态，其余的形态都不再支持了
        let windowSize: CGSize
        let window: UIWindow?
        switch uniqueID.appType {
        case .block:
            window = nil
            windowSize = BDPResponderHelper.windowSize(window)
        case .gadget:
            window = gadgetContext.controller?.view.window
            let container = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPContainerModuleProtocol.self) as? BDPContainerModuleProtocol
            windowSize = container?.containerSize(gadgetContext.controller, type: uniqueID.appType, uniqueID: uniqueID) ?? .zero
        case .webApp:
            window = gadgetContext.controller?.view.window
            windowSize = BDPResponderHelper.windowSize(window)
        default:
            window = nil
            windowSize = .zero
        }
        return (window, windowSize)
        
    }
    
    /// 获取当前容器 safe area rect
    /// - Parameters:
    ///   - window: 当前 window
    ///   - windowSize: 当前 window 尺寸
    /// - Returns: safe area rect
    func currentSafeArea(forWindow window: UIWindow?, windowSize: CGSize) -> GetSystemInfoSafeAreaRect  {
        let top = Float(BDPResponderHelper.safeAreaInsets(window).top)
        let statusBarHeight = Float(top == 0 ? 20 : top)
        let screenWidth = Float(UIScreen.main.bounds.size.width)
        let screenHeight = Float(UIScreen.main.bounds.size.height)
        
        /// 在竖屏正方向下的安全区域
        let safeAreaLeft: Float = 0
        let safeAreaRight: Float = 0
        let safeAreaTop = statusBarHeight
        
        /// safeAreaBottom以前是写死的，判断为x系列的手机则为34，否则为0
        /// 与原始开发者确认需求后，直接拿safeAreaInsets即可
        let safeAreaBottom = Float(BDPResponderHelper.safeAreaInsets(window).bottom)
        let safeAreaWidth = screenWidth - safeAreaRight - safeAreaLeft
        /// 安全区域的宽度，单位逻辑像素
        let safeAreaHeight = screenHeight - safeAreaBottom - safeAreaTop
        /// 安全区域的高度，单位逻辑像素
        return .init(left: safeAreaLeft,
                     right: screenWidth - safeAreaRight,
                     top: safeAreaTop,
                     bottom: screenHeight - safeAreaBottom,
                     width: safeAreaWidth,
                     height: safeAreaHeight)
    }
    
    
    /// 获取当前导航区域 safe area
    /// - Parameter gadgetContext: 当前 API 运行容器的上下文环境
    /// - Returns: safe area
    private func navigationBarSafeArea(gadgetContext: OPAPIContextProtocol) -> GetSystemInfoSafeAreaRect? {
        if gadgetContext.uniqueID.appType == .gadget {
            let naviBarSafeArea = BDPAppController
                .currentAppPageController(gadgetContext.controller, fixForPopover: false)?
                .getNavigationBarSafeArea()
            if let naviBarSafeAreaObject = naviBarSafeArea {
                return .init(left:Float(naviBarSafeAreaObject.left),
                              right: Float(naviBarSafeAreaObject.right),
                              top: Float(naviBarSafeAreaObject.top),
                              bottom: Float(naviBarSafeAreaObject.bottom),
                              width: Float(naviBarSafeAreaObject.width),
                              height: Float(naviBarSafeAreaObject.height))
            }
        }
        return nil
    }

    /// 获取页面方向(小程序横屏)
    /// - Parameter gadgetContext: 当前 API 运行容器的上下文环境
    /// - Returns: 页面方向;
    private func pageOrientation(gadgetContext: OPAPIContextProtocol) -> String? {
        guard OPGadgetRotationHelper.enableResponseOrientationInfo() else {
            return nil
        }

        // 非小程序返回原值
        guard gadgetContext.uniqueID.appType == .gadget else {
            return nil
        }

        var pageOrientation: String?
        if let appController = gadgetContext.controller as? BDPAppController,
           let appPageController = appController.currentAppPage() {
            pageOrientation = OPGadgetRotationHelper.configPageInterfaceResponse(appPageController.pageInterfaceOrientation)
        }

        return pageOrientation
    }

    /// 获取statuBar的高度(小程序横屏)
    /// - Parameters:
    ///   - gadgetContext: 当前 API 运行容器的上下文环境
    ///   - safeArea: 当前容器 safe area rect
    /// - Returns: 状态栏高度
    private func statusBarHeight(gadgetContext: OPAPIContextProtocol, safeArea: GetSystemInfoSafeAreaRect) -> Float {
        var statusBarHeight = safeArea.top == 0 ? 20 : safeArea.top
        // FG关闭时, 返回原逻辑的值
        guard OPGadgetRotationHelper.enableResponseOrientationInfo() else {
            return statusBarHeight
        }
        // 非小程序返回原值
        guard gadgetContext.uniqueID.appType == .gadget else {
            return statusBarHeight
        }

        if let appController = gadgetContext.controller as? BDPAppController,
           let appPageController = appController.currentAppPage() {
            if appPageController.pageInterfaceOrientation == .landscapeLeft
                || appPageController.pageInterfaceOrientation == .landscapeRight {
                statusBarHeight = 0
            }
        }
        return statusBarHeight
    }
    
    private func CommonModel(gadgetContext: OPAPIContextProtocol, trace: OPTrace) throws -> OpenPluginDeviceCommonInfo {
        let uniqueID = gadgetContext.uniqueID
        var common = OpenPluginDeviceCommonInfo()
        common.geo = try geoInfoForAppID(uniqueID.appID, trace: trace)
        
        return common
    }

    /// 全部 UI 信息
    /// - Parameter gadgetContext: 当前 API 运行容器的上下文环境
    /// - Returns: UI 信息
    private func UIModel(gadgetContext: OPAPIContextProtocol) -> OpenPluginDeviceUIInfo {
        let uniqueID = gadgetContext.uniqueID
        let (window, windowSize) = currentWindowAndSize(gadgetContext: gadgetContext)
        let safeArea = currentSafeArea(forWindow: window, windowSize: windowSize)
        
        let windowWidth = Float(windowSize.width)
        let windowHeight = Float(windowSize.height)
        let screenWidth = Float(UIScreen.main.bounds.size.width)
        let screenHeight = Float(UIScreen.main.bounds.size.height)
        let statusBarHeight = statusBarHeight(gadgetContext: gadgetContext, safeArea: safeArea)
        let naviSafeArea = navigationBarSafeArea(gadgetContext: gadgetContext)
        // 页面方向,当前受FG控制.
        let pageOrientation = pageOrientation(gadgetContext: gadgetContext)

        return .init(screenWidth: screenWidth,
                     screenHeight: screenHeight,
                     windowWidth: windowWidth,
                     windowHeight: windowHeight,
                     statusBarHeight: statusBarHeight,
                     theme: themeForUniqueID(uniqueID),
                     safeArea: safeArea,
                     navigationBarSafeArea: naviSafeArea,
                     pageOrientation: pageOrientation)
    }
    
    /// Block 容器信息，仅在 Block 容器中可用
    /// - Parameter uniqueID: 业务唯一 id
    /// - Returns: block 需要填充的信息
    private func blockInfo(uniqueID: OPAppUniqueID) -> OpenPluginBlockInfo? {
        guard uniqueID.appType == .block else {
            return nil
        }
        let blockitSDKVersion = uniqueID.runtimeVersion ?? ""
        let packageVersion = uniqueID.packageVersion ?? ""
        let host = uniqueID.host
        return .init(blockitVersion: blockitSDKVersion,
                     packageVersion: packageVersion,
                     host: host)
    }
    
    /// 获取当前 gadget 及 web 信息，字段较少直接合并了
    /// - Parameter uniqueID: 业务唯一 id
    /// - Returns: gadget 及 web 信息
    private func gadgetAndWebInfo(uniqueID: OPAppUniqueID, gadgetContext: OPAPIContextProtocol) -> OpenPluginGadgetAndWebInfo? {
        let appType = uniqueID.appType
        if appType != .gadget && appType != .webApp {
            return nil
        }
        let common = BDPCommonManager.shared().getCommonWith(uniqueID)
        let sdkVersion = common?.sdkVersion ?? BDPVersionManager.localLibBaseVersionString() ?? ""
        let sdkUpdateVersion =  common?.sdkUpdateVersion ?? BDPVersionManager.localLibVersionString() ?? ""
        let gadgetVersion = common?.model.version ?? ""
        
        // 小程序、网页应用的半屏信息
        var viewMode = "standard"
        var viewRatio = ""
        if appType == .gadget && BDPXScreenManager.isXScreenMode(uniqueID) {
            viewMode = "panel"
            viewRatio = BDPXScreenManager.xScreenPresentationStyle(uniqueID) ?? ""
        } else if appType == .webApp {
            if let webBrowser = gadgetContext.controller as? WebBrowser {
                viewMode = webBrowser.viewMode ?? "standard"
                viewRatio = webBrowser.viewRatio ?? ""
            }
        }
        
        return .init(gadgetVersion: gadgetVersion, sdkVersion: sdkVersion, sdkUpdateVersion: sdkUpdateVersion,viewMode: viewMode,viewRatio: viewRatio)
    }
    
    /// 当前该 API 支持的容器类型
    private var supportAppType: [OPAppType] {
        [
            .gadget,
            .webApp,
            .block,
        ]
    }
    
    /// 检查容器类型
    /// - Parameter appType: 当前容器类型
    private func checkAppType(appType: OPAppType) throws {
        if !supportAppType.contains(appType) {
            throw OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setErrno(OpenAPICommonErrno.unable)
        }
    }
    
    func getSystemInfoLocalV2(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol) -> OpenAPIBaseResponse<OpenPluginGetSystemInfoResult> {
        do {
            context.apiTrace.info("getSystemInfoV2 begin")
            let uniqueID = gadgetContext.uniqueID
            try checkAppType(appType: uniqueID.appType)
            context.apiTrace.info("getSystemInfoV2 checkAppType done")
            let common = try CommonModel(gadgetContext: gadgetContext, trace: context.apiTrace)
            let ui = UIModel(gadgetContext: gadgetContext)
            let block = blockInfo(uniqueID: uniqueID)
            let gadgetAndWeb = gadgetAndWebInfo(uniqueID: uniqueID, gadgetContext: gadgetContext)
            let tenantGeo = try getTenantGeo(appId: uniqueID.appID, trace: context.apiTrace)
            let result = OpenPluginGetSystemInfoV2Result(
                common:common,
                ui: ui,
                gadgetAndWeb: gadgetAndWeb,
                block: block,
                tenantGeo: tenantGeo
            )
            context.apiTrace.info("getSystemInfoV2 success")
            return .success(data: .init(result))
        } catch let e as OpenAPIError {
            context.apiTrace.error(e.outerMessage ?? OpenAPICommonErrorCode.unknown.errMsg)
            return .failure(error: e)
        } catch {
            assertionFailure()
            context.apiTrace.error(OpenAPICommonErrorCode.unknown.errMsg)
            return .failure(error: OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown))
        }
    }
}
