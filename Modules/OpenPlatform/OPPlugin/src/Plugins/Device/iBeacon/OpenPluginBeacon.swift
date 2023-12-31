//
//  OpenPluginBeacon.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/7/5.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import CoreLocation
import LarkContainer

class OpenPluginBeacon: OpenBasePlugin {

    private var iBeaconManager: OpenPluginBeaconManager?

    /// 开始搜索附近的 iBeacon 设备
    public func startBeaconDiscovery(params: StartBeaconParams, context: OpenAPIContext, callback:@escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {

        getBeaconManager(context: context).startBeaconDiscovery(uuids: params.uuidArray, ignoreBluetoothAvailable: params.ignoreBluetoothAvailable) { (available, discovering) in
            do {
                let data = ["available" : available, "discovering" : discovering]
                let fireEvent = try OpenAPIFireEventParams(event: "beaconServiceChange",
                                                           sourceID: NSNotFound,
                                                           data: data,
                                                           preCheckType: .none,
                                                           sceneType: .normal)
                let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            } catch {
                context.apiTrace.error("syncCall fireEvent beaconServiceChange error:\(error)")
            }
        } beaconUpdateCallback: { (beacons) in
            do {
                context.apiTrace.info("beaconUpdate get beacons count:\(beacons.count)")
                let beaconInfos = beacons.map {
                    $0.dictionary
                }
                let data = ["beacons" : beaconInfos]
                let fireEvent = try OpenAPIFireEventParams(event: "beaconUpdate",
                                                           sourceID: NSNotFound,
                                                           data: data,
                                                           preCheckType: .none,
                                                           sceneType: .normal)
                let _ = context.syncCall(apiName: "fireEvent", params: fireEvent, context: context)
            } catch {
                context.apiTrace.error("syncCall fireEvent beaconUpdate error:\(error)")
            }
        } completionCallback: { (error) in
            if let err = error {
                context.apiTrace.error("startBeaconDiscovery failed. error:\(err)")
                callback(.failure(error: err))
                return
            }
            context.apiTrace.info("startBeaconDiscovery suceess")
            callback(.success(data: nil))
        }
    }

    /// 停止搜索附近的 iBeacon 设备
    public func stopBeaconDiscovery(params: OpenAPIBaseParams, context: OpenAPIContext, callback:@escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        getBeaconManager(context: context).stopBeaconDiscovery { (error) in
            if let err = error {
                context.apiTrace.error("stopBeaconDiscovery failed. error:\(err)")
                callback(.failure(error: err))
                return
            }
            context.apiTrace.info("stopBeaconDiscovery suceess")
            callback(.success(data: nil))
        }
    }

    /// 获取所有已搜索到的 iBeacon 设备
    public func getBeacons(params: OpenAPIBaseParams, context: OpenAPIContext, callback:@escaping (OpenAPIBaseResponse<OpenAPIGetBeaconResult>) -> Void) {
        getBeaconManager(context: context).getBeacons { (error, beacons) in
            if let err = error {
                context.apiTrace.error("getBeacons failed. error:\(err)")
                callback(.failure(error: err))
                return
            }

            let beaconInfos = beacons.map {
                $0.dictionary
            }

            context.apiTrace.info("getBeacons suceess, count:\(beaconInfos.count)")
            callback(.success(data: OpenAPIGetBeaconResult(beacons: beaconInfos)))
        }
    }


    private func getBeaconManager(context: OpenAPIContext) -> OpenPluginBeaconManager {
        if let manager = iBeaconManager {
            return manager
        }

        let manager = OpenPluginBeaconManager(with: context.apiTrace)
        iBeaconManager = manager
        return manager
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "startBeaconDiscovery", pluginType: Self.self, paramsType: StartBeaconParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.startBeaconDiscovery(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "stopBeaconDiscovery", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIBaseResult.self) { (this, params, context, callback) in
            
            this.stopBeaconDiscovery(params: params, context: context, callback: callback)
        }

        registerInstanceAsyncHandler(for: "getBeacons", pluginType: Self.self, paramsType: OpenAPIBaseParams.self, resultType: OpenAPIGetBeaconResult.self) { (this, params, context, callback) in
            
            this.getBeacons(params: params, context: context, callback: callback)
        }
    }
}

fileprivate extension CLBeacon {
    var dictionary: [String : Any] {
        var dic = [String : Any]()
        dic["uuid"] = self.uuidString
        dic["major"] = self.major
        dic["minor"] = self.minor
        dic["proximity"] = self.proximity.rawValue
        dic["accuracy"] = self.accuracy
        dic["rssi"] = self.rssi
        return dic
    }
}


