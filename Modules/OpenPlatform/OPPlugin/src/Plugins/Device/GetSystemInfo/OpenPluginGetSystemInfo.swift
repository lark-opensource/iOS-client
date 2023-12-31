//
//  OpenPluginGetSystemInfo.swift
//  OPPlugin
//
//  Created by bytedance on 2021/4/20.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOInfra
import OPFoundation
import UniverseDesignTheme
import LarkAccountInterface
import LarkSetting
import LarkContainer
import TTMicroApp

func themeForUniqueID(_ uniuqeID: OPAppUniqueID) -> String? {
    guard uniuqeID.isAppSupportDarkMode else {
        return nil
    }
    if #available(iOS 13.0, *) {
        switch UDThemeManager.getRealUserInterfaceStyle() {
        case .light:
            return OPThemeValueLight
        case .dark:
            return OPThemeValueDark
        default:
            return nil
        }
    } else {
        return nil
    }
}

final class OpenPluginGetSystemInfo: OpenBasePlugin {
    @ScopedProvider private var userService: PassportUserService?

    private lazy var geoConfig: [String: Any] = {
        do {
            let config = try userResolver.settings.setting(with: .make(userKeyLiteral: "api_system_info_geo"))
            return config
        } catch {
            return [
                "apps": [],
                "forceAll": false
            ]
        }
    }()
    
    public func getSystemInfoSync(params: OpenAPIBaseParams, context:OpenAPIContext, gadgetContext: OPAPIContextProtocol) -> OpenAPIBaseResponse<OpenPluginGetSystemInfoResult> {
        return getSystemInfoFeatureSelect(params: params, context: context, gadgetContext: gadgetContext)
    }

