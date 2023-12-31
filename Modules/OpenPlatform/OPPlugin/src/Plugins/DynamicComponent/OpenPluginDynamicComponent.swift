//
//  OpenPluginDynamicComponent.swift
//  OPPlugin
//
//  Created by laisanpin on 2022/5/31.
//  加载动态组件
//  https://bytedance.feishu.cn/docx/doxcnyN34SKuYvJEpiIvznEsnUg

import Foundation
import OPFoundation
import OPSDK
import OPPluginManagerAdapter
import TTMicroApp
import LarkOpenAPIModel
import LarkOpenPluginManager
import OPDynamicComponent
import LarkContainer

final class OpenPluginLoadPlugin: OpenBasePlugin {

    private let dynamicComponentManager = OPDynamicComponentManager.sharedInstance

    func loadPlugin(params: OpenLoadPluginParams, context: OpenAPIContext, callback: @escaping(OpenAPIBaseResponse<OpenAPILoadPluginResult>) -> Void) {
        // 上报API调用埋点
        OPDynamicComponentHelper.reportLoadPluginStartMonitor(uniqueID: context.uniqueID,
                                                              pluginId: params.pluginId,
                                                              pluginVersion: params.version,
                                                              webviewId: params.webviewId)
        guard let uniqueID = context.uniqueID else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setMonitorMessage("uniqueID is nil")
            callback(.failure(error: error))
            OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: context.uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: error.code.rawValue, errMsg: error.monitorMsg)
            return
        }

        // 检查settings开关
        guard OPDynamicComponentHelper.enableDynamicComponent(uniqueID) else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                .setMonitorMessage("settings enable is false, appID: \(BDPSafeString(uniqueID.appID))")
            context.apiTrace.info("\(String.kDynamicTag) \(BDPSafeString(uniqueID.fullString)) settings return false")
            callback(.failure(error: error))
            OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: error.code.rawValue, errMsg: error.monitorMsg)
            return
        }

        context.apiTrace.info("\(String.kDynamicTag) \(BDPSafeString(uniqueID.fullString)) loadPlugin with pluginId: \(params.pluginId), version: \(params.version), webviewId: \(params.webviewId)")

        var previewToken: String?
        var isPreviewDynamicComponent = false
        // 这边预览插件的时候,开发者传入的version要为dev, 否则不认为其在调试插件.
        if params.version == "dev" && uniqueID.versionType == .preview,
           let container = OPApplicationService.current.getContainer(uniuqeID: uniqueID),
           let _previewToken = container.containerContext.containerConfig.previewToken {
            previewToken = _previewToken
            isPreviewDynamicComponent = true
            context.apiTrace.info("\(String.kDynamicTag) \(BDPSafeString(uniqueID.fullString)) loadPlugin by preview \(isPreviewDynamicComponent)")
        } else {
            context.apiTrace.info("\(String.kDynamicTag) \(BDPSafeString(uniqueID.fullString)) loadPlugin by \(uniqueID.versionType.rawValue) version: \(params.version) ")
        }

        // 开始获取插件文件时间戳(单位:ms)
        let startGetPluginPkgTime = Date().timeIntervalSince1970 * 1000
        dynamicComponentManager.prepareDynamicComponent(componentAppID: params.pluginId, requireVersion: params.version, hostAppID: uniqueID.appID, previewToken: previewToken) {[weak self] error, state, meta in
            guard let `self` = self else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setMonitorMessage("self is nil When call API")
                context.apiTrace.error("\(String.kDynamicTag) self is nil")
                callback(.failure(error: error))
                OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: error.code.rawValue, errMsg: error.monitorMsg)
                return
            }

            guard error == nil else {
                context.apiTrace.error("\(String.kDynamicTag) prepareDynamicComponent failed: \(String(describing: error)) status:\(String(describing: state?.rawValue))")
                // 这边处理几个特定错误
                // 后端错误码定义: https://bytedance.feishu.cn/wiki/wikcnQjXTyTEdSBawzpGFFEUM4f
                if let _error = error as NSError?,
                    let code = _error.userInfo["code"] as? Int {
                    // pluginID非法.(如'cli_123')
                    if code == 10200 {
                        let callbackError = OpenAPIError(code: LoadPluginError.invalidPluginId).setError(error).setMonitorMessage("invalid plugin ID")
                        callback(.failure(error: callbackError))
                        OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: callbackError.code.rawValue, errMsg: callbackError.monitorMsg)
                        return
                    }

                    // 没有可见性
                    if code == 10252 {
                        let callbackError = OpenAPIError(code: LoadPluginError.notVisible).setError(error).setMonitorMessage("no permission for plugin")
                        callback(.failure(error: callbackError))
                        OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: callbackError.code.rawValue, errMsg: callbackError.monitorMsg)
                        return
                    }

                    // 插件版本不正确
                    if code == 10253 {
                        let callbackError = OpenAPIError(code: LoadPluginError.invalidPluginVersion).setError(error).setMonitorMessage("plugin version invalid: \(params.version)")
                        callback(.failure(error: callbackError))
                        OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: callbackError.code.rawValue, errMsg: callbackError.monitorMsg)
                        return
                    }
                }

                let callbackError = OpenAPIError(code: LoadPluginError.downloadFailed).setError(error).setMonitorMessage("download plugin fail")
                callback(.failure(error: callbackError))
                OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: callbackError.code.rawValue, errMsg: callbackError.monitorMsg)
                return
            }

            guard let meta = meta else {
                context.apiTrace.error("\(String.kDynamicTag) meta is nil, status:\(String(describing: state?.rawValue))")
                let callbackError = OpenAPIError(code: LoadPluginError.pluginNotExist).setError(error).setMonitorMessage("meta is nil")
                callback(.failure(error: callbackError))
                OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: callbackError.code.rawValue, errMsg: callbackError.monitorMsg)
                return
            }

            context.apiTrace.info("\(String.kDynamicTag) dynamic component: \(params.pluginId), version:\(params.version) prepare success, state: \(String(describing: state?.rawValue))")

            // 这边加载对应JS文件的时候会回调2次,一次是meta获取成功, 一次是包获取成功.
            // 这边需要在包拉取成功后,去加载包中的plugin-frame.js文件
            if (state == .pkg) {
                context.apiTrace.info("\(String.kDynamicTag) start get dynamic component resource pluginID: \(params.pluginId), version:\(params.version) prepare success")
                // 完成获取插件文件时间戳(单位:ms)
                let endGetPluginPkgTime = Date().timeIntervalSince1970 * 1000
                // 开始加载插件文件时间戳(单位:ms)
                let startLoadScriptTime = Date().timeIntervalSince1970 * 1000

                guard let data = self.dynamicComponentManager.getComponentResourceByPath(path: "plugin-frame.js", previewToken: previewToken, componentID: params.pluginId, requireVersion: params.version) else {
                    let error = OpenAPIError(code: LoadPluginError.pluginNotExist)
                        .setMonitorMessage("dynamic component resource data is nil")
                    context.apiTrace.error("\(String.kDynamicTag) dynamic component resource data is nil, pluginID: \(params.pluginId), version: \(params.version)")
                    callback(.failure(error: error))
                    OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: error.code.rawValue, errMsg: error.monitorMsg)
                    return
                }

                guard let script = String(data: data, encoding: .utf8) else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("convert data to string failed")
                    context.apiTrace.error("\(String.kDynamicTag) convert data to string failed, pluginID: \(params.pluginId), version: \(params.version)")
                    callback(.failure(error: error))
                    OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: error.code.rawValue, errMsg: error.monitorMsg)
                    return
                }

                guard let task = BDPTaskManager.shared().getTaskWith(uniqueID),
                      let appPageManager = task.pageManager,
                      let appPage = OPUnsafeObject(appPageManager.appPage(withID: params.webviewId)) else {
                          let error = OpenAPIError(code: LoadPluginError.pageNotFound)
                              .setMonitorMessage("can not find appPage")
                          context.apiTrace.error("\(String.kDynamicTag) can not find appPage. pluginID: \(params.pluginId), version: \(params.version), webviewId: \(params.webviewId)")
                          callback(.failure(error: error))
                          OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: error.code.rawValue, errMsg: error.monitorMsg)
                          return
                      }

                func evaluateJavaScript(_ appPage: BDPAppPage?) {
                    context.apiTrace.info("\(String.kDynamicTag) start evaluate plugin script pluginID: \(params.pluginId), version:\(params.version) webviewId: \(params.webviewId)")

                    guard let appPage = appPage else {
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage("appPage is nil When evaluateJavaScript")
                        context.apiTrace.error("\(String.kDynamicTag) appPage is nil When evaluateJavaScript")
                        callback(.failure(error: error))
                        OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: error.code.rawValue, errMsg: error.monitorMsg)
                        return
                    }

                    // 最终执行JS代码前, 检查一下isAppPageReady状态
                    guard appPage.isAppPageReady else {
                        let callbackError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                            .setMonitorMessage("appPage: \(params.webviewId) \(appPage.bap_path) is not ready")
                        context.apiTrace.error("\(String.kDynamicTag) appPage: \(params.webviewId) \(appPage.bap_path) is not ready")
                        callback(.failure(error: callbackError))
                        OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: callbackError.code.rawValue, errMsg: callbackError.monitorMsg)
                        return
                    }

                    appPage.bdp_evaluateJavaScript(script) { _, error in
                        guard error == nil else {
                            let callbackError = OpenAPIError(code: LoadPluginError.loadPluginFailed)
                                .setMonitorMessage("appPage: \(params.webviewId) evaluateScprit fail").setError(error)
                            callback(.failure(error: callbackError))
                            context.apiTrace.error("\(String.kDynamicTag) appPage: \(params.webviewId) evaluateScprit fail")
                            OPDynamicComponentHelper.reportLoadPluginFailMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, errCode: callbackError.code.rawValue, errMsg: callbackError.monitorMsg)
                            return
                        }

                        context.apiTrace.info("\(String.kDynamicTag) dynamic component: \(meta.appID), version:\(meta.applicationVersion) preview: \(isPreviewDynamicComponent) load script success")

                        // 完成加载插件文件时间戳(单位:ms)
                        let endLoadScriptTime = Date().timeIntervalSince1970 * 1000
                        // 计算下载耗时和加载耗时
                        let downloadPkgDuration = endGetPluginPkgTime - startGetPluginPkgTime
                        let loadScriptDuration = endLoadScriptTime - startLoadScriptTime

                        OPDynamicComponentHelper.reportLoadPluginSuccessMonitor(uniqueID: uniqueID, pluginId: params.pluginId, pluginVersion: params.version, webviewId: params.webviewId, downloadDuration: downloadPkgDuration, loadScriptDuration: loadScriptDuration)

                        // 当前在preview插件的时候,返回的版本为"dev"
                        // Note: preview插件的时候,服务端返回的meta信息中的版本信息为"", 这边是交由端侧处理.
                        let version = isPreviewDynamicComponent ? "dev" : meta.applicationVersion

                        let data = OpenAPILoadPluginResult(version: version)
                        callback(.success(data: data))
                    }
                }

                context.apiTrace.info("\(String.kDynamicTag) before load script, current page is ready: \(appPage.isAppPageReady)")

                // 这边执行plugin-frame.js的时机要与page-frame.js时机一样; 即接收到webViewOnDocumentReady之后.
                if appPage.isAppPageReady {
                    evaluateJavaScript(appPage)
                } else {
                    appPage.appendEvaluateDynamicComponentJSCallback({ [weak appPage] in
                        evaluateJavaScript(appPage)
                    })
                }
            } else {
                context.apiTrace.info("\(String.kDynamicTag) load plugin: \(params.pluginId) current status:\(String(describing: state?.rawValue))")
            }
        }
    }

    // MARK: Life Cycle
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "loadPlugin", pluginType: Self.self, paramsType: OpenLoadPluginParams.self, resultType: OpenAPILoadPluginResult.self) { (this, params, context, callback) in
            
            this.loadPlugin(params: params, context: context, callback: callback)
        }
    }
}


fileprivate extension String {
    static let kDynamicTag = "[Dynamic Component]"
}
