//
//  OpenPluginMapComponent.swift
//  OPPlugin
//
//  Created by yi on 2021/6/7.
//

import Foundation
import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import TTMicroApp
import ECOProbe
import OPFoundation
import OPPluginBiz
import LarkContainer

final class OpenPluginMapComponent: OpenBasePlugin {

    func insertMap(params: OpenAPIInsertMapComponentParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIInsertMapComponentResult>) -> Void) {
        guard let appView = context.enginePageForComponent as? BDPAppPage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("Must be in the applet runtime environment")
                .setMonitorMessage("Must be in the applet runtime environment")
            callback(.failure(error: error))
            return
        }
        let useNativeRender = useNativeRender(uniqueID: context.uniqueID)
        if useNativeRender {
            guard let componentId = params.mapId else {
                context.apiTrace.error("componentId is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                callback(.failure(error: error))
                return
            }
            do {
                let model = try BDPMapViewModel(dictionary: params.data)
                if let viewModelError = OpenMapValidator.checkBDPMapViewModel(model: model) {
                    context.apiTrace.error("param is invaild")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setOuterMessage(viewModelError.localizedDescription)
                    callback(.failure(error: error))
                    return
                }
                let map = BDPMapView(model: model, componentID: 0, engine: appView)
                appView.bdp_insertComponent(map, atIndex: componentId, completion: { (success) in
                    if success {
                        callback(.success(data: OpenAPIInsertMapComponentResult(mapId: componentId)))
                    } else {
                        context.apiTrace.error("bdp_insert map fail")
                        let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage("bdp_insert map fail")
                        callback(.failure(error: error))
                    }
                })
            } catch {
                context.apiTrace.error("BDPMapViewModel init error")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                callback(.failure(error: error))
            }

        } else {
            guard let generateComponentId = BDPComponentManager.shared()?.generateComponentID() else {
                context.apiTrace.error("componentId is nil")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                callback(.failure(error: error))
                return
            }
            let componentId = "\(generateComponentId)"
            do {
                let model = try BDPMapViewModel(dictionary: params.data)
                if let viewModelError = OpenMapValidator.checkBDPMapViewModel(model: model) {
                    context.apiTrace.error("param is invaild")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setOuterMessage(viewModelError.localizedDescription)
                    callback(.failure(error: error))
                    return
                }
                let map = BDPMapView(model: model, componentID: generateComponentId, engine: appView)

                BDPComponentManager.shared()?.insertComponentView(map, to: appView.scrollView, stringID: componentId)
                callback(.success(data: OpenAPIInsertMapComponentResult(mapId: componentId)))
            } catch {
                context.apiTrace.error("BDPMapViewModel init error")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                callback(.failure(error: error))
            }
        }
    }

    func updateMap(params: OpenAPIUpdateMapComponentParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let appView = context.enginePageForComponent as? BDPAppPage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("Must be in the applet runtime environment")
                .setMonitorMessage("Must be in the applet runtime environment")
            callback(.failure(error: error))
            return
        }
        do {
            let model = try BDPMapViewModel(dictionary: params.data)
            if let viewModelError = OpenMapValidator.checkBDPMapViewModel(model: model) {
                context.apiTrace.error("param is invaild")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage(viewModelError.localizedDescription)
                callback(.failure(error: error))
                return
            }
            var mapView: BDPMapView?
            let useNativeRender = useNativeRender(uniqueID: context.uniqueID)
            if useNativeRender {
                mapView = appView.bdp_component(fromIndex: params.mapId) as? BDPMapView
            } else {
                mapView = BDPComponentManager.shared()?.findComponentView(byStringID: params.mapId) as? BDPMapView
            }
            if let map = mapView {
                map.update(with: model)
                callback(.success(data: nil))
            } else {
                context.apiTrace.error("mapId \(params.mapId)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown).setOuterMessage("mapView is nil")
                callback(.failure(error: error))
            }
        } catch {
            context.apiTrace.error("BDPMapViewModel init error")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            callback(.failure(error: error))
        }
    }

    func removeMap(params: OpenAPIMapComponentParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let page = context.enginePageForComponent as? BDPAppPage else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("Must be in the applet runtime environment")
                .setMonitorMessage("Must be in the applet runtime environment")
            callback(.failure(error: error))
            return
        }

        let useNativeRender = useNativeRender(uniqueID: context.uniqueID)
        if useNativeRender {
            page.bdp_removeComponent(atIndex: params.mapId)
        } else {
            BDPComponentManager.shared()?.removeComponentView(byStringID: params.mapId)
        }
        callback(.success(data: nil))
    }

    func moveToLocation(params: OpenAPIMoveToLocationMapComponentParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        guard let map = BDPComponentManager.shared()?.findComponentView(byStringID: params.mapId) as? BDPMapView else {
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setOuterMessage("mapView is nil")
            context.apiTrace.error("mapView is nil, mapId \(params.mapId)")
            callback(.failure(error: error))
            return
        }

        if let latitude = params.latitude, let longitude = params.longitude {
            let location = CLLocationCoordinate2DMake(latitude, longitude)
            map.move(to: location)
        } else {
            map.moveToCurrentLocation()
        }
        callback(.success(data: nil))
    }

    func operateMapContext(params: OpenAPIOperateMapComponentParams, context: OpenAPIContext, callback: (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        let useNativeRender = useNativeRender(uniqueID: context.uniqueID)
        if !useNativeRender {
            callback(.success(data: nil))
            return
        }
        if params.type == "moveToLocation" {
            var mapView: BDPMapView?
            if let appView = context.enginePageForComponent as? BDPAppPage {
                mapView = appView.bdp_component(fromIndex: params.mapId) as? BDPMapView
            } else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage("Must be in the applet runtime environment")
                    .setMonitorMessage("Must be in the applet runtime environment")
                callback(.failure(error: error))
                return
            }
            guard let map = mapView else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                    .setOuterMessage("mapView is nil")
                context.apiTrace.error("mapView is nil, mapId \(params.mapId)")
                callback(.failure(error: error))
                return
            }

            if let latitude = params.latitude, let longitude = params.longitude {
                let location = CLLocationCoordinate2DMake(latitude, longitude)
                map.move(to: location)
            } else {
                map.moveToCurrentLocation()
            }
            callback(.success(data: nil))
            return
        }
        callback(.success(data: nil))
    }

    func useNativeRender(uniqueID: OPAppUniqueID?) -> Bool {
        guard let uniqueID = uniqueID else {
            return false
        }
        return (BDPTimorClient.shared().appEnginePlugin.sharedPlugin() as? EMAAppEnginePluginDelegate)?.onlineConfig?.isMapUseSameLayerRender(for: uniqueID) ?? false
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "insertMap", pluginType: Self.self, paramsType: OpenAPIInsertMapComponentParams.self, resultType: OpenAPIInsertMapComponentResult.self) { (this, params, context, callback) in
            
            this.insertMap(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "updateMap", pluginType: Self.self, paramsType: OpenAPIUpdateMapComponentParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.updateMap(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "moveToLocation", pluginType: Self.self, paramsType: OpenAPIMoveToLocationMapComponentParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.moveToLocation(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "removeMap", pluginType: Self.self, paramsType: OpenAPIMapComponentParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.removeMap(params: params, context: context, callback: callback)
        }
        registerInstanceAsyncHandler(for: "operateMapContext", pluginType: Self.self, paramsType: OpenAPIOperateMapComponentParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.operateMapContext(params: params, context: context, callback: callback)
        }
    }
}