    public func getSystemInfo(params: OpenAPIBaseParams, context:OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenPluginGetSystemInfoResult>) -> Void) {
        let response = getSystemInfoFeatureSelect(params: params, context: context, gadgetContext: gadgetContext)
        callback(response)
    }
    
    public func getSystemInfoFeatureSelect(params: OpenAPIBaseParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol) -> OpenAPIBaseResponse<OpenPluginGetSystemInfoResult> {
        let enable = OpenAPIFeatureKey.getSystemInfo.isEnable()
        context.apiTrace.info("OpenPlugin.getSystemInfo use \(enable ? "new" : "old") logic")
        let uniqueID = gadgetContext.uniqueID
        // widget 形态不进行一致性处理
        if enable && uniqueID.appType != .widget {
            return getSystemInfoLocalV2(params: params, context: context, gadgetContext: gadgetContext)
        } else {
            return getSystemInfoLocal(params: params, context: context, gadgetContext: gadgetContext)
        }
    }
    
    func geoInfoForAppID(_ appID: String, trace: OPTrace) throws -> String? {
        guard enableGeo(appID) else { return nil }
        
        guard let userService else {
            trace.error("resolve PassportUserService failed")
            throw OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve PassportUserService failed")
        }
        
        return userService.userGeo
    }

    func getTenantGeo(appId: String, trace: OPTrace) throws -> String? {
        guard enableGeo(appId) else { return nil }
        
        guard let userService else {
            throw OpenAPIError(errno: OpenAPICommonErrno.internalError).setMonitorMessage("resolve PassportUserService failed")
        }
        
        return userService.userTenantGeo
    }

    private func enableGeo(_ appID: String) -> Bool {
        let forceAll = geoConfig["forceAll"] as? Bool ?? false
        if (forceAll) {
            return true
        }

        let apps = geoConfig["apps"] as? [String: Any] ?? [:]
        let enabled = apps[appID] as? Bool ?? false

        return enabled
    }
    
    public func getSystemInfoLocal(params: OpenAPIBaseParams, context:OpenAPIContext, gadgetContext: OPAPIContextProtocol) -> OpenAPIBaseResponse<OpenPluginGetSystemInfoResult> {
        let uniqueID = gadgetContext.uniqueID
        let model = OPUnsafeObject(BDPDeviceHelper.getDeviceName()) ?? ""
        let language = BDPApplicationManager.language() ?? ""
        let hostVersion = BDPDeviceTool.bundleShortVersion ?? ""
        // 宿主App名字(https://docs.bytedance.net/doc/UxLB5DWAzE256zDPVgvkef)
        let hostAppName = BDPApplicationManager.shared().applicationInfo[BDPAppNameKey] as? String ?? ""
        let theme = themeForUniqueID(uniqueID)
        let commonInfo = OpenPluginGetSystemInfoNativeCardResult(model: model, language: language, version: hostVersion, appName: hostAppName, theme: theme, geo: try? geoInfoForAppID(uniqueID.appID, trace: context.apiTrace))

// 原逻辑：
//        CGSize windowSize = CGSizeZero;
//        UIWindow *window = nil;
//        if(uniqueID.appType == BDPTypeNativeCard || uniqueID.appType == BDPTypeBlock) {
//            // 兼容不支持 BDPContainerModuleProtocol 的应用形态，如 Card、Block
//            windowSize = [BDPResponderHelper windowSize:nil];
//            window = nil;
//            if (uniqueID.runtimeVersion) {
//                [commonInfo setValue:uniqueID.runtimeVersion forKey:@"blockitVersion"];
//            }
//        } else {
//            BDPResolveModule(container, BDPContainerModuleProtocol, context.engine.uniqueID.appType);
//            windowSize = [container containerSizeWithContext:context];
//            window = context.controller.view.window;
//        }
        var windowSize = CGSize.zero
        var window: UIWindow?
        var blockitSDKVersion: String?
        // block新增包版本
        var packageVersion: String?
        // 只有block会返回host字段
        var host: String?

        var pageOrientation: String?
        
        let top = BDPResponderHelper.safeAreaInsets(window).top
        var statusBarHeight = top == 0 ? 20 :top
        switch uniqueID.appType {
        case .block, .widget:
            // 兼容不支持 BDPContainerModuleProtocol 的类型，如 Card、Block
            windowSize = BDPResponderHelper.windowSize(nil)
            blockitSDKVersion = uniqueID.runtimeVersion
            packageVersion = uniqueID.packageVersion
            host = uniqueID.host
        case .webApp, .thirdNativeApp:
            window = gadgetContext.controller?.view.window
            windowSize = BDPResponderHelper.windowSize(window)
        case .gadget, .dynamicComponent:
            window = gadgetContext.controller?.view.window
            if let container = BDPModuleManager(of: uniqueID.appType).resolveModule(with: BDPContainerModuleProtocol.self) as? BDPContainerModuleProtocol {
                windowSize = container.containerSize(gadgetContext.controller, type: uniqueID.appType, uniqueID: uniqueID)
            } else {
                context.apiTrace.info("container is nil")
            }
            if OPGadgetRotationHelper.enableResponseOrientationInfo() {
                if let appController = gadgetContext.controller as? BDPAppController,
                   let appPageController = appController.currentAppPage() {
                    pageOrientation = OPGadgetRotationHelper.configPageInterfaceResponse(appPageController.pageInterfaceOrientation)
                    if appPageController.pageInterfaceOrientation == .landscapeLeft
                        || appPageController.pageInterfaceOrientation == .landscapeRight {
                        // 横屏下状态栏高度为0
                        statusBarHeight = 0
                    }
                } else {
                    context.apiTrace.info("can not find appPageController")
                }
            }
        case  .unknown, .sdkMsgCard:
            assertionFailure("invalid app type, should not enter here")
        }
        let screenWidth = UIScreen.main.bounds.size.width
        let screenHeight = UIScreen.main.bounds.size.height
        let windowWidth = windowSize.width
        let windowHeight = windowSize.height
        /// 在竖屏正方向下的安全区域
        let safeAreaLeft:Float = 0
        let safeAreaRight:Float = 0
        let safeAreaTop = statusBarHeight
        // safeAreaBottom以前是写死的，判断为x系列的手机则为34，否则为0；与原始开发者确认需求后，直接拿safeAreaInsets即可
        let safeAreaBottom = BDPResponderHelper.safeAreaInsets(window).bottom
        let safeAreaWidth:Float = Float(screenWidth) - safeAreaRight - safeAreaLeft// 安全区域的宽度，单位逻辑像素
        let safeAreaHeight:Float = Float(screenHeight - safeAreaBottom - safeAreaTop)// 安全区域的高度，单位逻辑像素
        let safeArea = GetSystemInfoSafeAreaRect(left: safeAreaLeft, right: Float(screenWidth) - safeAreaRight, top: Float(safeAreaTop), bottom: Float(screenHeight - safeAreaBottom), width: safeAreaWidth, height: safeAreaHeight)
        var naviBarSafeArea: BDPNaviBarSafeArea?
        if let pageController = BDPAppController.currentAppPageController(gadgetContext.controller, fixForPopover: false) {
            naviBarSafeArea = pageController.getNavigationBarSafeArea()
        }
        let sdkVersion:String
        let sdkUpdateVersion:String
        let gadgetVersion:String
        if let commonManager = BDPCommonManager.shared(), let common = commonManager.getCommonWith(uniqueID) {
            sdkVersion = common.sdkVersion ?? BDPVersionManager.localLibBaseVersionString() ?? ""
            sdkUpdateVersion = common.sdkUpdateVersion ?? BDPVersionManager.localLibVersionString() ?? ""
            gadgetVersion = common.model.version ?? ""
        } else {
            context.apiTrace.error("common is nil")
            sdkVersion = ""; sdkUpdateVersion = ""; gadgetVersion = ""
        }
        var navigationBarSafeArea:GetSystemInfoSafeAreaRect?
        if let naviBarSafeAreaObject = naviBarSafeArea {
            navigationBarSafeArea = GetSystemInfoSafeAreaRect(left:Float(naviBarSafeAreaObject.left) , right: Float(naviBarSafeAreaObject.right), top: Float(naviBarSafeAreaObject.top), bottom: Float(naviBarSafeAreaObject.bottom), width: Float(naviBarSafeAreaObject.width), height: Float(naviBarSafeAreaObject.height))
        }
        //commonInfo外为非公共基础信息
        let info = OpenPluginGetSystemInfoResult(commonInfo: commonInfo, screenWidth: Float(screenWidth), screenHeight: Float(screenHeight), windowWidth: Float(windowWidth), windowHeight: Float(windowHeight), statusBarHeight:Float(statusBarHeight), safeArea: safeArea, SDKVersion: sdkVersion, SDKUpdateVersion: sdkUpdateVersion, gadgetVersion: gadgetVersion, benchmarkLevel: 40, navigationBarSafeArea: navigationBarSafeArea, blockitVersion: blockitSDKVersion, packageVersion: packageVersion, host: host, pageOrientation: pageOrientation)
        return OpenAPIBaseResponse.success(data: info)
    }

    public func getPageSize(params: OpenAPIGetPageSizeParams, context:OpenAPIContext, gadgetContext: GadgetAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenPluginGetPageSizeResult>) -> Void) {

        guard let pageController = BDPAppController.currentAppPageController(gadgetContext.controller, fixForPopover: false) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("can not find appPageController")
            callback(.failure(error: error))
            return
        }

        guard let appPage = pageController.appPage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setErrno(OpenAPICommonErrno.unknown)
                .setMonitorMessage("app page is nil")
            callback(.failure(error: error))
            return
        }

        callback(.success(data: OpenPluginGetPageSizeResult(size: appPage.bdp_size)))
    }
    
    enum APIName: String {
        case getSystemInfo
        case getSystemInfoSync
        case getPageSize
    }
    
    @FeatureGatingValue(key: "openplatform.api.pluginmanager.extension.enable")
    var apiExtensionEnable: Bool

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        if apiExtensionEnable {
            let registerInfo = OpenAPIRegisterInfo(pluginType: Self.self, resultType: OpenPluginGetSystemInfoResult.self)
            let extensionInfo = OpenAPIExtensionInfo(type: OpenAPIGetSystemInfoExtension.self, defaultCanBeUsed: false)
            registerSync(for: APIName.getSystemInfoSync.rawValue, registerInfo: registerInfo, extensionInfo: extensionInfo) { Self.getSystemInfoSync($0) }
            registerAsync(for: APIName.getSystemInfo.rawValue, registerInfo: registerInfo, extensionInfo: extensionInfo) { Self.getSystemInfo($0) }
        } else {
            registerInstanceAsyncHandlerGadget(for: APIName.getSystemInfo.rawValue, pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenPluginGetSystemInfoResult.self) { (this, params, context, gadgetContext, callback) in
                this.getSystemInfo(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
            }
            registerInstanceSyncHandlerGadget(for: APIName.getSystemInfoSync.rawValue, pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenPluginGetSystemInfoResult.self) { (this, params, context, gadgetContext) -> OpenAPIBaseResponse<OpenPluginGetSystemInfoResult> in
                return this.getSystemInfoSync(params: params, context: context, gadgetContext: gadgetContext)
            }
        }

        if (OPGadgetRotationHelper.enableResponseOrientationInfo()) {
            registerInstanceAsyncHandlerGadget(for: APIName.getPageSize.rawValue, pluginType: Self.self, paramsType: OpenAPIGetPageSizeParams.self, resultType: OpenPluginGetPageSizeResult.self) { (this, params, context, gadgetContext, callback) in
                
                this.getPageSize(params: params, context:context, gadgetContext: gadgetContext, callback: callback)
            }
        }
    }
}

