//
//  OpenPluginPicker.swift
//  OPPlugin
//
//  Created by yi on 2021/4/12.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import LKCommonsLogging
import LarkContainer

final class OpenPluginPicker: OpenBasePlugin {

    func showMultiPickerView(params: OpenAPIShowPickerViewParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIShowPickerViewResult>) -> Void) {
        showPickerView(params: params, context: context, callback: callback)
    }

    func showPickerView(params: OpenAPIShowPickerViewParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIShowPickerViewResult>) -> Void) {
        guard let gadgetContext = context.gadgetContext,let controller = gadgetContext.controller else {
            context.apiTrace.error("gadgetContext nil? \(context.gadgetContext == nil)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext nil? \(context.gadgetContext == nil)")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        guard let pickerPlugin = BDPTimorClient.shared().pickerPlugin.sharedPlugin() as? BDPPickerPluginDelegate else {
            context.apiTrace.error("has no BDPPickerPluginDelegate for \(uniqueID)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("has no BDPPickerPluginDelegate for \(uniqueID)")
            callback(.failure(error: error))
            return
        }

        var dict = [AnyHashable: Any]()
        dict["frameId"] = params.frameId
        dict["column"] = params.column
        if let array = params.array {
            dict["array"] = array
        }
        if let current = params.current {
            dict["current"] = current
        }

        do {
            let model = try BDPPickerPluginModel(dictionary: dict)

            pickerPlugin.bdp_showPickerView?(with: model, from: controller, pickerSelectedCallback: { [weak self] (seletedRow, column) in
                guard let `self` = self else {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("self is nil When call bdp_showPickerView")
                    callback(.failure(error: error))
                    context.apiTrace.error("Plugin: self is nil When call bdp_showPickerView")
                    return
                }
                let response = self.fireEventToWebView(context: context, event: "onMultiPickerViewChange", sourceID: params.frameId, data: ["column": column, "current": seletedRow])
                    switch response {
                    case .success(data: _):
                        context.apiTrace.info("fire showPickerView event success")
                    case let .failure(error: error):
                        context.apiTrace.error("fire showPickerView event error \(error)")
                    case .continue(event: _, data: _):
                        context.apiTrace.error("fire showPickerView event continue")
                    }
            }, completion: { (isCanceled, selectedRow, model) in
                if isCanceled {
                    // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("user cancel")
                    callback(.failure(error: error))
                    return
                }
                if let selectedRow = selectedRow as? [Int], selectedRow.count > 1 {
                    callback(.success(data: OpenAPIShowPickerViewResult(current: selectedRow, index: nil)))
                } else {
                    callback(.success(data: OpenAPIShowPickerViewResult(current: nil, index: selectedRow?.first as? Int ?? 0)))
                }
            })
        } catch {
            context.apiTrace.error("model error")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("model error")
            callback(.failure(error: error))
        }
    }

    func fireEventToWebView(context: OpenAPIContext, event: String, sourceID: Int, data: [AnyHashable: Any]?) -> OpenAPIBaseResponse<OpenAPIBaseResult> {
        do {
            let fireEvent = try OpenAPIFireEventParams(event: event,
                                                       sourceID: sourceID,
                                                       data: data,
                                                       preCheckType: .none,
                                                       sceneType: .render)
            let response = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            return response
        } catch {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("can not find gadgetContext to fireEventToWebView")
            context.apiTrace.error("can not find gadgetContext to fireEventToWebView")
            return .failure(error: error)
        }
    }

    func updateMultiPickerView(params: OpenAPIShowPickerViewParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let gadgetContext = context.gadgetContext,let controller = gadgetContext.controller else {
            context.apiTrace.error("gadgetContext nil? \(context.gadgetContext == nil)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext nil? \(context.gadgetContext == nil)")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        guard let pickerPlugin = BDPTimorClient.shared().pickerPlugin.sharedPlugin() as? BDPPickerPluginDelegate else {
            context.apiTrace.error("has no BDPPickerPluginDelegate for \(uniqueID)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("has no BDPPickerPluginDelegate for \(uniqueID)")
            callback(.failure(error: error))
            return
        }
        var dict = [AnyHashable: Any]()
        dict["frameId"] = params.frameId
        dict["column"] = params.column
        if let array = params.array {
            dict["array"] = array
        }
        if let current = params.current {
            dict["current"] = current
        }

        do {
            let model = try BDPPickerPluginModel(dictionary: dict)
            if model.selectedRows.isEmpty {
                model.selectedRows = [0]
            }
            pickerPlugin.bdp_updatePicker?(with: model, animated: false)
            callback(.success(data: nil))
        } catch {
            context.apiTrace.error("model error")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("model error")
            callback(.failure(error: error))
        }

    }

    func showDatePickerView(params: OpenAPIShowDatePickerViewParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIShowDatePickerViewResult>) -> Void) {
        guard let gadgetContext = context.gadgetContext,let controller = gadgetContext.controller else {
            context.apiTrace.error("gadgetContext nil? \(context.gadgetContext == nil)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext nil? \(context.gadgetContext == nil)")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        guard let pickerPlugin = BDPTimorClient.shared().pickerPlugin.sharedPlugin() as? BDPPickerPluginDelegate else {
            context.apiTrace.error("has no BDPPickerPluginDelegate for \(uniqueID)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("has no BDPPickerPluginDelegate for \(uniqueID)")
            callback(.failure(error: error))
            return
        }

        let dict: [String : Any] = ["range": params.range, "style": params.style, "current": params.current, "fields": params.fields, "mode": params.mode]
        do {
            let model = try BDPDatePickerPluginModel(dictionary: dict)
            pickerPlugin.bdp_showDatePickerView?(with: model, from: controller, completion: { (canceled, time) in
                if canceled {
                    // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("user cancel")
                    callback(.failure(error: error))
                    return
                }
                if var resultTime = OPUnsafeObject(time) {
                    context.apiTrace.info("bdp_showDatePickerView resultTime valid \(resultTime)")
                    if let startDate = OPUnsafeObject(model.startDate) {
                        let cmpRes = resultTime.compare(startDate)
                        let earlierThanStartDate = (cmpRes == .orderedAscending)
                        if earlierThanStartDate {
                            resultTime = startDate
                        }
                    }
                    if let endDate = OPUnsafeObject(model.endDate) {
                        let cmpRes = resultTime.compare(endDate)
                        let laterThanEndDate = (cmpRes == .orderedDescending)
                        if laterThanEndDate {
                            resultTime = endDate
                        }
                    }
                    let dateString = model.string(from: resultTime)
                    callback(.success(data: OpenAPIShowDatePickerViewResult(value: dateString)))
                } else {
                    context.apiTrace.error("picker time error")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage("picker time error")
                    callback(.failure(error: error))
                }
            })
        } catch {
            context.apiTrace.error("model error")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("model error")
            callback(.failure(error: error))
        }
    }

    func showRegionPickerView(params: OpenAPIShowRegionPickerViewParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIShowRegionPickerViewResult>) -> Void) {
        guard let gadgetContext = context.gadgetContext,let controller = gadgetContext.controller else {
            context.apiTrace.error("gadgetContext nil? \(context.gadgetContext == nil)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("gadgetContext nil? \(context.gadgetContext == nil)")
            callback(.failure(error: error))
            return
        }
        let uniqueID = gadgetContext.uniqueID
        guard let pickerPlugin = BDPTimorClient.shared().pickerPlugin.sharedPlugin() as? BDPPickerPluginDelegate else {
            context.apiTrace.error("has no BDPPickerPluginDelegate for \(uniqueID)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("has no BDPPickerPluginDelegate for \(uniqueID)")
            callback(.failure(error: error))
            return
        }

        let dict = ["current": params.current, "customItem": params.customItem] as [String : Any]
        do {
            let model = try BDPRegionPickerPluginModel(dictionary: dict)
            pickerPlugin.bdp_showRegionPickerView?(with: model, from: controller, completion: { (canceled, address) in
                if canceled {
                    // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("user cancel")
                    callback(.failure(error: error))
                    return
                }

                // 用户未取消
                var valueArray: [String] = []
                if let provinceName = address?.provinceName {
                    valueArray.append(provinceName)
                }
                if let cityName = address?.cityName {
                    valueArray.append(cityName)
                }
                if let countyName = address?.countyName {
                    valueArray.append(countyName)
                }

                var codeArray: [String] = []
                if let provinceCode = address?.provinceCode, !provinceCode.isEmpty {
                    codeArray.append(provinceCode)
                }
                if let cityCode = address?.cityCode, !cityCode.isEmpty {
                    codeArray.append(cityCode)
                }
                if let countryCode = address?.countryCode, !countryCode.isEmpty {
                    codeArray.append(countryCode)
                }

                callback(.success(data: OpenAPIShowRegionPickerViewResult(value: valueArray, code: codeArray)))
            })
        } catch {
            context.apiTrace.error("model error")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage("model error")
            callback(.failure(error: error))
        }
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "showMultiPickerView", pluginType: Self.self, paramsType: OpenAPIShowPickerViewParams.self, resultType: OpenAPIShowPickerViewResult.self) { (this, params, context, callback) in
            
            this.showMultiPickerView(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "showPickerView", pluginType: Self.self, paramsType: OpenAPIShowPickerViewParams.self, resultType: OpenAPIShowPickerViewResult.self) { (this, params, context, callback) in
            
            this.showPickerView(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "updateMultiPickerView", pluginType: Self.self, paramsType: OpenAPIShowPickerViewParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.updateMultiPickerView(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "showDatePickerView", pluginType: Self.self, paramsType: OpenAPIShowDatePickerViewParams.self, resultType: OpenAPIShowDatePickerViewResult.self) { (this, params, context, callback) in
            
            this.showDatePickerView(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "showRegionPickerView", pluginType: Self.self, paramsType: OpenAPIShowRegionPickerViewParams.self, resultType: OpenAPIShowRegionPickerViewResult.self) { (this, params, context, callback) in
            
            this.showRegionPickerView(params: params, context: context, callback: callback)
        }


    }
}
