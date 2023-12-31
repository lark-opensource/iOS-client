//
//  OpenPluginTabBar.swift
//  OPPlugin
//
//  Created by yi on 2021/4/7.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPFoundation
import LKCommonsLogging
import TTMicroApp
import OPPluginManagerAdapter
import OPSDK
import LarkOpenAPIModel
import LarkContainer

final class OpenPluginTabBar: OpenBasePlugin {
    
    private static let errorMsgGadgetContextIsNil = "gadgetContext is nil"
    private static let errorMsgControllerIsNil = "controller is nil"
    private static let errorMsgNoTabBar = "The current app does not contain a tabbar"
    private static let errorMsgTabItemIndexOutOfBounds = "Tab item index out of bounds"
    private static let errorMsgSandboxIsNil = "sandbox is nil"

    private enum APIName: String {
        case showTabBar
        case hideTabBar
        case hideTabBarRedDot
        case showTabBarRedDot
        case removeTabBarBadge
        case setTabBarBadge
        case setTabBarItem
        case setTabBarStyle
        case removeTabBarItem
        case addTabBarItem
    }
    
    func showTabBar(params: OpenAPIShowTabBarParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        tabbarController.setTabBarVisible(true, animated: params.animation) { (finished) in
            if finished {
                callback(.success(data: nil))
            } else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setOuterMessage("show tabBar failed").setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
            }
        }
    }

    func hideTabBar(params: OpenAPIHideTabBarParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        tabbarController.setTabBarVisible(false, animated: params.animation) { (finished) in
            if finished {
                callback(.success(data: nil))
            } else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setOuterMessage("hide tabBar failed").setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
            }
        }
    }

    func showTabBarRedDot(params: OpenAPIShowTabBarRedDotParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        let tabBarItemsCount = tabbarController.tabBar.items?.count ?? 0
        guard params.index >= 0, params.index < tabBarItemsCount else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage(Self.errorMsgTabItemIndexOutOfBounds).setOuterMessage(Self.errorMsgTabItemIndexOutOfBounds).setErrno(OpenAPITabbarErrno.indexOutOfBounds)
            callback(.failure(error: error))
            return
        }
        tabbarController.tabBar.showRedDot(with: params.index)
        callback(.success(data: nil))

    }

    func hideTabBarRedDot(params: OpenAPIHideTabBarRedDotParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }

        let tabBarItemsCount = tabbarController.tabBar.items?.count ?? 0
        guard params.index >= 0, params.index < tabBarItemsCount else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage(Self.errorMsgTabItemIndexOutOfBounds).setOuterMessage(Self.errorMsgTabItemIndexOutOfBounds).setErrno(OpenAPITabbarErrno.indexOutOfBounds)
            callback(.failure(error: error))
            return
        }
        tabbarController.tabBar.hideRedDot(with: params.index)
        callback(.success(data: nil))
    }
    
    func removeTabBarBadge(params: OpenAPIRemoveTabBarBadgeParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        let tabBarItemsCount = tabbarController.tabBar.items?.count ?? 0
        guard params.index >= 0, params.index < tabBarItemsCount else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage(Self.errorMsgTabItemIndexOutOfBounds).setOuterMessage(Self.errorMsgTabItemIndexOutOfBounds).setErrno(OpenAPITabbarErrno.indexOutOfBounds)
            callback(.failure(error: error))
            return
        }
        tabbarController.tabBar.removeBadge(with: params.index)
        callback(.success(data: nil))
    }
    
    func setTabBarBadge(params: OpenAPISetTabBarBadgeParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        let tabBarItemsCount = tabbarController.tabBar.items?.count ?? 0
        guard params.index >= 0, params.index < tabBarItemsCount else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage(Self.errorMsgTabItemIndexOutOfBounds).setOuterMessage(Self.errorMsgTabItemIndexOutOfBounds).setErrno(OpenAPITabbarErrno.indexOutOfBounds)
            callback(.failure(error: error))
            return
        }
        tabbarController.tabBar.setTabBarBadgeWith(params.index, text: params.text)
        callback(.success(data: nil))
    }
    
    func setTabBarItem(params: OpenAPISetTabBarItemParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        let tabBarItemsCount = tabbarController.tabBar.items?.count ?? 0
        guard params.index >= 0, params.index < tabBarItemsCount else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam).setMonitorMessage(Self.errorMsgTabItemIndexOutOfBounds).setOuterMessage(Self.errorMsgTabItemIndexOutOfBounds)
                .setErrno(OpenAPITabbarErrno.indexOutOfBounds)
            callback(.failure(error: error))
            return
        }

        /// 标准化文件 API 迁移
            standardFileAPISetTabBarItem(
                params: params,
                context: context,
                gadgetContext: gadgetContext,
                tabbarController: tabbarController,
                callback: callback
            )
    }

    /// 文件操作标准化迁移
    ///
    /// 1. 使用标准化文件 API 操作
    /// 2. outerMessage 与原逻辑保持不变
    /// 3. 去除冗余的 monitorMessage
    /// 4. 文件 API 差异逻辑部分的 error 使用标准 API error
    ///
    private func standardFileAPISetTabBarItem(
        params: OpenAPISetTabBarItemParams,
        context: OpenAPIContext,
        gadgetContext: OPAPIContextProtocol,
        tabbarController: BDPTabBarPageController,
        callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void
    ) {
        do {
            let fsContext = FileSystem.Context(uniqueId: gadgetContext.uniqueID, trace: context.apiTrace, tag: "setTabBarItem")

            /// 检查 iconPath
            if !params.iconPath.isEmpty {
                let iconFile = try FileObject(rawValue: params.iconPath)

                /// 文件是否存在
                guard try FileSystem.fileExist(iconFile, context: fsContext) else {
                    // API迁移变更记录： OPGeneralAPICodeFileCanNotRead 正确的应该是 iconNotFound
                    let error = OpenAPIError(code: SetTabBarItemErrorCode.iconNotFound)
                        .setOuterMessage("iconPath not found: \"\(params.iconPath)\"").setErrno(OpenAPICommonErrno.fileNotExists(filePath: params.iconPath))
                    callback(.failure(error: error))
                    return
                }

                /// 文件是否可读
                guard try FileSystem.canRead(iconFile, context: fsContext) else {
                    // API迁移变更记录： OPGeneralAPICodeFileCanNotRead，重构后根据要求全部改为 unknown
                    let error = OpenAPIError(code: InterfaceCommonErrorCode.noFileAccessPermission)
                        .setOuterMessage("permission denied, open \"\(params.iconPath)\"").setErrno(OpenAPICommonErrno.readPermissionDenied(filePath: params.iconPath))
                    callback(.failure(error: error))
                    return
                }
            }

            /// 检查 selectedIconPath
            if !params.selectedIconPath.isEmpty {
                let selectedIconFile = try FileObject(rawValue: params.selectedIconPath)

                /// 文件是否存在
                guard try FileSystem.fileExist(selectedIconFile, context: fsContext) else {
                    // API迁移变更记录： OPGeneralAPICodeFileCanNotRead，重构后根据要求全部改为 unknown
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.invalidParam)
                        .setOuterMessage("selectedIconPath not found: \"\(params.selectedIconPath)\"").setErrno(OpenAPICommonErrno.fileNotExists(filePath: params.selectedIconPath))
                    callback(.failure(error: error))
                    return
                }

                /// 文件是否可读
                guard try FileSystem.canRead(selectedIconFile, context: fsContext) else {
                    // API迁移变更记录： OPGeneralAPICodeFileCanNotRead，重构后根据要求全部改为 unknown
                    let error = OpenAPIError(code: InterfaceCommonErrorCode.noFileAccessPermission)
                        .setOuterMessage("permission denied, open \"\(params.selectedIconPath)\"").setErrno(OpenAPICommonErrno.readPermissionDenied(filePath: params.selectedIconPath))
                    callback(.failure(error: error))
                    return
                }
            }

            // API迁移变更记录: 原代码在这里进行了一次主现程转换并重新调用 tryGetTabbarController，由于新的API体系自己保证了 API 在主线程调用，因此这里不需要再切换主线程了
            tabbarController.setTabBarItem(
                params.index,
                text: params.text,
                iconPath: params.iconPath,
                selectedIconPath: params.selectedIconPath
            ) { (finished) in
                if finished {
                    callback(.success(data: nil))
                } else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("set tabBar item failed").setErrno(OpenAPICommonErrno.internalError)
                    callback(.failure(error: error))
                }
            }
        } catch let error as FileSystemError {
            callback(.failure(error: error.openAPIError))
        } catch {
            callback(.failure(error: error.fileSystemUnknownError))
        }
    }
    
    func setTabBarStyle(params: OpenAPISetTabBarStyleParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        tabbarController.setTabBarStyle(params.color, textSelectedColor: params.selectedColor, backgroundColor: params.backgroundColor, borderStyle: params.borderStyle, borderColor:params.borderColor) { (finished) in
            if finished {
                callback(.success(data: nil))
            } else {
                let errorMsg = "set tabBar style failed"
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage(errorMsg).setOuterMessage(errorMsg).setErrno(OpenAPICommonErrno.internalError)
                callback(.failure(error: error))
            }
        }
    }
    
    /// 删除TabBar的item
    /// https://bytedance.feishu.cn/docs/doccnQJAGDyfzZLtkOAczdlxnOe#
    func removeTabBarItem(params: OpenAPIRemoveTabBarItemParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        tabbarController.removeTabBarItem(params.tag) { (success, message, callbackcode) in
            if success {
                callback(.success(data: nil))
            } else {
                let errorMsg = message.isEmpty ? "remove tabBar item failed" : message
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage(errorMsg).setOuterMessage(errorMsg)
                switch callbackcode {
                case -10002:
                    error.setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "tag")))
                case -10011:
                    error.setErrno(OpenAPITabbarErrno.indexOutOfBounds)
                case -10013:
                    error.setErrno(OpenAPITabbarErrno.deleteCurrentTab)
                case -10014:
                    error.setErrno(OpenAPITabbarErrno.least2Tab)
                case -10015:
                    error.setErrno(OpenAPITabbarErrno.canNotFoundPath)
                default:
                    error.setErrno(OpenAPICommonErrno.internalError)
                }
                callback(.failure(error: error))
            }
        }
    }
    
    // 需求新增小程序API：addTabBarItem
    // 需求文档:https://bytedance.feishu.cn/docs/doccnQJAGDyfzZLtkOAczdlxnOe#
    func addTabBarItem(params: OpenAPIAddTabBarItemParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let (gadgetContext, tabbarController) = getTabbarControllerElseFailure(context, callback) else {
            return
        }
        if (params.pagePath.isEmpty) {
            let message = "no page path"
            let error = OpenAPIError(code: AddTabBarItemErrorCode.getNilPagePath).setMonitorMessage(message).setOuterMessage(message).setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "pagePath")))
            callback(.failure(error: error))
            return
        }

        tabbarController.addTabBarItem(params.index, pagePath: params.pagePath, text: params.text, dark: params.dark, light: params.light) { (success, message, callbackcode) in
            if success {
                callback(.success(data: nil))
            } else {
                let errorMsg = message.isEmpty ? "add tabBar item failed" : message
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setMonitorMessage(errorMsg).setOuterMessage(errorMsg).setOuterCode(Int(callbackcode))
                switch callbackcode {
                case -10005:
                    error.setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "light.iconPath")))
                case -10006:
                    error.setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "light.selectedIconPath")))
                case -10008:
                    error.setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "dark.iconPath")))
                case -10009:
                    error.setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "dark.selectedIconPath")))
                case -10010:
                    error.setErrno(OpenAPITabbarErrno.upTo5Tab)
                case -10011:
                    error.setErrno(OpenAPITabbarErrno.indexOutOfBounds)
                case -10012:
                    error.setErrno(OpenAPITabbarErrno.tabAlreadyExist)
                default:
                    error.setErrno(OpenAPICommonErrno.internalError)
                }

                callback(.failure(error: error))
                return
            }
        }
    
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        
        registerInstanceAsyncHandler(for: APIName.showTabBar.rawValue, pluginType: Self.self, paramsType: OpenAPIShowTabBarParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.showTabBar(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: APIName.hideTabBar.rawValue, pluginType: Self.self, paramsType: OpenAPIHideTabBarParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.hideTabBar(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: APIName.hideTabBarRedDot.rawValue, pluginType: Self.self, paramsType: OpenAPIHideTabBarRedDotParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.hideTabBarRedDot(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: APIName.showTabBarRedDot.rawValue, pluginType: Self.self, paramsType: OpenAPIShowTabBarRedDotParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.showTabBarRedDot(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.removeTabBarBadge.rawValue, pluginType: Self.self, paramsType: OpenAPIRemoveTabBarBadgeParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.removeTabBarBadge(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.setTabBarBadge.rawValue, pluginType: Self.self, paramsType: OpenAPISetTabBarBadgeParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.setTabBarBadge(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.setTabBarItem.rawValue, pluginType: Self.self, paramsType: OpenAPISetTabBarItemParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.setTabBarItem(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.setTabBarStyle.rawValue, pluginType: Self.self, paramsType: OpenAPISetTabBarStyleParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.setTabBarStyle(params: params, context: context, callback: callback)
        }
        
        registerInstanceAsyncHandler(for: APIName.removeTabBarItem.rawValue, pluginType: Self.self, paramsType: OpenAPIRemoveTabBarItemParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.removeTabBarItem(params: params, context: context, callback: callback)
        }
        
        // 小程序API_addTabBarItem，仅在新API中添加
        registerInstanceAsyncHandler(for: APIName.addTabBarItem.rawValue, pluginType: Self.self, paramsType: OpenAPIAddTabBarItemParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.addTabBarItem(params: params, context: context, callback: callback)
        }
    }
}

extension OpenPluginTabBar {
    
    private func getTabbarControllerElseFailure<Result>(_ context: OpenAPIContext, _ callback: @escaping (OpenAPIBaseResponse<Result>) -> Void) -> (OPAPIContextProtocol, BDPTabBarPageController)?
    where Result: OpenAPIBaseResult {
        guard let gadgetContext = context.gadgetContext as? GadgetAPIContext else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError).setMonitorMessage(Self.errorMsgGadgetContextIsNil).setErrno(OpenAPICommonErrno.internalError)
            callback(.failure(error: error))
            return nil
        }
        guard let controller = gadgetContext.getControllerElseFailure(context.apiTrace, callback) else {
            return nil
        }
        guard let tabbarController = tryGetTabbarController(controller: controller, context: context) else {
            let error = OpenAPIError(code: TabBarErrorCode.noTab).setMonitorMessage(Self.errorMsgNoTabBar).setOuterMessage(Self.errorMsgNoTabBar).setErrno(OpenAPITabbarErrno.notTabbar)
            callback(.failure(error: error))
            return nil
        }
        return (gadgetContext, tabbarController)
    }
    
    private func tryGetTabbarController(controller: UIViewController, context: OpenAPIContext) -> BDPTabBarPageController? {
        guard let pageVC = BDPAppController.currentAppPageController(controller, fixForPopover: false) else {
            context.apiTrace.info("pageVC is nil")
            return nil
        }
        var tabBarController: BDPTabBarPageController?
        if pageVC.navigationController?.viewControllers.first != pageVC && pageVC.hidesBottomBarWhenPushed {
            return tabBarController
        }
        if let tab = pageVC.navigationController?.tabBarController as? BDPTabBarPageController {
            tabBarController = tab
        } else {
            if let vcs = pageVC.navigationController?.viewControllers.reversed() {
                let reversedVC = Array(vcs)
                for vc in reversedVC {
                    if let vc = vc as? BDPTabBarPageController {
                        tabBarController = vc
                        break
                    }
                }

            }
        }
        return tabBarController

    }
}