// MARK: Extension

extension OpenPluginGetSystemInfo {
    
    func getSystemInfoSync(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        getSystemInfoExtension: OpenAPIGetSystemInfoExtension
    ) -> OpenAPIBaseResponse<OpenPluginGetSystemInfoResult> {
        
        let v2Enable = getSystemInfoExtension.v1Disable()
        context.apiTrace.info("OpenPlugin.getSystemInfo use \(v2Enable ? "new" : "old") logic")
        if v2Enable {
            return self.getSystemInfoExtension(params: params, context: context, getSystemInfoExtension: getSystemInfoExtension)
        } else {
            guard let gadgetContext = context.additionalInfo["gadgetContext"] as? GadgetAPIContext else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("gadgetContext is nil")
                    .setErrno(OpenAPICommonErrno.unknown)
                return .failure(error: error)
                
            }
            return getSystemInfoLocal(params: params, context: context, gadgetContext: gadgetContext)
        }
    }
    
    func getSystemInfo(
        params: OpenAPIBaseParams,
        context: OpenAPIContext,
        getSystemInfoExtension: OpenAPIGetSystemInfoExtension,
        callback: @escaping (OpenAPIBaseResponse<OpenPluginGetSystemInfoResult>) -> Void
    ) {
        let response = getSystemInfoSync(params: params, context: context, getSystemInfoExtension: getSystemInfoExtension)
        callback(response)
    }
}
